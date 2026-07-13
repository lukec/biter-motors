#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
tmp="$(mktemp -d /tmp/factoryx-validate.XXXXXX)"
mods="$tmp/mods"
smoke="$mods/factoryx_smoke_0.1.0"
save="$tmp/saves/x-smoke.zip"
report="$tmp/script-output/factoryx-smoke.jsonl"

mkdir -p "$mods" "$smoke" "$tmp/script-output" "$tmp/saves"
ln -sfn "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG

cat > "$mods/mod-list.json" <<'EOF_MOD_LIST'
{
  "mods": [
    {"name": "base", "enabled": true},
    {"name": "space-age", "enabled": true},
    {"name": "factoryx", "enabled": true},
    {"name": "factoryx_smoke", "enabled": true}
  ]
}
EOF_MOD_LIST

cat > "$smoke/info.json" <<'EOF_INFO'
{
  "name": "factoryx_smoke",
  "version": "0.1.0",
  "title": "FactoryX Smoke Test",
  "author": "Codex",
  "factorio_version": "2.1",
  "dependencies": ["base >= 2.1.0", "space-age >= 2.1.0", "factoryx >= 0.1.0"]
}
EOF_INFO

cat > "$smoke/data.lua" <<'EOF_DATA'
data:extend({
  {
    type = "recipe",
    name = "factoryx-smoke-premium-ev-economics",
    categories = {"x-vehicle-assembly"},
    enabled = true,
    hidden = true,
    energy_required = 20,
    allow_productivity = false,
    ingredients = {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "x-battery-pack", amount = 8},
      {type = "item", name = "x-electric-drivetrain", amount = 2},
      {type = "item", name = "advanced-circuit", amount = 10}
    },
    results = {{type = "item", name = "x-premium-ev", amount = 1}}
  }
})
EOF_DATA

cat > "$smoke/control.lua" <<'EOF_LUA'
local REPORT = "factoryx-smoke.jsonl"
local CONTROLLER = "x-planetary-grid-controller"
local AGI_MODEL = "x-agi-model"
local AGI_RECIPE = "x-agi-training-run"
local DOLLAR = "x-dollar"
local GRID_CONNECTION = "x-ev-charging-grid-connection"
local POWER_SINK = "x-ev-charging-power-sink"
local V2_POWER_SINK = "x-ev-charging-v2-power-sink"
local SALES_OFFICE = "x-sales-office"
local STATION = "x-ev-charging-station"
local STATION_V2 = "x-ev-charging-station-v2"
local STATION_V3 = "x-ev-charging-station-v3"
local STATION_V4 = "x-ev-charging-station-v4"
local POWER_POLE = "medium-electric-pole"
local POWER_SOURCE = "electric-energy-interface"
local RESERVATION = "x-ev-reservation"
local FIRST_SALE_RECIPE = "x-sell-prototype-roadster"
local PROTOTYPE_ROADSTER = "x-prototype-roadster"
local RESERVATION_SALES_RECIPE = "x-sell-mass-market-ev"
local ROBOTAXI_SALE_RECIPE = "x-sell-robotaxi-fleet"
local ROBOTAXI_FLEET = "x-robotaxi-fleet"
local ROBOTAXI_SERVICE_CENTER = "x-robotaxi-service-center"
local SMALL_LAUNCH_TECH = "x-small-orbital-launch"
local GIGAFACTORY = "x-gigafactory-building"
local GIGAFACTORY_V2 = "x-gigafactory-v2"
local GIGAFACTORY_RECIPE = "x-gigafactory-building"
local GIGAFACTORY_MODULE_RECIPE = "x-gigafactory-module"
local PREMIUM_EV_RECIPE = "x-premium-ev"
local PREMIUM_EV_ECONOMICS_RECIPE = "factoryx-smoke-premium-ev-economics"
local MASS_MARKET_EV_RECIPE = "x-mass-market-ev"
local SOLAR_ARRAY = "x-high-density-solar-array"
local MEGAPACK = "x-megapack"
local BITER_SPAWNER = "biter-spawner"
local SMALL_BITER = "small-biter"
local GUN_TURRET = "gun-turret"
local WORM = "small-worm-turret"
local CUSTOMER_FORCE = "factoryx-customers"
local TERRESTRIAL_DATACENTER = "x-terrestrial-datacenter"
local TERRESTRIAL_AI_RECIPE = "x-terrestrial-ai-token"

local function output_inventory_id()
  return defines.inventory.crafter_output or defines.inventory.assembling_machine_output
end

local function input_inventory_id()
  return defines.inventory.crafter_input or defines.inventory.assembling_machine_input
end

local function write_report(payload)
  helpers.write_file(REPORT, helpers.table_to_json(payload) .. "\n", true)
end

local function safe_value(getter)
  local ok, value = pcall(getter)
  if not ok then
    return {ok = false, error = tostring(value)}
  end
  return {ok = true, value = value}
end

local function create_named(surface, name, position, force)
  local found = surface.find_non_colliding_position(name, position, 128, 1) or position
  return surface.create_entity{name = name, position = found, force = force}
end

