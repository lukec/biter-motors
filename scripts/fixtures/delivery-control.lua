local REPORT = "bitermotors-delivery.jsonl"
local DATASET = "bitermotors-agi-training-dataset"
local TOKEN = "bitermotors-ai-token"
local CORE = "bitermotors-orbital-datacenter-core"
local COMPUTE = "bitermotors-orbital-ai-dataset-hyperscale"
local CONTROLLER = "bitermotors-planetary-grid-controller"
local TRAINING = "bitermotors-agi-training-run"
local RESEARCH = "bitermotors-planetary-energy-grid"
local assertions, loaded = 0, false

local function check(condition, label)
  assert(condition, label)
  assertions = assertions + 1
end

local function equal(actual, expected, label)
  check(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function report(status, fields)
  local row = fields or {}
  row.status, row.tick, row.assertions = status, game.tick, assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function state() return remote.call("bitermotors", "endgame_status", "player") end
local function input(entity) return entity.get_inventory(defines.inventory.crafter_input) end
local function output(entity) return entity.get_inventory(defines.inventory.crafter_output) end
local function make(surface, name, position, quality)
  return assert(surface.create_entity{name = name, position = position,
    force = game.forces.player, quality = quality or "normal", raise_built = true}, "create " .. name)
end

local function supply(surface, position)
  local source = make(surface, "electric-energy-interface", position)
  source.electric_interface_mode = defines.electric_interface_mode.primary_output
  source.power_production, source.output_flow_limit = 1000000000000, 1000000000000
end

local function request(entity, name, count)
  local sections = assert(entity.get_logistic_sections(), "native logistic sections")
  local section = assert(sections.add_section(), "native ungrouped request section")
  section.set_slot(1, {value = {type = "item", name = name, quality = "normal", comparator = "="}, min = count})
  equal(section.get_slot(1).min, count, "native request count")
end

local function inserter(surface, position, direction, filter)
  local entity = make(surface, "bulk-inserter", position)
  entity.direction = direction
  if filter then entity.use_filters = true; entity.set_filter(1, filter) end
  return entity
end

local function build_platform(name, extra_token_core)
  local platform = game.forces.player.create_space_platform{name = name, planet = "nauvis",
    starter_pack = "space-platform-starter-pack"}
  check(platform.apply_starter_pack(true) ~= nil, "native platform hub")
  local surface, tiles = platform.surface, {}
  for x = -88, 88 do
    for y = -48, 72 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end
  end
  surface.set_tiles(tiles, false, false, false, true)
  supply(surface, {-80, -40})
  local hub_point = assert(platform.hub.get_logistic_point(defines.logistic_member_index.space_platform_hub_requester))
  hub_point.trash_not_requested = true
  platform.hub.request_missing_construction_materials = false
  for i = 1, (extra_token_core and 17 or 16) * 8 do
    make(surface, "bitermotors-orbital-radiator-panel",
      {-60 + ((i - 1) % 16) * 8, 12 + math.floor((i - 1) / 16) * 6})
  end
  for x = -72, 56 do
    local belt = make(surface, "express-transport-belt", {x, -6})
    belt.direction = x < -2 and defines.direction.east or defines.direction.west
  end
  local row = {platform = platform, cores = {}, unloading = {}, datasets = 0, tokens = 0,
    pods = 0, delivered = 0}
  storage.platforms[#storage.platforms + 1] = row
  storage.by_surface[surface.index] = row
  for i = 1, extra_token_core and 17 or 16 do
    local x = i == 17 and -72 or -64 + (i - 1) * 8
    local machine = make(surface, CORE, {x, i == 17 and 0 or -16}, "legendary")
    local recipe = i == 17 and "bitermotors-orbital-ai-token" or COMPUTE
    game.forces.player.recipes[recipe].enabled = true
    machine.set_recipe(recipe)
    equal(input(machine).insert{name = "bitermotors-dollar", count = i == 17 and 1 or 313},
      i == 17 and 1 or 313, "provided compute capital")
    row.cores[#row.cores + 1] = machine
    storage.by_core[machine.unit_number] = row
    local loader = i == 17 and inserter(surface, {x + 3, 0}, defines.direction.west)
      or inserter(surface, {x, -13}, defines.direction.north)
    loader.disabled_by_script = true
    row.unloading[#row.unloading + 1] = loader
    if i == 17 then
      -- Keep research Tokens off the Dataset bus so a fulfilled request cannot block final cargo.
      for belt_x = -68, -6 do
        local belt = make(surface, "express-transport-belt", {belt_x, 0})
        belt.direction = belt_x == -6 and defines.direction.south or defines.direction.east
      end
      local belt = make(surface, "express-transport-belt", {-6, 1})
      belt.direction = defines.direction.south
      inserter(surface, {-5, 1}, defines.direction.west, TOKEN)
    else
      for y = -12, -7 do
        local belt = make(surface, "express-transport-belt", {x, y})
        belt.direction = defines.direction.south
      end
    end
  end
  row.hub_loaders = {inserter(surface, {-3, -5}, defines.direction.north),
    inserter(surface, {-2, -5}, defines.direction.north)}
end

local function land_setup(surface)
  surface.request_to_generate_chunks({0, 0}, 5)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-32, -24}, {112, 96}}}) do entity.destroy() end
  local tiles = {}
  for x = -32, 112 do
    for y = -24, 96 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
  end
  surface.set_tiles(tiles)
  storage.pad = make(surface, "cargo-landing-pad", {0, 0})
  request(storage.pad, DATASET, 20000)
  request(storage.pad, TOKEN, 2880)
  inserter(surface, {0, 4}, defines.direction.north, DATASET)
  for y = 5, 9 do
    local belt = make(surface, "express-transport-belt", {0, y})
    belt.direction = defines.direction.south
  end
  storage.final_loaders = {inserter(surface, {0, 10}, defines.direction.north, DATASET)}
  storage.capital = make(surface, "assembling-machine-3", {-6, 12})
  local chest = make(surface, "steel-chest", {-3, 12})
  storage.capital_chest = chest
  inserter(surface, {-4, 12}, defines.direction.west)
  storage.final_loaders[#storage.final_loaders + 1] =
    inserter(surface, {-2, 12}, defines.direction.west, "bitermotors-capital-allocation")
  chest = make(surface, "steel-chest", {3, 12})
  equal(chest.insert{name = "bitermotors-grid-battery-array", count = 100}, 100, "provided final batteries")
  storage.final_loaders[#storage.final_loaders + 1] =
    inserter(surface, {2, 12}, defines.direction.east, "bitermotors-grid-battery-array")
  for x = 0, 16 do
    local belt = make(surface, "express-transport-belt", {x, 16})
    belt.direction = x == 0 and defines.direction.north or defines.direction.west
  end
  local belt = make(surface, "express-transport-belt", {0, 15})
  belt.direction = defines.direction.north
  storage.final_loaders[#storage.final_loaders + 1] =
    inserter(surface, {0, 14}, defines.direction.south, "processing-unit")
  for _, loader in ipairs(storage.final_loaders) do loader.disabled_by_script = true end
  for _, x in ipairs({3, 7, 11, 15}) do
    chest = make(surface, "steel-chest", {x, 18})
    equal(chest.insert{name = "processing-unit", count = 2500}, 2500, "provided final processing units")
    inserter(surface, {x, 17}, defines.direction.south)
  end
  storage.builder = make(surface, "assembling-machine-3", {32, 0})
  storage.labs = {}
  for i = 1, 96 do
    local x, y = 10 + ((i - 1) % 12) * 5, 24 + math.floor((i - 1) / 12) * 6
    local lab = make(surface, "lab", {x, y}, "legendary")
    for _, ingredient in pairs(prototypes.technology[RESEARCH].research_unit_ingredients) do
      if ingredient.name ~= TOKEN then
        equal(lab.insert{name = ingredient.name, count = 30}, 30, "provided research science")
      end
    end
    chest = make(surface, "requester-chest", {x, y + 3})
    request(chest, TOKEN, 30)
    inserter(surface, {x, y + 2}, defines.direction.south, TOKEN)
    storage.labs[#storage.labs + 1] = lab
  end
  for _, position in ipairs({{0, 24}, {48, 20}, {0, 64}, {48, 76}}) do
    local port = make(surface, "roboport", position)
    equal(port.get_inventory(defines.inventory.roboport_robot).insert{name = "logistic-robot", count = 100},
      100, "provided logistic robots")
  end
  for x = -16, 96, 16 do
    for y = -8, 88, 16 do
      local position = assert(surface.find_non_colliding_position("substation", {x, y}, 4, 1), "pole tile")
      if math.abs(position.x - 0.5) < 3 and math.abs(position.y - 12.5) < 3 then
        position = assert(surface.find_non_colliding_position("substation", {x - 8, y}, 4, 1), "reserved controller tile")
      end
      make(surface, "substation", position, "legendary")
    end
  end
  supply(surface, {104, -16})
  local free = surface.can_place_entity{name = CONTROLLER, position = {0.5, 12.5}, force = game.forces.player}
  if not free then
    local rows = {}
    for _, entity in pairs(surface.find_entities_filtered{area = {{-1, 11}, {2, 14}}}) do
      rows[#rows + 1] = {name = entity.name, position = entity.position}
    end
    error("controller footprint blocked: " .. helpers.table_to_json(rows))
  end
end

script.on_init(function()
  game.tick_paused, game.speed = false, 100
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
  storage.started, storage.stage = game.tick, "compute"
  storage.platforms, storage.by_surface, storage.by_core = {}, {}, {}
  storage.launched, storage.delivered, storage.datasets, storage.tokens = 0, 0, 0, 0
  local force = game.forces.player
  for _, name in ipairs({"bitermotors-orbital-compute", "bitermotors-orbital-cluster-training",
    "bitermotors-grid-scale-energy", "bitermotors-hyperscale-training",
    "bitermotors-autonomous-logistics", "nuclear-power", "logistic-system", "logistic-robotics"}) do
    force.technologies[name].researched = true
  end
  for level = 1, 7 do force.technologies["inserter-capacity-bonus-" .. level].researched = true end
  force.technologies[RESEARCH].researched = false
  build_platform("Physical Dataset delivery A", true)
  build_platform("Physical Dataset delivery B", false)
  land_setup(game.surfaces.nauvis)
  equal(force.add_research(RESEARCH), true, "enqueue actual final technology")
  equal(state().agi.completed, false, "fixture cannot start won")
  report("delivery_setup_passed")
end)

script.on_load(function() loaded = true end)

for _, recipe in ipairs({COMPUTE, "bitermotors-orbital-ai-token"}) do
  script.on_event(prototypes.recipe[recipe].on_crafted_event, function(event)
    local row = storage.by_core[event.entity.unit_number]
    if not row then return end
    local amount = recipe == COMPUTE and 2 or 10000
    row[recipe == COMPUTE and "datasets" or "tokens"] = row[recipe == COMPUTE and "datasets" or "tokens"] + amount
    storage[recipe == COMPUTE and "datasets" or "tokens"] = storage[recipe == COMPUTE and "datasets" or "tokens"] + amount
  end)
end

script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
  local pod = event.cargo_pod
  local origin = pod.cargo_pod_origin
  local row = origin and origin.valid and storage.by_surface[origin.surface.index]
  if not row then return end
  equal(origin, row.platform.hub, "native pod originates at platform hub")
  local cargo = pod.get_inventory(defines.inventory.cargo_unit)
  row.pods, storage.launched = row.pods + 1, storage.launched + 1
  local datasets, tokens = cargo.get_item_count(DATASET), cargo.get_item_count(TOKEN)
  row.launched_datasets = (row.launched_datasets or 0) + datasets
  storage.pods = storage.pods or {}
  storage.pods[pod.unit_number] = {row = row, datasets = datasets, tokens = tokens}
end)

script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
  local pod = event.cargo_pod
  local shipment = storage.pods and storage.pods[pod.unit_number]
  if not shipment then return end
  equal(pod.surface, storage.pad.surface, "native pod landed on Nauvis")
  equal(event.spawned_container, nil, "cargo did not spill into a ground container")
  local box, position = storage.pad.bounding_box, pod.position
  check(position.x >= box.left_top.x and position.x <= box.right_bottom.x
    and position.y >= box.left_top.y and position.y <= box.right_bottom.y,
    "native cargo delivered inside the landing pad")
  shipment.row.delivered = shipment.row.delivered + shipment.datasets
  storage.delivered = storage.delivered + shipment.datasets
  storage.pods[pod.unit_number] = nil
end)

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name == RESEARCH then
    equal(event.by_script, false, "final technology completes in real labs")
    storage.researched_tick = game.tick
  end
end)

script.on_event(prototypes.recipe[TRAINING].on_crafted_event, function(event)
  if not storage.controller or event.entity ~= storage.controller then return end
  equal(state().agi.completed, true, "delivered native run latches victory")
  equal(event.bonus, false, "one real Model completion")
  equal(output(storage.controller).get_item_count("bitermotors-agi-model"), 1, "physical delivered-payload Model")
  local duration = game.tick - storage.training_tick + 1
  check(duration >= 71999 and duration <= 72001, "full delivered-payload training duration")
  equal(state().cumulative_ai_tokens, 1001610000, "research and transport cannot earn compute again")
  storage.stage, storage.victory, storage.saved_tick = "reload", state().agi.victory, game.tick
  report("delivery_training_passed", {datasets = storage.datasets, delivered = storage.delivered,
    launched_pods = storage.launched, earned_equivalents = state().cumulative_ai_tokens,
    researched_tick = storage.researched_tick, training_ticks = duration, victory = storage.victory})
  game.set_game_state{game_finished = false, player_won = true, can_continue = true}
  game.speed = 1
  game.server_save("bitermotors-delivery-reload")
end)

script.on_nth_tick(1, function()
  if game.tick <= storage.started then return end
  if loaded then
    loaded = false
    if storage.stage == "reload" then
      equal(state().agi.completed, true, "delivered victory survives reload")
      equal(state().agi.victory.tick, storage.victory.tick, "victory does not replay")
      equal(state().cumulative_ai_tokens, 1001610000, "delivered compute ledger survives reload")
      equal(storage.controller.products_finished, 1, "reload does not recraft Model")
      report("delivery_reload_passed", {saved_tick = storage.saved_tick, victory = state().agi.victory})
      storage.stage = "done"
    end
  end
  if game.tick % 18000 == 0 and storage.stage ~= "done" then
    local platforms = {}
    for _, row in ipairs(storage.platforms) do
      local remaining = 0
      for _, core in ipairs(row.cores) do remaining = remaining + output(core).get_item_count(DATASET) end
      platforms[#platforms + 1] = {name = row.platform.name, delivered = row.delivered, remaining = remaining,
        hub = row.platform.hub.get_inventory(defines.inventory.hub_main).get_contents()}
    end
    log("Delivery fixture: " .. storage.stage .. ", datasets=" .. storage.datasets
      .. ", delivered=" .. storage.delivered .. ", pods=" .. storage.launched
      .. ", research=" .. game.forces.player.research_progress
      .. ", platforms=" .. helpers.table_to_json(platforms))
    if storage.controller then
      local loaders = {}
      for _, loader in pairs(storage.controller.surface.find_entities_filtered{
        type = "inserter", area = {{-8, 3}, {8, 16}}}) do
        local target, held = loader.drop_target, loader.held_stack
        loaders[#loaders + 1] = {position = loader.position, status = loader.status,
          energy = loader.energy, held = held.valid_for_read and held.count or 0,
          target = target and target.valid and target.name or nil}
      end
      log("Delivery loading: " .. helpers.table_to_json{
        input = input(storage.controller).get_contents(), slots = #input(storage.controller),
        full = input(storage.controller).is_full(), energy = storage.controller.energy,
        progress = storage.controller.crafting_progress, disabled = storage.controller.disabled_by_script,
        capital = storage.capital.products_finished, loaders = loaders})
    end
  end
  if storage.stage == "compute" and storage.datasets == 20032 and storage.tokens == 10000 then
    equal(state().cumulative_ai_tokens, 1001610000, "actual native billion-equivalent computation")
    for _, row in ipairs(storage.platforms) do
      equal(row.datasets, 10016, "both platforms computed half the payload")
      for _, loader in ipairs(row.unloading) do loader.disabled_by_script = false end
    end
    storage.stage = "delivery"
    report("delivery_compute_passed", {datasets = storage.datasets, tokens = storage.tokens,
      earned_equivalents = state().cumulative_ai_tokens})
  elseif storage.stage == "delivery" and storage.researched_tick and not storage.builder_started then
    local force = game.forces.player
    equal(force.recipes[CONTROLLER].enabled, true, "native research unlocks final construction")
    equal(force.recipes["bitermotors-package-capital-allocation"].enabled, true, "native research unlocks capital packaging")
    storage.builder.set_recipe(CONTROLLER)
    for _, ingredient in pairs(prototypes.recipe[CONTROLLER].ingredients) do
      equal(input(storage.builder).insert{name = ingredient.name, count = ingredient.amount},
        ingredient.amount, "provided controller construction materials")
    end
    storage.capital.set_recipe("bitermotors-package-capital-allocation")
    equal(input(storage.capital).insert{name = "bitermotors-dollar", count = 50000}, 50000,
      "provided capital physically packaged")
    storage.builder_started = true
  elseif storage.builder_started and not storage.controller and output(storage.builder).get_item_count(CONTROLLER) == 1 then
    equal(output(storage.builder).remove{name = CONTROLLER, count = 1}, 1, "place actually constructed controller")
    check(game.surfaces.nauvis.can_place_entity{name = CONTROLLER, position = {0.5, 12.5}, force = game.forces.player},
      "constructed controller has an unobstructed footprint")
    storage.controller = make(game.surfaces.nauvis, CONTROLLER, {0, 12})
    storage.controller.set_recipe(TRAINING)
    for _, loader in ipairs(storage.final_loaders) do loader.disabled_by_script = false end
  elseif storage.controller and storage.controller.crafting_progress > 0 and not storage.training_tick then
    storage.training_tick = game.tick
    check(storage.delivered >= 20000, "complete final payload arrived by native pods")
    check(storage.platforms[1].delivered > 0 and storage.platforms[2].delivered > 0, "both real platforms delivered")
    check(input(storage.controller).get_item_count(DATASET) <= 32, "native inserters commit entire Dataset payload")
    equal(storage.capital.products_finished, 100, "100 native Capital Allocations")
    equal(storage.builder.products_finished, 1, "one native final controller")
    equal(state().agi.completed, false, "delivered inputs alone cannot win")
    storage.stage = "training"
    report("delivery_payload_passed", {delivered = storage.delivered, launched_pods = storage.launched,
      researched_tick = storage.researched_tick, training_tick = storage.training_tick})
  end
  assert(game.tick - storage.started < 480000, "bounded complete native delivery/training fixture")
end)
