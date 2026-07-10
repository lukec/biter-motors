local STATION_NAMES = {
  "x-ev-charging-station",
  "x-ev-charging-station-v2",
  "x-ev-charging-station-v3",
  "x-ev-charging-station-v4"
}
local STATION_CONFIGS = {
  ["x-ev-charging-station"] = {
    display_name = "EV Charging Station",
    stalls = 4,
    evs_per_stall = 12,
    power_per_stall_kw = 50,
    customer_radius = 64,
    vehicle_charge_radius = 8,
    power_sink_name = "x-ev-charging-power-sink"
  },
  ["x-ev-charging-station-v2"] = {
    display_name = "EV Charging Station V2",
    stalls = 8,
    evs_per_stall = 20,
    power_per_stall_kw = 150,
    customer_radius = 96,
    vehicle_charge_radius = 10,
    power_sink_name = "x-ev-charging-v2-power-sink"
  },
  ["x-ev-charging-station-v3"] = {
    display_name = "V3 Supercharger",
    stalls = 12,
    evs_per_stall = 32,
    power_per_stall_kw = 250,
    customer_radius = 128,
    vehicle_charge_radius = 12,
    power_sink_name = "x-ev-charging-v3-power-sink"
  },
  ["x-ev-charging-station-v4"] = {
    display_name = "V4 Supercharger",
    stalls = 20,
    evs_per_stall = 50,
    power_per_stall_kw = 500,
    customer_radius = 160,
    vehicle_charge_radius = 14,
    power_sink_name = "x-ev-charging-v4-power-sink"
  }
}
local STATION_GRID_CONNECTION_NAME = "x-ev-charging-grid-connection"
local SALES_OFFICE_COVERAGE_SHORTCUT = "x-toggle-sales-office-coverage"
local FACTORYX_PROGRESS_SHORTCUT = "x-open-factoryx-progress"
local SALES_OFFICE_NAME = "x-sales-office"
local LOGISTIC_SYSTEM_TECH_NAME = "logistic-system"
local GIGAFACTORY_ENTITY_NAMES = {
  ["x-gigafactory-building"] = true,
  ["x-gigafactory-v2"] = true
}
local GIGAFACTORY_CONFIGS = {
  ["x-gigafactory-building"] = {
    display_name = "Gigafactory",
    power = "20 MW",
    default_product = "Premium EV"
  },
  ["x-gigafactory-v2"] = {
    display_name = "Gigafactory V2",
    power = "30 MW",
    default_product = "Mass-market EV",
    productivity = "2x crafting speed; 150% built-in productivity"
  },
  ["x-terrestrial-datacenter"] = {
    display_name = "Terrestrial Datacenter",
    power = "8 MW",
    default_product = "AI Tokens",
    recipe_prompt = "Next: supply 20 Dollars per cycle and select terrestrial AI Token production. Each 30-second cycle also draws 8 MW."
  }
}
local HIGH_DENSITY_SOLAR_ARRAY_NAME = "x-high-density-solar-array"
local MEGAPACK_NAME = "x-megapack"
local TERRESTRIAL_DATACENTER_NAME = "x-terrestrial-datacenter"
ROBOTAXI_SERVICE_CENTER_NAME = "x-robotaxi-service-center"
ROBOTAXI_SERVICE_RECIPE = "x-operate-robotaxis"
ROBOTAXI_SERVICE_POWER_NAME = "x-robotaxi-service-power"
ROBOTAXI_ITEM_NAME = "x-robotaxi-fleet"
ROBOTAXI_SERVICE_RADIUS = 256
ROBOTAXI_CUSTOMERS_PER_VEHICLE = 5
ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 100
ROBOTAXI_ATTRITION_VEHICLE_HOURS = 60
local RESERVATION_NAME = "x-ev-reservation"
local CUSTOMER_FORCE_NAME = "factoryx-customers"
local GRID_CONTROLLER_NAME = "x-planetary-grid-controller"
local GRID_CHARGE_ITEM_NAME = "x-planetary-grid-charge"
local DOLLAR_NAME = "x-dollar"
local PROTOTYPE_ROADSTER_NAME = "x-prototype-roadster"
local PREMIUM_EV_NAME = "x-premium-ev"
local FIRST_PROTOTYPE_SALE_RECIPE = "x-sell-prototype-roadster"
local PREMIUM_EV_SALE_RECIPE = "x-sell-premium-ev"
local MASS_MARKET_EV_SALE_RECIPE = "x-sell-mass-market-ev"
CYBERTRUCK_SALE_RECIPE = "x-sell-cybertruck"
local ROBOTAXI_SALE_RECIPE = "x-sell-robotaxi-fleet"
CUSTOMER_EV_SALE_RECIPES = {
  [FIRST_PROTOTYPE_SALE_RECIPE] = {item = "x-prototype-roadster", vehicles = 1},
  [PREMIUM_EV_SALE_RECIPE] = {item = "x-premium-ev", vehicles = 1},
  [MASS_MARKET_EV_SALE_RECIPE] = {item = "x-mass-market-ev", vehicles = 1},
  [CYBERTRUCK_SALE_RECIPE] = {item = "x-cybertruck", vehicles = 1},
  [ROBOTAXI_SALE_RECIPE] = {item = "x-robotaxi-fleet", vehicles = 3}
}
local SMALL_ORBITAL_LAUNCH_TECH = "x-small-orbital-launch"
local RESERVATION_RECIPES = {
  ["x-sell-prototype-roadster"] = true,
  ["x-sell-premium-ev"] = true,
  ["x-sell-mass-market-ev"] = true
  ,["x-sell-cybertruck"] = true
}
local SALES_OFFICE_INITIAL_RECIPES = {
  "x-sales-office",
  "x-ev-charging-station",
  "x-sell-prototype-roadster"
}
local FIRST_CUSTOMER_CHARGER_UNLOCK_RECIPES = {
  "x-prototype-roadster"
}
local RESERVATION_BUFFER_LIMIT = 200
local RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE = 1
local RESERVATION_SAMPLES_PER_PRINT = 60
local CUSTOMER_GROWTH_STALL_MINUTES = 5
local CUSTOMER_GROWTH_PROGRESS_REQUIRED = CUSTOMER_GROWTH_STALL_MINUTES * 60
CUSTOMER_SERVICE_GRACE_TICKS = 3 * 60 * 60
CUSTOMER_MOOD_CHECK_TICKS = 60 * 60
CUSTOMER_MOOD_BASE_ANGER_CHANCE = 0.05
CUSTOMER_MOOD_MAX_ANGER_CHANCE = 0.25
AI_EFFICIENCY_THRESHOLDS = {1000, 10000, 100000, 1000000, 10000000, 100000000}
AI_EFFICIENCY_TRACKS = {
  terrestrial = {
    entity = "x-terrestrial-datacenter",
    recipe = "x-terrestrial-ai-token",
    technology_prefix = "x-terrestrial-ai-efficiency-",
    tokens_per_cycle = 20
  },
  orbital = {
    entity = "x-orbital-compute-array",
    recipe = "x-orbital-ai-token",
    technology_prefix = "x-orbital-ai-efficiency-",
    tokens_per_cycle = 40
  }
}
FACTORYX_START_TECHNOLOGIES = {
  "automation",
  "logistics",
  "electronics",
  "steel-processing",
  "automation-2",
  "logistic-science-pack",
  "electric-energy-distribution-1"
}
FACTORYX_START_SHIP_ITEMS = {
  ["steel-plate"] = 100,
  ["electronic-circuit"] = 100,
  ["iron-gear-wheel"] = 100,
  ["assembling-machine-1"] = 4,
  ["lab"] = 4
}
FACTORYX_START_DEBRIS_ITEMS = {
  ["iron-plate"] = 400,
  ["copper-plate"] = 200,
  ["stone"] = 200,
  ["coal"] = 200,
  ["transport-belt"] = 200,
  ["inserter"] = 30,
  ["electric-mining-drill"] = 10,
  ["stone-furnace"] = 12,
  ["small-electric-pole"] = 60,
  ["boiler"] = 2,
  ["steam-engine"] = 4,
  ["offshore-pump"] = 1,
  ["pipe"] = 50
}
local STATION_GRID_CONNECTION_DISTANCE = 18
local SALES_OFFICE_CUSTOMER_RADIUS = 128
local CUSTOMER_MOBILE_SERVICE_RADIUS = 48
local CUSTOMER_WANDER_RADIUS = 8
local ENEMY_RELEASE_WANDER_TICKS = 60
CUSTOMER_UNIT_COLOR = {r = 0.25, g = 0.95, b = 0.35, a = 1}
CUSTOMER_VEHICLE_CLASS_BY_ITEM = {
  ["x-prototype-roadster"] = "roadster",
  ["x-premium-ev"] = "premium",
  ["x-mass-market-ev"] = "mass-market",
  ["x-cybertruck"] = "cybertruck",
  ["x-robotaxi-fleet"] = "robotaxi"
}
ELECTRIC_VEHICLE_BATTERIES = {
  ["x-prototype-roadster"] = 2,
  ["x-premium-ev"] = 3,
  ["x-mass-market-ev"] = 2,
  ["x-cybertruck"] = 4,
  ["x-robotaxi-fleet"] = 3
}
ELECTRIC_DRIVE_FUEL_NAME = "x-electric-drive-charge"
ELECTRIC_DRIVE_FUEL_JOULES = 1000000
SUPERCHARGING_TECH_NAME = "x-supercharging-power-electronics"
LONG_RANGE_BATTERY_TECH_NAME = "x-long-range-battery"
PREMIUM_AUDIO_TECH_NAME = "x-premium-audio-systems"
CUSTOMER_REFERRAL_TECH_NAME = "x-customer-referral-program"
local BITER_SETTLEMENT_NAMES = {
  ["biter-spawner"] = true,
  ["spitter-spawner"] = true
}
local BITER_CUSTOMER_ENTITY_NAMES = {
  ["biter-spawner"] = true,
  ["spitter-spawner"] = true,
  ["small-biter"] = true,
  ["medium-biter"] = true,
  ["big-biter"] = true,
  ["behemoth-biter"] = true,
  ["small-spitter"] = true,
  ["medium-spitter"] = true,
  ["big-spitter"] = true,
  ["behemoth-spitter"] = true
}
CUSTOMER_UNIT_BASE_NAMES = {
  "small-biter", "medium-biter", "big-biter", "behemoth-biter",
  "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter"
}
CUSTOMER_UNIT_BASE_BY_NAME = {}
for _, base_name in pairs(CUSTOMER_UNIT_BASE_NAMES) do
  CUSTOMER_UNIT_BASE_BY_NAME[base_name] = base_name
  for _, class_name in pairs(CUSTOMER_VEHICLE_CLASS_BY_ITEM) do
    local variant_name = "x-" .. base_name .. "-" .. class_name
    CUSTOMER_UNIT_BASE_BY_NAME[variant_name] = base_name
    BITER_CUSTOMER_ENTITY_NAMES[variant_name] = true
  end
end
local HOSTILE_WORM_ENTITY_NAMES = {
  ["small-worm-turret"] = true,
  ["medium-worm-turret"] = true,
  ["big-worm-turret"] = true,
  ["behemoth-worm-turret"] = true
}
local STATION_INFO_PANEL_NAME = "factoryx_station_info_panel"
local ENTITY_INFO_PANEL_NAME = "factoryx_entity_info_panel"
local PROGRESS_PANEL_NAME = "factoryx_progress_panel"
local PROGRESS_CONTENT_NAME = "factoryx_progress_content"
local PROGRESS_CLOSE_BUTTON_NAME = "factoryx_progress_close"
local first_prototype_sale_unlocked
local find_sales_offices
local sync_customer_settlements
local customer_service_for_force

local function station_config(station)
  local base = station and STATION_CONFIGS[station.name]
  if not base then
    return nil
  end
  local quality_level = station.quality and station.quality.level or 0
  local battery_level = continuous_improvement_level(station.force, LONG_RANGE_BATTERY_TECH_NAME)
  if quality_level <= 0 and battery_level <= 0 then
    return base
  end
  local config = table.deepcopy(base)
  config.evs_per_stall = math.floor(
    base.evs_per_stall * (1 + quality_level * 0.1) * (1 + battery_level * 0.05) + 0.5
  )
  return config
end

local function is_station(entity)
  return entity and entity.valid and station_config(entity) ~= nil
end

local function station_reservation_inventory(station)
  if not is_station(station) then
    return nil
  end
  local inventory = station.get_inventory(defines.inventory.chest)
  if not inventory or not inventory.valid then
    return nil
  end
  if #inventory > 0 then
    pcall(function() inventory.set_filter(1, RESERVATION_NAME) end)
  end
  return inventory
end

local function find_stations(surface, force)
  return surface.find_entities_filtered{name = STATION_NAMES, force = force}
end

local function crafter_input_inventory_id()
  return defines.inventory.crafter_input or defines.inventory.assembling_machine_input
end

local function crafter_output_inventory_id()
  return defines.inventory.crafter_output or defines.inventory.assembling_machine_output
end

local function researched(force, technology_name)
  local technology = force and force.technologies and force.technologies[technology_name]
  return technology and technology.researched
end

function continuous_improvement_level(force, technology_name)
  local technology = force and force.technologies and force.technologies[technology_name]
  if not technology then
    return 0
  end
  return math.max(0, (technology.level or 1) - 1)
end

function continuous_improvement_levels(force)
  return {
    supercharging = continuous_improvement_level(force, SUPERCHARGING_TECH_NAME),
    battery = continuous_improvement_level(force, LONG_RANGE_BATTERY_TECH_NAME),
    audio = continuous_improvement_level(force, PREMIUM_AUDIO_TECH_NAME),
    referrals = continuous_improvement_level(force, CUSTOMER_REFERRAL_TECH_NAME)
  }
end

local function safe_products_finished(entity)
  local ok, products = pcall(function()
    return entity.products_finished
  end)
  if ok and products then
    return products
  end
  return 0
end

function ai_efficiency_progress()
  storage.factoryx_ai_efficiency_progress = storage.factoryx_ai_efficiency_progress or {}
  return storage.factoryx_ai_efficiency_progress
end

function researched_ai_efficiency_level(force, config)
  local level = 0
  for candidate = 1, #AI_EFFICIENCY_THRESHOLDS do
    local technology = force.technologies[config.technology_prefix .. candidate]
    if technology and technology.researched then
      level = candidate
    end
  end
  return level
end

function ai_efficiency_track_status(force, track_name)
  local config = AI_EFFICIENCY_TRACKS[track_name]
  if not force or not config then
    return nil
  end
  local force_progress = ai_efficiency_progress()[force.index] or {}
  local track = force_progress[track_name] or {generated = 0}
  local level = researched_ai_efficiency_level(force, config)
  return {
    generated = math.floor(track.generated or 0),
    researched_level = level,
    productivity_bonus = level * 0.1,
    tokens_per_cycle = config.tokens_per_cycle * (1 + level * 0.1),
    next_threshold = AI_EFFICIENCY_THRESHOLDS[level + 1],
    maximum_level = #AI_EFFICIENCY_THRESHOLDS
  }
end

function update_ai_efficiency_unlocks(force, track_name, track)
  local config = AI_EFFICIENCY_TRACKS[track_name]
  for level, threshold in pairs(AI_EFFICIENCY_THRESHOLDS) do
    local technology = force.technologies[config.technology_prefix .. level]
    if technology and not technology.researched then
      technology.enabled = track.generated >= threshold
    end
  end
end

function track_ai_efficiency_progress()
  local all_progress = ai_efficiency_progress()
  for _, force in pairs(game.forces) do
    if force.name ~= "enemy" and force.name ~= "neutral" and force.name ~= CUSTOMER_FORCE_NAME then
      all_progress[force.index] = all_progress[force.index] or {}
      for track_name, config in pairs(AI_EFFICIENCY_TRACKS) do
        local track = all_progress[force.index][track_name] or {
          generated = 0,
          machines = {},
          bonus_progress = {},
          pending_bonus = {}
        }
        all_progress[force.index][track_name] = track
        track.bonus_progress = track.bonus_progress or {}
        track.pending_bonus = track.pending_bonus or {}
        local seen = {}
        local level = researched_ai_efficiency_level(force, config)
        for _, surface in pairs(game.surfaces) do
          for _, machine in pairs(surface.find_entities_filtered{name = config.entity, force = force}) do
            if machine.valid and machine.unit_number then
              seen[machine.unit_number] = true
              local output_inventory = machine.get_inventory(
                defines.inventory.crafter_output or defines.inventory.assembling_machine_output
              )
              local pending_bonus = track.pending_bonus[machine.unit_number] or 0
              if output_inventory and pending_bonus > 0 then
                local inserted = output_inventory.insert{name = "x-ai-token", count = pending_bonus}
                track.pending_bonus[machine.unit_number] = pending_bonus - inserted
                track.pending_bonus_total = math.max(0, (track.pending_bonus_total or 0) - inserted)
                track.generated = track.generated + inserted
              end
              local finished = safe_products_finished(machine)
              local previous = track.machines[machine.unit_number]
              if previous ~= nil and finished > previous then
                local completed_cycles = finished - previous
                local bonus_progress = (track.bonus_progress[machine.unit_number] or 0)
                  + completed_cycles * level * 0.1
                local bonus_cycles = math.floor(bonus_progress + 0.000001)
                track.bonus_progress[machine.unit_number] = bonus_progress - bonus_cycles
                local bonus_tokens = bonus_cycles * config.tokens_per_cycle
                track.pending_bonus[machine.unit_number] =
                  (track.pending_bonus[machine.unit_number] or 0) + bonus_tokens
                track.pending_bonus_total = (track.pending_bonus_total or 0) + bonus_tokens
                track.generated = track.generated
                  + completed_cycles * config.tokens_per_cycle
              end
              track.machines[machine.unit_number] = finished
            end
          end
        end
        for unit_number in pairs(track.machines) do
          if not seen[unit_number] then
            track.machines[unit_number] = nil
            track.bonus_progress[unit_number] = nil
            track.pending_bonus[unit_number] = nil
          end
        end
        update_ai_efficiency_unlocks(force, track_name, track)
      end
    end
  end
end

function factoryx_accelerated_start_enabled()
  local setting = settings.startup["x-accelerated-start"]
  return setting and setting.value == true
end

function factoryx_copy_table(source)
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
end

function configure_factoryx_new_game()
  if not factoryx_accelerated_start_enabled() then
    return
  end
  local force = game.forces.player
  for _, technology_name in pairs(FACTORYX_START_TECHNOLOGIES) do
    local technology = force.technologies[technology_name]
    if technology then
      technology.researched = true
    end
  end
  if remote.interfaces.freeplay then
    remote.call("freeplay", "set_ship_items", factoryx_copy_table(FACTORYX_START_SHIP_ITEMS))
    remote.call("freeplay", "set_debris_items", factoryx_copy_table(FACTORYX_START_DEBRIS_ITEMS))
    remote.call("freeplay", "set_custom_intro_message", {
      "",
      "FACTORYX\n\n",
      "Your expedition survived atmospheric entry, but the industrial world you expected does not exist. Native settlements control the surrounding land. They can become customers, provided you build the energy, transportation, and manufacturing systems they need.\n\n",
      "Recover the supplies scattered through the wreckage. Rebuild electric industry, establish a Sales Office, and turn physical products into capital. Your long-term objective is to scale energy and computation far beyond one factory."
    })
  end
end

local function current_recipe_name(entity)
  local ok, recipe = pcall(function()
    return entity.get_recipe()
  end)
  if ok and recipe then
    return recipe.name
  end
  return nil
end

