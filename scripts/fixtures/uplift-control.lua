-- Isolated slice-1 qualification. Only Nauvis receives supplied items/power.
-- API contract: https://lua-api.factorio.com/2.1.20/runtime-api.json
local REPORT = "bitermotors-uplift.jsonl"
local CORE = "bitermotors-orbital-datacenter-core"
local SOLAR = "bitermotors-high-density-space-solar-panel"
local RADIATOR = "bitermotors-orbital-radiator-panel"
local DOLLAR, TOKEN = "bitermotors-dollar", "bitermotors-ai-token"
local ENTRY, COMPUTE = "bitermotors-orbital-compute", "bitermotors-orbital-ai-token"
local MANIFEST = {
  {name = "space-platform-starter-pack", count = 1},
  {name = "space-platform-foundation", count = 100},
  {name = CORE, count = 1}, {name = SOLAR, count = 5},
  {name = RADIATOR, count = 1}, {name = "transport-belt", count = 12},
  {name = "inserter", count = 4}, {name = DOLLAR, count = 100}
}
local assertions, loaded = 0, false
local function check(ok, label) assert(ok, label); assertions = assertions + 1 end
local function equal(a, b, label)
  check(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function report(status, fields)
  local row = fields or {}
  row.status, row.tick, row.assertions = status, game.tick, assertions
  storage.assertions = assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end
local function inv(entity, kind) return assert(entity.get_inventory(kind), entity.name .. " inventory") end
local function ground(name, position)
  return assert(game.surfaces.nauvis.create_entity{name = name, position = position,
    force = "player", raise_built = true}, "ground placement " .. name)
end
local function supplied(inventory, name, count)
  equal(inventory.insert{name = name, count = count, quality = "normal"}, count, "ground supply " .. name)
end
local function request(entity, name, count, minimum)
  local section = assert(entity.get_logistic_sections().add_section())
  section.set_slot(1, {value = {type = "item", name = name, quality = "normal", comparator = "="},
    min = count, max = count, minimum_delivery_count = minimum, import_from = "nauvis"})
  equal(section.get_slot(1).min, count, "native request " .. name)
  if minimum then
    equal(section.get_slot(1).minimum_delivery_count, minimum, "native partial launch minimum " .. name)
    storage.requests = storage.requests or {}
    storage.requests[name] = {count = count, minimum_delivery_count = minimum}
  end
end
local function counts(inventory)
  local result = {}
  for _, stack in pairs(inventory.get_contents()) do
    equal(stack.quality, "normal", "normal cargo quality")
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end
local function accumulate(target, source)
  for name, count in pairs(source) do target[name] = (target[name] or 0) + count end
end
local function expected()
  local result = {}
  for _, item in ipairs(MANIFEST) do result[item.name] = item.count end
  return result
end
local function same_counts(actual, wanted, label)
  for name, count in pairs(wanted) do equal(actual[name] or 0, count, label .. " " .. name) end
  for name, count in pairs(actual) do equal(count, wanted[name] or 0, label .. " unexpected " .. name) end
end
local function inspect_contract()
  local weights, footprints = {}, {}
  for name, mass in pairs({[CORE] = 100000, [SOLAR] = 25000, [RADIATOR] = 100000,
    [DOLLAR] = 10, ["bitermotors-agi-model"] = 1000, [TOKEN] = 1,
    ["bitermotors-agi-training-dataset"] = 1000}) do
    weights[name] = prototypes.item[name].weight
    equal(weights[name], mass, "runtime item mass " .. name)
  end
  for _, name in ipairs({CORE, SOLAR, RADIATOR}) do
    local p = prototypes.entity[name]
    footprints[name] = {p.tile_width, p.tile_height}
    equal(p.tile_width, 3, "3-wide " .. name); equal(p.tile_height, 3, "3-high " .. name)
    equal(p.selection_box.right_bottom.x - p.selection_box.left_top.x, 3, "selection width " .. name)
    equal(p.selection_box.right_bottom.y - p.selection_box.left_top.y, 3, "selection height " .. name)
    local gravity = false
    for _, condition in pairs(p.surface_conditions or {}) do
      if condition.property == "gravity" then
        equal(condition.min, 0, "minimum gravity"); equal(condition.max, 0, "maximum gravity")
        gravity = true
      end
    end
    check(gravity, "orbital-only hardware " .. name)
  end
  equal(prototypes.entity[CORE].energy_usage * 60, 250000000, "250MW core")
  equal(prototypes.entity[SOLAR].get_max_energy_production("normal") * 60, 20000000, "20MW nominal wing")
  local ingredients = {}
  for _, ingredient in pairs(game.forces.player.technologies[ENTRY].research_unit_ingredients) do
    ingredients[ingredient.name] = ingredient.amount
  end
  same_counts(ingredients, {["automation-science-pack"] = 1, ["logistic-science-pack"] = 1,
    ["chemical-science-pack"] = 1, ["production-science-pack"] = 1,
    ["utility-science-pack"] = 1, [DOLLAR] = 1, [TOKEN] = 1}, "entry research")
  return weights, footprints, ingredients
end
local function prerequisites(technology, seen)
  if seen[technology.name] then return end
  seen[technology.name] = true
  equal(technology.name ~= "space-science-pack", true, "no white-science prerequisite")
  for _, ingredient in pairs(technology.research_unit_ingredients) do
    check(ingredient.name ~= "space-science-pack", "no white science on entry ancestry")
  end
  for _, parent in pairs(technology.prerequisites) do prerequisites(parent, seen) end
  if technology.name ~= ENTRY and technology.name ~= "space-platform" then technology.researched = true end
end
script.on_init(function()
  game.tick_paused, game.speed = false, 100
  local force, surface = game.forces.player, game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 4); surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-50, -40}, {100, 80}}}) do entity.destroy() end
  local tiles = {}
  for x = -50, 100 do for y = -40, 80 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  surface.set_tiles(tiles)
  local power = ground("electric-energy-interface", {-20, -20})
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production, power.output_flow_limit = 10000000000, 10000000000
  for _, p in ipairs({{-20, -16}, {-20, -8}, {-10, -8}, {0, -8}, {8, 4}, {8, 12}, {-8, 12}, {-8, 16}}) do
    ground("substation", p)
  end
  storage.weights, storage.footprints, storage.science = inspect_contract()
  prerequisites(force.technologies[ENTRY], {})
  force.laboratory_speed_modifier, force.laboratory_productivity_bonus = 0, 0
  -- Supplied ordinary capacity prerequisite: the native non-bulk maximum is +2.
  force.inserter_stack_size_bonus = 2
  storage.labs = {}
  for i = 1, 50 do
    local lab = ground("lab", {-40 + ((i - 1) % 10) * 4, 20 + math.floor((i - 1) / 10) * 4})
    ground("small-electric-pole", {lab.position.x + 2, lab.position.y})
    for name, count in pairs(storage.science) do supplied(inv(lab, defines.inventory.lab_input), name, count * 30) end
    storage.labs[#storage.labs + 1] = lab
  end
  equal(force.technologies[ENTRY].research_unit_count, 1500, "entry cycles")
  equal(force.technologies["space-platform"].researched, false, "native platform trigger remains locked")
  storage.stage, storage.start_tick = "starter-manufacture", game.tick
  storage.shipped, storage.delivered, storage.pods, storage.shipments = {}, {}, {}, {}
  storage.rockets, storage.parts, storage.produced, storage.returned = 0, 0, 0, 0
  storage.built, storage.built_tiles, storage.return_pods = {}, 0, 0
  storage.manufactured = {}
  storage.provider = ground("passive-provider-chest", {0, 12})
  storage.port = ground("roboport", {0, 20})
  supplied(inv(storage.port, defines.inventory.roboport_robot), "logistic-robot", 100)
  storage.silo = ground("rocket-silo", {0, 0})
  storage.silo.use_transitional_requests = true
  storage.silo.set_recipe("rocket-part")
  storage.pad = ground("cargo-landing-pad", {-20, 0})
  storage.starter_builder = ground("assembling-machine-3", {12, -6})
  ground("substation", {12, -10})
  check(force.recipes["space-platform-starter-pack"].enabled, "rocket-silo unlocks starter recipe")
  storage.starter_builder.set_recipe("space-platform-starter-pack")
  for _, ingredient in pairs(force.recipes["space-platform-starter-pack"].ingredients) do
    supplied(inv(storage.starter_builder, defines.inventory.crafter_input), ingredient.name, ingredient.amount)
  end
  report("uplift_setup_passed", {weights = storage.weights, footprints = storage.footprints,
    science = storage.science, manifest = expected(), inserter_stack_size_bonus = force.inserter_stack_size_bonus})
end)
script.on_load(function() loaded = true; assertions = storage.assertions or 0 end)
script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name == "space-platform" then
    equal(event.by_script, false, "native create-space-platform trigger")
    storage.platform_research_tick = game.tick
    return
  end
  if event.research.name ~= ENTRY then return end
  equal(event.by_script, false, "native lab entry research")
  storage.researched_tick = game.tick
  for _, lab in ipairs(storage.labs) do
    for name in pairs(storage.science) do equal(inv(lab, defines.inventory.lab_input).get_item_count(name), 0, "science consumed") end
  end