script.on_init(function()
  game.tick_paused = false
  local surface = game.surfaces.nauvis or game.surfaces[1]
  local force = game.forces.player
  for _, technology_name in pairs({
    "x-sales-office",
    "x-premium-ev-program",
    "x-ev-charging-network",
    "x-capital-scaling",
    "x-energy-products",
    "x-terrestrial-ai",
    "x-autonomous-logistics",
    "x-planetary-energy-grid"
  }) do
    if force.technologies[technology_name] then
      force.technologies[technology_name].researched = true
    end
  end
  force.get_item_production_statistics(surface).set_output_count("x-premium-ev", 100)

  local milestone_office = create_named(surface, SALES_OFFICE, {-12, 0}, force)
  local reservation_office = create_named(surface, SALES_OFFICE, {-8, 0}, force)
  local robotaxi_office = create_named(surface, SALES_OFFICE, {-8, -12}, force)
  local robotaxi_center = create_named(surface, ROBOTAXI_SERVICE_CENTER, {90, 0}, force)
  local pole = create_named(surface, POWER_POLE, {-4, 0}, force)
  local station_v2 = create_named(surface, STATION_V2, {4, 0}, force)
  local station = create_named(surface, STATION, {-2, 0}, force)
  local biter_spawner = create_named(surface, BITER_SPAWNER, {-2, 16}, game.forces.enemy)
  local commanded_biter = create_named(surface, SMALL_BITER, {6, 16}, game.forces.enemy)
  local customer_buyer_2 = create_named(surface, SMALL_BITER, {8, 18}, game.forces.enemy)
  local customer_buyer_3 = create_named(surface, SMALL_BITER, {10, 18}, game.forces.enemy)
  local customer_buyer_4 = create_named(surface, SMALL_BITER, {12, 18}, game.forces.enemy)
  local outer_customer_spawner = create_named(surface, BITER_SPAWNER, {70, 20}, game.forces.enemy)
  local outer_customer_biter = create_named(surface, SMALL_BITER, {72, 20}, game.forces.enemy)
  local customer_turret = create_named(surface, GUN_TURRET, {10, 16}, force)
  local far_biter_spawner = create_named(surface, BITER_SPAWNER, {1400, 0}, game.forces.enemy)
  local hostile_worm = create_named(surface, WORM, {180, 100}, game.forces.enemy)
  local legacy_customer_worm = create_named(surface, WORM, {190, 100}, game.forces[CUSTOMER_FORCE])
  local controller = create_named(surface, CONTROLLER, {24, -24}, force)
  local gigafactory = create_named(surface, GIGAFACTORY, {24, 24}, force)
  local gigafactory_v2 = create_named(surface, GIGAFACTORY_V2, {40, 24}, force)
  local gigafactory_economics_test = create_named(surface, GIGAFACTORY, {80, 80}, force)
  local solar_array = create_named(surface, SOLAR_ARRAY, {60, 24}, force)
  local megapack = create_named(surface, MEGAPACK, {64, 24}, force)
  local power_source = create_named(surface, POWER_SOURCE, {-4, -2}, force)
  local roadster = create_named(surface, PROTOTYPE_ROADSTER, {4, -6}, force)
  local datacenter = create_named(surface, TERRESTRIAL_DATACENTER, {0, -40}, force)
  local datacenter_pole = create_named(surface, POWER_POLE, {0, -35}, force)
  local datacenter_power = create_named(surface, POWER_SOURCE, {2, -35}, force)
  if power_source then
    power_source.electric_interface_mode = defines.electric_interface_mode.primary_output
    power_source.power_production = 10000000
    power_source.power_usage = 0
    power_source.output_flow_limit = 10000000
  end
  if datacenter_power then
    datacenter_power.electric_interface_mode = defines.electric_interface_mode.primary_output
    datacenter_power.power_production = 100000000
    datacenter_power.power_usage = 0
    datacenter_power.output_flow_limit = 100000000
  end
  if not milestone_office or not reservation_office or not robotaxi_office or not robotaxi_center or not pole or not station or not station_v2 or not biter_spawner or not commanded_biter or not customer_buyer_2 or not customer_buyer_3 or not customer_buyer_4 or not outer_customer_spawner or not outer_customer_biter or not customer_turret or not far_biter_spawner or not hostile_worm or not legacy_customer_worm or not controller or not gigafactory or not gigafactory_v2 or not gigafactory_economics_test or not solar_array or not megapack or not power_source or not roadster or not datacenter or not datacenter_pole or not datacenter_power then
    write_report{tick = game.tick, status = "failed", reason = "entity creation failed", milestone_office = milestone_office ~= nil, reservation_office = reservation_office ~= nil, pole = pole ~= nil, station = station ~= nil, station_v2 = station_v2 ~= nil, biter_spawner = biter_spawner ~= nil, far_biter_spawner = far_biter_spawner ~= nil, hostile_worm = hostile_worm ~= nil, legacy_customer_worm = legacy_customer_worm ~= nil, controller = controller ~= nil, gigafactory = gigafactory ~= nil, gigafactory_v2 = gigafactory_v2 ~= nil, solar_array = solar_array ~= nil, megapack = megapack ~= nil}
    return
  end

  for _, entity in pairs({
    milestone_office, reservation_office, robotaxi_office,
    station, station_v2, robotaxi_center, roadster
  }) do
    script.raise_script_built{entity = entity}
  end

  commanded_biter.commandable.set_command{
    type = defines.command.attack,
    target = customer_turret,
    distraction = defines.distraction.none
  }
  remote.call("factoryx", "refresh_biter_customer_market", "player")
  local customer_command = commanded_biter.commandable and commanded_biter.commandable.command
  local customers = game.forces[CUSTOMER_FORCE]
  storage.commanded_biter_converted = commanded_biter.force.name == CUSTOMER_FORCE
  storage.customer_attack_command_cleared = customer_command
    and customer_command.type == defines.command.wander
    and customer_command.distraction == defines.distraction.none
  storage.commanded_biter_unit_number = commanded_biter.unit_number
  storage.commanded_biter_initial_position = {
    x = commanded_biter.position.x,
    y = commanded_biter.position.y
  }
  storage.player_customer_friend = customers and force.get_friend(customers) or false
  storage.customer_player_friend = customers and customers.get_friend(force) or false
  storage.outer_customer_spawner_unit_number = outer_customer_spawner.unit_number
  storage.outer_customer_biter_unit_number = outer_customer_biter.unit_number
  storage.outer_customer_biter_converted = outer_customer_biter.force.name == CUSTOMER_FORCE
  storage.v4_recipe_enabled_before_robotaxi_sale = force.recipes[STATION_V4].enabled

  pcall(function() milestone_office.set_recipe(FIRST_SALE_RECIPE) end)
  pcall(function() reservation_office.set_recipe(RESERVATION_SALES_RECIPE) end)
  pcall(function() robotaxi_office.set_recipe(ROBOTAXI_SALE_RECIPE) end)
  local robotaxi_input = robotaxi_office.get_inventory(input_inventory_id())
  local inserted_robotaxi_fleet = robotaxi_input and robotaxi_input.insert{name = ROBOTAXI_FLEET, count = 3} or 0
  local robotaxi_center_inventory = robotaxi_center.get_inventory(defines.inventory.chest)
  if robotaxi_center_inventory then robotaxi_center_inventory.insert{name = ROBOTAXI_FLEET, count = 20} end
  local token_statistics = force.get_item_production_statistics(surface)
  token_statistics.set_output_count("x-ai-token", 1000000000)
  storage.agi_training_status = remote.call("factoryx", "agi_training_status", "player")
  pcall(function() controller.set_recipe(AGI_RECIPE) end)
  pcall(function() gigafactory.set_recipe(PREMIUM_EV_RECIPE) end)
  pcall(function() gigafactory_v2.set_recipe(MASS_MARKET_EV_RECIPE) end)
  pcall(function() gigafactory_economics_test.set_recipe(PREMIUM_EV_ECONOMICS_RECIPE) end)
  local economics_input = gigafactory_economics_test.get_inventory(input_inventory_id())
  storage.gigafactory_economics_cars_inserted = economics_input.insert{name = "car", count = 1}
  economics_input.insert{name = "x-battery-pack", count = 16}
  economics_input.insert{name = "x-electric-drivetrain", count = 4}
  economics_input.insert{name = "advanced-circuit", count = 20}
  storage.gigafactory_economics_test = gigafactory_economics_test
  for level = 1, 5 do
    local efficiency_technology = force.technologies["x-terrestrial-ai-efficiency-" .. level]
    efficiency_technology.enabled = true
    efficiency_technology.researched = true
  end
  force.reset_technology_effects()
  pcall(function() datacenter.set_recipe(TERRESTRIAL_AI_RECIPE) end)
  local datacenter_input = datacenter.get_inventory(input_inventory_id())
  storage.datacenter_dollars_inserted = datacenter_input and datacenter_input.insert{name = DOLLAR, count = 100} or 0
  local gigafactory_modules = gigafactory.get_inventory(defines.inventory.crafter_modules)
  local gigafactory_v2_modules = gigafactory_v2.get_inventory(defines.inventory.crafter_modules)
  storage.gigafactory_modules_inserted = gigafactory_modules
    and gigafactory_modules.insert{name = "speed-module", count = 8} or 0
  storage.gigafactory_v2_modules_inserted = gigafactory_v2_modules
    and gigafactory_v2_modules.insert{name = "speed-module", count = 8} or 0
  if gigafactory_v2_modules then
    gigafactory_v2_modules.clear()
    storage.final_productivity_modules_inserted = gigafactory_v2_modules.insert{
      name = "productivity-module",
      count = 8
    }
    pcall(function() gigafactory_v2.set_recipe("x-battery-pack") end)
    storage.intermediate_productivity_modules_inserted = gigafactory_v2_modules.insert{
      name = "productivity-module",
      count = 8
    }
    gigafactory_v2_modules.clear()
    pcall(function() gigafactory_v2.set_recipe(MASS_MARKET_EV_RECIPE) end)
  end
  local event_unpowered_station = create_named(surface, STATION, {80, 0}, force)
  local event_unpowered_station_created = event_unpowered_station ~= nil
  if event_unpowered_station then
    script.raise_event(defines.events.script_raised_built, {entity = event_unpowered_station})
  end
  storage.event_unpowered_station_created = event_unpowered_station_created
  storage.event_unpowered_station_survived = event_unpowered_station_created and event_unpowered_station.valid
  storage.event_unpowered_station_unit_number = event_unpowered_station and event_unpowered_station.unit_number
  local direct_unpowered_station = create_named(surface, STATION, {96, 0}, force)
  storage.direct_unpowered_station_created = direct_unpowered_station ~= nil
  storage.direct_unpowered_station_unit_number = direct_unpowered_station and direct_unpowered_station.unit_number
  local station_v3 = create_named(surface, STATION_V3, {112, 0}, force)
  local station_v4 = create_named(surface, STATION_V4, {128, 0}, force)
  storage.station_v3_unit_number = station_v3 and station_v3.unit_number
  storage.station_v4_unit_number = station_v4 and station_v4.unit_number
  if station_v3 then
    script.raise_event(defines.events.script_raised_built, {entity = station_v3})
  end
  if station_v4 then
    script.raise_event(defines.events.script_raised_built, {entity = station_v4})
  end
  script.raise_event(defines.events.script_raised_built, {entity = gigafactory})
  script.raise_event(defines.events.script_raised_built, {entity = controller})
  script.raise_event(defines.events.script_raised_built, {entity = datacenter})
  script.raise_event(defines.events.script_raised_built, {entity = roadster})

  local office_output = milestone_office.get_inventory(output_inventory_id())
  local inserted_sale_dollar = office_output and office_output.insert{name = DOLLAR, count = 1} or 0
  storage.reservation_office_unit_number = reservation_office.unit_number
  storage.robotaxi_office_unit_number = robotaxi_office.unit_number
  storage.robotaxi_office = robotaxi_office
  storage.station_v2_unit_number = station_v2.unit_number
  storage.controller_unit_number = controller.unit_number
  storage.gigafactory_unit_number = gigafactory.unit_number
  storage.gigafactory_v2_unit_number = gigafactory_v2.unit_number
  storage.solar_array_unit_number = solar_array.unit_number
  storage.megapack_unit_number = megapack.unit_number
  storage.power_source_unit_number = power_source.unit_number
  storage.roadster_unit_number = roadster.unit_number
  storage.datacenter_unit_number = datacenter.unit_number
  storage.datacenter_power_unit_number = datacenter_power.unit_number
  storage.biter_spawner_unit_number = biter_spawner.unit_number
  storage.far_biter_spawner_unit_number = far_biter_spawner.unit_number
  storage.hostile_worm_unit_number = hostile_worm.unit_number
  storage.legacy_customer_worm_unit_number = legacy_customer_worm.unit_number
  storage.surface_index = surface.index
  storage.initial_spawner_count = #surface.find_entities_filtered{type = "unit-spawner"}
  storage.initial_worm_count = #surface.find_entities_filtered{type = "turret", name = WORM}
  write_report{
    tick = game.tick,
    status = "setup",
    inserted_sale_dollar = inserted_sale_dollar,
    agi_training_unlocked = storage.agi_training_status and storage.agi_training_status.unlocked,
    event_unpowered_station_created = storage.event_unpowered_station_created,
    event_unpowered_station_survived = storage.event_unpowered_station_survived,
    event_unpowered_station_unit_number = storage.event_unpowered_station_unit_number,
    direct_unpowered_station_created = storage.direct_unpowered_station_created,
    direct_unpowered_station_unit_number = storage.direct_unpowered_station_unit_number,
    station_v3_unit_number = storage.station_v3_unit_number,
    station_v4_unit_number = storage.station_v4_unit_number,
    milestone_office_unit_number = milestone_office.unit_number,
    reservation_office_unit_number = reservation_office.unit_number,
    robotaxi_office_unit_number = robotaxi_office.unit_number,
    inserted_robotaxi_fleet = inserted_robotaxi_fleet,
    commanded_biter_converted = storage.commanded_biter_converted,
    customer_attack_command_cleared = storage.customer_attack_command_cleared,
    player_customer_friend = storage.player_customer_friend,
    customer_player_friend = storage.customer_player_friend,
    station_unit_number = station.unit_number,
    station_v2_unit_number = station_v2.unit_number,
    biter_spawner_unit_number = biter_spawner.unit_number,
    far_biter_spawner_unit_number = far_biter_spawner.unit_number,
    hostile_worm_unit_number = hostile_worm.unit_number,
    legacy_customer_worm_unit_number = legacy_customer_worm.unit_number,
    controller_unit_number = controller.unit_number,
    gigafactory_unit_number = gigafactory.unit_number,
    gigafactory_v2_unit_number = gigafactory_v2.unit_number,
    solar_array_unit_number = storage.solar_array_unit_number,
    megapack_unit_number = megapack.unit_number
  }
end)

script.on_event(defines.events.on_tick, function()
  if game.tick_paused then
    game.tick_paused = false
  end
  local office = storage.robotaxi_office
  if office and office.valid then
    office.energy = 100000000
  end
  local economics_test = storage.gigafactory_economics_test
  if economics_test and economics_test.valid then
    economics_test.energy = 1000000000
    local economics_output = economics_test.get_inventory(output_inventory_id())
    local completed = economics_output.get_item_count("x-premium-ev")
    if completed > 0 then
      storage.gigafactory_economics_outputs =
        (storage.gigafactory_economics_outputs or 0) + completed
      economics_output.clear()
    end
    if (storage.gigafactory_economics_cars_inserted or 0) < 2 then
      local economics_input = economics_test.get_inventory(input_inventory_id())
      storage.gigafactory_economics_cars_inserted =
        (storage.gigafactory_economics_cars_inserted or 0)
        + economics_input.insert{name = "car", count = 1}
    end
  end
end)

script.on_nth_tick(30, function()
  if storage.roadster_factory_charge_checked then return end
  local surface = game.get_surface(storage.surface_index or 1)
  local roadster
  for _, candidate in pairs(surface and surface.find_entities_filtered{name = PROTOTYPE_ROADSTER} or {}) do
    if candidate.unit_number == storage.roadster_unit_number then
      roadster = candidate
      break
    end
  end
  if not roadster or not roadster.grid then return end
  local battery_count = 0
  local battery_energy = 0
  local battery_capacity = 0
  for _, equipment in pairs(roadster.grid.equipment) do
    if equipment.type == "battery-equipment" then
      battery_count = battery_count + 1
      battery_energy = battery_energy + equipment.energy
      battery_capacity = battery_capacity + equipment.max_energy
      equipment.energy = 0
    end
  end
  local drive_charge = 0
  if roadster.burner and roadster.burner.inventory then
    drive_charge = roadster.burner.inventory.get_item_count("x-electric-drive-charge") * 1000000
    roadster.burner.inventory.clear()
  end
  storage.roadster_started_charged = battery_count > 0
    and battery_energy + drive_charge >= battery_capacity
  storage.roadster_factory_charge_checked = true
end)

script.on_nth_tick(60, function()
  if not storage.preproduction_market then
    storage.preproduction_market = remote.call("factoryx", "biter_customer_market", "player")
  end
end)

script.on_nth_tick(120, function()
  if storage.customer_ev_seeded then
    return
  end
  local surface = game.get_surface(storage.surface_index or 1)
  local statistics = game.forces.player.get_item_production_statistics(surface)
  statistics.set_input_count(PROTOTYPE_ROADSTER, 1)
  statistics.set_output_count(PROTOTYPE_ROADSTER, 1)
  storage.customer_ev_seeded = true
end)

