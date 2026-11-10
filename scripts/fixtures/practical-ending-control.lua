-- Independent finite-ground-stock rehearsal. Never mutates mod-owned authority.
local C = require("practical-config")
local Layout = require("orbital-layout")
local P = "bitermotors-"
local CORE, DC = P .. "orbital-datacenter-core", P .. "terrestrial-datacenter"
local DOLLAR, TOKEN, DATASET = P .. "dollar", P .. "ai-token", P .. "agi-training-dataset"
local RACK, MODEL = P .. "datacenter-rack", P .. "agi-model"
local ASSEMBLE, ACTIVATE = P .. "assemble-agi-model", P .. "activate-agi-model"
local REPORT = "bitermotors-practical-ending.jsonl"
local loaded = false
local function check(ok, why) assert(ok, why) end
local function enabled(entity, value)
  if value ~= nil then entity.disabled_by_script = not value end
  return not entity.disabled_by_script
end
local function select_recipe(entity, recipe)
  local removed = entity.set_recipe(recipe)
  for _, item in pairs(removed) do
    check(item.name == DOLLAR, "recipe selection must not discard physical payload")
    storage.recipe_change_discarded_dollars = storage.recipe_change_discarded_dollars + item.count
  end
end
local function inv(e, kind) return assert(e.get_inventory(kind), e.name .. " inventory") end
local function count(e, kind, name) return inv(e, kind).get_item_count(name) end
local function contents(i)
  local out = {}
  for _, s in pairs(i.get_contents()) do
    check(s.quality == "normal", "unexpected quality")
    out[s.name] = (out[s.name] or 0) + s.count
  end
  return out
end
local function add(to, from)
  for name, n in pairs(from) do to[name] = (to[name] or 0) + n end