end)
local function manufacture_setup()
  storage.builders = {}
  for index, item in ipairs(MANIFEST) do
    if item.name ~= DOLLAR and item.name ~= "space-platform-starter-pack" then
      local machine = ground("assembling-machine-3", {12 + (index - 1) * 8, -6})
      ground("substation", {machine.position.x, -10})
      local recipe = assert(game.forces.player.recipes[item.name])
      check(recipe.enabled, "unlocked native hardware " .. item.name)
      check(machine.set_recipe(item.name) ~= nil, "ground hardware recipe " .. item.name)
      local amount = 0
      for _, product in pairs(recipe.products) do
        if product.name == item.name then amount = product.amount end
      end
      check(amount > 0 and item.count % amount == 0, "deterministic whole hardware batches")
      local batches = item.count / amount
      local ingredients = {}
      for _, ingredient in pairs(recipe.ingredients) do
        equal(ingredient.type, "item", "item-only hardware ingredients")
        ingredients[ingredient.name] = {required = ingredient.amount * batches, supplied = 0}
      end
      storage.builders[#storage.builders + 1] = {machine = machine, name = item.name,
        count = item.count, batches = batches, ingredients = ingredients}
    end
  end
  storage.stage = "manufacture"
end
local function manufacture_done()
  local done = true
  for _, row in ipairs(storage.builders) do
    local input = inv(row.machine, defines.inventory.crafter_input)
    for name, ingredient in pairs(row.ingredients) do
      local remaining = ingredient.required - ingredient.supplied
      if remaining > 0 then ingredient.supplied = ingredient.supplied + input.insert{name = name, count = remaining} end
    end
    local output = inv(row.machine, defines.inventory.crafter_output)
    local count = output.get_item_count(row.name)
    if count > 0 then
      equal(output.remove{name = row.name, count = count}, count, "ground output transfer")
      supplied(inv(storage.provider, defines.inventory.chest), row.name, count)
      storage.manufactured[row.name] = (storage.manufactured[row.name] or 0) + count
    end
    if (storage.manufactured[row.name] or 0) < row.count then done = false end
  end
  if not done then return false end
  for _, row in ipairs(storage.builders) do
    equal(storage.manufactured[row.name], row.count, "exact manufactured output")
    check(row.machine.products_finished > 0, "native hardware completions")
    equal(#inv(row.machine, defines.inventory.crafter_input).get_contents(), 0, "hardware ingredients consumed")
    for _, ingredient in pairs(row.ingredients) do equal(ingredient.supplied, ingredient.required, "native manufacturing bill") end
  end
  supplied(inv(storage.provider, defines.inventory.chest), DOLLAR, 100)
  storage.stage = "uplift"
  report("uplift_manufacture_passed", {manufactured = storage.manufactured,
    researched_tick = storage.researched_tick, science_consumed = 1500,
    platform_research_tick = storage.platform_research_tick, starter_tick = storage.starter_tick})
  return true
end
local function ghost(name, position, direction)
  return assert(storage.platform.surface.create_entity{name = "entity-ghost", inner_name = name,
    position = position, direction = direction, force = "player", expires = false}, "platform ghost " .. name)
end
local function request_next_cargo()
  local item = MANIFEST[storage.request_cursor]
  request(storage.platform.hub, item.name,
    item.count + (item.name == "space-platform-foundation" and 10 or 0),
    item.name == "space-platform-foundation" and 50 or item.count)
end
local function blueprint()
  local platform = storage.platform
  equal(platform.surface.get_property("gravity"), 0, "platform gravity")
  equal(platform.space_location.solar_power_in_space, 300, "Nauvis orbit solar coefficient")
  -- Exactly 100 connected additional tiles, leaving the starter's ten spares intact.
  for x = -5, 3 do for y = 5, 15 do
    assert(platform.surface.create_entity{name = "tile-ghost", inner_name = "space-platform-foundation",
      position = {x, y}, force = "player"})
  end end
  assert(platform.surface.create_entity{name = "tile-ghost", inner_name = "space-platform-foundation",
    position = {4, 5}, force = "player"})
  ghost(CORE, {0.5, 6.5})
  for _, position in ipairs({{-3.5, 11.5}, {-0.5, 11.5}, {2.5, 11.5}, {-3.5, 14.5}, {-0.5, 14.5}}) do ghost(SOLAR, position) end
  ghost(RADIATOR, {2.5, 14.5})
  for y = 5, 9 do ghost("transport-belt", {-1.5, y + 0.5}, y == 9 and defines.direction.east or defines.direction.south) end
  ghost("transport-belt", {-0.5, 9.5}, defines.direction.north)
  ghost("transport-belt", {1.5, 9.5}, defines.direction.east)
  for y = 5, 9 do ghost("transport-belt", {2.5, y + 0.5}, defines.direction.north) end
  ghost("inserter", {-1.5, 4.5}, defines.direction.north)
  ghost("inserter", {-0.5, 8.5}, defines.direction.south)
  ghost("inserter", {1.5, 8.5}, defines.direction.north)
  ghost("inserter", {2.5, 4.5}, defines.direction.south)
  platform.hub.request_missing_construction_materials = false
  -- Native 2.1 can pack several requests into one rocket. Stage partial requests
  -- to qualify the conservative nine-launch bill without changing silo prototypes.
  -- Ten foundations arrive with the starter; request 100 MORE in two 50-item loads.
  storage.request_cursor = 2
  request_next_cargo()
  request(storage.pad, TOKEN, 10000, nil)
  storage.blueprinted = true
end
script.on_event(defines.events.on_space_platform_built_entity, function(event)
  if event.platform ~= storage.platform then return end
  local entity = event.entity
  if entity.name ~= CORE and entity.name ~= SOLAR and entity.name ~= RADIATOR
    and entity.name ~= "transport-belt" and entity.name ~= "inserter" then return end
  equal(event.stack.name, entity.name, "native platform consumes matching delivered building")
  equal(entity.quality.name, "normal", "normal native construction")
  storage.built[entity.name] = (storage.built[entity.name] or 0) + 1
  if entity.name == CORE then
    storage.core = entity
    check(entity.set_recipe(COMPUTE) ~= nil, "native orbital recipe")
    equal(entity.get_recipe().name, COMPUTE, "orbital recipe accepted")
  elseif entity.name == "inserter" then
    entity.use_filters = true
    entity.set_filter(1, entity.position.x < 0 and DOLLAR or TOKEN)
    if entity.position.x < 0 then entity.inserter_stack_size_override = 1 end
    entity.disabled_by_script = true
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
  equal(event.launched_by_rocket, true, "actual silo rocket")
  local cargo = counts(inv(pod, defines.inventory.cargo_unit))
  local destination = pod.cargo_pod_destination
  if cargo["space-platform-starter-pack"] then
    equal(destination.type, defines.cargo_destination.space_platform, "native starter destination type")
    equal(destination.space_platform, storage.platform, "native starter destination platform")
  else
    equal(destination.type, defines.cargo_destination.station, "native cargo destination type")
    equal(destination.station, storage.platform.hub, "native cargo targets platform hub")
  end
  local mass, slots = 0, 0
  for name, count in pairs(cargo) do
    mass = mass + prototypes.item[name].weight * count
    slots = slots + math.ceil(count / prototypes.item[name].stack_size)
  end
  check(mass > 0 and mass <= 1000000, "native rocket payload mass")
  local capacity = #inv(pod, defines.inventory.cargo_unit)
  check(slots <= capacity, "native payload slots")
  accumulate(storage.shipped, cargo)
  local shipment = {cargo = cargo, mass = mass, slots = slots, capacity = capacity, tick = game.tick,
    origin = "nauvis-silo", launched_by_rocket = event.launched_by_rocket}
  storage.shipments[#storage.shipments + 1] = shipment
  storage.pods[pod.unit_number] = shipment
end)
script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
  local pod = event.cargo_pod
  if not storage.platform or pod.cargo_pod_origin ~= storage.platform.hub then return end
  local cargo = counts(inv(pod, defines.inventory.cargo_unit))
  same_counts(cargo, {[TOKEN] = cargo[TOKEN] or 0}, "native return cargo")
  check((cargo[TOKEN] or 0) > 0, "nonempty native return")
  storage.pods[pod.unit_number] = {return_count = cargo[TOKEN], tick = game.tick}
  storage.return_pods = storage.return_pods + 1
end)
script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
  local pod, shipment = event.cargo_pod, storage.pods[event.cargo_pod.unit_number]
  if not shipment then return end
  equal(event.spawned_container, nil, "no spilled delivery")
  if shipment.return_count then
    equal(pod.surface, storage.pad.surface, "native ground return")
    local box, p = storage.pad.bounding_box, pod.position
    check(p.x >= box.left_top.x and p.x <= box.right_bottom.x and p.y >= box.left_top.y and p.y <= box.right_bottom.y,
      "Token pod delivered inside pad")
    storage.returned = storage.returned + shipment.return_count
  else
    if not shipment.cargo["space-platform-starter-pack"] then
      equal(pod.surface, storage.platform.surface, "silo cargo arrived on platform")
    end
    accumulate(storage.delivered, shipment.cargo)
    shipment.delivered_tick = game.tick
    if shipment.cargo["space-platform-starter-pack"] then
      check(storage.platform.hub ~= nil, "real starter deployment created hub")
      storage.starter_tick = game.tick
    end
  end
  storage.pods[pod.unit_number] = nil
end)
script.on_event(prototypes.recipe[COMPUTE].on_crafted_event, function(event)
  if event.entity ~= storage.core then return end
  equal(event.bonus, false, "ordinary native compute batch")
  equal(event.recipe, COMPUTE, "native recipe completion")
  equal(event.product_quality, "normal", "normal compute quality")
  storage.produced = storage.produced + 10000
  -- One batch is enough for slice 1; prevent another committed Dollar on the input bus.
  storage.core.disabled_by_script = true
  for _, entity in pairs(storage.platform.surface.find_entities_filtered{name = "inserter"}) do
    if entity.position.x < 0 then entity.disabled_by_script = true end
  end
end)
-- Stop native input before completion, not afterwards: native crafting may
-- commit the next batch before raising the previous batch's completion event.
script.on_nth_tick(1, function()
  if storage.stage ~= "return" or storage.feed_stopped or not storage.core.is_crafting() then return end
  for _, entity in pairs(storage.platform.surface.find_entities_filtered{name = "inserter"}) do
    if entity.position.x < 0 then entity.disabled_by_script = true end
  end
  storage.feed_stopped = true
end)
local function rocket_feed()
  -- Trickled ground input respects native per-ingredient slot limits (fuel holds 40).
  -- Allocate one rocket at a time, never write rocket_parts or crafting progress.
  local input = inv(storage.silo, defines.inventory.crafter_input)
  local parts = storage.silo.prototype.rocket_parts_required
  local limit = storage.stage == "starter-launch" and parts or 9 * parts
  if storage.silo.products_finished == storage.parts / parts and storage.silo.rocket_parts == 0
    and storage.silo.rocket == nil and #input.get_contents() == 0 and storage.parts < limit then
    storage.parts = storage.parts + parts
  end
  storage.rocket_supplied = storage.rocket_supplied or {}
  for _, ingredient in pairs(game.forces.player.recipes["rocket-part"].ingredients) do
    local already = storage.rocket_supplied[ingredient.name] or 0
    local remaining = ingredient.amount * storage.parts - already
    if remaining > 0 then
      local inserted = input.insert{name = ingredient.name, count = remaining, quality = "normal"}
      storage.rocket_supplied[ingredient.name] = already + inserted
    end
  end