local function count_entities(force, entity_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    count = count + #surface.find_entities_filtered{name = entity_name, force = force}
  end
  return count
end

local function station_grid_connections()
  storage.factoryx_station_grid_connections = storage.factoryx_station_grid_connections or {}
  return storage.factoryx_station_grid_connections
end

local function station_power_sinks()
  storage.factoryx_station_power_sinks = storage.factoryx_station_power_sinks or {}
  return storage.factoryx_station_power_sinks
end

function electric_vehicle_registry()
  storage.factoryx_electric_vehicles = storage.factoryx_electric_vehicles or {}
  return storage.factoryx_electric_vehicles
end

function is_electric_vehicle(entity)
  return entity and entity.valid and ELECTRIC_VEHICLE_BATTERIES[entity.name] ~= nil
end

function electric_vehicle_battery_target(entity)
  local quality_level = entity.quality and entity.quality.level or 0
  return ELECTRIC_VEHICLE_BATTERIES[entity.name] + quality_level
end

function install_vehicle_batteries(entity)
  if not is_electric_vehicle(entity) or not entity.grid then
    return
  end
  local existing = 0
  for _, equipment in pairs(entity.grid.equipment) do
    if equipment.name == "battery-equipment" then
      existing = existing + 1
    end
  end
  local needed = electric_vehicle_battery_target(entity) - existing
  for y = 0, entity.grid.height - 2, 2 do
    for x = 0, entity.grid.width - 2, 2 do
      if needed <= 0 then
        return
      end
      local equipment = entity.grid.put{name = "battery-equipment", position = {x, y}}
      if equipment then
        needed = needed - 1
      end
    end
  end
end

function track_electric_vehicle(entity)
  if not is_electric_vehicle(entity) or not entity.unit_number then
    return
  end
  install_vehicle_batteries(entity)
  electric_vehicle_registry()[entity.unit_number] = entity
end

function rebuild_electric_vehicles()
  storage.factoryx_electric_vehicles = {}
  for _, surface in pairs(game.surfaces) do
    for vehicle_name in pairs(ELECTRIC_VEHICLE_BATTERIES) do
      for _, entity in pairs(surface.find_entities_filtered{name = vehicle_name}) do
        track_electric_vehicle(entity)
      end
    end
  end
end

function vehicle_battery_energy(entity)
  local energy = 0
  local capacity = 0
  if not is_electric_vehicle(entity) or not entity.grid then
    return energy, capacity
  end
  for _, equipment in pairs(entity.grid.equipment) do
    if equipment.type == "battery-equipment" then
      energy = energy + equipment.energy
      capacity = capacity + equipment.max_energy
    end
  end
  return energy, capacity
end

function vehicle_needs_charge(entity)
  local energy, capacity = vehicle_battery_energy(entity)
  return capacity > 0 and energy < capacity - 1000
end

function charge_vehicle(entity, joules)
  if not is_electric_vehicle(entity) or not entity.grid then
    return 0
  end
  local remaining = joules
  for _, equipment in pairs(entity.grid.equipment) do
    if equipment.type == "battery-equipment" and remaining > 0 then
      local added = math.min(remaining, equipment.max_energy - equipment.energy)
      equipment.energy = equipment.energy + added
      remaining = remaining - added
    end
  end
  return joules - remaining
end

function nearby_uncharged_vehicles(station, limit)
  local config = station_config(station)
  if not config then
    return {}
  end
  local vehicles = station.surface.find_entities_filtered{
    area = {
      {station.position.x - config.vehicle_charge_radius, station.position.y - config.vehicle_charge_radius},
      {station.position.x + config.vehicle_charge_radius, station.position.y + config.vehicle_charge_radius}
    },
    name = (function()
      local names = {}
      for name in pairs(ELECTRIC_VEHICLE_BATTERIES) do names[#names + 1] = name end
      return names
    end)(),
    force = station.force
  }
  local result = {}
  table.sort(vehicles, function(left, right)
    return (left.unit_number or 0) < (right.unit_number or 0)
  end)
  for _, vehicle in pairs(vehicles) do
    if vehicle_needs_charge(vehicle) then
      result[#result + 1] = vehicle
      if limit and #result >= limit then
        break
      end
    end
  end
  return result
end

function feed_electric_drive_from_batteries(entity)
  if not is_electric_vehicle(entity) or not entity.burner then
    return
  end
  local fuel_inventory = entity.burner.inventory
  if not fuel_inventory or not fuel_inventory.is_empty() then
    return
  end
  local battery_level = continuous_improvement_level(entity.force, LONG_RANGE_BATTERY_TECH_NAME)
  local required_energy = ELECTRIC_DRIVE_FUEL_JOULES * math.max(0.25, 1 - battery_level * 0.08)
  local energy = vehicle_battery_energy(entity)
  if energy < required_energy then
    return
  end
  local remaining = required_energy
  for _, equipment in pairs(entity.grid.equipment) do
    if equipment.type == "battery-equipment" and remaining > 0 then
      local removed = math.min(remaining, equipment.energy)
      equipment.energy = equipment.energy - removed
      remaining = remaining - removed
    end
  end
  if remaining == 0 then
    fuel_inventory.insert{name = ELECTRIC_DRIVE_FUEL_NAME, count = 1}
  end
end

function feed_tracked_electric_vehicles()
  for unit_number, entity in pairs(electric_vehicle_registry()) do
    if entity and entity.valid then
      feed_electric_drive_from_batteries(entity)
    else
      electric_vehicle_registry()[unit_number] = nil
    end
  end
end

local function customer_markers()
  storage.factoryx_customer_markers = storage.factoryx_customer_markers or {}
  return storage.factoryx_customer_markers
end

function customer_unit_registry()
  storage.factoryx_customer_units = storage.factoryx_customer_units or {}
  return storage.factoryx_customer_units
end

function customer_home_settlements()
  storage.factoryx_customer_home_settlements = storage.factoryx_customer_home_settlements or {}
  return storage.factoryx_customer_home_settlements
end

function customer_vehicle_owners()
  storage.factoryx_customer_vehicle_owners = storage.factoryx_customer_vehicle_owners or {}
  return storage.factoryx_customer_vehicle_owners
end

function office_buyer_reservations()
  storage.factoryx_office_buyer_reservations = storage.factoryx_office_buyer_reservations or {}
  return storage.factoryx_office_buyer_reservations
end

function buyer_reserved_by_unit()
  storage.factoryx_buyer_reserved_by_unit = storage.factoryx_buyer_reserved_by_unit or {}
  return storage.factoryx_buyer_reserved_by_unit
end

function station_power_service()
  storage.factoryx_station_power_service = storage.factoryx_station_power_service or {}
  return storage.factoryx_station_power_service
end

local function sales_office_coverage_enabled()
  storage.factoryx_sales_office_coverage_enabled = storage.factoryx_sales_office_coverage_enabled or {}
  return storage.factoryx_sales_office_coverage_enabled
end

local function sales_office_coverage_renderings()
  storage.factoryx_sales_office_coverage_renderings = storage.factoryx_sales_office_coverage_renderings or {}
  return storage.factoryx_sales_office_coverage_renderings
end

local function destroy_sales_office_coverage(player_index)
  local renderings = sales_office_coverage_renderings()
  for _, object in pairs(renderings[player_index] or {}) do
    if object and object.valid then
      object.destroy()
    end
  end
  renderings[player_index] = {}
end

local function refresh_sales_office_coverage(player)
  if not player or not player.valid then
    return
  end

  destroy_sales_office_coverage(player.index)
  local enabled = sales_office_coverage_enabled()[player.index] == true
  player.set_shortcut_toggled(SALES_OFFICE_COVERAGE_SHORTCUT, enabled)
  if not enabled then
    return
  end

  local objects = sales_office_coverage_renderings()[player.index]
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME, force = player.force}) do
      objects[#objects + 1] = rendering.draw_circle{
        color = {r = 0.03, g = 0.16, b = 0.18, a = 0.18},
        radius = SALES_OFFICE_CUSTOMER_RADIUS,
        width = 1,
        filled = true,
        target = office,
        surface = surface,
        players = {player},
        render_mode = "chart"
      }
      objects[#objects + 1] = rendering.draw_circle{
        color = {r = 0.18, g = 0.62, b = 0.58, a = 0.72},
        radius = SALES_OFFICE_CUSTOMER_RADIUS,
        width = 4,
        filled = false,
        target = office,
        surface = surface,
        players = {player},
        render_mode = "chart"
      }
    end
  end
end

local function refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    refresh_sales_office_coverage(player)
  end
  storage.factoryx_sales_office_coverage_dirty = false
end

local function mark_sales_office_coverage_dirty()
  storage.factoryx_sales_office_coverage_dirty = true
end

local function player_market_force(force)
  return force
    and force.valid
    and force.name ~= "enemy"
    and force.name ~= "neutral"
    and force.name ~= CUSTOMER_FORCE_NAME
end

local function customer_force_if_exists()
  return game.forces[CUSTOMER_FORCE_NAME]
end

local function customer_force()
  local force = customer_force_if_exists()
  if not force then
    force = game.create_force(CUSTOMER_FORCE_NAME)
  end
  return force
end

local function is_biter_customer_entity(entity)
  return entity and entity.valid and BITER_CUSTOMER_ENTITY_NAMES[entity.name]
end

local function is_hostile_worm_entity(entity)
  return entity and entity.valid and HOSTILE_WORM_ENTITY_NAMES[entity.name]
end

local function nearby_real_power_pole(station)
  local position = station.position
  local radius = STATION_GRID_CONNECTION_DISTANCE
  local area = {
    {position.x - radius, position.y - radius},
    {position.x + radius, position.y + radius}
  }

  for _, pole in pairs(station.surface.find_entities_filtered{type = "electric-pole", force = station.force, area = area}) do
    if pole.valid and pole.name ~= STATION_GRID_CONNECTION_NAME then
      local dx = pole.position.x - position.x
      local dy = pole.position.y - position.y
      if dx * dx + dy * dy <= radius * radius then
        return pole
      end
    end
  end
  return nil
end

local function station_has_grid_access(station)
  return station and station.valid and nearby_real_power_pole(station) ~= nil
end

local function ensure_station_grid_connection(station)
  if not station or not station.valid or not station.unit_number then
    return nil
  end
  if not station_has_grid_access(station) then
    return nil
  end

  local connections = station_grid_connections()
  local existing = connections[station.unit_number]
  if existing and existing.valid then
    return existing
  end

  local connector = station.surface.create_entity{
    name = STATION_GRID_CONNECTION_NAME,
    position = station.position,
    force = station.force
  }
  connections[station.unit_number] = connector
  return connector
end

local function destroy_power_sink(sink)
  if sink and sink.valid then
    sink.destroy()
  end
end

function station_stall_power_watts(station)
  local config = station_config(station)
  if not config then
    return 0
  end
  local level = continuous_improvement_level(station.force, SUPERCHARGING_TECH_NAME)
  return config.power_per_stall_kw * 1000 * (1 + level * 0.1)
end

function configure_station_power_sink(station, sink)
  if not sink or not sink.valid then
    return
  end
  local watts = station_stall_power_watts(station)
  sink.power_usage = watts
  sink.input_flow_limit = watts / 60
  sink.electric_buffer_size = watts
end

local function normalize_station_power_sinks(station)
  if not station or not station.valid or not station.unit_number then
    return nil
  end

  local sinks = station_power_sinks()
  local existing = sinks[station.unit_number]
  if existing and existing.valid ~= nil then
    if existing.valid then
      sinks[station.unit_number] = {existing}
    else
      sinks[station.unit_number] = {}
    end
  elseif not existing then
    sinks[station.unit_number] = {}
  end

  return sinks[station.unit_number]
end

local function ensure_station_power_sinks(station, active_stalls)
  local station_sinks = normalize_station_power_sinks(station)
  if not station_sinks then
    return nil
  end

  local config = station_config(station)
  if not config then
    return nil
  end
  local stalls = math.max(0, math.min(config.stalls, math.floor(active_stalls or 0)))
  local power_state = station_power_service()[station.unit_number] or {power_fraction = 1}
  power_state.requested_stalls = stalls
  station_power_service()[station.unit_number] = power_state
  for stall = 1, config.stalls do
    local existing = station_sinks[stall]
    if stall <= stalls then
      if not existing or not existing.valid then
        station_sinks[stall] = station.surface.create_entity{
          name = config.power_sink_name,
          position = station.position,
          force = station.force
        }
      end
      configure_station_power_sink(station, station_sinks[stall])
    else
      destroy_power_sink(existing)
      station_sinks[stall] = nil
    end
  end

  return station_sinks
end

function sample_station_power_service(station)
  local config = station_config(station)
  if not config or not station.unit_number then
    return 0
  end
  local state = station_power_service()[station.unit_number] or {}
  local requested = math.max(0, math.min(config.stalls, state.requested_stalls or 0))
  if requested == 0 then
    state.power_fraction = 1
    state.powered_stalls = 0
  elseif not station_has_grid_access(station) then
    state.power_fraction = 0
    state.powered_stalls = 0
  else
    local sinks = normalize_station_power_sinks(station) or {}
    local fraction
    for stall = 1, requested do
      local sink = sinks[stall]
      local sub_network = sink and sink.valid and sink.electric_network
      local network = sub_network and sub_network.parent_network
      local flow = network and network.flow_last_tick
      if flow then
        fraction = math.min(1, math.max(0, flow.secondary_demand_usage or 0))
        break
      end
    end
    fraction = fraction or 0
    state.power_fraction = fraction
    state.powered_stalls = fraction >= 0.95
      and requested
      or math.max(0, math.min(requested, math.floor(requested * fraction + 0.05)))
  end
  state.last_sample_tick = game.tick
  station_power_service()[station.unit_number] = state
  return state.powered_stalls
end

function powered_station_stalls(station, requested)
  if not station or not station.valid or not station.unit_number or not station_has_grid_access(station) then
    return 0
  end
  local state = station_power_service()[station.unit_number]
  if not state or not state.last_sample_tick then
    return requested or 0
  end
  return math.min(requested or state.requested_stalls or 0, state.powered_stalls or 0)
end

local function remove_station_grid_connection(station)
  if not station or not station.unit_number then
    return
  end

  local connections = station_grid_connections()
  local connector = connections[station.unit_number]
  if connector and connector.valid then
    connector.destroy()
  end
  connections[station.unit_number] = nil
end

local function remove_station_power_sink(station)
  if not station or not station.unit_number then
    return
  end

  local sinks = station_power_sinks()
  local station_sinks = sinks[station.unit_number]
  if station_sinks then
    if station_sinks.valid ~= nil then
      destroy_power_sink(station_sinks)
    else
      for _, sink in pairs(station_sinks) do
        destroy_power_sink(sink)
      end
    end
  end
  sinks[station.unit_number] = nil
  station_power_service()[station.unit_number] = nil
end

local function remove_station_support_entities(station)
  remove_station_grid_connection(station)
  remove_station_power_sink(station)
end

local function count_powered_stations(force)
  local count = 0
  local capacity = 0
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      if station.valid and station_has_grid_access(station) then
        ensure_station_grid_connection(station)
        count = count + 1
        capacity = capacity + station_config(station).stalls
      else
        remove_station_grid_connection(station)
        remove_station_power_sink(station)
      end
    end
  end
  return count, capacity
end

local function biter_customer_mode_enabled()
  return true
end

local function area_around(position, radius)
  return {
    {position.x - radius, position.y - radius},
    {position.x + radius, position.y + radius}
  }
end

local function within_radius(source, target, radius)
  local dx = target.position.x - source.position.x
  local dy = target.position.y - source.position.y
  return dx * dx + dy * dy <= radius * radius
end

local function settlement_key(surface, settlement)
  if settlement.unit_number then
    return surface.index .. ":" .. settlement.unit_number
  end
  return string.format(
    "%d:%s:%.1f:%.1f",
    surface.index,
    settlement.name,
    settlement.position.x,
    settlement.position.y
  )
end

function register_customer_unit(entity, settlement, market_force)
  if not entity or not entity.valid or entity.type ~= "unit" or not entity.unit_number then
    return
  end
  customer_unit_registry()[entity.unit_number] = entity
  customer_home_settlements()[entity.unit_number] = {
    settlement_key = settlement_key(settlement.surface, settlement),
    market_force_name = market_force.name
  }
end

function unregister_customer_unit(entity)
  if not entity or not entity.unit_number then
    return nil
  end
  local unit_number = entity.unit_number
  local ownership = customer_vehicle_owners()[unit_number]
  customer_vehicle_owners()[unit_number] = nil
  customer_unit_registry()[unit_number] = nil
  customer_home_settlements()[unit_number] = nil
  buyer_reserved_by_unit()[unit_number] = nil
  return ownership
end

function active_customer_vehicle_summary(force)
  local summary = {total = 0, by_vehicle = {}, by_settlement = {}}
  local owners = customer_vehicle_owners()
  local units = customer_unit_registry()
  for unit_number, ownership in pairs(owners) do
    local entity = units[unit_number]
    if not entity or not entity.valid then
      owners[unit_number] = nil
      units[unit_number] = nil
      customer_home_settlements()[unit_number] = nil
      buyer_reserved_by_unit()[unit_number] = nil
    elseif ownership.market_force_name == force.name then
      summary.total = summary.total + 1
      summary.by_vehicle[ownership.vehicle] = (summary.by_vehicle[ownership.vehicle] or 0) + 1
      summary.by_settlement[ownership.settlement_key] = (summary.by_settlement[ownership.settlement_key] or 0) + 1
    end
  end
  return summary
end

function settlement_vehicle_count(vehicle_summary, settlement)
  return vehicle_summary.by_settlement[settlement_key(settlement.surface, settlement)] or 0
end

local function for_each_biter_customer_settlement(surface, force, area, callback)
  if not force then
    return
  end

  for _, settlement in pairs(surface.find_entities_filtered{type = "unit-spawner", force = force, area = area}) do
    if settlement.valid and BITER_SETTLEMENT_NAMES[settlement.name] then
      callback(settlement)
    end
  end
end

local function count_biter_settlements_near_station(station)
  if not biter_customer_mode_enabled() then
    return 0
  end

  local customers = customer_force_if_exists()
  if not customers or not station or not station.valid or not station_has_grid_access(station) then
    return 0
  end

  local covered = {}
  local count = 0
  local radius = station_config(station).customer_radius
  local area = area_around(station.position, radius)
  for_each_biter_customer_settlement(station.surface, customers, area, function(settlement)
    if within_radius(station, settlement, radius) then
      local key = settlement_key(station.surface, settlement)
      if not covered[key] then
        covered[key] = true
        count = count + 1
      end
    end
  end)
  return count
end

local function count_hostile_biter_settlements_near_station(station)
  local enemy = game.forces.enemy
  if not enemy or not station or not station.valid then
    return 0
  end

  local covered = {}
  local count = 0
  local radius = station_config(station).customer_radius
  local area = area_around(station.position, radius)
  for_each_biter_customer_settlement(station.surface, enemy, area, function(settlement)
    if within_radius(station, settlement, radius) then
      local key = settlement_key(station.surface, settlement)
      if not covered[key] then
        covered[key] = true
        count = count + 1
      end
    end
  end)
  return count
end

local function count_covered_biter_settlements(force)
  if not biter_customer_mode_enabled() then
    return 0
  end

  local customers = customer_force_if_exists()
  if not customers then
    return 0
  end

  local covered = {}
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      if station.valid and station_has_grid_access(station) then
        ensure_station_grid_connection(station)
        local radius = station_config(station).customer_radius
        local area = area_around(station.position, radius)
        for_each_biter_customer_settlement(surface, customers, area, function(settlement)
          if within_radius(station, settlement, radius) then
            local key = settlement_key(surface, settlement)
            if not covered[key] then
              covered[key] = true
              count = count + 1
            end
          end
        end)
      end
    end
  end
  return count
end

local function customer_ev_sales_by_force()
  storage.factoryx_customer_ev_sales = storage.factoryx_customer_ev_sales or {}
  return storage.factoryx_customer_ev_sales
end

local function historical_customer_ev_sales(force)
  local totals = {
    ["x-prototype-roadster"] = 0,
    ["x-premium-ev"] = 0,
    ["x-mass-market-ev"] = 0,
    ["x-cybertruck"] = 0,
    ["x-robotaxi-fleet"] = 0
  }
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_item_production_statistics(surface)
    totals["x-prototype-roadster"] = totals["x-prototype-roadster"]
      + (statistics.get_input_count("x-prototype-roadster") or 0)
    totals["x-premium-ev"] = totals["x-premium-ev"]
      + (statistics.get_input_count("x-premium-ev") or 0)
    local mass_market_inputs = statistics.get_input_count("x-mass-market-ev") or 0
    local robotaxi_manufacturing_inputs = statistics.get_input_count("x-autonomy-computer") or 0
    totals["x-mass-market-ev"] = totals["x-mass-market-ev"]
      + math.max(0, mass_market_inputs - robotaxi_manufacturing_inputs)
    totals["x-cybertruck"] = totals["x-cybertruck"]
      + (statistics.get_input_count("x-cybertruck") or 0)
    totals["x-robotaxi-fleet"] = totals["x-robotaxi-fleet"]
      + (statistics.get_input_count("x-robotaxi-fleet") or 0)
  end
  return totals
end

local function sold_customer_evs(force)
  if not force or not force.valid then
    return {}
  end
  local sales = customer_ev_sales_by_force()
  if not sales[force.name] then
    sales[force.name] = historical_customer_ev_sales(force)
  end
  return sales[force.name]
end

local function record_customer_ev_sales(force, recipe_name, completed_crafts)
  local sale = CUSTOMER_EV_SALE_RECIPES[recipe_name]
  if not sale or completed_crafts <= 0 then
    return 0
  end
  local totals = sold_customer_evs(force)
  local vehicles = completed_crafts * sale.vehicles
  totals[sale.item] = (totals[sale.item] or 0) + vehicles
  return vehicles
end

function lifetime_customer_ev_sales_size(force)
  local tracked = sold_customer_evs(force)
  local historical = historical_customer_ev_sales(force)
  local total = 0
  for item_name, count in pairs(historical) do
    tracked[item_name] = math.max(tracked[item_name] or 0, count)
  end
  for _, count in pairs(tracked) do
    total = total + count
  end
  return math.max(0, math.floor(total))
end

function customer_ev_fleet_size(force)
  return active_customer_vehicle_summary(force).total
end

local function entity_sort_key(entity)
  return entity and entity.unit_number or 0
end

local function sorted_entities(entities)
  table.sort(entities, function(left, right)
    if left.surface.index ~= right.surface.index then
      return left.surface.index < right.surface.index
    end
    return entity_sort_key(left) < entity_sort_key(right)
  end)
  return entities
end

local function force_sales_offices(force)
  local offices = {}
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME, force = force}) do
      if office.valid then
        offices[#offices + 1] = office
      end
    end
  end
  return sorted_entities(offices)
end

local function position_has_sales_coverage(surface, position, offices)
  for _, office in pairs(offices) do
    if office.valid and office.surface == surface then
      local dx = position.x - office.position.x
      local dy = position.y - office.position.y
      if dx * dx + dy * dy <= SALES_OFFICE_CUSTOMER_RADIUS * SALES_OFFICE_CUSTOMER_RADIUS then
        return true
      end
    end
  end
  return false
end

local function office_covered_settlements(offices)
  local enemy = game.forces.enemy
  local customers = customer_force()
  local settlements_by_key = {}
  for _, office in pairs(offices) do
    local area = area_around(office.position, SALES_OFFICE_CUSTOMER_RADIUS)
    for _, source_force in pairs({enemy, customers}) do
      for_each_biter_customer_settlement(office.surface, source_force, area, function(settlement)
        if within_radius(office, settlement, SALES_OFFICE_CUSTOMER_RADIUS) then
          settlements_by_key[settlement_key(office.surface, settlement)] = settlement
        end
      end)
    end
  end

  local settlements = {}
  for _, settlement in pairs(settlements_by_key) do
    settlements[#settlements + 1] = settlement
  end
  return sorted_entities(settlements)
end

function customer_settlement_moods(force)
  storage.factoryx_customer_settlement_moods = storage.factoryx_customer_settlement_moods or {}
  storage.factoryx_customer_settlement_moods[force.index] = storage.factoryx_customer_settlement_moods[force.index] or {}
  return storage.factoryx_customer_settlement_moods[force.index]
end

function customer_mood_random()
  local generator = storage.factoryx_customer_mood_random
  if not generator or not generator.valid then
    generator = game.create_random_generator()
    storage.factoryx_customer_mood_random = generator
  end
  return generator
end

function settlement_friendly_after_service_check(force, key, operational, advance_mood)
  local moods = customer_settlement_moods(force)
  local state = moods[key] or {was_customer = false, angry = false}
  moods[key] = state
  if operational then
    state.was_customer = true
    state.angry = false
    state.deficit_since = nil
    state.next_check_tick = nil
    return true, false
  end
  if not state.was_customer then
    return false, false
  end
  state.deficit_since = state.deficit_since or game.tick
  state.next_check_tick = state.next_check_tick
    or (state.deficit_since + CUSTOMER_SERVICE_GRACE_TICKS)
  if not state.angry and advance_mood and game.tick >= state.next_check_tick then
    local checks_after_grace = math.max(0, math.floor(
      (game.tick - state.deficit_since - CUSTOMER_SERVICE_GRACE_TICKS) / CUSTOMER_MOOD_CHECK_TICKS
    ))
    local chance = math.min(
      CUSTOMER_MOOD_MAX_ANGER_CHANCE,
      CUSTOMER_MOOD_BASE_ANGER_CHANCE * (checks_after_grace + 1)
    )
    local random = customer_mood_random()
    if random() < chance then
      state.angry = true
    end
    state.next_check_tick = game.tick + CUSTOMER_MOOD_CHECK_TICKS
  end
  return not state.angry, state.angry
end

customer_service_for_force = function(force, advance_mood)
  local service = {
    assignments = {},
    assignment_by_settlement_key = {},
    operational_keys = {},
    served_keys = {},
    served_settlements = {},
    angry_keys = {},
    accessible_stall_capacity = 0,
    powered_stall_capacity = 0,
    supported_ev_capacity = 0,
    average_evs_per_stall = 0,
    stranded_evs = 0
  }
  if not player_market_force(force) then
    return service
  end

  local offices = force_sales_offices(force)
  local candidates = office_covered_settlements(offices)
  service.candidate_settlements = candidates
  local vehicle_summary = active_customer_vehicle_summary(force)
  local assigned = {}
  local stations = {}
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      if station.valid and station_has_grid_access(station)
        and position_has_sales_coverage(surface, station.position, offices) then
        stations[#stations + 1] = station
      end
    end
  end
  sorted_entities(stations)

  for _, station in pairs(stations) do
    local config = station_config(station)
    local station_candidates = {}
    for _, settlement in pairs(candidates) do
      if settlement.valid and settlement.surface == station.surface
        and within_radius(station, settlement, config.customer_radius) then
        station_candidates[#station_candidates + 1] = settlement
      end
    end
    local assignment = {
      station = station,
      settlements = {},
      operational_settlements = {},
      customer_requested_stalls = 0,
      requested_stalls = 0,
      powered_stalls = 0
    }
    for _, settlement in pairs(station_candidates) do
      local key = settlement_key(station.surface, settlement)
      if not assigned[key] and #assignment.settlements < config.stalls then
        assigned[key] = true
        assignment.settlements[#assignment.settlements + 1] = settlement
        service.assignment_by_settlement_key[key] = station
      end
    end
    for _, settlement in pairs(assignment.settlements) do
      if settlement_vehicle_count(vehicle_summary, settlement) > 0 then
        assignment.customer_requested_stalls = assignment.customer_requested_stalls + 1
      end
    end
    assignment.requested_stalls = assignment.customer_requested_stalls
    assignment.powered_stalls = powered_station_stalls(station, assignment.requested_stalls)
    local powered_remaining = assignment.powered_stalls
    for _, settlement in pairs(assignment.settlements) do
      local key = settlement_key(settlement.surface, settlement)
      local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
      local operational = vehicle_count == 0
      if vehicle_count > 0 and powered_remaining > 0 and vehicle_count <= config.evs_per_stall then
        operational = true
        powered_remaining = powered_remaining - 1
      end
      if operational then
        service.operational_keys[key] = true
        assignment.operational_settlements[#assignment.operational_settlements + 1] = settlement
      end
    end
    if #station_candidates > 0 then
      service.accessible_stall_capacity = service.accessible_stall_capacity + config.stalls
      service.powered_stall_capacity = service.powered_stall_capacity + assignment.powered_stalls
      service.supported_ev_capacity = service.supported_ev_capacity
        + assignment.powered_stalls * config.evs_per_stall
    end
    service.assignments[station.unit_number] = assignment
  end

  for _, settlement in pairs(candidates) do
    local key = settlement_key(settlement.surface, settlement)
    local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
    if vehicle_count > 0 and not service.operational_keys[key] then
      service.stranded_evs = service.stranded_evs + vehicle_count
    end
    local friendly, angry = settlement_friendly_after_service_check(
      force,
      key,
      service.operational_keys[key] == true,
      advance_mood == true
    )
    if friendly then
      service.served_keys[key] = true
      service.served_settlements[#service.served_settlements + 1] = settlement
    elseif angry then
      service.angry_keys[key] = true
    end
  end

  if service.powered_stall_capacity > 0 then
    service.average_evs_per_stall = math.floor(
      service.supported_ev_capacity / service.powered_stall_capacity + 0.5
    )
  end
  return service
end

local function calculate_station_utilization(force)
  local service = customer_service_for_force(force)
  local stations = {}
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      if station.valid and station_has_grid_access(station) then
        stations[#stations + 1] = station
      end
    end
  end
  table.sort(stations, function(left, right)
    if left.surface.index ~= right.surface.index then
      return left.surface.index < right.surface.index
    end
    return (left.unit_number or 0) < (right.unit_number or 0)
  end)

  local allocations = {}
  local assigned_vehicles = {}
  local vehicle_assignments = {}
  local total_active = 0
  for _, station in pairs(stations) do
    local config = station_config(station)
    local assignment = service.assignments[station.unit_number]
    local customer_requested = math.min(config.stalls, assignment and assignment.requested_stalls or 0)
    local charging_vehicles = {}
    local spare_stalls = config.stalls - customer_requested
    for _, vehicle in pairs(nearby_uncharged_vehicles(station)) do
      if spare_stalls <= 0 then
        break
      end
      if vehicle.unit_number and not assigned_vehicles[vehicle.unit_number] then
        assigned_vehicles[vehicle.unit_number] = true
        charging_vehicles[#charging_vehicles + 1] = vehicle
        spare_stalls = spare_stalls - 1
      end
    end
    local active = customer_requested + #charging_vehicles
    allocations[station.unit_number] = active
    vehicle_assignments[station.unit_number] = {
      customer_requested_stalls = customer_requested,
      vehicles = charging_vehicles
    }
    total_active = total_active + active
  end
  storage.factoryx_station_vehicle_assignments = storage.factoryx_station_vehicle_assignments or {}
  storage.factoryx_station_vehicle_assignments[force.index] = vehicle_assignments
  return allocations, total_active
end

function charge_station_vehicles(station)
  local by_force = storage.factoryx_station_vehicle_assignments or {}
  local assignments = by_force[station.force.index] or {}
  local assignment = assignments[station.unit_number]
  if not assignment then
    return 0
  end
  local power_state = station_power_service()[station.unit_number] or {}
  local vehicle_stalls = math.max(
    0,
    (power_state.powered_stalls or 0) - (assignment.customer_requested_stalls or 0)
  )
  local charged = 0
  local joules = station_stall_power_watts(station)
  for index = 1, math.min(vehicle_stalls, #assignment.vehicles) do
    if charge_vehicle(assignment.vehicles[index], joules) > 0 then
      charged = charged + 1
    end
  end
  return charged
end

local function destroy_customer_marker_key(key)
  local markers = customer_markers()
  local marker = markers[key]
  local object = type(marker) == "table" and marker.render_object or marker
  if object and object.valid then
    object.destroy()
  end
  markers[key] = nil
end

local function destroy_customer_marker(entity)
  if not entity or not entity.valid then
    return
  end
  destroy_customer_marker_key(settlement_key(entity.surface, entity))
end

local function draw_customer_marker(entity)
  if not is_biter_customer_entity(entity) then
    return
  end

  local key = settlement_key(entity.surface, entity)
  local markers = customer_markers()
  local existing = markers[key]
  local is_settlement = BITER_SETTLEMENT_NAMES[entity.name] == true
  if not is_settlement then
    destroy_customer_marker_key(key)
    return
  end
  local marker_type = "market"
  local existing_object = type(existing) == "table" and existing.render_object or existing
  if existing_object and existing_object.valid
    and type(existing) == "table" and existing.marker_type == marker_type then
    return
  end
  if existing_object and existing_object.valid then
    existing_object.destroy()
  end

  local render_object = rendering.draw_text{
    surface = entity.surface,
    target = entity,
    text = "$",
    color = {r = 0.75, g = 1, b = 0.25, a = 1},
    scale = 1.1,
    alignment = "center",
    vertical_alignment = "middle"
  }
  markers[key] = {render_object = render_object, marker_type = marker_type}
end

local function scan_biter_customer_entities(surface, force, area, callback)
  if not force then
    return
  end

  for _, entity in pairs(surface.find_entities_filtered{force = force, area = area}) do
    if is_biter_customer_entity(entity) then
      callback(entity)
    end
  end
end

local function give_customer_wander_command(entity, force_reset)
  if not entity.valid or entity.type ~= "unit" or not entity.commandable then
    return false
  end
  local command = entity.commandable.command
  if not force_reset and command and command.type == defines.command.wander then
    return false
  end
  entity.commandable.set_command{
    type = defines.command.wander,
    distraction = defines.distraction.none,
    radius = CUSTOMER_WANDER_RADIUS
  }
  return true
end

function customer_vehicle_variant_name(entity_name, vehicle_name)
  local base_name = CUSTOMER_UNIT_BASE_BY_NAME[entity_name]
  local class_name = CUSTOMER_VEHICLE_CLASS_BY_ITEM[vehicle_name]
  if not base_name or not class_name then
    return nil
  end
  return "x-" .. base_name .. "-" .. class_name
end

function replace_customer_vehicle_entity(entity, ownership)
  if not entity or not entity.valid or not entity.unit_number or not ownership then
    return entity
  end
  local target_name = customer_vehicle_variant_name(entity.name, ownership.vehicle)
  if not target_name or entity.name == target_name then
    return entity
  end

  local old_unit_number = entity.unit_number
  local home = customer_home_settlements()[old_unit_number]
  local reserved_office = buyer_reserved_by_unit()[old_unit_number]
  local health_ratio = entity.get_health_ratio and entity.get_health_ratio() or 1
  local replacement = entity.surface.create_entity{
    name = target_name,
    position = entity.position,
    direction = entity.direction,
    force = entity.force
  }
  if not replacement or not replacement.valid or not replacement.unit_number then
    return entity
  end

  replacement.health = math.max(1, replacement.max_health * health_ratio)
  customer_unit_registry()[replacement.unit_number] = replacement
  customer_home_settlements()[replacement.unit_number] = home
  customer_vehicle_owners()[replacement.unit_number] = ownership
  if reserved_office then
    buyer_reserved_by_unit()[replacement.unit_number] = reserved_office
    local reservation = office_buyer_reservations()[reserved_office]
    if reservation then
      for index, unit_number in pairs(reservation.buyers or {}) do
        if unit_number == old_unit_number then
          reservation.buyers[index] = replacement.unit_number
        end
      end
    end
  end

  destroy_customer_marker(entity)
  customer_unit_registry()[old_unit_number] = nil
  customer_home_settlements()[old_unit_number] = nil
  customer_vehicle_owners()[old_unit_number] = nil
  buyer_reserved_by_unit()[old_unit_number] = nil
  entity.destroy()
  give_customer_wander_command(replacement, true)
  return replacement
end

function queue_customer_vehicle_variant_migration()
  local queue = {}
  for unit_number, ownership in pairs(customer_vehicle_owners()) do
    local entity = customer_unit_registry()[unit_number]
    if entity and entity.valid
      and customer_vehicle_variant_name(entity.name, ownership.vehicle) ~= entity.name then
      queue[#queue + 1] = unit_number
    end
  end
  storage.factoryx_customer_vehicle_variant_queue = queue
  return #queue
end

function process_customer_vehicle_variant_migration(limit)
  local queue = storage.factoryx_customer_vehicle_variant_queue or {}
  local migrated = 0
  while #queue > 0 and migrated < (limit or 50) do
    local unit_number = table.remove(queue)
    local entity = customer_unit_registry()[unit_number]
    local ownership = customer_vehicle_owners()[unit_number]
    if entity and entity.valid and ownership then
      replace_customer_vehicle_entity(entity, ownership)
      migrated = migrated + 1
    end
  end
  storage.factoryx_customer_vehicle_variant_queue = queue
  return migrated
end

function charger_placement_overlay_states()
  storage.factoryx_charger_placement_overlay_states = storage.factoryx_charger_placement_overlay_states or {}
  return storage.factoryx_charger_placement_overlay_states
end

function sync_charger_placement_overlay(player)
  if not player or not player.valid then
    return
  end
  local stack = player.cursor_stack
  local holding_charger = stack and stack.valid_for_read and STATION_CONFIGS[stack.name] ~= nil
  local states = charger_placement_overlay_states()
  local previous = states[player.index]
  if holding_charger then
    if not previous then
      local settings = player.map_view_settings
      previous = {
        show_electric_network = settings.show_electric_network,
        show_logistic_network = settings.show_logistic_network
      }
      states[player.index] = previous
    end
    player.map_view_settings = {
      show_electric_network = true,
      show_logistic_network = false
    }
  elseif previous then
    player.map_view_settings = previous
    states[player.index] = nil
  end
end

local function release_enemy_mobile_unit(entity)
  if not entity.valid or entity.type ~= "unit" or not entity.commandable then
    return
  end
  entity.commandable.set_command{
    type = defines.command.wander,
    distraction = defines.distraction.by_enemy,
    radius = CUSTOMER_WANDER_RADIUS,
    ticks_to_wait = ENEMY_RELEASE_WANDER_TICKS
  }
end

local function convert_biter_entity(entity, force)
  local converted = false
  if entity.valid and entity.force ~= force then
    entity.force = force
    converted = true
  end
  if entity.valid and entity.type == "unit-spawner" then
    pcall(function() entity.active = true end)
  end
  if entity.valid and entity.type == "unit" and force.name == CUSTOMER_FORCE_NAME and entity.commandable then
    give_customer_wander_command(entity)
    pcall(function()
      entity.color = CUSTOMER_UNIT_BASE_BY_NAME[entity.name] == entity.name and CUSTOMER_UNIT_COLOR or nil
    end)
  elseif converted and entity.valid and entity.type == "unit" and force.name == "enemy" then
    pcall(function() entity.color = nil end)
    release_enemy_mobile_unit(entity)
  end
  return converted
end

function customer_settlement_alert_states()
  storage.factoryx_customer_settlement_alert_states = storage.factoryx_customer_settlement_alert_states or {}
  return storage.factoryx_customer_settlement_alert_states
end

function update_customer_settlement_alerts(force, service)
  local moods = customer_settlement_moods(force)
  local vehicle_summary = active_customer_vehicle_summary(force)
  local disrupted = {}
  for _, settlement in pairs(service.candidate_settlements or {}) do
    if settlement.valid then
      local key = settlement_key(settlement.surface, settlement)
      local mood = moods[key]
      if (vehicle_summary.by_settlement[key] or 0) > 0
        and not service.operational_keys[key]
        and mood and mood.was_customer then
        disrupted[key] = settlement
      end
    end
  end

  local states = customer_settlement_alert_states()
  for _, player in pairs(force.connected_players) do
    states[player.index] = states[player.index] or {}
    local player_states = states[player.index]
    for key, settlement in pairs(player_states) do
      if not disrupted[key] or not settlement.valid then
        if settlement.valid then
          player.remove_alert{entity = settlement, type = defines.alert_type.custom}
        end
        player_states[key] = nil
      end
    end
    for key, settlement in pairs(disrupted) do
      if not player_states[key] then
        player.add_custom_alert(
          settlement,
          {type = "item", name = "x-ev-charging-station"},
          {"", "Customer settlement lacks powered charging stall capacity."},
          true
        )
        player_states[key] = settlement
      end
    end
  end
end

function sync_customer_settlements()
  if not biter_customer_mode_enabled() then
    return {customer_settlements = 0, converted_to_customer = 0, reverted_to_enemy = 0, reverted_hostile_worms = 0}
  end

  local enemy = game.forces.enemy
  local customers = customer_force()
  local covered = {}
  local converted = 0
  local customer_settlements = 0
  for _, force in pairs(game.forces) do
    if player_market_force(force) then
      local service = customer_service_for_force(force, true)
      update_customer_settlement_alerts(force, service)
      for _, settlement in pairs(service.served_settlements) do
        if settlement.valid then
          local key = settlement_key(settlement.surface, settlement)
          covered[key] = true
          if convert_biter_entity(settlement, customers) then
            converted = converted + 1
          end
          draw_customer_marker(settlement)
          customer_settlements = customer_settlements + 1
        end
      end
      for _, settlement in pairs(service.served_settlements) do
        if settlement.valid then
          local area = area_around(settlement.position, CUSTOMER_MOBILE_SERVICE_RADIUS)
          for _, source_force in pairs({enemy, customers}) do
            scan_biter_customer_entities(settlement.surface, source_force, area, function(entity)
              if not BITER_SETTLEMENT_NAMES[entity.name]
                and within_radius(settlement, entity, CUSTOMER_MOBILE_SERVICE_RADIUS) then
                local key = settlement_key(settlement.surface, entity)
                covered[key] = true
                register_customer_unit(entity, settlement, force)
                if convert_biter_entity(entity, customers) then
                  converted = converted + 1
                end
                draw_customer_marker(entity)
              end
            end)
          end
        end
      end
    end
  end

  local reverted = 0
  local reverted_hostile_worms = 0
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{force = customers}) do
      if is_hostile_worm_entity(entity) then
        destroy_customer_marker(entity)
        if enemy and convert_biter_entity(entity, enemy) then
          reverted_hostile_worms = reverted_hostile_worms + 1
        end
      elseif is_biter_customer_entity(entity) then
        local key = settlement_key(surface, entity)
        if covered[key] then
          draw_customer_marker(entity)
        elseif enemy then
          if entity.unit_number and customer_vehicle_owners()[entity.unit_number] then
            draw_customer_marker(entity)
          else
            destroy_customer_marker(entity)
          end
          if convert_biter_entity(entity, enemy) then
            reverted = reverted + 1
          end
        end
      end
    end
  end

  local owned_marker_keys = {}
  for unit_number, ownership in pairs(customer_vehicle_owners()) do
    local entity = customer_unit_registry()[unit_number]
    if ownership and entity and entity.valid then
      owned_marker_keys[settlement_key(entity.surface, entity)] = true
    end
  end
  for key, _ in pairs(customer_markers()) do
    if not covered[key] and not owned_marker_keys[key] then
      destroy_customer_marker_key(key)
    end
  end

  return {
    customer_settlements = customer_settlements,
    converted_to_customer = converted,
    reverted_to_enemy = reverted,
    reverted_hostile_worms = reverted_hostile_worms
  }
end

function sync_customer_service_states()
  if not biter_customer_mode_enabled() then
    return
  end
  local customers = customer_force()
  local enemy = game.forces.enemy
  for _, force in pairs(game.forces) do
    if player_market_force(force) then
      local service = customer_service_for_force(force, true)
      update_customer_settlement_alerts(force, service)
      for _, settlement in pairs(service.candidate_settlements or {}) do
        if settlement.valid then
          local key = settlement_key(settlement.surface, settlement)
          local target_force = service.served_keys[key] and customers or enemy
          if target_force then
            convert_biter_entity(settlement, target_force)
          end
          if service.served_keys[key] then
            draw_customer_marker(settlement)
          else
            destroy_customer_marker(settlement)
          end
        end
      end
    end
  end
end

local function customer_growth_states()
  storage.factoryx_customer_growth_states = storage.factoryx_customer_growth_states or {}
  return storage.factoryx_customer_growth_states
end

local function customer_growth_random()
  local generator = storage.factoryx_customer_growth_random
  if not generator or not generator.valid then
    generator = game.create_random_generator()
    storage.factoryx_customer_growth_random = generator
  end
  return generator
end

local function enemy_evolution(surface)
  local evolution = 0
  local enemy = game.forces.enemy
  if enemy then
    local ok, value = pcall(function() return enemy.get_evolution_factor(surface) end)
    if ok and value then
      evolution = value
    end
  end
  return evolution
end

local function hostile_worm_chance(evolution)
  if evolution >= 0.6 then
    return 0.75
  elseif evolution >= 0.3 then
    return 0.50
  end
  return 0.25
end

local function hostile_worm_name(evolution)
  if evolution >= 0.9 then
    return "behemoth-worm-turret"
  elseif evolution >= 0.6 then
    return "big-worm-turret"
  elseif evolution >= 0.3 then
    return "medium-worm-turret"
  end
  return "small-worm-turret"
end

local function deterministic_growth_position(station, entity_name, minimum_distance, maximum_distance, salt)
  local offices = force_sales_offices(station.force)
  local span = math.max(1, maximum_distance - minimum_distance)
  for attempt = 0, 31 do
    local seed = (station.unit_number or 1) * 37 + (salt or 0) * 83 + attempt * 47
    local angle = math.rad(seed % 360)
    local distance = minimum_distance + (seed % span)
    local target = {
      x = station.position.x + math.cos(angle) * distance,
      y = station.position.y + math.sin(angle) * distance
    }
    local position = station.surface.find_non_colliding_position(entity_name, target, 8, 1)
    if position and within_radius(station, {position = position}, station_config(station).customer_radius)
      and position_has_sales_coverage(station.surface, position, offices) then
      return position
    end
  end
  return nil
end

local function grow_customer_settlement(station, state)
  local config = station_config(station)
  if not config then
    return nil
  end
  local colony_number = (state.colonies or 0) + 1
  local spawner_name = colony_number % 2 == 0 and "spitter-spawner" or "biter-spawner"
  local spawner_position = deterministic_growth_position(
    station,
    spawner_name,
    20,
    math.max(28, config.customer_radius - 8),
    colony_number
  )
  if not spawner_position then
    return nil
  end

  local settlement = station.surface.create_entity{
    name = spawner_name,
    position = spawner_position,
    force = customer_force()
  }
  if not settlement then
    return nil
  end
  draw_customer_marker(settlement)

  local evolution = enemy_evolution(station.surface)
  local worm
  local random = customer_growth_random()
  if random() < hostile_worm_chance(evolution) then
    local worm_name = hostile_worm_name(evolution)
    local worm_position = station.surface.find_non_colliding_position(worm_name, spawner_position, 24, 1)
    worm = worm_position and station.surface.create_entity{
      name = worm_name,
      position = worm_position,
      force = game.forces.enemy
    } or nil
  end
  state.colonies = colony_number
  state.last_growth_tick = game.tick
  return settlement
end

local function process_customer_growth(force)
  if not player_market_force(force) then
    return
  end
  local service = customer_service_for_force(force)
  local allocations = calculate_station_utilization(force)
  local states = customer_growth_states()
  local referral_level = continuous_improvement_level(force, CUSTOMER_REFERRAL_TECH_NAME)
  local referral_multiplier = 1 + referral_level * 0.1
  for unit_number, assignment in pairs(service.assignments) do
    local station = assignment.station
    if station and station.valid then
      local state = states[unit_number] or {progress = 0, colonies = 0}
      states[unit_number] = state
      local active_stalls = active_customer_station_stalls(station, service)
      local spare_stalls = station_config(station).stalls - #assignment.settlements
      if service.stranded_evs == 0 and active_stalls > 0 and spare_stalls > 0 then
        state.progress = (state.progress or 0) + active_stalls * referral_multiplier
        if state.progress >= CUSTOMER_GROWTH_PROGRESS_REQUIRED then
          if grow_customer_settlement(station, state) then
            state.progress = state.progress - CUSTOMER_GROWTH_PROGRESS_REQUIRED
          else
            state.progress = CUSTOMER_GROWTH_PROGRESS_REQUIRED
          end
        end
      end
    end
  end
end

local function customer_growth_summary(force)
  local service = customer_service_for_force(force)
  local states = customer_growth_states()
  local progress = 0
  local colonies = 0
  for unit_number, assignment in pairs(service.assignments) do
    local state = states[unit_number] or {}
    progress = progress + (state.progress or 0)
    colonies = colonies + (state.colonies or 0)
  end
  local angry = 0
  for _ in pairs(service.angry_keys) do angry = angry + 1 end
  return service, {
    friendly_settlements = #service.served_settlements,
    angry_settlements = angry,
    accessible_stall_capacity = service.accessible_stall_capacity,
    supported_ev_capacity = service.supported_ev_capacity,
    evs_per_stall = service.average_evs_per_stall,
    stranded_evs = service.stranded_evs,
    growth_progress = progress,
    growth_progress_required = CUSTOMER_GROWTH_PROGRESS_REQUIRED,
    grown_colonies = colonies
  }
end

local function active_station_stalls(station, allocations)
  if not station_config(station) then
    return 0
  end
  if not allocations then
    allocations = calculate_station_utilization(station.force)
  end
  local requested = allocations[station.unit_number] or 0
  return powered_station_stalls(station, requested)
end

function active_customer_station_stalls(station, service)
  service = service or customer_service_for_force(station.force)
  local assignment = service.assignments[station.unit_number]
  local requested = assignment and assignment.requested_stalls or 0
  local power_state = station_power_service()[station.unit_number]
  local total_requested = power_state and power_state.requested_stalls or requested
  return math.min(requested, powered_station_stalls(station, total_requested))
end

function waiting_market_buyers_at_station(station, service)
  service = service or customer_service_for_force(station.force)
  local count = 0
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    if entity and entity.valid and entity.force.name == CUSTOMER_FORCE_NAME
      and home and service.operational_keys[home.settlement_key]
      and service.assignment_by_settlement_key[home.settlement_key] == station
      and not customer_vehicle_owners()[unit_number]
      and not buyer_reserved_by_unit()[unit_number] then
      count = count + 1
    end
  end
  return count
end

function station_reservation_demand(station, active_stalls, service)
  service = service or customer_service_for_force(station.force)
  local customer_powered = active_customer_station_stalls(station, service)
  if customer_powered > 0 then
    return customer_powered
  end
  return waiting_market_buyers_at_station(station, service) > 0 and 1 or 0
end

local function count_active_customer_stalls(force)
  if not biter_customer_mode_enabled() then
    return count_powered_stations(force)
  end

  local allocations = calculate_station_utilization(force)
  local service = customer_service_for_force(force)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      if station.valid and station_has_grid_access(station) then
        local stalls = active_customer_station_stalls(station, service)
        count = count + stalls
        ensure_station_grid_connection(station)
        ensure_station_power_sinks(station, allocations[station.unit_number] or 0)
      else
        remove_station_grid_connection(station)
        remove_station_power_sink(station)
      end
    end
  end
  return count
end

local function close_station_info_panel(player)
  if not player or not player.valid then
    return
  end
  local panel = player.gui.left[STATION_INFO_PANEL_NAME]
  if panel then
    panel.destroy()
  end
end

local function add_station_info_label(parent, caption)
  parent.add{
    type = "label",
    caption = caption,
    single_line = false
  }
end

local function station_next_step(station, covered_settlements, hostile_settlements, offices)
  if covered_settlements == 0 then
    if hostile_settlements > 0 then
      return string.format("Next: place or move a Sales Office within %d tiles so these hostile spawners become customer settlements, then this charger can create demand.", SALES_OFFICE_CUSTOMER_RADIUS)
    end
    return string.format("Next: place this charger within %d tiles of Sales Office-converted customer spawners.", station_config(station).customer_radius)
  end
  if station.name == "x-ev-charging-station-v3" then
    if researched(station.force, "x-autonomous-logistics") then
      return "Next: V4 Superchargers are unlocked; craft one from this V3, Solar Arrays, Megapacks, and Dollars."
    end
    return "Next: research Autonomous Logistics to unlock Robotaxis, V4 fleet charging, and the Robotaxi Service Center."
  elseif station.name == "x-ev-charging-station-v4" then
    return "Next: use this 20-stall solar-canopy site to support Robotaxi-scale charging demand."
  elseif station.name == "x-ev-charging-station-v2" then
    return "Next: Mass-market EV Production unlocks V3 Superchargers and Gigafactory V2."
  end
  local roadster_recipe = station.force and station.force.recipes and station.force.recipes[PROTOTYPE_ROADSTER_NAME]
  if roadster_recipe and roadster_recipe.enabled then
    return "Next: craft Prototype Roadsters and sell hopes and dreams through a Sales Office."
  end
  return "Next: this customer charging site unlocks Prototype Roadsters for the first Sales Office recipe."
end

local function show_station_info_panel(player, station)
  if not player or not player.valid then
    return
  end
  close_station_info_panel(player)
  if not is_station(station) then
    return
  end

  local config = station_config(station)
  local grid_connected = station_has_grid_access(station)
  local covered_settlements = count_biter_settlements_near_station(station)
  local hostile_settlements = count_hostile_biter_settlements_near_station(station)
  local allocations = calculate_station_utilization(station.force)
  local active_stalls = active_station_stalls(station, allocations)
  local customer_evs = customer_ev_fleet_size(station.force)
  local potential_demand = math.min(config.stalls, covered_settlements)
  local offices = #find_sales_offices(station.force)
  local service, growth = customer_growth_summary(station.force)
  local reservation_rate = station_reservation_demand(station, active_stalls, service)
    * RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE
  local reservation_inventory = station_reservation_inventory(station)
  local reservation_stock = reservation_inventory and reservation_inventory.get_item_count(RESERVATION_NAME) or 0
  local researched_power_per_stall_kw = station_stall_power_watts(station) / 1000
  local power_draw_kw = active_stalls * researched_power_per_stall_kw
  local power_state = station_power_service()[station.unit_number] or {power_fraction = grid_connected and 1 or 0}
  local assignment = service.assignments[station.unit_number]
  local vehicle_assignments = storage.factoryx_station_vehicle_assignments
    and storage.factoryx_station_vehicle_assignments[station.force.index] or {}
  local vehicle_assignment = vehicle_assignments[station.unit_number] or {vehicles = {}, customer_requested_stalls = 0}
  local powered_vehicle_stalls = math.max(
    0,
    (power_state.powered_stalls or 0) - (vehicle_assignment.customer_requested_stalls or 0)
  )
  local friendly_here = assignment and #assignment.operational_settlements or 0
  local growth_state = customer_growth_states()[station.unit_number] or {}
  local spare_growth_stalls = math.max(0, config.stalls - friendly_here)
  local panel = player.gui.left.add{
    type = "frame",
    name = STATION_INFO_PANEL_NAME,
    caption = "FactoryX " .. config.display_name,
    direction = "vertical"
  }

  add_station_info_label(panel, grid_connected and "Grid: connected" or "Grid: not connected")
  add_station_info_label(panel, string.format("Customer settlements in charger range: %d", covered_settlements))
  if hostile_settlements > 0 then
    add_station_info_label(panel, string.format("Hostile spawners nearby, not customers yet: %d", hostile_settlements))
  end
  add_station_info_label(panel, string.format("Active customer vehicles: %d", customer_evs))
  add_station_info_label(panel, string.format(
    "Reachable network capacity: %d EVs (weighted average %d per stall)",
    growth.supported_ev_capacity,
    growth.evs_per_stall
  ))
  add_station_info_label(panel, string.format("This charger tier: %d EVs per stall / %d EVs total", config.evs_per_stall, config.stalls * config.evs_per_stall))
  add_station_info_label(panel, string.format("Potential local stall demand: %d", potential_demand))
  add_station_info_label(panel, string.format("Active stalls: %d/%d", active_stalls, config.stalls))
  add_station_info_label(panel, string.format(
    "Player EV charging: %d nearby / %d powered stalls",
    #vehicle_assignment.vehicles,
    math.min(powered_vehicle_stalls, #vehicle_assignment.vehicles)
  ))
  add_station_info_label(panel, string.format("Player EV charge radius: %d tiles", config.vehicle_charge_radius))
  add_station_info_label(panel, string.format(
    "Stall power availability: %d%% (%d requested)",
    math.floor((power_state.power_fraction or 0) * 100 + 0.5),
    allocations[station.unit_number] or 0
  ))
  add_station_info_label(panel, string.format("Friendly settlements served here: %d", friendly_here))
  add_station_info_label(panel, string.format("Stranded EVs: %d", growth.stranded_evs))
  add_station_info_label(panel, growth.stranded_evs > 0
    and string.format("Customer mood: %d angry; others may be in the grace period", growth.angry_settlements)
    or "Customer mood: friendly")
  add_station_info_label(panel, string.format("Spare settlement capacity: %d", spare_growth_stalls))
  add_station_info_label(panel, string.format(
    "Next settlement: %d/%d active stall-minutes",
    math.floor((growth_state.progress or 0) / 60),
    CUSTOMER_GROWTH_STALL_MINUTES
  ))
  add_station_info_label(panel, string.format(
    "Power draw: %.0f kW / %.0f kW max",
    power_draw_kw,
    config.stalls * researched_power_per_stall_kw
  ))
  add_station_info_label(panel, string.format("Paperwork output: %d EV Reservations per minute", reservation_rate))
  add_station_info_label(panel, string.format("Paperwork waiting for pickup: %d", reservation_stock))
  add_station_info_label(panel, string.format("Active EV Sales Offices: %d", offices))
  add_station_info_label(panel, station_next_step(station, covered_settlements, hostile_settlements, offices))
end

local function biter_customer_market_summary(force)
  local powered_stations, charging_stall_capacity = count_powered_stations(force)
  local customer_mode = biter_customer_mode_enabled()
  local covered_settlements = 0
  local demand_units = powered_stations
  local active_customer_stalls = powered_stations

  if customer_mode then
    covered_settlements = count_covered_biter_settlements(force)
    active_customer_stalls = count_active_customer_stalls(force)
    demand_units = 0
    local service = customer_service_for_force(force)
    local allocations = calculate_station_utilization(force)
    for _, surface in pairs(game.surfaces) do
      for _, station in pairs(find_stations(surface, force)) do
        demand_units = demand_units + station_reservation_demand(
          station,
          active_station_stalls(station, allocations),
          service
        )
      end
    end
  end

  local _, growth = customer_growth_summary(force)
  return {
    biter_customer_mode = customer_mode,
    powered_stations = powered_stations,
    covered_biter_settlements = covered_settlements,
    active_customer_stalls = active_customer_stalls,
    charging_stall_capacity = charging_stall_capacity,
    accessible_stall_capacity = growth.accessible_stall_capacity,
    supported_ev_capacity = growth.supported_ev_capacity,
    evs_per_stall = growth.evs_per_stall,
    customer_ev_fleet = customer_ev_fleet_size(force),
    friendly_settlements = growth.friendly_settlements,
    angry_settlements = growth.angry_settlements,
    stranded_evs = growth.stranded_evs,
    grown_colonies = growth.grown_colonies,
    growth_progress = growth.growth_progress,
    growth_progress_required = growth.growth_progress_required,
    demand_units = demand_units,
    reservations_per_minute = demand_units * RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE
  }
end

function find_sales_offices(force)
  local offices = {}
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME, force = force}) do
      if office.valid and RESERVATION_RECIPES[current_recipe_name(office)] then
        offices[#offices + 1] = office
      end
    end
  end
  return offices
end

local function top_up_station_reservations(station, amount)
  local inventory = station_reservation_inventory(station)
  if not inventory then
    return 0
  end
  local existing = inventory.get_item_count(RESERVATION_NAME)
  if existing >= RESERVATION_BUFFER_LIMIT then
    return 0
  end

  return inventory.insert{
    name = RESERVATION_NAME,
    count = math.min(amount, RESERVATION_BUFFER_LIMIT - existing)
  }
end

local function reservation_print_progress()
  storage.factoryx_reservation_print_progress = storage.factoryx_reservation_print_progress or {}
  return storage.factoryx_reservation_print_progress
end

local function generate_station_reservations(force)
  if not researched(force, "x-ev-charging-network") and not first_prototype_sale_unlocked(force) then
    return
  end

  local allocations = calculate_station_utilization(force)
  local service = customer_service_for_force(force)
  local progress = reservation_print_progress()
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      local active_stalls = active_station_stalls(station, allocations)
      local demand_stalls = station_reservation_demand(station, active_stalls, service)
      if demand_stalls > 0 and station_has_grid_access(station) then
        local key = station.unit_number
        local accumulated = (progress[key] or 0) + demand_stalls * RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE
        local ready = math.floor(accumulated / RESERVATION_SAMPLES_PER_PRINT)
        if ready > 0 then
          local inserted = top_up_station_reservations(station, ready)
          accumulated = accumulated - inserted * RESERVATION_SAMPLES_PER_PRINT
          if inserted == 0 then
            accumulated = math.min(accumulated, RESERVATION_SAMPLES_PER_PRINT)
          end
        end
        progress[key] = accumulated
      end
    end
  end
end

local function add_reservation_output_status(summary, force)
  local progress = reservation_print_progress()
  summary.charger_reservation_stock = 0
  summary.reservation_print_progress = 0
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      local inventory = station_reservation_inventory(station)
      summary.charger_reservation_stock = summary.charger_reservation_stock
        + (inventory and inventory.get_item_count(RESERVATION_NAME) or 0)
      summary.reservation_print_progress = summary.reservation_print_progress
        + (progress[station.unit_number] or 0)
    end
  end
  return summary
end

local function victory_forces()
  storage.factoryx_victory_forces = storage.factoryx_victory_forces or {}
  return storage.factoryx_victory_forces
end

local function grid_controllers()
  storage.factoryx_grid_controllers = storage.factoryx_grid_controllers or {}
  return storage.factoryx_grid_controllers
end

local function first_prototype_sales()
  storage.factoryx_first_prototype_sales = storage.factoryx_first_prototype_sales or {}
  return storage.factoryx_first_prototype_sales
end

local function sales_office_products_finished()
  storage.factoryx_sales_office_products_finished = storage.factoryx_sales_office_products_finished or {}
  return storage.factoryx_sales_office_products_finished
end

function robotaxi_service_states()
  storage.factoryx_robotaxi_service_states = storage.factoryx_robotaxi_service_states or {}
  return storage.factoryx_robotaxi_service_states
end

function robotaxi_service_power_entities()
  storage.factoryx_robotaxi_service_power = storage.factoryx_robotaxi_service_power or {}
  return storage.factoryx_robotaxi_service_power
end

function ensure_robotaxi_service_power(center)
  local powers = robotaxi_service_power_entities()
  local power = powers[center.unit_number]
  if power and power.valid then return power end
  power = center.surface.create_entity{
    name = ROBOTAXI_SERVICE_POWER_NAME,
    position = center.position,
    force = center.force,
    quality = center.quality,
    create_build_effect_smoke = false
  }
  if power then
    pcall(function() power.set_recipe(ROBOTAXI_SERVICE_RECIPE) end)
    powers[center.unit_number] = power
  end
  return power
end

function robotaxi_service_inventories(center)
  if not center or not center.valid or center.name ~= ROBOTAXI_SERVICE_CENTER_NAME then
    return nil, nil
  end
  local inventory = center.get_inventory(defines.inventory.chest)
  if inventory and inventory.valid and #inventory >= 41 then
    for slot = 1, 40 do pcall(function() inventory.set_filter(slot, ROBOTAXI_ITEM_NAME) end) end
    pcall(function() inventory.set_filter(41, DOLLAR_NAME) end)
  end
  return inventory, inventory
end

function robotaxi_customers_in_range(center)
  local customer_force = game.forces[CUSTOMER_FORCE_NAME]
  if not customer_force then return 0 end
  return #center.surface.find_entities_filtered{
    type = "unit",
    force = customer_force,
    area = {
      {center.position.x - ROBOTAXI_SERVICE_RADIUS, center.position.y - ROBOTAXI_SERVICE_RADIUS},
      {center.position.x + ROBOTAXI_SERVICE_RADIUS, center.position.y + ROBOTAXI_SERVICE_RADIUS}
    }
  }
end

function robotaxi_service_power_factor(center)
  local power = ensure_robotaxi_service_power(center)
  if not power then return 0 end
  if power.status == defines.entity_status.no_power then return 0 end
  if power.status == defines.entity_status.low_power then return 0.5 end
  return power.energy and power.energy > 0 and 1 or 0
end

function robotaxi_service_snapshot(center)
  local input, output = robotaxi_service_inventories(center)
  local stored = input and input.get_item_count(ROBOTAXI_ITEM_NAME) or 0
  local fleet = math.min(200, stored)
  local customers = robotaxi_customers_in_range(center)
  local allocated = math.min(fleet, math.ceil(customers / ROBOTAXI_CUSTOMERS_PER_VEHICLE))
  local served = math.min(customers, allocated * ROBOTAXI_CUSTOMERS_PER_VEHICLE)
  local power_factor = robotaxi_service_power_factor(center)
  local audio_level = continuous_improvement_level(center.force, PREMIUM_AUDIO_TECH_NAME)
  local state = robotaxi_service_states()[center.unit_number] or {revenue = 0, attrition = 0, dollars = 0, vehicles_retired = 0}
  return {
    stored = fleet,
    allocated = allocated,
    customers = customers,
    served = served,
    power_factor = power_factor,
    revenue_per_minute = allocated / ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR
      * power_factor * (1 + audio_level * 0.05),
    output_dollars = output and output.get_item_count(DOLLAR_NAME) or 0,
    revenue_progress = state.revenue or 0,
    attrition_progress = state.attrition or 0,
    lifetime_dollars = state.dollars or 0,
    vehicles_retired = state.vehicles_retired or 0
  }
end

function process_robotaxi_service_centers()
  local seen = {}
  for _, surface in pairs(game.surfaces) do
    for _, center in pairs(surface.find_entities_filtered{name = ROBOTAXI_SERVICE_CENTER_NAME}) do
      if center.valid and center.unit_number then
        seen[center.unit_number] = true
        local input, output = robotaxi_service_inventories(center)
        local snapshot = robotaxi_service_snapshot(center)
        local state = robotaxi_service_states()[center.unit_number]
          or {revenue = 0, attrition = 0, dollars = 0, vehicles_retired = 0}
        robotaxi_service_states()[center.unit_number] = state
        if snapshot.allocated > 0 then
          state.revenue = state.revenue + snapshot.revenue_per_minute / 60
          state.attrition = state.attrition
            + snapshot.allocated * snapshot.power_factor / (ROBOTAXI_ATTRITION_VEHICLE_HOURS * 3600)
          local dollars = math.floor(state.revenue)
          if dollars > 0 and output then
            local inserted = output.insert{name = DOLLAR_NAME, count = dollars}
            state.revenue = state.revenue - inserted
            state.dollars = state.dollars + inserted
            if inserted > 0 then
              local statistics = center.force.get_item_production_statistics(center.surface)
              statistics.set_output_count(DOLLAR_NAME, statistics.get_output_count(DOLLAR_NAME) + inserted)
              announce_first_robotaxi_service(center.force)
            end
          end
          local retirements = math.floor(state.attrition)
          if retirements > 0 and input then
            local removed = input.remove{name = ROBOTAXI_ITEM_NAME, count = retirements}
            state.attrition = state.attrition - removed
            state.vehicles_retired = state.vehicles_retired + removed
          end
        end
      end
    end
  end
  for unit_number in pairs(robotaxi_service_states()) do
    if not seen[unit_number] then
      robotaxi_service_states()[unit_number] = nil
      local power = robotaxi_service_power_entities()[unit_number]
      if power and power.valid then power.destroy() end
      robotaxi_service_power_entities()[unit_number] = nil
    end
  end
end

local function first_ev_production_line_hints()
  storage.factoryx_first_ev_production_line_hints = storage.factoryx_first_ev_production_line_hints or {}
  return storage.factoryx_first_ev_production_line_hints
end

local function first_premium_ev_sales()
  storage.factoryx_first_premium_ev_sales = storage.factoryx_first_premium_ev_sales or {}
  return storage.factoryx_first_premium_ev_sales
end

local function first_mass_market_ev_sales()
  storage.factoryx_first_mass_market_ev_sales = storage.factoryx_first_mass_market_ev_sales or {}
  return storage.factoryx_first_mass_market_ev_sales
end

local function first_robotaxi_sales()
  storage.factoryx_first_robotaxi_sales = storage.factoryx_first_robotaxi_sales or {}
  return storage.factoryx_first_robotaxi_sales
end

local function first_entity_placement_hints()
  storage.factoryx_first_entity_placement_hints = storage.factoryx_first_entity_placement_hints or {}
  return storage.factoryx_first_entity_placement_hints
end

local function force_has_first_prototype_sale_history(force)
  if not force then
    return false
  end

  for _, surface in pairs(game.surfaces) do
    local ok, consumed_count = pcall(function()
      local statistics = force.get_item_production_statistics(surface)
      return statistics.output_counts[PROTOTYPE_ROADSTER_NAME] or 0
    end)
    if ok and consumed_count > 0 then
      return true
    end
  end
  return false
end

local function force_has_first_premium_sale_history(force)
  if not force then
    return false
  end

  for _, surface in pairs(game.surfaces) do
    local ok, consumed_count = pcall(function()
      local statistics = force.get_item_production_statistics(surface)
      return statistics.output_counts[PREMIUM_EV_NAME] or 0
    end)
    if ok and consumed_count > 0 then
      return true
    end
  end
  return false
end

function first_prototype_sale_unlocked(force)
  if not force or not force.valid then
    return false
  end
  return first_prototype_sales()[force.name]
    or force_has_first_prototype_sale_history(force)
end

local function track_grid_controller(entity)
  if entity and entity.valid and entity.name == GRID_CONTROLLER_NAME and entity.unit_number then
    grid_controllers()[entity.unit_number] = entity
  end
end

local function track_sales_office(entity)
  if entity and entity.valid and entity.name == SALES_OFFICE_NAME and entity.unit_number then
    sales_office_products_finished()[entity.unit_number] = safe_products_finished(entity)
  end
end

local function rebuild_grid_controllers()
  storage.factoryx_grid_controllers = {}
  for _, surface in pairs(game.surfaces) do
    for _, controller in pairs(surface.find_entities_filtered{name = GRID_CONTROLLER_NAME}) do
      track_grid_controller(controller)
    end
  end
end

local function rebuild_sales_offices()
  storage.factoryx_sales_office_products_finished = {}
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME}) do
      track_sales_office(office)
    end
  end
end

local function unlock_roadster_sales(force)
  if not force or not force.valid then
    return
  end

  local milestones = first_prototype_sales()
  local first_unlock = not milestones[force.name]
  milestones[force.name] = true

  for _, recipe_name in pairs(FIRST_CUSTOMER_CHARGER_UNLOCK_RECIPES) do
    local recipe = force.recipes and force.recipes[recipe_name]
    if recipe then
      recipe.enabled = true
    end
  end
  if first_unlock then
    force.print("[FactoryX] First biter customer charging site covered. Prototype Roadsters are now available for Sell hopes and dreams.")
  end
end

local function announce_first_ev_production_line_hint(force)
  if not force or not force.valid then
    return
  end

  local milestones = first_ev_production_line_hints()
  if milestones[force.name] then
    return
  end
  milestones[force.name] = true

  force.print("[FactoryX] First Dollars earned. Next: research EV Production Line to unlock Gigafactory Modules, EV components, Premium EV design, and Sell premium product.")
end

local function announce_ev_production_line_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[FactoryX] EV Production Line researched. Build 10 Gigafactory Modules and the EV components, then research Energy Products to unlock Gigafactory construction.")
end

local function announce_mass_market_production_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[FactoryX] Mass-market EV Production researched. Craft Gigafactory V2 in an Assembling Machine or Gigafactory, then place it directly over a V1. V2 runs twice as fast with 150% built-in productivity while drawing 30 MW.")
end

local function announce_ev_charging_network_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[FactoryX] EV Charging Network researched. Craft a separate V2 charger from 1 V1 charger, 2 Substations, 20 Processing Units, and 20 Dollars, then place it. V2 has 8 stalls, 96-tile customer range, and up to 1.2 MW demand.")
end

local function announce_first_premium_ev_sale(force)
  if not force or not force.valid then
    return
  end

  local milestones = first_premium_ev_sales()
  if milestones[force.name] then
    return
  end
  milestones[force.name] = true

  force.print("[FactoryX] Premium EV sales are working. Next: build EV Charging Network, then research Mass-market EV Production for Gigacasting and Gigafactory V2.")
end

local function announce_first_mass_market_ev_sale(force)
  if not force or not force.valid then
    return
  end

  local milestones = first_mass_market_ev_sales()
  if milestones[force.name] then
    return
  end
  milestones[force.name] = true

  force.print("[FactoryX] Mass-market EV sales are online. Build High-density Solar Arrays and Megapacks through Energy Products, then research Terrestrial AI.")
end

announce_first_robotaxi_service = function(force)
  if not force or not force.valid then
    return
  end
  local milestones = first_robotaxi_sales()
  if milestones[force.name] then
    return
  end
  milestones[force.name] = true
  local v4_recipe = force.recipes and force.recipes["x-ev-charging-station-v4"]
  if v4_recipe then
    v4_recipe.enabled = true
  end
  local legacy_robotaxi_sale = force.recipes and force.recipes[ROBOTAXI_SALE_RECIPE]
  if legacy_robotaxi_sale then legacy_robotaxi_sale.enabled = false end
  local launch_technology = force.technologies and force.technologies[SMALL_ORBITAL_LAUNCH_TECH]
  if launch_technology then
    launch_technology.enabled = true
  end
  force.print("[FactoryX] Robotaxi service is producing recurring profit. Small Orbital Launch is now available.")
end

local RESEARCH_COMPLETION_MESSAGES = {
  ["x-sales-office"] = "[FactoryX] Sales Office researched. Place one within 128 tiles of enemy spawners, then place a grid-connected EV Charging Station within 64 tiles of the converted customer settlement.",
  ["x-energy-products"] = "[FactoryX] Energy Products researched. Gigafactory construction is now unlocked. Build one from 10 Gigafactory Modules and 2 Substations, then manufacture Premium EVs, High-density Solar Arrays, and Megapacks.",
  ["x-small-orbital-launch"] = "[FactoryX] Small Orbital Launch researched. Manufacture a Small Launch Service, then sell the physical service through a Sales Office to fund reusable launch development.",
  ["x-reusable-launch"] = "[FactoryX] Reusable Launch researched. Build Reusable Boosters, combine them into Reusable Launch Services, and sell those services through a Sales Office.",
  ["x-satellite-constellation"] = "[FactoryX] Satellite Constellation researched. Manufacture Satellite Buses and Ground Station Networks; both become physical inputs to orbital compute and the planetary grid.",
  ["x-terrestrial-ai"] = "[FactoryX] Terrestrial AI researched. Build 4 Datacenter Racks, then construct an 8 MW Terrestrial Datacenter. Supply 20 Dollars per cycle to produce 20 AI Tokens every 30 seconds; stockpile 1,000 for Autonomous Logistics.",
  ["x-autonomous-logistics"] = "[FactoryX] Autonomous Logistics researched. Build Robotaxis in Gigafactory V2, then deploy them through a powered Robotaxi Service Center. Each vehicle serves five nearby customers.",
  ["x-orbital-compute"] = "[FactoryX] Orbital Compute researched. Build Orbital Compute Arrays on space platforms and return their high-volume AI Tokens to the planet.",
  ["x-planetary-energy-grid"] = "[FactoryX] Planetary Energy Grid researched. Build the 1 GW controller and supply AI Tokens, Megapacks, satellite infrastructure, capital, and grid segments.",
  ["x-kardashev-type-1"] = "[FactoryX] Kardashev Type I researched. Produce the final Planetary Grid Charge in a powered controller; completing its 1 GW charge cycle wins the game."
}

local function announce_research_completion(research)
  if not research or not research.force then
    return
  end
  local message = RESEARCH_COMPLETION_MESSAGES[research.name]
  if message then
    research.force.print(message)
  end
end

local ENTITY_PLACEMENT_MESSAGES = {
  ["x-gigafactory-building"] = "[FactoryX] First Gigafactory online. Select Premium EV, then supply Cars, Battery Packs, and Electric Drivetrains. Route the finished EV plus charger paperwork to a Sales Office.",
  ["x-gigafactory-v2"] = "[FactoryX] First Gigafactory V2 online. It runs twice as fast with 150% built-in productivity while drawing 30 MW. Select Mass-market EV; each sale still needs one EV Reservation.",
  [HIGH_DENSITY_SOLAR_ARRAY_NAME] = "[FactoryX] First High-density Solar Array online: 300 kW peak output. Scale generation before chargers, Gigafactories, and datacenters compete for power.",
  [MEGAPACK_NAME] = "[FactoryX] First Megapack online: 100 MJ storage with 5 MW charge and discharge. Pair it with daytime generation to stabilize FactoryX loads.",
  [TERRESTRIAL_DATACENTER_NAME] = "[FactoryX] First Terrestrial Datacenter online. Supply Dollars and select AI Token production: each 30-second cycle consumes 20 Dollars, draws 8 MW, and produces 20 AI Tokens.",
  [ROBOTAXI_SERVICE_CENTER_NAME] = "[FactoryX] Robotaxi Service Center online. Load up to 200 Robotaxis; its built-in V4 fleet charging draws 10 MW while Operate Robotaxis converts nearby customer service into recurring profit."
}

local function announce_first_entity_placement(entity)
  if not entity or not entity.valid or not entity.force then
    return
  end
  local message = ENTITY_PLACEMENT_MESSAGES[entity.name]
  if not message then
    return
  end
  local force_hints = first_entity_placement_hints()[entity.force.name] or {}
  first_entity_placement_hints()[entity.force.name] = force_hints
  if force_hints[entity.name] then
    return
  end
  force_hints[entity.name] = true
  entity.force.print(message)
end

local function force_has_gigafactory(force)
  for _, surface in pairs(game.surfaces) do
    if #surface.find_entities_filtered{name = {"x-gigafactory-building", "x-gigafactory-v2"}, force = force, limit = 1} > 0 then
      return true
    end
  end
  return false
end

local function unlock_gigafactory_logistics(force, announce)
  local technology = force and force.technologies and force.technologies[LOGISTIC_SYSTEM_TECH_NAME]
  if not technology or technology.researched then
    return false
  end
  technology.researched = true
  if announce then
    force.print("[FactoryX] Gigafactory logistics online: Logistic System researched. Requester, buffer, and active-provider chests are now available.")
  end
  return true
end

local function is_factoryx_name(name)
  return type(name) == "string" and string.sub(name, 1, 2) == "x-"
end

local function repair_researched_factoryx_unlocks(force)
  local repaired = {}
  if not force or not force.valid then
    return repaired
  end
  for technology_name, technology in pairs(force.technologies or {}) do
    if is_factoryx_name(technology_name) and technology.researched then
      for _, effect in pairs(technology.prototype.effects or {}) do
        if effect.type == "unlock-recipe" and is_factoryx_name(effect.recipe)
          and effect.recipe ~= ROBOTAXI_SALE_RECIPE then
          local recipe = force.recipes and force.recipes[effect.recipe]
          if recipe and not recipe.enabled then
            recipe.enabled = true
            table.insert(repaired, effect.recipe)
          end
        end
      end
    end
  end
  table.sort(repaired)
  return repaired
end

local function progression_integrity_status(force)
  local disabled = {}
  if not force or not force.valid then
    return {ok = false, disabled_recipes = disabled}
  end
  for technology_name, technology in pairs(force.technologies or {}) do
    if is_factoryx_name(technology_name) and technology.researched then
      for _, effect in pairs(technology.prototype.effects or {}) do
        if effect.type == "unlock-recipe" and is_factoryx_name(effect.recipe)
          and effect.recipe ~= ROBOTAXI_SALE_RECIPE then
          local recipe = force.recipes and force.recipes[effect.recipe]
          if recipe and not recipe.enabled then
            table.insert(disabled, effect.recipe)
          end
        end
      end
    end
  end
  if first_prototype_sale_unlocked(force) then
    local roadster_recipe = force.recipes and force.recipes[PROTOTYPE_ROADSTER_NAME]
    if roadster_recipe and not roadster_recipe.enabled then
      table.insert(disabled, PROTOTYPE_ROADSTER_NAME)
    end
  end
  table.sort(disabled)
  return {ok = #disabled == 0, disabled_recipes = disabled}
end

local function sync_force_unlocks(force)
  repair_researched_factoryx_unlocks(force)
  if force_has_gigafactory(force) then
    unlock_gigafactory_logistics(force, false)
  end
  local launch_technology = force.technologies and force.technologies[SMALL_ORBITAL_LAUNCH_TECH]
  if launch_technology and (launch_technology.researched or first_robotaxi_sales()[force.name]) then
    launch_technology.enabled = true
  end
  local v4_recipe = force.recipes and force.recipes["x-ev-charging-station-v4"]
  if v4_recipe then
    v4_recipe.enabled = researched(force, "x-autonomous-logistics")
  end
  if researched(force, "x-sales-office") then
    for _, recipe_name in pairs(SALES_OFFICE_INITIAL_RECIPES) do
      local recipe = force.recipes and force.recipes[recipe_name]
      if recipe then
        recipe.enabled = true
      end
    end
  end
  if force_has_first_prototype_sale_history(force) then
    unlock_roadster_sales(force)
  elseif first_prototype_sale_unlocked(force) then
    for _, recipe_name in pairs(FIRST_CUSTOMER_CHARGER_UNLOCK_RECIPES) do
      local recipe = force.recipes and force.recipes[recipe_name]
      if recipe then
        recipe.enabled = true
      end
    end
  end
  if force_has_first_premium_sale_history(force) then
    first_premium_ev_sales()[force.name] = true
  end
end

local function sync_all_force_unlocks()
  for _, force in pairs(game.forces) do
    sync_force_unlocks(force)
  end
end

local function trigger_victory(force)
  if not force or not force.valid then
    return
  end

  local victories = victory_forces()
  if victories[force.name] then
    return
  end
  victories[force.name] = true

  force.print("[FactoryX] Kardashev Type I achieved: the charged planetary energy grid is online.")
  game.set_game_state{
    game_finished = true,
    player_won = true,
    can_continue = true
  }
end

local function consume_grid_charge(entity)
  local inventory_id = crafter_output_inventory_id()
  if not inventory_id then
    return false
  end

  local inventory = entity.get_inventory(inventory_id)
  if not inventory or not inventory.valid then
    return false
  end

  if inventory.get_item_count(GRID_CHARGE_ITEM_NAME) == 0 then
    return false
  end

  inventory.remove{name = GRID_CHARGE_ITEM_NAME, count = 1}
  return true
end

local function finish_completed_grid_charges(force)
  if not force or not force.valid then
    return
  end

  local controllers = grid_controllers()
  for unit_number, controller in pairs(controllers) do
    if not controller.valid then
      controllers[unit_number] = nil
    elseif controller.force == force and consume_grid_charge(controller) then
      trigger_victory(force)
      return
    end
  end
end

function clear_office_buyer_reservation(office_unit_number)
  local reservations = office_buyer_reservations()
  local reservation = reservations[office_unit_number]
  if reservation then
    for _, unit_number in pairs(reservation.buyers or {}) do
      if buyer_reserved_by_unit()[unit_number] == office_unit_number then
        buyer_reserved_by_unit()[unit_number] = nil
      end
    end
  end
  reservations[office_unit_number] = nil
end

function office_has_all_sale_inputs(office, recipe)
  local inventory = office.get_inventory(crafter_input_inventory_id())
  if not inventory or not inventory.valid then
    return false
  end
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" and inventory.get_item_count(ingredient.name) < ingredient.amount then
      return false
    end
  end
  return true
end

function eligible_customer_buyers(office, needed)
  local buyers_by_settlement = {}
  local service = customer_service_for_force(office.force)
  local vehicle_summary = active_customer_vehicle_summary(office.force)
  local reserved_by_settlement = {}
  for unit_number, _ in pairs(buyer_reserved_by_unit()) do
    local home = customer_home_settlements()[unit_number]
    if home and home.market_force_name == office.force.name then
      reserved_by_settlement[home.settlement_key] = (reserved_by_settlement[home.settlement_key] or 0) + 1
    end
  end
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    local assigned_station = home and service.assignment_by_settlement_key[home.settlement_key]
    local config = assigned_station and station_config(assigned_station)
    if entity and entity.valid and entity.type == "unit"
      and entity.force.name == CUSTOMER_FORCE_NAME
      and home and home.market_force_name == office.force.name
      and service.operational_keys[home.settlement_key]
      and config
      and (vehicle_summary.by_settlement[home.settlement_key] or 0)
        + (reserved_by_settlement[home.settlement_key] or 0) < config.evs_per_stall
      and not customer_vehicle_owners()[unit_number]
      and not buyer_reserved_by_unit()[unit_number]
      and entity.surface == office.surface
      and within_radius(office, entity, SALES_OFFICE_CUSTOMER_RADIUS) then
      local key = home.settlement_key
      buyers_by_settlement[key] = buyers_by_settlement[key] or {}
      buyers_by_settlement[key][#buyers_by_settlement[key] + 1] = unit_number
    end
  end

  local pools = {}
  for key, units in pairs(buyers_by_settlement) do
    table.sort(units)
    pools[#pools + 1] = {
      key = key,
      units = units,
      load = (vehicle_summary.by_settlement[key] or 0) + (reserved_by_settlement[key] or 0)
    }
  end

  local buyers = {}
  while #buyers < needed do
    table.sort(pools, function(left, right)
      if left.load ~= right.load then
        return left.load < right.load
      end
      return left.key < right.key
    end)
    local pool
    for _, candidate in pairs(pools) do
      if #candidate.units > 0 then
        pool = candidate
        break
      end
    end
    if not pool then
      break
    end
    buyers[#buyers + 1] = table.remove(pool.units, 1)
    pool.load = pool.load + 1
  end
  return buyers
end

function reserve_office_buyers(office, recipe_name, sale)
  clear_office_buyer_reservation(office.unit_number)
  local buyers = eligible_customer_buyers(office, sale.vehicles)
  if #buyers < sale.vehicles then
    return false
  end
  office_buyer_reservations()[office.unit_number] = {
    recipe_name = recipe_name,
    buyers = buyers
  }
  for _, unit_number in pairs(buyers) do
    buyer_reserved_by_unit()[unit_number] = office.unit_number
  end
  return true
end

function sync_sales_office_buyers()
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME}) do
      if office.valid and office.unit_number then
        local recipe = office.get_recipe()
        local recipe_name = recipe and recipe.name
        local sale = recipe_name and CUSTOMER_EV_SALE_RECIPES[recipe_name]
        local reservation = office_buyer_reservations()[office.unit_number]
        if not sale then
          clear_office_buyer_reservation(office.unit_number)
          office.disabled_by_script = false
        else
          local valid_reservation = reservation and reservation.recipe_name == recipe_name
            and #reservation.buyers == sale.vehicles
          if valid_reservation then
            for _, unit_number in pairs(reservation.buyers) do
              local entity = customer_unit_registry()[unit_number]
              if not entity or not entity.valid or entity.force.name ~= CUSTOMER_FORCE_NAME
                or customer_vehicle_owners()[unit_number] then
                valid_reservation = false
                break
              end
            end
          end
          if not valid_reservation then
            if office_has_all_sale_inputs(office, recipe) or (office.crafting_progress or 0) > 0 then
              valid_reservation = reserve_office_buyers(office, recipe_name, sale)
            else
              clear_office_buyer_reservation(office.unit_number)
              office.disabled_by_script = false
              valid_reservation = nil
            end
          end
          if valid_reservation ~= nil then
            office.disabled_by_script = not valid_reservation
          end
        end
      end
    end
  end
end

function accelerate_consumer_ev_sales()
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME}) do
      local recipe = office.valid and office.get_recipe()
      local recipe_name = recipe and recipe.name
      local level = continuous_improvement_level(office.force, PREMIUM_AUDIO_TECH_NAME)
      if level > 0 and RESERVATION_RECIPES[recipe_name]
        and office.active and (office.crafting_progress or 0) > 0 then
        local bonus_progress = office.crafting_speed * 0.5 / recipe.energy * level * 0.05
        office.crafting_progress = math.min(0.999999, office.crafting_progress + bonus_progress)
      end
    end
  end
end

function robotaxi_audio_revenue_progress()
  storage.factoryx_robotaxi_audio_revenue_progress = storage.factoryx_robotaxi_audio_revenue_progress or {}
  return storage.factoryx_robotaxi_audio_revenue_progress
end

function award_robotaxi_audio_revenue(office, completed_crafts)
  local level = continuous_improvement_level(office.force, PREMIUM_AUDIO_TECH_NAME)
  if level <= 0 or completed_crafts <= 0 then
    return 0
  end
  local progress = robotaxi_audio_revenue_progress()
  local accumulated = (progress[office.unit_number] or 0) + completed_crafts * level * 0.05
  local whole_dollars = math.floor(accumulated)
  if whole_dollars <= 0 then
    progress[office.unit_number] = accumulated
    return 0
  end
  local inventory = office.get_inventory(crafter_output_inventory_id())
  local inserted = inventory and inventory.insert{name = DOLLAR_NAME, count = whole_dollars} or 0
  progress[office.unit_number] = accumulated - inserted
  if inserted > 0 then
    local statistics = office.force.get_item_production_statistics(office.surface)
    statistics.set_output_count(DOLLAR_NAME, statistics.get_output_count(DOLLAR_NAME) + inserted)
  end
  return inserted
end

function complete_reserved_vehicle_sale(office, recipe_name)
  local reservation = office_buyer_reservations()[office.unit_number]
  local sale = CUSTOMER_EV_SALE_RECIPES[recipe_name]
  if not reservation or not sale or reservation.recipe_name ~= recipe_name then
    return 0
  end
  local assigned = 0
  for _, unit_number in pairs(reservation.buyers) do
    local entity = customer_unit_registry()[unit_number]
    local home = customer_home_settlements()[unit_number]
    if entity and entity.valid and home and not customer_vehicle_owners()[unit_number] then
      customer_vehicle_owners()[unit_number] = {
        vehicle = sale.item,
        settlement_key = home.settlement_key,
        market_force_name = office.force.name
      }
      buyer_reserved_by_unit()[unit_number] = nil
      replace_customer_vehicle_entity(entity, customer_vehicle_owners()[unit_number])
      assigned = assigned + 1
    end
  end
  clear_office_buyer_reservation(office.unit_number)
  storage.factoryx_last_vehicle_sale_assignment = {
    recipe_name = recipe_name,
    assigned = assigned,
    tick = game.tick
  }
  return assigned
end

local function office_has_prototype_sale_output(office)
  local inventory_id = crafter_output_inventory_id()
  if not inventory_id then
    return false
  end

  local inventory = office.get_inventory(inventory_id)
  return inventory and inventory.valid and inventory.get_item_count(DOLLAR_NAME) > 0
end

local function check_first_prototype_sales()
  local products_by_unit = sales_office_products_finished()
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME}) do
      if office.valid and office.unit_number then
        local products = safe_products_finished(office)
        local previous_products = products_by_unit[office.unit_number] or products
        local recipe_name = current_recipe_name(office)
        local completed_crafts = math.max(0, products - previous_products)
        if completed_crafts > 0 then
          complete_reserved_vehicle_sale(office, recipe_name)
          record_customer_ev_sales(office.force, recipe_name, completed_crafts)
        end
        if recipe_name == FIRST_PROTOTYPE_SALE_RECIPE then
          if office_has_prototype_sale_output(office) or completed_crafts > 0 then
            unlock_roadster_sales(office.force)
            announce_first_ev_production_line_hint(office.force)
          end
        elseif recipe_name == PREMIUM_EV_SALE_RECIPE and completed_crafts > 0 then
          announce_first_premium_ev_sale(office.force)
        elseif recipe_name == MASS_MARKET_EV_SALE_RECIPE and completed_crafts > 0 then
          announce_first_mass_market_ev_sale(office.force)
        elseif recipe_name == ROBOTAXI_SALE_RECIPE and completed_crafts > 0 then
          award_robotaxi_audio_revenue(office, completed_crafts)
          announce_first_robotaxi_service(office.force)
        end
        products_by_unit[office.unit_number] = products
      end
    end
  end
end

local function count_item_produced(force, item_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_item_production_statistics(surface)
    count = count + (statistics.output_counts[item_name] or 0)
  end
  return count
end

local function count_sales_office_customer_settlements(force)
  local customers = customer_force_if_exists()
  if not customers then
    return 0
  end
  local covered = {}
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = SALES_OFFICE_NAME, force = force}) do
      local area = area_around(office.position, SALES_OFFICE_CUSTOMER_RADIUS)
      scan_biter_customer_entities(surface, customers, area, function(entity)
        if BITER_SETTLEMENT_NAMES[entity.name]
          and within_radius(office, entity, SALES_OFFICE_CUSTOMER_RADIUS) then
          covered[settlement_key(surface, entity)] = true
        end
      end)
    end
  end
  local count = 0
  for _ in pairs(covered) do
    count = count + 1
  end
  return count
end

local function count_customer_settlements_near_office(office)
  local customers = customer_force_if_exists()
  if not customers or not office or not office.valid then
    return 0
  end
  local count = 0
  local area = area_around(office.position, SALES_OFFICE_CUSTOMER_RADIUS)
  scan_biter_customer_entities(office.surface, customers, area, function(entity)
    if BITER_SETTLEMENT_NAMES[entity.name]
      and within_radius(office, entity, SALES_OFFICE_CUSTOMER_RADIUS) then
      count = count + 1
    end
  end)
  return count
end

local function progress_snapshot(force)
  local market = add_reservation_output_status(biter_customer_market_summary(force), force)
  local improvements = continuous_improvement_levels(force)
  local first_sale_complete = first_ev_production_line_hints()[force.name] == true
    or researched(force, "x-premium-ev-program")
  local premium_sale_complete = first_premium_ev_sales()[force.name] == true
    or researched(force, "x-capital-scaling")
  local terrestrial_ai = ai_efficiency_track_status(force, "terrestrial")
  return {
    sales_office_researched = researched(force, "x-sales-office"),
    ev_production_researched = researched(force, "x-premium-ev-program"),
    charging_network_researched = researched(force, "x-ev-charging-network"),
    mass_market_researched = researched(force, "x-capital-scaling"),
    energy_products_researched = researched(force, "x-energy-products"),
    terrestrial_ai_researched = researched(force, "x-terrestrial-ai"),
    autonomous_logistics_researched = researched(force, "x-autonomous-logistics"),
    small_launch_researched = researched(force, "x-small-orbital-launch"),
    reusable_launch_researched = researched(force, "x-reusable-launch"),
    satellite_constellation_researched = researched(force, "x-satellite-constellation"),
    orbital_compute_researched = researched(force, "x-orbital-compute"),
    planetary_grid_researched = researched(force, "x-planetary-energy-grid"),
    kardashev_researched = researched(force, "x-kardashev-type-1"),
    first_sale_complete = first_sale_complete,
    premium_sale_complete = premium_sale_complete,
    mass_market_sale_complete = first_mass_market_ev_sales()[force.name] == true,
    robotaxi_sale_complete = first_robotaxi_sales()[force.name] == true,
    sales_offices = count_entities(force, SALES_OFFICE_NAME),
    customer_settlements = count_sales_office_customer_settlements(force),
    powered_stations = market.powered_stations,
    charging_capacity = market.charging_stall_capacity,
    active_stalls = market.active_customer_stalls,
    customer_ev_fleet = market.customer_ev_fleet,
    customer_ev_sales_lifetime = lifetime_customer_ev_sales_size(force),
    friendly_settlements = market.friendly_settlements,
    angry_settlements = market.angry_settlements,
    stranded_evs = market.stranded_evs,
    grown_colonies = market.grown_colonies,
    reservations_per_minute = market.reservations_per_minute,
    reservation_stock = market.charger_reservation_stock,
    gigafactories = count_entities(force, "x-gigafactory-building"),
    gigafactories_v2 = count_entities(force, "x-gigafactory-v2"),
    chargers_v2 = count_entities(force, "x-ev-charging-station-v2"),
    chargers_v3 = count_entities(force, "x-ev-charging-station-v3"),
    chargers_v4 = count_entities(force, "x-ev-charging-station-v4"),
    solar_arrays = count_entities(force, HIGH_DENSITY_SOLAR_ARRAY_NAME),
    megapacks = count_entities(force, MEGAPACK_NAME),
    datacenters = count_entities(force, TERRESTRIAL_DATACENTER_NAME),
    ai_tokens_produced = count_item_produced(force, "x-ai-token"),
    terrestrial_ai_tokens_generated = terrestrial_ai.generated,
    terrestrial_ai_efficiency_level = terrestrial_ai.researched_level,
    terrestrial_ai_next_threshold = terrestrial_ai.next_threshold,
    dollars_produced = count_item_produced(force, DOLLAR_NAME),
    prototype_evs_produced = count_item_produced(force, PROTOTYPE_ROADSTER_NAME),
    premium_evs_produced = count_item_produced(force, PREMIUM_EV_NAME),
    mass_market_evs_produced = count_item_produced(force, "x-mass-market-ev"),
    robotaxi_fleets_produced = count_item_produced(force, "x-robotaxi-fleet"),
    robotaxi_service_centers = count_entities(force, ROBOTAXI_SERVICE_CENTER_NAME),
    supercharging_level = improvements.supercharging,
    battery_level = improvements.battery,
    audio_level = improvements.audio,
    referral_level = improvements.referrals,
    victory = victory_forces()[force.name] == true
  }
end

local function current_progress_objective(snapshot)
  if not snapshot.sales_office_researched then
    return "Customer discovery", "Research Sales Office.", "This unlocks the Sales Office, V1 charger, and Sell hopes and dreams."
  elseif snapshot.sales_offices == 0 then
    return "Customer discovery", "Build a Sales Office near enemy spawners.", "Spawners within 128 tiles become customer settlements; worms remain hostile."
  elseif snapshot.customer_settlements == 0 then
    return "Customer discovery", "Serve a biter settlement with both Sales Office and powered charger coverage.", "The Sales Office market radius is 128 tiles; the settlement must also be inside a powered charger's local radius."
  elseif snapshot.powered_stations == 0 then
    return "Customer discovery", "Build and power a V1 charger near a customer settlement.", "The charger must be within 18 tiles of a real electric pole and within 64 tiles of the customer spawner."
  elseif snapshot.prototype_evs_produced == 0 then
    return "Prototype revenue", "Craft the first Prototype Roadster.", "A mobile customer with a $ marker must be available before the Sales Office can complete the sale."
  elseif not snapshot.first_sale_complete then
    if snapshot.reservation_stock == 0 then
      return "Prototype revenue", "Wait for the first EV Reservation at the charger.", "A powered customer site with an available mobile buyer prints initial demand paperwork even before its first vehicle sale."
    end
    return "Prototype revenue", "Run Sell hopes and dreams.", "Supply one Prototype Roadster and one EV Reservation, then remove the Dollars after the 120-second sale."
  elseif not snapshot.ev_production_researched then
    return "Premium production", "Research EV Production Line.", "Invest 250 cycles of red, green, blue science, and Dollars; Energy Products unlocks the factory itself."
  elseif not snapshot.energy_products_researched then
    return "Energy products", "Research Energy Products.", "Invest 500 cycles through production science plus Dollars to unlock Gigafactory construction, High-density Solar Arrays, and Megapacks."
  elseif snapshot.gigafactories == 0 and snapshot.gigafactories_v2 == 0 then
    return "Premium production", "Construct the first Gigafactory.", "Build 10 Gigafactory Modules, add 2 Substations, then place the 9x9, 20 MW factory."
  elseif not snapshot.premium_sale_complete then
    return "Premium production", "Produce and sell a Premium EV.", "Select Premium EV in the Gigafactory and route the vehicle plus one EV Reservation to a Sales Office."
  elseif not snapshot.charging_network_researched then
    return "Charging network", "Research EV Charging Network.", "Invest 300 cycles of red, green, blue science, and Dollars to unlock the eight-stall V2 charger."
  elseif snapshot.chargers_v2 == 0 then
    return "Charging network", "Craft and place a V2 charger.", "In an Assembling Machine 2 or 3, craft it from 1 V1 charger, 2 Substations, 20 Processing Units, and 20 Dollars."
  elseif not snapshot.mass_market_researched then
    return "Mass-market scale", "Research Mass-market EV Production.", "Invest 1,000 cycles through purple and yellow science plus Dollars to unlock Gigacast, Gigafactory V2, mass-market EVs, and V3 charging."
  elseif snapshot.gigafactories_v2 == 0 then
    return "Mass-market scale", "Upgrade a Gigafactory to V2.", "Craft V2 in an Assembling Machine or Gigafactory from 1 Gigafactory item, 1 Gigacast, and 100 Dollars, then place it directly over a V1."
  elseif not snapshot.mass_market_sale_complete then
    return "Mass-market scale", "Produce and sell the first Mass-market EV.", "Gigafactory V2 is faster and more productive; each 5-second sale consumes one EV Reservation and returns 1 Dollar of profit."
  elseif snapshot.chargers_v3 == 0 then
    return "Supercharging", "Craft and place a V3 Supercharger.", "Craft it from 1 V2 charger, 4 Substations, 40 Processing Units, and 75 Dollars. Its 12 occupied stalls can draw 3 MW."
  elseif snapshot.solar_arrays == 0 or snapshot.megapacks == 0 then
    return "Energy products", "Build a High-density Solar Array and a Megapack.", "Manufacture both in either Gigafactory tier and place them on the grid."
  elseif not snapshot.terrestrial_ai_researched then
    return "Terrestrial AI", "Research Terrestrial AI.", "Unlock Datacenter Racks, Autonomy Computers, and an 8 MW Terrestrial Datacenter that converts electricity into AI Tokens."
  elseif snapshot.datacenters == 0 then
    return "Terrestrial AI", "Build a Terrestrial Datacenter.", "Combine 4 Datacenter Racks, a Gigafactory Module, 4 Substations, and 100 Refined Concrete."
  elseif snapshot.ai_tokens_produced < 1000 then
    return "Terrestrial AI", "Generate 1,000 AI Tokens.", "Supply 20 Dollars per cycle; one 8 MW datacenter produces 20 tokens every 30 seconds."
  elseif not snapshot.autonomous_logistics_researched then
    return "Autonomy", "Research Autonomous Logistics.", "Invest 1,000 cycles through utility science plus 1,000 AI Tokens and 1,000 Dollars to unlock Robotaxi Fleets."
  elseif snapshot.robotaxi_fleets_produced == 0 then
    return "Autonomy", "Build the first Robotaxi Fleet in Gigafactory V2.", "Commit 4 Mass-market EVs, 4 Autonomy Computers, and 100 Dollars."
  elseif snapshot.chargers_v4 == 0 then
    return "Supercharging", "Craft and place a solar-canopy V4 Supercharger.", "Craft it from 1 V3 Supercharger, 4 High-density Solar Arrays, 4 Megapacks, and 200 Dollars. Twenty occupied stalls can draw 10 MW."
  elseif snapshot.robotaxi_service_centers == 0 then
    return "Autonomy", "Build a Robotaxi Service Center.", "Combine a V4 Supercharger, 4 Roboports, 50 Processing Units, and 200 Dollars. The center stores 200 Robotaxis and draws 10 MW."
  elseif not snapshot.robotaxi_sale_complete then
    return "Autonomy", "Operate the Robotaxi service.", "Load Robotaxis into the 40-slot fleet inventory. Each vehicle serves five nearby mobile customers; recurring profit unlocks launch services."
  elseif not snapshot.small_launch_researched then
    return "Launch services", "Research Small Orbital Launch.", "Invest 1,000 cycles through utility science plus Dollars; the terrestrial business is now ready for launch services."
  elseif not snapshot.reusable_launch_researched then
    return "Launch services", "Research Reusable Launch.", "Invest 1,500 cycles through space science plus Dollars, then build boosters and repeatable launch services."
  elseif not snapshot.satellite_constellation_researched then
    return "Orbital infrastructure", "Research Satellite Constellation.", "Invest 2,000 cycles through space science plus Dollars to build the satellite and ground network required by orbital compute."
  elseif not snapshot.orbital_compute_researched then
    return "Orbital compute", "Research Orbital Compute.", "Invest 2,000 cycles through electromagnetic and space science plus AI Tokens and Dollars."
  elseif not snapshot.planetary_grid_researched then
    return "Planetary grid", "Research Planetary Energy Grid.", "Invest 2,500 cycles of all pre-Promethium science plus AI Tokens and Dollars; prepare a 1 GW supply."
  elseif not snapshot.kardashev_researched then
    return "Planetary grid", "Research Kardashev Type I and stockpile Planetary Grid Segments.", "The research consumes 5,000 cycles of all pre-Promethium science plus AI Tokens; Grid Segments remain physical charge inputs."
  elseif not snapshot.victory then
    return "Kardashev Type I", "Complete the Planetary Grid Charge.", "Keep the Planetary Energy Grid Controller powered through its final 1 GW charge cycle."
  end
  return "Kardashev Type I", "Planetary energy grid online.", "FactoryX victory achieved."
end

local function progress_stages(snapshot)
  return {
    {name = "Customer market", complete = snapshot.customer_settlements > 0 and snapshot.powered_stations > 0},
    {name = "Prototype revenue", complete = snapshot.first_sale_complete},
    {name = "Premium production", complete = snapshot.premium_sale_complete},
    {name = "Charging network", complete = snapshot.charging_network_researched and snapshot.chargers_v2 > 0},
    {name = "Mass-market scale", complete = snapshot.mass_market_sale_complete},
    {name = "Supercharging", complete = snapshot.chargers_v3 > 0 and snapshot.chargers_v4 > 0},
    {name = "Energy products", complete = snapshot.energy_products_researched and snapshot.solar_arrays > 0 and snapshot.megapacks > 0},
    {name = "AI and autonomy", complete = snapshot.autonomous_logistics_researched and snapshot.robotaxi_sale_complete},
    {name = "Orbital compute", complete = snapshot.orbital_compute_researched},
    {name = "Planetary grid", complete = snapshot.victory}
  }
end

local function add_section_heading(parent, caption)
  parent.add{type = "label", caption = caption, style = "bold_label"}
end

local function add_progress_metric(table_element, name, value, value_name)
  table_element.add{type = "label", caption = name}
  local value_label = table_element.add{
    type = "label",
    name = value_name,
    caption = value
  }
  value_label.style.horizontal_align = "right"
end

local function refresh_progress_panel(player)
  if not player or not player.valid then
    return
  end
  local panel = player.gui.screen[PROGRESS_PANEL_NAME]
  if not panel then
    return
  end
  local old_content = panel[PROGRESS_CONTENT_NAME]
  if old_content then
    old_content.destroy()
  end

  local snapshot = progress_snapshot(player.force)
  local stage, objective, detail = current_progress_objective(snapshot)
  local content = panel.add{
    type = "flow",
    name = PROGRESS_CONTENT_NAME,
    direction = "vertical"
  }

  local stage_label = content.add{type = "label", caption = stage, style = "bold_label"}
  stage_label.style.font_color = {r = 1.0, g = 0.72, b = 0.2}
  local objective_label = content.add{type = "label", caption = objective, single_line = false}
  objective_label.style.font = "default-bold"
  objective_label.style.maximal_width = 440
  local detail_label = content.add{type = "label", caption = detail, single_line = false}
  detail_label.style.maximal_width = 440
  content.add{type = "line"}

  add_section_heading(content, "Market and throughput")
  local metrics = content.add{type = "table", column_count = 2}
  metrics.style.horizontally_stretchable = true
  add_progress_metric(
    metrics,
    "Dollars produced",
    tostring(snapshot.dollars_produced),
    "factoryx_dollars_produced_value"
  )
  add_progress_metric(metrics, "Customer settlements", tostring(snapshot.customer_settlements))
  add_progress_metric(metrics, "Charging stalls", string.format("%d / %d active", snapshot.active_stalls, snapshot.charging_capacity))
  add_progress_metric(metrics, "Active customer vehicles", tostring(snapshot.customer_ev_fleet))
  add_progress_metric(metrics, "Lifetime EV sales", tostring(snapshot.customer_ev_sales_lifetime))
  add_progress_metric(metrics, "Reservations at chargers", tostring(snapshot.reservation_stock))
  add_progress_metric(metrics, "Reservation rate", string.format("%d / min", snapshot.reservations_per_minute))
  add_progress_metric(metrics, "AI Tokens produced", tostring(snapshot.ai_tokens_produced))
  add_progress_metric(metrics, "Terrestrial AI tracked", tostring(snapshot.terrestrial_ai_tokens_generated))
  add_progress_metric(metrics, "Robotaxi Fleets", tostring(snapshot.robotaxi_fleets_produced))
  add_progress_metric(metrics, "Robotaxi Service Centers", tostring(snapshot.robotaxi_service_centers))

  content.add{type = "line"}
  add_section_heading(content, "Infrastructure")
  local infrastructure = content.add{type = "table", column_count = 2}
  infrastructure.style.horizontally_stretchable = true
  add_progress_metric(infrastructure, "Sales Offices", tostring(snapshot.sales_offices))
  add_progress_metric(infrastructure, "Gigafactories", string.format("%d V1, %d V2", snapshot.gigafactories, snapshot.gigafactories_v2))
  add_progress_metric(infrastructure, "Energy Products", string.format("%d solar, %d Megapacks", snapshot.solar_arrays, snapshot.megapacks))
  add_progress_metric(infrastructure, "Terrestrial Datacenters", tostring(snapshot.datacenters))

  content.add{type = "line"}
  add_section_heading(content, "Continuous improvement")
  local improvement_table = content.add{type = "table", column_count = 2}
  improvement_table.style.horizontally_stretchable = true
  add_progress_metric(improvement_table, "Supercharging electronics", "Level " .. snapshot.supercharging_level)
  add_progress_metric(improvement_table, "Long-range battery", "Level " .. snapshot.battery_level)
  add_progress_metric(improvement_table, "Premium audio", "Level " .. snapshot.audio_level)
  add_progress_metric(improvement_table, "Customer referrals", "Level " .. snapshot.referral_level)
  add_progress_metric(
    improvement_table,
    "Terrestrial AI efficiency",
    snapshot.terrestrial_ai_next_threshold
      and string.format("Level %d; next at %d", snapshot.terrestrial_ai_efficiency_level, snapshot.terrestrial_ai_next_threshold)
      or string.format("Level %d; terrestrial ceiling", snapshot.terrestrial_ai_efficiency_level)
  )

  content.add{type = "line"}
  add_section_heading(content, "Progression")
  local stage_table = content.add{type = "table", column_count = 2}
  for _, stage_info in pairs(progress_stages(snapshot)) do
    local status = stage_table.add{
      type = "label",
      caption = stage_info.complete and "DONE" or "NEXT"
    }
    status.style.font_color = stage_info.complete
      and {r = 0.3, g = 0.9, b = 0.4}
      or {r = 0.85, g = 0.85, b = 0.85}
    stage_table.add{type = "label", caption = stage_info.name}
    if not stage_info.complete then
      break
    end
  end
end

local function open_progress_panel(player)
  if not player or not player.valid then
    return
  end
  local existing = player.gui.screen[PROGRESS_PANEL_NAME]
  if existing then
    existing.destroy()
    return
  end
  local panel = player.gui.screen.add{
    type = "frame",
    name = PROGRESS_PANEL_NAME,
    direction = "vertical"
  }
  panel.style.width = 480
  panel.auto_center = true
  local titlebar = panel.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = panel
  titlebar.add{type = "label", caption = "FactoryX Progress", style = "frame_title"}
  local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.drag_target = panel
  titlebar.add{
    type = "sprite-button",
    name = PROGRESS_CLOSE_BUTTON_NAME,
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = "Close"
  }
  refresh_progress_panel(player)
end

local function close_entity_info_panel(player)
  if not player or not player.valid then
    return
  end
  local panel = player.gui.left[ENTITY_INFO_PANEL_NAME]
  if panel then
    panel.destroy()
  end
end

local function is_factoryx_manufacturer(entity)
  return entity and entity.valid
    and (entity.name == SALES_OFFICE_NAME
      or entity.name == ROBOTAXI_SERVICE_CENTER_NAME
      or GIGAFACTORY_CONFIGS[entity.name] ~= nil)
end

local function entity_status_text(entity)
  if entity.name == SALES_OFFICE_NAME and entity.disabled_by_script then
    return "Waiting for mobile buyers"
  end
  local status = entity.status
  if status == defines.entity_status.working then
    return "Working"
  elseif status == defines.entity_status.no_power then
    return "No power"
  elseif status == defines.entity_status.low_power then
    return "Low power"
  elseif status == defines.entity_status.no_recipe then
    return "No recipe selected"
  elseif status == defines.entity_status.no_ingredients
    or status == defines.entity_status.item_ingredient_shortage
    or status == defines.entity_status.fluid_ingredient_shortage then
    return "Missing inputs"
  elseif status == defines.entity_status.full_output then
    return "Output blocked"
  elseif status == defines.entity_status.disabled_by_control_behavior then
    return "Disabled by circuit condition"
  end
  return "Idle"
end

local function add_item_inventory_row(parent, item_name, current, required)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.add{type = "sprite", sprite = "item/" .. item_name}
  local prototype = prototypes.item[item_name]
  local name = prototype and prototype.localised_name or item_name
  row.add{type = "label", caption = {"", name, ": ", current, " / ", required}}
end

local function recipe_missing_item(entity, recipe)
  local inventory_id = crafter_input_inventory_id()
  local inventory = inventory_id and entity.get_inventory(inventory_id)
  if not inventory or not inventory.valid then
    return nil
  end
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      local current = inventory.get_item_count(ingredient.name)
      if current < ingredient.amount then
        return ingredient.name, current, ingredient.amount
      end
    end
  end
  return nil
end

local function show_manufacturer_info_panel(player, entity)
  if not player or not player.valid then
    return
  end
  close_entity_info_panel(player)
  if not is_factoryx_manufacturer(entity) then
    return
  end

  local panel = player.gui.left.add{
    type = "frame",
    name = ENTITY_INFO_PANEL_NAME,
    caption = {"", "FactoryX ", entity.prototype.localised_name},
    direction = "vertical"
  }
  panel.style.width = 380
  add_station_info_label(panel, "State: " .. entity_status_text(entity))

  if entity.name == ROBOTAXI_SERVICE_CENTER_NAME then
    local snapshot = robotaxi_service_snapshot(entity)
    add_station_info_label(panel, string.format(
      "Fleet: %d / 200 Robotaxis; %d allocated",
      snapshot.stored,
      snapshot.allocated
    ))
    add_station_info_label(panel, string.format(
      "Customers: %d / %d served within %d tiles",
      snapshot.served,
      snapshot.customers,
      ROBOTAXI_SERVICE_RADIUS
    ))
    add_station_info_label(panel, string.format(
      "Built-in V4 charging: %.0f%% power; rated demand 10 MW",
      snapshot.power_factor * 100
    ))
    add_station_info_label(panel, string.format(
      "Profit: %.2f Dollars/min; %.2f pending; %d lifetime Dollars",
      snapshot.revenue_per_minute,
      snapshot.revenue_progress,
      snapshot.lifetime_dollars
    ))
    add_station_info_label(panel, string.format(
      "Fleet attrition: %.1f%% toward next replacement; %d vehicles retired",
      snapshot.attrition_progress * 100,
      snapshot.vehicles_retired
    ))
    add_station_info_label(panel, "One Robotaxi serves five customers. Premium Audio increases trip revenue.")
    if snapshot.stored == 0 then
      add_station_info_label(panel, "Next: deliver Robotaxis to the 40-slot fleet inventory.")
    elseif snapshot.customers == 0 then
      add_station_info_label(panel, "Blocked: no mobile biter customers are inside service coverage.")
    elseif snapshot.power_factor == 0 then
      add_station_info_label(panel, "Blocked: connect and supply the 10 MW fleet charger load.")
    else
      add_station_info_label(panel, "Operating: keep the fleet stocked, power stable, and Dollar output clear.")
    end
    return
  end

  if entity.name == SALES_OFFICE_NAME then
    add_station_info_label(panel, string.format(
      "Customer settlements in office coverage: %d",
      count_customer_settlements_near_office(entity)
    ))
  else
    local config = GIGAFACTORY_CONFIGS[entity.name]
    add_station_info_label(panel, "Rated demand: " .. config.power)
    if config.productivity then
      add_station_info_label(panel, config.productivity)
    end
    if entity.name == TERRESTRIAL_DATACENTER_NAME then
      local status = ai_efficiency_track_status(entity.force, "terrestrial")
      add_station_info_label(panel, "Capital burn: 20 Dollars per 30-second cycle (40 Dollars/minute at full speed)")
      add_station_info_label(panel, string.format(
        "AI output: %g Tokens/cycle (%g/minute at full power)",
        status.tokens_per_cycle,
        status.tokens_per_cycle * 2
      ))
      add_station_info_label(panel, string.format(
        "Terrestrial production tracked: %d AI Tokens",
        status.generated
      ))
      if status.next_threshold then
        add_station_info_label(panel, string.format(
          "Efficiency: level %d/%d (+%d%%); next research unlocks at %d tracked Tokens",
          status.researched_level,
          status.maximum_level,
          status.researched_level * 10,
          status.next_threshold
        ))
      else
        add_station_info_label(panel, string.format(
          "Efficiency: level %d/%d (+%d%%); terrestrial ceiling reached",
          status.researched_level,
          status.maximum_level,
          status.researched_level * 10
        ))
      end
    end
  end

  local recipe = entity.get_recipe()
  if not recipe then
    local config = GIGAFACTORY_CONFIGS[entity.name]
    local next_step = entity.name == SALES_OFFICE_NAME
      and "Next: select the available sales contract for the product you are supplying."
      or config.recipe_prompt
      or "Next: select " .. config.default_product .. ", an Energy Product, or a vertically integrated component recipe."
    add_station_info_label(panel, "Recipe: none selected")
    add_station_info_label(panel, next_step)
    return
  end

  add_station_info_label(panel, {"", "Recipe: ", recipe.localised_name})
  if entity.name == SALES_OFFICE_NAME and CUSTOMER_EV_SALE_RECIPES[recipe.name] then
    local buyer_reservation = office_buyer_reservations()[entity.unit_number]
    local reserved = buyer_reservation and #buyer_reservation.buyers or 0
    add_station_info_label(panel, string.format(
      "Reserved mobile buyers: %d / %d",
      reserved,
      CUSTOMER_EV_SALE_RECIPES[recipe.name].vehicles
    ))
  end
  add_station_info_label(panel, string.format("Cycle progress: %d%%", math.floor((entity.crafting_progress or 0) * 100)))
  add_section_heading(panel, "Inputs")
  local input_inventory = entity.get_inventory(crafter_input_inventory_id())
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      local current = input_inventory and input_inventory.get_item_count(ingredient.name) or 0
      add_item_inventory_row(panel, ingredient.name, current, ingredient.amount)
    end
  end

  add_section_heading(panel, "Outputs")
  local output_inventory = entity.get_inventory(crafter_output_inventory_id())
  for _, product in pairs(recipe.products) do
    if product.type == "item" then
      local amount = product.amount or product.amount_min or 1
      local current = output_inventory and output_inventory.get_item_count(product.name) or 0
      add_item_inventory_row(panel, product.name, current, amount)
    end
  end

  local missing_name, current, required = recipe_missing_item(entity, recipe)
  local next_step
  if entity.status == defines.entity_status.no_power or entity.status == defines.entity_status.low_power then
    next_step = "Blocked: restore electric power to this machine."
  elseif entity.status == defines.entity_status.full_output then
    next_step = entity.name == SALES_OFFICE_NAME
      and "Blocked: Dollar output is full. Remove Dollars; sales and EV Reservation consumption are paused."
      or "Blocked: remove finished products from the output inventory."
  elseif entity.name == SALES_OFFICE_NAME and entity.disabled_by_script then
    next_step = "Blocked: no eligible mobile customer is ready to buy this vehicle. Expand powered customer coverage."
  elseif missing_name then
    local item = prototypes.item[missing_name]
    local display_name = item and item.localised_name or missing_name
    next_step = {"", "Blocked: deliver ", display_name, " (", current, " / ", required, ")."}
  elseif entity.status == defines.entity_status.working then
    next_step = "Running: keep inputs supplied and clear the output."
  else
    next_step = "Ready: this recipe will start when all required inputs and power are available."
  end
  add_station_info_label(panel, next_step)
end

local function is_customer_settlement_entity(entity)
  return entity and entity.valid and entity.type == "unit-spawner"
    and BITER_SETTLEMENT_NAMES[entity.name] == true
end

local function show_customer_settlement_info_panel(player, settlement)
  if not player or not player.valid then
    return
  end
  close_entity_info_panel(player)
  if not is_customer_settlement_entity(settlement) then
    return
  end

  local force = player.force
  local key = settlement_key(settlement.surface, settlement)
  local offices = force_sales_offices(force)
  local sales_covered = position_has_sales_coverage(settlement.surface, settlement.position, offices)
  local service = customer_service_for_force(force)
  local assigned_station = service.assignment_by_settlement_key[key]
  local friendly = service.served_keys[key] == true
  local angry = service.angry_keys[key] == true
  local operational = service.operational_keys[key] == true
  local vehicle_summary = active_customer_vehicle_summary(force)
  local settlement_vehicles = vehicle_summary.by_settlement[key] or 0
  local panel = player.gui.left.add{
    type = "frame",
    name = ENTITY_INFO_PANEL_NAME,
    caption = "FactoryX Customer Settlement",
    direction = "vertical"
  }
  panel.style.width = 380

  add_station_info_label(panel, "Status: " .. (friendly and "customer" or "hostile"))
  add_station_info_label(panel, "Sales Office coverage: " .. (sales_covered and "yes" or "no"))
  add_station_info_label(panel, string.format("Active vehicles at this settlement: %d", settlement_vehicles))
  add_station_info_label(panel, string.format("Active customer vehicles network-wide: %d", vehicle_summary.total))
  add_station_info_label(panel, string.format("Network vehicle capacity: %d", service.supported_ev_capacity))

  if assigned_station and assigned_station.valid then
    local config = station_config(assigned_station)
    local assignment = service.assignments[assigned_station.unit_number]
    local assigned_count = assignment and #assignment.settlements or 0
    local allocations = calculate_station_utilization(force)
    local active_stalls = active_station_stalls(assigned_station, allocations)
    add_station_info_label(panel, "Assigned charger: " .. config.display_name)
    add_station_info_label(panel, string.format(
      "Charger stalls: %d active, %d settlement slots free, %d total",
      active_stalls,
      math.max(0, config.stalls - assigned_count),
      config.stalls
    ))
    add_station_info_label(panel, string.format("This stall supports %d sold EVs", config.evs_per_stall))
    add_station_info_label(panel, "Charger grid: " .. (station_has_grid_access(assigned_station) and "connected" or "not connected"))
  else
    add_station_info_label(panel, "Assigned charger: none")
  end

  local reason
  if friendly and operational then
    reason = "Customer status: served by both market and powered charging coverage."
  elseif friendly then
    reason = "Customer status: charging is disrupted, but this settlement is still friendly during its patience period."
  elseif angry then
    reason = string.format(
      "Hostile reason: %d sold EVs exceed reachable charging capacity. Add powered stalls to restore service.",
      service.stranded_evs
    )
  elseif not sales_covered then
    reason = string.format(
      "Hostile reason: outside the %d-tile Sales Office market radius.",
      SALES_OFFICE_CUSTOMER_RADIUS
    )
  elseif not assigned_station then
    reason = "Hostile reason: no reachable powered charger has a free settlement stall."
  else
    reason = "Hostile reason: charging service is not currently available."
  end
  add_station_info_label(panel, reason)
end

local function refresh_station_power_state(station, allocations)
  if not is_station(station) then
    return false
  end
  if station_has_grid_access(station) then
    ensure_station_grid_connection(station)
    ensure_station_power_sinks(station, allocations and allocations[station.unit_number] or 0)
    return true
  end
  remove_station_grid_connection(station)
  remove_station_power_sink(station)
  return false
end

local function update_station_alerts(station)
  if not is_station(station) then
    return
  end
  local powered = station_has_grid_access(station)
  for _, player in pairs(game.connected_players) do
    if player.valid and player.surface == station.surface and player.force == station.force then
      player.remove_alert{
        entity = station,
        type = defines.alert_type.custom
      }
      if not powered then
        player.add_custom_alert(
          station,
          {type = "item", name = station.name},
          {"", station.prototype.localised_name, " is not connected to power."},
          true
        )
      end
    end
  end
end

local function handle_station_built(entity, event)
  if not is_station(entity) then
    return
  end

  station_reservation_inventory(entity)
  local config = station_config(entity)
  local powered = refresh_station_power_state(entity)
  local covered_settlements = count_biter_settlements_near_station(entity)
  local hostile_settlements = count_hostile_biter_settlements_near_station(entity)
  local message
  if not powered then
    message = "[FactoryX] " .. config.display_name .. " placed. Connect it within 18 tiles of your electric grid before it can create biter customer demand."
  elseif covered_settlements > 0 then
    local active_stalls = active_station_stalls(entity)
    unlock_roadster_sales(entity.force)
    message = string.format(
      "[FactoryX] %s online: %d/%d stalls active from %d covered biter customer settlements. %s",
      config.display_name,
      active_stalls,
      config.stalls,
      covered_settlements,
      station_next_step(entity, covered_settlements, hostile_settlements, #find_sales_offices(entity.force))
    )
  else
    if hostile_settlements > 0 then
      message = string.format(
        "[FactoryX] %s online, but %d nearby spawners are still hostile. Put a Sales Office within %d tiles to convert them into customers.",
        config.display_name,
        hostile_settlements,
        SALES_OFFICE_CUSTOMER_RADIUS
      )
    else
      message = string.format("[FactoryX] %s online, but no Sales Office-converted customer settlements are within %d tiles.", config.display_name, config.customer_radius)
    end
  end
  local player = event and event.player_index and game.get_player(event.player_index)
  if player and player.valid then
    player.print(message)
    show_station_info_panel(player, entity)
  end
  update_station_alerts(entity)
end

local function sync_biter_customer_diplomacy()
  if not biter_customer_mode_enabled() then
    return
  end

  local enemy = game.forces.enemy
  local customers = customer_force()

  for _, force in pairs(game.forces) do
    if player_market_force(force) then
      if enemy then
        force.set_cease_fire(enemy, false)
        enemy.set_cease_fire(force, false)
      end
      force.set_cease_fire(customers, true)
      customers.set_cease_fire(force, true)
      force.set_friend(customers, true)
      customers.set_friend(force, true)
    end
  end
  if enemy then
    customers.set_cease_fire(enemy, true)
    enemy.set_cease_fire(customers, true)
    customers.set_friend(enemy, false)
    enemy.set_friend(customers, false)
  end
end

script.on_init(function()
  configure_factoryx_new_game()
  rebuild_electric_vehicles()
  rebuild_grid_controllers()
  rebuild_sales_offices()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
  end
  track_ai_efficiency_progress()
  queue_customer_vehicle_variant_migration()
end)

script.on_configuration_changed(function()
  rebuild_electric_vehicles()
  rebuild_grid_controllers()
  rebuild_sales_offices()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
  end
  track_ai_efficiency_progress()
  queue_customer_vehicle_variant_migration()
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  if event.prototype_name == FACTORYX_PROGRESS_SHORTCUT then
    open_progress_panel(player)
    return
  end
  if event.prototype_name == SALES_OFFICE_COVERAGE_SHORTCUT then
    local enabled = sales_office_coverage_enabled()
    enabled[player.index] = not enabled[player.index]
    refresh_sales_office_coverage(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not element or not element.valid or element.name ~= PROGRESS_CLOSE_BUTTON_NAME then
    return
  end
  local player = game.get_player(event.player_index)
  local panel = player and player.gui.screen[PROGRESS_PANEL_NAME]
  if panel then
    panel.destroy()
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player then
    sales_office_coverage_enabled()[player.index] = false
    refresh_sales_office_coverage(player)
    sync_charger_placement_overlay(player)
  end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  sync_charger_placement_overlay(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_entity_damaged, function(event)
  local victim = event.entity
  local attacker = event.cause
  if victim and victim.valid and attacker and attacker.valid
    and attacker.type == "unit" and attacker.force.name == CUSTOMER_FORCE_NAME
    and player_market_force(victim.force) then
    give_customer_wander_command(attacker, true)
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  refresh_sales_office_coverage(player)
  refresh_progress_panel(player)
end)

script.on_event(defines.events.on_player_changed_force, function(event)
  local player = game.get_player(event.player_index)
  refresh_sales_office_coverage(player)
  refresh_progress_panel(player)
end)

script.on_event(defines.events.on_research_finished, function(event)
  local research = event.research
  sync_force_unlocks(research and research.force)
  if research and research.name == "x-premium-ev-program" then
    announce_ev_production_line_researched(research.force)
  elseif research and research.name == "x-ev-charging-network" then
    announce_ev_charging_network_researched(research.force)
  elseif research and research.name == "x-capital-scaling" then
    announce_mass_market_production_researched(research.force)
  end
  announce_research_completion(research)
  if research and research.force then
    for _, player in pairs(research.force.players) do
      refresh_progress_panel(player)
    end
  end
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
  local player = event.player_index and game.get_player(event.player_index)
  if not player or not player.valid then
    return
  end
  local selected = player.selected
  if is_station(selected) then
    close_entity_info_panel(player)
    show_station_info_panel(player, selected)
  elseif is_factoryx_manufacturer(selected) then
    close_station_info_panel(player)
    show_manufacturer_info_panel(player, selected)
  elseif is_customer_settlement_entity(selected) then
    close_station_info_panel(player)
    show_customer_settlement_info_panel(player, selected)
  else
    close_station_info_panel(player)
    close_entity_info_panel(player)
  end
end)

script.on_event(defines.events.on_gui_opened, function(event)
  local player = event.player_index and game.get_player(event.player_index)
  local entity = event.entity
  if player and player.valid then
    if is_station(entity) then
      close_entity_info_panel(player)
      show_station_info_panel(player, entity)
    elseif is_factoryx_manufacturer(entity) then
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, entity)
    elseif is_customer_settlement_entity(entity) then
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, entity)
    end
  end
end)

for _, event_name in pairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive
}) do
  if event_name then
	    script.on_event(event_name, function(event)
	      local entity = event.entity or event.created_entity
	      handle_station_built(entity, event)
	      track_grid_controller(entity)
	      track_sales_office(entity)
	      track_electric_vehicle(entity)
	      if entity and entity.valid and GIGAFACTORY_ENTITY_NAMES[entity.name] then
	        unlock_gigafactory_logistics(entity.force, true)
	      end
	      announce_first_entity_placement(entity)
	      if entity and entity.valid and entity.name == ROBOTAXI_SERVICE_CENTER_NAME then
	        robotaxi_service_inventories(entity)
	        ensure_robotaxi_service_power(entity)
	      end
	      if entity and entity.valid and entity.name == SALES_OFFICE_NAME then
	        sync_customer_settlements()
	        mark_sales_office_coverage_dirty()
	      end
	    end)
	  end
	end

for _, event_name in pairs({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy
}) do
  if event_name then
    script.on_event(event_name, function(event)
      local entity = event.entity
      if entity and entity.valid and entity.unit_number and customer_unit_registry()[entity.unit_number] then
        destroy_customer_marker(entity)
        unregister_customer_unit(entity)
      end
      if entity and entity.unit_number and ELECTRIC_VEHICLE_BATTERIES[entity.name] then
        electric_vehicle_registry()[entity.unit_number] = nil
      end
      if is_station(entity) then
        reservation_print_progress()[entity.unit_number] = nil
        customer_growth_states()[entity.unit_number] = nil
        remove_station_support_entities(entity)
      elseif entity and entity.name == SALES_OFFICE_NAME then
        clear_office_buyer_reservation(entity.unit_number)
        robotaxi_audio_revenue_progress()[entity.unit_number] = nil
        mark_sales_office_coverage_dirty()
      elseif entity and entity.name == ROBOTAXI_SERVICE_CENTER_NAME and entity.unit_number then
        robotaxi_service_states()[entity.unit_number] = nil
        local power = robotaxi_service_power_entities()[entity.unit_number]
        if power and power.valid then power.destroy() end
        robotaxi_service_power_entities()[entity.unit_number] = nil
      end
    end)
  end
end


script.on_nth_tick(30, function()
  feed_tracked_electric_vehicles()
  sync_sales_office_buyers()
  accelerate_consumer_ev_sales()
  check_first_prototype_sales()
  for _, force in pairs(game.forces) do
    finish_completed_grid_charges(force)
  end
end)

script.on_nth_tick(60, function()
  track_ai_efficiency_progress()
  process_robotaxi_service_centers()
  process_customer_vehicle_variant_migration(50)
  if storage.factoryx_sales_office_coverage_dirty then
    refresh_all_sales_office_coverage()
  end
  for _, force in pairs(game.forces) do
    process_customer_growth(force)
  end
  local allocations_by_force = {}
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface)) do
      local force_index = station.force.index
      if not allocations_by_force[force_index] then
        allocations_by_force[force_index] = calculate_station_utilization(station.force)
      end
      refresh_station_power_state(station, allocations_by_force[force_index])
      sample_station_power_service(station)
      charge_station_vehicles(station)
      update_station_alerts(station)
      if station.valid and count_biter_settlements_near_station(station) > 0 then
        unlock_roadster_sales(station.force)
      end
    end
  end
  for _, player in pairs(game.connected_players) do
    local selected = player.selected
    if is_station(selected) then
      close_entity_info_panel(player)
      show_station_info_panel(player, selected)
    elseif is_factoryx_manufacturer(selected) then
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, selected)
    elseif is_customer_settlement_entity(selected) then
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, selected)
    else
      close_station_info_panel(player)
      close_entity_info_panel(player)
    end
  end
  for _, force in pairs(game.forces) do
    generate_station_reservations(force)
  end
  for _, player in pairs(game.connected_players) do
    refresh_progress_panel(player)
  end