end
local function state() return remote.call("bitermotors", "endgame_status", "player").agi end
local function thermal() return remote.call("bitermotors", "thermal_status", "player") end
local function active_count()
  local target = (#C.tiers == 3 and storage.nohyper_expanded) and C.cores or math.min(C.cores, C.ramp[storage.tier])
  local available = 0
  for _, n in ipairs(C.ramp) do if n <= storage.ready_cores and n <= target then available = n end end
  return math.min(target, available)
end
local function physical_datasets()
  if not storage.platform.hub then return 0 end
  local total = count(storage.platform.hub, defines.inventory.hub_main, DATASET)
  for _, e in ipairs(storage.cores) do
    total = total + count(e, defines.inventory.crafter_input, DATASET) + count(e, defines.inventory.crafter_output, DATASET)
  end
  for _, a in ipairs(storage.arms) do
    local stack = a.entity.held_stack
    if stack.valid_for_read and stack.name == DATASET then total = total + stack.count end
  end
  for _, e in pairs(storage.platform.surface.find_entities_filtered{type = "transport-belt"}) do
    for i = 1, 2 do total = total + e.get_transport_line(i).get_item_count(DATASET) end
  end
  return total
end
local function ground(name, x, y)
  return assert(game.surfaces.nauvis.create_entity{name = name, position = {x, y},
    force = "player", raise_built = true}, "ground " .. name)
end
local function initial_stock(i, name, n)
  check(storage.initializing, "all item insertion confined to initial ground setup")
  check(i.insert{name = name, count = n} == n, "initial stock capacity: " .. name)
end
local function filter(e, names)
  if #names > e.filter_slot_count then e.use_filters = false; return end
  e.use_filters = true
  for i = 1, e.filter_slot_count do e.set_filter(i, names[i]) end
end
local function request(e, name, n, from, minimum, maximum)
  local section = e.get_logistic_sections().add_section()
  section.set_slot(1, {value = {type = "item", name = name, quality = "normal", comparator = "="},
    min = n, max = maximum or n, import_from = from, minimum_delivery_count = minimum})
  local actual = section.get_slot(1)
  check(actual.min == n and actual.max == (maximum or n), "request readback " .. name)
  if minimum then check(actual.minimum_delivery_count == minimum, "minimum delivery readback " .. name) end
  return section
end
local function update_request(section, name, minimum, maximum, delivery)
  local old = section.get_slot(1)
  if old.min == minimum and old.max == maximum and old.minimum_delivery_count == delivery then return end
  section.set_slot(1, {value = {type = "item", name = name, quality = "normal", comparator = "="},
    min = minimum, max = maximum, import_from = "nauvis", minimum_delivery_count = delivery})
  local actual = section.get_slot(1)
  check(actual.min == minimum and actual.max == maximum and actual.minimum_delivery_count == delivery, "updated native request readback " .. name)
end
local function arm(x, y, direction, names)
  local e = ground("bulk-inserter", x, y)
  e.direction = direction
  filter(e, names)
  return e
end
local function feeder(x, y, direction, names)
  local chest = ground("requester-chest", x, y)
  for name, n in pairs(names) do request(chest, name, n) end
  arm(x + (direction == 12 and 1 or 0), y + (direction == 0 and 1 or 0), direction,
    (function() local a = {}; for name in pairs(names) do a[#a + 1] = name end; return a end)())
  return chest
end
local function snapshot()
  local s = state()
  local stats = game.forces.player.get_item_production_statistics(game.surfaces.nauvis)
  local row = {stage = storage.stage, earned = s.cumulative_ai_tokens, produced = storage.produced,
    datasets_returned = storage.datasets_returned, unpacked = storage.unpacked,
    compute_dollars = storage.compute_dollars, initial_stock = storage.stock,
    recipe_change_discarded_dollars = storage.recipe_change_discarded_dollars,
    shipped = storage.shipped, delivered = storage.delivered, shipments = storage.shipments,
    returns = storage.returns, rockets = storage.rockets, research = storage.research,
    native_assemblies = storage.native_assemblies, native_activations = storage.native_activations,
    models_assembled = s.models_assembled, models_returned = s.models_returned,
    models_activated = s.models_activated, victory = s.victory, completed = s.completed,
    timings = storage.timings, low_power_samples = storage.low_power_samples,
    full_output_samples = storage.full_output_samples, max_temperature = storage.max_temperature,
    burnouts = thermal().burnouts, cores = C.cores, active_cores = active_count(), source_sha256 = C.source_sha256,
    built = storage.built, manifest = storage.layout.manifest,
    ramp_history = storage.ramp_history, research_catalog = storage.research_catalog,
    orbital_datasets = physical_datasets(), item_catalog = storage.item_catalog,
    bulk_inserter_capacity_bonus = game.forces.player.bulk_inserter_capacity_bonus,
    starter_prototype_items = storage.starter_prototype_items, starter_prototype_tiles = storage.starter_prototype_tiles,
    starter_hub_items = storage.starter_hub_items, starter_surface_tiles = storage.starter_surface_tiles,
    payload_arms = {},
    research_dollars_consumed = stats.get_output_count(DOLLAR),
    rocket_parts = stats.get_input_count("rocket-part"), parts_per_rocket = storage.parts_per_rocket, rocket_consumed = {},
    config = C, scope = "native-practical-ending", phase_ticks = game.tick - storage.phase_tick,
    limits = "Finite finished ground hardware, science, Dollars, rocket ingredients and ground EEI supplied at init; baseline research through Orbital Compute. Native 1/4/8/12 staged uplift overlaps compute; larger groups wait for physical hardware. Lab count/speed cap approximates science throughput, not science manufacturing. Not business cash generation, a natural campaign, GUI or multiplayer qualification.",
    game_finished = game.finished, paused = game.tick_paused,
    ground_stock_remaining = {}, input_datasets = 0, input_racks = 0}
  for _, e in ipairs(storage.providers) do add(row.ground_stock_remaining, contents(inv(e, defines.inventory.chest))) end
  if storage.platform.hub then
    row.hub = contents(inv(storage.platform.hub, defines.inventory.hub_main))
    row.orbital_eei = #storage.platform.surface.find_entities_filtered{type = "electric-energy-interface"}
    row.solar_multiplier = storage.platform.surface.solar_power_multiplier
    row.compute_dollars_native = game.forces.player.get_item_production_statistics(storage.platform.surface).get_output_count(DOLLAR)
    row.ghosts = #storage.platform.surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}}
    row.foundation_surface_tiles = #storage.platform.surface.find_tiles_filtered{name = "space-platform-foundation"}
    local required = {}
    for _, tile in ipairs(storage.layout.tiles) do
      required[math.floor(tile.position.x) .. ":" .. math.floor(tile.position.y)] = true
    end
    row.foundation_required_tiles = 0
    for _ in pairs(required) do row.foundation_required_tiles = row.foundation_required_tiles + 1 end
    row.core_diagnostics = {}
    for _, core in ipairs(storage.cores) do
      check(core.valid, "core lost (burnout or destruction)")
      local recipe = core.get_recipe()
      row.core_diagnostics[#row.core_diagnostics + 1] = {unit = core.unit_number, recipe = recipe and recipe.name,
        progress = core.crafting_progress, status = core.status, active = core.active, energy = core.energy,
        input = contents(inv(core, defines.inventory.crafter_input)), output = contents(inv(core, defines.inventory.crafter_output))}
    end
  end
  row.silo = {status = storage.silo.status, progress = storage.silo.crafting_progress,
    input = contents(inv(storage.silo, defines.inventory.crafter_input)),
    requester = contents(inv(storage.rocket_requester, defines.inventory.chest))}
  if storage.cash_section then row.cash_request = storage.cash_section.get_slot(1) end
  for _, a in ipairs(storage.arms) do
    if a.role == "payload-hub" or a.role == "assembly-input" or a.role == "hub-input"
      or (a.role == "core-input" and a.entity.position.x == -4.5) then
      local stack = a.entity.held_stack
      row.payload_arms[#row.payload_arms + 1] = {role = a.role, override = a.entity.inserter_stack_size_override,
        target_pickup = a.entity.inserter_target_pickup_count,
        held = stack.valid_for_read and stack.count or 0, item = stack.valid_for_read and stack.name or nil, enabled = enabled(a.entity)}
    end
  end
  for _, ingredient in pairs(game.forces.player.recipes["rocket-part"].ingredients) do
    row.rocket_consumed[ingredient.name] = stats.get_output_count(ingredient.name)
  end
  row.research_progress = game.forces.player.research_progress
  row.current_research = game.forces.player.current_research and game.forces.player.current_research.name
  if storage.assembler then
    row.input_datasets = count(storage.assembler, defines.inventory.crafter_input, DATASET)
    row.input_racks = count(storage.assembler, defines.inventory.crafter_input, RACK)
    row.assembly_progress = storage.assembler.crafting_progress
    row.assembler_unit = storage.assembler.unit_number
  end
  row.terminal_unit = storage.terminal.unit_number
  row.activation_progress = storage.terminal.crafting_progress
  row.activation_output = count(storage.terminal, defines.inventory.crafter_output, MODEL)
  return row
end
local function export_layout()
  local tools = game.create_inventory(2)
  tools[1].set_stack{name = "blueprint"}
  local left, top, right, bottom = -5, -5, 5, 5
  for _, tile in ipairs(storage.layout.tiles) do
    left, top = math.min(left, tile.position.x - 1), math.min(top, tile.position.y - 1)
    right, bottom = math.max(right, tile.position.x + 2), math.max(bottom, tile.position.y + 2)
  end
  tools[1].create_blueprint{surface = storage.platform.surface, force = "player",
    area = {{left, top}, {right, bottom}}, include_entities = true, always_include_tiles = true}
  tools[1].label = "Biter Motors practical physical ending"
  local encoded = tools[1].export_stack()
  check(tools[2].import_stack(encoded) == 0, "native ending blueprint round trip")
  check(#tools[2].get_blueprint_entities() == #storage.layout.entities + 1, "blueprint retains hub and complete ending I/O")
  helpers.write_file("practical-ending-layout.txt", encoded, false)
  helpers.write_file("practical-ending-layout.json", helpers.table_to_json(storage.layout), false)
  tools.destroy()
end
local function report(status, extra)
  local row = snapshot()
  for k, v in pairs(extra or {}) do row[k] = v end
  row.status, row.tick = status, game.tick
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end
local function phase(name)
  storage.timings[storage.stage] = (storage.timings[storage.stage] or 0) + game.tick - storage.phase_tick
  storage.stage, storage.phase_tick = name, game.tick
end
local function baseline(technology, seen)
  if seen[technology.name] then return end
  seen[technology.name] = true
  for _, parent in pairs(technology.prerequisites) do baseline(parent, seen) end
  technology.researched = true
end
local function add_payload_io(layout)
  local floor = {}
  for _, t in ipairs(layout.tiles) do floor[t.position.x .. ":" .. t.position.y] = true end
  local function tile(x, y)
    if x >= -5 and x <= 4 and y >= -5 and y <= 4 then return end
    local key = x .. ":" .. y
    if not floor[key] then
      floor[key] = true
      layout.tiles[#layout.tiles + 1] = {name = "space-platform-foundation", position = {x = x, y = y}}
    end
  end
  local function entity(name, x, y, direction, role)
    layout.entities[#layout.entities + 1] = {name = name, position = {x = x, y = y}, direction = direction, role = role}
    layout.manifest[name] = (layout.manifest[name] or 0) + 1
    tile(math.floor(x), math.floor(y))
  end
  local last = -3.5 + (C.cores - 1) * 9
  -- Separate payload arms cannot be stranded holding an operating Dollar.
  entity("bulk-inserter", -2.5, 4.5, 0, "payload-hub")
  entity("express-transport-belt", -2.5, 5.5, 12, "payload-feed")
  entity("bulk-inserter", -2.5, 8.5, 0, "assembly-input")
  entity("express-transport-belt", last, 7.5, 4, "input")
  entity("express-transport-belt", last + 1, 7.5, 4, "input")
  entity("bulk-inserter", last + 2, 7.5, 12, "cash-drain")
  for x = last + 3, last + 7, 1 do entity("express-transport-belt", x, 7.5, 4, "cash-return") end
  for y = 7.5, 12.5, 1 do entity("express-transport-belt", last + 8, y, 8, "cash-return") end
  for x = last + 8, last + 2, -1 do entity("express-transport-belt", x, 13.5, 12, "cash-return") end
  -- Fill the newly enclosed region; native foundation cannot enclose holes.
  for x = math.floor(last + 1), math.floor(last + 8) do for y = 7, 13 do tile(x, y) end end
  tile(math.floor(last), 8) -- The turn otherwise encloses this north-core corner.
  layout.manifest["space-platform-foundation"] = #layout.tiles
end
local function stock_bank()
  local index = 0
  for name, amount in pairs(storage.stock) do
    while amount > 0 do
      index = index + 1
      local e = ground("passive-provider-chest", -16.5 + (index - 1) % 12 * 2, 30.5 + math.floor((index - 1) / 12) * 2)
      local n = math.min(amount, #inv(e, defines.inventory.chest) * prototypes.item[name].stack_size)
      initial_stock(inv(e, defines.inventory.chest), name, n)
      storage.providers[#storage.providers + 1] = e
      amount = amount - n
    end
  end
end
script.on_init(function()
  storage.initializing = true
  game.tick_paused, game.speed = false, C.speed
  game.map_settings.pollution.enabled, game.map_settings.enemy_expansion.enabled = false, false
  local f, land = game.forces.player, game.surfaces.nauvis
  land.request_to_generate_chunks({0, 0}, 5); land.force_generate_chunk_requests()
  for _, e in pairs(land.find_entities_filtered{area = {{-80, -50}, {100, 100}}}) do e.destroy() end
  local tiles = {}
  for x = -80, 100 do for y = -50, 100 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  land.set_tiles(tiles)
  local seen = {}
  for _, name in ipairs({P .. "orbital-compute", "logistic-system", "bulk-inserter", "logistics-3"}) do
    baseline(assert(f.technologies[name], name), seen)
  end
  f.laboratory_speed_modifier, f.laboratory_productivity_bonus = C.lab_speed_modifier, 0
  f.bulk_inserter_capacity_bonus = C.bulk_inserter_capacity_bonus
  storage.layout = Layout.make(C.cores, C.tiers[1].recipe)
  -- One saturated normal lane takes ~44 minutes to move the payload. Use native
  -- express belts from the outset; do not silently omit that transport cost.
  for _, e in ipairs(storage.layout.entities) do
    if e.role == "input" and e.name ~= "express-transport-belt" then
      storage.layout.manifest[e.name] = storage.layout.manifest[e.name] - 1
      e.name = "express-transport-belt"
      storage.layout.manifest[e.name] = (storage.layout.manifest[e.name] or 0) + 1
    end
  end
  add_payload_io(storage.layout)
  storage.stage, storage.start_tick, storage.phase_tick = "starter", game.tick, game.tick
  storage.providers, storage.cores, storage.arms, storage.roles, storage.input_belts = {}, {}, {}, {}, {}
  storage.shipped, storage.delivered, storage.shipments, storage.pods, storage.returns, storage.research = {}, {}, {}, {}, {}, {}
  storage.timings, storage.built, storage.stock = {}, {}, {}
  storage.ramp_history, storage.research_catalog, storage.item_catalog = {}, {}, {}
  storage.planned_entities, storage.planned_tiles, storage.sections, storage.stage_manifest = {}, {}, {}, {}
  storage.built_tile_positions = {}
  storage.built_tiles, storage.construction_target = 0, 0
  storage.ready_cores = 0
  storage.produced, storage.datasets_returned, storage.unpacked, storage.compute_dollars = 0, 0, 0, 0
  storage.recipe_change_discarded_dollars = 0
  local starter = prototypes.item["space-platform-starter-pack"]
  storage.starter_prototype_items = {}
  for _, item in pairs(starter.initial_items) do
    check(item.amount and not item.amount_min and not item.amount_max, "deterministic native starter stock")
    storage.starter_prototype_items[item.name] = (storage.starter_prototype_items[item.name] or 0) + item.amount
  end
  storage.starter_prototype_tiles = #starter.tiles
  storage.rockets, storage.native_assemblies, storage.native_activations = 0, 0, 0
  storage.low_power_samples, storage.full_output_samples, storage.max_temperature = 0, 0, 15
  storage.tier = 1
  local power = ground("electric-energy-interface", -60, -20)
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production, power.output_flow_limit = 10000000000, 10000000000
  for x = -60, 84, 18 do for y = -20, 88, 18 do ground("substation", x, y) end end
  for _, p in ipairs({{0, -16}, {-24, 24}, {24, 24}, {-24, 64}, {24, 64}}) do
    local port = ground("roboport", p[1], p[2])
    initial_stock(inv(port, defines.inventory.roboport_robot), "logistic-robot", C.robots)
  end
  storage.silo = ground("rocket-silo", 0.5, 0.5)
  storage.silo.use_transitional_requests = true
  storage.silo.set_recipe("rocket-part")
  storage.pad = ground("cargo-landing-pad", -20, 0)
  storage.terminal = ground(DC, -20.5, 16.5) -- Exists before compute or returned Model.
  -- Separate physical pad exits: Dataset -> unpacker -> provider; Model -> DC.
  local bottom = storage.pad.position.y + storage.pad.prototype.tile_height / 2
  arm(-20.5, bottom + 0.5, 0, {MODEL})
  local top = storage.terminal.position.y - storage.terminal.prototype.tile_height / 2
  for y = bottom + 1.5, top - 1.5, 1 do ground("express-transport-belt", -20.5, y).direction = 8 end
  arm(-20.5, top - 0.5, 0, {MODEL})
  local right = storage.pad.position.x + storage.pad.prototype.tile_width / 2
  arm(right + 0.5, 0.5, 12, {DATASET})
  storage.unpacker = ground("assembling-machine-3", -8.5, 0.5)
  storage.unpacker.set_recipe(P .. "unpack-agi-training-dataset")
  local left = storage.unpacker.position.x - storage.unpacker.prototype.tile_width / 2
  for x = right + 1.5, left - 1.5, 1 do ground("express-transport-belt", x, 0.5).direction = 4 end
  arm(left - 0.5, 0.5, 12, {DATASET})
  arm(-8.5, 2.5, 0, {TOKEN})
  storage.token_provider = ground("passive-provider-chest", -8.5, 3.5)
  storage.providers[#storage.providers + 1] = storage.token_provider
  storage.dataset_request = request(storage.pad, DATASET, 1)
  request(storage.pad, MODEL, 1)
  storage.stock["space-platform-starter-pack"], storage.stock[RACK] = 1, 1
  add(storage.stock, storage.layout.manifest)
  -- Capture runtime costs/yields; operating cash remains a finite configured cap.
  storage.catalog = {}
  for _, tier in ipairs(C.tiers) do
    local r = assert(f.recipes[tier.recipe], tier.recipe)
    check(#r.products == 1 and r.products[1].name == DATASET, "Dataset compute tier")
    check(#r.ingredients == 1 and r.ingredients[1].name == DOLLAR, "Dollar-only compute tier")
    storage.catalog[#storage.catalog + 1] = {recipe = r.name, output = r.products[1].amount,
      dollars = r.ingredients[1].amount, seconds = r.energy}
  end
  storage.operating_budget = C.operating_dollars or (#C.tiers == 4 and 8000 or 12000)
  storage.stock[DOLLAR] = storage.operating_budget
  local sciences, research_cash = {}, 0
  for _, tier in ipairs(C.tiers) do
    if tier.technology then
      local tech = assert(f.technologies[tier.technology])
      check(not tech.researched, "scale research not supplied")
      local ingredients = {}
      for _, ingredient in pairs(tech.research_unit_ingredients) do
        local amount = ingredient.amount * tech.research_unit_count
        ingredients[ingredient.name] = ingredient.amount
        if ingredient.name ~= TOKEN then sciences[ingredient.name] = (sciences[ingredient.name] or 0) + amount end
        if ingredient.name == DOLLAR then research_cash = research_cash + amount end
      end
      storage.research_catalog[tier.technology] = {cycles = tech.research_unit_count,
        seconds = tech.research_unit_energy / 60, ingredients = ingredients}
    end
  end
  for name in pairs(sciences) do sciences[name] = sciences[name] + C.labs * C.lab_supply_reserve end
  add(storage.stock, sciences)
  storage.research_cash = research_cash
  local rocket = f.recipes["rocket-part"]
  storage.parts_per_rocket = assert(prototypes.entity["rocket-silo"].rocket_parts_required)
  local rocket_feed = {}
  for _, ingredient in pairs(rocket.ingredients) do
    check(ingredient.type == "item", "item-only rocket baseline")
    storage.stock[ingredient.name] = (storage.stock[ingredient.name] or 0) + ingredient.amount * C.rocket_budget * storage.parts_per_rocket
    rocket_feed[ingredient.name] = ingredient.amount * storage.parts_per_rocket * 2
  end
  storage.rocket_requester = feeder(0.5, -5.5, 0, rocket_feed)
  for i = 1, C.labs do
    local x, y = -44.5 + ((i - 1) % 12) * 6, 44.5 + math.floor((i - 1) / 12) * 6
    ground("lab", x, y)
    local wants = {[TOKEN] = 20}
    for name in pairs(sciences) do wants[name] = 20 end
    feeder(x - 3, y, 12, wants)
  end
  stock_bank()
  for name in pairs(storage.stock) do
    storage.item_catalog[name] = {weight = prototypes.item[name].weight, stack_size = prototypes.item[name].stack_size}
  end
  for _, name in ipairs({DATASET, MODEL}) do
    storage.item_catalog[name] = {weight = prototypes.item[name].weight, stack_size = prototypes.item[name].stack_size}
  end
  storage.platform = assert(f.create_space_platform{name = "Practical ending", planet = "nauvis",
    starter_pack = "space-platform-starter-pack"})
  check(not storage.platform.hub, "starter must fly in a real rocket")
  storage.platform.paused = true
  storage.initializing = false
  check(state().cumulative_ai_tokens == 0, "no injected compute")
  report("setup", {catalog = storage.catalog, operating_budget = storage.operating_budget,
    research_cash = storage.research_cash, baseline_research = seen})
end)
script.on_load(function() loaded = storage.stage == "checkpoint" end)
script.on_event(defines.events.on_space_platform_built_entity, function(event)
  if event.platform ~= storage.platform then return end
  local e = event.entity
  local role = assert(storage.roles[e.position.x .. ":" .. e.position.y], "unexpected orbital construction")
  storage.built[e.name] = (storage.built[e.name] or 0) + 1
  if role == "core" then
    e.set_recipe(C.tiers[storage.tier].recipe); enabled(e, false)
    storage.cores[#storage.cores + 1] = e
    table.sort(storage.cores, function(a, b) return a.position.x < b.position.x end)
  elseif e.type == "inserter" then
    enabled(e, false)
    storage.arms[#storage.arms + 1] = {entity = e, role = role}
    if role == "hub-input" or role == "core-input" or role == "cash-drain" or role == "cash-hub" then filter(e, {DOLLAR})
    elseif role == "payload-hub" or role == "assembly-input" then filter(e, {DATASET, RACK})
    else filter(e, {DATASET, MODEL}) end
    if role == "hub-input" or role == "core-input" then e.inserter_stack_size_override = 1
    elseif role == "payload-hub" or role == "assembly-input" then e.inserter_stack_size_override = 12 end
  elseif role == "input" then
    storage.input_belts[#storage.input_belts + 1] = e
  end
end)
script.on_event(defines.events.on_space_platform_built_tile, function(event)
  if event.platform ~= storage.platform then return end
  for _, tile in pairs(event.tiles) do
    local pos = tile.position or tile
    local key = math.floor(pos.x) .. ":" .. math.floor(pos.y)
    if storage.planned_tiles[key] and not storage.built_tile_positions[key] then
      storage.built_tiles = storage.built_tiles + 1
      storage.built_tile_positions[key] = true
    end
  end
end)
script.on_event(defines.events.on_rocket_launched, function(event)
  if event.rocket_silo == storage.silo then storage.rockets = storage.rockets + 1 end
end)
local function ascending(event, outbound)
  local pod = event.cargo_pod
  if outbound and pod.cargo_pod_origin ~= storage.silo then return end
  if not outbound and (not storage.platform.hub or pod.cargo_pod_origin ~= storage.platform.hub) then return end
  local cargo = contents(inv(pod, defines.inventory.cargo_unit))
  local row = {tick = game.tick, cargo = cargo, origin = outbound and "ground-rocket" or "orbital-hub",
    pod = pod.unit_number, mass = 0, slots = 0, capacity = #inv(pod, defines.inventory.cargo_unit)}
  for name, n in pairs(cargo) do
    row.mass = row.mass + prototypes.item[name].weight * n
    row.slots = row.slots + math.ceil(n / prototypes.item[name].stack_size)
    if not outbound then check(name == DATASET or name == MODEL, "unexpected return cargo: " .. helpers.table_to_json(cargo)) end
  end
  check(row.slots <= row.capacity, "native cargo slots")
  if outbound then
    check(event.launched_by_rocket and row.mass <= 1000000, "native rocket cargo")
    add(storage.shipped, cargo); storage.shipments[#storage.shipments + 1] = row
  else
    storage.returns[#storage.returns + 1] = row
    if cargo[DATASET] then storage.dataset_request.active = false end
  end
  storage.pods[pod.unit_number] = row
end
script.on_event(defines.events.on_cargo_pod_finished_ascending, function(event) ascending(event, true) end)
script.on_event(defines.events.on_cargo_pod_started_ascending, function(event) ascending(event, false) end)
script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
  local row = storage.pods[event.cargo_pod.unit_number]
  if row then
    local destination = event.cargo_pod.cargo_pod_destination
    check(destination.station == (row.origin == "ground-rocket" and storage.platform.hub or storage.pad), "native cargo destination")
    row.destination = row.origin == "ground-rocket" and "orbital-hub" or "ground-pad"
    row.descended_tick = game.tick
  end
end)
script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
  local row = storage.pods[event.cargo_pod.unit_number]
  if not row then return end
  -- Native starter ascension deploys directly, without a descent callback.
  if row.cargo["space-platform-starter-pack"] and not row.destination then
    row.destination, row.descended_tick, row.starter_direct_deploy = "orbital-hub", game.tick, true
  end
  check(not event.spawned_container and row.destination, "delivered, not spilled or merely arrived")
  row.delivered_tick = game.tick
  if row.origin == "ground-rocket" then
    add(storage.delivered, row.cargo)
  else
    storage.datasets_returned = storage.datasets_returned + (row.cargo[DATASET] or 0)
  end
  storage.pods[event.cargo_pod.unit_number] = nil
end)
local crafted_events = {}
for _, tier in ipairs(C.tiers) do crafted_events[assert(prototypes.recipe[tier.recipe].on_crafted_event)] = true end
crafted_events[assert(prototypes.recipe[ASSEMBLE].on_crafted_event)] = true
crafted_events[assert(prototypes.recipe[ACTIVATE].on_crafted_event)] = true
local function crafted(event)
  if event.entity == storage.terminal and event.recipe == ACTIVATE then
    storage.native_activations = storage.native_activations + 1
    check(state().completed and game.finished, "real native victory")
    storage.victory, storage.activation_tick = state().victory, game.tick
    game.set_game_state{game_finished = false, player_won = true, can_continue = true}
    game.tick_paused = false
    enabled(storage.terminal, false)
    phase("victory")
  elseif event.entity.surface == storage.platform.surface then
    check(not event.bonus and event.product_quality == "normal", "ordinary native completion")
    if event.recipe == ASSEMBLE then
      storage.native_assemblies = storage.native_assemblies + 1
      storage.assembly_tick = game.tick
      phase("return")
    else
      local r = game.forces.player.recipes[event.recipe]
      storage.produced = storage.produced + r.products[1].amount
      storage.compute_dollars = storage.compute_dollars + r.ingredients[1].amount
      -- Freeze at a real completion boundary, never reset/insert committed work.
      if storage.produced - storage.datasets_returned >= 20000 and (storage.stage == "compute" or storage.stage == "finish_compute") then
        local input_arm
        for _, a in ipairs(storage.arms) do if a.role == "core-input" and a.entity.position.x == -4.5 then input_arm = a.entity end end
        if event.entity ~= storage.cores[1] or input_arm.held_stack.valid_for_read then
          for _, e in ipairs(storage.cores) do enabled(e, e == storage.cores[1]) end
          filter(input_arm, {}); enabled(input_arm, true)
          if storage.stage == "compute" then phase("finish_compute") end
          return
        end
        storage.assembler = storage.cores[1]
        storage.cash_section.active = false
        for _, e in ipairs(storage.cores) do enabled(e, false) end
        for _, a in ipairs(storage.arms) do
          if a.role == "hub-input" or a.role == "core-input" then enabled(a.entity, false)
          elseif a.role == "cash-drain" then filter(a.entity, {DOLLAR, DATASET, RACK}); enabled(a.entity, true)
          elseif a.role == "hub-output" then filter(a.entity, {DATASET, MODEL, DOLLAR, RACK}) end
        end
        phase("drain")
      elseif storage.stage == "compute" and event.recipe ~= C.tiers[storage.tier].recipe then
        select_recipe(event.entity, C.tiers[storage.tier].recipe)
      end
    end
  end
end
for id in pairs(crafted_events) do script.on_event(id, crafted) end
script.on_event(defines.events.on_research_finished, function(event)
  if event.by_script then return end
  for _, tier in ipairs(C.tiers) do
    if event.research.name == tier.technology then
      storage.research[#storage.research + 1] = {name = event.research.name, tick = game.tick,
        started_tick = storage.research_started_tick, by_script = false}
    end
  end
end)
local function checkpoint(name)
  storage.saved_tick, storage.resume_stage = game.tick, storage.stage
  if storage.assembler then enabled(storage.assembler, false) end
  for _, a in ipairs(storage.arms) do a.saved_active = enabled(a.entity); enabled(a.entity, false) end
  storage.stage = "checkpoint"
  report(name .. "_checkpoint", {saved_tick = game.tick, resume_stage = storage.resume_stage})
  storage.checkpoint_name = name
  game.speed = 1
  game.server_save("bitermotors-practical-" .. name)
end
local function queue_layout(n)
  local surface = storage.platform.surface
  local layout = n == C.cores and storage.layout or Layout.make(n, C.tiers[storage.tier].recipe)
  storage.construction_target = n
  storage.stage_manifest = layout.manifest
  storage.platform.hub.request_missing_construction_materials = false
  for _, t in ipairs(layout.tiles) do
    local key = t.position.x .. ":" .. t.position.y
    if not storage.planned_tiles[key] and surface.get_tile(t.position).name ~= "space-platform-foundation" then
      check(surface.create_entity{name = "tile-ghost", inner_name = t.name, position = t.position, force = "player"}, "foundation ghost")
      storage.planned_tiles[key] = true
    end
  end
  for _, e in ipairs(layout.entities) do
    local key = e.position.x .. ":" .. e.position.y
    storage.roles[key] = e.role
    if not storage.planned_entities[key] then
      check(surface.create_entity{name = "entity-ghost", inner_name = e.name, position = e.position,
        direction = e.direction, force = "player", expires = false}, "orbital ghost " .. e.name)
      storage.planned_entities[key] = true
    end
  end
  for name, amount in pairs(layout.manifest) do
    if amount > 0 and not storage.sections[name] then storage.sections[name] = request(storage.platform.hub, name, amount, "nauvis", 1) end
  end
end
local function refresh_construction_requests()
  for name, section in pairs(storage.sections) do
    local used = name == "space-platform-foundation" and storage.built_tiles or (storage.built[name] or 0)
    local missing = math.max(0, (storage.stage_manifest[name] or 0) - used)
    update_request(section, name, missing, storage.stage_manifest[name], 1)
  end
  if storage.cash_section and storage.cash_section.active then
    local buffer = C.cash_buffers[storage.tier]
    local dollars = count(storage.platform.hub, defines.inventory.hub_main, DOLLAR)
      + math.max(0, storage.operating_budget - (storage.delivered[DOLLAR] or 0))
    dollars = math.min(buffer, dollars)
    local minimum = math.min(math.floor(buffer / 4), dollars)
    local delivery = math.max(1, math.min(math.floor(buffer / 2), dollars - minimum))
    update_request(storage.cash_section, DOLLAR, minimum, dollars, delivery)
  end
end
local function begin_layout()
  local surface = storage.platform.surface
  check(storage.platform.hub and surface.get_property("gravity") == 0, "native starter created orbital hub")
  storage.starter_hub_items = contents(inv(storage.platform.hub, defines.inventory.hub_main))
  storage.starter_surface_tiles = #surface.find_tiles_filtered{name = "space-platform-foundation"}
  check(helpers.table_to_json(storage.starter_hub_items) == helpers.table_to_json(storage.starter_prototype_items), "native starter actual hub stock equals prototype")
  check(storage.starter_surface_tiles == storage.starter_prototype_tiles, "native starter actual floor equals prototype")
  for _, row in ipairs(storage.shipments) do
    if row.cargo["space-platform-starter-pack"] then row.starter_hub_verified = true end
  end
  queue_layout(1)
  storage.cash_section = request(storage.platform.hub, DOLLAR, C.cash_buffers[1] / 4, "nauvis", C.cash_buffers[1] / 2, C.cash_buffers[1])
  request(storage.platform.hub, RACK, 1, "nauvis", 1)
  phase("construction"); report("starter_delivered")
end
script.on_nth_tick(30, function()
  if game.tick == 0 or not storage.stage or storage.stage == "done" then return end
  if storage.stage == "checkpoint" then
    if not loaded then return end
    loaded = false
    check(game.tick > storage.saved_tick, "reload must advance actual game time")
    storage.stage = storage.resume_stage
    for _, a in ipairs(storage.arms) do enabled(a.entity, a.saved_active) end
    if storage.assembler and storage.stage == "loading" then enabled(storage.assembler, true) end
    game.speed = C.speed
    if storage.checkpoint_name == "victory" then
      check(state().completed and not game.finished, "victory persisted into freeplay")
      check(helpers.table_to_json(state().victory) == helpers.table_to_json(storage.victory), "once-only victory persisted")
      storage.freeplay_start = game.tick
      phase("freeplay")
    end
    report(storage.checkpoint_name .. "_reload", {saved_tick = storage.saved_tick})
    return
  end
  check(game.tick - storage.start_tick <= C.max_ticks, "finite-route simulation budget exceeded: " .. storage.stage)
  if storage.platform.hub then
    check(#storage.platform.surface.find_entities_filtered{type = "electric-energy-interface"} == 0, "no orbital EEI")
    check(storage.platform.surface.solar_power_multiplier == 1, "native solar multiplier")
    refresh_construction_requests()
    if #storage.platform.surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}} == 0 and storage.ready_cores < storage.construction_target then
      storage.ready_cores = storage.construction_target
      storage.ready_tick = game.tick
    end
    local heat = thermal()
    check(heat.burnouts == 0, "orbital burnout")
    for _, core in ipairs(heat.cores or {}) do storage.max_temperature = math.max(storage.max_temperature, core.temperature) end
    if storage.stage ~= "starter" and storage.stage ~= "construction" then
      for _, core in ipairs(storage.cores) do
        if enabled(core) and (core.status == defines.entity_status.low_power or core.status == defines.entity_status.no_power) then
          storage.low_power_samples = storage.low_power_samples + 1
        end
        if enabled(core) and core.status == defines.entity_status.full_output then storage.full_output_samples = storage.full_output_samples + 1 end
      end
      if storage.stage == "activation" and (storage.terminal.status == defines.entity_status.low_power
        or storage.terminal.status == defines.entity_status.no_power) then storage.low_power_samples = storage.low_power_samples + 1 end
    end
  end
  storage.unpacked = game.forces.player.get_item_production_statistics(game.surfaces.nauvis).get_output_count(DATASET)
  if storage.stage == "starter" and storage.delivered["space-platform-starter-pack"] then begin_layout()
  elseif storage.stage == "construction" then
    local ready = #storage.platform.surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}} == 0
    if ready and #storage.cores == 1 then
      table.sort(storage.cores, function(a, b) return a.position.x < b.position.x end)
      for i, e in ipairs(storage.cores) do enabled(e, i <= active_count()) end
      for _, a in ipairs(storage.arms) do
        enabled(a.entity, a.role == "hub-input" or a.role == "hub-output" or a.role == "core-output"
          or (a.role == "core-input" and game.tick >= storage.ready_tick + 120 and a.entity.position.x <= storage.cores[active_count()].position.x))
      end
      phase("compute"); report("built")
    end
  elseif storage.stage == "compute" then
    local f = game.forces.player
    if #C.tiers == 3 and state().cumulative_ai_tokens >= 100000000 then storage.nohyper_expanded = true end
    for i, tier in ipairs(C.tiers) do
      if tier.technology then
        local t = f.technologies[tier.technology]
        if t.enabled and not t.researched and not f.current_research then
          check(f.add_research(t), "native scale research start")
          storage.research_started_tick = game.tick
        end
        if t.researched then storage.tier = math.max(storage.tier, i) end
      end
    end
    local desired = (#C.tiers == 3 and storage.nohyper_expanded) and C.cores or math.min(C.cores, C.ramp[storage.tier])
    -- Uplift may overlap research after the genuine milestone enables its tier;
    -- activation still waits for completed research and complete construction.
    for i, tier in ipairs(C.tiers) do
      if tier.technology and f.technologies[tier.technology].enabled then desired = math.max(desired, math.min(C.cores, C.ramp[i])) end
    end
    if desired > storage.construction_target then queue_layout(desired) end
    local recipe = C.tiers[storage.tier].recipe
    for i, core in ipairs(storage.cores) do
      enabled(core, i <= active_count())
      if 0 == core.crafting_progress and core.get_recipe().name ~= recipe then select_recipe(core, recipe) end
    end
    for _, a in ipairs(storage.arms) do
      if a.role == "core-input" then enabled(a.entity, active_count() > 0 and game.tick >= storage.ready_tick + 120
        and a.entity.position.x <= storage.cores[active_count()].position.x)
      elseif a.role == "core-output" or a.role == "hub-output" then enabled(a.entity, true) end
    end
    local last = storage.ramp_history[#storage.ramp_history]
    if not last or last.cores ~= active_count() then
      storage.ramp_history[#storage.ramp_history + 1] = {cores = active_count(), tick = game.tick,
        tier = storage.tier, earned = state().cumulative_ai_tokens}
    end
  elseif storage.stage == "drain" then
    local hub = inv(storage.platform.hub, defines.inventory.hub_main)
    local dollars = 0
    for _, e in ipairs(storage.input_belts) do
      for i = 1, 2 do dollars = dollars + e.get_transport_line(i).get_item_count(DOLLAR) end
    end
    if hub.get_item_count(DATASET) >= 20000 and physical_datasets() == hub.get_item_count(DATASET) and dollars == 0 and state().unlocked then
      check(hub.get_item_count(RACK) == 1 and storage.delivered[RACK] == 1, "real rocket Rack in hub")
      storage.retained_datasets = hub.get_item_count(DATASET)
      select_recipe(storage.assembler, ASSEMBLE)
      enabled(storage.assembler, true)
      for _, a in ipairs(storage.arms) do
        if a.role == "payload-hub" or a.role == "hub-input" or (a.role == "core-input" and a.entity.position.x == -4.5) then
          filter(a.entity, {DATASET, RACK}); a.entity.inserter_stack_size_override = 12; enabled(a.entity, true)
        elseif a.role == "assembly-input" then
          enabled(a.entity, math.abs(a.entity.position.x - (storage.assembler.position.x + 1)) < 0.1)
        end
      end
      export_layout()
      phase("loading"); report("payload_retained", {retained_datasets = storage.retained_datasets})
    end
  elseif storage.stage == "loading" then
    local n = count(storage.assembler, defines.inventory.crafter_input, DATASET)
    if not storage.loading_reloaded and n >= 1000 and n < 20000 then
      storage.loading_reloaded = true
      checkpoint("loading")
    elseif storage.assembler.crafting_progress > 0 then
      check(storage.loading_reloaded, "mid-loading reload required")
      phase("assembly"); report("assembly_started", {committed_datasets = 20000, retained_datasets = storage.retained_datasets})
    end
  elseif storage.stage == "return" then
    if state().models_returned == 1 then
      check(game.forces.player.recipes[ACTIVATE].enabled, "native activation unlock")
      storage.terminal.set_recipe(ACTIVATE)
      phase("activation"); report("model_returned")
    end
  elseif storage.stage == "victory" then
    check(storage.native_activations == 1 and storage.native_assemblies == 1, "one physical ending")
    checkpoint("victory")
  elseif storage.stage == "freeplay" and game.tick - storage.freeplay_start >= 2400 then
    check(not game.finished and not game.tick_paused, "freeplay actually advances")
    check(state().models_activated == 1, "no duplicated activation")
    report("complete", {freeplay_ticks = game.tick - storage.freeplay_start, saved_tick = storage.saved_tick,
      retained_datasets = storage.retained_datasets})
    storage.stage = "done"
  end
  if game.tick % 3600 == 0 then
    local row = snapshot(); row.tick = game.tick
    row.remaining_ghosts = {}
    if storage.platform.hub then
      for _, e in pairs(storage.platform.surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}}) do
        if #row.remaining_ghosts < 16 then row.remaining_ghosts[#row.remaining_ghosts + 1] = {name = e.ghost_name, position = e.position} end
      end
    end
    helpers.write_file("bitermotors-practical-progress.jsonl", helpers.table_to_json(row) .. "\n", true)
  end
end)