end
local function built_done()
  for name, count in pairs({[CORE] = 1, [SOLAR] = 5, [RADIATOR] = 1, ["transport-belt"] = 12, ["inserter"] = 4}) do
    if (storage.built[name] or 0) < count then return false end
    equal(storage.built[name], count, "exact native building count")
  end
  return storage.built_tiles == 100
end
local function snapshot()
  local consumed = {}
  local remaining = storage.silo and counts(inv(storage.silo, defines.inventory.crafter_input)) or {}
  for name, count in pairs(storage.rocket_supplied or {}) do consumed[name] = count - (remaining[name] or 0) end
  return {shipped = storage.shipped, delivered = storage.delivered, shipments = storage.shipments,
    starter_tick = storage.starter_tick, built = storage.built, built_tiles = storage.built_tiles,
    rockets = storage.rockets,
    rocket_parts = game.forces.player.get_item_production_statistics(game.surfaces.nauvis).get_input_count("rocket-part"),
    rocket_consumed = consumed, manufactured = storage.manufactured,
    produced = storage.produced, returned = storage.returned, return_pods = storage.return_pods,
    requests = storage.requests,
    physical_tokens = storage.pad and inv(storage.pad, defines.inventory.cargo_landing_pad_main).get_item_count(TOKEN) or 0,
    foundation_remaining = storage.platform and storage.platform.hub
      and inv(storage.platform.hub, defines.inventory.hub_main).get_item_count("space-platform-foundation") or nil,
    gravity = storage.platform and storage.platform.hub and storage.platform.surface.get_property("gravity") or nil,
    solar_coefficient = storage.platform and storage.platform.hub and storage.platform.space_location.solar_power_in_space or nil,
    solar_multiplier = storage.platform and storage.platform.hub and storage.platform.surface.solar_power_multiplier or nil,
    core_watts = prototypes.entity[CORE].energy_usage * 60,
    wing_nominal_watts = prototypes.entity[SOLAR].get_max_energy_production("normal") * 60}
