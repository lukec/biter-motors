local REPORT = "bitermotors-cooling.jsonl"
local DOLLAR = "bitermotors-dollar"
local CORE = "bitermotors-orbital-datacenter-core"
local RADIATOR = "bitermotors-orbital-radiator-panel"
local RECIPE = "bitermotors-orbital-ai-token"
local assertions = 0

local function check(value, label)
  assert(value, label)
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
  return remote.call("bitermotors", "endgame_status", force.name)
end

local function cooling(force)
  return ledger(force).cooling
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

local function platform(force, name)
  local value = force.create_space_platform{name = name, planet = "nauvis",
    starter_pack = "space-platform-starter-pack"}
  check(value.apply_starter_pack(true) ~= nil, "native starter hub applied")
  local surface = value.surface
  local tiles = {}
  for x = -64, 64 do
    for y = -48, 48 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
  end
  surface.set_tiles(tiles, false, false, false, true)
  return surface
end

local function core(surface, force, position)
  force.recipes[RECIPE].enabled = true
  local machine = make(surface, CORE, position, force)
  machine.set_recipe(RECIPE)
  return machine
end

local function radiators(surface, force, count, origin)
  local result = {}
  for index = 1, count do
    result[index] = make(surface, RADIATOR,
      {origin[1] + ((index - 1) % 8) * 8, origin[2] + math.floor((index - 1) / 8) * 8}, force)
  end
  return result
end

local function input(machine)
  return machine.get_inventory(defines.inventory.crafter_input)
end

local function output(machine)
  return machine.get_inventory(defines.inventory.crafter_output)
end

local function reserve(machine, amount)
  equal(input(machine).insert{name = DOLLAR, count = amount}, amount, "reserve replacement operating Dollars")
end

local function core_status(force, machine)
  for _, row in ipairs(ledger(force).cores) do
    if row.unit_number == machine.unit_number then return row end
  end
  error("core missing from live status: " .. tostring(machine.unit_number))
end

local function status_name(value)
  for name, code in pairs(defines.entity_status) do
    if code == value then return name end
  end
  return tostring(value)
end

local function replace_power(watts)
  if storage.source and storage.source.valid then storage.source.destroy{raise_destroy = true} end
  storage.source = watts and power(storage.surface, storage.player_force, {0, 12}, watts) or nil
end

script.on_init(function()
  game.tick_paused, game.speed = false, 100
  storage.stage, storage.started = "native", game.tick
  storage.player_force = game.forces.player
  storage.player_force.technologies["bitermotors-orbital-compute"].researched = true

  storage.surface = platform(storage.player_force, "Cooling validation A")
  storage.first = core(storage.surface, storage.player_force, {-30, 12})
  storage.second = core(storage.surface, storage.player_force, {20, 12})
  storage.source = power(storage.surface, storage.player_force, {0, 12}, 10000000000)
  storage.panels = radiators(storage.surface, storage.player_force, 16, {-56, 32})

  storage.other_force = game.create_force("cooling-validation-other")
  storage.other_force.technologies["bitermotors-orbital-compute"].researched = true
  storage.other_surface = platform(storage.player_force, "Cooling validation B")
  storage.other_core = core(storage.other_surface, storage.player_force, {0, 12})
  storage.other_source = power(storage.other_surface, storage.player_force, {0, 22}, 10000000000)
  storage.other_panels = radiators(storage.other_surface, storage.player_force, 7, {-28, 32})

  storage.cross_force_core = core(storage.surface, storage.other_force, {0, -24})
  storage.cross_force_panels = radiators(storage.surface, storage.other_force, 7, {-28, -44})
end)

