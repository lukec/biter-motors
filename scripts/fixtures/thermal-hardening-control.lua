local CORE, RAD = "bitermotors-orbital-datacenter-core", "bitermotors-orbital-radiator-panel"
local PIPE, BUFFER = "bitermotors-orbital-heat-pipe", "bitermotors-orbital-heat-buffer"
local SOLAR = "bitermotors-high-density-space-solar-panel"
local RECIPE, CASH, PRODUCT = "bitermotors-orbital-ai-dataset-hyperscale", "bitermotors-dollar", "bitermotors-agi-training-dataset"
local REPORT = "bitermotors-thermal-hardening.jsonl"
local loaded, benchmark, benchmark_start = false, false, nil
local function check(ok, label)
  assert(ok, label)
  storage.assertions = (storage.assertions or 0) + 1
end
local function near(a, b, tolerance, label) check(math.abs(a - b) <= tolerance, label .. ": " .. a .. " / " .. b) end
local function status() return remote.call("bitermotors", "thermal_status") end
local function core_row(entity)
  for _, row in ipairs(status().cores) do if row.unit == entity.unit_number then return row end end
  error("missing production thermal core " .. entity.unit_number)
end
local function report(name, row)
  row = row or {}
  row.status, row.tick, row.assertions = name, game.tick, storage.assertions
  row.scope = "production-native-thermal-hardening"
  row.limits = "Supplied foundation, research, hardware and finite physical Dollars. Single-core native solar; shared arrays supplied EEI. No campaign/rocket/economics or connected-client presentation qualification."
  row.max_visited = status().max_visited
  check(row.max_visited <= 128, "bounded 64 cores plus 64 radiators per thermal callback")
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end
local function stage(name) storage.stage, storage.since = name, game.tick end
local function alerts(expected)
  local players, count = 0, 0
  for _, player in pairs(game.forces.player.players) do
    players = players + 1
    local own = 0
    for _, kinds in pairs(player.get_alerts{entity = storage.core, type = defines.alert_type.custom}) do
      for _, entries in pairs(kinds) do for _, alert in pairs(entries) do
        own, count = own + 1, count + 1
        if expected then
          check(alert.target == storage.core, "native alert targets real core")
          check(alert.icon and (alert.icon.type or "item") == "item" and alert.icon.name == RAD, "native alert radiator icon")
          check(alert.message and alert.message[1] == "bitermotors-thermal.alert-" .. expected, "native alert localized message key")
        end
      end end
    end
    check(expected and own >= 1 or not expected and own == 0, "native per-player alerts present/cleared")
  end
  return {players = players, count = count, message_key = expected and "bitermotors-thermal.alert-" .. expected or "none"}
end
local function make(surface, name, x, y, force)
  return assert(surface.create_entity{name = name, position = {x, y}, force = force or "player", raise_built = true}, name)
end
local function platform(name, count)
  local p = assert(game.forces.player.create_space_platform{name = name, planet = "nauvis", starter_pack = "space-platform-starter-pack"})
  check(p.apply_starter_pack(true) ~= nil, "native platform hub")
  local tiles = {}
  for x = -24, count * 6 + 12 do for y = -8, 32 do
    tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}}
  end end
  p.surface.set_tiles(tiles)
  return p
end
local function output(array)
  local total = 0
  for _, chest in ipairs(array.chests) do total = total + chest.get_inventory(defines.inventory.chest).get_item_count(PRODUCT) end
  return total
end
local function products(array)
  local total = 0
  for _, core in ipairs(array.cores) do if core.valid then total = total + core.products_finished end end
  return total
end
local function cash(array)
  for _, core in ipairs(array.cores) do
    check(core.get_inventory(defines.inventory.crafter_input).insert{name = CASH, count = 2000} == 2000, "finite cash sufficient for warmup and benchmark")
  end
