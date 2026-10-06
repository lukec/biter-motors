local REPORT = "bitermotors-recycling.jsonl"
local WRECK = "bitermotors-wrecked-ev"
local HIGH_SCRAP = "bitermotors-damaged-high-energy-battery-pack"
local LFP_SCRAP = "bitermotors-damaged-lfp-battery-pack"
local REWRITTEN = {
  "electric-furnace", "big-mining-drill", "foundry", "recycler", "teslagun",
  "tesla-turret", "tesla-ammo", "stack-inserter", "speed-module-3",
  "productivity-module-3", "efficiency-module-3", "quality-module-3",
  "personal-roboport-mk2-equipment", "battery-mk3-equipment", "cliff-explosives",
  "artillery-wagon", "artillery-turret", "artillery-shell"
}
local assertions = 0

local function check(condition, label)
  assert(condition, label)
  assertions = assertions + 1
end

local function equal(actual, expected, label)
  check(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function report(status, extra)
  local row = extra or {}
  row.status = status
  row.tick = game.tick
  row.assertions = assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function make(name, position, quality)
  return assert(game.surfaces.nauvis.create_entity{
    name = name, position = position, quality = quality or "normal",
    force = game.forces.player, raise_built = true
  }, "could not place " .. name)
end

local function power_at(position)
  make("substation", {position.x + 3, position.y + 3})
  local power = make("electric-energy-interface", {position.x + 7, position.y + 3})
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production = 100000000
  power.output_flow_limit = 100000000
end

local function source(machine)
  return machine.get_inventory(defines.inventory.crafter_input)
end

local function area(position)
  return {{position.x - 6, position.y - 6}, {position.x + 6, position.y + 6}}
end

local function add_stack(counts, stack)
  if stack.valid_for_read then
    local key = stack.name .. ":" .. stack.quality.name
    counts[key] = (counts[key] or 0) + stack.count
  end
end

local function collect_output(task)
  local inventory = task.machine.get_inventory(defines.inventory.crafter_output)
  for index = 1, #inventory do add_stack(task.outputs, inventory[index]) end
  inventory.clear()
  for _, drop in pairs(game.surfaces.nauvis.find_entities_filtered{
    area = area(task.machine.position), type = "item-entity"
  }) do
    add_stack(task.outputs, drop.stack)
    drop.destroy()
  end
end

local function output_total(outputs)
  local total = 0
  for _, count in pairs(outputs) do total = total + count end
  return total
end

local function assert_recipe_outputs(task, recipe_name, batch)
  local expected = {}
  for _, ingredient in pairs(prototypes.recipe[recipe_name].ingredients) do
    equal(ingredient.type, "item", "rewritten recipe has only terrestrial item ingredients")
    local key = ingredient.name .. ":" .. task.quality
    local per_craft = ingredient.amount / 4
    -- Native fractional recovery rolls independently on each craft.
    expected[key] = {minimum = math.floor(per_craft) * batch, maximum = math.ceil(per_craft) * batch}
  end
  for key, count in pairs(task.outputs) do
    check(expected[key] ~= nil, recipe_name .. " created unexpected " .. key)
    check(count >= expected[key].minimum and count <= expected[key].maximum,
      recipe_name .. " did not use native quarter recovery: " .. key .. "=" .. count)
  end
  for key, count in pairs(expected) do
    local actual = task.outputs[key] or 0
    check(actual >= count.minimum and actual <= count.maximum,
      recipe_name .. " lost or inflated " .. key .. "=" .. actual)
  end
end

local function salvage_on_ground(position)
  local counts = {}
  for _, drop in pairs(game.surfaces.nauvis.find_entities_filtered{area = area(position), type = "item-entity"}) do
    if drop.stack.valid_for_read and (drop.stack.name == WRECK or drop.stack.name == HIGH_SCRAP
        or drop.stack.name == LFP_SCRAP) then
      add_stack(counts, drop.stack)
      drop.destroy()
    end
  end
  return counts
end

local function statistics_count(name, quality)
  return game.forces.player.get_item_production_statistics(game.surfaces.nauvis)
    .get_input_count{name = name, quality = quality or "normal"}
end

local function expect_salvage_statistic(item, quality, count)
  local key = item .. ":" .. quality
  local row = storage.salvage_statistics[key]
  if not row then
    row = {item = item, quality = quality, before = statistics_count(item, quality), expected = 0}
    storage.salvage_statistics[key] = row
  end
  row.expected = row.expected + count
end

local function assert_vehicle_death(name, position, quality, high_packs, lfp_packs)
  local expected = {[WRECK] = 1, [HIGH_SCRAP] = high_packs, [LFP_SCRAP] = lfp_packs}
  for item, count in pairs(expected) do expect_salvage_statistic(item, quality, count) end
  local vehicle = make(name, position, quality)
  check(vehicle.die(game.forces.enemy), "native vehicle death succeeded")
  local drops = salvage_on_ground(position)
  for item, count in pairs(expected) do
    equal(drops[item .. ":" .. quality] or 0, count, name .. " physical salvage quantity")
  end
  equal(output_total(drops), 1 + high_packs + lfp_packs, name .. " produces no extra-quality salvage")
  storage.salvage_cases = storage.salvage_cases + 1
  storage.last_death_tick = game.tick
end

local function policy_checks()
  for _, name in ipairs(REWRITTEN) do
    local recipe = prototypes.recipe[name .. "-recycling"]
    check(recipe ~= nil, name .. " reverse recipe exists")
    check(recipe.allowed_effects and not recipe.allowed_effects.productivity,
      name .. " reverse is non-productive")
  end
  for _, case in ipairs({
    {item = HIGH_SCRAP, recipe = "bitermotors-high-energy-battery-recovery", cell = "bitermotors-high-nickel-cell"},
    {item = LFP_SCRAP, recipe = "bitermotors-lfp-battery-recovery", cell = "bitermotors-lfp-cell"}
  }) do
    equal(prototypes.recipe[case.item .. "-recycling"], nil, "damaged pack has no destructive fallback")
    local recipe = prototypes.recipe[case.recipe]
    equal(#recipe.ingredients, 1, "one recovery input")
    equal(recipe.ingredients[1].name, case.item, "correct damaged chemistry input")
    equal(recipe.ingredients[1].amount, 10, "ten-pack recovery batch")
    equal(#recipe.products, 1, "one recovery output")
    equal(recipe.products[1].name, case.cell, "correct recovered chemistry")
    equal(recipe.products[1].amount, 36, "90 percent of original forty cells")
    check(recipe.allowed_effects and not recipe.allowed_effects.productivity,
      "recovery cannot amplify through productivity")
  end
  report("policy_passed", {rewritten = #REWRITTEN, battery_routes = 2})
end

local function recycler_task(index, item, quality, kind, cell)
  local position = {x = -70 + ((index - 1) % 5) * 20, y = -70 + math.floor((index - 1) / 5) * 20}
  power_at(position)
  local task = {machine = make("recycler", position), item = item, quality = quality,
    kind = kind, cell = cell, outputs = {}, stage_tick = game.tick}
  if kind == "incremental" then
    task.stage = "prior_recipe"
    equal(source(task.machine).insert{name = "big-mining-drill", count = 1}, 1, "seed prior automatic recipe")
  else
    task.stage = "craft"
    task.batch = kind == "recovery" and 10 or 4
    equal(source(task.machine).insert{name = item, quality = quality, count = task.batch},
      task.batch, "feed native recycler")
  end
  storage.tasks[#storage.tasks + 1] = task
end

script.on_init(function()
  storage.salvage_cases = 0
  storage.salvage_statistics = {}
  storage.tasks = {}
  storage.premium = {}
  storage.started = game.tick
  game.tick_paused = false
  game.speed = 100
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 4)
  surface.force_generate_chunk_requests()
  surface.peaceful_mode = true
  game.map_settings.enemy_expansion.enabled = false
  for _, entity in pairs(surface.find_entities_filtered{area = {{-96, -96}, {96, 96}}}) do entity.destroy() end
  local tiles = {}
  for x = -96, 96 do
    for y = -96, 96 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
  end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.technologies.recycling.researched = true
  force.technologies["bitermotors-battery-material-recovery"].researched = true
  policy_checks()
  for index, name in ipairs(REWRITTEN) do recycler_task(index, name, "normal", "reverse") end
  recycler_task(19, "big-mining-drill", "rare", "reverse")
  recycler_task(20, HIGH_SCRAP, "normal", "incremental", "bitermotors-high-nickel-cell")
  recycler_task(21, LFP_SCRAP, "normal", "incremental", "bitermotors-lfp-cell")
  recycler_task(22, HIGH_SCRAP, "rare", "recovery", "bitermotors-high-nickel-cell")
  recycler_task(23, LFP_SCRAP, "rare", "recovery", "bitermotors-lfp-cell")

  local position = {x = 20, y = 60}
  power_at(position)
  storage.partial = make("recycler", position)
  equal(source(storage.partial).insert{name = HIGH_SCRAP, count = 9}, 9, "checkpoint partial batch seeded")
  for index, recipe_name in ipairs({"bitermotors-premium-ev", "bitermotors-premium-ev-cell-scale"}) do
    force.recipes[recipe_name].enabled = true
    position = {x = 60 + (index - 1) * 20, y = 60}
    power_at(position)
    local machine = make("assembling-machine-3", position)
    machine.set_recipe(recipe_name)
    equal(machine.get_recipe().name, recipe_name, "selected actual Premium crafting recipe")
    for _, ingredient in pairs(prototypes.recipe[recipe_name].ingredients) do
      equal(machine.get_inventory(defines.inventory.crafter_input).insert{
        name = ingredient.name, count = ingredient.amount
      }, ingredient.amount, "feed real Premium ingredients")
    end
    storage.premium[#storage.premium + 1] = {machine = machine, recipe_name = recipe_name}
  end
  storage.stage = "native"
end)

local function native_salvage_setup()
  local surface = game.surfaces.nauvis
  assert_vehicle_death("bitermotors-mass-market-ev", {x = 60, y = -70}, "normal", 0, 4)
  assert_vehicle_death("bitermotors-megatruck", {x = 60, y = -50}, "rare", 8, 0)
  assert_vehicle_death("bitermotors-bitertaxi-fleet", {x = 60, y = -30}, "normal", 0, 16)
  assert_vehicle_death("bitermotors-espider", {x = 60, y = -10}, "normal", 0, 0)
  for y = 24, 38, 2 do make("straight-rail", {x = 64, y = y}) end
  assert_vehicle_death("bitermotors-cybertrain", {x = 64, y = 30}, "rare", 8, 0)

  local chest = make("steel-chest", {x = -8, y = 64})
  local inventory = chest.get_inventory(defines.inventory.chest)
  local position = {x = -8, y = 60}
  local mined = make("bitermotors-premium-ev", position)
  check(mined.mine{inventory = inventory}, "native entity mining succeeds")
  equal(inventory.get_item_count("bitermotors-premium-ev"), 1, "mining returns reusable vehicle")
  equal(output_total(salvage_on_ground(position)), 0, "mining creates no extra wreck or battery scrap")
  storage.salvage_cases = storage.salvage_cases + 1

  position = {x = -40, y = 60}
  power_at(position)
  local port = make("roboport", position)
  equal(port.get_inventory(defines.inventory.roboport_robot).insert{name = "construction-robot", count = 4},
    4, "native construction robots supplied")
  storage.robot_chest = make("storage-chest", {x = -44, y = 60})
  storage.robot_vehicle_position = {x = -40, y = 68}
  storage.robot_vehicle = make("bitermotors-megatruck", storage.robot_vehicle_position)
  check(storage.robot_vehicle.order_deconstruction(game.forces.player), "native robot deconstruction ordered")
  position = {x = -30, y = 60}
  local removed = make("bitermotors-megatruck", position)
  check(removed.destroy{raise_destroy = true}, "native script removal succeeds")
  equal(output_total(salvage_on_ground(position)), 0, "script removal does not impersonate a death")
  storage.salvage_cases = storage.salvage_cases + 1

  make("stone-wall", {x = -70, y = 66})
  storage.collision_position = {x = -70, y = 70}
  expect_salvage_statistic(WRECK, "normal", 1)
  local roadster = make("bitermotors-prototype-roadster", storage.collision_position)
  roadster.orientation = 0
  roadster.health = 1
  roadster.speed = 0.5
  storage.collision_vehicle = roadster
end

local function advance_task(task)
  if task.stage == "done" then return end
  collect_output(task)
  if task.stage == "prior_recipe" then
    if task.machine.products_finished < 1 then return end
    equal(source(task.machine).is_empty(), true, "prior recipe input consumed")
    assert_recipe_outputs(task, "big-mining-drill", 1)
    task.outputs = {}
    task.finished_before = task.machine.products_finished
    task.stage = "partial"
    task.partial_count = 1
    task.stage_tick = game.tick
    equal(source(task.machine).insert{name = task.item, count = 1}, 1, "begin damaged batch after prior recipe")
  elseif task.stage == "partial" and game.tick >= task.stage_tick + 90 then
    equal(source(task.machine).get_item_count(task.item), task.partial_count,
      "1-9 damaged packs survive native automatic recipe selection")
    equal(task.machine.products_finished, task.finished_before, "small batch has not crafted")
    equal(output_total(task.outputs), 0, "small batch produces no waste or cells")
    equal(source(task.machine).insert{name = task.item, count = 1}, 1, "incrementally add next damaged pack")
    task.partial_count = task.partial_count + 1
    task.stage_tick = game.tick
    if task.partial_count == 10 then task.stage = "craft"; task.batch = 10 end
  elseif task.stage == "craft" then
    local expected_finished = (task.finished_before or 0) + (task.kind == "reverse" and task.batch or 1)
    if task.machine.products_finished < expected_finished then return end
    equal(task.machine.products_finished, expected_finished, "native completion count is exact")
    equal(source(task.machine).is_empty(), true, "native recycler consumed complete batch")
    if task.kind == "reverse" then
      assert_recipe_outputs(task, task.item, task.batch)
    else
      equal(task.outputs[task.cell .. ":" .. task.quality] or 0, 36, "native recovery returns exactly 36 correct-quality cells")
      equal(output_total(task.outputs), 36, "native recovery creates no bonus hardware or other chemistry")
    end
    task.stage = "done"
  end
end

local function native_stage()
  local done = true
  for _, task in ipairs(storage.tasks) do
    advance_task(task)
    if task.stage ~= "done" then done = false end
  end
  for index, task in ipairs(storage.premium) do
    if not task.done then
      -- This fixture tests the real recipe, not earning its sales milestone.
      game.forces.player.recipes[task.recipe_name].enabled = true
      local output = task.machine.get_inventory(defines.inventory.crafter_output)
      if output.get_item_count("bitermotors-premium-ev") == 1 then
        equal(task.machine.products_finished, 1, "one Premium from actual recipe")
        equal(task.machine.get_inventory(defines.inventory.crafter_input).is_empty(), true,
          "actual Premium ingredients consumed")
        equal(output.remove{name = "bitermotors-premium-ev", count = 1}, 1, "take crafted Premium")
        assert_vehicle_death("bitermotors-premium-ev", {x = 60 + (index - 1) * 20, y = 80}, "normal", 0, 0)
        task.done = true
      else
        done = false
      end
    end
  end
  if not storage.collision_done then
    if storage.collision_vehicle.valid then
      done = false
    else
      local drops = salvage_on_ground(storage.collision_position)
      equal(drops[WRECK .. ":normal"] or 0, 1, "actual low-health driving collision creates one wreck")
      equal(output_total(drops), 1, "Roadster collision creates no advanced materials")
      storage.salvage_cases = storage.salvage_cases + 1
      storage.collision_done = true
      storage.last_death_tick = game.tick
    end
  end
  if not storage.robot_mining_done then
    if storage.robot_vehicle.valid or storage.robot_chest.get_inventory(defines.inventory.chest)
        .get_item_count("bitermotors-megatruck") ~= 1 then
      done = false
    else
      equal(storage.robot_mining_events, 1, "engine emitted exactly one robot mining event")
      equal(output_total(salvage_on_ground(storage.robot_vehicle_position)), 0,
        "robot mining returns vehicle without battery scrap or wreck")
      local inventory = storage.robot_chest.get_inventory(defines.inventory.chest)
      equal(inventory.get_item_count(HIGH_SCRAP), 0, "robot inventory contains no fabricated high-energy packs")
      equal(inventory.get_item_count(WRECK), 0, "robot inventory contains no duplicate body wreck")
      equal(inventory.get_item_count("bitermotors-electric-drive-charge"), 0,
        "native robot mining does not leak hidden drive charge into storage")
      storage.salvage_cases = storage.salvage_cases + 1
      storage.robot_mining_done = true
    end
  end
  if done then
    if game.tick <= storage.last_death_tick then return end
    for _, row in pairs(storage.salvage_statistics) do
      equal(statistics_count(row.item, row.quality) - row.before, row.expected,
        "salvage statistic reconciles physical drops: " .. row.item .. ":" .. row.quality)
    end
    equal(source(storage.partial).get_item_count(HIGH_SCRAP), 9, "nine damaged packs wait until checkpoint")
    equal(storage.partial.products_finished, 0, "checkpoint partial batch has never been consumed")
    storage.stage = "reload"
    storage.saved_tick = game.tick
    local counts = {normal_rewrites = 0, rare_rewrites = 0, recovery_cases = 0}
    for _, task in ipairs(storage.tasks) do
      if task.kind == "reverse" then
        local key = task.quality == "normal" and "normal_rewrites" or "rare_rewrites"
        counts[key] = counts[key] + 1
      else
        counts.recovery_cases = counts.recovery_cases + 1
      end
    end
    equal(counts.normal_rewrites, 18, "all rewritten native recipes completed")
    equal(counts.rare_rewrites, 1, "native rare reverse completed")
    equal(counts.recovery_cases, 4, "both chemistries completed at normal and rare quality")
    equal(storage.salvage_cases, 11, "all native salvage and mining cases completed")
    local progress = remote.call("bitermotors", "progress_status", "player").snapshot
    equal(progress.customer_ev_sales_lifetime, 0, "recycling and salvage do not count as customer sales")
    equal(progress.consumer_evs_sold, 0, "recycling does not advance consumer sale gates")
    equal(progress.first_sale_complete, false, "recovered capital does not establish a first vehicle sale")
    counts.recovered_capital = 0
    for _, task in ipairs(storage.tasks) do
      counts.recovered_capital = counts.recovered_capital + (task.outputs["bitermotors-dollar:normal"] or 0)
    end
    counts.progress_reported_profit = progress.dollars_produced
    counts.salvage_cases = storage.salvage_cases
    counts.checkpoint_partial_packs = 9
    game.server_save("bitermotors-recycling-reload")
    report("recycling_passed", counts)
  end
end

local loaded = false
script.on_load(function() loaded = storage.stage == "reload" end)
script.on_event(defines.events.on_robot_mined_entity, function(event)
  if event.entity.name == "bitermotors-megatruck" then
    storage.robot_mining_events = (storage.robot_mining_events or 0) + 1
  end
end)
script.on_nth_tick(30, function()
  if loaded and storage.stage == "reload" and game.tick > storage.saved_tick then
    equal(source(storage.partial).get_item_count(HIGH_SCRAP), 9, "partial damaged batch survives native reload")
    equal(storage.partial.products_finished, 0, "reload does not silently self-recycle damaged packs")
    for _, task in ipairs(storage.tasks) do equal(task.stage, "done", "completed recycler case remains complete") end
    equal(storage.salvage_cases, 11, "reload preserves exact salvage case count")
    report("reload_passed", {saved_tick = storage.saved_tick, checkpoint_partial_packs = 9})
    storage.stage = "done"
    return
  end
  if storage.stage ~= "native" or game.tick <= storage.started then return end
  if not storage.salvage_started then
    storage.salvage_started = true
    native_salvage_setup()
    return
  end
  if game.tick - storage.started >= 12000 then
    local pending = {}
    for _, task in ipairs(storage.tasks) do
      if task.stage ~= "done" then
        pending[#pending + 1] = {item = task.item, quality = task.quality, stage = task.stage,
          finished = task.machine.products_finished, status = task.machine.status,
          inputs = source(task.machine).get_contents(), outputs = task.outputs}
      end
    end
    error("recycling fixture timed out: " .. helpers.table_to_json{
      tasks = pending, collision_valid = storage.collision_vehicle.valid,
      premium = (function()
        local rows = {}
        for _, task in ipairs(storage.premium) do
          rows[#rows + 1] = {recipe = task.recipe_name, done = task.done,
            enabled = game.forces.player.recipes[task.recipe_name].enabled,
            finished = task.machine.products_finished, status = task.machine.status,
            energy = task.machine.energy,
            inputs = task.machine.get_inventory(defines.inventory.crafter_input).get_contents(),
            outputs = task.machine.get_inventory(defines.inventory.crafter_output).get_contents()}
        end
        return rows
      end)(), robot_vehicle_valid = storage.robot_vehicle.valid,
      robot_mining_events = storage.robot_mining_events,
      robot_chest = storage.robot_chest.get_inventory(defines.inventory.chest).get_contents()
    })
  end
  native_stage()
end)