script.on_nth_tick(300, function()
  if storage.customer_ev_seeded and not storage.postproduction_market then
    local surface = game.get_surface(storage.surface_index or 1)
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE}) do
      if office.unit_number == storage.reservation_office_unit_number then
        pcall(function() office.set_recipe(RESERVATION_SALES_RECIPE) end)
      end
    end
    storage.postproduction_market = remote.call("factoryx", "biter_customer_market", "player")
  end
end)

local function find_unit(surface, name, unit_number)
  for _, entity in pairs(surface.find_entities_filtered{name = name}) do
    if entity.unit_number == unit_number then
      return entity
    end
  end
  return nil
end

script.on_nth_tick(101, function()
  if game.tick < 101 or storage.compute_brownout_started then return end
  storage.compute_brownout_started = true
  local surface = game.get_surface(storage.surface_index or 1)
  local datacenter = find_unit(surface, TERRESTRIAL_DATACENTER, storage.datacenter_unit_number)
  local power = find_unit(surface, POWER_SOURCE, storage.datacenter_power_unit_number)
  storage.compute_progress_before_brownout = datacenter and datacenter.crafting_progress or -1
  if power then
    power.power_production = 1
    power.output_flow_limit = 1
    power.energy = 0
  end
end)

script.on_nth_tick(111, function()
  if game.tick < 111 or storage.compute_brownout_reported then return end
  storage.compute_brownout_reported = true
  local surface = game.get_surface(storage.surface_index or 1)
  local datacenter = find_unit(surface, TERRESTRIAL_DATACENTER, storage.datacenter_unit_number)
  write_report{
    tick = game.tick,
    status = "compute_brownout",
    progress_before = storage.compute_progress_before_brownout,
    progress_after = datacenter and datacenter.crafting_progress or -1,
    entity_status = datacenter and tostring(datacenter.status) or "missing",
    low_power_status = tostring(defines.entity_status.low_power),
    no_power_status = tostring(defines.entity_status.no_power),
    energy = datacenter and datacenter.energy or -1,
    electric_buffer_size = datacenter and datacenter.electric_buffer_size or -1
  }
end)

script.on_nth_tick(121, function()
  if game.tick < 121 or storage.compute_brownout_recovered then return end
  storage.compute_brownout_recovered = true
  local surface = game.get_surface(storage.surface_index or 1)
  local power = find_unit(surface, POWER_SOURCE, storage.datacenter_power_unit_number)
  if power then
    power.power_production = 100000000
    power.output_flow_limit = 100000000
    power.energy = power.electric_buffer_size
  end
end)

script.on_nth_tick(180, function()
  if storage.commanded_biter_wander_distance then return end
  local surface = game.get_surface(storage.surface_index or 1)
  local commanded_biter = find_unit(surface, SMALL_BITER, storage.commanded_biter_unit_number)
  if commanded_biter and storage.commanded_biter_initial_position then
    local dx = commanded_biter.position.x - storage.commanded_biter_initial_position.x
    local dy = commanded_biter.position.y - storage.commanded_biter_initial_position.y
    storage.commanded_biter_wander_distance = math.sqrt(dx * dx + dy * dy)
  end
end)

script.on_nth_tick(5000, function()
  if game.tick < 5000 or storage.brownout_started then return end
  storage.brownout_started = true
  local surface = game.get_surface(storage.surface_index or 1)
  local power_source = find_unit(surface, POWER_SOURCE, storage.power_source_unit_number)
  if power_source then
    power_source.power_production = 2600
    power_source.output_flow_limit = 2600
    power_source.energy = 0
  end
end)

script.on_nth_tick(5160, function()
  if game.tick < 5160 or storage.brownout_reported then return end
  storage.brownout_reported = true
  local surface = game.get_surface(storage.surface_index or 1)
  local power_source = find_unit(surface, POWER_SOURCE, storage.power_source_unit_number)
  local sub_network = power_source and power_source.electric_network
  local network = sub_network and sub_network.parent_network
  write_report{
    tick = game.tick,
    status = "customer_brownout",
    market = remote.call("factoryx", "refresh_biter_customer_market", "player"),
    power_flow = network and network.flow_last_tick,
    source_production = power_source and power_source.power_production,
    source_output_limit = power_source and power_source.output_flow_limit
  }
end)

script.on_nth_tick(5220, function()
  if game.tick < 5220 or storage.brownout_recovered then return end
  storage.brownout_recovered = true
  local surface = game.get_surface(storage.surface_index or 1)
  local power_source = find_unit(surface, POWER_SOURCE, storage.power_source_unit_number)
  if power_source then
    power_source.power_production = 10000000
    power_source.output_flow_limit = 10000000
  end
end)

script.on_nth_tick(1, function()
  if not storage.awaiting_victory or storage.victory_reported or not game.finished then
    return
  end
  storage.victory_reported = true
  local surface = game.get_surface(storage.surface_index or 1)
  local controller = surface and find_unit(surface, CONTROLLER, storage.controller_unit_number)
  local output = controller and controller.get_inventory(output_inventory_id())
  write_report{
    tick = game.tick,
    status = "victory",
    agi_models = output and output.get_item_count(AGI_MODEL) or -1,
    game_finished = safe_value(function() return game.finished end)
  }
end)

