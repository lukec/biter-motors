local AiAccounting = require("__bitermotors__/runtime/ai_accounting")
local REPORT = "bitermotors-ai.jsonl"
local TOKEN = "bitermotors-ai-token"
local DATASET = "bitermotors-agi-training-dataset"
local DOLLAR = "bitermotors-dollar"
local CORE = "bitermotors-orbital-datacenter-core"
local DATACENTER = "bitermotors-terrestrial-datacenter"
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
  row.status, row.tick, row.assertions = status, game.tick, assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function ledger(force)
  return remote.call("bitermotors", "endgame_status", (force or game.forces.player).name)
end

local function input(machine) return machine.get_inventory(defines.inventory.crafter_input) end
local function output(machine) return machine.get_inventory(defines.inventory.crafter_output) end

local function pure_fixtures()
  check(prototypes.recipe[DATASET .. "-recycling"] == nil, "Datasets cannot reverse-recycle into fresh progress or capital")
  check(prototypes.recipe["bitermotors-capital-allocation-recycling"] == nil, "Allocations cannot reverse-recycle")
  for _, case in ipairs({
    {"bitermotors-terrestrial-ai-token", 20},
    {"bitermotors-orbital-ai-token", 10000},
    {"bitermotors-orbital-ai-token-cluster", 25000},
    {"bitermotors-orbital-ai-token-grid-scale", 50000},
    {"bitermotors-orbital-ai-token-hyperscale", 100000},
    {"bitermotors-orbital-ai-dataset-grid-scale", 50000},
    {"bitermotors-orbital-ai-dataset-hyperscale", 100000}
  }) do
    local track = AiAccounting.ensure()
    equal(AiAccounting.record(track, case[1], 1, "normal", false, 0), true, "approved completion")
    equal(track.generated, case[2], "exact token equivalents")
    local physical_equivalents = 0
    for _, product in pairs(prototypes.recipe[case[1]].products) do
      physical_equivalents = physical_equivalents + product.amount
        * (product.name == DATASET and 50000 or 1)
    end
    equal(physical_equivalents, case[2], "ledger descriptor matches native physical outputs")
    track = helpers.json_to_table(helpers.table_to_json(track))
    equal(track.generated, case[2], "serialized ledger conserves progress")
  end
  local track = AiAccounting.ensure()
  equal(AiAccounting.record(track, "bitermotors-package-agi-training-dataset", 1, "normal", false, 6),
    false, "packaging is not computation")
  equal(track.generated, 0, "packaging does not mint progress")
  for _, quality in ipairs({"normal", "rare"}) do
    AiAccounting.record(track, "bitermotors-terrestrial-ai-token", 1, quality, false, 1)
    equal(track.pending_bonus[1][quality], 2, "research bonus retains product quality")
  end
  equal(track.generated, 40, "undelivered bonuses are not earned")
  equal(AiAccounting.deliver_bonus(track, 1, "normal", 1), 1, "partial delivery")
  equal(AiAccounting.deliver_bonus(track, 1, "normal", 99), 1, "delivery cannot exceed liability")
  equal(AiAccounting.deliver_bonus(track, 1, "normal", 99), 0, "no duplicate bonus delivery")
  equal(track.generated, 42, "only materialized bonuses earn progress")
  equal(AiAccounting.discard_pending(track, 1), 2, "removal discards undelivered quality bonus")
  equal(track.pending_bonus_total, 0, "pending total reconciles on removal")
  AiAccounting.record(track, "bitermotors-terrestrial-ai-token", 2, "normal", true, 6)
  equal(track.generated, 62, "native productivity completion counts once")
  equal(track.pending_bonus_total, 0, "no bonus on native bonus")
  report("ai_policy_passed")
end

local function make(surface, name, position, force, quality)
  return assert(surface.create_entity{
    name = name, position = position, force = force, quality = quality or "normal", raise_built = true
  }, "could not create " .. name)
end

local function power(surface, position, force, terrestrial)
  if terrestrial then make(surface, "substation", {position[1] + 4, position[2] + 4}, force) end
  local source = make(surface, "electric-energy-interface", position, force)
  source.electric_interface_mode = defines.electric_interface_mode.primary_output
  source.power_production, source.output_flow_limit = 10000000000, 10000000000
end

