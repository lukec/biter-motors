-- Shared native ending rehearsal. The finale helper adds adversarial cases.
local M = {}
local Ledger = require("__bitermotors__/runtime/agi_completion")
function M.run(options)
  options = options or {}
  local prefix = options.adversarial and "finale" or "delivery"
  local payload_quality = options.adversarial and "rare" or "normal"
  local wrong_quality = options.adversarial and "normal" or "rare"
  local CORE = "bitermotors-orbital-datacenter-core"
  local DC = "bitermotors-terrestrial-datacenter"
  local DATASET = "bitermotors-agi-training-dataset"
  local MODEL = "bitermotors-agi-model"
  local RACK = "bitermotors-datacenter-rack"
  local COMPUTE = "bitermotors-orbital-ai-dataset-hyperscale"
  local ASSEMBLE = "bitermotors-assemble-agi-model"
  local ACTIVATE = "bitermotors-activate-agi-model"
  local loaded, assertions = false, 0
  local function check(value, message)
    assertions = assertions + 1
    assert(value, prefix .. ": " .. message)
  end
  local function equal(a, b, message)
    check(a == b, message .. ": " .. tostring(a) .. " != " .. tostring(b))
  end
  local function state(force)
    return remote.call("bitermotors", "agi_training_status", force or "player")
  end
  local function input(e) return e.get_inventory(defines.inventory.crafter_input) end
  local function output(e) return e.get_inventory(defines.inventory.crafter_output) end
  local function count(inv, name, quality)
    return inv.get_item_count{name = name, quality = quality or payload_quality}
  end
  local function make(surface, name, position, force, quality)
    return assert(surface.create_entity{name = name, position = position, force = force or "player",
      quality = quality or "normal", raise_built = true}, "create " .. name)
  end
  local function report(status, fields)
    local row = fields or {}
    row.status, row.tick, row.assertions = status, game.tick, assertions
    row.validation_scope = "native-model-ending"
    row.payload_quality = payload_quality
    row.limits = "Supplied construction, foundation, research, physical Dollars, Rack and EEI power; manual inventory transfers after verified native extraction. Not campaign economics, uplift or orbital solar qualification."
    helpers.write_file("bitermotors-" .. prefix .. ".jsonl", helpers.table_to_json(row) .. "\n", true)
  end
  local function power(surface, position, land, force)
    local source = make(surface, "electric-energy-interface", position, force)
    source.electric_interface_mode = defines.electric_interface_mode.primary_output
    source.power_production, source.output_flow_limit = 1000000000000, 1000000000000
    local pole = land and make(surface, "substation", {position[1] + 3, position[2]}, force) or nil
    return source, pole
  end
  local function checkpoint(phase, progress)
    storage.resume_phase, storage.stage = phase, "checkpoint"
    storage.saved_tick, storage.saved_progress = game.tick, progress
    storage.saved_products = phase == "assembly" and storage.assembler.products_finished
      or phase == "activation" and storage.terminal.products_finished or 0
    report(phase .. "_checkpoint", {progress = progress, products = storage.saved_products,
      models_assembled = state().models_assembled, models_returned = state().models_returned,
      models_activated = state().models_activated, victory = state().victory,
      models_in_transit = state().models_in_transit, return_credits = state().return_credits,
      pod = phase == "flight" and storage.flight_pod_id or nil})
    game.speed = 1
    game.server_save("bitermotors-" .. prefix .. "-" .. phase)
    -- Do not mutate after requesting a checkpoint. Only on_load resumes it.
  end
  local function transfer(from, to, name, amount, quality)
    local stack = {name = name, count = amount, quality = quality or payload_quality}
    equal(from.remove(stack), amount, "physical withdrawal " .. name)
    equal(to.insert(stack), amount, "physical loading " .. name)
  end
  local function recipe(machine, name, quality)
    check(machine.set_recipe(name, quality or payload_quality) ~= nil, "select native " .. name)
  end
  local function platform(force, name)
    local p = game.forces[force].create_space_platform{name = name, planet = "nauvis",
      starter_pack = "space-platform-starter-pack"}
    check(p.apply_starter_pack(true) ~= nil, "native starter hub")
    local tiles = {}
    for x = -80, 80 do
      for y = -64, 80 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
    end
    p.surface.set_tiles(tiles, false, false, false, true)
    p.surface.solar_power_multiplier = 0 -- Isolate EEI outages, including radiator trickle.
    return p
  end
  local function extractor(machine, name, force)
    local edge = machine.position.y + machine.prototype.selection_box.right_bottom.y
    local chest = make(machine.surface, "steel-chest", {machine.position.x, edge + 1.5}, force)
    local arm = make(machine.surface, "bulk-inserter", {machine.position.x, edge + 0.5}, force)
    arm.direction, arm.use_filters = defines.direction.north, true
    arm.set_filter(1, {name = name, quality = payload_quality, comparator = "="})
    check(arm.pickup_position.y < edge, "native extractor targets actual machine bounds")
    return chest, arm
  end
  local function negative_machine(surface, force, position, quality)
    local e = make(surface, DC, position, force)
    power(surface, {position[1] - 6, position[2] + 6}, surface.platform == nil, force)
    -- Enabled explicitly only for adversarial native crafts; never grants credits.
    game.forces[force].recipes[ACTIVATE].enabled = true
    recipe(e, ACTIVATE, quality or "normal")
    equal(input(e).insert{name = MODEL, count = 1, quality = quality or "normal"}, 1, "injected negative Model")
    return e
  end
  local function ledger_fixture()
    local ledger = Ledger.ensure()
    Ledger.assemble(ledger, 1, 101, "rare")
    equal(Ledger.depart(ledger, 10, 110, 2, 101, {rare = 1}), false, "no cross-force departure")
    equal(Ledger.depart(ledger, 10, 110, 1, 102, {rare = 1}), false, "no cross-platform departure")
    equal(Ledger.depart(ledger, 10, 110, 1, 101, {normal = 1}), false, "no cross-quality departure")
    equal(Ledger.depart(ledger, 10, 110, 1, 101, {rare = 50}), true, "excess cargo reserves only native credit")
    equal(ledger.pods[10].qualities.rare, 1, "one native credit despite fifty cargo items")
    equal(Ledger.depart(ledger, 10, 110, 1, 101, {rare = 50}), false, "replayed departure cannot mint")
    equal(Ledger.deliver(ledger, 10, 1), true, "matching native delivery")
    equal(Ledger.deliver(ledger, 10, 1), false, "replayed delivery cannot mint")
    equal(Ledger.activate(ledger, 1, "normal"), false, "wrong-quality activation rejected")
    equal(Ledger.activate(ledger, 2, "rare"), false, "wrong-force activation rejected")
    equal(Ledger.activate(ledger, 1, "rare"), true, "matching quality consumes return credit")
    equal(Ledger.activate(ledger, 1, "rare"), false, "replayed activation rejected")
    Ledger.assemble(ledger, 1, 101, "rare")
    check(Ledger.depart(ledger, 11, 111, 1, 101, {rare = 1}), "lost-pod departure")
    check(Ledger.forget_pod(ledger, 11) ~= nil, "lost-pod cleanup forfeits reservation")
    equal(ledger.registrations[111], nil, "lost-pod registration removed")
    equal(Ledger.deliver(ledger, 11, 1), false, "lost pod cannot later return")
    equal(Ledger.depart(ledger, 12, 112, 1, 101, {rare = 1}), false, "lost credit cannot be reused")
    Ledger.assemble(ledger, 1, 101, "rare")
    check(Ledger.depart(ledger, 13, 113, 1, 101, {rare = 1}), "reserve cross-force delivery case")
    equal(Ledger.deliver(ledger, 13, 2), false, "cross-force delivery forfeits instead of transferring")
    Ledger.assemble(ledger, 1, 101, "rare")
    check(Ledger.depart(ledger, 14, 114, 1, 101, {rare = 1}), "persist in-transit credit")
    local decoded = helpers.json_to_table(helpers.table_to_json(ledger))
    local force = decoded.forces[1] or decoded.forces["1"]
    local pod = decoded.pods[14] or decoded.pods["14"]
    equal(force.models_assembled, 4, "JSON conserves native assemblies")
    equal(force.models_returned, 1, "JSON conserves returns")
    equal(force.models_activated, 1, "JSON conserves consumed credits")
    equal(pod.qualities.rare, 1, "JSON conserves in-transit quality")
    storage.pure_ledger = ledger -- Private fixture ledger, never runtime earned state.
  end
  script.on_init(function()
    game.tick_paused, game.speed = false, 100
    game.map_settings.pollution.enabled = false
    game.map_settings.enemy_expansion.enabled = false
    storage.started, storage.stage = game.tick, "compute"
    storage.cores, storage.pods = {}, {}
    storage.native_datasets, storage.native_assemblies, storage.native_activations = 0, 0, 0
    local force, land = game.forces.player, game.surfaces.nauvis
    for _, name in ipairs({"bitermotors-orbital-compute", "bitermotors-orbital-cluster-training",
      "bitermotors-grid-scale-energy", "bitermotors-hyperscale-training"}) do
      force.technologies[name].researched = true
    end
    land.request_to_generate_chunks({0, 0}, 5)
    land.force_generate_chunk_requests()
    for _, e in pairs(land.find_entities_filtered{area = {{-64, -48}, {128, 96}}}) do e.destroy() end
    local tiles = {}
    for x = -64, 128 do
      for y = -48, 96 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
    end
    land.set_tiles(tiles)
    storage.pad = make(land, "cargo-landing-pad", {0, 0})
    storage.terminal = make(land, DC, {24, 0}) -- Existing before any Model is assembled.
    storage.ground_power, storage.ground_pole = power(land, {18, 6}, true)
    storage.platform = platform("player", "Native Model origin")
    local surface = storage.platform.surface
    storage.orbit_power = power(surface, {-72, -48}, false)
    force.recipes[COMPUTE].enabled = true
    for i = 1, 40 do
      local x, y = -64 + ((i - 1) % 10) * 12, -32 + math.floor((i - 1) / 10) * 10
      local core = make(surface, CORE, {x, y})
      make(surface, "bitermotors-orbital-radiator-panel", {x, 24 + math.floor((i - 1) / 10) * 10})
      recipe(core, COMPUTE)
      equal(input(core).insert{name = "bitermotors-dollar", count = 125, quality = payload_quality},
        125, "supplied physical operating Dollars")
      storage.cores[#storage.cores + 1] = core
    end
    storage.assembler = storage.cores[1]
    storage.model_chest, storage.model_arm = extractor(storage.assembler, MODEL)
    storage.model_arm.disabled_by_script = true
    if options.adversarial then
      local other = game.create_force("ending-adversary")
      other.technologies["bitermotors-grid-scale-energy"].researched = true
      other.get_item_production_statistics(land).set_input_count("bitermotors-ai-token", 1000000000)
      storage.fake = negative_machine(land, "player", {48, 0})
      storage.wrong_force = negative_machine(land, other.name, {72, 0})
      storage.quality_fake = negative_machine(land, "player", {96, 0}, wrong_quality)
      storage.wrong_surface = negative_machine(surface, "player", {64, 0})
    end
  end)
  script.on_load(function() loaded = true end)
  script.on_event(prototypes.recipe[COMPUTE].on_crafted_event, function(event)
    for _, core in ipairs(storage.cores or {}) do
      if core.valid and core == event.entity then
        equal(event.bonus, false, "no productivity compute shortcut")
        storage.native_datasets = storage.native_datasets + 4
        return
      end
    end
  end)
  script.on_event(prototypes.recipe[ASSEMBLE].on_crafted_event, function(event)
    if event.entity ~= storage.assembler then return end
    equal(event.bonus, false, "assembly is not productivity")
    equal(type(event.product_quality) == "string" and event.product_quality or event.product_quality.name,
      payload_quality, "native product quality")
    storage.native_assemblies = storage.native_assemblies + 1
    equal(storage.native_assemblies, 1, "one native assembly")
    equal(state().completed, false, "orbital Model is not victory")
    equal(state().models_assembled, 1, "native assembly credited")
    storage.assembly_finished = game.tick
  end)
  script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
    local pod = event.cargo_pod
    if pod.cargo_pod_origin ~= storage.platform.hub then return end
    local amount = count(pod.get_inventory(defines.inventory.cargo_unit), MODEL)
    if amount == 0 then return end
    equal(amount, 1, "one physical Model in native return pod")
    storage.pods[pod.unit_number] = {count = amount, tick = game.tick}
    storage.model_pod_ids = storage.model_pod_ids or {}
    storage.model_pod_ids[pod.unit_number] = true
    storage.return_started = game.tick
    equal(state().assembly_credits, 0, "ascent reserves assembly credit")
    equal(state().models_in_transit, 1, "native ascent reserves one in-transit credit")
    storage.flight_pod, storage.flight_pod_id = pod, pod.unit_number
    storage.flight_saved_tick = game.tick
    checkpoint("flight", 0)
  end)
  script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
    local pod = event.cargo_pod
    if not storage.model_pod_ids or not storage.model_pod_ids[pod.unit_number] then return end
    local destination = pod.cargo_pod_destination
    local station = destination.type == defines.cargo_destination.station and destination.station
    log("native Model finished-descending probe: " .. helpers.table_to_json{tick = game.tick,
      pod = pod.unit_number, surface = pod.surface.name, position = pod.position,
      destination_type = destination.type, station = station and station.valid and station.name or nil,
      pad_models = count(storage.pad.get_inventory(defines.inventory.cargo_landing_pad_main), MODEL),
      status = state()})
  end)
  script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
    local pod, shipment = event.cargo_pod, storage.pods[event.cargo_pod.unit_number]
    if not shipment then return end
    check(storage.flight_reload_tick and game.tick > storage.flight_reload_tick
      and game.tick > storage.flight_saved_tick, "new native delivery after actual in-flight reload")
    equal(event.spawned_container, nil, "real delivery did not spill")
    equal(pod.surface, storage.pad.surface, "Model returned to Nauvis")
    local box, pos = storage.pad.bounding_box, pod.position
    check(pos.x >= box.left_top.x and pos.x <= box.right_bottom.x
      and pos.y >= box.left_top.y and pos.y <= box.right_bottom.y, "Model landed inside native pad")
    local destination = pod.cargo_pod_destination
    local station = destination.type == defines.cargo_destination.station and destination.station
    log("native Model delivery probe: " .. helpers.table_to_json{tick = game.tick,
      destination_type = destination.type, station_type = defines.cargo_destination.station,
      station = station and station.valid and station.name or nil, pod_force = pod.force.name,
      pad_force = storage.pad.force.name, status = state()})
    equal(state().models_returned, 1, "native return credited")
    equal(state().return_credits, 1, "one activation credit")
    storage.return_delivered = game.tick
    storage.pods[pod.unit_number] = nil
  end)
  script.on_event(prototypes.recipe[ACTIVATE].on_crafted_event, function(event)
    if event.entity == storage.wrong_surface then
      storage.wrong_surface_events = (storage.wrong_surface_events or 0) + 1
      equal(state().models_activated, 0, "native wrong-surface completion cannot consume activation credit")
      equal(state().completed, false, "native wrong-surface completion cannot win")
      return
    end
    if event.entity ~= storage.terminal then return end
    check(storage.activation_reload_tick and game.tick > storage.activation_reload_tick,
      "new native activation event after activation reload")
    storage.native_activations = storage.native_activations + 1
    equal(storage.native_activations, 1, "one genuine ground activation")
    equal(state().models_activated, 1, "native activation counted")
    equal(state().return_credits, 0, "activation consumes return credit")
    equal(state().completed, true, "native activation wins")
    equal(game.finished, true, "native victory sets game finished")
    storage.victory = state().victory
    check(storage.victory ~= nil, "persistent victory record exists")
    game.set_game_state{game_finished = false, player_won = true, can_continue = true}
    game.tick_paused = false
    storage.activation_finished = game.tick
    -- Native output and products_finished update after the completion callback.
    -- Inspect/extract at the first following tick, before saving the won world.
    storage.stage = "activation_finished"
  end)
  local function negative_checks()
    if not options.adversarial then return end
    equal(state("ending-adversary").cumulative_ai_tokens, 0, "raw statistics cannot earn compute")
    equal(state("ending-adversary").completed, false, "wrong force cannot win")
    equal(state().models_activated, 0, "injected and wrong-quality Models cannot activate")
    equal(state().completed, false, "injected Models cannot win after earned gate either")
    check(storage.fake.products_finished > 0 or state().models_returned == 0,
      "injected Model negative ran a real native activation or is still permission-gated")
    check(storage.wrong_force.products_finished > 0 or not state("ending-adversary").unlocked,
      "wrong-force negative ran a real native activation or lacks earned permission")
    equal(state().models_activated, 0, "wrong surface cannot earn activation credit")
  end
  script.on_nth_tick(1, function()
    if game.tick <= storage.started then return end -- Tick-zero callbacks are not evidence.
    check(game.tick - storage.started < 360000, "bounded native ending rehearsal")
    if loaded and storage.stage == "compute" then loaded = false end -- Initial --create save.
    if loaded then
      loaded = false
      if options.adversarial then
        local ledger = storage.pure_ledger
        equal(ledger.forces[1].models_assembled, 4, "native reload conserves ledger assemblies")
        equal(ledger.pods[14].qualities.rare, 1, "native reload conserves in-transit quality")
        local copy = helpers.json_to_table(helpers.table_to_json(ledger.forces[1]))
        equal(copy.models_activated, 1, "reload preserves consumed credit")
        equal(Ledger.activate(ledger, 1, "rare"), false, "reload cannot reuse consumed activation")
      end
      equal(storage.stage, "checkpoint", "load expected checkpoint")
      check(game.tick > storage.saved_tick, "reload advances actual game tick")
      local phase = storage.resume_phase
      if phase == "assembly" or phase == "activation" then
        local machine = phase == "assembly" and storage.assembler or storage.terminal
        equal(machine.products_finished, storage.saved_products, "no old output accepted as reload completion")
        check(machine.crafting_progress >= storage.saved_progress, "native committed progress survives reload")
        equal(state().completed, false, "partial reload cannot invent victory")
        storage.reloaded_products = machine.products_finished
        storage.reloaded_output = count(output(machine), MODEL)
        storage[phase .. "_reload_tick"] = game.tick
        if phase == "assembly" then
          equal(input(machine).get_item_count(DATASET), 0, "reload retains committed 20k without replacement")
          storage.orbit_power.power_production, storage.orbit_power.output_flow_limit = 1000000000000, 1000000000000
          storage.radiator = make(storage.platform.surface, "bitermotors-orbital-radiator-panel", storage.radiator_position)
          storage.model_arm.set_filter(1, {name = MODEL, quality = payload_quality, comparator = "="})
        else
          equal(count(input(machine), MODEL), 0, "activation reload retains committed original Model")
          equal(state().return_credits, 1, "activation outage reload does not consume return credit")
          check(math.abs(machine.crafting_progress - storage.saved_progress) < 1e-9,
            "unpowered activation checkpoint retains exact native progress")
          storage.ground_power.power_production, storage.ground_power.output_flow_limit = 1000000000000, 1000000000000
        end
      elseif phase == "flight" then
        check(storage.flight_pod and storage.flight_pod.valid, "original native in-flight pod survives reload")
        equal(storage.flight_pod.unit_number, storage.flight_pod_id, "same native pod identity after reload")
        equal(count(storage.flight_pod.get_inventory(defines.inventory.cargo_unit), MODEL), 1,
          "original physical Model remains in native pod after reload")
        equal(state().models_in_transit, 1, "reserved native in-flight credit survives reload")
        equal(state().assembly_credits, 0, "in-flight credit cannot be reused for a second departure")
        equal(state().return_credits, 0, "in-flight checkpoint precedes delivery, not same-tick arrival")
        equal(state().models_returned, 0, "flight save has no old native delivery")
        storage.flight_reload_tick = game.tick
      elseif phase == "return" then
        equal(state().completed, false, "return checkpoint cannot win")
        equal(state().return_credits, 1, "return credit survives separate process")
        local pad = storage.pad.get_inventory(defines.inventory.cargo_landing_pad_main)
        equal(count(pad, MODEL), 1, "physical returned Model survives reload")
        if options.adversarial then
          output(storage.quality_fake).clear()
          storage.wrong_quality_products = storage.quality_fake.products_finished
          equal(input(storage.quality_fake).insert{name = MODEL, count = 1, quality = wrong_quality},
            1, "retry wrong-quality activation after real return")
          output(storage.wrong_surface).clear()
          input(storage.wrong_surface).clear()
          storage.wrong_surface_products = storage.wrong_surface.products_finished
          storage.wrong_surface_events_at_return = storage.wrong_surface_events or 0
          recipe(storage.wrong_surface, ACTIVATE, payload_quality)
          equal(input(storage.wrong_surface).insert{name = MODEL, count = 1, quality = payload_quality},
            1, "matching-quality wrong-surface Model cannot consume genuine return credit")
        end
        storage.return_reload_tick = game.tick
      elseif phase == "won" then
        equal(state().completed, true, "victory survives separate-process reload")
        equal(helpers.table_to_json(state().victory), helpers.table_to_json(storage.victory), "once-only victory unchanged")
        equal(state().models_activated, 1, "reload does not reactivate")
        equal(game.finished, false, "continued freeplay survives reload")
        -- Reuse the genuine displayed output, without creating a second credit.
        storage.replay = make(game.surfaces.nauvis, DC, {24, 0})
        recipe(storage.replay, ACTIVATE)
        transfer(storage.display, input(storage.replay), MODEL, 1)
        storage.freeplay_start, storage.stage = game.tick, "freeplay"
        game.speed = 100
        return
      end
      report(phase .. "_reload_passed", {saved_tick = storage.saved_tick,
        pod = phase == "flight" and storage.flight_pod_id or nil})
      storage.stage, game.speed = phase, 100
      if phase == "assembly" then
        -- Block the original banked batch after reload, without resetting work
        -- or replacing its committed ingredients. Full native progress may be
        -- 1 while the actual completion event still waits for output space.
        local inv = output(storage.assembler)
        equal(inv.insert{name = MODEL, count = #inv * prototypes.item[MODEL].stack_size, quality = payload_quality},
          #inv * prototypes.item[MODEL].stack_size, "adversarial blocked output filled")
        storage.stage, storage.blocked_tick = "blocked", game.tick
      end
    end
    if storage.stage == "checkpoint" or storage.stage == "done" then return end
    if options.adversarial and not storage.pure_ledger then ledger_fixture() end
    if game.tick % 18000 == 0 then
      local snapshot = remote.call("bitermotors", "endgame_status", "player")
      log(prefix .. " native ending: " .. storage.stage .. " " .. helpers.table_to_json{
        agi = snapshot.agi, cooling = snapshot.cooling, core = snapshot.cores[1]})
      if storage.assembler.valid then
        log("assembly physical: " .. helpers.table_to_json{status = storage.assembler.status,
          energy = storage.assembler.energy, output = output(storage.assembler).get_contents(),
          chest = storage.model_chest.get_inventory(defines.inventory.chest).get_contents(),
          disabled = storage.assembler.disabled_by_script, products = storage.assembler.products_finished,
          source_watts = storage.orbit_power.power_production})
      end
    end
    if storage.stage == "compute" and storage.native_datasets == 20000 then
      equal(state().cumulative_ai_tokens, 1000000000, "one billion native earned equivalents")
      negative_checks()
      -- Hyper is an efficiency option, not permission to assemble or activate.
      game.forces.player.technologies["bitermotors-hyperscale-training"].researched = false
      storage.gate_tick, storage.stage = game.tick, "gate"
    elseif storage.stage == "gate" and game.tick > storage.gate_tick + 120 then
      equal(state().unlocked, true, "grid-scale research and earned billion suffice without Hyper")
      equal(game.forces.player.recipes[ASSEMBLE].enabled, true, "assembly unlocked without Hyper")
      equal(prototypes.recipe[ASSEMBLE].energy, 90, "90 native recipe seconds")
      equal(prototypes.recipe[ACTIVATE].energy, 30, "30 native activation seconds")
      check(math.abs(storage.terminal.prototype.energy_usage * 60 - 8000000) < 0.001,
        "ordinary 8MW datacenter")
      local payload = game.create_inventory(201)
      for _, core in ipairs(storage.cores) do
        equal(core.products_finished, 125, "all supplied Dollars consumed by native batches")
        transfer(output(core), payload, DATASET, 500)
        if core ~= storage.assembler then core.destroy{raise_destroy = true} end
      end
      equal(count(payload, DATASET), 20000, "entire physical 20k payload extracted from earned outputs")
      -- Leave exactly one radiator on this platform for the assembly test.
      local radiators = storage.platform.surface.find_entities_filtered{name = "bitermotors-orbital-radiator-panel"}
      for i = 2, #radiators do radiators[i].destroy{raise_destroy = true} end
      storage.radiator = radiators[1]
      recipe(storage.assembler, ASSEMBLE)
      storage.assembler.disabled_by_script = true
      equal(storage.assembler.crafting_speed, 1.5, "normal native assembly speed")
      transfer(payload, input(storage.assembler), DATASET, 19999)
      equal(input(storage.assembler).insert{name = RACK, count = 1, quality = payload_quality}, 1, "supplied physical Rack")
      storage.payload, storage.stage, storage.partial_tick = payload, "partial", game.tick
      storage.assembler.disabled_by_script = false
    elseif storage.stage == "partial" and game.tick > storage.partial_tick + 60 then
      equal(storage.assembler.crafting_progress, 0, "19999 Datasets cannot assemble")
      storage.assembler.disabled_by_script = true
      transfer(storage.payload, input(storage.assembler), DATASET, 1)
      equal(count(input(storage.assembler), DATASET), 20000, "actual full 20k input loading assertion")
      equal(count(input(storage.assembler), RACK), 1, "entire Rack payload loaded")
      storage.payload.destroy()
      storage.assembler.disabled_by_script, storage.stage = false, "assembly"
      report("payload_passed", {datasets_loaded = 20000, earned_equivalents = state().cumulative_ai_tokens})
    elseif storage.stage == "blocked" and game.tick > storage.blocked_tick + 4000 then
      equal(storage.assembler.status, defines.entity_status.full_output, "native full_output observed beyond full 60-second craft")
      equal(storage.assembler.products_finished, storage.reloaded_products, "full output cannot complete native batch")
      equal(state().models_assembled, 0, "blocked output and injected Model cannot mint assembly credit")
      equal(state().assembly_credits, 0, "no native completion while output is blocked")
      equal(storage.native_assemblies, 0, "blocked output has no native assembly event")
      output(storage.assembler).clear()
      storage.stage = "assembly"
    elseif storage.stage == "assembly" then
      local machine = storage.assembler
      if not storage.assembly_reload_tick and machine.crafting_progress > 0.3 then
        for _, source in ipairs(storage.platform.surface.find_entities_filtered{name = "electric-energy-interface"}) do
          source.power_production, source.output_flow_limit, source.energy = 0, 0, 0
        end
        storage.radiator_position = storage.radiator.position
        storage.radiator.destroy{raise_destroy = true}
        storage.outage_tick, storage.outage_progress, storage.stage = game.tick, machine.crafting_progress, "outage"
      elseif storage.assembly_finished and count(storage.model_chest.get_inventory(defines.inventory.chest), MODEL) == 1 then
        check(machine.products_finished > storage.reloaded_products, "new physical Model produced after assembly reload")
        check(storage.assembly_finished > storage.assembly_reload_tick, "new native assembly event after reload")
        equal(count(output(machine), MODEL), 0, "native inserter physically extracted Model")
        equal(state().assembly_credits, 1, "extraction does not erase credit")
        -- Exercise same-platform credit persistence after immediate machine removal.
        local products = machine.products_finished
        machine.destroy{raise_destroy = true}
        equal(state().assembly_credits, 1, "machine removal does not erase earned assembly credit")
        local hub = storage.platform.hub
        local point = assert(hub.get_logistic_point(defines.logistic_member_index.space_platform_hub_requester))
        point.trash_not_requested = true
        hub.request_missing_construction_materials = false
        local section = storage.pad.get_logistic_sections().add_section()
        section.set_slot(1, {value = {type = "item", name = MODEL, quality = payload_quality, comparator = "="}, min = 1})
        transfer(storage.model_chest.get_inventory(defines.inventory.chest), hub.get_inventory(defines.inventory.hub_main), MODEL, 1)
        storage.stage = "returning"
        report("assembly_passed", {products_after_reload = products,
          assembly_reload_tick = storage.assembly_reload_tick, native_completion_tick = storage.assembly_finished})
      elseif storage.assembly_reload_tick then storage.model_arm.disabled_by_script = false end
    elseif storage.stage == "outage" and game.tick > storage.outage_tick + 180 then
      check(storage.assembler.crafting_progress >= storage.outage_progress, "orbital outage banks progress")
      check(storage.assembler.crafting_progress < 1, "outage cannot finish assembly")
      equal(count(input(storage.assembler), DATASET), 0, "banked assembly retains committed payload")
      check(state().assembly_progress >= storage.outage_progress, "status exposes banked native assembly progress")
      checkpoint("assembly", storage.assembler.crafting_progress)
    elseif storage.stage == "flight" then
      storage.stage = "returning"
    elseif storage.stage == "returning" and storage.return_delivered then
      check(storage.return_delivered >= storage.return_started, "native return event order")
      equal(count(storage.pad.get_inventory(defines.inventory.cargo_landing_pad_main), MODEL), 1, "real pod deposited Model")
      checkpoint("return", 0)
    elseif storage.stage == "return" then
      if game.tick > storage.return_reload_tick + 2400 then
        negative_checks()
        if options.adversarial then
          check(storage.quality_fake.products_finished > storage.wrong_quality_products,
            "wrong-quality negative completed anew after return reload")
          check(storage.wrong_surface.products_finished > storage.wrong_surface_products
            and storage.wrong_surface_events > storage.wrong_surface_events_at_return,
            "matching-quality wrong-surface negative completed anew after return reload")
        end
        equal(state().return_credits, 1, "wrong-quality activation cannot consume returned quality credit")
        recipe(storage.terminal, ACTIVATE)
        transfer(storage.pad.get_inventory(defines.inventory.cargo_landing_pad_main), input(storage.terminal), MODEL, 1)
        storage.stage = "activation"
      end
    elseif storage.stage == "activation" then
      if not storage.activation_sample_tick and storage.terminal.crafting_progress > 0.05 then
        storage.activation_sample_tick = game.tick
        storage.activation_sample_joules = storage.ground_pole.electric_network_statistics.get_input_count{
          name = DC, quality = "normal"}
      elseif storage.activation_sample_tick and not storage.activation_measured_watts
        and game.tick >= storage.activation_sample_tick + 60 then
        storage.activation_measured_watts = storage.ground_pole.electric_network_statistics.get_input_count{
          name = DC, quality = "normal"} - storage.activation_sample_joules
        check(math.abs(storage.activation_measured_watts - 8000000) < 400000,
          "native activation draws approximately 8MW including ordinary drain: " .. tostring(storage.activation_measured_watts))
      end
      if not storage.activation_reload_tick and storage.terminal.crafting_progress > 0.3 then
        check(storage.activation_measured_watts ~= nil, "native activation power measured before outage")
        negative_checks()
        check(state().activation_progress > 0, "status exposes native activation progress")
        storage.activation_outage_tick, storage.stage = game.tick, "activation_outage"
        -- The injected-case sources share the Nauvis electric network.
        storage.ground_sources = game.surfaces.nauvis.find_entities_filtered{name = "electric-energy-interface"}
        for _, source in ipairs(storage.ground_sources) do
          source.power_production, source.output_flow_limit, source.energy = 0, 0, 0
        end
      end
    elseif storage.stage == "activation_outage" then
      local machine = storage.terminal
      local stopped = machine.status == defines.entity_status.no_power or machine.status == defines.entity_status.low_power
      if stopped and game.tick > storage.activation_outage_tick + 180 and not storage.activation_stopped_progress then
        storage.activation_stopped_progress, storage.activation_stopped_tick = machine.crafting_progress, game.tick
      elseif storage.activation_stopped_tick and game.tick > storage.activation_stopped_tick + 180 then
        check(stopped, "native activation low/no_power observed through checkpoint")
        equal(machine.crafting_progress, storage.activation_stopped_progress, "activation outage retains exact progress")
        equal(count(input(machine), MODEL), 0, "original Model stays committed during activation outage")
        equal(state().return_credits, 1, "activation outage does not consume return credit")
        equal(machine.products_finished, 0, "outage cannot activate")
        checkpoint("activation", machine.crafting_progress)
      end
    elseif storage.stage == "activation_finished" then
      check(storage.terminal.products_finished > storage.reloaded_products,
        "new activation product after reload, not an old output")
      check(count(output(storage.terminal), MODEL) > storage.reloaded_output,
        "new physical activation output after reload, not an old output")
      storage.display = game.create_inventory(1)
      transfer(output(storage.terminal), storage.display, MODEL, 1)
      storage.terminal.destroy{raise_destroy = true}
      equal(state().completed, true, "immediate post-event extraction/removal preserves victory")
      checkpoint("won", 1)
    elseif storage.stage == "freeplay" and game.tick >= storage.freeplay_start + 2400 then
      check(storage.replay.products_finished > 0, "genuine output reran native activation without a new credit")
      equal(state().models_assembled, 1, "no duplicate assembly during freeplay")
      equal(state().models_returned, 1, "no duplicate return during freeplay")
      equal(state().models_activated, 1, "no duplicate activation during freeplay")
      equal(helpers.table_to_json(state().victory), helpers.table_to_json(storage.victory), "victory stays once-only")
      report("won_reload_passed", {saved_tick = storage.saved_tick, victory = state().victory,
        freeplay_ticks = game.tick - storage.freeplay_start, native_activations = storage.native_activations,
        activation_measured_watts = storage.activation_measured_watts})
      storage.stage = "done"
    end
  end)
end
if script.mod_name == "bitermotors_delivery_validation" then M.run() end
return M