script.on_nth_tick(3780, function()
  if game.tick < 3780 then
    return
  end
  local surface = game.get_surface(storage.surface_index or 1)
  if not surface then
    write_report{tick = game.tick, status = "failed", reason = "surface missing"}
    return
  end
  local office = find_unit(surface, SALES_OFFICE, storage.reservation_office_unit_number)
  local robotaxi_office = find_unit(surface, SALES_OFFICE, storage.robotaxi_office_unit_number)
  local station_v2 = find_unit(surface, STATION_V2, storage.station_v2_unit_number)
  local controller = find_unit(surface, CONTROLLER, storage.controller_unit_number)
  local biter_spawner = find_unit(surface, BITER_SPAWNER, storage.biter_spawner_unit_number)
  local far_biter_spawner = find_unit(surface, BITER_SPAWNER, storage.far_biter_spawner_unit_number)
  local hostile_worm = find_unit(surface, WORM, storage.hostile_worm_unit_number)
  local legacy_customer_worm = find_unit(surface, WORM, storage.legacy_customer_worm_unit_number)
  local commanded_biter = find_unit(surface, SMALL_BITER, storage.commanded_biter_unit_number)
  local outer_customer_biter = find_unit(surface, SMALL_BITER, storage.outer_customer_biter_unit_number)
  local event_unpowered_station = find_unit(surface, STATION, storage.event_unpowered_station_unit_number)
  local direct_unpowered_station = find_unit(surface, STATION, storage.direct_unpowered_station_unit_number)
  local station_v3 = find_unit(surface, STATION_V3, storage.station_v3_unit_number)
  local station_v4 = find_unit(surface, STATION_V4, storage.station_v4_unit_number)
  local gigafactory = find_unit(surface, GIGAFACTORY, storage.gigafactory_unit_number)
  local gigafactory_v2 = find_unit(surface, GIGAFACTORY_V2, storage.gigafactory_v2_unit_number)
  local gigafactory_economics_test = storage.gigafactory_economics_test
  local solar_array = find_unit(surface, SOLAR_ARRAY, storage.solar_array_unit_number)
  local roadster = find_unit(surface, PROTOTYPE_ROADSTER, storage.roadster_unit_number)
  local datacenter = find_unit(surface, TERRESTRIAL_DATACENTER, storage.datacenter_unit_number)
  local station_output = station_v2 and station_v2.get_inventory(defines.inventory.chest)
  local controller_inventory = controller and controller.get_inventory(output_inventory_id())
  local station_recipe = game.forces.player.recipes["x-ev-charging-station"]
  local station_v2_recipe = game.forces.player.recipes["x-ev-charging-station-v2"]
  local station_v3_recipe = game.forces.player.recipes["x-ev-charging-station-v3"]
  local station_v4_recipe = game.forces.player.recipes["x-ev-charging-station-v4"]
  local first_sale_recipe = game.forces.player.recipes["x-sell-prototype-roadster"]
  local roadster_recipe = game.forces.player.recipes["x-prototype-roadster"]
  local gigafactory_item_recipe = game.forces.player.recipes[GIGAFACTORY_RECIPE]
  local gigafactory_module_recipe = game.forces.player.recipes[GIGAFACTORY_MODULE_RECIPE]
  local premium_ev_recipe = game.forces.player.recipes[PREMIUM_EV_RECIPE]
  local gigacast_recipe = game.forces.player.recipes["x-gigacast"]
  local gigafactory_v2_recipe = game.forces.player.recipes[GIGAFACTORY_V2]
  local mass_market_ev_recipe = game.forces.player.recipes[MASS_MARKET_EV_RECIPE]
  local solar_array_recipe = game.forces.player.recipes[SOLAR_ARRAY]
  local megapack_recipe = game.forces.player.recipes[MEGAPACK]
  local sell_megapack_recipe = game.forces.player.recipes["x-sell-megapack"]
  local selected_gigafactory_recipe = gigafactory and gigafactory.get_recipe()
  local selected_gigafactory_v2_recipe = gigafactory_v2 and gigafactory_v2.get_recipe()
  local selected_reservation_office_recipe = office and office.get_recipe()
  local robotaxi_output = robotaxi_office and robotaxi_office.get_inventory(output_inventory_id())
  local small_launch_technology = game.forces.player.technologies[SMALL_LAUNCH_TECH]
  local logistic_system_technology = game.forces.player.technologies["logistic-system"]
  local market = remote.call("factoryx", "refresh_biter_customer_market", "player")
  local progress = remote.call("factoryx", "progress_status", "player")
  local progression_integrity = remote.call("factoryx", "progression_integrity", "player")
  local vehicle_ownership = remote.call("factoryx", "customer_vehicle_ownership", "player")
  local sales_office_status = remote.call("factoryx", "sales_office_status", "player")
  local maximum_settlement_capacity = 0
  for _, office_status in pairs(sales_office_status or {}) do
    for _, settlement_status in pairs(office_status.settlements or {}) do
      maximum_settlement_capacity = math.max(
        maximum_settlement_capacity,
        settlement_status.capacity or 0
      )
    end
  end
  local ai_efficiency = remote.call("factoryx", "ai_efficiency_status", "player")
  local datacenter_input = datacenter and datacenter.get_inventory(input_inventory_id())
  local datacenter_output = datacenter and datacenter.get_inventory(output_inventory_id())
  local reservations = station_output and station_output.get_item_count(RESERVATION) or -1
  local agi_training = remote.call("factoryx", "agi_training_status", "player")
  local grid_connections = #surface.find_entities_filtered{name = GRID_CONNECTION, force = game.forces.player}
  local logistic_roboports = #surface.find_entities_filtered{type = "roboport", force = game.forces.player}
  local power_sinks = #surface.find_entities_filtered{name = POWER_SINK, force = game.forces.player}
  local v2_power_sinks = #surface.find_entities_filtered{name = V2_POWER_SINK, force = game.forces.player}
  local customer_force = game.forces[CUSTOMER_FORCE]
  local prospect_units = #surface.find_entities_filtered{
    name = {
      "x-small-biter-prospect", "x-medium-biter-prospect",
      "x-big-biter-prospect", "x-behemoth-biter-prospect",
      "x-small-spitter-prospect", "x-medium-spitter-prospect",
      "x-big-spitter-prospect", "x-behemoth-spitter-prospect"
    },
    force = customer_force
  }
  local biter_spawner_customer = biter_spawner and customer_force and biter_spawner.force.name == CUSTOMER_FORCE
  local far_biter_spawner_enemy = far_biter_spawner and far_biter_spawner.force.name == "enemy"
  local hostile_worm_enemy = hostile_worm and hostile_worm.force.name == "enemy"
  local legacy_customer_worm_enemy = legacy_customer_worm and legacy_customer_worm.force.name == "enemy"
  local commanded_biter_distance = storage.commanded_biter_wander_distance or 0
  local roadster_batteries = 0
  local roadster_battery_energy = 0
  if roadster and roadster.grid then
    for _, equipment in pairs(roadster.grid.equipment) do
      if equipment.type == "battery-equipment" then
        roadster_batteries = roadster_batteries + 1
        roadster_battery_energy = roadster_battery_energy + equipment.energy
      end
    end
  end
  local roadster_fuel = roadster and roadster.burner
    and roadster.burner.inventory.get_item_count("x-electric-drive-charge") or 0
  local economics_output = gigafactory_economics_test and gigafactory_economics_test.valid
    and gigafactory_economics_test.get_inventory(output_inventory_id())
  if commanded_biter and storage.commanded_biter_initial_position then
    local dx = commanded_biter.position.x - storage.commanded_biter_initial_position.x
    local dy = commanded_biter.position.y - storage.commanded_biter_initial_position.y
    commanded_biter_distance = math.sqrt(dx * dx + dy * dy)
  end
  write_report{
    tick = game.tick,
    status = "checked",
    prospect_units = prospect_units,
    ev_charging_station_enabled = station_recipe and station_recipe.enabled,
    ev_charging_station_v2_created = find_unit(surface, STATION_V2, storage.station_v2_unit_number) ~= nil,
    ev_charging_station_v2_enabled = station_v2_recipe and station_v2_recipe.enabled,
    ev_charging_station_v3_enabled = station_v3_recipe and station_v3_recipe.enabled,
    ev_charging_station_v4_enabled = station_v4_recipe and station_v4_recipe.enabled,
    first_sale_recipe_enabled = first_sale_recipe and first_sale_recipe.enabled,
    prototype_roadster_enabled = roadster_recipe and roadster_recipe.enabled,
    gigafactory_created = gigafactory ~= nil,
    gigafactory_recipe_enabled = gigafactory_item_recipe and gigafactory_item_recipe.enabled,
    gigafactory_module_recipe_enabled = gigafactory_module_recipe and gigafactory_module_recipe.enabled,
    premium_ev_recipe_enabled = premium_ev_recipe and premium_ev_recipe.enabled,
    gigacast_recipe_enabled = gigacast_recipe and gigacast_recipe.enabled,
    gigafactory_v2_created = gigafactory_v2 ~= nil,
    gigafactory_v2_recipe_enabled = gigafactory_v2_recipe and gigafactory_v2_recipe.enabled,
    mass_market_ev_recipe_enabled = mass_market_ev_recipe and mass_market_ev_recipe.enabled,
    solar_array_created = solar_array ~= nil,
    solar_array_recipe_enabled = solar_array_recipe and solar_array_recipe.enabled,
    megapack_created = find_unit(surface, MEGAPACK, storage.megapack_unit_number) ~= nil,
    megapack_recipe_enabled = megapack_recipe and megapack_recipe.enabled,
    sell_megapack_recipe_enabled = sell_megapack_recipe and sell_megapack_recipe.enabled,
    gigafactory_selected_recipe = selected_gigafactory_recipe and selected_gigafactory_recipe.name,
    gigafactory_v2_selected_recipe = selected_gigafactory_v2_recipe and selected_gigafactory_v2_recipe.name,
    gigafactory_v1_two_input_output = economics_output
      and (storage.gigafactory_economics_outputs or 0)
        + economics_output.get_item_count("x-premium-ev") or -1,
    gigafactory_modules_inserted = storage.gigafactory_modules_inserted,
    gigafactory_v2_modules_inserted = storage.gigafactory_v2_modules_inserted,
    final_productivity_modules_inserted = storage.final_productivity_modules_inserted,
    intermediate_productivity_modules_inserted = storage.intermediate_productivity_modules_inserted,
    reservation_office_selected_recipe = selected_reservation_office_recipe and selected_reservation_office_recipe.name,
    robotaxi_dollars_produced = robotaxi_output and robotaxi_output.get_item_count(DOLLAR) or 0,
    small_launch_enabled_by_robotaxi_sale = small_launch_technology and small_launch_technology.enabled,
    logistic_system_researched_by_gigafactory = logistic_system_technology and logistic_system_technology.researched,
    grid_connections = grid_connections,
    logistic_roboports = logistic_roboports,
    grid_connection_created = grid_connections > 0,
    power_sinks = power_sinks,
    v1_power_sinks_capped = power_sinks == 0,
    v2_power_sinks = v2_power_sinks,
    v2_power_sinks_created = v2_power_sinks == 2,
    roadster_created = roadster ~= nil,
    roadster_started_charged = storage.roadster_started_charged,
    roadster_batteries = roadster_batteries,
    roadster_battery_energy = roadster_battery_energy,
    roadster_electric_fuel = roadster_fuel,
    terrestrial_datacenter_created = datacenter ~= nil,
    terrestrial_datacenter_dollars_remaining = datacenter_input and datacenter_input.get_item_count(DOLLAR) or -1,
    terrestrial_datacenter_tokens = datacenter_output and datacenter_output.get_item_count("x-ai-token") or -1,
    terrestrial_datacenter_productivity_bonus = datacenter and datacenter.productivity_bonus or -1,
    terrestrial_datacenter_bonus_progress = datacenter and datacenter.bonus_progress or -1,
    terrestrial_ai_efficiency = ai_efficiency and ai_efficiency.terrestrial,
    event_unpowered_station_created = storage.event_unpowered_station_created,
    event_unpowered_station_survived = storage.event_unpowered_station_created and event_unpowered_station ~= nil,
    direct_unpowered_station_created = storage.direct_unpowered_station_created,
    direct_unpowered_station_survived = storage.direct_unpowered_station_created and direct_unpowered_station ~= nil,
    ev_charging_station_v3_created = station_v3 ~= nil,
    ev_charging_station_v3_unpowered_survived = station_v3 ~= nil,
    ev_charging_station_v4_created = station_v4 ~= nil,
    ev_charging_station_v4_unpowered_survived = station_v4 ~= nil,
    market = market,
    progress = progress,
    progression_integrity = progression_integrity,
    vehicle_ownership = vehicle_ownership,
    maximum_settlement_capacity = maximum_settlement_capacity,
    preproduction_market = storage.preproduction_market,
    biter_customer_mode = market and market.biter_customer_mode,
    customer_force_created = customer_force ~= nil,
    nearby_spawner_converted_to_customer = biter_spawner_customer,
    far_spawner_remained_enemy = far_biter_spawner_enemy,
    nearby_worm_remained_enemy = hostile_worm_enemy,
    legacy_customer_worm_reverted_to_enemy = legacy_customer_worm_enemy,
    commanded_biter_converted = storage.commanded_biter_converted,
    customer_attack_command_cleared = storage.customer_attack_command_cleared,
    customer_biter_wandered = vehicle_ownership and vehicle_ownership.wandering_owners == vehicle_ownership.active,
    customer_biter_wander_distance = commanded_biter_distance,
    outer_customer_biter_converted = storage.outer_customer_biter_converted
      and ((outer_customer_biter and outer_customer_biter.force.name == CUSTOMER_FORCE)
        or (vehicle_ownership and vehicle_ownership.active == 3)),
    v4_recipe_enabled_before_robotaxi_sale = storage.v4_recipe_enabled_before_robotaxi_sale,
    player_customer_friend = storage.player_customer_friend,
    customer_player_friend = storage.customer_player_friend,
    player_enemy_cease_fire = game.forces.player.get_cease_fire(game.forces.enemy),
    player_customer_cease_fire = customer_force and game.forces.player.get_cease_fire(customer_force),
    enemy_customer_cease_fire = customer_force and game.forces.enemy.get_cease_fire(customer_force),
    covered_biter_settlements = market and market.covered_biter_settlements,
    charger_reservations = reservations,
    charger_reservations_generated = reservations > 0,
    agi_training_unlocked = agi_training and agi_training.unlocked,
    agi_training_selected = controller and controller.get_recipe() and controller.get_recipe().name == AGI_RECIPE
  }
end)

script.on_nth_tick(18200, function()
  if game.tick < 18200 then return end
  local surface = game.get_surface(storage.surface_index or 1)
  local market = remote.call("factoryx", "refresh_biter_customer_market", "player")
  write_report{
    tick = game.tick,
    status = "customer_growth",
    market = market,
    spawner_growth = #surface.find_entities_filtered{type = "unit-spawner"} - (storage.initial_spawner_count or 0),
    worm_growth = #surface.find_entities_filtered{type = "turret", name = WORM} - (storage.initial_worm_count or 0)
  }
  local power_source = find_unit(surface, POWER_SOURCE, storage.power_source_unit_number)
  if power_source then
    power_source.power_production = 0
    power_source.output_flow_limit = 0
    power_source.energy = 0
  end
end)

script.on_nth_tick(18320, function()
  if game.tick < 18320 then return end
  write_report{
    tick = game.tick,
    status = "customer_overload",
    market = remote.call("factoryx", "refresh_biter_customer_market", "player"),
    sales_offices = remote.call("factoryx", "sales_office_status", "player")
  }
end)

script.on_nth_tick(18380, function()
  if game.tick < 18380 then return end
  local surface = game.get_surface(storage.surface_index or 1)
  local power_source = find_unit(surface, POWER_SOURCE, storage.power_source_unit_number)
  if power_source then
    power_source.power_production = 10000000
    power_source.output_flow_limit = 10000000
  end
end)

script.on_nth_tick(18500, function()
  if game.tick < 18500 then return end
  write_report{
    tick = game.tick,
    status = "customer_recovery",
    market = remote.call("factoryx", "refresh_biter_customer_market", "player")
  }
end)

script.on_nth_tick(8000, function()
  if game.tick < 8000 then return end
  write_report{
    tick = game.tick,
    status = "customer_commutes",
    commutes = remote.call("factoryx", "customer_charging_commutes", "player"),
    performance = remote.call("factoryx", "performance_status", "player")
  }
end)

script.on_nth_tick(18520, function()
  if game.tick < 18520 then return end
  local surface = game.get_surface(storage.surface_index or 1)
  local controller = surface and find_unit(surface, CONTROLLER, storage.controller_unit_number)
  local inventory = controller and controller.get_inventory(output_inventory_id())
  local inserted = inventory and inventory.insert{name = AGI_MODEL, count = 1} or 0
  storage.awaiting_victory = inserted == 1
end)
EOF_LUA

echo "Validation temp dir: $tmp"
python3 -m unittest tests.test_factoryx_mod
python3 - "$repo_root/mod/factoryx_0.1.0/data.lua" "$read_data" "$repo_root/mod/factoryx_0.1.0" <<'PY'
import re
import sys
from pathlib import Path