local function advance()
  local tick = game.tick
  if tick <= storage.started then return end
  if tick - storage.started >= 30000 then
    local machine = storage.first and storage.first.valid and storage.first
    error("cooling fixture timeout: " .. helpers.table_to_json{
      stage = storage.stage, tick = tick, machine_status = machine and status_name(machine.status),
      energy = machine and machine.energy, buffer = machine and machine.electric_buffer_size,
      progress = machine and machine.crafting_progress,
      disabled = machine and machine.disabled_by_script,
      failed_for_power = machine and core_status(storage.player_force, machine).reset_for_power,
      machine_network = machine and machine.electric_network_id,
      source_production = storage.source and storage.source.power_production,
      source_limit = storage.source and storage.source.output_flow_limit,
      source_network = storage.source and storage.source.electric_network_id,
      source_count = #storage.surface.find_entities_filtered{name = "electric-energy-interface"}
    })
  end
  local force = storage.player_force
  local own, other = ledger(force), ledger(storage.other_force)

  if storage.stage == "native" then
    equal(cooling(force).cores, 3, "player-force cores span two platforms")
    equal(cooling(force).radiators, 23, "player-force radiator count")
    equal(cooling(force).cooled_cores, 2, "sixteen radiators cool two cores")
    equal(cooling(storage.other_force).cores, 1, "second-force core is independently counted")
    check(not core_status(force, storage.other_core).cooled,
      "seven radiators do not borrow cooling from the other platform")
    check(not core_status(storage.other_force, storage.cross_force_core).cooled,
      "radiators on another force do not cross-qualify same-surface core")
    equal(cooling(storage.other_force).cooled_cores, 0,
      "cooling allocation is grouped by surface and force")
    storage.transient_core = core(storage.surface, force, {0, -12})
    equal(cooling(force).cores, 4, "new core is registered for cooling demand")
    equal(cooling(force).cooled_cores, 2, "new core does not exceed available radiator capacity")
    check(not core_status(force, storage.transient_core).cooled, "newest core waits for a cooling slot")
    storage.second.destroy{raise_destroy = true}
    equal(cooling(force).cores, 3, "cooled core removal updates demand")
    check(core_status(force, storage.transient_core).cooled, "cooled core removal promotes the next core")
    storage.transient_core.destroy{raise_destroy = true}
    equal(cooling(force).cores, 2, "removed core leaves cooling demand")
    storage.second = core(storage.surface, force, {20, 12})
    equal(cooling(force).cooled_cores, 2, "removed core releases its deterministic slot")
    report("cooling_policy_passed", {platforms = 2, cores = 4, same_surface_force_isolation = true,
      seven_vs_eight = true, capacity_scope = "surface+force"})
    storage.panels[16].destroy{raise_destroy = true}
    storage.stage = "allocation"
    return
  end

  if storage.stage == "allocation" then
    equal(cooling(force).cooled_cores, 1, "fifteen radiators cool exactly one core")
    check(core_status(force, storage.first).cooled, "oldest unit-number core wins deterministic capacity")
    check(not core_status(force, storage.second).cooled, "newer core loses deterministic capacity")
    storage.panels[16] = make(storage.surface, RADIATOR, {58, 32}, force)
    storage.other_panels[8] = make(storage.other_surface, RADIATOR, {36, 32}, force)
    storage.cross_force_panels[8] = make(storage.surface, RADIATOR, {36, -44}, storage.other_force)
    storage.stage = "restore_capacity"
    return
  end

  if storage.stage == "restore_capacity" then
    equal(cooling(force).cooled_cores, 3, "restored radiators restore both platforms' capacity")
    check(core_status(force, storage.other_core).cooled,
      "eighth platform radiator cools same-force platform core")
    check(core_status(storage.other_force, storage.cross_force_core).cooled,
      "eighth same-surface radiator cools same-force-group core")
    reserve(storage.second, 4)
    storage.stage = "cooling_start"
    return
  end

  if storage.stage == "cooling_start" then
    if storage.second.crafting_progress <= 0 then return end
    storage.cooling_interrupted_progress = storage.second.crafting_progress
    storage.panels[1].destroy{raise_destroy = true}
    storage.stage = "cooling_failure"
    return
  end

  if storage.stage == "cooling_failure" then
    local failed = core_status(force, storage.second)
    if not failed.reset_for_cooling then return end
    check(storage.cooling_interrupted_progress > 0, "undercooling interrupted genuine active progress")
    equal(failed.crafting_progress, 0, "undercooling scraps active progress to exact zero")
    check(failed.disabled_by_script, "undercooling blocks output until recovery")
    reserve(storage.second, 2)
    storage.panels[1] = make(storage.surface, RADIATOR, {-56, 32}, force)
    storage.stage = "cooling_recovery"
    return
  end

  if storage.stage == "cooling_recovery" then
    if core_status(force, storage.second).reset_for_cooling then return end
    if storage.second.crafting_progress <= 0 then return end
    check(storage.second.crafting_progress > 0, "restored cooling resumes native craft with reserved Dollars")
    local blocked = output(storage.second)
    blocked.insert{name = "bitermotors-ai-token", count = #blocked
      * prototypes.item["bitermotors-ai-token"].stack_size}
    storage.blocked_started, storage.stage = tick, "blocked_output"
    return
  end

  if storage.stage == "blocked_output" then
    if tick - storage.blocked_started < 1800 then return end
    equal(storage.second.products_finished, 0, "blocked output does not complete a native craft")
    equal(own.orbital.generated, 0, "blocked output earns no compute ledger progress")
    output(storage.second).clear()
    storage.stage = "cooling_completion"
    return
  end

  if storage.stage == "cooling_completion" then
    if storage.second.products_finished < 1 then return end
    equal(storage.second.products_finished, 1, "cooled native craft completes once")
    equal(ledger(force).orbital.generated, 10000, "real cooled completion earns exact orbital equivalents")
    storage.second.set_recipe(nil)
    input(storage.second).clear()
    reserve(storage.first, 4)
    storage.stage = "power_start"
    return
  end

  if storage.stage == "power_start" then
    if storage.first.crafting_progress <= 0 then return end
    storage.power_interrupted_progress = storage.first.crafting_progress
    storage.power_completed_before_interrupt = storage.first.products_finished
    replace_power(125000000)
    storage.half_previous_progress = storage.first.crafting_progress
    storage.stage = "half_power"
    return
  end

  if storage.stage == "half_power" then
    local failed = core_status(force, storage.first)
    equal(failed.products_finished, storage.power_completed_before_interrupt,
      "half-power cannot finish native training")
    if storage.first.crafting_progress > 0 then
      storage.half_previous_progress = storage.first.crafting_progress
      return
    end
    if storage.half_previous_progress <= 0 then return end
    if not failed.reset_for_power then return end
    check(storage.power_interrupted_progress > 0, "half-power test interrupted genuine active progress")
    equal(failed.crafting_progress, 0, "125 MW supply scraps active progress")
    equal(failed.products_finished, storage.power_completed_before_interrupt,
      "half-power interruption does not earn a completion")
    reserve(storage.first, 2)
    replace_power(10000000000)
    storage.stage = "half_power_recovery"
    return
  end

  if storage.stage == "half_power_recovery" then
    if core_status(force, storage.first).reset_for_power then return end
    if storage.first.crafting_progress <= 0 then return end
    check(storage.first.crafting_progress > 0, "restored supply resumes compute after half-power reset")
    storage.power_interrupted_progress = storage.first.crafting_progress
    storage.power_completed_before_interrupt = storage.first.products_finished
    replace_power(nil)
    storage.outage_previous_progress = storage.first.crafting_progress
    storage.stage = "total_outage"
    return
  end

  if storage.stage == "total_outage" then
    local failed = core_status(force, storage.first)
    if storage.first.crafting_progress > 0 then
      storage.outage_previous_progress = storage.first.crafting_progress
      return
    end
    if storage.outage_previous_progress <= 0 or not failed.reset_for_power then return end
    check(storage.power_interrupted_progress > 0, "total outage interrupted genuine active progress")
    equal(failed.crafting_progress, 0, "total power loss scraps active progress")
    equal(failed.products_finished, storage.power_completed_before_interrupt,
      "total outage interruption does not earn a completion")
    check(failed.disabled_by_script, "total outage is held by script")
    storage.saved_generated = ledger(force).orbital.generated
    storage.saved_first_products = storage.first.products_finished
    storage.saved_first_output = output(storage.first).get_item_count("bitermotors-ai-token")
    storage.saved_tick, storage.stage = tick, "power_checkpoint"
    game.server_save("bitermotors-cooling-failure")
    report("cooling_checkpoint", {saved_tick = tick, saved_file = "bitermotors-cooling-failure.zip",
      failure = "total_power", generated = storage.saved_generated,
      first_products = storage.saved_first_products, first_output = storage.saved_first_output,
      dollars_reserved = 2})
    return
  end

  if storage.stage == "reload_recovery" then
    local failed = core_status(force, storage.first)
    if failed.reset_for_power then return end
    if storage.first.crafting_progress <= 0 then return end
    check(tick > storage.saved_tick, "recovery occurs on advancing post-reload tick")
    check(storage.first.crafting_progress > 0, "restored power and reserved Dollars restart native compute")
    storage.stage = "reload_completion"
    return
  end

  if storage.stage == "reload_completion" then
    if storage.first.products_finished <= storage.saved_first_products then return end
    equal(storage.first.products_finished, storage.saved_first_products + 1,
      "recovered native batch completes exactly once after reload")
    equal(output(storage.first).get_item_count("bitermotors-ai-token"), storage.saved_first_output + 10000,
      "recovered native completion adds physical orbital Tokens")
    equal(ledger(force).orbital.generated, storage.saved_generated + 10000,
      "recovery earns exactly one new native batch")
    equal(ledger(storage.other_force).orbital.generated, 0, "other-force ledger stays isolated")
    storage.recovered = {saved_tick = storage.saved_tick,
      generated = ledger(force).orbital.generated,
      recovered_products = storage.first.products_finished - storage.saved_first_products,
      recovered_output = output(storage.first).get_item_count("bitermotors-ai-token"),
      recovery_ledger_delta = ledger(force).orbital.generated - storage.saved_generated,
      recovery_output_delta = output(storage.first).get_item_count("bitermotors-ai-token") - storage.saved_first_output,
      platforms = 2, cooling_failure_reset = true, half_power_reset_and_recovery = true,
      total_power_failure_reset = true}
    storage.first.set_recipe(nil)
    input(storage.first).clear()
    storage.other_surface.platform.destroy(1)
    storage.stage = "platform_removal"
    return
  end

  if storage.stage == "platform_removal" then
    if storage.other_surface.valid then return end
    equal(cooling(force).cores, 2, "deleted platform removes its cooling demand")
    equal(cooling(force).radiators, 16, "deleted platform removes its radiators")
    equal(cooling(force).cooled_cores, 2, "remaining platform preserves independent cooling")
    equal(ledger(force).orbital.generated, storage.recovered.generated, "platform removal cannot erase earned compute")
    storage.recovered.platform_removal = true
    report("cooling_reload_passed", storage.recovered)
    storage.stage = "done"
  end
end

local loaded = false
script.on_load(function() loaded = storage.stage == "power_checkpoint" end)
script.on_event(defines.events.on_tick, function()
  if storage.stage == "cooling_failure" or storage.stage == "half_power"
    or storage.stage == "total_outage" then
    advance()
    return
  end
  if not loaded or storage.stage ~= "power_checkpoint" or game.tick <= storage.saved_tick then return end
  local force = storage.player_force
  local failed = core_status(force, storage.first)
  equal(failed.reset_for_power, true, "held total-power failure survives save and reload")
  equal(failed.crafting_progress, 0, "failed batch remains canceled after reload")
  check(failed.disabled_by_script, "script hold survives reload")
  equal(ledger(force).orbital.generated, storage.saved_generated, "failure checkpoint conserves earned ledger")
  replace_power(10000000000)
  reserve(storage.first, 2)
  storage.stage = "reload_recovery"
end)

script.on_nth_tick(30, function()
  if storage.stage == "done" then return end
  if storage.stage ~= "power_checkpoint" then advance() end
  if storage.stage == "power_checkpoint" and loaded and game.tick > storage.saved_tick then advance() end
end)