end)

script.on_nth_tick(600, function()
  sync_biter_customer_diplomacy()
  sync_customer_service_states()
end)

remote.add_interface("factoryx", {
  robotaxi_service_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local centers = {}
    for _, surface in pairs(game.surfaces) do
      for _, center in pairs(surface.find_entities_filtered{name = ROBOTAXI_SERVICE_CENTER_NAME, force = force}) do
        local snapshot = robotaxi_service_snapshot(center)
        snapshot.unit_number = center.unit_number
        snapshot.surface = surface.name
        snapshot.position = center.position
        centers[#centers + 1] = snapshot
      end
    end
    return centers
  end,
  continuous_improvements = function(force_name)
    local force = game.forces[force_name or "player"]
    return force and continuous_improvement_levels(force) or nil
  end,
  ai_efficiency_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local result = {}
    for track_name in pairs(AI_EFFICIENCY_TRACKS) do
      result[track_name] = ai_efficiency_track_status(force, track_name)
    end
    return result
  end,
  customer_vehicle_ownership = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local summary = active_customer_vehicle_summary(force)
    local registered = 0
    local reserved = 0
    local by_entity_name = {}
    local wandering_owners = 0
    for _, entity in pairs(customer_unit_registry()) do
      if entity and entity.valid then registered = registered + 1 end
    end
    for _ in pairs(buyer_reserved_by_unit()) do reserved = reserved + 1 end
    for unit_number in pairs(customer_vehicle_owners()) do
      local entity = customer_unit_registry()[unit_number]
      if entity and entity.valid then
        by_entity_name[entity.name] = (by_entity_name[entity.name] or 0) + 1
        local command = entity.commandable and entity.commandable.command
        if command and command.type == defines.command.wander then
          wandering_owners = wandering_owners + 1
        end
      end
    end
    return {
      active = summary.total,
      by_vehicle = summary.by_vehicle,
      registered_buyers = registered,
      reserved_buyers = reserved,
      by_entity_name = by_entity_name,
      wandering_owners = wandering_owners,
      last_assignment = storage.factoryx_last_vehicle_sale_assignment
    }
  end,
  biter_customer_market = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then
      return nil
    end
    return add_reservation_output_status(biter_customer_market_summary(force), force)
  end,
  refresh_biter_customer_market = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then
      return nil
    end
    sync_customer_settlements()
    return add_reservation_output_status(biter_customer_market_summary(force), force)
  end,
  progress_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then
      return nil
    end
    local snapshot = progress_snapshot(force)
    local stage, objective, detail = current_progress_objective(snapshot)
    return {
      stage = stage,
      objective = objective,
      detail = detail,
      snapshot = snapshot
    }
  end,
  progression_integrity = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then
      return nil
    end
    local repaired = repair_researched_factoryx_unlocks(force)
    sync_force_unlocks(force)
    local status = progression_integrity_status(force)
    status.repaired_recipes = repaired
    return status
  end,
  open_progress = function(player_index)
    local player = game.get_player(player_index)
    if not player then
      return false
    end
    if player.gui.screen[PROGRESS_PANEL_NAME] then
      refresh_progress_panel(player)
    else
      open_progress_panel(player)
    end
    return player.gui.screen[PROGRESS_PANEL_NAME] ~= nil
  end
})

commands.add_command("factoryx-status", "Open or report FactoryX progression status.", function(command)
  local player = command.player_index and game.get_player(command.player_index)
  local force = player and player.force or game.forces.player
  if not force then
    return
  end
  if player then
    if player.gui.screen[PROGRESS_PANEL_NAME] then
      refresh_progress_panel(player)
    else
      open_progress_panel(player)
    end
    return
  end
  local snapshot = progress_snapshot(force)
  local stage, objective, detail = current_progress_objective(snapshot)
  rcon.print(string.format("[FactoryX] %s: %s %s", stage, objective, detail))
end)

commands.add_command("factoryx-coverage", "Report FactoryX EV charging grid connections.", function(command)
  local player = command.player_index and game.get_player(command.player_index)
  local force = player and player.force or game.forces.player
  local stations = count_entities(force, STATION_NAMES)
  local market = biter_customer_market_summary(force)
  local offices = #find_sales_offices(force)

  local message
  if market.biter_customer_mode then
    message = string.format(
      "[FactoryX] Biter customer market: %d customer EVs, %d/%d stations grid-connected, %d covered biter settlements, %d/%d active charging stalls, %d active EV Sales Offices, %d EV Reservations printed at chargers per minute.",
      market.customer_ev_fleet,
      market.powered_stations,
      stations,
      market.covered_biter_settlements,
      market.active_customer_stalls,
      market.charging_stall_capacity,
      offices,
      market.reservations_per_minute
    )
  else
    message = string.format(
      "[FactoryX] EV charging capacity: %d customer EVs, %d/%d stations grid-connected, %d active EV Sales Offices, %d EV Reservations printed at chargers per minute.",
      market.customer_ev_fleet,
      market.powered_stations,
      stations,
      offices,
      market.reservations_per_minute
    )
  end

  if player then
    player.print(message)
  else
    rcon.print(message)
  end
end)