end
local function wings(count)
  for _, wing in ipairs(storage.wings or {}) do if wing.valid then wing.destroy{raise_destroy = true} end end
  storage.wings = {}
  for i = 1, count do storage.wings[i] = make(storage.single.platform.surface, SOLAR, -19.5 + i * 3, 24.5) end
end
local function array(count, supplied)
  local a = {platform = platform("Thermal hardening " .. count, count), cores = {}, radiators = {}, chests = {}, arms = {}}
  local s = a.platform.surface
  for i = 1, count do
    local x = (i - 1) * 6 + 0.5
    local core = make(s, CORE, x, 10.5)
    check(core.set_recipe(RECIPE) ~= nil, "unaltered native production recipe")
    a.cores[i] = core
    a.radiators[i] = make(s, RAD, x, 16.5)
    for y = 12.5, 14.5 do
      local pipe = make(s, PIPE, x, y)
      if i == 1 and y == 13.5 then a.bridge = pipe end
    end
    -- Center-edge ports: the horizontal trunk physically joins every core.
    if i < count then for dx = 2, 4 do make(s, PIPE, x + dx, 10.5) end end
    a.chests[i] = make(s, "steel-chest", x, 7.5)
    a.arms[i] = make(s, "bulk-inserter", x, 8.5)
    a.arms[i].direction = defines.direction.south
  end
  if supplied then
    s.solar_power_multiplier = 0
    a.source = make(s, "electric-energy-interface", -12, 18)
    a.source.electric_interface_mode = defines.electric_interface_mode.primary_output
    a.source.power_production, a.source.output_flow_limit = count * 400000000 / 60, count * 400000000 / 60
    a.supplied_watts = count * 400000000
  end
  return a
end
local function summary(a)
  local low, high, min_products, min_output, min_cash = 1000, 0, math.huge, math.huge, math.huge
  local work, heat, per_core = 0, 0, {}
  local by_unit = {}
  for _, row in ipairs(status().cores) do by_unit[row.unit] = row end
  for i, core in ipairs(a.cores) do
    local r = assert(by_unit[core.unit_number], "missing array thermal core")
    low, high = math.min(low, r.temperature), math.max(high, r.temperature)
    min_products = math.min(min_products, core.products_finished)
    min_output = math.min(min_output, a.chests[i].get_inventory(defines.inventory.chest).get_item_count(PRODUCT))
    min_cash = math.min(min_cash, core.get_inventory(defines.inventory.crafter_input).get_item_count(CASH))
    work, heat = work + r.work_seconds, heat + r.heat_joules
    per_core[#per_core + 1] = {unit = r.unit, products = r.products, work_seconds = r.work_seconds,
      output = a.chests[i].get_inventory(defines.inventory.chest).get_item_count(PRODUCT), temperature = r.temperature}
  end
  return {count = #a.cores, min_c = low, max_c = high, min_products = min_products,
    min_output = min_output, min_cash = min_cash, products = products(a), output = output(a),
    work_seconds = work, heat_joules = heat, supplied_power = a.source ~= nil,
    supplied_watts = a.supplied_watts or 0, per_core = per_core}
end
local function stable(a)
  local r = summary(a)
  check(r.min_c >= 95.5 and r.max_c <= 98.5, "every connected production core stable near 97C: " .. helpers.table_to_json(r))
  check(r.min_products > 10 and r.min_output > 0 and r.min_cash > 0, "every core physically produces and retains finite cash")
  return r
end
local function save(name, extra)
  storage.saved_tick = game.tick
  stage(name .. "_checkpoint")
  report(storage.stage, extra)
  game.server_save("bitermotors-thermal-hardening-" .. name)
end
local function destroy_array(a)
  storage.deleted_surface = a.platform.surface.index
  a.platform.destroy(1)
