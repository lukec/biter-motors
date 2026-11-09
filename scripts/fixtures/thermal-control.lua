local P = require("__bitermotors_thermal_prototype__/thermal-policy")
local CORE, RAD, PIPE, BUFFER = "bitermotors-thermal-core", "bitermotors-thermal-radiator", "bitermotors-thermal-conduit", "bitermotors-thermal-buffer"
local RECIPE, DOLLAR = "bitermotors-orbital-ai-dataset-hyperscale", "bitermotors-dollar"
local REPORT, loaded = "bitermotors-thermal.jsonl", false
local function check(ok, text) assert(ok, text); storage.assertions = (storage.assertions or 0) + 1 end
local function near(a, b, tolerance, text) check(math.abs(a - b) <= tolerance, text .. ": " .. a .. " / " .. b) end
local function status() return remote.call("bitermotors_thermal_prototype", "status") end
local function core_status() return assert(status().cores[1], "live primary thermal core") end
local function input() return storage.core.get_inventory(defines.inventory.crafter_input) end
local function output() return storage.chest.get_inventory(defines.inventory.chest).get_item_count("bitermotors-agi-training-dataset") end
local function report(name, extra)
  local row = extra or {}
  row.status, row.tick, row.assertions = name, game.tick, storage.assertions
  row.scope = "isolated-thermal-prototype"
  row.limits = "Supplied platform foundation, hardware, research and physical Dollars. Real orbital solar, native crafting, native heat conduction and destructive death. No rocket, campaign or graphical qualification."
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end
local function make(name, x, y)
  return assert(storage.surface.create_entity{name = name, position = {x, y}, force = "player", raise_built = true}, name)
end
local function wings(count)
  for _, e in ipairs(storage.wings or {}) do if e.valid then e.destroy{raise_destroy = true} end end
  storage.wings = {}
  for i = 1, count do storage.wings[i] = make("bitermotors-high-density-space-solar-panel", -19.5 + i * 3, 22.5) end
end
local function stage(name)
  storage.stage, storage.since = name, game.tick
end
local function checkpoint(name)
  storage.saved_tick = game.tick
  storage.stage = name .. "_checkpoint"
  report(storage.stage, {thermal = status(), output = output()})
  game.server_save("bitermotors-thermal-" .. name)
