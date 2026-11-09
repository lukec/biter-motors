-- Practical I/O rehearsal: supplied Nauvis stock/technology, real rockets and solar.
local config = require("platform-config")
local Layout = require("orbital-layout")
local P = "bitermotors-"
local CORE, SOLAR, RADIATOR = P .. "orbital-datacenter-core", P .. "high-density-space-solar-panel", P .. "orbital-radiator-panel"
local DOLLAR, TOKEN, DATASET = P .. "dollar", P .. "ai-token", P .. "agi-training-dataset"
local REPORT = "bitermotors-platform.jsonl"
local loaded, assertions = false, 0
local function check(ok, text) assert(ok, text); assertions = assertions + 1 end
local function equal(a, b, text) check(a == b, text .. ": " .. tostring(a) .. " != " .. tostring(b)) end
local function inventory(e, kind) return assert(e.get_inventory(kind), e.name .. " inventory") end
local function contents(inv)
  local out = {}
  for _, stack in pairs(inv.get_contents()) do
    equal(stack.quality, "normal", "normal cargo")
    out[stack.name] = (out[stack.name] or 0) + stack.count
  end
  return out
end
local function accumulate(to, from)
  for name, n in pairs(from) do to[name] = (to[name] or 0) + n end
end
local function count(inv, name) return inv.get_item_count(name) end
local function supplied(inv, name, amount)
  equal(inv.insert{name = name, count = amount}, amount, "finite Nauvis supply " .. name)
end
local function ground(name, x, y)
  return assert(game.surfaces.nauvis.create_entity{name = name, position = {x, y}, force = "player", raise_built = true}, name)
end
local function report(status, extra)
  local row = extra or {}
  row.status, row.tick, row.assertions = status, game.tick, assertions
  row.cores, row.recipe = config.cores, config.recipe
  row.source_sha256 = config.source_sha256
  row.scope = "native-platform-logistics"
  row.limits = "Finite finished hardware, operating Dollars, rocket ingredients, technology and Nauvis power supplied. No platform entities/items, solar multipliers or crafting progress supplied. Not a natural campaign."
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
  storage.assertions = assertions
end
local function request(entity, name, amount, minimum, from)
  local section = entity.get_logistic_sections().add_section()
  section.set_slot(1, {value = {type = "item", name = name, quality = "normal", comparator = "="},
    min = amount, max = amount, minimum_delivery_count = minimum, import_from = from})
end
local function filter(entity, names)
  entity.use_filters = true
  for i, name in ipairs(names) do entity.set_filter(i, name) end
end
local function native_status()
  local agi = remote.call("bitermotors", "endgame_status", "player")
  local output = storage.output_item
  local physical = count(inventory(storage.pad, defines.inventory.cargo_landing_pad_main), output)
  return {produced = storage.produced, returned = storage.returned, physical_returned = physical,
    completions = storage.completions, earned_equivalents = agi.cumulative_ai_tokens,
    operation_tick = storage.operation_tick, first_completion_tick = storage.first_completion_tick,
    last_completion_tick = storage.last_completion_tick, rockets = storage.rockets,
    rocket_parts = game.forces.player.get_item_production_statistics(game.surfaces.nauvis).get_input_count("rocket-part"),
    rocket_supplied = storage.rocket_supplied, shipments = storage.shipments,
    rocket_input_remaining = contents(inventory(storage.silo, defines.inventory.crafter_input)),
    shipped = storage.shipped, delivered = storage.delivered, manifest = storage.manifest,
    built = storage.built, built_tiles = storage.built_tiles, foundation_added = storage.foundation_added,
    solar_multiplier = storage.platform.surface and storage.platform.surface.solar_power_multiplier,
    solar_coefficient = storage.platform.space_location.solar_power_in_space,
    core_rated_watts = prototypes.entity[CORE].energy_usage * 60,
    wing_nominal_watts = prototypes.entity[SOLAR].get_max_energy_production("normal") * 60,
    output_item = output, batch_output = storage.batch_output, batch_dollars = storage.batch_dollars,
    cycle_ticks = storage.cycle_ticks, target_batches = storage.target_batches,
    blueprint_roundtrip = storage.blueprint_roundtrip,
    core_products = storage.core_products, low_power_samples = storage.low_power_samples,
    no_cooling_samples = storage.no_cooling_samples, return_pods = storage.return_pods,
    measured_ticks = storage.operation_tick and game.tick - storage.operation_tick or 0}