data_file = Path(sys.argv[1])
read_data = Path(sys.argv[2])
mod_dir = Path(sys.argv[3])
missing = []
for reference in sorted(set(re.findall(r'"(__[^"]+/graphics/[^"]+)"', data_file.read_text()))):
    actual = reference.replace("__base__", str(read_data / "base"))
    actual = actual.replace("__space-age__", str(read_data / "space-age"))
    actual = actual.replace("__factoryx__", str(mod_dir))
    if not Path(actual).exists():
        missing.append(reference)
if missing:
    raise SystemExit("missing graphics references:\n" + "\n".join(missing))
print("Graphics references OK.")
PY
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --dump-data >/tmp/factoryx-dump-data.log 2>&1
if grep -qE ' Error |Error while loading|Modifications: ' /tmp/factoryx-dump-data.log; then
  cat /tmp/factoryx-dump-data.log
  exit 1
fi
python3 - "$tmp/script-output/data-raw-dump.json" <<'PY'
import json
import math
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())

factoryx_badge = "__factoryx__/graphics/technology/factoryx-tech-badge.png"
factoryx_technologies = {
    name for name in data["technology"]
    if name.startswith("x-")
} | {"big-mining-drill", "foundry", "recycling", "tesla-weapons"}
for technology_name in factoryx_technologies:
    icon_paths = {layer.get("icon") for layer in data["technology"][technology_name].get("icons", [])}
    if factoryx_badge not in icon_paths:
        raise SystemExit(f"{technology_name} is missing the FactoryX technology badge: {sorted(str(p) for p in icon_paths)}")
print("FactoryX technology icon branding OK.")

rgb = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack"}
rgbpy = rgb | {"production-science-pack", "utility-science-pack"}
rgbpys = rgbpy | {"space-science-pack"}
planet_four = {
    "metallurgic-science-pack",
    "electromagnetic-science-pack",
    "agricultural-science-pack",
    "cryogenic-science-pack",
}
expected_research = {
    "x-sales-office": (75, 20, {"automation-science-pack", "logistic-science-pack", "chemical-science-pack"}),
    "x-premium-ev-program": (250, 30, rgb | {"x-dollar"}),
    "x-ev-charging-network": (300, 30, rgb | {"x-dollar"}),
    "x-energy-products": (500, 45, rgb | {"production-science-pack", "x-dollar"}),
    "x-capital-scaling": (1000, 60, rgbpy | {"x-dollar"}),
    "x-terrestrial-ai": (1000, 60, rgbpy | {"x-dollar"}),
    "x-autonomous-logistics": (1000, 60, rgbpy | {"x-ai-token", "x-dollar"}),
    "x-small-orbital-launch": (1000, 60, rgbpy | {"x-dollar"}),
    "x-reusable-launch": (1500, 60, rgbpys | {"x-dollar"}),
    "x-satellite-constellation": (2000, 60, rgbpys | {"x-dollar"}),
    "x-orbital-compute": (2000, 60, rgbpys | {"electromagnetic-science-pack", "x-ai-token", "x-dollar"}),
    "x-planetary-energy-grid": (2500, 60, rgbpys | planet_four | {"x-ai-token", "x-dollar"}),
}
for technology_name, (count, time, ingredients) in expected_research.items():
    unit = data["technology"][technology_name]["unit"]
    actual_ingredients = {ingredient[0] for ingredient in unit["ingredients"]}
    if unit["count"] != count or unit["time"] != time or actual_ingredients != ingredients:
        raise SystemExit(
            f"{technology_name} research mismatch: count={unit['count']} time={unit['time']} "
            f"ingredients={sorted(actual_ingredients)}"
        )

expected_terrestrial_recipes = {
    "electric-furnace": {"steel-plate": 10, "electronic-circuit": 10, "stone-brick": 10},
    "big-mining-drill": {"electric-mining-drill": 4, "engine-unit": 20, "electronic-circuit": 20},
    "foundry": {"electric-furnace": 25, "electronic-circuit": 50, "refined-concrete": 200},
    "recycler": {"steel-plate": 20, "iron-gear-wheel": 40, "electronic-circuit": 20, "concrete": 20},
    "teslagun": {"x-battery-pack": 4, "processing-unit": 10, "steel-plate": 20},
    "tesla-turret": {"teslagun": 1, "x-battery-pack": 10, "processing-unit": 20, "accumulator": 4},
    "tesla-ammo": {"x-battery-pack": 1, "advanced-circuit": 2, "copper-cable": 10},
}
for recipe_name, expected in expected_terrestrial_recipes.items():
    recipe = data["recipe"][recipe_name]
    actual = {row["name"]: row["amount"] for row in recipe["ingredients"]}
    if actual != expected or recipe.get("surface_conditions"):
        raise SystemExit(f"{recipe_name} terrestrial recipe mismatch: {recipe}")
for technology_name in ("x-industrial-supply-chain", "big-mining-drill", "foundry", "recycling"):
    packs = {row[0] for row in data["technology"][technology_name]["unit"]["ingredients"]}
    if packs != {"automation-science-pack", "logistic-science-pack"}:
        raise SystemExit(f"{technology_name} is not red-green terrestrial research: {packs}")
expected_branch_prerequisites = {
    "x-industrial-supply-chain": {"automation-2", "electric-mining-drill", "steel-processing"},
    "big-mining-drill": {"x-industrial-supply-chain", "engine"},
    "foundry": {"x-industrial-supply-chain", "concrete"},
    "recycling": {"x-industrial-supply-chain", "concrete"},
}
for technology_name, expected in expected_branch_prerequisites.items():
    actual = set(data["technology"][technology_name].get("prerequisites", []))
    if actual != expected:
        raise SystemExit(f"{technology_name} prerequisite mismatch: {sorted(actual)}")
tungsten_steel = data["technology"]["tungsten-steel"]
if set(tungsten_steel.get("prerequisites", [])) != {"planet-discovery-vulcanus"}:
    raise SystemExit(f"Tungsten steel leaked into terrestrial progression: {tungsten_steel}")
if tungsten_steel.get("research_trigger", {}).get("entities") != ["tungsten-ore"]:
    raise SystemExit(f"Tungsten steel is not triggered by mining tungsten ore: {tungsten_steel}")
holmium = data["technology"]["holmium-processing"]
if set(holmium.get("prerequisites", [])) != {"recycling", "planet-discovery-fulgora"}:
    raise SystemExit(f"Holmium processing leaked before Fulgora discovery: {holmium}")
foundry_unlocks = {
    effect["recipe"] for effect in data["technology"]["foundry"].get("effects", [])
    if effect.get("type") == "unlock-recipe"
}
if {"molten-iron-from-lava", "molten-copper-from-lava", "casting-low-density-structure"} & foundry_unlocks:
    raise SystemExit(f"Terrestrial Foundry exposes unavailable planetary recipes: {sorted(foundry_unlocks)}")
electric_furnace_owners = {
    technology_name for technology_name, technology in data["technology"].items()
    if any(
        effect.get("type") == "unlock-recipe" and effect.get("recipe") == "electric-furnace"
        for effect in technology.get("effects", [])
    )
}
if electric_furnace_owners != {"x-industrial-supply-chain"}:
    raise SystemExit(f"Electric Furnace technology ownership mismatch: {sorted(electric_furnace_owners)}")
calcite_control = data["planet"]["nauvis"]["map_gen_settings"]["autoplace_controls"].get("calcite")
if calcite_control != {"frequency": 0.5, "size": 0.7, "richness": 0.8}:
    raise SystemExit(f"Nauvis calcite autoplace mismatch: {calcite_control}")
if not data["resource"]["calcite"].get("autoplace", {}).get("probability_expression"):
    raise SystemExit("Calcite has no terrestrial autoplace probability expression")
print("FactoryX terrestrial industrial supply chain prototypes OK.")

ev_production_line = data["technology"]["x-premium-ev-program"]
ev_line_unlocks = {
    effect["recipe"] for effect in ev_production_line.get("effects", [])
    if effect.get("type") == "unlock-recipe"
}
energy_product_unlocks = {
    effect["recipe"] for effect in data["technology"]["x-energy-products"].get("effects", [])
    if effect.get("type") == "unlock-recipe"
}
for runtime_recipe in ("x-gigafactory-module", "x-gigafactory-building"):
    if runtime_recipe in ev_line_unlocks or runtime_recipe in energy_product_unlocks:
        raise SystemExit(f"{runtime_recipe} must be owned by the 100-Premium-EV runtime milestone")

sale_recipe_products = {
    "x-sell-prototype-roadster": "prototype-roadster.png",
    "x-sell-premium-ev": "premium-ev.png",
    "x-sell-mass-market-ev": "mass-market-ev.png",
    "x-sell-megapack": "megapack.png",
    "x-sell-small-launch": "small-launch-service.png",
    "x-sell-reusable-launch": "reusable-launch-service.png",
    "x-sell-robotaxi-fleet": "robotaxi-fleet.png",
}
for recipe_name, product_icon in sale_recipe_products.items():
    icon_paths = [layer["icon"] for layer in data["recipe"][recipe_name].get("icons", [])]
    if not any(path.endswith(product_icon) for path in icon_paths):
        raise SystemExit(f"{recipe_name} is missing its product icon: {icon_paths}")
    if not any(path.endswith("/coin.png") for path in icon_paths):
        raise SystemExit(f"{recipe_name} is missing its coin badge: {icon_paths}")
premium_sale = data["recipe"]["x-sell-premium-ev"]
mass_market_sale = data["recipe"]["x-sell-mass-market-ev"]
prototype_sale = data["recipe"]["x-sell-prototype-roadster"]
if prototype_sale["energy_required"] != 60 or prototype_sale["results"] != [{"type": "item", "name": "x-dollar", "amount": 2}]:
    raise SystemExit(f"Prototype Roadster sale balance mismatch: {prototype_sale}")
if premium_sale["energy_required"] != 30 or premium_sale["results"] != [{"type": "item", "name": "x-dollar", "amount": 1}]:
    raise SystemExit(f"Premium EV sale balance mismatch: {premium_sale}")
if mass_market_sale["energy_required"] != 5 or mass_market_sale["results"] != [{"type": "item", "name": "x-dollar", "amount": 1}]:
    raise SystemExit(f"Mass-market EV sale balance mismatch: {mass_market_sale}")
robotaxi_sale = data["recipe"]["x-sell-robotaxi-fleet"]
if robotaxi_sale["energy_required"] != 3 or robotaxi_sale["ingredients"] != [{"type": "item", "name": "x-robotaxi-fleet", "amount": 3}] or robotaxi_sale["results"] != [{"type": "item", "name": "x-dollar", "amount": 1}]:
    raise SystemExit(f"Robotaxi sale balance mismatch: {robotaxi_sale}")
print("FactoryX research balance and sale recipe icons OK.")

terrestrial_tech = data["technology"]["x-terrestrial-ai"]
if set(terrestrial_tech["prerequisites"]) != {"x-capital-scaling", "x-energy-products", "processing-unit"}:
    raise SystemExit(f"Terrestrial AI prerequisites mismatch: {terrestrial_tech['prerequisites']}")
autonomy_tech = data["technology"]["x-autonomous-logistics"]
autonomy_prerequisites = set(autonomy_tech["prerequisites"])
if "logistic-robotics" not in autonomy_prerequisites or "logistic-system" in autonomy_prerequisites:
    raise SystemExit(f"Autonomous Logistics must remain terrestrial: {sorted(autonomy_prerequisites)}")