end
script.on_init(function()
  game.speed, game.tick_paused = 100, false
  game.forces.player.research_all_technologies(true)
  local platform = assert(game.forces.player.create_space_platform{name = "Orbital thermals laboratory",
    planet = "nauvis", starter_pack = "space-platform-starter-pack"})
  check(platform.apply_starter_pack(true) ~= nil, "supplied native platform starter")
  storage.platform, storage.surface, storage.started = platform, platform.surface, game.tick
  local tiles = {}
  for x = -24, 25 do for y = -8, 30 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end end
  storage.surface.set_tiles(tiles)
  storage.core = make(CORE, 0.5, 10.5)
  check(storage.core.set_recipe(RECIPE) ~= nil, "native orbital compute recipe")
  storage.radiator = make(RAD, 6.5, 10.5)
  storage.unrelated = make(RAD, 20.5, 10.5)
  for x = 2.5, 4.5, 1 do
    local pipe = make(PIPE, x, 10.5)
    if x == 3.5 then storage.bridge = pipe end
  end
  storage.chest = make("steel-chest", 0.5, 13.5)
  local arm = make("bulk-inserter", 0.5, 12.5)
  storage.arm = arm
  arm.direction = defines.direction.north
  wings(5)
  check(#storage.surface.find_entities_filtered{type = "electric-energy-interface"} == 0, "real solar only")
  stage("idle")
  report("setup_passed", {target_c = P.target_c, warning_c = P.warning_c, burnout_c = P.burnout_c,
    core_watts = P.core_watts, buffer_joules_per_c = P.core_joules_per_c})
end)
script.on_load(function() loaded = storage.stage == "hot_checkpoint" or storage.stage == "burned_checkpoint" end)
script.on_event(defines.events.on_entity_died, function(event)
  if event.entity == storage.core then
    storage.native_deaths = (storage.native_deaths or 0) + 1
    storage.death_tick = game.tick
  end
end)
script.on_event(defines.events.on_tick, function()
  if not loaded or game.tick <= storage.saved_tick then return end
  loaded = false
  if storage.stage == "hot_checkpoint" then
    local now = core_status()
    near(now.temperature, storage.hot_temperature, 0.5, "hot native buffer survives separate reload")
    check(now.temperature > P.warning_c, "reload does not reset heat")
    near(now.heat_joules, storage.hot_heat_joules, 1, "earned heat accounting survives reload")
    check(storage.core.crafting_progress > 0, "native committed batch survives hot reload")
    report("hot_reload_passed", {thermal = status(), saved_tick = storage.saved_tick})
    stage("burn_wait")
  elseif storage.stage == "burned_checkpoint" then
    check(not storage.core.valid, "burned core stays destroyed after reload")
    check(storage.native_deaths == 1 and status().burnouts == 1, "no duplicate native destruction")
    check(#storage.surface.find_entities_filtered{name = BUFFER} == 0, "no orphan thermal components after reload")
    check(output() == storage.burned_output, "reload cannot mint products from burned work")
    report("reload_passed", {thermal = status(), saved_tick = storage.saved_tick, native_deaths = storage.native_deaths})
    stage("done")
  end
end)
script.on_nth_tick(60, function()
  if game.tick == 0 or storage.stage == "done" or string.find(storage.stage, "checkpoint", 1, true) then return end
  check(game.tick - storage.started < 240000, "thermal simulation bounded")
  local elapsed = game.tick - storage.since
  local thermal = status()
  if game.tick % 300 == 0 then
    helpers.write_file("bitermotors-thermal-samples.jsonl", helpers.table_to_json{stage = storage.stage,
      tick = game.tick, thermal = thermal, output = output()} .. "\n", true)
  end
  if storage.stage == "idle" and elapsed >= 600 then
    near(core_status().temperature, P.floor_c, 0.001, "powered idle core does not produce compute heat")
    check(core_status().heat_joules == 0, "no work means no injected energy")
    check(#storage.surface.find_entities_filtered{name = BUFFER} == 1, "one thermal component per core")
    check(input().insert{name = DOLLAR, count = 2000} == 2000, "finite physical operating capital")
    stage("warmup")
  elseif storage.stage == "warmup" then
    check(storage.core.valid, "connected core survives warmup")
    if elapsed < 108000 then return end
    local core = core_status()
    near(core.temperature, P.target_c, 1, "connected operating point near 97C")
    check(core.products > 10 and output() > 0, "native computation and physical extraction")
    near(core.watts, P.core_watts, 1, "full native work generates 250MW waste heat")
    check(thermal.radiators[1].removed_joules > 0, "connected radiator rejects finite heat")
    near(thermal.radiators[2].temperature, P.floor_c, 0.001, "disconnected radiator stays cold")
    local stored_heat = (core.temperature - P.floor_c) * P.core_joules_per_c
    for _, row in ipairs(thermal.radiators) do stored_heat = stored_heat + (row.temperature - P.floor_c) * P.radiator_joules_per_c end
    for _, pipe in pairs(storage.surface.find_entities_filtered{name = PIPE}) do
      stored_heat = stored_heat + (pipe.temperature - P.floor_c) * P.conduit_joules_per_c
    end
    local removed = 0
    for _, row in ipairs(thermal.radiators) do removed = removed + row.removed_joules end
    near(core.heat_joules - removed, stored_heat, core.heat_joules * 0.001, "native heat transport conserves injected, stored and radiated energy")
    report("steady_passed", {thermal = thermal, output = output()})
    game.server_save("bitermotors-thermal-demo")
    storage.full_start = {tick = game.tick, work = core.work_seconds, temperature = core.temperature}
    stage("full_measure")
  elseif storage.stage == "full_measure" and elapsed >= 1800 then
    local core = core_status()
    storage.full_work_rate = (core.work_seconds - storage.full_start.work) / 30
    storage.arm.disabled_by_script = true
    local inventory = storage.core.get_inventory(defines.inventory.crafter_output)
    inventory.insert{name = "bitermotors-agi-training-dataset", count = #inventory * 1000}
    stage("blocked_settle")
  elseif storage.stage == "blocked_settle" and elapsed >= 1800 then
    storage.blocked_start = core_status().heat_joules
    stage("blocked_measure")
  elseif storage.stage == "blocked_measure" and elapsed >= 1800 then
    local core = core_status()
    near(core.heat_joules, storage.blocked_start, 1, "output-blocked core produces no fictitious heat")
    near(core.watts, 0, 1, "output-full machine does no active work")
    report("blocked_output_passed", {thermal = thermal})
    storage.core.get_inventory(defines.inventory.crafter_output).clear()
    storage.arm.disabled_by_script = false
    storage.low_start = {work = core.work_seconds, temperature = core.temperature}
    wings(2)
    stage("brownout")
  elseif storage.stage == "brownout" and elapsed >= 7200 then
    local core = core_status()
    local rate = (core.work_seconds - storage.low_start.work) / 120
    check(rate > 0.4 and rate < 0.55, "120MW solar proportionally slows native compute and waste heat")
    check(core.temperature < storage.low_start.temperature - 2, "brownout reduces temperature")
    report("brownout_passed", {thermal = thermal, work_fraction = rate, full_work_fraction = storage.full_work_rate})
    wings(0)
    storage.off_start = core.heat_joules
    stage("power_outage")
  elseif storage.stage == "power_outage" and elapsed >= 1800 then
    local core = core_status()
    check(core.heat_joules - storage.off_start < P.core_watts, "outage cannot keep producing full-load heat")
    near(core.watts, 0, 1, "fully unpowered core adds no compute heat")
    report("outage_passed", {thermal = thermal})
    wings(5)
    storage.bridge.destroy{raise_destroy = true}
    storage.cut_tick, storage.cut_temperature = game.tick, core.temperature
    stage("repairable_cut")
  elseif storage.stage == "repairable_cut" then
    check(storage.core.valid, "thermal buffer gives repair time")
    if core_status().temperature < 110 then return end
    check(game.tick - storage.cut_tick > 1800, "disconnection has a real thermal grace period")
    storage.bridge = make(PIPE, 3.5, 10.5)
    storage.repaired_products = core_status().products
    report("repair_started", {thermal = thermal, disconnected_ticks = game.tick - storage.cut_tick})
    stage("repaired")
  elseif storage.stage == "repaired" and elapsed >= 72000 then
    local core = core_status()
    near(core.temperature, P.target_c, 1, "repair restores thermal equilibrium")
    check(core.products > storage.repaired_products, "same native core continues computing after repair")
    check(status().burnouts == 0, "repair before burnout avoids destruction")
    report("repair_passed", {thermal = thermal})
    storage.bridge.destroy{raise_destroy = true}
    stage("hot_save")
  elseif storage.stage == "hot_save" then
    if core_status().temperature < 110 then return end
    storage.hot_temperature, storage.hot_heat_joules = core_status().temperature, core_status().heat_joules
    checkpoint("hot")
  elseif storage.stage == "burn_wait" then
    if storage.core.valid then return end
    check(storage.native_deaths == 1 and thermal.burnouts == 1, "one real native overheat death")
    local event = thermal.burnout_events[1]
    check(event.temperature >= P.burnout_c and event.temperature < P.burnout_c + 1, "destruction at calibrated threshold")
    check(storage.death_tick - storage.saved_tick > 1800, "hot saved buffer does not burn immediately on reload")
    check(#storage.surface.find_entities_filtered{name = BUFFER} == 0, "death removes only its thermal component")
    check(storage.radiator.valid and storage.unrelated.valid, "burnout is local, not nuclear chain destruction")
    storage.burned_output = output()
    report("burnout_passed", {thermal = thermal, native_deaths = storage.native_deaths, death_tick = storage.death_tick,
      seconds_from_hot_checkpoint = (storage.death_tick - storage.saved_tick) / 60})
    stage("burned_wait")
  elseif storage.stage == "burned_wait" and elapsed >= 1200 then
    check(output() == storage.burned_output, "destroyed core cannot continue earning output")
    checkpoint("burned")
  end
end)