end
local function remaining_dollars()
  local surface, count = storage.platform.surface, 0
  for _, kind in ipairs({defines.inventory.hub_main, defines.inventory.hub_trash}) do
    count = count + inv(storage.platform.hub, kind).get_item_count(DOLLAR)
  end
  count = count + inv(storage.core, defines.inventory.crafter_input).get_item_count(DOLLAR)
  for _, entity in pairs(surface.find_entities_filtered{name = {"transport-belt", "inserter"}}) do
    if entity.name == "transport-belt" then
      for i = 1, 2 do count = count + entity.get_transport_line(i).get_item_count(DOLLAR) end
    elseif entity.held_stack.valid_for_read and entity.held_stack.name == DOLLAR then count = count + entity.held_stack.count end
  end
  return count
end
script.on_nth_tick(60, function()
  if game.tick == 0 then return end
  if storage.stage == "reload" then
    if not loaded then return end
    check(game.tick > storage.saved_tick, "reload advances time")
    equal(inv(storage.pad, defines.inventory.cargo_landing_pad_main).get_item_count(TOKEN), storage.produced,
      "physical returned Tokens survive reload")
    equal(remaining_dollars(), 99, "physical Dollars survive reload")
    local row = snapshot(); row.saved_tick = storage.saved_tick
    row.earned_equivalents = remote.call("bitermotors", "endgame_status", "player").cumulative_ai_tokens
    row.core_completions, row.dollars_remaining = storage.core.products_finished, remaining_dollars()
    equal(row.earned_equivalents, 10000, "live earned ledger survives reload")
    equal(row.core_completions, 1, "live core completions survive reload")
    report("uplift_reload_passed", row); storage.stage = "done"
    return
  elseif storage.stage == "done" then return end
  if game.tick % 3600 == 0 then
    local progress = snapshot()
    progress.stage, progress.tick = storage.stage, game.tick
    progress.research_progress = game.forces.player.research_progress
    progress.silo_status = storage.silo.status
    progress.silo_parts = storage.silo.rocket_parts
    progress.silo_inputs = counts(inv(storage.silo, defines.inventory.crafter_input))
    progress.silo_requests = storage.silo.transitional_request_target and storage.silo.transitional_request_target.name
    progress.labs = {}
    for _, lab in ipairs(storage.labs) do
      progress.labs[#progress.labs + 1] = {position = lab.position, status = lab.status, energy = lab.energy,
        inputs = counts(inv(lab, defines.inventory.lab_input)), network = lab.electric_network_id}
    end
    helpers.write_file("bitermotors-uplift-progress.jsonl", helpers.table_to_json(progress) .. "\n", true)
  end
  if game.tick - storage.start_tick > 1800000 then
    report("failed", {reason = "simulation timeout", stage = storage.stage, evidence = snapshot()})
    error("uplift fixture simulation timeout")
  end
  if storage.stage == "starter-manufacture" and storage.starter_builder.products_finished == 1 then
    equal(inv(storage.starter_builder, defines.inventory.crafter_output).remove{name = "space-platform-starter-pack", count = 1},
      1, "manufactured native starter")
    equal(#inv(storage.starter_builder, defines.inventory.crafter_input).get_contents(), 0, "starter ingredients consumed")
    supplied(inv(storage.provider, defines.inventory.chest), "space-platform-starter-pack", 1)
    storage.manufactured["space-platform-starter-pack"] = 1
    storage.platform = assert(game.forces.player.create_space_platform{name = "Native uplift",
      planet = "nauvis", starter_pack = "space-platform-starter-pack"})
    equal(storage.platform.hub, nil, "starter pack not script-applied")
    storage.platform.paused = true
    storage.stage = "starter-launch"
  elseif storage.stage == "starter-launch" then
    if storage.starter_tick and storage.platform_research_tick then
      equal(game.forces.player.technologies["space-platform"].researched, true, "real starter unlocked platform technology")
      check(game.forces.player.add_research(ENTRY), "queue actual entry research after native starter")
      storage.stage = "research"
    else rocket_feed() end
  elseif storage.stage == "research" and storage.researched_tick then manufacture_setup()
  elseif storage.stage == "manufacture" then manufacture_done()
  elseif storage.stage == "uplift" then
    rocket_feed()
    if storage.starter_tick and not storage.blueprinted then blueprint() end
    if storage.blueprinted and storage.request_cursor < #MANIFEST then
      local item = MANIFEST[storage.request_cursor]
      if (storage.delivered[item.name] or 0) >= item.count then
        storage.request_cursor = storage.request_cursor + 1
        request_next_cargo()
      end
    end
    if storage.blueprinted and built_done() and #storage.shipments == 9 and not next(storage.pods) then
      same_counts(storage.shipped, expected(), "shipped manifest")
      same_counts(storage.delivered, expected(), "delivered manifest")
      equal(storage.rockets, 9, "nine actual separate-item rockets")
      equal(storage.silo.products_finished, 9, "native completed rockets")
      equal(game.forces.player.get_item_production_statistics(game.surfaces.nauvis).get_input_count("rocket-part"),
        450, "actual native rocket parts")
      equal(inv(storage.platform.hub, defines.inventory.hub_main).get_item_count("space-platform-foundation"), 10,
        "starter foundation plus uplift minus native construction")
      equal(storage.platform.surface.solar_power_multiplier, 1, "unmodified native solar multiplier")
      local point = assert(storage.platform.hub.get_logistic_point(defines.logistic_member_index.space_platform_hub_requester))
      point.trash_not_requested = true
      for _, entity in pairs(storage.platform.surface.find_entities_filtered{name = "inserter"}) do entity.disabled_by_script = false end
      storage.operation_tick, storage.stage = game.tick, "return"
      report("uplift_delivery_passed", snapshot())
    end
  elseif storage.stage == "return" and storage.produced == 10000 and storage.returned == storage.produced and not next(storage.pods) then
    equal(inv(storage.pad, defines.inventory.cargo_landing_pad_main).get_item_count(TOKEN), 10000, "physical native Token return")
    equal(storage.core.products_finished, 1, "one real native orbital completion with one radiator")
    local state = remote.call("bitermotors", "endgame_status", "player")
    equal(state.cumulative_ai_tokens, 10000, "uplifted Dollar earned actual compute")
    local dollars = remaining_dollars()
    equal(dollars, 99, "100 uplifted Dollars minus one native batch")
    storage.saved_tick, storage.stage = game.tick, "reload"
    loaded = false
    game.speed = 1
    local row = snapshot(); row.operation_tick = storage.operation_tick
    row.earned_equivalents, row.core_completions = state.cumulative_ai_tokens, storage.core.products_finished
    row.dollars_remaining = dollars
    report("uplift_return_passed", row)
    game.server_save("bitermotors-uplift-reload")
  end
end)