small_launch_tech = data["technology"]["x-small-orbital-launch"]
if "x-autonomous-logistics" not in small_launch_tech["prerequisites"]:
    raise SystemExit("Small Orbital Launch must follow the terrestrial Robotaxi branch")
if small_launch_tech.get("enabled") is not False:
    raise SystemExit("Small Orbital Launch must remain disabled until the first Robotaxi Fleet sale")
if "x-satellite-constellation" not in data["technology"]["x-orbital-compute"]["prerequisites"]:
    raise SystemExit("Orbital Compute must require Satellite Constellation")
if "electromagnetic-science-pack" not in data["technology"]["x-orbital-compute"]["prerequisites"]:
    raise SystemExit("Orbital Compute must require electromagnetic science")
if any(
    "x-planetary-grid-segment" in data["lab"][lab_name]["inputs"]
    for lab_name in ("lab", "biolab")
):
    raise SystemExit("Planetary Grid Segments must remain physical infrastructure, not lab science")

token_recipe = data["recipe"]["x-terrestrial-ai-token"]
if token_recipe.get("ingredients") != [{"type": "item", "name": "x-dollar", "amount": 20}] or token_recipe["energy_required"] != 30:
    raise SystemExit(f"Terrestrial AI Token recipe mismatch: {token_recipe}")
token_results = token_recipe.get("results", [])
if not any(result.get("name") == "x-ai-token" and result.get("amount") == 20 for result in token_results):
    raise SystemExit(f"Terrestrial AI Token output mismatch: {token_results}")
if data["item"]["x-ai-token"]["stack_size"] != 1000000:
    raise SystemExit("AI Tokens must stack to 1,000,000")
if data["item"]["x-ai-token"].get("weight") != 1:
    raise SystemExit("one million AI Tokens must fit within a one-ton rocket payload")
for track in ("terrestrial", "orbital"):
    for level in range(1, 7):
        technology = data["technology"][f"x-{track}-ai-efficiency-{level}"]
        if technology.get("enabled") is not False:
            raise SystemExit(f"AI efficiency milestone must start runtime-gated: {track} {level}")
for base_name in (
    "small-biter", "medium-biter", "big-biter", "behemoth-biter",
    "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter",
):
    for class_name in ("roadster", "premium", "mass-market", "robotaxi"):
        if f"x-{base_name}-{class_name}" not in data["unit"]:
            raise SystemExit(f"missing baked customer vehicle unit: {base_name} {class_name}")
datacenter = data["assembling-machine"]["x-terrestrial-datacenter"]
if datacenter["energy_usage"] != "8MW" or "x-datacenter" not in datacenter["crafting_categories"]:
    raise SystemExit(f"Terrestrial Datacenter prototype mismatch: {datacenter}")
robotaxi_recipe = data["recipe"]["x-robotaxi-fleet"]
if robotaxi_recipe["categories"] != ["x-mass-vehicle-assembly"]:
    raise SystemExit(f"Robotaxi Fleet must be built in Gigafactory V2: {robotaxi_recipe['categories']}")
if "x-mass-vehicle-assembly" not in data["assembling-machine"]["x-gigafactory-v2"]["crafting_categories"]:
    raise SystemExit("Gigafactory V2 cannot build Robotaxi Fleets")
print("Terrestrial AI and Robotaxi engine prototypes OK.")

if "factoryx" in data.get("item-group", {}):
    raise SystemExit("FactoryX must use vanilla crafting tabs, not a separate item group")
expected_subgroup_groups = {
    "x-factoryx-infrastructure": "production",
    "x-factoryx-components": "intermediate-products",
    "x-factoryx-capital": "intermediate-products",
}
for subgroup, expected_group in expected_subgroup_groups.items():
    actual_group = data["item-subgroup"][subgroup]["group"]
    if actual_group != expected_group:
        raise SystemExit(f"{subgroup} group mismatch: {actual_group}")

expected_item_subgroups = {
    "x-prototype-roadster": "transport",
    "x-premium-ev": "transport",
    "x-high-density-solar-array": "energy",
    "x-reusable-booster": "space-related",
    "x-ai-token": "science-pack",
    "x-sales-office": "x-factoryx-infrastructure",
    "x-battery-pack": "x-factoryx-components",
    "x-dollar": "x-factoryx-capital",
    "x-ev-reservation": "raw-material",
}
for item_name, expected_subgroup in expected_item_subgroups.items():
    actual_subgroup = data["item"][item_name]["subgroup"]
    if actual_subgroup != expected_subgroup:
        raise SystemExit(f"{item_name} item subgroup mismatch: {actual_subgroup}")
if data["item"]["x-ev-reservation"].get("hidden", False):
    raise SystemExit("EV Reservation must remain visible in item-filter selectors")

expected_recipe_subgroups = {
    "x-prototype-roadster": "transport",
    "x-high-density-solar-array": "energy",
    "x-reusable-booster": "space-related",
    "x-terrestrial-ai-token": "science-pack",
    "x-sales-office": "x-factoryx-infrastructure",
    "x-battery-pack": "x-factoryx-components",
    "x-sell-prototype-roadster": "x-factoryx-capital",
}
for recipe_name, expected_subgroup in expected_recipe_subgroups.items():
    actual_subgroup = data["recipe"][recipe_name]["subgroup"]
    if actual_subgroup != expected_subgroup:
        raise SystemExit(f"{recipe_name} recipe subgroup mismatch: {actual_subgroup}")
print("FactoryX vanilla crafting-tab integration OK.")

factoryx_recipes = {
    name for name in data["recipe"]
    if name.startswith("x-") and not name.endswith("-recycling")
}
technology_unlocks = set()
for technology_name, technology in data["technology"].items():
    if not technology_name.startswith("x-"):
        continue
    for effect in technology.get("effects", []):
        if effect.get("type") == "unlock-recipe":
            technology_unlocks.add(effect["recipe"])
runtime_milestone_recipes = {
    "x-prototype-roadster",
    "x-ev-charging-station-v4",
    "x-gigafactory-module",
    "x-gigafactory-building",
    "x-agi-training-run",
}
missing_unlocks = factoryx_recipes - technology_unlocks - runtime_milestone_recipes
if missing_unlocks:
    raise SystemExit(f"FactoryX recipes without a progression owner: {sorted(missing_unlocks)}")

category_crafters = {}
for machine_name, machine in data["assembling-machine"].items():
    for category in machine.get("crafting_categories", []):
        category_crafters.setdefault(category, set()).add(machine_name)
uncraftable = {}
for recipe_name in sorted(factoryx_recipes):
    categories = data["recipe"][recipe_name].get("categories", ["crafting"])
    if not any(category_crafters.get(category) for category in categories):
        uncraftable[recipe_name] = categories
if uncraftable:
    raise SystemExit(f"FactoryX recipes without a compatible machine: {uncraftable}")
print("FactoryX progression ownership and machine compatibility OK.")

prototype = data["assembling-machine"]["x-gigafactory-v2"]
categories = set(prototype["crafting_categories"])
productivity = prototype["effect_receiver"]["base_effect"]["productivity"]
if prototype["energy_usage"] != "30MW":
    raise SystemExit(f"Gigafactory V2 engine power draw mismatch: {prototype['energy_usage']}")
if categories != {"advanced-crafting", "x-vehicle-assembly", "x-mass-vehicle-assembly", "x-energy-products", "x-vertical-integration"}:
    raise SystemExit(f"Gigafactory V2 engine categories mismatch: {sorted(categories)}")
if prototype["crafting_speed"] != 8:
    raise SystemExit(f"Gigafactory V2 engine crafting speed mismatch: {prototype['crafting_speed']}")
if productivity != 1.5:
    raise SystemExit(f"Gigafactory V2 engine productivity mismatch: {productivity}")
v1_prototype = data["assembling-machine"]["x-gigafactory-building"]
v1_productivity = v1_prototype["effect_receiver"]["base_effect"]["productivity"]
if v1_prototype["crafting_speed"] != 4:
    raise SystemExit(f"Gigafactory V1 engine crafting speed mismatch: {v1_prototype['crafting_speed']}")
if v1_productivity != 0.5:
    raise SystemExit(f"Gigafactory V1 engine productivity mismatch: {v1_productivity}")
if v1_prototype.get("fast_replaceable_group") != "x-gigafactory" or prototype.get("fast_replaceable_group") != "x-gigafactory":
    raise SystemExit("Gigafactory tiers do not share a fast-replace group")
if v1_prototype.get("next_upgrade") != "x-gigafactory-v2":
    raise SystemExit(f"Gigafactory V1 next upgrade mismatch: {v1_prototype.get('next_upgrade')}")
for gigafactory_name in ("x-gigafactory-building", "x-gigafactory-v2"):
    gigafactory_prototype = data["assembling-machine"][gigafactory_name]
    if gigafactory_prototype["module_slots"] != 8:
        raise SystemExit(f"{gigafactory_name} module slot mismatch: {gigafactory_prototype['module_slots']}")
    if "productivity" not in gigafactory_prototype["allowed_effects"]:
        raise SystemExit(f"{gigafactory_name} does not allow productivity modules")
    if "advanced-crafting" not in gigafactory_prototype["crafting_categories"]:
        raise SystemExit(f"{gigafactory_name} cannot manufacture Gigafactory recipes")
vertical_intermediates = {
    "copper-cable", "electronic-circuit", "advanced-circuit", "low-density-structure",
    "x-gigafactory-module", "x-gigacast", "x-battery-pack", "x-electric-drivetrain",
    "x-autonomy-computer", "x-datacenter-rack", "x-reusable-booster",
    "x-satellite-bus", "x-ground-station-network",
}
for recipe_name in vertical_intermediates:
    recipe = data["recipe"][recipe_name]
    if "x-vertical-integration" not in recipe["categories"] or recipe.get("allow_productivity") is not True:
        raise SystemExit(f"{recipe_name} is not a productive vertically integrated intermediate")
for recipe_name in ("x-premium-ev", "x-mass-market-ev", "x-high-density-solar-array", "x-megapack", "x-robotaxi-fleet"):
    if data["recipe"][recipe_name].get("allow_productivity") is not False:
        raise SystemExit(f"{recipe_name} incorrectly allows productivity modules")
print("Gigafactory economic ladder engine prototypes OK.")

chargers = {
    "V2": (
        data["logistic-container"]["x-ev-charging-station-v2"],
        data["electric-energy-interface"]["x-ev-charging-v2-power-sink"],
        [[-2, -2], [2, 2]],
        "150kW",
    ),
    "V3": (
        data["logistic-container"]["x-ev-charging-station-v3"],
        data["electric-energy-interface"]["x-ev-charging-v3-power-sink"],
        [[-2.5, -2.5], [2.5, 2.5]],
        "250kW",
    ),
    "V4": (
        data["logistic-container"]["x-ev-charging-station-v4"],
        data["electric-energy-interface"]["x-ev-charging-v4-power-sink"],
        [[-3, -3], [3, 3]],
        "500kW",
    ),
}
shortcut = data["shortcut"]["x-toggle-sales-office-coverage"]
progress_shortcut = data["shortcut"]["x-open-factoryx-progress"]
solar_array = data["solar-panel"]["x-high-density-solar-array"]
megapack = data["accumulator"]["x-megapack"]
assembling_machine_2 = data["assembling-machine"]["assembling-machine-2"]
prototype_roadster = data["recipe"]["x-prototype-roadster"]
for tier, (charger, sink, selection_box, stall_power) in chargers.items():
    if charger["selection_box"] != selection_box:
        raise SystemExit(f"EV Charging Station {tier} footprint mismatch: {charger['selection_box']}")
    if charger["inventory_size"] != 2 or charger["logistic_mode"] != "passive-provider" or charger.get("render_not_in_network_icon") is not False:
        raise SystemExit(f"EV Charging Station {tier} paperwork output mismatch: {charger}")
    if sink["energy_usage"] != stall_power or sink["energy_source"]["input_flow_limit"] != stall_power:
        raise SystemExit(f"EV Charging Station {tier} stall power mismatch: {sink}")