local function task(surface, name, recipe, position, force, kind, quality)
  local machine = make(surface, name, position, force)
  force.recipes[recipe].enabled = true
  machine.set_recipe(recipe, quality or "normal")
  local row = {machine = machine, kind = kind or "ordinary", recipe = recipe,
    quality = quality or "normal", force = force.name, completions = 0, native_bonus = 0}
  storage.tasks[#storage.tasks + 1] = row
  storage.by_unit[machine.unit_number] = row
  if kind ~= "pack" and kind ~= "capital" then
    input(machine).insert{name = DOLLAR, count = name == DATACENTER and 20 or 1, quality = row.quality}
  end
  return row
end

local function platform(force, name, count)
  local value = force.create_space_platform{name = name, planet = "nauvis",
    starter_pack = "space-platform-starter-pack"}
  check(value.apply_starter_pack(true) ~= nil, "real platform starter hub")
  local surface = value.surface
  local tiles = {}
  for x = -64, 64 do
    for y = -48, 64 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
  end
  surface.set_tiles(tiles, false, false, false, true)
  power(surface, {-48, -32}, force)
  for index = 1, count * 8 do
    make(surface, "bitermotors-orbital-radiator-panel",
      {-54 + ((index - 1) % 18) * 6, 32 + math.floor((index - 1) / 18) * 6}, force)
  end
  return surface
end

script.on_init(function()
  pure_fixtures()
  game.tick_paused, game.speed = false, 100
  storage.tasks, storage.by_unit, storage.events = {}, {}, {}
  storage.started, storage.stage = game.tick, "native"
  local force, land = game.forces.player, game.surfaces.nauvis
  force.technologies["bitermotors-terrestrial-ai"].researched = true
  force.technologies["bitermotors-terrestrial-ai-efficiency-1"].researched = true
  force.technologies["bitermotors-orbital-compute"].researched = true
  land.request_to_generate_chunks({0, 0}, 4)
  land.force_generate_chunk_requests()
  for _, entity in pairs(land.find_entities_filtered{area = {{-96, -32}, {96, 48}}}) do entity.destroy() end
  local tiles = {}
  for x = -96, 96 do
    for y = -32, 48 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
  end
  land.set_tiles(tiles)
  for _, x in ipairs({-64, -40, -16, 8, 32, 56}) do power(land, {x, -8}, force, true) end
  storage.normal = task(land, DATACENTER, "bitermotors-terrestrial-ai-token", {-64, 0}, force)
  storage.rare = task(land, DATACENTER, "bitermotors-terrestrial-ai-token", {-40, 0}, force, "ordinary", "rare")
  storage.pending = task(land, DATACENTER, "bitermotors-terrestrial-ai-token", {-16, 0}, force, "pending")
  storage.removed = task(land, DATACENTER, "bitermotors-terrestrial-ai-token", {8, 0}, force, "removed")
  storage.productivity = task(land, DATACENTER, "bitermotors-terrestrial-ai-token", {32, 0}, force, "productivity")
  storage.pack = task(land, "assembling-machine-2", "bitermotors-package-agi-training-dataset", {56, 0}, force, "pack")
  storage.capital = task(land, "bitermotors-biterfactory-building", "bitermotors-package-capital-allocation", {56, 20}, force, "capital")
  power(land, {40, 24}, force, true)
  input(storage.capital.machine).insert{name = DOLLAR, count = 500}

  local orbit = platform(force, "AI accounting A", 7)
  for index, spec in ipairs({
    {"bitermotors-orbital-ai-token", "ordinary"},
    {"bitermotors-orbital-ai-token-cluster", "ordinary"},
    {"bitermotors-orbital-ai-token-grid-scale", "ordinary"},
    {"bitermotors-orbital-ai-token-hyperscale", "ordinary"},
    {"bitermotors-orbital-ai-dataset-grid-scale", "switch"},
    {"bitermotors-orbital-ai-dataset-hyperscale", "ordinary"},
    {"bitermotors-orbital-ai-token", "destroyed"}
  }) do
    task(orbit, CORE, spec[1], {-48 + (index - 1) * 14, 12}, force, spec[2])
  end
  local second = game.create_force("ai-second-force")
  second.technologies["bitermotors-orbital-compute"].researched = true
  local orbit_b = platform(second, "AI accounting B", 1)
  storage.other = task(orbit_b, CORE, "bitermotors-orbital-ai-dataset-hyperscale", {0, 12}, second)
  local payload_machine = storage.tasks[13].machine
  local edge = payload_machine.position.y + payload_machine.prototype.selection_box.right_bottom.y
  storage.payload_chest = make(orbit, "steel-chest", {payload_machine.position.x, edge + 1.5}, force)
  local inserter = make(orbit, "fast-inserter", {payload_machine.position.x, edge + 0.5}, force)
  inserter.direction = defines.direction.north
  check(inserter.pickup_position.y < edge, "payload extraction targets current core footprint")
  storage.payload_inserter = inserter
  storage.blocked = storage.tasks[9]
  -- A real output-full machine must not advance the ledger until it can craft.
  local blocked_output = output(storage.blocked.machine)
  blocked_output.insert{name = TOKEN, count = #blocked_output * prototypes.item[TOKEN].stack_size}
  storage.fake_stats = game.create_force("ai-statistics-only")
  storage.fake_stats.get_item_production_statistics(land).set_input_count(TOKEN, 1000000000)
end)

for recipe_name in pairs(AiAccounting.recipes) do
  script.on_event(prototypes.recipe[recipe_name].on_crafted_event, function(event)
    local row = storage.by_unit and storage.by_unit[event.entity.unit_number]
    if not row then return end
    local amount = AiAccounting.recipes[event.recipe].tokens
    storage.events[row.force] = (storage.events[row.force] or 0) + amount
    row.completions = row.completions + 1
    if event.bonus then row.native_bonus = row.native_bonus + 1 end
    if row.kind == "pending" then
      equal(output(row.machine).get_item_count(TOKEN), 20, "native craft materializes before event")
      output(row.machine).insert{name = TOKEN, count = #output(row.machine) * prototypes.item[TOKEN].stack_size}
    elseif row.kind == "removed" or row.kind == "destroyed" then
      row.machine.destroy{raise_destroy = row.kind == "removed"}
    elseif row.kind == "switch" and row.completions == 1 then
      equal(output(row.machine).get_item_count(DATASET), 1, "direct grid-scale Dataset is physical")
      row.machine.set_recipe("bitermotors-orbital-ai-token")
      input(row.machine).insert{name = DOLLAR, count = 1}
    end
  end)
end

local function native_step()
  local elapsed = game.tick - storage.started
  if storage.checkpoint_started then
    if storage.normal.machine.crafting_progress < 0.98 then return end
    equal(storage.normal.completions, 1, "save contains a genuine unfinished second craft")
    equal(ledger().cumulative_ai_tokens, storage.saved_generated, "unfinished craft does not earn progress")
    storage.saved_tick, storage.stage = game.tick, "reload"
    report("ai_accounting_passed", {generated = storage.saved_generated,
      native_generated = storage.events.player, pending_bonus = 2,
      other_force_generated = 100000, platforms = 2, packaging_datasets = 1,
      datasets_extracted_by_inserter = 18, native_milestone_unlocked = true})
    game.server_save("bitermotors-ai-reload")
    return
  end
  if not storage.productivity_seeded and storage.productivity.machine.crafting_progress > 0 then
    storage.productivity_seeded = true
    -- Exercise a native bonus-craft event without changing recipe time/output.
    storage.productivity.machine.bonus_progress = 1
  end
  if not storage.blocked_checked and elapsed >= 600 then
    storage.blocked_checked = true
    equal(storage.blocked.completions, 0, "full output does not complete computation")
    equal(ledger(storage.fake_stats).cumulative_ai_tokens, 0, "statistics alone do not earn computation")
    equal(ledger(storage.fake_stats).agi.unlocked, false, "injected item statistics cannot unlock AGI")
    output(storage.blocked.machine).clear()
  end
  local ready = storage.blocked_checked and storage.productivity_seeded
  for _, row in ipairs(storage.tasks) do
    if row.kind ~= "pack" and row.kind ~= "capital" then
      local target = row.kind == "switch" and 2 or 1
      ready = ready and row.completions >= target
    end
  end
  if not ready then return end
  if not storage.pack_started then
    storage.pack_started = true
    local grid = storage.tasks[10]
    equal(output(grid.machine).get_item_count(TOKEN), 50000, "grid-scale physical token batch")
    equal(input(storage.pack.machine).insert{name = TOKEN, count = output(grid.machine).remove{name = TOKEN, count = 50000}},
      50000, "earned Tokens supplied to ordinary packaging")
    storage.before_pack = ledger().cumulative_ai_tokens
    return
  end
  if output(storage.pack.machine).get_item_count(DATASET) ~= 1
    or output(storage.capital.machine).get_item_count("bitermotors-capital-allocation") ~= 1 then return end
  if not storage.milestone_started then
    equal(ledger().cumulative_ai_tokens, storage.before_pack, "packaging does not earn another compute event")
    equal(game.forces.player.technologies["bitermotors-orbital-cluster-training"].enabled,
      false, "less than a million orbital equivalents leaves first milestone locked")
    storage.milestone_started = true
    input(storage.tasks[13].machine).insert{name = DOLLAR, count = 8}
    return
  end
  if storage.tasks[13].completions < 9 then return end
  if storage.payload_chest.get_inventory(defines.inventory.chest).get_item_count(DATASET) < 18 then return end
  local progress = ledger()
  equal(storage.normal.completions, 1, "one base terrestrial craft")
  equal(output(storage.normal.machine).get_item_count(TOKEN), 22, "10% research bonus is physical")
  equal(output(storage.rare.machine).get_item_count{name = TOKEN, quality = "rare"}, 22, "rare bonus retains quality")
  equal(output(storage.rare.machine).get_item_count{name = TOKEN, quality = "normal"}, 0, "rare research does not downgrade tokens")
  check(storage.productivity.native_bonus > 0, "native productivity event exercised")
  equal(output(storage.productivity.machine).get_item_count(TOKEN), 42, "research and native productivity do not compound twice")
  equal(progress.terrestrial.native_generated, storage.events.player - progress.orbital.native_generated,
    "track-local terrestrial native events reconcile")
  equal(progress.cumulative_ai_tokens, storage.events.player + 6, "only three delivered research bonuses count")
  equal(progress.cumulative_ai_tokens, storage.before_pack + 800000, "only additional native Dataset compute earns progress")
  equal(game.forces.player.technologies["bitermotors-orbital-cluster-training"].enabled,
    true, "genuine native Dataset computation unlocks orbital milestone")
  equal(progress.terrestrial.pending_bonus, 2, "blocked bonus remains pending at checkpoint")
  equal(ledger(game.forces["ai-second-force"]).cumulative_ai_tokens, 100000, "other platform/force earns its own equivalents")
  equal(output(storage.other.machine).get_item_count(DATASET), 2, "hyperscale direct payload is physical")
  equal(progress.agi.unlocked, false, "partial native computation cannot unlock final training")
  storage.other.machine.surface.platform.destroy(1)
  storage.other_platform_removed = true
  local statistics = game.forces.player.get_item_production_statistics(game.surfaces.nauvis)
  statistics.set_input_count(TOKEN, 0)
  equal(ledger().cumulative_ai_tokens, progress.cumulative_ai_tokens, "statistics reset does not erase earned compute")
  storage.saved_generated = progress.cumulative_ai_tokens
  storage.checkpoint_started = true
  input(storage.normal.machine).insert{name = DOLLAR, count = 20}
end

local loaded = false
script.on_load(function() loaded = storage.stage == "reload" end)
script.on_event(defines.events.on_tick, function()
  if loaded and storage.stage == "reload" and game.tick > storage.saved_tick then
    if not storage.reload_cleared then
      equal(ledger().cumulative_ai_tokens, storage.saved_generated, "native reload does not replay completions")
      equal(ledger().terrestrial.pending_bonus, 2, "pending bonus survives native save/reload")
      output(storage.pending.machine).clear()
      storage.reload_cleared = true
      return
    end
    if ledger().cumulative_ai_tokens < storage.saved_generated + 24 then return end
    equal(ledger().cumulative_ai_tokens, storage.saved_generated + 24, "saved bonus and second native craft materialize exactly once")
    equal(output(storage.pending.machine).get_item_count(TOKEN), 2, "saved bonus has physical output")
    equal(ledger().terrestrial.pending_bonus, 0, "no pending liability after delivery")
    equal(storage.normal.completions, 2, "recipe event subscriptions survive reload")
    equal(output(storage.normal.machine).get_item_count(TOKEN), 44, "second native craft and research bonus are physical")
    equal(storage.other.machine.valid, false, "other platform deletion completed before reload")
    equal(ledger(game.forces["ai-second-force"]).cumulative_ai_tokens, 100000,
      "platform removal does not erase already computed equivalents")
    report("ai_reload_passed", {saved_tick = storage.saved_tick, generated = ledger().cumulative_ai_tokens})
    storage.stage = "done"
    return
  end
end)
script.on_nth_tick(30, function()
  if storage.stage ~= "native" or game.tick <= storage.started then return end
  assert(game.tick - storage.started < 24000, "native AI fixture timed out: " .. helpers.table_to_json{
    tasks = (function()
      local rows = {}
      for _, row in ipairs(storage.tasks) do
        rows[#rows + 1] = {recipe = row.recipe, completions = row.completions, kind = row.kind,
          valid = row.machine.valid, status = row.machine.valid and row.machine.status or nil,
          finished = row.machine.valid and row.machine.products_finished or nil}
      end
      return rows
    end)(), ledger = ledger(), payload = storage.payload_chest.get_inventory(defines.inventory.chest).get_contents(),
    inserter = {status = storage.payload_inserter.status, pickup = storage.payload_inserter.pickup_position,
      drop = storage.payload_inserter.drop_position}
  })
  native_step()
end)