end
script.on_init(function()
  game.speed, game.tick_paused = 100, false
  game.forces.player.research_all_technologies(true)
  storage.started, storage.native_deaths = game.tick, 0
  storage.single = array(1, false)
  storage.core = storage.single.cores[1]
  wings(5)
  local s, location = storage.single.platform.surface, storage.single.platform.space_location
  storage.solar_watts = prototypes.entity[SOLAR].get_max_energy_production("normal") * 60
    * s.solar_power_multiplier * location.solar_power_in_space / 100
  near(storage.solar_watts * 5, 300000000, 1, "unaltered five native orbital wings supply 300MW")
  check(#storage.single.platform.surface.find_entities_filtered{type = "electric-energy-interface"} == 0, "single core exclusively native solar")
  stage("idle")
end)
script.on_load(function() loaded = true end)
script.on_event(defines.events.on_entity_died, function(event)
  if event.entity == storage.core then
    storage.native_deaths, storage.death_tick = storage.native_deaths + 1, game.tick
  end
end)
script.on_event(defines.events.on_tick, function()
  if not loaded then return end
  loaded = false
  if storage.stage == "hot_checkpoint" then
    local r = core_row(storage.core)
    near(r.temperature, storage.hot.temperature, 0.01, "hot buffer temperature survives separate process")
    local queued_ticks = game.tick - storage.saved_tick
    check(queued_ticks >= 1 and queued_ticks < 15, "queued save completes before the next thermal sample")
    near(storage.core.crafting_progress, storage.hot.progress + storage.hot_progress_per_tick * queued_ticks, 0.000001,
      "committed native progress matches exact elapsed native ticks across queued save")
    near(r.heat_joules, storage.hot.heat_joules, 1, "heat accounting survives separate process")
    report("hot_reload_passed", {saved_tick = storage.saved_tick, before = storage.hot, after = r,
      progress_per_tick = storage.hot_progress_per_tick, queued_ticks = queued_ticks, separate_process_reload = true})
    stage("burn_wait")
  elseif storage.stage == "burned_checkpoint" then
    check(not storage.core.valid and storage.native_deaths == 1 and status().burnouts == 1, "one persistent real death")
    check(#storage.single.platform.surface.find_entities_filtered{name = BUFFER} == 0, "no orphan heat buffer after burned reload")
    check(output(storage.single) == storage.burned_output, "burned reload cannot duplicate physical output")
    report("burned_reload_passed", {saved_tick = storage.saved_tick, native_deaths = storage.native_deaths,
      burnouts = status().burnouts, buffers = 0, output = output(storage.single),
      checkpoint_output = storage.burned_output, separate_process_reload = true})
    stage("burned_reload_wait")
  elseif storage.stage == "array12_checkpoint" or storage.stage == "array128_checkpoint" then
    benchmark, benchmark_start = true, {tick = game.tick, state = summary(storage.shared)}
    helpers.write_file("bitermotors-thermal-hardening-benchmark.jsonl", helpers.table_to_json{
      status = "benchmark_start", tick = game.tick, state = benchmark_start.state, max_visited = status().max_visited} .. "\n", true)
  end
end)
script.on_nth_tick(60, function()
  if game.tick == 0 or storage.stage == "done" then return end
  if benchmark then
    if game.tick - benchmark_start.tick >= 3540 and not benchmark_start.done then
      local r = stable(storage.shared)
      check(r.products > benchmark_start.state.products and r.output > benchmark_start.state.output, "benchmark has new physical production")
      check(r.work_seconds > benchmark_start.state.work_seconds, "benchmark has advancing native work")
      for i, core in ipairs(r.per_core) do
        local before = benchmark_start.state.per_core[i]
        check(core.unit == before.unit and core.products > before.products and core.output > before.output
          and core.work_seconds > before.work_seconds, "every benchmark core advances native production and physical extraction")
      end
      helpers.write_file("bitermotors-thermal-hardening-benchmark.jsonl", helpers.table_to_json{
        status = "benchmark_end", tick = game.tick, state = r, max_visited = status().max_visited} .. "\n", true)
      benchmark_start.done = true
    end
    return
  end
  if storage.stage == "hot_checkpoint" or storage.stage == "burned_checkpoint" then return end
  check(game.tick - storage.started < 1500000, "bounded simulation deadline at " .. storage.stage)
  local elapsed, a = game.tick - storage.since, storage.single
  if game.tick % 600 == 0 then
    helpers.write_file("bitermotors-thermal-hardening-samples.jsonl", helpers.table_to_json{
      tick = game.tick, stage = storage.stage, thermal = status()} .. "\n", true)
  end
  if storage.stage == "idle" and elapsed >= 600 then
    local r = core_row(storage.core)
    check(r.heat_joules > 0 and r.work_seconds == 0, "powered idle has real drain, no active compute")
    near(r.watts, 250000000 / 30, 100000, "native idle drain becomes heat")
    report("idle_passed", {core = r, solar_wings = 5, native_solar_watts = storage.solar_watts * 5,
      supplied_power = false, players = #game.forces.player.players})
    cash(a)
    stage("nominal")
  elseif storage.stage == "nominal" and elapsed >= 180000 then
    local r = stable(a)
    r.elapsed_ticks, r.solar_wings = elapsed, 5
    near(core_row(storage.core).watts, 250000000 * 31 / 30, 1000000, "active plus native idle watts")
    report("nominal_passed", r)
    storage.full_work = core_row(storage.core).work_seconds
    wings(2)
    stage("brownout")
  elseif storage.stage == "brownout" and elapsed >= 7200 then
    local r = core_row(storage.core)
    local rate = (r.work_seconds - storage.full_work) / (elapsed / 60)
    check(rate > 0.35 and rate < 0.55, "native 120MW brownout proportionally reduces active work")
    report("brownout_passed", {work_fraction = rate, core = r, native_solar_watts = storage.solar_watts * 2})
    wings(0)
    stage("outage_settle")
  elseif storage.stage == "outage_settle" and elapsed >= 600 then
    storage.before = core_row(storage.core)
    stage("outage")
  elseif storage.stage == "outage" and elapsed >= 1800 then
    local r = core_row(storage.core)
    near(r.work_seconds, storage.before.work_seconds, 0.001, "outage stops active work")
    near(r.heat_joules, storage.before.heat_joules, 1, "outage stops idle and active heat")
    report("outage_passed", {before = storage.before, after = r, elapsed_ticks = elapsed})
    wings(5)
    a.arms[1].disabled_by_script = true
    local inv = storage.core.get_inventory(defines.inventory.crafter_output)
    inv.insert{name = PRODUCT, count = #inv * prototypes.item[PRODUCT].stack_size}
    stage("blocked_settle")
  elseif storage.stage == "blocked_settle" and elapsed >= 1200 then
    storage.before = core_row(storage.core)
    stage("blocked")
  elseif storage.stage == "blocked" and elapsed >= 1800 then
    local r = core_row(storage.core)
    near(r.work_seconds, storage.before.work_seconds, 0.001, "native output-blocked stops active work")
    near(r.watts, 250000000 / 30, 100000, "output-blocked retains only real idle drain")
    report("blocked_passed", {before = storage.before, after = r, elapsed_ticks = elapsed})
    storage.core.get_inventory(defines.inventory.crafter_output).clear()
    a.arms[1].disabled_by_script = false
    stage("repair_warmup")
  elseif storage.stage == "repair_warmup" and elapsed >= 180000 then
    stable(a)
    a.bridge.destroy{raise_destroy = true}
    stage("repair_cut")
  elseif storage.stage == "repair_cut" then
    local r = core_row(storage.core)
    check(storage.core.valid and status().burnouts == 0, "repair window survives")
    if r.temperature < 108 then return end
    check(r.state == "warning" and r.warning_visible, "105C native warning rendering exists without fake players")
    check(storage.core.custom_status ~= nil, "native warning custom status exists")
    report("repair_warning_passed", {core = r, elapsed_ticks = elapsed, alerts = alerts("warning"), custom_status = true})
    a.bridge = make(a.platform.surface, PIPE, 0.5, 13.5)
    storage.repair_products = products(a)
    stage("repair")
  elseif storage.stage == "repair" and elapsed >= 72000 then
    local r = stable(a)
    check(products(a) > storage.repair_products and status().burnouts == 0, "repair resumes same core before burnout")
    check(not core_row(storage.core).warning_visible, "repair clears warning rendering")
    r.alerts = alerts(nil)
    report("repair_passed", r)
    a.bridge.destroy{raise_destroy = true}
    storage.cut_tick, storage.cut_temperature = game.tick, core_row(storage.core).temperature
    stage("fatal_cut")
  elseif storage.stage == "fatal_cut" then
    local r = core_row(storage.core)
    if r.temperature < 108 or r.progress <= 0.05 or r.progress >= 0.9 then return end
    storage.hot = r
    storage.hot_progress_per_tick = storage.core.crafting_speed / (storage.core.get_recipe().energy * 60)
    save("hot", {core = r, cut_tick = storage.cut_tick, cut_temperature = storage.cut_temperature,
      progress_per_tick = storage.hot_progress_per_tick})
  elseif storage.stage == "burn_wait" then
    if storage.core.valid then
      local r = core_row(storage.core)
      if r.temperature >= 120 and not storage.critical_seen then
        check(r.state == "critical" and r.warning_visible and storage.core.custom_status ~= nil, "120C critical warning has real rendering and custom status")
        storage.critical_seen = true
        report("critical_passed", {core = r, alerts = alerts("critical"), custom_status = true})
      end
      return
    end
    local t = status()
    check(storage.critical_seen and storage.native_deaths == 1 and t.burnouts == 1, "one real native death, not destroy")
    local seconds = (storage.death_tick - storage.cut_tick) / 60
    check(seconds >= 120 and seconds <= 180, "disconnect from nominal burns in 120-180 actual seconds: " .. seconds)
    check(t.last_burnout.unit == storage.hot.unit and t.last_burnout.tick == storage.death_tick, "native death matches burnout ledger")
    check(t.last_burnout.temperature >= 130 and t.last_burnout.temperature < 131, "130C real burnout")
    check(#a.platform.surface.find_entities_filtered{name = BUFFER} == 0, "native death removes hidden buffer")
    storage.burned_output = output(a)
    report("burnout_passed", {native_deaths = storage.native_deaths, burnouts = t.burnouts, last_burnout = t.last_burnout,
      cut_tick = storage.cut_tick, death_tick = storage.death_tick, seconds = seconds, buffers = 0})
    stage("burned_wait")
  elseif storage.stage == "burned_wait" and elapsed >= 1200 then
    check(output(a) == storage.burned_output, "dead core cannot create new output")
    save("burned", {output = storage.burned_output})
  elseif storage.stage == "burned_reload_wait" and elapsed >= 600 then
    check(output(a) == storage.burned_output, "burned reload advances without duplicate output")
    destroy_array(a)
    storage.shared = array(4, true)
    cash(storage.shared)
    stage("shared4")
  elseif storage.stage == "shared4" and elapsed >= 180000 then
    report("shared4_passed", stable(storage.shared))
    storage.shared.radiators[1].destroy{raise_destroy = true}
    storage.shared_before = summary(storage.shared)
    stage("shared_loss")
  elseif storage.stage == "shared_loss" and elapsed >= 2400 then
    local r = summary(storage.shared)
    check(r.min_c > storage.shared_before.max_c + 0.5, "removed radiator heats every core of the physically shared network")
    check(r.max_c < 120, "shared network repair still possible")
    report("shared_loss_passed", {before = storage.shared_before, after = r, elapsed_ticks = elapsed})
    storage.shared.radiators[1] = make(storage.shared.platform.surface, RAD, 0.5, 16.5)
    stage("shared_repair")
  elseif storage.stage == "shared_repair" and elapsed >= 72000 then
    report("shared_repair_passed", stable(storage.shared))
    stage("lifecycle")
  elseif storage.stage == "lifecycle" then
    local s = storage.lifecycle ~= 6 and storage.shared.platform.surface or nil
    if not storage.lifecycle then
      local core = storage.shared.cores[1]
      local before = core_row(core)
      local clone = assert(core.clone{position = {0.5, 25.5}, surface = s, force = "player"})
      storage.clone, storage.clone_temperature = clone, before.temperature
      storage.lifecycle = 1
      stage("lifecycle")
    elseif storage.lifecycle == 1 and elapsed >= 60 then
      local r = core_row(storage.clone)
      near(r.temperature, storage.clone_temperature, 1, "clone inherits real heat without cold reset")
      local other = game.create_force("thermal-hardening-other")
      storage.clone.force = other
      storage.lifecycle = 2
      stage("lifecycle")
    elseif storage.lifecycle == 2 and elapsed >= 60 then
      local r = core_row(storage.clone)
      local buffer = s.find_entity(BUFFER, storage.clone.position)
      check(buffer and buffer.force == storage.clone.force and buffer.unit_number == r.buffer_unit, "force change keeps single owned heat buffer")
      local inv = game.create_inventory(100)
      check(storage.clone.mine{inventory = inv, force = true, raise_destroyed = true}, "native mining")
      inv.destroy()
      storage.lifecycle = 3
      stage("lifecycle")
    elseif storage.lifecycle == 3 and elapsed >= 60 then
      check(#s.find_entities_filtered{name = BUFFER} == 4, "mining removes clone buffer only")
      local rebuilt = make(s, CORE, 0.5, 25.5)
      storage.rebuilt = rebuilt
      storage.lifecycle = 4
      stage("lifecycle")
    elseif storage.lifecycle == 4 and elapsed >= 60 then
      check(core_row(storage.rebuilt).buffer_unit ~= nil, "rebuild registers exactly one buffer")
      storage.rebuilt.destroy{raise_destroy = true}
      storage.lifecycle = 5
      stage("lifecycle")
    elseif storage.lifecycle == 5 and elapsed >= 60 then
      check(#s.find_entities_filtered{name = BUFFER} == 4, "script removal cleans buffer")
      destroy_array(storage.shared)
      storage.lifecycle = 6
      stage("lifecycle")
    elseif storage.lifecycle == 6 and elapsed >= 60 then
      check(game.surfaces[storage.deleted_surface] == nil, "native platform surface actually deleted")
      check(#status().cores == 0 and #status().radiators == 0, "surface deletion leaves no thermal registry orphans")
      report("lifecycle_passed", {cloning = true, force_change = true, mining = true, rebuild = true, removal = true, surface_delete = true,
        configuration_rebuild = false})
      storage.shared = array(12, true)
      cash(storage.shared)
      stage("array12")
    end
  elseif storage.stage == "array12" and elapsed >= 180000 then
    local r = stable(storage.shared)
    r.elapsed_ticks = elapsed
    save("array12", r)
  elseif storage.stage == "array12_checkpoint" and elapsed >= 120 then
    destroy_array(storage.shared)
    storage.shared = array(128, true)
    cash(storage.shared)
    stage("array128")
  elseif storage.stage == "array128" and elapsed >= 180000 then
    local r = stable(storage.shared)
    r.elapsed_ticks = elapsed
    save("array128", r)
  elseif storage.stage == "array128_checkpoint" and elapsed >= 120 then
    report("hardening_passed", {native_deaths = storage.native_deaths, player_alert_delivery = #game.forces.player.players > 0,
      configuration_rebuild = false})
    stage("done")
  end
end)
