local REPORT = "bitermotors-finale.jsonl"
local CONTROLLER = "bitermotors-planetary-grid-controller"
local RECIPE = "bitermotors-agi-training-run"
local MODEL = "bitermotors-agi-model"
local CORE = "bitermotors-orbital-datacenter-core"
local COMPUTE = "bitermotors-orbital-ai-dataset-hyperscale"
local DATASET = "bitermotors-agi-training-dataset"
local RUN_TICKS = 72000
local POWER = 10000000000
local assertions = 0
local loaded = false

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

local function agi(force)
  return remote.call("bitermotors", "endgame_status", (force or game.forces.player).name).agi
end

local function input(machine) return machine.get_inventory(defines.inventory.crafter_input) end
local function output(machine) return machine.get_inventory(defines.inventory.crafter_output) end

local function make(surface, name, position, force, quality)
  return assert(surface.create_entity{name = name, position = position, force = force,
    quality = quality or "normal", raise_built = true}, "could not create " .. name)
end

local function supply(surface, position, force, land)
  local source = make(surface, "electric-energy-interface", {position[1] - 4, position[2] + 4}, force)
  source.electric_interface_mode = defines.electric_interface_mode.primary_output
  source.power_production, source.output_flow_limit = 1000000000000, 1000000000000
  local pole = land and make(surface, "substation", {position[1] + 4, position[2] + 4}, force) or nil
  return source, pole
end