print("EV Charging Station V2/V3/V4 engine prototypes OK.")
if shortcut["action"] != "lua" or not shortcut["toggleable"] or shortcut["technology_to_unlock"] != "x-sales-office":
    raise SystemExit(f"Sales Office Coverage shortcut mismatch: {shortcut}")
print("Sales Office Coverage shortcut prototype OK.")
if progress_shortcut["action"] != "lua" or progress_shortcut.get("toggleable"):
    raise SystemExit(f"FactoryX Progress shortcut mismatch: {progress_shortcut}")
print("FactoryX Progress shortcut prototype OK.")
if solar_array["collision_box"] != [[-1.9, -1.9], [1.9, 1.9]] or solar_array["selection_box"] != [[-2, -2], [2, 2]]:
    raise SystemExit(f"High-density Solar Array 4x4 footprint mismatch: {solar_array}")
solar_layers = solar_array["picture"]["layers"]
solar_overlays = solar_array["overlay"]["layers"]
if len(solar_layers) != 8 or len(solar_overlays) != 4:
    raise SystemExit(f"High-density Solar Array should tile four panel sprites: picture={len(solar_layers)} overlay={len(solar_overlays)}")
expected_panel_scale = 1 / 3
if any(not math.isclose(layer.get("scale", 0), expected_panel_scale) for layer in solar_layers + solar_overlays):
    raise SystemExit(f"High-density Solar Array panel tiles are not scaled to 2x2: {solar_layers} {solar_overlays}")
panel_layers = [layer for layer in solar_layers if not layer.get("draw_as_shadow")]
panel_x = sorted({layer["shift"][0] for layer in panel_layers})
panel_y = sorted({layer["shift"][1] for layer in panel_layers})
if len(panel_x) != 2 or len(panel_y) != 2 or not math.isclose(panel_x[1] - panel_x[0], 2) or not math.isclose(panel_y[1] - panel_y[0], 2):
    raise SystemExit(f"High-density Solar Array panel centers do not tile edge-to-edge: {panel_layers}")
if solar_array["production"] != "300kW":
    raise SystemExit(f"High-density Solar Array native production mismatch: {solar_array['production']}")
energy = megapack["energy_source"]
if energy["buffer_capacity"] != "100MJ" or energy["input_flow_limit"] != "5MW" or energy["output_flow_limit"] != "5MW":
    raise SystemExit(f"Megapack energy source mismatch: {energy}")
print("Energy Products engine prototypes OK.")
if prototype_roadster["categories"] != ["advanced-crafting"]:
    raise SystemExit(f"Prototype Roadster recipe category mismatch: {prototype_roadster}")
if "advanced-crafting" not in assembling_machine_2["crafting_categories"]:
    raise SystemExit(f"Assembling Machine 2 cannot craft Prototype Roadsters: {assembling_machine_2['crafting_categories']}")
print("Prototype Roadster AM2 compatibility OK.")
for vehicle_name in (
    "x-prototype-roadster", "x-premium-ev", "x-mass-market-ev",
    "x-cybertruck", "x-robotaxi-fleet",
):
    vehicle = data["car"][vehicle_name]
    layers = vehicle["animation"]["layers"]
    layer = layers[0]
    expected_file = f"__factoryx__/graphics/entity/vehicles/{vehicle_name[2:]}.png"
    if layer.get("filename") != expected_file:
        raise SystemExit(f"{vehicle_name} custom vehicle sheet mismatch: {layer}")
    if layer.get("direction_count") != 64 or layer.get("line_length") != 8:
        raise SystemExit(f"{vehicle_name} direction layout mismatch: {layer}")
    expected_shadow = f"__factoryx__/graphics/entity/vehicles/{vehicle_name[2:]}-shadow.png"
    shadow_layers = [candidate for candidate in layers if candidate.get("draw_as_shadow")]
    if len(shadow_layers) != 1 or shadow_layers[0].get("filename") != expected_shadow:
        raise SystemExit(f"{vehicle_name} separate shadow layer mismatch: {layers}")
    if shadow_layers[0].get("direction_count") != 64 or shadow_layers[0].get("line_length") != 8:
        raise SystemExit(f"{vehicle_name} shadow direction layout mismatch: {shadow_layers[0]}")
    if vehicle.get("turret_animation") is not None or vehicle.get("light_animation") is not None:
        raise SystemExit(f"{vehicle_name} retained mismatched vanilla overlay art")
print("FactoryX custom vehicle engine sprites OK.")
PY
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --create "$save" >/tmp/factoryx-create.log 2>&1
if grep -qE ' errored when running|Error:|Error while loading|Modifications: ' /tmp/factoryx-create.log; then
  cat /tmp/factoryx-create.log
  exit 1
fi
if grep -qE "non-recoverable error|Error while running event" /tmp/factoryx-create.log; then
  tail -80 /tmp/factoryx-create.log >&2
  exit 1
fi
rm -f "$report"
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --benchmark "$save" --benchmark-ticks 18580 --benchmark-runs 1 >/tmp/factoryx-benchmark.log 2>&1
if grep -qE "non-recoverable error|Error while running event" /tmp/factoryx-benchmark.log; then
  tail -120 /tmp/factoryx-benchmark.log >&2
  exit 1
fi

python3 - "$report" <<'PY'
import json
import sys
from pathlib import Path

report = Path(sys.argv[1])
records = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
checked = next((record for record in records if record.get("status") == "checked"), None)
if checked is None:
    raise SystemExit("smoke report missing checked record")
victory = next((record for record in records if record.get("status") == "victory"), None)
growth = next((record for record in records if record.get("status") == "customer_growth"), None)
brownout = next((record for record in records if record.get("status") == "customer_brownout"), None)
overload = next((record for record in records if record.get("status") == "customer_overload"), None)
recovery = next((record for record in records if record.get("status") == "customer_recovery"), None)
compute_brownout = next((record for record in records if record.get("status") == "compute_brownout"), None)
commutes = next((record for record in records if record.get("status") == "customer_commutes"), None)
if compute_brownout is None or compute_brownout.get("progress_before", 0) <= 0:
    raise SystemExit(f"compute brownout test did not begin during an active run: {compute_brownout}")
if compute_brownout.get("progress_after") != 0:
    raise SystemExit(f"underpowered datacenter did not discard run progress: {compute_brownout}")
if commutes is None or commutes.get("commutes", {}).get("completed", 0) < 1:
    raise SystemExit(f"customer EV owners did not complete a physical charging commute: {commutes}")
performance = commutes.get("performance", {})
counters = performance.get("counters", {})
if performance.get("registered_sales_offices") != 3 or performance.get("registered_stations", 0) < 3:
    raise SystemExit(f"FactoryX entity registries missed smoke entities: {performance}")
if performance.get("registered_robotaxi_centers") != 1:
    raise SystemExit(f"Robotaxi Service Center registry missed smoke entity: {performance}")
if counters.get("market_snapshot_builds", 999999) > 200:
    raise SystemExit(f"market snapshots were rebuilt too often: {performance}")
if counters.get("robotaxi_allocation_builds", 999999) > 30:
    raise SystemExit(f"Robotaxi allocations were rebuilt too often: {performance}")
if performance.get("active_commutes", 999999) > 512:
    raise SystemExit(f"active commute cap was exceeded: {performance}")
if checked.get("vehicle_ownership", {}).get("registered_buyers", 0) <= 5:
    raise SystemExit(f"naturally spawned customer units were not registered: {checked}")
if checked.get("prospect_units", 0) <= 0:
    raise SystemExit(f"friendly unowned customers did not migrate to prospect prototypes: {checked}")
if not checked.get("event_unpowered_station_survived"):
    raise SystemExit(f"unpowered EV Charging Station placed by build event did not stay in place: {checked}")
if not checked.get("direct_unpowered_station_survived"):
    raise SystemExit(f"unpowered EV Charging Station placed without build event did not stay in place: {checked}")
if not checked.get("ev_charging_station_enabled"):
    raise SystemExit(f"EV Charging Station recipe was not enabled by Sales Office tech: {checked}")
if not checked.get("ev_charging_station_v2_created") or not checked.get("ev_charging_station_v2_enabled"):
    raise SystemExit(f"EV Charging Network did not unlock a placeable EV Charging Station V2: {checked}")
if not checked.get("first_sale_recipe_enabled"):
    raise SystemExit(f"Sell hopes and dreams was not enabled as the first Sales Office recipe: {checked}")
if not checked.get("prototype_roadster_enabled"):
    raise SystemExit(f"Prototype Roadster was not enabled by the first covered biter charging station: {checked}")
if not checked.get("gigafactory_created"):
    raise SystemExit(f"Gigafactory entity was not created: {checked}")
if not checked.get("gigafactory_recipe_enabled"):
    raise SystemExit(f"Energy Products did not unlock the Gigafactory recipe: {checked}")
if not checked.get("logistic_system_researched_by_gigafactory"):
    raise SystemExit(f"first Gigafactory placement did not research Logistic System: {checked}")
if not checked.get("gigafactory_module_recipe_enabled"):
    raise SystemExit(f"EV Production Line did not unlock Gigafactory Modules: {checked}")
if checked.get("premium_ev_recipe_enabled"):
    raise SystemExit(f"Premium EV recipe bypassed its 50-Roadster sales gate: {checked}")
if checked.get("gigafactory_selected_recipe") != "x-premium-ev":
    raise SystemExit(f"Gigafactory could not select the Premium EV recipe: {checked}")
if checked.get("gigafactory_v1_two_input_output") != 3:
    raise SystemExit(f"Gigafactory V1 did not turn two Premium EV input sets into three outputs: {checked}")
if not checked.get("gigacast_recipe_enabled"):
    raise SystemExit(f"Mass-market EV Production did not unlock Gigacast: {checked}")
if not checked.get("gigafactory_v2_created") or not checked.get("gigafactory_v2_recipe_enabled"):
    raise SystemExit(f"Mass-market EV Production did not unlock a placeable Gigafactory V2: {checked}")
if checked.get("mass_market_ev_recipe_enabled"):
    raise SystemExit(f"Mass-market EV recipe bypassed its 250-Premium sales gate: {checked}")
if checked.get("gigafactory_v2_selected_recipe") != "x-mass-market-ev":
    raise SystemExit(f"Gigafactory V2 could not select the Mass-market EV recipe: {checked}")
if checked.get("gigafactory_modules_inserted") != 8:
    raise SystemExit(f"Gigafactory did not accept eight modules: {checked}")
if checked.get("gigafactory_v2_modules_inserted") != 8:
    raise SystemExit(f"Gigafactory V2 did not accept eight speed modules: {checked}")
if checked.get("final_productivity_modules_inserted") != 0:
    raise SystemExit(f"Mass-market EV incorrectly accepted productivity modules: {checked}")