end
script.on_init(function()
  game.tick_paused, game.speed = false, 100
  local force, surface = game.forces.player, game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 5); surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area = {{-70, -50}, {70, 70}}}) do e.destroy() end
  local tiles = {}
  for x = -70, 70 do for y = -50, 70 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  surface.set_tiles(tiles)
  force.research_all_technologies(true)
  storage.layout = Layout.make(config.cores, config.recipe)
  storage.manifest = { ["space-platform-starter-pack"] = 1 }
  storage.stage, storage.start_tick = "starter", game.tick
  storage.shipped, storage.delivered, storage.shipments, storage.pods = {}, {}, {}, {}
  storage.cores, storage.core_products = {}, {}
  storage.built, storage.built_tiles, storage.foundation_added = {}, 0, 0
  storage.rockets, storage.produced, storage.returned, storage.completions, storage.return_pods = 0, 0, 0, 0, 0
  storage.low_power_samples, storage.no_cooling_samples = 0, 0
  storage.rocket_supplied = {}
  local recipe = force.recipes[config.recipe]
  equal(#recipe.products, 1, "one measurable output")
  storage.output_item, storage.batch_output = recipe.products[1].name, recipe.products[1].amount
  storage.batch_dollars = recipe.ingredients[1].amount
  equal(recipe.ingredients[1].name, DOLLAR, "compute operating cash")
  storage.cycle_ticks = recipe.energy / prototypes.entity[CORE].get_crafting_speed("normal") * 60
  storage.target_batches = config.cores * config.batches
  local power = ground("electric-energy-interface", -20, -20)
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production, power.output_flow_limit = 10000000000, 10000000000
  for _, pos in ipairs({{-20, -16}, {-20, -8}, {-10, -8}, {0, -8}, {8, 4}, {8, 12}, {0, 12}, {0, 20}}) do ground("substation", pos[1], pos[2]) end
  storage.provider = ground("passive-provider-chest", 0, 12)
  local port = ground("roboport", 0, 20)
  supplied(inventory(port, defines.inventory.roboport_robot), "logistic-robot", 100)
  storage.silo = ground("rocket-silo", 0, 0)
  storage.silo.use_transitional_requests = true
  storage.silo.set_recipe("rocket-part")
  storage.pad = ground("cargo-landing-pad", -20, 0)
  supplied(inventory(storage.provider, defines.inventory.chest), "space-platform-starter-pack", 1)
  storage.platform = assert(force.create_space_platform{name = "Practical compute " .. config.cores,
    planet = "nauvis", starter_pack = "space-platform-starter-pack"})
  equal(storage.platform.hub, nil, "real starter required")
  storage.platform.paused = true
  report("setup_passed", {layout = storage.layout, technologies_supplied = true,
    bulk_capacity_bonus = force.bulk_inserter_capacity_bonus})
end)
script.on_load(function() loaded = storage.stage == "checkpoint"; assertions = storage.assertions or 0 end)
local function create_layout()
  local layout, surface = storage.layout, storage.platform.surface
  equal(surface.get_property("gravity"), 0, "native orbital gravity")
  equal(storage.platform.space_location.solar_power_in_space, 300, "Nauvis native solar")
  equal(#surface.find_entities_filtered{type = "electric-energy-interface"}, 0, "no orbital EEI")
  storage.role_by_position = {}
  for _, tile in ipairs(layout.tiles) do
    if surface.get_tile(tile.position).name ~= "space-platform-foundation" then
      assert(surface.create_entity{name = "tile-ghost", inner_name = "space-platform-foundation", position = tile.position, force = "player"})
      storage.foundation_added = storage.foundation_added + 1
    end
  end
  for _, e in ipairs(layout.entities) do
    storage.role_by_position[e.position.x .. ":" .. e.position.y] = e.role
    assert(surface.create_entity{name = "entity-ghost", inner_name = e.name, position = e.position,
      direction = e.direction, force = "player", expires = false}, e.name)
  end
  layout.manifest["space-platform-foundation"] = storage.foundation_added
  layout.manifest[DOLLAR] = storage.target_batches * storage.batch_dollars
  accumulate(storage.manifest, layout.manifest)
  local provider = inventory(storage.provider, defines.inventory.chest)
  for name, amount in pairs(layout.manifest) do supplied(provider, name, amount) end
  storage.platform.hub.request_missing_construction_materials = false
  for name, amount in pairs(layout.manifest) do request(storage.platform.hub, name, amount, 1, "nauvis") end
  request(storage.pad, storage.output_item, 1000000000, nil, nil)
  storage.stage = "construction"
  report("starter_delivered", {layout = layout, manifest = storage.manifest, starter_tick = storage.starter_tick})
end
script.on_event(defines.events.on_space_platform_built_entity, function(event)
  if event.platform ~= storage.platform then return end
  local e = event.entity
  local role = storage.role_by_position[e.position.x .. ":" .. e.position.y]
  check(role ~= nil, "only blueprint entities constructed")
  equal(event.stack.name, e.name, "real construction item")
  equal(e.quality.name, "normal", "normal construction quality")
  storage.built[e.name] = (storage.built[e.name] or 0) + 1
  if role == "core" then
    e.set_recipe(config.recipe); e.disabled_by_script = true
    storage.cores[#storage.cores + 1] = e
  elseif e.type == "inserter" then
    if role == "hub-input" or role == "core-input" then
      filter(e, {DOLLAR})
      e.inserter_stack_size_override = 1
    else
      filter(e, {TOKEN, DATASET, P .. "agi-model"})
    end
    e.disabled_by_script = true
  end
end)
script.on_event(defines.events.on_space_platform_built_tile, function(event)
  if event.platform == storage.platform then storage.built_tiles = storage.built_tiles + #event.tiles end
end)
script.on_event(defines.events.on_rocket_launched, function(event)
  if event.rocket_silo == storage.silo then storage.rockets = storage.rockets + 1 end
end)
script.on_event(defines.events.on_cargo_pod_finished_ascending, function(event)
  local pod = event.cargo_pod
  if pod.cargo_pod_origin ~= storage.silo then return end
  check(event.launched_by_rocket, "native rocket ascent")
  local cargo = contents(inventory(pod, defines.inventory.cargo_unit))
  local mass, slots = 0, 0
  for name, amount in pairs(cargo) do
    check(storage.manifest[name] ~= nil, "manifest cargo only")
    mass = mass + prototypes.item[name].weight * amount
    slots = slots + math.ceil(amount / prototypes.item[name].stack_size)
  end
  check(mass > 0 and mass <= 1000000, "rocket mass limit")
  check(slots <= #inventory(pod, defines.inventory.cargo_unit), "native pod slots")
  local row = {cargo = cargo, mass = mass, slots = slots, tick = game.tick}
  accumulate(storage.shipped, cargo)
  storage.shipments[#storage.shipments + 1], storage.pods[pod.unit_number] = row, row
end)
script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
  local pod = event.cargo_pod
  if not storage.platform.hub or pod.cargo_pod_origin ~= storage.platform.hub then return end
  local cargo = contents(inventory(pod, defines.inventory.cargo_unit))
  for name in pairs(cargo) do equal(name, storage.output_item, "only computed output returns") end
  check((cargo[storage.output_item] or 0) > 0, "nonempty native return")
  storage.pods[pod.unit_number] = {return_count = cargo[storage.output_item], tick = game.tick}
  storage.return_pods = storage.return_pods + 1
end)
script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
  local row = storage.pods[event.cargo_pod.unit_number]
  if row and row.return_count then
    equal(event.cargo_pod.cargo_pod_destination.station, storage.pad, "canonical landing pad destination")
    row.correct_pad = true
  end
end)
script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
  local pod, row = event.cargo_pod, storage.pods[event.cargo_pod.unit_number]
  if not row then return end
  equal(event.spawned_container, nil, "no spilled cargo")
  if row.return_count then
    check(row.correct_pad, "real descent to the requested pad")
    equal(pod.surface, storage.pad.surface, "Nauvis return")
    storage.returned = storage.returned + row.return_count
  else
    accumulate(storage.delivered, row.cargo)
    if row.cargo["space-platform-starter-pack"] then storage.starter_tick = game.tick end
    row.delivered_tick = game.tick
  end
  storage.pods[pod.unit_number] = nil
end)
script.on_event(prototypes.recipe[config.recipe].on_crafted_event, function(event)
  if event.recipe ~= config.recipe or event.entity.surface ~= storage.platform.surface then return end
  equal(event.bonus, false, "no productivity output")
  equal(event.product_quality, "normal", "normal output")
  storage.produced = storage.produced + storage.batch_output
  storage.completions = storage.completions + 1
  storage.first_completion_tick = storage.first_completion_tick or game.tick
  storage.last_completion_tick = game.tick
  local unit = tostring(event.entity.unit_number)
  storage.core_products[unit] = (storage.core_products[unit] or 0) + 1
end)
local function feed_rocket()
  local input = inventory(storage.silo, defines.inventory.crafter_input)
  for _, ingredient in pairs(game.forces.player.recipes["rocket-part"].ingredients) do
    -- Ground intermediates only; native silo progress and launches stay untouched.
    local inserted = input.insert{name = ingredient.name, count = ingredient.amount * 50}
    storage.rocket_supplied[ingredient.name] = (storage.rocket_supplied[ingredient.name] or 0) + inserted
  end
end
local function construction_done()
  if storage.built_tiles ~= storage.foundation_added or next(storage.pods) then return false end
  for name, amount in pairs(storage.layout.manifest) do
    if name ~= "space-platform-foundation" and name ~= DOLLAR and (storage.built[name] or 0) ~= amount then return false end
    if (storage.delivered[name] or 0) ~= amount then return false end
  end
  return true
end
local function export_blueprint()
  local inv = game.create_inventory(2)
  inv[1].set_stack{name = "blueprint"}
  inv[1].create_blueprint{surface = storage.platform.surface, force = "player",
    area = {{-11, -5}, {4 * config.cores + 2, 35}}, include_entities = true, always_include_tiles = true}
  inv[1].label = "Biter Motors orbital compute - " .. config.cores .. " cluster(s)"
  check(inv[1].is_blueprint_setup(), "native blueprint export")
  local encoded = inv[1].export_stack()
  equal(inv[2].import_stack(encoded), 0, "native blueprint import has no errors")
  equal(#inv[2].get_blueprint_entities(), #storage.layout.entities + 1, "blueprint retains every entity and hub")
  local hubs = 0
  for _, entity in ipairs(inv[2].get_blueprint_entities()) do
    if entity.name == "space-platform-hub" then hubs = hubs + 1 end
  end
  equal(hubs, 1, "one native starter hub in blueprint")
  equal(#inv[2].get_blueprint_tiles(), #inv[1].get_blueprint_tiles(), "blueprint retains foundation")
  storage.blueprint_roundtrip = true
  helpers.write_file("orbital-compute-" .. config.cores .. ".txt", encoded, false)
  helpers.write_file("orbital-layout-" .. config.cores .. ".json", helpers.table_to_json(storage.layout), false)
  inv.destroy()
end
local function checkpoint(phase)
  storage.resume_phase, storage.saved_tick = phase, game.tick
  storage.saved_produced, storage.saved_returned = storage.produced, storage.returned
  storage.stage = "checkpoint"
  report(phase .. "_checkpoint", native_status())
  game.server_save("bitermotors-platform-" .. phase)
end
script.on_nth_tick(60, function()
  if game.tick == 0 then return end
  if storage.stage == "done" then return end
  if storage.stage == "checkpoint" then
    if not loaded then return end
    loaded = false
    check(game.tick > storage.saved_tick, "actual reload advances time")
    equal(storage.produced, storage.saved_produced, "native completions persisted")
    equal(storage.returned, storage.saved_returned, "native deliveries persisted")
    if storage.resume_phase == "complete" then
      equal(count(inventory(storage.pad, defines.inventory.cargo_landing_pad_main), storage.output_item), storage.returned, "physical returned output persisted")
      local row = native_status(); row.saved_tick = storage.saved_tick
      report("reload_passed", row); storage.stage = "done"
    else
      storage.stage, storage.mid_reloaded = "operation", true
      report("mid_reload_passed", native_status())
    end
    return
  end
  if game.tick - storage.start_tick > 3000000 then
    report("failed", native_status()); error("platform fixture simulation timeout: " .. storage.stage)
  end
  if storage.stage == "starter" then
    feed_rocket()
    if storage.starter_tick then create_layout() end
  elseif storage.stage == "construction" then
    feed_rocket()
    if construction_done() then
      equal(storage.platform.surface.solar_power_multiplier, 1, "real solar multiplier")
      equal(#storage.platform.surface.find_entities_filtered{type = "electric-energy-interface"}, 0, "no supplied orbital power")
      local point = storage.platform.hub.get_logistic_point(defines.logistic_member_index.space_platform_hub_requester)
      point.trash_not_requested = true
      for _, core in ipairs(storage.cores) do core.disabled_by_script = false end
      for _, arm in pairs(storage.platform.surface.find_entities_filtered{type = "inserter"}) do arm.disabled_by_script = false end
      export_blueprint()
      storage.stage, storage.operation_tick = "operation", game.tick
      report("built_passed", native_status())
    end
  elseif storage.stage == "operation" then
    local state = remote.call("bitermotors", "endgame_status", "player")
    for _, core in ipairs(state.cores) do
      if core.power_limited then storage.low_power_samples = storage.low_power_samples + 1 end
      if not core.cooled then storage.no_cooling_samples = storage.no_cooling_samples + 1 end
    end
    if not storage.mid_reloaded and ((config.raw and game.tick - storage.operation_tick >= 18000)
      or (not config.raw and storage.completions >= math.max(2, math.floor(storage.target_batches / 2)))) then
      checkpoint("mid")
    elseif config.raw and game.tick - storage.operation_tick >= 36000 and storage.mid_reloaded then
      local row = native_status(); row.raw_baseline = true
      check(storage.returned < storage.produced, "raw-token transport deficit is actually observed")
      report("measured_passed", row); checkpoint("complete")
    elseif not config.raw and storage.completions == storage.target_batches and storage.returned == storage.produced and not next(storage.pods) then
      equal(storage.produced, storage.target_batches * storage.batch_output, "exact native output")
      equal(count(inventory(storage.pad, defines.inventory.cargo_landing_pad_main), storage.output_item), storage.produced, "real delivered physical output")
      equal(storage.low_power_samples, 0, "solar keeps all clusters powered")
      equal(storage.no_cooling_samples, 0, "radiators serve all clusters")
      local multiplier = storage.output_item == DATASET and 50000 or 1
      equal(state.cumulative_ai_tokens, storage.produced * multiplier, "earned-equivalent conservation")
      check(next(storage.core_products) ~= nil, "real native completions")
      report("measured_passed", native_status()); checkpoint("complete")
    end
  end
  if game.tick % 3600 == 0 then
    local row = native_status(); row.stage = storage.stage
    if storage.platform.hub then
      row.hub = contents(inventory(storage.platform.hub, defines.inventory.hub_main))
      row.ghosts = #storage.platform.surface.find_entities_filtered{type = "entity-ghost"}
      row.tile_ghosts = #storage.platform.surface.find_entities_filtered{type = "tile-ghost"}
      row.remaining_ghosts = {}
      for _, e in pairs(storage.platform.surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}}) do
        if #row.remaining_ghosts < 5 then
          row.remaining_ghosts[#row.remaining_ghosts + 1] = {name = e.ghost_name, position = e.position}
        end
      end
      row.core_diagnostics = {}
      for _, core in ipairs(storage.cores) do
        row.core_diagnostics[#row.core_diagnostics + 1] = {status = core.status, enabled = core.get_recipe().enabled,
          recipe = core.get_recipe().name, progress = core.crafting_progress, disabled = core.disabled_by_script,
          input = contents(inventory(core, defines.inventory.crafter_input)), energy = core.energy}
      end
    end
    helpers.write_file("bitermotors-platform-progress.jsonl", helpers.table_to_json(row) .. "\n", true)
  end
end)