local function build_compute_platform(force, name)
  local platform = force.create_space_platform{name = name, planet = "nauvis",
    starter_pack = "space-platform-starter-pack"}
  check(platform.apply_starter_pack(true) ~= nil, "native platform hub")
  local surface, tiles = platform.surface, {}
  for x = -112, 112 do
    for y = -64, 112 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
  end
  surface.set_tiles(tiles, false, false, false, true)
  supply(surface, {-96, -48}, force, false)
  for i = 1, 256 do
    make(surface, "bitermotors-orbital-radiator-panel",
      {-100 + ((i - 1) % 32) * 6, 48 + math.floor((i - 1) / 32) * 6}, force)
  end
  for i = 1, 32 do
    local machine = make(surface, CORE,
      {-90 + ((i - 1) % 16) * 12, -16 + math.floor((i - 1) / 16) * 18}, force, "legendary")
    machine.set_recipe(COMPUTE)
    equal(input(machine).insert{name = "bitermotors-dollar", count = 200}, 200, "compute operating capital")
    storage.cores[#storage.cores + 1] = machine
  end
end

local function add_case(surface, spec, index)
  local force, x = game.forces.player, -192 + (index - 1) * 48
  local machine = make(surface, CONTROLLER, {x, 0}, force, spec.quality)
  local source, pole = supply(surface, {x, 0}, force, true)
  local row = {label = spec.label, quality = spec.quality, mode = spec.mode,
    machine = machine, source = source, pole = pole, completions = 0}
  storage.cases[#storage.cases + 1] = row
  storage.by_unit[machine.unit_number] = row
  if spec.module then
    local beacon = make(surface, "beacon", {x + 4, 0}, force)
    equal(beacon.get_module_inventory().insert{name = spec.module, count = 2}, 2, "native beacon modules")
    row.witness = make(surface, "assembling-machine-3", {x, -4}, force)
    row.beacon = beacon
  end
  if spec.mode == "local" then machine.local_effect = {speed = 10, consumption = -0.8} end
  if spec.mode == "inserter" then
    row.chest = make(surface, "steel-chest", {x, 3}, force)
    row.inserter = make(surface, "fast-inserter", {x, 2}, force)
    row.inserter.direction = defines.direction.north
  end
  return row
end

script.on_init(function()
  game.tick_paused, game.speed = false, 100
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
  storage.cores, storage.cases, storage.by_unit = {}, {}, {}
  storage.stage, storage.started = "compute", game.tick
  local force, land = game.forces.player, game.surfaces.nauvis
  for _, name in ipairs({"bitermotors-orbital-compute", "bitermotors-orbital-cluster-training",
    "bitermotors-grid-scale-energy", "bitermotors-hyperscale-training", "bitermotors-planetary-energy-grid"}) do
    force.technologies[name].researched = true
  end
  force.recipes[COMPUTE].enabled = true
  land.request_to_generate_chunks({0, 0}, 9)
  land.force_generate_chunk_requests()
  for _, entity in pairs(land.find_entities_filtered{area = {{-240, -48}, {288, 96}}}) do entity.destroy() end
  local tiles = {}
  for x = -240, 288 do
    for y = -48, 96 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
  end
  land.set_tiles(tiles)
  for i, spec in ipairs({
    {label = "normal extraction", quality = "normal", mode = "extract"},
    {label = "uncommon recipe change", quality = "uncommon", mode = "switch"},
    {label = "rare removal", quality = "rare", mode = "remove"},
    {label = "epic native inserter", quality = "epic", mode = "inserter"},
    {label = "legendary", quality = "legendary"},
    {label = "speed beacon", quality = "normal", module = "speed-module-3"},
    {label = "efficiency beacon", quality = "normal", module = "efficiency-module-3"},
    {label = "brownout recovery", quality = "normal", mode = "brownout"},
    {label = "local effects", quality = "legendary", mode = "local"},
    {label = "failed-state reload", quality = "normal", mode = "reload-brownout"}
  }) do add_case(land, spec, i) end
  local fake = make(land, CONTROLLER, {-192, 48}, force)
  supply(land, {-192, 48}, force, true)
  fake.set_recipe(RECIPE)
  equal(output(fake).insert{name = MODEL, count = 1}, 1, "negative Model insertion")
  storage.fake = fake
  build_compute_platform(force, "Finale earned compute A")
  build_compute_platform(force, "Finale earned compute B")
end)

script.on_load(function() loaded = true end)

script.on_event(prototypes.recipe[RECIPE].on_crafted_event, function(event)
  local row = storage.by_unit and storage.by_unit[event.entity.unit_number]
  if not row then return end
  equal(event.recipe, RECIPE, "genuine final recipe completion")
  equal(event.bonus, false, "one base Model, not a productivity bonus")
  check(row.first_progress_tick ~= nil, "actual native progress was observed")
  row.duration_ticks = game.tick - row.first_progress_tick + 1
  check(row.duration_ticks >= RUN_TICKS - 1 and row.duration_ticks <= RUN_TICKS + 1,
    row.label .. " complete native duration " .. tostring(row.duration_ticks))
  row.total_joules = row.pole.electric_network_statistics.get_input_count{
    name = CONTROLLER, quality = row.quality
  } - row.start_joules
  check(math.abs(row.total_joules - POWER * 1200) <= POWER / 60 * 2,
    row.label .. " full-run energy " .. tostring(row.total_joules))
  equal(output(row.machine).get_item_count(MODEL), 1, row.label .. " physical Model exists")
  row.completions = row.completions + 1
  equal(row.completions, 1, "no duplicate recipe completion")
  local state = agi()
  equal(state.completed, true, "completion has already latched victory (energy "
    .. tostring(row.machine.energy) .. "/" .. tostring(row.machine.electric_buffer_size)
    .. ", status " .. tostring(row.machine.status) .. ")")
  equal(state.victory.source, "native-training-completion", "native victory provenance")
  if not storage.first_victory then
    equal(game.finished, true, "native victory sets game finished")
    storage.first_victory = state.victory
    -- Rehearse the player's Continue action; victory storage must remain latched.
    game.set_game_state{game_finished = false, player_won = true, can_continue = true}
    game.tick_paused = false
  end
  if row.mode == "extract" then
    equal(output(row.machine).remove{name = MODEL, count = 1}, 1, "same-event immediate extraction")
  elseif row.mode == "remove" then
    row.machine.destroy{raise_destroy = true}
  elseif row.mode == "switch" then
    row.machine.set_recipe(nil)
  end
  equal(agi().victory.tick, storage.first_victory.tick, "parallel completions do not repeat victory")
end)

local function start_training()
  local force = game.forces.player
  local state = agi()
  check(state.cumulative_ai_tokens >= 1000000000, "one billion genuinely computed equivalents")
  equal(state.unlocked, true, "native compute opens final gate")
  equal(force.recipes[RECIPE].enabled, true, "final recipe enabled by earned gate")
  equal(state.completed, false, "inserted Model does not win after gate opens")
  local datasets = 0
  for _, core in ipairs(storage.cores) do
    datasets = datasets + output(core).get_item_count(DATASET)
  end
  check(datasets >= 20000, "physical final payload has genuinely been computed")
  storage.earned_equivalents, storage.computed_datasets = state.cumulative_ai_tokens, datasets
  local remaining = 20000
  for _, core in ipairs(storage.cores) do
    local removed = output(core).remove{name = DATASET, count = remaining}
    remaining = remaining - removed
    if remaining == 0 then break end
  end
  equal(remaining, 0, "earned payload withdrawn from compute outputs")
  equal(output(storage.fake).remove{name = MODEL, count = 1}, 1, "negative Model removed")
  storage.fake.destroy{raise_destroy = true}
  for index, row in ipairs(storage.cases) do
    equal(row.machine.set_recipe(RECIPE) ~= nil, true, "select final recipe")
    -- The first payload is earned above; replicas isolate time/power/quality, not campaign economics.
    for _, ingredient in ipairs(prototypes.recipe[RECIPE].ingredients) do
      equal(input(row.machine).insert{name = ingredient.name, count = ingredient.amount}, ingredient.amount,
        row.label .. " supplied " .. ingredient.name)
    end
  end
  storage.training_started, storage.stage = game.tick, "training"
end

local function training_step()
  local elapsed = game.tick - storage.training_started
  local all_done = true
  for _, row in ipairs(storage.cases) do
    if row.completions == 0 then
      all_done = false
      local machine = row.machine
      if machine.crafting_progress > 1e-9 and not row.first_progress_tick
        and not machine.disabled_by_script
        and (not row.cut_started or row.restored) then
        row.first_progress_tick = game.tick
        row.start_joules = row.pole.electric_network_statistics.get_input_count{
          name = CONTROLLER, quality = row.quality
        }
      end
      if not row.power_measured and row.first_progress_tick and elapsed > 120 then
        row.power_measured = true
        equal(machine.crafting_speed, 1, row.label .. " fixed speed")
        equal(machine.consumption_bonus, 0, row.label .. " fixed consumption")
        equal(machine.prototype.energy_usage * 60, POWER, row.label .. " native power prototype")
        row.power_sample_tick = game.tick
        -- Electric-network input is consumption, unlike item-production input.
        row.power_sample = row.pole.electric_network_statistics.get_input_count{
          name = CONTROLLER, quality = row.quality
        }
        if row.witness then
          if row.label == "speed beacon" then
            check(row.witness.speed_bonus > 0, "beacon actually boosts witness")
          else
            check(row.witness.consumption_bonus < 0, "beacon actually reduces witness power")
          end
        end
      elseif row.power_sample_tick and not row.measured_watts and game.tick >= row.power_sample_tick + 60 then
        row.measured_watts = row.pole.electric_network_statistics.get_input_count{
          name = CONTROLLER, quality = row.quality
        } - row.power_sample
        check(math.abs(row.measured_watts - POWER) < POWER * 0.00001,
          row.label .. " measured network consumption " .. tostring(row.measured_watts))
      end
      if row.mode == "brownout" then
        if not row.cut_started and elapsed >= 6000 then
          check(machine.crafting_progress > 0.05, "genuine partial run before brownout")
          row.cut_started, row.first_progress_tick = game.tick, nil
          row.source.power_production, row.source.output_flow_limit = POWER / 120, POWER / 120
          row.source.energy = 0
        elseif row.cut_started and not row.half_checked and game.tick >= row.cut_started + 30 then
          row.half_checked = true
          check(machine.crafting_progress > 0 and machine.crafting_progress < 1e-9,
            "half-power supply scraps training but retains native batch")
          equal(machine.disabled_by_script, true, "brownout holds controller for recovery")
          check(machine.custom_status ~= nil, "native GUI explains retained-input retry")
          equal(input(machine).get_item_count(DATASET), 0, "original payload is committed, not refunded")
          equal(machine.products_finished, 0, "brownout cannot produce a Model")
          row.source.power_production, row.source.output_flow_limit, row.source.energy = 0, 0, 0
        elseif row.half_checked and not row.total_checked and game.tick >= row.cut_started + 180 then
          row.total_checked = true
          check(machine.crafting_progress > 0 and machine.crafting_progress < 1e-9,
            "total loss retains effectively zero progress")
          equal(machine.products_finished, 0, "outage cannot complete")
          row.source.power_production, row.source.output_flow_limit = 1000000000000, 1000000000000
          row.restored, row.restore_tick = true, game.tick
        end
      elseif row.mode == "reload-brownout" and not row.cut_started and elapsed >= 68000 then
        check(machine.crafting_progress > 0.9, "failed-state fixture has genuine committed training")
        row.cut_started, row.first_progress_tick = game.tick, nil
        row.source.power_production, row.source.output_flow_limit, row.source.energy = 0, 0, 0
      end
      if row.restore_tick and not row.restart_checked and game.tick >= row.restore_tick + 120 then
        row.restart_checked = true
        check(machine.crafting_progress > 0.0001, row.label .. " native batch actually restarts")
        equal(input(machine).get_item_count(DATASET), 0, "retry needs no replacement payload")
      end
    end
  end
  if not storage.midrun_requested and elapsed >= 69000 then
    local machine = storage.cases[1].machine
    check(machine.crafting_progress > 0.9 and machine.crafting_progress < 1, "real near-completion checkpoint")
    equal(agi().completed, false, "unfinished real training cannot win")
    check(storage.cases[10].machine.crafting_progress > 0
      and storage.cases[10].machine.crafting_progress < 1e-9, "checkpoint includes failed-power state")
    equal(storage.cases[10].machine.disabled_by_script, true, "failed controller is held across checkpoint")
    storage.midrun_requested, storage.stage = true, "midrun"
    storage.saved_progress = machine.crafting_progress
    storage.midrun_tick = game.tick
    report("finale_checkpoint", {progress = storage.saved_progress, training_seconds = 1200,
      required_power_watts = POWER, earned_equivalents = storage.earned_equivalents,
      computed_datasets = storage.computed_datasets})
    game.speed = 1
    game.server_save("bitermotors-finale-midrun")
    return
  end
  if all_done then
    local cases = {}
    for _, row in ipairs(storage.cases) do
      equal(row.completions, 1, "every full-duration case completed once")
      cases[#cases + 1] = {label = row.label, quality = row.quality, duration_ticks = row.duration_ticks,
        measured_watts = row.measured_watts, total_joules = row.total_joules}
    end
    equal(storage.cases[8].half_checked, true, "partial power was exercised")
    equal(storage.cases[8].total_checked, true, "total outage was exercised")
    equal(storage.cases[4].chest.get_item_count(MODEL), 1, "native output inserter delivered physical Model")
    equal(output(storage.cases[4].machine).get_item_count(MODEL), 0, "native extraction cleared output")
    equal(output(storage.cases[8].machine).get_item_count(MODEL), 1, "recovered run used retained inputs")
    equal(agi().completed, true, "Model extraction/removal did not erase victory")
    storage.victory, storage.saved_tick, storage.stage = agi().victory, game.tick, "completed"
    equal(storage.victory.tick, storage.first_victory.tick, "continued play does not retrigger victory")
    report("finale_training_passed", {completion_cases = cases, training_seconds = 1200,
      required_power_watts = POWER, victory = storage.victory})
    game.speed = 1
    game.server_save("bitermotors-finale-completed")
  end
end

script.on_nth_tick(1, function()
  if game.tick <= storage.started then return end
  if loaded then
    loaded = false
    if storage.stage == "midrun" then
      local loaded_progress = storage.cases[1].machine.crafting_progress
      -- Server-save is asynchronous; account for the native ticks before it finishes.
      local expected_progress = storage.saved_progress + (game.tick - storage.midrun_tick) / RUN_TICKS
      check(math.abs(loaded_progress - expected_progress) < 0.000000001,
        "native midrun progress survives reload: " .. tostring(loaded_progress)
          .. " versus " .. tostring(expected_progress))
      equal(agi().completed, false, "midrun reload cannot invent victory")
      local failed = storage.cases[10]
      equal(failed.machine.disabled_by_script, true, "failed-power hold survives reload")
      check(failed.machine.crafting_progress > 0 and failed.machine.crafting_progress < 1e-9,
        "failed-power progress stays effectively zero after reload")
      equal(input(failed.machine).get_item_count(DATASET), 0, "failed-state committed inputs survive reload")
      failed.source.power_production, failed.source.output_flow_limit = 1000000000000, 1000000000000
      failed.restored, failed.restore_tick = true, game.tick
      storage.stage, game.speed = "training", 100
    elseif storage.stage == "completed" then
      equal(agi().completed, true, "victory survives native reload")
      equal(agi().victory.tick, storage.victory.tick, "victory tick is not replayed")
      equal(agi().victory.source, "native-training-completion", "native provenance survives reload")
      equal(agi().victory.training_seconds, 1200, "saved training contract")
      equal(agi().victory.required_power_watts, POWER, "saved power contract")
      equal(agi().cumulative_ai_tokens, storage.earned_equivalents, "earned compute survives reload")
      report("finale_reload_passed", {saved_tick = storage.saved_tick, victory = agi().victory})
      storage.stage = "done"
      return
    end
  end
  if not storage.policy_checked and game.tick >= storage.started + 60 then
    storage.policy_checked = true
    equal(prototypes.recipe[RECIPE].energy, 1200, "unshortened native training recipe")
    check(prototypes.recipe[RECIPE].on_crafted_event ~= nil, "native final completion event")
    equal(agi().completed, false, "an inserted Model is not a completed run")
    equal(game.finished, false, "insertion does not finish game")
    for _, row in ipairs(storage.cases) do
      equal(row.machine.crafting_speed, 1, row.label .. " native quality/effect speed")
      equal(row.machine.get_module_inventory() == nil or #row.machine.get_module_inventory() == 0,
        true, "zero final module slots")
    end
    report("finale_policy_passed")
  end
  if storage.stage == "compute" and game.tick % 60 == 0
    and agi().cumulative_ai_tokens >= 1000000000 then
    start_training()
    -- Retire compute without losing ledger or physical payload provenance.
    for _, core in ipairs(storage.cores) do core.destroy{raise_destroy = true} end
  elseif storage.stage == "training" then
    training_step()
  end
end)