if checked.get("intermediate_productivity_modules_inserted") != 8:
    raise SystemExit(f"Battery Pack did not accept eight productivity modules: {checked}")
if checked.get("robotaxi_dollars_produced", 0) < 1:
    raise SystemExit(f"Robotaxi Fleet sale did not complete without an EV Reservation: {checked}")
if not checked.get("small_launch_enabled_by_robotaxi_sale"):
    raise SystemExit(f"first Robotaxi Fleet sale did not enable Small Orbital Launch: {checked}")
if not checked.get("solar_array_created") or not checked.get("solar_array_recipe_enabled"):
    raise SystemExit(f"Energy Products did not unlock a placeable High-density Solar Array: {checked}")
if not checked.get("megapack_created") or not checked.get("megapack_recipe_enabled"):
    raise SystemExit(f"Energy Products did not unlock a placeable Megapack: {checked}")
if not checked.get("sell_megapack_recipe_enabled"):
    raise SystemExit(f"Energy Products did not unlock Sell Megapack: {checked}")
if not checked.get("terrestrial_datacenter_created"):
    raise SystemExit(f"Terrestrial Datacenter was not created in smoke test: {checked}")
if checked.get("terrestrial_datacenter_tokens", 0) < 20:
    raise SystemExit(f"powered Terrestrial Datacenter did not produce efficiency-adjusted AI Tokens: {checked}")
if checked.get("terrestrial_datacenter_productivity_bonus") != 0:
    raise SystemExit(f"Terrestrial Datacenter unexpectedly accepted native productivity: {checked}")
if checked.get("terrestrial_datacenter_dollars_remaining", 100) > 80:
    raise SystemExit(f"Terrestrial Datacenter did not consume Dollars while operating: {checked}")
terrestrial_ai = checked.get("terrestrial_ai_efficiency") or {}
if terrestrial_ai.get("researched_level") != 5 or terrestrial_ai.get("tokens_per_cycle") != 30 or terrestrial_ai.get("next_threshold") != 100000000:
    raise SystemExit(f"Terrestrial AI efficiency status mismatch: {checked}")
if terrestrial_ai.get("generated", 0) < 20:
    raise SystemExit(f"Terrestrial AI production tracker did not observe completed cycles: {checked}")
if not checked.get("grid_connection_created"):
    raise SystemExit(f"EV Charging Station grid connection was not created: {checked}")
if not checked.get("v1_power_sinks_capped"):
    raise SystemExit(f"V1 charger should receive no utilization after the single produced EV is allocated to the earlier V2 charger: {checked}")
if not checked.get("v2_power_sinks_created"):
    raise SystemExit(f"EV Charging Station V2 should retain two customer sinks after the nearby Roadster finishes charging: {checked}")
if not checked.get("roadster_created") or checked.get("roadster_batteries") != 3:
    raise SystemExit(f"placed Roadster did not receive its three short-range battery equipment items: {checked}")
if not checked.get("roadster_started_charged"):
    raise SystemExit(f"FactoryX EVs should leave the factory with a full starter charge: {checked}")
if checked.get("roadster_battery_energy", 0) <= 0 or checked.get("roadster_electric_fuel", 0) != 1:
    raise SystemExit(f"powered V2 charger did not charge the Roadster and produce electric drive fuel: {checked}")
if not checked.get("ev_charging_station_v3_enabled"):
    raise SystemExit(f"Mass-market EV Production did not unlock the V3 Supercharger: {checked}")
if not checked.get("ev_charging_station_v4_enabled"):
    raise SystemExit(f"Autonomous Logistics did not unlock the V4 Supercharger: {checked}")
if not checked.get("ev_charging_station_v3_created") or not checked.get("ev_charging_station_v3_unpowered_survived"):
    raise SystemExit(f"V3 Supercharger did not survive unpowered placement: {checked}")
if not checked.get("ev_charging_station_v4_created") or not checked.get("ev_charging_station_v4_unpowered_survived"):
    raise SystemExit(f"V4 Supercharger did not survive unpowered placement: {checked}")
if not checked.get("biter_customer_mode"):
    raise SystemExit(f"biter customer mode was not enabled in smoke test: {checked}")
if not checked.get("customer_force_created"):
    raise SystemExit(f"customer force was not created: {checked}")
if not checked.get("nearby_spawner_converted_to_customer"):
    raise SystemExit(f"Sales Office-covered biter spawner was not converted to customer force: {checked}")
if not checked.get("far_spawner_remained_enemy"):
    raise SystemExit(f"far biter spawner should remain enemy force: {checked}")
if not checked.get("nearby_worm_remained_enemy"):
    raise SystemExit(f"Sales Office-covered worm should remain enemy force: {checked}")
if not checked.get("legacy_customer_worm_reverted_to_enemy"):
    raise SystemExit(f"previously converted worm should return to enemy force: {checked}")
if checked.get("player_enemy_cease_fire") is not False:
    raise SystemExit(f"player/enemy cease-fire should be disabled outside customer conversion: {checked}")
if checked.get("player_customer_cease_fire") is not True:
    raise SystemExit(f"player/customer cease-fire should be enabled: {checked}")
if checked.get("enemy_customer_cease_fire") is not True:
    raise SystemExit(f"enemy/customer cease-fire should be enabled so customer settlements are not erased: {checked}")
if not checked.get("commanded_biter_converted") or not checked.get("customer_attack_command_cleared"):
    raise SystemExit(f"customer biter retained an enemy attack command after conversion: {checked}")
if not checked.get("customer_biter_wandered"):
    raise SystemExit(f"baked vehicle-owner units did not retain non-combat wander commands: {checked}")
owner_entities = checked.get("vehicle_ownership", {}).get("by_entity_name", {})
if sum(owner_entities.values()) != 3 or not all(name.endswith("-robotaxi") for name in owner_entities):
    raise SystemExit(f"Robotaxi sale did not replace owners with baked Robotaxi variants: {checked}")
if not checked.get("outer_customer_biter_converted"):
    raise SystemExit(f"mobile unit beside a served outer spawner did not remain a customer: {checked}")
if checked.get("v4_recipe_enabled_before_robotaxi_sale") is not True:
    raise SystemExit(f"Autonomous Logistics should unlock the V4 Supercharger needed by the Robotaxi Service Center: {checked}")
if not checked.get("player_customer_friend") or not checked.get("customer_player_friend"):
    raise SystemExit(f"player and customer forces should be mutual friends: {checked}")
if checked.get("covered_biter_settlements", 0) < 1:
    raise SystemExit(f"biter customer settlement was not covered by charging network: {checked}")
preproduction_market = checked.get("preproduction_market", {})
if preproduction_market.get("customer_ev_fleet") != 0 or preproduction_market.get("active_customer_stalls") != 0:
    raise SystemExit(f"charging utilization should be zero before the first EV is produced: {checked}")
if checked.get("market", {}).get("customer_ev_fleet") != 3:
    raise SystemExit(f"expected three living Robotaxi owners in the active customer fleet: {checked}")
if checked.get("market", {}).get("active_customer_stalls") != 2:
    raise SystemExit(f"charging utilization must be capped by sold EVs and the two served settlements: {checked}")
progress = checked.get("progress", {})
if progress.get("stage") != "Prototype market validation" or progress.get("objective") != "Sell 50 Prototype Roadsters.":
    raise SystemExit(f"FactoryX progress status did not identify the next concrete objective: {checked}")
if progress.get("snapshot", {}).get("customer_ev_fleet") != 3:
    raise SystemExit(f"FactoryX progress snapshot did not expose live EV market state: {checked}")
integrity = checked.get("progression_integrity", {})
if not integrity.get("ok") or integrity.get("disabled_recipes"):
    raise SystemExit(f"FactoryX progression integrity check failed: {checked}")
if checked.get("market", {}).get("charging_stall_capacity") != 12:
    raise SystemExit(f"expected mixed V1/V2 charging capacity of 12 stalls: {checked}")
if checked.get("market", {}).get("supported_ev_capacity") != 40:
    raise SystemExit(f"expected two powered V2 stalls to support 40 active customer EVs: {checked}")
if checked.get("maximum_settlement_capacity", 0) <= 20:
    raise SystemExit(f"overlapping chargers did not add sale capacity at a settlement: {checked}")
if checked.get("market", {}).get("evs_per_stall") != 20:
    raise SystemExit(f"expected the active V2 stalls to support 20 EVs each: {checked}")
if brownout is None or brownout.get("market", {}).get("active_customer_stalls") != 1:
    raise SystemExit(f"50 percent charger power should proportionally leave one of two requested stalls powered: {brownout}")
if brownout.get("market", {}).get("stranded_evs", 0) < 1:
    raise SystemExit(f"brownout should strand the owners at one settlement despite spare aggregate EV capacity: {brownout}")
if brownout.get("market", {}).get("angry_settlements") != 0:
    raise SystemExit(f"customers should remain friendly during the three-minute service grace period: {brownout}")
if growth is None or growth.get("spawner_growth", 0) < 1:
    raise SystemExit(f"served charger did not grow a customer settlement: {growth}")
if growth.get("worm_growth", 0) not in (0, 1):
    raise SystemExit(f"one settlement growth event should create at most one hostile worm: {growth}")
if growth.get("market", {}).get("grown_colonies", 0) < 1:
    raise SystemExit(f"customer growth state did not report the grown colony: {growth}")
if overload is None or overload.get("market", {}).get("stranded_evs", 0) < 1:
    raise SystemExit(f"charging overload did not report stranded EVs: {overload}")
if overload.get("market", {}).get("angry_settlements") != 0:
    raise SystemExit(f"full outage should not immediately turn a customer settlement hostile: {overload}")
overload_offices = overload.get("sales_offices", [])
overload_settlements = [
    settlement
    for office in overload_offices
    for settlement in office.get("settlements", [])
]
if not any(settlement.get("underserved", 0) > 0 for settlement in overload_settlements):
    raise SystemExit(f"Sales Office status hid friendly underserved settlements: {overload}")
if not any(office.get("buyer_status", {}).get("friendly_settlements", 0) > 0 for office in overload_offices):
    raise SystemExit(f"charging overload became an immediate Sales Office hard stop: {overload}")
if recovery is None or recovery.get("market", {}).get("stranded_evs") != 0:
    raise SystemExit(f"restored charging capacity did not clear stranded EVs: {recovery}")
if recovery.get("market", {}).get("angry_settlements") != 0:
    raise SystemExit(f"restored charging capacity did not recover angry settlements: {recovery}")
if not checked.get("charger_reservations_generated"):
    raise SystemExit(f"EV reservations were not generated in the charger output: {checked}")
if checked.get("logistic_roboports") != 0:
    raise SystemExit(f"smoke test should prove charger output without a logistics network: {checked}")
if not checked.get("agi_training_unlocked") or not checked.get("agi_training_selected"):
    raise SystemExit(f"one-billion-token gate did not unlock/select AGI training: {checked}")
if victory is None or victory.get("agi_models") != 1:
    raise SystemExit(f"AGI Model should remain in controller output after victory: {victory}")
game_finished = victory.get("game_finished", {})
if not (game_finished.get("ok") and game_finished.get("value") is True):
    raise SystemExit(f"game.finished was not true: {victory}")
print("Smoke report OK:", json.dumps(checked, sort_keys=True))
PY

echo "FactoryX validation passed."
