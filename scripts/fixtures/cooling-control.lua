local REPORT = "bitermotors-cooling.jsonl"
local DOLLAR, TOKEN = "bitermotors-dollar", "bitermotors-ai-token"
local CORE, RADIATOR = "bitermotors-orbital-datacenter-core", "bitermotors-orbital-radiator-panel"
local RECIPE = "bitermotors-orbital-ai-token"

local function check(value, label)
  assert(value, label)
  storage.assertions = (storage.assertions or 0) + 1
end

local function equal(actual, expected, label)
  check(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function report(status, row)
  row = row or {}
  row.status, row.tick, row.assertions = status, game.tick, storage.assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function ledger(force) return remote.call("bitermotors", "endgame_status", force.name) end
local function input(machine) return machine.get_inventory(defines.inventory.crafter_input) end
local function output(machine) return machine.get_inventory(defines.inventory.crafter_output) end
local function count(inventory, name, quality)
  return inventory.get_item_count{name = name, quality = quality or "normal"}
end

local function core_status(machine)
  for _, row in ipairs(ledger(machine.force).cores) do
    if row.unit_number == machine.unit_number then
      equal(row.work_policy, "banked", "orbital policy is banked")
      equal(type(row.power_limited), "boolean", "native power status is explicit")
      equal(type(row.paused_for_cooling), "boolean", "cooling pause status is explicit")
      equal(row.reset_for_power, nil, "obsolete power reset key absent")
      equal(row.reset_for_cooling, nil, "obsolete cooling reset key absent")
      equal(row.power_limited, machine.status == defines.entity_status.no_power
        or machine.status == defines.entity_status.low_power, "power_limited reflects native status")
      return row
    end
  end
  error("core missing from live status")
end

local function make(surface, name, position, force)
  return assert(surface.create_entity{name = name, position = position, force = force, raise_built = true}, name)
end

local function power(surface, force, position, watts)
  local source = make(surface, "electric-energy-interface", position, force)
  source.electric_interface_mode = defines.electric_interface_mode.primary_output
  source.power_production, source.output_flow_limit = watts / 60, watts / 60
  return source
end

local function replace_power(watts)
  if storage.source and storage.source.valid then storage.source.destroy{raise_destroy = true} end
  storage.source = watts and power(storage.surface, storage.force, {0, 12}, watts) or nil
end

local function platform(force, name)
  local value = force.create_space_platform{name = name, planet = "nauvis",
    starter_pack = "space-platform-starter-pack"}
  check(value.apply_starter_pack(true) ~= nil, "native starter hub applied")
  -- Isolate supplied EEI power: radiator solar trickle must not mask a full outage.
  value.surface.solar_power_multiplier = 0
  local tiles = {}
  for x = -64, 64 do
    for y = -48, 48 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
  end
  value.surface.set_tiles(tiles, false, false, false, true)
  return value.surface
end

local function core(surface, force, position, quality)
  force.recipes[RECIPE].enabled = true
  local machine = make(surface, CORE, position, force)
  machine.set_recipe(RECIPE, quality or "normal")
  return machine
end

local function change_stage(name)
  storage.stage, storage.since = name, game.tick
end

local function no_earnings(machine, generated)
  equal(machine.products_finished, 0, "interruption cannot finish native batch")
  equal(ledger(storage.force).orbital.generated, generated or 0, "interruption earns no orbital compute")
end

local function original_committed(machine, quality)
  equal(count(input(machine), DOLLAR, quality), 0, "only original Dollar is already committed")
end

script.on_init(function()
  game.tick_paused, game.speed = false, 100
  storage.started = game.tick
  storage.events = {}
  storage.force = game.forces.player
  storage.force.technologies["bitermotors-orbital-compute"].researched = true
  storage.surface = platform(storage.force, "Cooling validation A")
  storage.first = core(storage.surface, storage.force, {-30, 12})
  storage.second = core(storage.surface, storage.force, {20, 12}, "rare")
  replace_power(10000000000)
  storage.other_force = game.create_force("cooling-validation-other")
  storage.other_force.technologies["bitermotors-orbital-compute"].researched = true
  storage.other_surface = platform(storage.force, "Cooling validation B")
  storage.other_core = core(storage.other_surface, storage.force, {0, 12})
  storage.other_source = power(storage.other_surface, storage.force, {0, 22}, 10000000000)
  storage.cross_force_core = core(storage.surface, storage.other_force, {0, -24})
  change_stage("zero_cooling")
end)

local function advance()
  local tick, force, first = game.tick, storage.force, storage.first
  if tick <= storage.started then return end
  if tick - storage.started > 45000 then
    error("cooling fixture timeout: " .. helpers.table_to_json{
      stage = storage.stage, progress = first.crafting_progress, energy = first.energy,
      native_status = first.status, core = core_status(first)})
  end
  local elapsed = tick - storage.since
  if storage.stage == "zero_cooling" then
    if elapsed < 120 then return end
    local own, other = ledger(force).cooling, ledger(storage.other_force).cooling
    equal(own.cores, 3, "player cores span two platforms")
    equal(own.cooled_cores, 0, "zero radiators cool zero cores")
    equal(other.cores, 1, "second force counted independently")
    for _, machine in ipairs({first, storage.second, storage.other_core, storage.cross_force_core}) do
      local row = core_status(machine)
      check(row.paused_for_cooling and machine.disabled_by_script, "missing cooling pauses before first craft")
      equal(machine.crafting_progress, 0, "unstarted core has no progress")
    end
    equal(input(first).insert{name = DOLLAR, count = 1}, 1, "supply exactly one original orbital Dollar")
    change_stage("unstarted_hold")
  elseif storage.stage == "unstarted_hold" then
    if elapsed < 120 then return end
    equal(count(input(first), DOLLAR), 1, "uncooled unstarted batch leaves Dollar uncommitted")
    no_earnings(first)
    storage.panel = make(storage.surface, RADIATOR, {-56, 32}, force)
    change_stage("allocation")
  elseif storage.stage == "allocation" then
    if elapsed < 120 then return end
    equal(ledger(force).cooling.cooled_cores, 1, "one radiator cools exactly one core")
    check(core_status(first).cooled, "oldest unit-number core wins deterministic capacity")
    check(not core_status(storage.second).cooled, "newer core waits for capacity")
    check(not core_status(storage.other_core).cooled, "platform isolation")
    check(not core_status(storage.cross_force_core).cooled, "same-surface force isolation")
    equal(ledger(storage.other_force).cooling.cooled_cores, 0, "force cooling isolation")
    local transient = core(storage.surface, force, {0, -12})
    equal(ledger(force).cooling.cores, 4, "new core is registered for cooling demand")
    transient.destroy{raise_destroy = true}
    equal(ledger(force).cooling.cores, 3, "removed core leaves cooling demand")
    check(first.crafting_progress > 0, "real native batch starts with one radiator")
    original_committed(first)
    storage.before_cooling = first.crafting_progress
    storage.panel.destroy{raise_destroy = true}
    report("cooling_policy_passed", {platforms = 2, zero_vs_one = true,
      capacity_scope = "surface+force", before_first_craft_paused = true, work_policy = "banked",
      supplied_power_fixture = true, solar_power_multiplier = 0})
    change_stage("cooling_pause")
  elseif storage.stage == "cooling_pause" then
    local row = core_status(first)
    if not row.paused_for_cooling then return end
    check(first.disabled_by_script, "cooling uses a script pause")
    check(first.crafting_progress >= storage.before_cooling, "cooling never cancels active progress")
    storage.paused_progress = first.crafting_progress
    change_stage("cooling_hold")
  elseif storage.stage == "cooling_hold" then
    if elapsed < 120 then return end
    equal(first.crafting_progress, storage.paused_progress, "cooling pause preserves positive progress")
    original_committed(first)
    no_earnings(first)
    storage.panel = make(storage.surface, RADIATOR, {-56, 32}, force)
    change_stage("cooling_resume")
  elseif storage.stage == "cooling_resume" then
    if core_status(first).paused_for_cooling or first.crafting_progress <= storage.paused_progress then return end
    original_committed(first)
    local inventory = output(first)
    equal(inventory.insert{name = TOKEN, count = #inventory * prototypes.item[TOKEN].stack_size},
      #inventory * prototypes.item[TOKEN].stack_size, "fill every output slot to block native completion")
    change_stage("blocked_output")
  elseif storage.stage == "blocked_output" then
    if elapsed < 2400 then return end
    no_earnings(first)
    equal(first.status, defines.entity_status.full_output, "native output is genuinely blocked")
    output(first).clear()
    change_stage("base_completion")
  elseif storage.stage == "base_completion" then
    if first.products_finished == 0 then return end
    equal(first.products_finished, 1, "cooling-resumed original batch completes once")
    equal(storage.events[first.unit_number], 1, "base earned batch has one native completion event")
    equal(count(output(first), TOKEN), 10000, "base completion produces physical Tokens")
    equal(ledger(force).orbital.generated, 10000, "base native completion earns exactly its physical batch")
    original_committed(first)
    -- The rare batch is the sole active load during measured power trials.
    storage.second.destroy{raise_destroy = true}
    storage.second = core(storage.surface, force, {20, 12}, "rare")
    storage.rare_panel = make(storage.surface, RADIATOR, {40, 32}, force)
    equal(input(storage.second).insert{name = DOLLAR, quality = "rare", count = 1}, 1,
      "supply exactly one original rare Dollar, never replacement inputs")
    change_stage("full_rate_start")
  elseif storage.stage == "full_rate_start" then
    local machine = storage.second
    if machine.crafting_progress < 0.05 then return end
    original_committed(machine, "rare")
    storage.full_start = machine.crafting_progress
    change_stage("full_rate")
  elseif storage.stage == "full_rate" then
    if elapsed < 120 then return end
    storage.full_rate = (storage.second.crafting_progress - storage.full_start) / elapsed
    check(storage.full_rate > 0, "full power gives positive native progress")
    storage.before_half = storage.second.crafting_progress
    replace_power(125000000)
    change_stage("half_settle")
  elseif storage.stage == "half_settle" then
    if elapsed < 180 then return end
    local row = core_status(storage.second)
    check(row.power_limited, "half-power is reported as native power limited")
    check(not row.paused_for_cooling and not storage.second.disabled_by_script, "power is not a script hold")
    check(storage.second.crafting_progress >= storage.before_half, "half-power never cancels progress")
    storage.half_start = storage.second.crafting_progress
    change_stage("half_measure")
  elseif storage.stage == "half_measure" then
    if elapsed < 120 then return end
    local machine = storage.second
    storage.half_rate = (machine.crafting_progress - storage.half_start) / elapsed
    check(storage.half_rate > 0 and storage.half_rate < storage.full_rate * 0.8,
      "half-power gives slower positive native progress without cancellation")
    no_earnings(machine, 10000)
    original_committed(machine, "rare")
    storage.before_outage = machine.crafting_progress
    replace_power(nil)
    change_stage("outage_settle")
  elseif storage.stage == "outage_settle" then
    if elapsed < 180 then return end
    local machine, row = storage.second, core_status(storage.second)
    check(row.power_limited and not machine.disabled_by_script, "full outage is native, not script held")
    check(machine.crafting_progress >= storage.before_outage, "outage does not cancel active progress")
    storage.outage_progress = machine.crafting_progress
    check(storage.outage_progress > 0, "outage banks positive native progress")
    change_stage("outage_hold")
  elseif storage.stage == "outage_hold" then
    if elapsed < 180 then return end
    equal(storage.second.crafting_progress, storage.outage_progress, "full outage holds identical positive progress")
    no_earnings(storage.second, 10000)
    original_committed(storage.second, "rare")
    storage.saved_tick = tick
    change_stage("power_checkpoint")
    game.server_save("bitermotors-cooling-failure")
    report("cooling_checkpoint", {saved_tick = tick, saved_file = "bitermotors-cooling-failure.zip",
      failure = "native_total_power", work_policy = "banked", power_limited = true,
      paused_for_cooling = false, progress = storage.outage_progress, generated = 10000,
      products = 0, output = 0, quality = "rare", dollars_supplied = 1, dollars_remaining = 0,
      replacement_dollars = 0, full_rate = storage.full_rate, half_rate = storage.half_rate,
      cooling_progress_preserved = true, blocked_output_generated = 0,
      base_products = first.products_finished, base_output = count(output(first), TOKEN),
      base_events = storage.events[first.unit_number]})
  elseif storage.stage == "reload_completion" then
    local machine = storage.second
    check(machine.crafting_progress >= storage.outage_progress or machine.products_finished == 1,
      "resume retains the banked native progress until completion")
    if machine.products_finished == 0 then return end
    equal(machine.products_finished, 1, "recovered native batch completes exactly once after reload")
    equal(storage.events[machine.unit_number], 1, "rare batch has one native completion event")
    equal(count(output(machine), TOKEN, "rare"), 10000, "new rare physical batch after reload")
    equal(ledger(force).orbital.generated, 20000, "exactly one new earned batch after reload")
    original_committed(machine, "rare")
    change_stage("reload_no_duplicate")
  elseif storage.stage == "reload_no_duplicate" then
    if elapsed < 2400 then return end
    equal(storage.second.products_finished, 1, "no duplicate completion without replacement Dollar")
    equal(count(output(storage.second), TOKEN, "rare"), 10000, "rare output remains exactly one batch")
    equal(ledger(force).orbital.generated, 20000, "no duplicate earned compute")
    equal(ledger(storage.other_force).orbital.generated, 0, "other-force earned ledger isolated")
    report("orbital_banked_reload_passed", {saved_tick = storage.saved_tick, work_policy = "banked",
      progress_after_reload = storage.reload_progress, replacement_dollars = 0,
      dollars_supplied = 1, dollars_remaining = 0, quality = "rare", recovered_products = 1,
      recovery_output_delta = 10000, recovery_ledger_delta = 10000, generated = 20000,
      native_events = storage.events[storage.second.unit_number]})
    storage.other_surface.platform.destroy(1)
    change_stage("platform_removal")
  elseif storage.stage == "platform_removal" then
    if storage.other_surface.valid then return end
    equal(ledger(force).cooling.cores, 2, "deleted platform removes its cooling demand")
    equal(ledger(force).cooling.radiators, 2, "deleted platform removes its radiators")
    equal(ledger(force).orbital.generated, 20000, "platform removal preserves earned compute")
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({0, 0}, 2)
    surface.force_generate_chunk_requests()
    local tiles = {}
    for x = -10, 20 do
      for y = -10, 20 do tiles[#tiles + 1] = {name = "concrete", position = {x, y}} end
    end
    surface.set_tiles(tiles)
    for _, entity in pairs(surface.find_entities_filtered{
      area = {{-10, -10}, {20, 20}}, type = {"tree", "simple-entity"}}) do entity.destroy() end
    storage.ground = make(surface, "bitermotors-terrestrial-datacenter", {0, 0}, force)
    force.recipes["bitermotors-terrestrial-ai-token"].enabled = true
    storage.ground.set_recipe("bitermotors-terrestrial-ai-token")
    make(surface, "substation", {4, 4}, force)
    storage.ground_source = power(surface, force, {8, 0}, 100000000)
    equal(input(storage.ground).insert{name = DOLLAR, count = 20}, 20, "original terrestrial operating20")
    change_stage("ground_start")
  elseif storage.stage == "ground_start" then
    if storage.ground.crafting_progress < 0.05 then return end
    equal(count(input(storage.ground), DOLLAR), 0, "terrestrial original20 committed")
    storage.ground_source.destroy{raise_destroy = true}
    storage.ground_source = power(game.surfaces.nauvis, force, {8, 0}, 4000000)
    change_stage("ground_failure")
  elseif storage.stage == "ground_failure" then
    if elapsed < 240 then return end
    equal(storage.ground.crafting_progress, 0, "terrestrial low-power still cancels batch")
    equal(count(input(storage.ground), DOLLAR), 0, "canceled terrestrial operating20 are scrapped")
    equal(storage.ground.products_finished, 0, "failure has no terrestrial completion")
    equal(count(output(storage.ground), TOKEN), 0, "failure has no physical terrestrial output")
    equal(ledger(force).terrestrial.generated, 0, "terrestrial failure ledger0")
    storage.ground_source.destroy{raise_destroy = true}
    storage.ground_source = power(game.surfaces.nauvis, force, {8, 0}, 100000000)
    change_stage("ground_without_replacement")
  elseif storage.stage == "ground_without_replacement" then
    if elapsed < 2400 then return end
    equal(storage.ground.products_finished, 0, "restored terrestrial power cannot finish scrapped batch")
    equal(storage.ground.crafting_progress, 0, "no retained terrestrial committed batch")
    equal(ledger(force).terrestrial.generated, 0, "restored power alone still earns nothing")
    equal(input(storage.ground).insert{name = DOLLAR, count = 20}, 20, "newly supplied terrestrial retry20")
    change_stage("ground_retry")
  elseif storage.stage == "ground_retry" then
    if storage.ground.products_finished == 0 then return end
    equal(storage.ground.products_finished, 1, "new terrestrial retry succeeds once")
    equal(storage.events[storage.ground.unit_number], 1, "only retry emits native terrestrial completion")
    equal(count(output(storage.ground), TOKEN), 20, "retry produces physical terrestrial20")
    equal(count(input(storage.ground), DOLLAR), 0, "retry spends newly supplied20")
    equal(ledger(force).terrestrial.generated, 20, "only retry earns terrestrial20")
    report("terrestrial_scrap_passed", {original_dollars = 20, scrapped_dollars = 20,
      failure_generated = 0, restored_without_inputs_products = 0, retry_dollars = 20,
      retry_products = 1, retry_output = 20, retry_generated = 20,
      native_events = storage.events[storage.ground.unit_number]})
    report("cooling_reload_passed", {saved_tick = storage.saved_tick, work_policy = "banked",
      orbital_generated = 20000, terrestrial_generated = 20, platform_removal = true,
      separate_process_reload = true})
    change_stage("done")
  end
end

local loaded = false
script.on_load(function() loaded = storage.stage == "power_checkpoint" end)
script.on_event(defines.events.on_tick, function()
  if storage.stage == "done" then return end
  if storage.stage == "power_checkpoint" then
    if not loaded or game.tick <= storage.saved_tick then return end
    local machine, row = storage.second, core_status(storage.second)
    check(row.power_limited and not row.paused_for_cooling, "native outage state survives reload")
    check(not machine.disabled_by_script, "power remains native after reload")
    equal(machine.crafting_progress, storage.outage_progress, "same positive progress survives separate-process reload")
    no_earnings(machine, 10000)
    original_committed(machine, "rare")
    storage.reload_progress = machine.crafting_progress
    replace_power(10000000000)
    change_stage("reload_completion")
    return
  end
  if game.tick % 30 == 0 then advance() end
end)

for _, recipe in ipairs({RECIPE, "bitermotors-terrestrial-ai-token"}) do
  script.on_event(prototypes.recipe[recipe].on_crafted_event, function(event)
    check(not event.bonus, "fixture has no productivity bonus completions")
    storage.events[event.entity.unit_number] = (storage.events[event.entity.unit_number] or 0) + 1
  end)
end
