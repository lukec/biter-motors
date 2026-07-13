TimingWheel = require("runtime.timing_wheel")
PerformanceState = require("runtime.performance_state")
CustomerAggregates = require("runtime.customer_aggregates")
BuyerQueues = require("runtime.buyer_queues")
RobotaxiService = require("runtime.robotaxi_service")
PowerQueue = require("runtime.power_queue")
UiRefresh = require("runtime.ui_refresh")

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
    vehicle_charge_radius = 10,
    power_sink_name = "x-ev-charging-v3-power-sink"
  },
  ["x-ev-charging-station-v4"] = {
    display_name = "V4 Supercharger",
    stalls = 20,
    evs_per_stall = 50,
    power_per_stall_kw = 500,
    customer_radius = 160,
    vehicle_charge_radius = 10,
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
WRECKED_EV_NAME = "x-wrecked-ev"
local CUSTOMER_FORCE_NAME = "factoryx-customers"
local GRID_CONTROLLER_NAME = "x-planetary-grid-controller"
AGI_TRAINING_RECIPE_NAME = "x-agi-training-run"
AGI_MODEL_ITEM_NAME = "x-agi-model"
AGI_TOKEN_GATE = 1000000000
AGI_TRAINING_SECONDS = 3600
FACTORYX_COMPUTE_RECIPES = {
  ["x-terrestrial-datacenter"] = true,
  ["x-orbital-compute-array"] = true,
  ["x-planetary-grid-controller"] = AGI_TRAINING_RECIPE_NAME
}
local DOLLAR_NAME = "x-dollar"
local PROTOTYPE_ROADSTER_NAME = "x-prototype-roadster"
local PREMIUM_EV_NAME = "x-premium-ev"
GIGAFACTORY_PRODUCTION_GATE = 100
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
SALES_OFFICE_SHOWROOM_SPRITES = {
  [FIRST_PROTOTYPE_SALE_RECIPE] = "x-sales-office-showroom-prototype-roadster",
  [PREMIUM_EV_SALE_RECIPE] = "x-sales-office-showroom-premium-ev",
  [MASS_MARKET_EV_SALE_RECIPE] = "x-sales-office-showroom-mass-market-ev",
  [CYBERTRUCK_SALE_RECIPE] = "x-sales-office-showroom-cybertruck"
}
EV_SALES_GATES = {
  premium = {
    item = "x-prototype-roadster",
    threshold = 50,
    technology = "x-premium-ev-program",
    recipes = {"x-premium-ev", "x-sell-premium-ev"},
    label = "Premium EV"
  },
  mass_market = {
    item = "x-premium-ev",
    threshold = 250,
    technology = "x-capital-scaling",
    recipes = {"x-mass-market-ev", "x-sell-mass-market-ev"},
    label = "Mass-market EV"
  },
  cybertruck = {
    item = "x-mass-market-ev",
    threshold = 2000,
    technology = "x-megatruck-engineering",
    recipes = {"x-cybertruck", "x-sell-cybertruck"},
    label = "Megatruck"
  },
  robotaxi = {
    total_consumer_sales = true,
    threshold = 5000,
    technology = "x-autonomous-logistics",
    recipes = {"x-robotaxi-fleet"},
    label = "Robotaxi"
  }
}
EV_SALES_GATED_RECIPES = {}
for _, gate in pairs(EV_SALES_GATES) do
  for _, recipe_name in pairs(gate.recipes) do EV_SALES_GATED_RECIPES[recipe_name] = true end
end
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
local CUSTOMER_VISIBLE_GLOBAL_LIMIT = 2000
local CUSTOMER_VISIBLE_PER_SETTLEMENT_LIMIT = 128
CUSTOMER_SERVICE_GRACE_TICKS = 3 * 60 * 60
CUSTOMER_MOOD_CHECK_TICKS = 60 * 60
CUSTOMER_MOOD_BASE_ANGER_CHANCE = 0.05
CUSTOMER_MOOD_MAX_ANGER_CHANCE = 0.25
CUSTOMER_COMMUTE_MAX_ACTIVE = 512
CUSTOMER_COMMUTE_STARTS_PER_SECOND = 8
CUSTOMER_COMMUTE_SCHEDULER_BATCH = 256
CUSTOMER_COMMUTE_CHARGE_SECONDS = 30
CUSTOMER_COMMUTE_FIRST_VISIT_TICKS = 60 * 60
CUSTOMER_COMMUTE_RETRY_BASE_TICKS = 30 * 60
CUSTOMER_COMMUTE_RETRY_MAX_TICKS = 5 * 60 * 60
CUSTOMER_COMMUTE_PATH_TIMEOUT_TICKS = 2 * 60 * 60
CUSTOMER_COMMUTE_INTERVALS = {
  ["x-prototype-roadster"] = 3 * 60 * 60,
  ["x-premium-ev"] = 6 * 60 * 60,
  ["x-mass-market-ev"] = 5 * 60 * 60,
  ["x-cybertruck"] = 8 * 60 * 60,
  ["x-robotaxi-fleet"] = 7 * 60 * 60
}
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
  "steam-power",
  "automation-science-pack",
  "automation",
  "logistics",
  "electronics",
  "steel-processing",
  "steel-axe",
  "electric-mining-drill",
  "repair-pack",
  "military",
  "gun-turret",
  "radar",
  "heavy-armor",
  "stone-wall",
  "landfill",
  "circuit-network",
  "automation-2",
  "logistic-science-pack",
  "electric-energy-distribution-1",
  "electric-energy-distribution-2",
  "advanced-material-processing",
  "advanced-material-processing-1",
  "advanced-material-processing-2",
  "optics",
  "lamp",
  "solar-energy",
  "electric-energy-accumulators",
  "engine",
  "electric-engine",
  "oil-processing",
  "sulfur-processing",
  "plastics",
  "advanced-circuit",
  "battery",
  "fluid-handling",
  "robotics",
  "construction-robotics",
  "logistic-robotics",
  "modular-armor",
  "solar-panel-equipment",
  "battery-equipment",
  "night-vision-equipment",
  "personal-roboport-equipment"
}
FACTORYX_START_SHIP_ITEMS = {
  ["steel-plate"] = 100,
  ["electronic-circuit"] = 100,
  ["iron-gear-wheel"] = 100,
  ["assembling-machine-1"] = 4,
  ["lab"] = 4,
  ["lamp"] = 50
}
FACTORYX_START_DEBRIS_ITEMS = {
  ["iron-plate"] = 400,
  ["copper-plate"] = 200,
  ["stone"] = 200,
  ["coal"] = 200,
  ["transport-belt"] = 200,
  ["inserter"] = 30,
  ["small-electric-pole"] = 60,
  ["medium-electric-pole"] = 40,
  ["pipe"] = 50
}
FACTORYX_ENERGY_JUMPSTART_ITEMS = {
  ["x-high-density-solar-array"] = 54,
  ["x-megapack"] = 24,
  ["substation"] = 40,
  ["roboport"] = 20,
  ["passive-provider-chest"] = 50,
  ["storage-chest"] = 50,
  ["electric-mining-drill"] = 10,
  ["electric-furnace"] = 10,
  ["construction-robot"] = 50,
  ["logistic-robot"] = 100,
  ["modular-armor"] = 1,
  ["personal-roboport-equipment"] = 1,
  ["battery-equipment"] = 2,
  ["solar-panel-equipment"] = 8,
  ["night-vision-equipment"] = 1
}
FACTORYX_ENERGY_JUMPSTART_QUALITY = "legendary"
local FACTORYX_RUNTIME_VISUAL_CONFIGS = {
  ["x-sales-office"] = {
    status = true,
    sprite_prefix = "x-sales-office-status-red-frame-",
    working_sprite_prefix = "x-sales-office-status-green-frame-",
    stopped_sprite_prefix = "x-sales-office-status-red-frame-",
    offset = {1.03, -1.18},
    scale = 0.5
  },
  ["x-robotaxi-service-center"] = {sprite_prefix = "x-robotaxi-dispatch-lights-frame-", offset = {0, -0.55}, scale = 0.9}
}
CHARGER_STALL_VISUAL_LAYOUTS = {
  ["x-ev-charging-station"] = {columns = 4, spacing_x = 0.7, spacing_y = 0.7, offset_y = -0.35, scale = 0.75},
  ["x-ev-charging-station-v2"] = {columns = 4, spacing_x = 0.78, spacing_y = 0.72, offset_y = -0.15, scale = 0.78},
  ["x-ev-charging-station-v3"] = {columns = 6, spacing_x = 0.76, spacing_y = 0.72, offset_y = -0.05, scale = 0.72},
  ["x-ev-charging-station-v4"] = {columns = 5, spacing_x = 0.9, spacing_y = 0.78, offset_y = 0, scale = 0.78}
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
  ["x-prototype-roadster"] = 3,
  ["x-premium-ev"] = 4,
  ["x-mass-market-ev"] = 3,
  ["x-cybertruck"] = 8,
  ["x-robotaxi-fleet"] = 5
}
ELECTRIC_DRIVE_FUEL_NAME = "x-electric-drive-charge"
ELECTRIC_DRIVE_FUEL_JOULES = 1000000
EV_BATTERY_POPUP_TICKS = 2 * 60
EV_BATTERY_POPUP_FADE_TICKS = 60
SUPERCHARGING_TECH_NAME = "x-supercharging-power-electronics"
LONG_RANGE_BATTERY_TECH_NAME = "x-long-range-battery"
PREMIUM_AUDIO_TECH_NAME = "x-premium-audio-systems"
CUSTOMER_REFERRAL_TECH_NAME = "x-customer-referral-program"
SOLAR_PRODUCTIVITY_TECH_NAME = "x-high-density-solar-productivity"
MEGAPACK_PRODUCTIVITY_TECH_NAME = "x-megapack-productivity"
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
  local prospect_name = "x-" .. base_name .. "-prospect"
  CUSTOMER_UNIT_BASE_BY_NAME[prospect_name] = base_name
  BITER_CUSTOMER_ENTITY_NAMES[prospect_name] = true
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

local function factoryx_runtime_visuals()
  storage.factoryx_runtime_visuals = storage.factoryx_runtime_visuals or {}
  return storage.factoryx_runtime_visuals
end

local function destroy_factoryx_runtime_visual(unit_number)
  if not unit_number then return end
  local visuals = factoryx_runtime_visuals()
  local entry = visuals[unit_number]
  if entry and entry.object and entry.object.valid then entry.object.destroy() end
  visuals[unit_number] = nil
end

local function attach_factoryx_runtime_visual(entity)
  local config = entity and entity.valid and FACTORYX_RUNTIME_VISUAL_CONFIGS[entity.name]
  if not config or not entity.unit_number then return end
  destroy_factoryx_runtime_visual(entity.unit_number)
  local object = rendering.draw_sprite{
    sprite = config.sprite_prefix .. "1",
    surface = entity.surface,
    target = entity,
    target_offset = config.offset,
    x_scale = config.scale,
    y_scale = config.scale,
    render_layer = "higher-object-above",
    visible = false
  }
  factoryx_runtime_visuals()[entity.unit_number] = {
    object = object,
    entity = entity,
    sprite_prefix = config.sprite_prefix,
    working_sprite_prefix = config.working_sprite_prefix,
    stopped_sprite_prefix = config.stopped_sprite_prefix,
    status = config.status == true,
    enabled = config.status == true
  }
end

local function set_factoryx_runtime_visual_enabled(entity, enabled)
  if not entity or not entity.valid or not entity.unit_number then return end
  local entry = factoryx_runtime_visuals()[entity.unit_number]
  if not entry then
    attach_factoryx_runtime_visual(entity)
    entry = factoryx_runtime_visuals()[entity.unit_number]
  end
  if entry then entry.enabled = enabled == true end
end

local function rebuild_factoryx_runtime_visuals()
  for unit_number in pairs(factoryx_runtime_visuals()) do
    destroy_factoryx_runtime_visual(unit_number)
  end
  local names = {}
  for name in pairs(FACTORYX_RUNTIME_VISUAL_CONFIGS) do names[#names + 1] = name end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = names}) do
      attach_factoryx_runtime_visual(entity)
    end
  end
end

local function update_factoryx_runtime_visuals()
  local frame_index = math.floor(game.tick / 15) % 8 + 1
  for unit_number, entry in pairs(factoryx_runtime_visuals()) do
    if not entry.entity or not entry.entity.valid or not entry.object or not entry.object.valid then
      destroy_factoryx_runtime_visual(unit_number)
    else
      entry.object.visible = entry.status or entry.enabled
      if entry.status then
        local prefix = entry.entity.status == defines.entity_status.working
          and entry.working_sprite_prefix or entry.stopped_sprite_prefix
        entry.object.sprite = prefix .. frame_index
      elseif entry.enabled then
        entry.object.sprite = entry.sprite_prefix .. frame_index
      end
    end
  end
end

function charger_stall_visuals()
  storage.factoryx_charger_stall_visuals = storage.factoryx_charger_stall_visuals or {}
  return storage.factoryx_charger_stall_visuals
end

function destroy_charger_stall_visuals(unit_number)
  if not unit_number then return end
  local entry = charger_stall_visuals()[unit_number]
  for _, object in pairs(entry and entry.objects or {}) do
    if object and object.valid then object.destroy() end
  end
  charger_stall_visuals()[unit_number] = nil
end

function ensure_charger_stall_visuals(station)
  if not station or not station.valid or not station.unit_number then return nil end
  local config = station_config(station)
  local layout = CHARGER_STALL_VISUAL_LAYOUTS[station.name]
  if not config or not layout then return nil end
  local entry = charger_stall_visuals()[station.unit_number]
  local complete = entry and entry.entity and entry.entity.valid and #entry.objects == config.stalls
  for _, object in pairs(complete and entry.objects or {}) do
    if not object or not object.valid then
      complete = false
      break
    end
  end
  if complete then return entry end
  destroy_charger_stall_visuals(station.unit_number)
  entry = {entity = station, objects = {}}
  local rows = math.ceil(config.stalls / layout.columns)
  for stall_index = 1, config.stalls do
    local column = (stall_index - 1) % layout.columns
    local row = math.floor((stall_index - 1) / layout.columns)
    entry.objects[stall_index] = rendering.draw_sprite{
      sprite = "x-charger-stall-idle-frame-1",
      surface = station.surface,
      target = station,
      target_offset = {
        (column - (layout.columns - 1) / 2) * layout.spacing_x,
        layout.offset_y + (row - (rows - 1) / 2) * layout.spacing_y
      },
      x_scale = layout.scale,
      y_scale = layout.scale,
      render_layer = "higher-object-above"
    }
  end
  charger_stall_visuals()[station.unit_number] = entry
  return entry
end

function charger_stall_visual_state(service, station, assignment, stall_index, charging_available)
  local load = assignment and assignment.stall_loads and assignment.stall_loads[stall_index] or 0
  if load <= 0 then return "idle", charging_available end
  local settlement = assignment and assignment.settlements[stall_index]
  local key = settlement and (
    settlement.surface.index .. ":" .. (settlement.unit_number or string.format(
      "%s:%.1f:%.1f",
      settlement.name,
      settlement.position.x,
      settlement.position.y
    ))
  )
  local vehicle_summary = service.vehicle_summary or active_customer_vehicle_summary(station.force)
  local owned = key and (vehicle_summary.by_settlement[key] or 0) or 0
  local capacity = key and (service.powered_capacity_by_settlement_key[key] or 0) or 0
  if owned > capacity then return "overload", charging_available end
  if charging_available > 0 then return "charging", charging_available - 1 end
  local config = station_config(station)
  local fraction = config and load / config.evs_per_stall or 0
  if fraction >= 0.9 then return "full", charging_available end
  if fraction >= 0.34 then return "medium", charging_available end
  return "low", charging_available
end

function update_charger_stall_visuals(force_refresh)
  local frame_index = math.floor(game.tick / 15) % 8 + 1
  local refresh_states = force_refresh == true or game.tick % 120 == 0
  local commute_counts = refresh_states and customer_commute_station_counts() or {}
  local seen = {}
  local services = {}
  for _, station in pairs(registered_factoryx_entities("stations")) do
    if station.valid and station.unit_number then
      seen[station.unit_number] = true
      local entry = ensure_charger_stall_visuals(station)
      if refresh_states or not entry.states then
        services[station.force.index] = services[station.force.index]
          or customer_service_for_force(station.force)
        local service = services[station.force.index]
        local assignment = service.assignments[station.unit_number]
        local charging_available = (commute_counts[station.unit_number] or {}).charging or 0
        entry.states = {}
        for stall_index = 1, #entry.objects do
          entry.states[stall_index], charging_available = charger_stall_visual_state(
            service, station, assignment, stall_index, charging_available
          )
        end
      end
      for stall_index, object in ipairs(entry and entry.objects or {}) do
        local state = entry.states[stall_index] or "idle"
        if object and object.valid then
          local staggered_frame = (frame_index + (stall_index - 1) * 2 - 1) % 8 + 1
          object.sprite = "x-charger-stall-" .. state .. "-frame-" .. staggered_frame
        end
      end
    end
  end
  for unit_number in pairs(charger_stall_visuals()) do
    if not seen[unit_number] then destroy_charger_stall_visuals(unit_number) end
  end
end

function rebuild_charger_stall_visuals()
  for unit_number in pairs(charger_stall_visuals()) do
    destroy_charger_stall_visuals(unit_number)
  end
  update_charger_stall_visuals()
end

function sales_office_showroom_renderings()
  storage.factoryx_sales_office_showroom_renderings =
    storage.factoryx_sales_office_showroom_renderings or {}
  return storage.factoryx_sales_office_showroom_renderings
end

function destroy_sales_office_showroom_rendering(unit_number)
  if not unit_number then return end
  local entry = sales_office_showroom_renderings()[unit_number]
  if entry and entry.object and entry.object.valid then entry.object.destroy() end
  sales_office_showroom_renderings()[unit_number] = nil
end

function update_sales_office_showrooms()
  local seen = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
    if office.valid and office.unit_number then
      seen[office.unit_number] = true
      local recipe = office.get_recipe()
      local sprite = recipe and SALES_OFFICE_SHOWROOM_SPRITES[recipe.name]
      local active = sprite and office.status == defines.entity_status.working
      local entry = sales_office_showroom_renderings()[office.unit_number]
      if active and (not entry or entry.sprite ~= sprite or not entry.object or not entry.object.valid) then
        destroy_sales_office_showroom_rendering(office.unit_number)
        local object = rendering.draw_sprite{
          sprite = sprite,
          surface = office.surface,
          target = office,
          target_offset = {0, 0.55},
          x_scale = 0.2,
          y_scale = 0.2,
          render_layer = "higher-object-above"
        }
        sales_office_showroom_renderings()[office.unit_number] = {
          object = object,
          sprite = sprite
        }
      elseif not active and entry then
        destroy_sales_office_showroom_rendering(office.unit_number)
      end
    end
  end
  for unit_number in pairs(sales_office_showroom_renderings()) do
    if not seen[unit_number] then destroy_sales_office_showroom_rendering(unit_number) end
  end
end

function rebuild_sales_office_showrooms()
  for unit_number in pairs(sales_office_showroom_renderings()) do
    destroy_sales_office_showroom_rendering(unit_number)
  end
  update_sales_office_showrooms()
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
  return registered_factoryx_entities("stations", force, surface)
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
    referrals = continuous_improvement_level(force, CUSTOMER_REFERRAL_TECH_NAME),
    solar_productivity = continuous_improvement_level(force, SOLAR_PRODUCTIVITY_TECH_NAME),
    megapack_productivity = continuous_improvement_level(force, MEGAPACK_PRODUCTIVITY_TECH_NAME)
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

function count_item_produced(force, item_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_item_production_statistics(surface)
    count = count + (statistics.output_counts[item_name] or 0)
  end
  return count
end

function agi_training_unlocks()
  storage.factoryx_agi_training_unlocks = storage.factoryx_agi_training_unlocks or {}
  return storage.factoryx_agi_training_unlocks
end

function factoryx_compute_machines()
  storage.factoryx_compute_machines = storage.factoryx_compute_machines or {}
  return storage.factoryx_compute_machines
end

function factoryx_compute_power_failures()
  storage.factoryx_compute_power_failures = storage.factoryx_compute_power_failures or {}
  return storage.factoryx_compute_power_failures
end

function factoryx_compute_queue()
  storage.factoryx_compute_queue = PowerQueue.ensure(storage.factoryx_compute_queue)
  return storage.factoryx_compute_queue
end

function track_factoryx_compute_machine(entity)
  if entity and entity.valid and entity.unit_number and FACTORYX_COMPUTE_RECIPES[entity.name] then
    factoryx_compute_machines()[entity.unit_number] = entity
    local queue = factoryx_compute_queue()
    if not queue.members[entity.unit_number] then
      PowerQueue.track(queue, entity.unit_number)
    end
  end
end

function rebuild_factoryx_compute_machines()
  storage.factoryx_compute_machines = {}
  storage.factoryx_compute_power_failures = {}
  storage.factoryx_compute_queue = {units = {}, index = 1, members = {}}
  local names = {}
  for name in pairs(FACTORYX_COMPUTE_RECIPES) do names[#names + 1] = name end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = names}) do
      track_factoryx_compute_machine(entity)
    end
  end
end

function reset_underpowered_compute_progress()
  local queue = factoryx_compute_queue()
  local processed = 0
  while processed < 32 and #queue.units > 0 do
    local unit_number = PowerQueue.next(queue)
    processed = processed + 1
    local entity = factoryx_compute_machines()[unit_number]
    if not entity or not entity.valid then
      factoryx_compute_machines()[unit_number] = nil
      factoryx_compute_power_failures()[unit_number] = nil
      PowerQueue.remove_current(queue, unit_number)
    else
      local power_failure = factoryx_compute_power_failures()[unit_number]
      if power_failure then
        if entity.electric_buffer_size > 0
          and entity.energy >= entity.electric_buffer_size * 0.9 then
          entity.disabled_by_script = false
          factoryx_compute_power_failures()[unit_number] = nil
        end
        goto continue
      end
      local required_recipe = FACTORYX_COMPUTE_RECIPES[entity.name]
      local recipe = entity.get_recipe()
      local recipe_matches = required_recipe == true or (recipe and recipe.name == required_recipe)
      local status = entity.status
      local power_failed = status == defines.entity_status.no_power
        or (status == defines.entity_status.low_power
          and entity.electric_buffer_size > 0
          and entity.energy < entity.electric_buffer_size * 0.1)
      if recipe_matches and (entity.crafting_progress or 0) > 0
        and power_failed then
        entity.crafting_progress = 0
        entity.disabled_by_script = true
        factoryx_compute_power_failures()[unit_number] = true
      end
    end
    ::continue::
  end
end

function sync_agi_training_unlock(force, announce)
  if not force or not force.valid then return false end
  local cumulative = count_item_produced(force, "x-ai-token")
  local unlocked = cumulative >= AGI_TOKEN_GATE
  local recipe = force.recipes and force.recipes[AGI_TRAINING_RECIPE_NAME]
  if recipe then recipe.enabled = unlocked end
  local unlocks = agi_training_unlocks()
  if unlocked and not unlocks[force.name] then
    unlocks[force.name] = true
    if announce ~= false then
      force.print("[FactoryX] One billion cumulative AI Tokens generated. AGI Training Run is now available in the Planetary Energy Grid Controller.")
    end
  end
  return unlocked
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
                if inserted > 0 then
                  local statistics = force.get_item_production_statistics(machine.surface)
                  statistics.set_output_count(
                    "x-ai-token",
                    statistics.get_output_count("x-ai-token") + inserted
                  )
                end
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
      sync_agi_training_unlock(force, true)
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
      "You arrived to establish a permanent colony. An advance landing party was supposed to prepare the site, but they never made it. No base, no beacon, and no survivors are waiting for you.\n\n",
      "Your ship carried advanced equipment, but the crash destroyed much of its technical archive. Recover the scattered cargo and use the surviving solar, storage, and robotics hardware carefully: you possess machines that you cannot yet reproduce.\n\n",
      "Restore red and green science as quickly as possible. The Industrial Supply Chain recovers plans for Big Mining Drills, electric furnaces, and foundries that can accelerate the colony. From there, rebuild industry, establish trade with native settlements, and scale energy and computation far beyond one factory."
    })
  end
end

function grant_factoryx_energy_jumpstart(player)
  if not factoryx_accelerated_start_enabled() or not player or not player.valid then
    return nil
  end
  storage.factoryx_energy_jumpstart_forces = storage.factoryx_energy_jumpstart_forces or {}
  if storage.factoryx_energy_jumpstart_forces[player.force.name] then
    return nil
  end
  local surface = player.surface
  local target = {x = player.position.x + 8, y = player.position.y}
  local position = surface.find_non_colliding_position("passive-provider-chest", target, 32, 1) or target
  local chest = surface.create_entity{
    name = "passive-provider-chest",
    position = position,
    force = player.force,
    create_build_effect_smoke = false
  }
  local inventory = chest and chest.get_inventory(defines.inventory.chest)
  if not inventory then
    if chest and chest.valid then chest.destroy() end
    return nil
  end
  for item_name, count in pairs(FACTORYX_ENERGY_JUMPSTART_ITEMS) do
    inventory.insert{name = item_name, count = count, quality = FACTORYX_ENERGY_JUMPSTART_QUALITY}
  end
  pcall(function() chest.backer_name = "Captain's Chest" end)
  storage.factoryx_energy_jumpstart_forces[player.force.name] = true
  return chest
end

local function crash_site_salvage(entity)
  if not entity or not entity.valid then return end
  local inventory = entity.get_output_inventory and entity.get_output_inventory()
  if not inventory or not inventory.valid or not inventory.is_empty() then return end
  local item_name = "iron-plate"
  local count = 10
  if string.find(entity.name, "big", 1, true) then
    item_name = "steel-plate"
    count = 20
  elseif string.find(entity.name, "medium", 1, true) then
    count = 15
  elseif string.find(entity.name, "small", 1, true) then
    item_name = "copper-plate"
  end
  inventory.insert{name = item_name, count = count}
end

function seed_crash_site_salvage(player)
  if not factoryx_accelerated_start_enabled() or not player or not player.valid then return end
  for _, entity in pairs(player.surface.find_entities_filtered{
    area = {{player.position.x - 96, player.position.y - 96}, {player.position.x + 96, player.position.y + 96}}
  }) do
    if string.find(entity.name, "crash-site-spaceship-wreck-", 1, true) == 1 then
      crash_site_salvage(entity)
    end
  end
end

local function award_small_crash_site_salvage(event)
  local entity = event.entity
  if not entity or not string.find(entity.name, "crash-site-spaceship-wreck-small-", 1, true) then
    return
  end
  local inserted = event.buffer and event.buffer.insert{name = "copper-plate", count = 5} or 0
  if inserted < 5 and entity.surface and entity.position then
    entity.surface.spill_item_stack{
      position = entity.position,
      stack = {name = "copper-plate", count = 5 - inserted},
      enable_looted = true,
      force = entity.force
    }
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

function install_vehicle_batteries(entity, charge_new_batteries)
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
        if charge_new_batteries then
          equipment.energy = equipment.max_energy
        end
        needed = needed - 1
      end
    end
  end
end

function track_electric_vehicle(entity, charge_new_batteries)
  if not is_electric_vehicle(entity) or not entity.unit_number then
    return
  end
  install_vehicle_batteries(entity, charge_new_batteries)
  electric_vehicle_registry()[entity.unit_number] = entity
end

function rebuild_electric_vehicles()
  storage.factoryx_electric_vehicles = {}
  for _, surface in pairs(game.surfaces) do
    for vehicle_name in pairs(ELECTRIC_VEHICLE_BATTERIES) do
      for _, entity in pairs(surface.find_entities_filtered{name = vehicle_name}) do
        track_electric_vehicle(entity, false)
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

function vehicle_total_charge_energy(entity)
  local energy, capacity = vehicle_battery_energy(entity)
  if not is_electric_vehicle(entity) or not entity.burner then return energy, capacity end
  energy = energy + (entity.burner.remaining_burning_fuel or 0)
  local inventory = entity.burner.inventory
  if inventory and inventory.valid then
    energy = energy + inventory.get_item_count(ELECTRIC_DRIVE_FUEL_NAME) * ELECTRIC_DRIVE_FUEL_JOULES
  end
  return math.min(capacity, energy), capacity
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

function customer_settlement_populations()
  storage.factoryx_customer_settlement_populations = storage.factoryx_customer_settlement_populations or {}
  return storage.factoryx_customer_settlement_populations
end

function customer_visible_count()
  if storage.factoryx_customer_visible_count == nil then
    local count = 0
    for _, entity in pairs(customer_unit_registry()) do
      if entity and entity.valid then count = count + 1 end
    end
    storage.factoryx_customer_visible_count = count
  end
  return storage.factoryx_customer_visible_count
end

function customer_population_members()
  storage.factoryx_customer_population_members = storage.factoryx_customer_population_members or {}
  return storage.factoryx_customer_population_members
end

function customer_settlement_population(settlement, market_force)
  local key
  if settlement.unit_number then
    key = settlement.surface.index .. ":" .. settlement.unit_number
  else
    key = string.format(
      "%d:%s:%.1f:%.1f",
      settlement.surface.index,
      settlement.name,
      settlement.position.x,
      settlement.position.y
    )
  end
  local populations = customer_settlement_populations()
  local population = populations[key]
  if not population then
    population = {
      market_force_name = market_force.name,
      surface_index = settlement.surface.index,
      position = {x = settlement.position.x, y = settlement.position.y},
      physical = 0,
      virtual_unowned = 0,
      virtual_reserved = 0,
      virtual_by_vehicle = {}
    }
    populations[key] = population
  else
    population.market_force_name = market_force.name
    population.surface_index = settlement.surface.index
    population.position = {x = settlement.position.x, y = settlement.position.y}
  end
  return key, population
end

function customer_home_settlements()
  storage.factoryx_customer_home_settlements = storage.factoryx_customer_home_settlements or {}
  return storage.factoryx_customer_home_settlements
end

function customer_vehicle_owners()
  storage.factoryx_customer_vehicle_owners = storage.factoryx_customer_vehicle_owners or {}
  return storage.factoryx_customer_vehicle_owners
end

function customer_charging_commutes()
  storage.factoryx_customer_charging_commutes = storage.factoryx_customer_charging_commutes or {}
  return storage.factoryx_customer_charging_commutes
end

function factoryx_entity_registries()
  return PerformanceState.ensure(storage).registries
end

function track_factoryx_entity(entity)
  if not entity or not entity.valid or not entity.unit_number then return end
  if STATION_CONFIGS[entity.name] then
    PerformanceState.track(PerformanceState.ensure(storage), "stations", entity)
  elseif entity.name == SALES_OFFICE_NAME then
    PerformanceState.track(PerformanceState.ensure(storage), "sales_offices", entity)
  elseif entity.name == ROBOTAXI_SERVICE_CENTER_NAME then
    PerformanceState.track(PerformanceState.ensure(storage), "robotaxi_centers", entity)
  end
end

function untrack_factoryx_entity(entity)
  if not entity or not entity.unit_number then return end
  PerformanceState.untrack(PerformanceState.ensure(storage), entity)
end

function registered_factoryx_entities(kind, force, surface)
  return PerformanceState.entities(PerformanceState.ensure(storage), kind, force, surface)
end

function rebuild_factoryx_entity_registries()
  PerformanceState.ensure(storage).registries = {stations = {}, sales_offices = {}, robotaxi_centers = {}}
  local names = {SALES_OFFICE_NAME, ROBOTAXI_SERVICE_CENTER_NAME}
  for _, name in pairs(STATION_NAMES) do names[#names + 1] = name end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = names}) do
      track_factoryx_entity(entity)
    end
  end
end

function reconcile_factoryx_entity_registry_step()
  local state = PerformanceState.ensure(storage)
  local surfaces = {}
  for _, surface in pairs(game.surfaces) do surfaces[#surfaces + 1] = surface end
  if #surfaces == 0 then return end
  table.sort(surfaces, function(left, right) return left.index < right.index end)
  local kinds = {
    {kind = "stations", names = STATION_NAMES},
    {kind = "sales_offices", names = {SALES_OFFICE_NAME}},
    {kind = "robotaxi_centers", names = {ROBOTAXI_SERVICE_CENTER_NAME}}
  }
  local cursor = state.reconciliation
  if cursor.surface > #surfaces then cursor.surface = 1 end
  if cursor.kind > #kinds then cursor.kind = 1 end
  local surface = surfaces[cursor.surface]
  local config = kinds[cursor.kind]
  local registry = state.registries[config.kind]
  for _, entity in pairs(surface.find_entities_filtered{name = config.names}) do
    if entity.unit_number and not registry[entity.unit_number] then
      PerformanceState.track(state, config.kind, entity)
      mark_factoryx_market_dirty(entity.force, "registry-reconciled")
    end
  end
  PerformanceState.entities(state, config.kind, nil, surface)
  cursor.kind = cursor.kind + 1
  if cursor.kind > #kinds then
    cursor.kind = 1
    cursor.surface = cursor.surface + 1
    if cursor.surface > #surfaces then cursor.surface = 1 end
  end
  storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
  storage.factoryx_perf_counters.registry_reconciliation_steps =
    (storage.factoryx_perf_counters.registry_reconciliation_steps or 0) + 1
end

function factoryx_market_cache()
  return PerformanceState.ensure(storage).market_cache
end

function factoryx_market_generation()
  return PerformanceState.ensure(storage).market_generation
end

function mark_factoryx_market_dirty(force, reason)
  if not force then return end
  PerformanceState.invalidate(PerformanceState.ensure(storage), force.index, reason)
  storage.factoryx_vehicle_summary_cache = storage.factoryx_vehicle_summary_cache or {}
  storage.factoryx_vehicle_summary_cache[force.index] = nil
end

function customer_buyer_queues()
  return BuyerQueues.ensure(storage)
end

function customer_settlement_market_forces()
  storage.factoryx_customer_settlement_market_forces = storage.factoryx_customer_settlement_market_forces or {}
  return storage.factoryx_customer_settlement_market_forces
end

function buyer_queue_for(force_name, settlement_key_value)
  return BuyerQueues.queue_for(storage, force_name, settlement_key_value)
end

function enqueue_customer_buyer(unit_number, home)
  if not unit_number or not home then return end
  local queue = buyer_queue_for(home.market_force_name, home.settlement_key)
  BuyerQueues.enqueue(queue, unit_number)
end

function compact_customer_buyer_queue(queue)
  BuyerQueues.compact(queue)
end

function rebuild_customer_buyer_queues()
  storage.factoryx_customer_buyer_queues = {}
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    if entity and entity.valid and home and not customer_vehicle_owners()[unit_number]
      and not buyer_reserved_by_unit()[unit_number] then
      enqueue_customer_buyer(unit_number, home)
    end
  end
end

function customer_commute_timing_wheel()
  storage.factoryx_customer_commute_timing_wheel = TimingWheel.ensure(
    storage.factoryx_customer_commute_timing_wheel,
    3600
  )
  return storage.factoryx_customer_commute_timing_wheel
end

function customer_active_commutes()
  storage.factoryx_customer_active_commutes = storage.factoryx_customer_active_commutes or {}
  return storage.factoryx_customer_active_commutes
end

function schedule_customer_commute(unit_number, due_tick)
  if not unit_number then return end
  TimingWheel.schedule(customer_commute_timing_wheel(), unit_number, due_tick)
end

function enqueue_customer_commute(unit_number)
  local state = unit_number and customer_charging_commutes()[unit_number]
  schedule_customer_commute(
    unit_number,
    state and (state.retry_tick or state.next_charge_tick) or game.tick + 60
  )
end

function rebuild_customer_commute_queue()
  storage.factoryx_customer_commute_timing_wheel = TimingWheel.ensure(nil, 3600)
  storage.factoryx_customer_active_commutes = {}
  for unit_number, ownership in pairs(customer_vehicle_owners()) do
    local entity = customer_unit_registry()[unit_number]
    if ownership and entity and entity.valid then
      local state = customer_charging_commutes()[unit_number]
      if state and (state.phase == "to_charger" or state.phase == "charging") then
        customer_active_commutes()[unit_number] = true
      else
        enqueue_customer_commute(unit_number)
      end
    end
  end
end

function customer_commute_totals()
  storage.factoryx_customer_commute_totals = storage.factoryx_customer_commute_totals or {}
  return storage.factoryx_customer_commute_totals
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

  local nearest = nil
  local nearest_distance_squared = nil
  for _, pole in pairs(station.surface.find_entities_filtered{type = "electric-pole", force = station.force, area = area}) do
    if pole.valid and pole.name ~= STATION_GRID_CONNECTION_NAME then
      local dx = pole.position.x - position.x
      local dy = pole.position.y - position.y
      local distance_squared = dx * dx + dy * dy
      if distance_squared <= radius * radius
        and (not nearest_distance_squared or distance_squared < nearest_distance_squared) then
        nearest = pole
        nearest_distance_squared = distance_squared
      end
    end
  end
  return nearest
end

local function station_has_grid_access(station)
  return station and station.valid and nearby_real_power_pole(station) ~= nil
end

local function ensure_station_grid_connection(station)
  if not station or not station.valid or not station.unit_number then
    return nil
  end
  local real_pole = nearby_real_power_pole(station)
  if not real_pole then
    return nil
  end

  local connections = station_grid_connections()
  local connector = connections[station.unit_number]
  if not connector or not connector.valid then
    connector = station.surface.create_entity{
      name = STATION_GRID_CONNECTION_NAME,
      position = station.position,
      force = station.force
    }
    connections[station.unit_number] = connector
  end

  local charger_wire = connector.get_wire_connector(defines.wire_connector_id.pole_copper, true)
  local grid_wire = real_pole.get_wire_connector(defines.wire_connector_id.pole_copper, true)
  if charger_wire and grid_wire
    and (charger_wire.real_connection_count ~= 1 or not charger_wire.is_connected_to(grid_wire)) then
    charger_wire.disconnect_all()
    charger_wire.connect_to(grid_wire, false)
  end
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
    return false
  end
  local home_key, population = customer_settlement_population(settlement, market_force)
  if customer_unit_registry()[entity.unit_number] then
    if not customer_population_members()[entity.unit_number] then
      population.physical = (population.physical or 0) + 1
      customer_population_members()[entity.unit_number] = home_key
    end
    return true
  end
  local benchmark = script.active_mods["factoryx_perf_benchmark"] ~= nil
  if not benchmark and (customer_visible_count() >= CUSTOMER_VISIBLE_GLOBAL_LIMIT
    or population.physical >= CUSTOMER_VISIBLE_PER_SETTLEMENT_LIMIT) then
    population.virtual_unowned = (population.virtual_unowned or 0) + 1
    mark_factoryx_market_dirty(market_force, "customer-virtualized")
    entity.destroy()
    return false
  end
  customer_unit_registry()[entity.unit_number] = entity
  customer_home_settlements()[entity.unit_number] = {
    settlement_key = home_key,
    market_force_name = market_force.name
  }
  population.physical = (population.physical or 0) + 1
  customer_population_members()[entity.unit_number] = home_key
  storage.factoryx_customer_visible_count = customer_visible_count() + 1
  if not customer_vehicle_owners()[entity.unit_number]
    and not buyer_reserved_by_unit()[entity.unit_number] then
    enqueue_customer_buyer(entity.unit_number, customer_home_settlements()[entity.unit_number])
  end
  enqueue_customer_variant_migration(entity.unit_number)
  mark_factoryx_market_dirty(market_force, "customer-registered")
  return true
end

function customer_vehicle_aggregates()
  return CustomerAggregates.ensure(storage)
end

function customer_vehicle_aggregate(force_name)
  return CustomerAggregates.summary(storage, force_name)
end

function add_customer_vehicle_ownership(unit_number, ownership)
  return CustomerAggregates.add(storage, customer_vehicle_owners(), unit_number, ownership)
end

function remove_customer_vehicle_ownership(unit_number)
  return CustomerAggregates.remove(storage, customer_vehicle_owners(), unit_number)
end

function rebuild_customer_vehicle_aggregates()
  CustomerAggregates.rebuild(
    storage,
    customer_vehicle_owners(),
    customer_unit_registry(),
    customer_settlement_populations()
  )
end

function rebuild_customer_settlement_population_cache()
  local previous = storage.factoryx_customer_settlement_populations or {}
  storage.factoryx_customer_settlement_populations = {}
  storage.factoryx_customer_population_members = {}

  local settlements = {}
  for _, surface in pairs(game.surfaces) do
    for _, settlement in pairs(surface.find_entities_filtered{type = "unit-spawner"}) do
      if BITER_SETTLEMENT_NAMES[settlement.name] then
        settlements[settlement_key(surface, settlement)] = settlement
      end
    end
  end

  local restored = 0
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    local settlement = home and settlements[home.settlement_key]
    local market_force = home and game.forces[home.market_force_name]
    if entity and entity.valid and settlement and market_force then
      local _, population = customer_settlement_population(settlement, market_force)
      population.physical = (population.physical or 0) + 1
      customer_population_members()[unit_number] = home.settlement_key
      restored = restored + 1
    end
  end

  for key, old in pairs(previous) do
    local population = customer_settlement_populations()[key]
    if population then
      population.virtual_unowned = old.virtual_unowned or 0
      population.virtual_reserved = old.virtual_reserved or 0
      population.virtual_by_vehicle = old.virtual_by_vehicle or {}
    end
  end
  rebuild_customer_vehicle_aggregates()
  rebuild_customer_buyer_queues()
  return restored
end

function ensure_customer_settlement_population_cache()
  if next(customer_settlement_populations()) == nil
    and next(customer_unit_registry()) ~= nil then
    return rebuild_customer_settlement_population_cache()
  end
  return 0
end

function unregister_customer_unit(entity)
  if not entity or not entity.unit_number then
    return nil
  end
  local unit_number = entity.unit_number
  local home = customer_home_settlements()[unit_number]
  local ownership = remove_customer_vehicle_ownership(unit_number)
  customer_charging_commutes()[unit_number] = nil
  customer_active_commutes()[unit_number] = nil
  TimingWheel.cancel(customer_commute_timing_wheel(), unit_number)
  customer_unit_registry()[unit_number] = nil
  customer_home_settlements()[unit_number] = nil
  customer_population_members()[unit_number] = nil
  if home then
    local population = customer_settlement_populations()[home.settlement_key]
    if population then population.physical = math.max(0, (population.physical or 0) - 1) end
    storage.factoryx_customer_visible_count = math.max(0, customer_visible_count() - 1)
  end
  buyer_reserved_by_unit()[unit_number] = nil
  if ownership and ownership.market_force_name then
    mark_factoryx_market_dirty(game.forces[ownership.market_force_name], "customer-removed")
  end
  return ownership
end

function active_customer_vehicle_summary(force)
  return customer_vehicle_aggregate(force.name)
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
  sync_ev_sales_recipe_gates(force, true)
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

function consumer_ev_sales_total(force)
  local totals = sold_customer_evs(force)
  return math.max(0, math.floor(
    (totals["x-prototype-roadster"] or 0)
    + (totals["x-premium-ev"] or 0)
    + (totals["x-mass-market-ev"] or 0)
    + (totals["x-cybertruck"] or 0)
  ))
end

function ev_sales_gate_progress(force, gate)
  if gate.total_consumer_sales then return consumer_ev_sales_total(force) end
  return math.max(0, math.floor(sold_customer_evs(force)[gate.item] or 0))
end

function ev_sales_gate_announcements()
  storage.factoryx_ev_sales_gate_announcements = storage.factoryx_ev_sales_gate_announcements or {}
  return storage.factoryx_ev_sales_gate_announcements
end

function sync_ev_sales_recipe_gates(force, announce)
  if not force or not force.valid then return {} end
  local result = {}
  local announced = ev_sales_gate_announcements()[force.name] or {}
  ev_sales_gate_announcements()[force.name] = announced
  for gate_name, gate in pairs(EV_SALES_GATES) do
    local count = ev_sales_gate_progress(force, gate)
    local market_ready = count >= gate.threshold
    local technology_ready = researched(force, gate.technology) == true
    local enabled = market_ready and technology_ready
    for _, recipe_name in pairs(gate.recipes) do
      local recipe = force.recipes and force.recipes[recipe_name]
      if recipe then recipe.enabled = enabled end
    end
    if market_ready and not announced[gate_name] then
      announced[gate_name] = true
      if announce ~= false then
        force.print(string.format(
          "[FactoryX] Market milestone reached: %d/%d qualifying EV sales. %s production is now available%s.",
          count,
          gate.threshold,
          gate.label,
          technology_ready and "" or " after its technology is researched"
        ))
      end
    end
    result[gate_name] = {
      count = count,
      threshold = gate.threshold,
      market_ready = market_ready,
      technology_ready = technology_ready,
      enabled = enabled
    }
  end
  return result
end

function gigafactory_gate_announcements()
  storage.factoryx_gigafactory_gate_announcements =
    storage.factoryx_gigafactory_gate_announcements or {}
  return storage.factoryx_gigafactory_gate_announcements
end

function sync_gigafactory_production_gate(force, announce)
  if not force or not force.valid then return false end
  local produced = count_item_produced(force, PREMIUM_EV_NAME)
  local unlocked = researched(force, "x-premium-ev-program")
    and produced >= GIGAFACTORY_PRODUCTION_GATE
  for _, recipe_name in pairs({"x-gigafactory-module", "x-gigafactory-building"}) do
    local recipe = force.recipes and force.recipes[recipe_name]
    if recipe then recipe.enabled = unlocked end
  end
  local announcements = gigafactory_gate_announcements()
  if unlocked and not announcements[force.name] then
    announcements[force.name] = true
    if announce ~= false then
      force.print(string.format(
        "[FactoryX] Premium pilot run complete: %d Premium EVs produced. Gigafactory Modules and Gigafactory construction are now available.",
        GIGAFACTORY_PRODUCTION_GATE
      ))
    end
  end
  return unlocked
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
  return sorted_entities(registered_factoryx_entities("sales_offices", force))
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
  local generation = factoryx_market_generation()[force.index] or 0
  local cached = factoryx_market_cache()[force.index]
  if not advance_mood and cached and cached.tick == game.tick
    and cached.generation == generation then
    return cached.service
  end
  local service = {
    assignments = {},
    assignment_by_settlement_key = {},
    assigned_capacity_by_settlement_key = {},
    requested_capacity_by_settlement_key = {},
    powered_capacity_by_settlement_key = {},
    capacity_by_settlement_key = {},
    operational_keys = {},
    served_keys = {},
    served_settlements = {},
    angry_keys = {},
    accessible_stall_capacity = 0,
    powered_stall_capacity = 0,
    supported_ev_capacity = 0,
    average_evs_per_stall = 0,
    stranded_evs = 0,
    underserved_settlements = 0
  }
  if not player_market_force(force) then
    return service
  end

  local offices = force_sales_offices(force)
  local candidates = office_covered_settlements(offices)
  service.candidate_settlements = candidates
  local vehicle_summary = active_customer_vehicle_summary(force)
  service.vehicle_summary = vehicle_summary
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
    table.sort(station_candidates, function(left, right)
      local left_key = settlement_key(left.surface, left)
      local right_key = settlement_key(right.surface, right)
      local left_capacity = service.assigned_capacity_by_settlement_key[left_key] or 0
      local right_capacity = service.assigned_capacity_by_settlement_key[right_key] or 0
      if left_capacity ~= right_capacity then return left_capacity < right_capacity end
      local left_dx = left.position.x - station.position.x
      local left_dy = left.position.y - station.position.y
      local right_dx = right.position.x - station.position.x
      local right_dy = right.position.y - station.position.y
      local left_distance = left_dx * left_dx + left_dy * left_dy
      local right_distance = right_dx * right_dx + right_dy * right_dy
      if left_distance ~= right_distance then return left_distance < right_distance end
      return entity_sort_key(left) < entity_sort_key(right)
    end)
    local assignment = {
      station = station,
      settlements = {},
      operational_settlements = {},
      requested_settlement_keys = {},
      stall_loads = {},
      customer_requested_stalls = 0,
      requested_stalls = 0,
      powered_stalls = 0
    }
    for _, settlement in pairs(station_candidates) do
      local key = settlement_key(station.surface, settlement)
      if #assignment.settlements < config.stalls then
        assignment.settlements[#assignment.settlements + 1] = settlement
        service.assignment_by_settlement_key[key] = service.assignment_by_settlement_key[key] or station
        service.assigned_capacity_by_settlement_key[key] =
          (service.assigned_capacity_by_settlement_key[key] or 0) + config.evs_per_stall
      end
    end
    for stall_index, settlement in ipairs(assignment.settlements) do
      local key = settlement_key(settlement.surface, settlement)
      local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
      local requested_capacity = service.requested_capacity_by_settlement_key[key] or 0
      assignment.stall_loads[stall_index] = math.max(
        0,
        math.min(config.evs_per_stall, vehicle_count - requested_capacity)
      )
      if vehicle_count > requested_capacity then
        assignment.customer_requested_stalls = assignment.customer_requested_stalls + 1
        assignment.requested_settlement_keys[key] = true
        service.requested_capacity_by_settlement_key[key] = requested_capacity + config.evs_per_stall
      end
    end
    assignment.requested_stalls = assignment.customer_requested_stalls
    assignment.powered_stalls = powered_station_stalls(station, assignment.requested_stalls)
    local powered_remaining = assignment.powered_stalls
    for _, settlement in pairs(assignment.settlements) do
      local key = settlement_key(settlement.surface, settlement)
      local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
      if assignment.requested_settlement_keys[key] and powered_remaining > 0 then
        service.powered_capacity_by_settlement_key[key] =
          (service.powered_capacity_by_settlement_key[key] or 0) + config.evs_per_stall
        powered_remaining = powered_remaining - 1
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
    customer_settlement_market_forces()[key] = force.name
    local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
    local assigned_capacity = service.assigned_capacity_by_settlement_key[key] or 0
    local powered_capacity = service.powered_capacity_by_settlement_key[key] or 0
    service.capacity_by_settlement_key[key] = assigned_capacity
    if (vehicle_count == 0 and assigned_capacity > 0)
      or (vehicle_count > 0 and vehicle_count <= powered_capacity) then
      service.operational_keys[key] = true
    end
    if vehicle_count > powered_capacity then
      service.stranded_evs = service.stranded_evs + (vehicle_count - powered_capacity)
      service.underserved_settlements = service.underserved_settlements + 1
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

  for _, assignment in pairs(service.assignments) do
    for _, settlement in pairs(assignment.settlements) do
      local key = settlement_key(settlement.surface, settlement)
      if service.operational_keys[key] then
        assignment.operational_settlements[#assignment.operational_settlements + 1] = settlement
      end
    end
  end

  if service.powered_stall_capacity > 0 then
    service.average_evs_per_stall = math.floor(
      service.supported_ev_capacity / service.powered_stall_capacity + 0.5
    )
  end
  storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
  storage.factoryx_perf_counters.market_snapshot_builds =
    (storage.factoryx_perf_counters.market_snapshot_builds or 0) + 1
  factoryx_market_cache()[force.index] = {
    tick = game.tick,
    generation = generation,
    service = service
  }
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
  for index = 1, math.min(vehicle_stalls, #assignment.vehicles) do
    local vehicle = assignment.vehicles[index]
    local _, capacity = vehicle_battery_energy(vehicle)
    local joules = math.max(station_stall_power_watts(station), capacity * 0.03)
    if charge_vehicle(vehicle, joules) > 0 then
      charged = charged + 1
      if vehicle and vehicle.valid and vehicle.unit_number then
        storage.factoryx_vehicle_charge_activity = storage.factoryx_vehicle_charge_activity or {}
        storage.factoryx_vehicle_charge_activity[vehicle.unit_number] = game.tick
      end
    end
  end
  return charged
end

function ev_driver_overlay_states()
  storage.factoryx_ev_driver_overlay_states = storage.factoryx_ev_driver_overlay_states or {}
  return storage.factoryx_ev_driver_overlay_states
end

function ev_battery_popup_states()
  storage.factoryx_ev_battery_popups = storage.factoryx_ev_battery_popups or {}
  return storage.factoryx_ev_battery_popups
end

function destroy_ev_battery_popup(player_index)
  local states = ev_battery_popup_states()
  local state = states[player_index]
  if state and state.object and state.object.valid then state.object.destroy() end
  states[player_index] = nil
end

function show_ev_battery_popup(player, vehicle)
  if not player or not player.valid or not is_electric_vehicle(vehicle) then return end
  destroy_ev_battery_popup(player.index)
  local energy, capacity = vehicle_total_charge_energy(vehicle)
  local percent = capacity > 0 and math.floor(energy * 100 / capacity + 0.5) or 0
  local color
  if percent <= 20 then
    color = {r = 1.0, g = 0.25, b = 0.18}
  elseif percent <= 50 then
    color = {r = 1.0, g = 0.72, b = 0.18}
  else
    color = {r = 0.38, g = 1.0, b = 0.48}
  end
  local object = rendering.draw_text{
    text = string.format("BATTERY %d%%", percent),
    surface = vehicle.surface,
    target = vehicle,
    target_offset = {0, -2.4},
    color = {r = color.r, g = color.g, b = color.b, a = 1},
    alignment = "center",
    scale = 0.95,
    players = {player}
  }
  ev_battery_popup_states()[player.index] = {
    object = object,
    color = color,
    expires_tick = game.tick + EV_BATTERY_POPUP_TICKS
  }
end

function update_ev_battery_popups()
  for player_index, state in pairs(ev_battery_popup_states()) do
    if not state.object or not state.object.valid or game.tick >= state.expires_tick then
      destroy_ev_battery_popup(player_index)
    else
      local remaining = state.expires_tick - game.tick
      local alpha = math.min(1, remaining / EV_BATTERY_POPUP_FADE_TICKS)
      state.object.color = {
        r = state.color.r,
        g = state.color.g,
        b = state.color.b,
        a = alpha
      }
    end
  end
end

function destroy_ev_driver_overlay(player_index)
  local states = ev_driver_overlay_states()
  local state = states[player_index]
  if not state then return end
  for _, object in pairs(state.objects or {}) do
    if object and object.valid then object.destroy() end
  end
  states[player_index] = nil
end

function create_ev_driver_overlay(player, vehicle)
  destroy_ev_driver_overlay(player.index)
  local state = {
    vehicle = vehicle,
    vehicle_unit_number = vehicle.unit_number,
    objects = {},
    rebuilt_tick = game.tick,
    market_generation = factoryx_market_generation()[vehicle.force.index] or 0,
    rebuilt_position = {x = vehicle.position.x, y = vehicle.position.y}
  }
  for _, station in pairs(find_stations(vehicle.surface, vehicle.force)) do
    local config = station_config(station)
    local dx = station.position.x - vehicle.position.x
    local dy = station.position.y - vehicle.position.y
    if config and station_has_grid_access(station) and dx * dx + dy * dy <= 256 * 256 then
      state.objects[#state.objects + 1] = rendering.draw_circle{
        color = {r = 0.10, g = 0.75, b = 0.35, a = 0.16},
        radius = config.vehicle_charge_radius,
        width = 1,
        filled = true,
        draw_on_ground = true,
        target = station,
        surface = station.surface,
        players = {player}
      }
      state.objects[#state.objects + 1] = rendering.draw_circle{
        color = {r = 0.20, g = 1.0, b = 0.50, a = 0.8},
        radius = config.vehicle_charge_radius,
        width = 3,
        filled = false,
        draw_on_ground = true,
        target = station,
        surface = station.surface,
        players = {player}
      }
    end
  end
  state.charge_icon = rendering.draw_sprite{
    sprite = "item/x-electric-drive-charge",
    surface = vehicle.surface,
    target = vehicle,
    target_offset = {0, -2.1},
    x_scale = 0.55,
    y_scale = 0.55,
    tint = {r = 0.35, g = 1.0, b = 0.45, a = 1},
    render_layer = "air-object",
    players = {player},
    visible = false
  }
  state.objects[#state.objects + 1] = state.charge_icon
  state.charge_text = rendering.draw_text{
    text = "",
    surface = vehicle.surface,
    target = vehicle,
    target_offset = {0, -2.9},
    color = {r = 0.55, g = 1.0, b = 0.60, a = 1},
    alignment = "center",
    scale = 0.85,
    players = {player},
    visible = false
  }
  state.objects[#state.objects + 1] = state.charge_text
  ev_driver_overlay_states()[player.index] = state
  return state
end

function refresh_ev_driver_overlays()
  local activity = storage.factoryx_vehicle_charge_activity or {}
  local connected = {}
  for _, player in pairs(game.connected_players) do
    connected[player.index] = true
    local vehicle = player.vehicle
    if not is_electric_vehicle(vehicle) or not vehicle.unit_number then
      destroy_ev_driver_overlay(player.index)
    else
      local state = ev_driver_overlay_states()[player.index]
      local moved_far = state and state.rebuilt_position
        and ((vehicle.position.x - state.rebuilt_position.x) ^ 2
          + (vehicle.position.y - state.rebuilt_position.y) ^ 2 > 64 * 64)
      local market_changed = state
        and state.market_generation ~= (factoryx_market_generation()[vehicle.force.index] or 0)
      if not state or state.vehicle_unit_number ~= vehicle.unit_number
        or not state.vehicle or not state.vehicle.valid
        or moved_far or market_changed then
        state = create_ev_driver_overlay(player, vehicle)
      end
      local charging = game.tick - (activity[vehicle.unit_number] or -1000) <= 75
      local energy, capacity = vehicle_total_charge_energy(vehicle)
      local percent = capacity > 0 and math.floor(energy * 100 / capacity + 0.5) or 0
      local pulse = 0.48 + (math.floor(game.tick / 10) % 2) * 0.14
      state.charge_icon.visible = charging
      state.charge_icon.x_scale = pulse
      state.charge_icon.y_scale = pulse
      state.charge_text.visible = charging
      state.charge_text.text = string.format("CHARGING %d%%", percent)
    end
  end
  for player_index in pairs(ev_driver_overlay_states()) do
    if not connected[player_index] then destroy_ev_driver_overlay(player_index) end
  end
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

function customer_commute_interval_ticks(entity, ownership)
  local base = CUSTOMER_COMMUTE_INTERVALS[ownership.vehicle] or (5 * 60 * 60)
  local market_force = game.forces[ownership.market_force_name]
  local battery_level = market_force
    and continuous_improvement_level(market_force, LONG_RANGE_BATTERY_TECH_NAME)
    or 0
  return math.floor(base * (1 + battery_level * 0.25))
end

function customer_commute_station_counts()
  local counts = {}
  for unit_number in pairs(customer_active_commutes()) do
    local state = customer_charging_commutes()[unit_number]
    if state then
    if (state.phase == "to_charger" or state.phase == "charging") and state.station_unit_number then
      local count = counts[state.station_unit_number] or {en_route = 0, charging = 0, active = 0}
      counts[state.station_unit_number] = count
      count.active = count.active + 1
      if state.phase == "charging" then
        count.charging = count.charging + 1
      else
        count.en_route = count.en_route + 1
      end
    end
    end
  end
  return counts
end

function customer_commute_summary(force)
  local summary = {
    scheduled = 0,
    en_route = 0,
    charging = 0,
    retrying = 0,
    completed = customer_commute_totals()[force.name] or 0
  }
  for unit_number, state in pairs(customer_charging_commutes()) do
    local ownership = customer_vehicle_owners()[unit_number]
    if ownership and ownership.market_force_name == force.name then
      if state.phase == "to_charger" then summary.en_route = summary.en_route + 1
      elseif state.phase == "charging" then summary.charging = summary.charging + 1
      elseif state.retry_tick and state.retry_tick > game.tick then summary.retrying = summary.retrying + 1
      else summary.scheduled = summary.scheduled + 1 end
    end
  end
  summary.active = summary.en_route + summary.charging
  return summary
end

function select_customer_commute_station(entity, force, service, station_counts)
  local selected
  local selected_distance
  for unit_number, assignment in pairs(service.assignments or {}) do
    local station = assignment.station
    if station and station.valid and station.surface == entity.surface
      and station_has_grid_access(station) and (assignment.powered_stalls or 0) > 0 then
      local occupancy = station_counts[unit_number] and station_counts[unit_number].active or 0
      local commuter_capacity = assignment.powered_stalls * 8
      if occupancy < commuter_capacity then
        local dx = station.position.x - entity.position.x
        local dy = station.position.y - entity.position.y
        local distance = dx * dx + dy * dy
        if not selected_distance or distance < selected_distance then
          selected = station
          selected_distance = distance
        end
      end
    end
  end
  return selected
end

function customer_commute_staging_position(entity, station, occupancy)
  local config = station_config(station)
  local radius = 3.5 + math.min(3, (config and config.stalls or 4) / 8)
  local angle = ((station.unit_number or 0) * 0.37 + occupancy * 2.399963) % (2 * math.pi)
  local target = {
    x = station.position.x + math.cos(angle) * radius,
    y = station.position.y + math.sin(angle) * radius
  }
  return station.surface.find_non_colliding_position(entity.name, target, 8, 0.5) or target
end

function begin_customer_charging_commute(entity, ownership, state, station, station_counts)
  if not entity.commandable then return false end
  local counts = station_counts[station.unit_number] or {en_route = 0, charging = 0, active = 0}
  station_counts[station.unit_number] = counts
  local destination = customer_commute_staging_position(entity, station, counts.active)
  entity.commandable.set_command{
    type = defines.command.go_to_location,
    destination = destination,
    distraction = defines.distraction.none,
    radius = 1.5
  }
  state.phase = "to_charger"
  state.station = station
  state.station_unit_number = station.unit_number
  state.destination = destination
  state.command_started_tick = game.tick
  state.retry_tick = nil
  counts.en_route = counts.en_route + 1
  counts.active = counts.active + 1
  customer_active_commutes()[entity.unit_number] = true
  return true
end

function retry_customer_charging_commute(entity, state)
  local attempts = math.min(5, (state.retry_attempts or 0) + 1)
  state.phase = "roaming"
  state.station = nil
  state.station_unit_number = nil
  state.destination = nil
  state.retry_attempts = attempts
  state.retry_tick = game.tick + math.min(
    CUSTOMER_COMMUTE_RETRY_MAX_TICKS,
    CUSTOMER_COMMUTE_RETRY_BASE_TICKS * (2 ^ (attempts - 1))
  )
  if entity and entity.unit_number then
    customer_active_commutes()[entity.unit_number] = nil
    enqueue_customer_commute(entity.unit_number)
  end
  if entity and entity.valid then give_customer_wander_command(entity, true) end
end

function send_customer_home_after_charging(entity, state)
  local home = entity and entity.unit_number and customer_home_settlements()[entity.unit_number]
  local population = home and home.settlement_key
    and customer_settlement_populations()[home.settlement_key]
  local surface_index = population and population.surface_index or (home and home.surface_index)
  local surface = entity and entity.surface
  local home_position = population and population.position or (home and home.position)
  if not entity or not entity.valid or not entity.commandable or not home_position
    or (surface_index and surface_index ~= surface.index) then
    return false
  end
  local visit = state.completed_visits or 0
  local angle = ((entity.unit_number * 0.61803398875) + visit * 2.399963) % (2 * math.pi)
  local radius = 8 + ((entity.unit_number * 7 + visit * 11) % 13)
  local target = {
    x = home_position.x + math.cos(angle) * radius,
    y = home_position.y + math.sin(angle) * radius
  }
  local destination = surface.find_non_colliding_position(entity.name, target, 12, 0.5) or target
  entity.commandable.set_command{
    type = defines.command.go_to_location,
    destination = destination,
    distraction = defines.distraction.none,
    radius = 2
  }
  state.phase = "returning_home"
  state.return_destination = destination
  return true
end

function complete_customer_charging_commute(entity, ownership, state)
  state.phase = "roaming"
  state.station = nil
  state.station_unit_number = nil
  state.destination = nil
  state.charge_progress = 0
  state.retry_attempts = 0
  state.retry_tick = nil
  state.completed_visits = (state.completed_visits or 0) + 1
  customer_commute_totals()[ownership.market_force_name] =
    (customer_commute_totals()[ownership.market_force_name] or 0) + 1
  state.next_charge_tick = game.tick + customer_commute_interval_ticks(entity, ownership)
  customer_active_commutes()[entity.unit_number] = nil
  enqueue_customer_commute(entity.unit_number)
  if not send_customer_home_after_charging(entity, state) then
    give_customer_wander_command(entity, true)
  end
end

function process_customer_charging_commutes()
  local states = customer_charging_commutes()
  local station_counts = customer_commute_station_counts()
  local active = 0
  for unit_number in pairs(customer_active_commutes()) do
    local state = states[unit_number]
    local entity = customer_unit_registry()[unit_number]
    local ownership = customer_vehicle_owners()[unit_number]
    if not state or not entity or not entity.valid or not ownership then
      states[unit_number] = nil
      customer_active_commutes()[unit_number] = nil
    elseif state.phase == "to_charger" then
      active = active + 1
      if not state.station or not state.station.valid or not station_has_grid_access(state.station) then
        retry_customer_charging_commute(entity, state)
      elseif game.tick - (state.command_started_tick or game.tick) >= CUSTOMER_COMMUTE_PATH_TIMEOUT_TICKS then
        retry_customer_charging_commute(entity, state)
      end
    elseif state.phase == "charging" then
      active = active + 1
      local station = state.station
      if not station or not station.valid or not station_has_grid_access(station) then
        retry_customer_charging_commute(entity, state)
      else
        local power = station_power_service()[station.unit_number] or {}
        local fraction = math.max(0, math.min(1, power.power_fraction or 0))
        local supercharging = continuous_improvement_level(station.force, SUPERCHARGING_TECH_NAME)
        state.charge_progress = (state.charge_progress or 0)
          + fraction * (1 + supercharging * 0.1) / CUSTOMER_COMMUTE_CHARGE_SECONDS
        if state.charge_progress >= 1 then
          complete_customer_charging_commute(entity, ownership, state)
        end
      end
    end
  end

  local starts = 0
  if active >= CUSTOMER_COMMUTE_MAX_ACTIVE then return end
  local service_by_force = {}
  local due_units = TimingWheel.pop_due(
    customer_commute_timing_wheel(),
    game.tick,
    CUSTOMER_COMMUTE_SCHEDULER_BATCH
  )
  for index, unit_number in ipairs(due_units) do
    if starts >= CUSTOMER_COMMUTE_STARTS_PER_SECOND
      or active + starts >= CUSTOMER_COMMUTE_MAX_ACTIVE then
      for deferred = index, #due_units do
        schedule_customer_commute(due_units[deferred], game.tick + 60)
      end
      break
    end
    local ownership = customer_vehicle_owners()[unit_number]
    local entity = customer_unit_registry()[unit_number]
    if ownership and entity and entity.valid then
      local state = states[unit_number]
      if not state then
        state = {
          phase = "roaming",
          next_charge_tick = game.tick + CUSTOMER_COMMUTE_FIRST_VISIT_TICKS,
          completed_visits = 0
        }
        states[unit_number] = state
      end
      local due = state.phase == "roaming"
        and game.tick >= (state.retry_tick or state.next_charge_tick or game.tick)
      if due then
        local force = game.forces[ownership.market_force_name]
        if force then
          service_by_force[force.index] = service_by_force[force.index]
            or customer_service_for_force(force)
          local station = select_customer_commute_station(
            entity, force, service_by_force[force.index], station_counts
          )
          if station and begin_customer_charging_commute(
            entity, ownership, state, station, station_counts
          ) then
            starts = starts + 1
          else
            retry_customer_charging_commute(entity, state)
          end
        end
      else
        enqueue_customer_commute(unit_number)
      end
    end
  end
end

function handle_customer_commute_command_completed(event)
  local state = event.unit_number and customer_charging_commutes()[event.unit_number]
  if not state then return end
  local entity = customer_unit_registry()[event.unit_number]
  if not entity or not entity.valid then
    customer_charging_commutes()[event.unit_number] = nil
    return
  end
  if state.phase == "returning_home" then
    state.phase = "roaming"
    state.return_destination = nil
    give_customer_wander_command(entity, true)
    return
  elseif state.phase ~= "to_charger" then
    return
  end
  local destination = state.destination
  local dx = destination and entity.position.x - destination.x or math.huge
  local dy = destination and entity.position.y - destination.y or math.huge
  if destination and dx * dx + dy * dy <= 36 then
    state.phase = "charging"
    state.charge_progress = 0
    state.arrived_tick = game.tick
    entity.commandable.set_command{
      type = defines.command.wander,
      distraction = defines.distraction.none,
      radius = 0.25,
      ticks_to_wait = 60
    }
  else
    retry_customer_charging_commute(entity, state)
  end
end

function customer_vehicle_variant_name(entity_name, vehicle_name)
  local base_name = CUSTOMER_UNIT_BASE_BY_NAME[entity_name]
  local class_name = CUSTOMER_VEHICLE_CLASS_BY_ITEM[vehicle_name]
  if not base_name or not class_name then
    return nil
  end
  return "x-" .. base_name .. "-" .. class_name
end

function customer_prospect_variant_name(entity_name)
  local base_name = CUSTOMER_UNIT_BASE_BY_NAME[entity_name]
  if not base_name then return nil end
  return "x-" .. base_name .. "-prospect"
end

function replace_customer_prospect_entity(entity)
  if not entity or not entity.valid or not entity.unit_number
    or customer_vehicle_owners()[entity.unit_number] then
    return entity
  end
  local target_name = customer_prospect_variant_name(entity.name)
  if not target_name or entity.name == target_name then return entity end

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
  if not replacement or not replacement.valid or not replacement.unit_number then return entity end

  replacement.health = math.max(1, replacement.max_health * health_ratio)
  customer_unit_registry()[replacement.unit_number] = replacement
  customer_home_settlements()[replacement.unit_number] = home
  customer_population_members()[replacement.unit_number] = customer_population_members()[old_unit_number]
  if home then
    local queue = buyer_queue_for(home.market_force_name, home.settlement_key)
    for index = queue.head, #queue.units do
      if queue.units[index] == old_unit_number then queue.units[index] = replacement.unit_number end
    end
  end
  if reserved_office then
    buyer_reserved_by_unit()[replacement.unit_number] = reserved_office
    local reservation = office_buyer_reservations()[reserved_office]
    if reservation then
      for index, unit_number in pairs(reservation.buyers or {}) do
        if unit_number == old_unit_number then reservation.buyers[index] = replacement.unit_number end
      end
    end
  end

  destroy_customer_marker(entity)
  customer_unit_registry()[old_unit_number] = nil
  customer_home_settlements()[old_unit_number] = nil
  customer_population_members()[old_unit_number] = nil
  buyer_reserved_by_unit()[old_unit_number] = nil
  entity.destroy()
  give_customer_wander_command(replacement, true)
  draw_customer_marker(replacement)
  return replacement
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
  customer_population_members()[replacement.unit_number] = customer_population_members()[old_unit_number]
  customer_vehicle_owners()[replacement.unit_number] = ownership
  if customer_charging_commutes()[old_unit_number] then
    customer_charging_commutes()[replacement.unit_number] = customer_charging_commutes()[old_unit_number]
    customer_charging_commutes()[old_unit_number] = nil
  end
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
  customer_population_members()[old_unit_number] = nil
  customer_vehicle_owners()[old_unit_number] = nil
  buyer_reserved_by_unit()[old_unit_number] = nil
  entity.destroy()
  give_customer_wander_command(replacement, true)
  return replacement
end

function queue_customer_vehicle_variant_migration()
  local queue = {}
  for unit_number, entity in pairs(customer_unit_registry()) do
    local ownership = customer_vehicle_owners()[unit_number]
    local target_name = entity and entity.valid and (ownership
      and customer_vehicle_variant_name(entity.name, ownership.vehicle)
      or customer_prospect_variant_name(entity.name))
    if entity and entity.valid and target_name and target_name ~= entity.name then
      queue[#queue + 1] = unit_number
    end
  end
  storage.factoryx_customer_vehicle_variant_queue = queue
  return #queue
end

function enqueue_customer_variant_migration(unit_number)
  if not unit_number then return end
  storage.factoryx_customer_vehicle_variant_queue = storage.factoryx_customer_vehicle_variant_queue or {}
  local queue = storage.factoryx_customer_vehicle_variant_queue
  queue[#queue + 1] = unit_number
end

function process_customer_vehicle_variant_migration(limit)
  local queue = storage.factoryx_customer_vehicle_variant_queue or {}
  local migrated = 0
  while #queue > 0 and migrated < (limit or 50) do
    local unit_number = table.remove(queue)
    local entity = customer_unit_registry()[unit_number]
    local ownership = customer_vehicle_owners()[unit_number]
    if entity and entity.valid then
      if ownership then
        replace_customer_vehicle_entity(entity, ownership)
      else
        replace_customer_prospect_entity(entity)
      end
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

function set_charger_placement_overlay(player, enabled)
  if not player or not player.valid or not player.connected then
    return false
  end
  local ok, error_message = pcall(function()
    player.map_view_settings = {
      ["show-electric-network"] = enabled,
      ["show-logistic-network"] = false
    }
  end)
  if not ok then
    storage.factoryx_charger_overlay_warnings = storage.factoryx_charger_overlay_warnings or {}
    if not storage.factoryx_charger_overlay_warnings[player.index] then
      storage.factoryx_charger_overlay_warnings[player.index] = true
      log("[FactoryX] Charger placement overlay unavailable for player "
        .. player.index .. ": " .. tostring(error_message))
    end
  end
  return ok
end

function sync_charger_placement_overlay(player)
  if not player or not player.valid then
    return
  end
  local states = charger_placement_overlay_states()
  if not player.connected then
    states[player.index] = nil
    return
  end
  local stack = player.cursor_stack
  local holding_charger = stack and stack.valid_for_read and STATION_CONFIGS[stack.name] ~= nil
  local previous = states[player.index]
  if holding_charger then
    if not previous and set_charger_placement_overlay(player, true) then
      states[player.index] = true
    end
  elseif previous then
    -- MapViewSettings is write-only, so FactoryX can only clear the overlay it enabled.
    set_charger_placement_overlay(player, false)
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
    local commute = entity.unit_number and customer_charging_commutes()[entity.unit_number]
    if not commute or (commute.phase ~= "to_charger" and commute.phase ~= "charging"
      and commute.phase ~= "returning_home") then
      give_customer_wander_command(entity)
    end
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

function ensure_seed_customer(settlement, market_force)
  local key, population = customer_settlement_population(settlement, market_force)
  local population_size = (population.physical or 0)
    + (population.virtual_unowned or 0)
    + (population.virtual_reserved or 0)
  for _, count in pairs(population.virtual_by_vehicle or {}) do
    population_size = population_size + count
  end
  if population_size > 0 then
    return nil
  end

  local unit_name = settlement.name == "spitter-spawner" and "small-spitter" or "small-biter"
  local target = {
    x = settlement.position.x + 3,
    y = settlement.position.y + 3
  }
  local position = settlement.surface.find_non_colliding_position(unit_name, target, 12, 0.5)
  if not position then
    return nil
  end
  local customer = settlement.surface.create_entity{
    name = unit_name,
    position = position,
    force = customer_force()
  }
  if customer and register_customer_unit(customer, settlement, market_force) then
    draw_customer_marker(customer)
    give_customer_wander_command(customer, true)
    mark_factoryx_market_dirty(market_force, "settlement-seed-customer")
    return customer
  end
  if customer and customer.valid then
    customer.destroy()
  end
  return nil
end

function convert_station_area_customers(market_force, service)
  local enemy = game.forces.enemy
  local customers = customer_force()
  local offices = force_sales_offices(market_force)
  local converted = 0
  for _, assignment in pairs(service.assignments or {}) do
    local station = assignment.station
    local config = station and station.valid and station_config(station)
    if config and #assignment.settlements > 0 then
      local area = area_around(station.position, config.customer_radius)
      for _, source_force in pairs({enemy, customers}) do
        scan_biter_customer_entities(station.surface, source_force, area, function(entity)
          if entity.type == "unit"
            and within_radius(station, entity, config.customer_radius)
            and position_has_sales_coverage(entity.surface, entity.position, offices) then
            local nearest
            local nearest_distance
            for _, settlement in pairs(assignment.settlements) do
              local dx = settlement.position.x - entity.position.x
              local dy = settlement.position.y - entity.position.y
              local distance = dx * dx + dy * dy
              if not nearest_distance or distance < nearest_distance then
                nearest = settlement
                nearest_distance = distance
              end
            end
            if nearest and register_customer_unit(entity, nearest, market_force) then
              if convert_biter_entity(entity, customers) then
                converted = converted + 1
              end
              draw_customer_marker(entity)
            end
          end
        end)
      end
    end
  end
  return converted
end

function sync_customer_settlements()
  if not biter_customer_mode_enabled() then
    return {customer_settlements = 0, converted_to_customer = 0, reverted_to_enemy = 0, reverted_hostile_worms = 0}
  end

  local enemy = game.forces.enemy
  local customers = customer_force()
  local covered = {}
  local served_home_keys = {}
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
          served_home_keys[key] = true
          if convert_biter_entity(settlement, customers) then
            converted = converted + 1
          end
          draw_customer_marker(settlement)
          customer_settlements = customer_settlements + 1
        end
      end
      converted = converted + convert_station_area_customers(force, service)
      for _, settlement in pairs(service.served_settlements) do
        if settlement.valid then
          local area = area_around(settlement.position, CUSTOMER_MOBILE_SERVICE_RADIUS)
          for _, source_force in pairs({enemy, customers}) do
            scan_biter_customer_entities(settlement.surface, source_force, area, function(entity)
              if not BITER_SETTLEMENT_NAMES[entity.name]
                and within_radius(settlement, entity, CUSTOMER_MOBILE_SERVICE_RADIUS) then
                local key = settlement_key(settlement.surface, entity)
                covered[key] = true
                if register_customer_unit(entity, settlement, force) then
                  if convert_biter_entity(entity, customers) then
                    converted = converted + 1
                  end
                  draw_customer_marker(entity)
                end
              end
            end)
          end
          ensure_seed_customer(settlement, force)
        end
      end
    end
  end

  -- Customer status follows the served home settlement, not roaming position.
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    if entity and entity.valid and home and served_home_keys[home.settlement_key] then
      covered[settlement_key(entity.surface, entity)] = true
      if convert_biter_entity(entity, customers) then converted = converted + 1 end
      draw_customer_marker(entity)
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
          destroy_customer_marker(entity)
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
  customer_settlement_market_forces()[settlement_key(settlement.surface, settlement)] = station.force.name
  mark_factoryx_market_dirty(station.force, "settlement-growth")
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
  local states = customer_growth_states()
  local referral_level = continuous_improvement_level(force, CUSTOMER_REFERRAL_TECH_NAME)
  local referral_multiplier = 1 + referral_level * 0.1
  for unit_number, assignment in pairs(service.assignments) do
    local station = assignment.station
    if station and station.valid then
      local state = states[unit_number] or {progress = 0, colonies = 0}
      states[unit_number] = state
      local active_stalls = math.min(
        assignment.requested_stalls or 0,
        assignment.powered_stalls or 0
      )
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
  local assignment = service.assignments[station.unit_number]
  local assigned_keys = {}
  for _, settlement in pairs(assignment and assignment.settlements or {}) do
    assigned_keys[settlement_key(settlement.surface, settlement)] = true
  end
  local count = 0
  for key, population in pairs(customer_settlement_populations()) do
    if population.market_force_name == station.force.name
      and service.operational_keys[key]
      and assigned_keys[key] then
      count = count + math.max(
        0,
        (population.virtual_unowned or 0) - (population.virtual_reserved or 0)
      )
    end
  end
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    if entity and entity.valid and entity.force.name == CUSTOMER_FORCE_NAME
      and home and service.operational_keys[home.settlement_key]
      and assigned_keys[home.settlement_key]
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
  local screen_panel = player.gui.screen[STATION_INFO_PANEL_NAME]
  if screen_panel then screen_panel.destroy() end
  local legacy_panel = player.gui.relative[STATION_INFO_PANEL_NAME]
  if legacy_panel then legacy_panel.destroy() end
end

function factoryx_relative_anchor(entity)
  local gui_type = entity.type == "logistic-container"
    and defines.relative_gui_type.container_gui
    or defines.relative_gui_type.assembling_machine_gui
  return {
    gui = gui_type,
    position = defines.relative_gui_position.right
  }
end

function opened_factoryx_entities()
  storage.factoryx_opened_entities = storage.factoryx_opened_entities or {}
  return storage.factoryx_opened_entities
end

local function add_station_info_label(parent, caption, color)
  local label = parent.add{
    type = "label",
    caption = caption,
    single_line = false
  }
  if color then label.style.font_color = color end
  return label
end

function add_factoryx_metric_table(parent, rows)
  local metrics = parent.add{type = "table", column_count = 3}
  metrics.style.horizontal_spacing = 8
  metrics.style.vertical_spacing = 4
  for _, row in pairs(rows) do
    local icon = metrics.add{type = "sprite", sprite = row.sprite, tooltip = row.tooltip}
    icon.style.width = 24
    icon.style.height = 24
    icon.style.stretch_image_to_widget_size = true
    local label = metrics.add{type = "label", caption = row.label}
    label.style.width = 112
    local value = metrics.add{type = "label", caption = row.value}
    value.style.width = 190
    value.style.horizontal_align = "right"
    if row.color then value.style.font_color = row.color end
  end
  return metrics
end

function add_factoryx_status_strip(parent, caption, color)
  local line = parent.add{type = "line"}
  line.style.top_margin = 4
  local label = parent.add{type = "label", caption = caption, single_line = false}
  label.style.top_margin = 4
  if color then label.style.font_color = color end
  return label
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
  return "This site serves customer EVs and prints EV Reservations for Sales Offices."
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
  local service = customer_growth_summary(station.force)
  local reservation_rate = station_reservation_demand(station, active_stalls, service)
    * RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE
  local reservation_inventory = station_reservation_inventory(station)
  local reservation_stock = reservation_inventory and reservation_inventory.get_item_count(RESERVATION_NAME) or 0
  local researched_power_per_stall_kw = station_stall_power_watts(station) / 1000
  local power_draw_kw = active_stalls * researched_power_per_stall_kw
  local power_state = station_power_service()[station.unit_number] or {power_fraction = grid_connected and 1 or 0}
  local assignment = service.assignments[station.unit_number]
  local friendly_here = assignment and #assignment.operational_settlements or 0
  local commute_counts = customer_commute_station_counts()[station.unit_number]
    or {en_route = 0, charging = 0}
  local underserved_here = 0
  local seen_settlements = {}
  local vehicle_summary = service.vehicle_summary or active_customer_vehicle_summary(station.force)
  for _, settlement in pairs(assignment and assignment.settlements or {}) do
    local key = settlement_key(settlement.surface, settlement)
    if not seen_settlements[key] then
      underserved_here = underserved_here + math.max(
        0,
        (vehicle_summary.by_settlement[key] or 0)
          - (service.powered_capacity_by_settlement_key[key] or 0)
      )
      seen_settlements[key] = true
    end
  end
  local panel = player.gui.screen.add{
    type = "frame",
    name = STATION_INFO_PANEL_NAME,
    direction = "vertical"
  }
  panel.style.width = 380
  panel.auto_center = true
  local titlebar = panel.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = panel
  titlebar.add{type = "label", caption = "FactoryX " .. config.display_name, style = "frame_title"}
  local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.drag_target = panel
  titlebar.add{
    type = "sprite-button",
    name = "factoryx_station_info_close",
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = "Close"
  }

  local power_percent = math.floor((power_state.power_fraction or 0) * 100 + 0.5)
  local state_text = grid_connected and (power_percent > 0 and "Powered" or "No power") or "No grid"
  local state_color = grid_connected and (power_percent > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.bad)
    or FACTORYX_STATE_COLORS.bad
  local state_row = panel.add{type = "flow", direction = "horizontal"}
  state_row.add{type = "label", caption = "State: "}
  add_station_info_label(state_row, state_text, state_color)

  add_factoryx_metric_table(panel, {
    {sprite = "item/x-ev-charging-station", label = "Stalls", value = string.format("%d / %d active", active_stalls, config.stalls)},
    {sprite = "item/x-mass-market-ev", label = "EV capacity", value = string.format("%d / %d", active_stalls * config.evs_per_stall, config.stalls * config.evs_per_stall)},
    {sprite = "entity/biter-spawner", label = "Settlements", value = string.format("%d served", friendly_here)},
    {sprite = "item/x-ev-charging-station", label = "Underserved", value = tostring(underserved_here), color = underserved_here > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good},
    {sprite = "item/x-prototype-roadster", label = "Commutes", value = string.format("%d in / %d charging", commute_counts.en_route, commute_counts.charging)},
    {sprite = "item/accumulator", label = "Power", value = string.format("%.0f / %.0f kW", power_draw_kw, config.stalls * researched_power_per_stall_kw)},
    {sprite = "item/x-ev-reservation", label = "Reservations", value = string.format("%d / min", reservation_rate)},
    {sprite = "item/x-ev-reservation", label = "Stored", value = tostring(reservation_stock)}
  })

  local summary
  local summary_color
  if not grid_connected or power_percent == 0 then
    summary, summary_color = "Connect and power this charger.", FACTORYX_STATE_COLORS.bad
  elseif underserved_here > 0 then
    summary, summary_color = string.format("%d EVs need charging capacity.", underserved_here), FACTORYX_STATE_COLORS.bad
  elseif hostile_settlements > 0 and covered_settlements == 0 then
    summary, summary_color = "Add Sales Office coverage.", FACTORYX_STATE_COLORS.warning
  elseif active_stalls < config.stalls then
    summary, summary_color = string.format("%d stalls available.", config.stalls - active_stalls), FACTORYX_STATE_COLORS.good
  else
    summary, summary_color = "Charger operating at capacity.", FACTORYX_STATE_COLORS.good
  end
  add_factoryx_status_strip(panel, summary, summary_color)
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
  for _, office in pairs(registered_factoryx_entities("sales_offices", force)) do
      if office.valid and RESERVATION_RECIPES[current_recipe_name(office)] then
        offices[#offices + 1] = office
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

unlock_vehicle_recycling = function(force)
  local technology = force.technologies and force.technologies.recycling
  if not technology or technology.enabled or technology.researched then return false end
  technology.enabled = true
  return true
end

generate_station_wrecks = function(station, completed_charges)
  local inventory = station_reservation_inventory(station)
  if not inventory or completed_charges <= 0 then return 0 end
  local wrecks = 0
  for _ = 1, completed_charges do
    if math.random() < 0.01 then wrecks = wrecks + 1 end
  end
  if wrecks == 0 then return 0 end
  local inserted = inventory.insert{name = WRECKED_EV_NAME, count = wrecks}
  if inserted > 0 then
    local statistics = station.force.get_item_production_statistics(station.surface)
    statistics.set_output_count(WRECKED_EV_NAME, statistics.get_output_count(WRECKED_EV_NAME) + inserted)
    unlock_vehicle_recycling(station.force)
  end
  return inserted
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
          generate_station_wrecks(station, inserted)
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
  local existing = center.surface.find_entities_filtered{
    name = ROBOTAXI_SERVICE_POWER_NAME,
    position = center.position,
    radius = 0.25,
    force = center.force
  }
  for _, candidate in pairs(existing) do
    if candidate.valid then
      if not power then
        power = candidate
      else
        candidate.destroy()
      end
    end
  end
  if power then
    powers[center.unit_number] = power
    return power
  end
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

function robotaxi_customer_allocations(force)
  if not force then return {} end
  storage.factoryx_robotaxi_allocation_cache = storage.factoryx_robotaxi_allocation_cache or {}
  local cached = storage.factoryx_robotaxi_allocation_cache[force.index]
  if cached and game.tick - cached.tick < 300 then
    return cached.allocations
  end
  local result = {}
  local customer_force = game.forces[CUSTOMER_FORCE_NAME]
  if not customer_force then return result end
  local centers_by_surface = {}
  for _, center in pairs(registered_factoryx_entities("robotaxi_centers", force)) do
    centers_by_surface[center.surface.index] = centers_by_surface[center.surface.index] or {}
    centers_by_surface[center.surface.index][#centers_by_surface[center.surface.index] + 1] = center
  end
  for surface_index, centers in pairs(centers_by_surface) do
    local surface = game.surfaces[surface_index]
    table.sort(centers, function(a, b) return a.unit_number < b.unit_number end)
    local available = {}
    for _, center in pairs(centers) do
      local inventory = robotaxi_service_inventories(center)
      local stored = inventory and math.min(200, inventory.get_item_count(ROBOTAXI_ITEM_NAME)) or 0
      available[center.unit_number] = stored > 0
      result[center.unit_number] = 0
    end
    for _, population in pairs(customer_settlement_populations()) do
      if population.market_force_name == force.name and population.surface_index == surface_index then
        local selected
        local best_distance
        for _, center in pairs(centers) do
          if available[center.unit_number] then
            local dx = population.position.x - center.position.x
            local dy = population.position.y - center.position.y
            local distance = dx * dx + dy * dy
            if distance <= ROBOTAXI_SERVICE_RADIUS * ROBOTAXI_SERVICE_RADIUS
              and (not best_distance or distance < best_distance) then
              selected = center
              best_distance = distance
            end
          end
        end
        if selected then
          local customers = (population.physical or 0) + (population.virtual_unowned or 0)
          for _, count in pairs(population.virtual_by_vehicle or {}) do customers = customers + count end
          result[selected.unit_number] = result[selected.unit_number] + customers
        end
      end
    end
  end
  storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
  storage.factoryx_perf_counters.robotaxi_allocation_builds =
    (storage.factoryx_perf_counters.robotaxi_allocation_builds or 0) + 1
  storage.factoryx_robotaxi_allocation_cache[force.index] = {
    tick = game.tick,
    allocations = result
  }
  return result
end

function robotaxi_service_power_factor(center)
  local power = ensure_robotaxi_service_power(center)
  if not power then return 0 end
  if power.status == defines.entity_status.no_power then return 0 end
  if power.status == defines.entity_status.low_power then return 0.5 end
  return power.energy and power.energy > 0 and 1 or 0
end

function robotaxi_service_snapshot(center, allocated_customers)
  local input, output = robotaxi_service_inventories(center)
  local stored = input and input.get_item_count(ROBOTAXI_ITEM_NAME) or 0
  local customers = allocated_customers
  if customers == nil then
    customers = robotaxi_customer_allocations(center.force)[center.unit_number] or 0
  end
  local power_factor = robotaxi_service_power_factor(center)
  local audio_level = continuous_improvement_level(center.force, PREMIUM_AUDIO_TECH_NAME)
  local metrics = RobotaxiService.metrics{
    max_fleet = 200,
    stored = stored,
    customers = customers,
    customers_per_vehicle = ROBOTAXI_CUSTOMERS_PER_VEHICLE,
    vehicle_minutes_per_dollar = ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR,
    power_factor = power_factor,
    revenue_multiplier = 1 + audio_level * 0.05
  }
  local state = robotaxi_service_states()[center.unit_number] or {revenue = 0, attrition = 0, dollars = 0, vehicles_retired = 0}
  return {
    stored = metrics.fleet,
    allocated = metrics.allocated,
    customers = customers,
    served = metrics.served,
    power_factor = power_factor,
    revenue_per_minute = metrics.revenue_per_minute,
    output_dollars = output and output.get_item_count(DOLLAR_NAME) or 0,
    output_blocked = not (output and output.can_insert{name = DOLLAR_NAME, count = 1}),
    revenue_progress = state.revenue or 0,
    attrition_progress = state.attrition or 0,
    lifetime_dollars = state.dollars or 0,
    vehicles_retired = state.vehicles_retired or 0
  }
end

function process_robotaxi_service_centers()
  local seen = {}
  local active_power_units = {}
  local allocations_by_force = {}
  for _, center in pairs(registered_factoryx_entities("robotaxi_centers")) do
      if center.valid and center.unit_number then
        allocations_by_force[center.force.index] = allocations_by_force[center.force.index]
          or robotaxi_customer_allocations(center.force)
        local customer_allocations = allocations_by_force[center.force.index]
        seen[center.unit_number] = true
        local power = ensure_robotaxi_service_power(center)
        if power and power.valid and power.unit_number then
          active_power_units[power.unit_number] = true
        end
        local input, output = robotaxi_service_inventories(center)
        local snapshot = robotaxi_service_snapshot(center, customer_allocations[center.unit_number] or 0)
        set_factoryx_runtime_visual_enabled(center, snapshot.allocated > 0 and snapshot.power_factor > 0)
        local state = robotaxi_service_states()[center.unit_number]
          or {revenue = 0, attrition = 0, dollars = 0, vehicles_retired = 0}
        robotaxi_service_states()[center.unit_number] = state
        if snapshot.allocated > 0 and snapshot.power_factor > 0 and not snapshot.output_blocked then
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
          if retirements > 0 and input and output then
            local wreck_capacity = output.get_insertable_count(WRECKED_EV_NAME)
            local removed = input.remove{
              name = ROBOTAXI_ITEM_NAME,
              count = math.min(retirements, wreck_capacity)
            }
            state.attrition = state.attrition - removed
            state.vehicles_retired = state.vehicles_retired + removed
            if removed > 0 then
              local wrecks = output.insert{name = WRECKED_EV_NAME, count = removed}
              if wrecks > 0 then
                local statistics = center.force.get_item_production_statistics(center.surface)
                statistics.set_output_count(WRECKED_EV_NAME, statistics.get_output_count(WRECKED_EV_NAME) + wrecks)
                unlock_vehicle_recycling(center.force)
              end
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
  for _, surface in pairs(game.surfaces) do
    for _, power in pairs(surface.find_entities_filtered{name = ROBOTAXI_SERVICE_POWER_NAME}) do
      if power.valid and not active_power_units[power.unit_number] then
        power.destroy()
      end
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

  force.print("[FactoryX] First Dollars earned. Next: research EV Production Line to unlock EV components, Premium EV pilot production, and Sell premium product.")
end

local function announce_ev_production_line_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[FactoryX] EV Production Line researched. Premium EV tooling is ready, but production requires 50 completed Prototype Roadster sales. Scale Sales Offices across multiple settlements.")
end

local function announce_mass_market_production_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[FactoryX] Mass-market EV Production researched. Gigafactory V2 tooling is ready. Mass-market EVs require 250 Premium EV sales; Megatruck Engineering requires Tank technology and 2,000 Mass-market EV sales.")
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
  ["x-energy-products"] = "[FactoryX] Energy Products researched. High-density Solar Arrays and Megapacks are now available for the power demands of mass-market scale.",
  ["x-small-orbital-launch"] = "[FactoryX] Small Orbital Launch researched. Manufacture a Small Launch Service, then sell the physical service through a Sales Office to fund reusable launch development.",
  ["x-reusable-launch"] = "[FactoryX] Reusable Launch researched. Build Reusable Boosters, combine them into Reusable Launch Services, and sell those services through a Sales Office.",
  ["x-satellite-constellation"] = "[FactoryX] Satellite Constellation researched. Manufacture Satellite Buses and Ground Station Networks; both become physical inputs to orbital compute and the planetary grid.",
  ["x-terrestrial-ai"] = "[FactoryX] Terrestrial AI researched. Build 4 Datacenter Racks, then construct an 8 MW Terrestrial Datacenter. Supply 20 Dollars per cycle to produce 20 AI Tokens every 30 seconds; stockpile 1,000 for Autonomous Logistics.",
  ["x-autonomous-logistics"] = "[FactoryX] Autonomous Logistics researched. Robotaxi production requires 5,000 total consumer EV sales. Then build them in Gigafactory V2 and deploy them through a powered Robotaxi Service Center.",
  ["x-orbital-compute"] = "[FactoryX] Orbital Compute researched. Build Orbital Compute Arrays on space platforms and return their high-volume AI Tokens to the planet.",
  ["x-planetary-energy-grid"] = "[FactoryX] Planetary Energy Grid researched. Build the 1 TW controller, scale cumulative AI Token production to one billion, then complete the final AGI Training Run."
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
  ["x-gigafactory-building"] = "[FactoryX] First Gigafactory online. Premium EV production appears after 50 Prototype Roadster sales. Then supply Cars, Battery Packs, and Electric Drivetrains.",
  ["x-gigafactory-v2"] = "[FactoryX] First Gigafactory V2 online. It runs twice as fast with 150% built-in productivity while drawing 30 MW. Mass-market production appears after 250 Premium EV sales.",
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
          and effect.recipe ~= ROBOTAXI_SALE_RECIPE
          and not EV_SALES_GATED_RECIPES[effect.recipe] then
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
          and effect.recipe ~= ROBOTAXI_SALE_RECIPE
          and not EV_SALES_GATED_RECIPES[effect.recipe] then
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
  if researched(force, "x-premium-ev-program")
    and count_item_produced(force, PREMIUM_EV_NAME) >= GIGAFACTORY_PRODUCTION_GATE then
    for _, recipe_name in pairs({"x-gigafactory-module", "x-gigafactory-building"}) do
      local recipe = force.recipes and force.recipes[recipe_name]
      if recipe and not recipe.enabled then table.insert(disabled, recipe_name) end
    end
  end
  table.sort(disabled)
  return {ok = #disabled == 0, disabled_recipes = disabled}
end

local function sync_force_unlocks(force)
  repair_researched_factoryx_unlocks(force)
  sync_gigafactory_production_gate(force, false)
  sync_agi_training_unlock(force, false)
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
  sync_ev_sales_recipe_gates(force, false)
end

local function sync_all_force_unlocks()
  for _, force in pairs(game.forces) do
    sync_force_unlocks(force)
  end
end

function agi_training_status(force)
  local cumulative = count_item_produced(force, "x-ai-token")
  local active = 0
  local progress = 0
  for unit_number, controller in pairs(grid_controllers()) do
    if not controller.valid then
      grid_controllers()[unit_number] = nil
    elseif controller.force == force then
      local recipe = current_recipe_name(controller)
      if recipe == AGI_TRAINING_RECIPE_NAME then
        active = active + 1
        progress = math.max(progress, controller.crafting_progress or 0)
      end
    end
  end
  return {
    cumulative_ai_tokens = cumulative,
    required_ai_tokens = AGI_TOKEN_GATE,
    unlocked = cumulative >= AGI_TOKEN_GATE,
    active_controllers = active,
    progress = progress,
    training_seconds = AGI_TRAINING_SECONDS,
    completed = victory_forces()[force.name] == true
  }
end

function trigger_victory(force, controller)
  if not force or not force.valid then
    return
  end

  local victories = victory_forces()
  if victories[force.name] then
    return
  end
  victories[force.name] = true
  storage.factoryx_agi_victory = storage.factoryx_agi_victory or {}
  storage.factoryx_agi_victory[force.name] = {
    tick = game.tick,
    cumulative_ai_tokens = count_item_produced(force, "x-ai-token"),
    surface = controller and controller.valid and controller.surface.name or nil,
    position = controller and controller.valid and controller.position or nil
  }

  force.print("[FactoryX] AGI achieved. The trained model is online, and humanity now has a new tool for deciding what comes next.")
  game.set_game_state{
    game_finished = true,
    player_won = true,
    can_continue = true
  }
end

function controller_has_agi_model(entity)
  local inventory_id = crafter_output_inventory_id()
  if not inventory_id then
    return false
  end

  local inventory = entity.get_inventory(inventory_id)
  if not inventory or not inventory.valid then
    return false
  end

  return inventory.get_item_count(AGI_MODEL_ITEM_NAME) > 0
end

function finish_completed_agi_training(force)
  if not force or not force.valid then
    return
  end

  local controllers = grid_controllers()
  for unit_number, controller in pairs(controllers) do
    if not controller.valid then
      controllers[unit_number] = nil
    elseif controller.force == force and controller_has_agi_model(controller) then
      trigger_victory(force, controller)
      return
    end
  end
end

function clear_office_buyer_reservation(office_unit_number)
  local reservations = office_buyer_reservations()
  local reservation = reservations[office_unit_number]
  if reservation then
    for _, buyer in pairs(reservation.buyers or {}) do
      if type(buyer) == "table" and buyer.virtual then
        local population = customer_settlement_populations()[buyer.settlement_key]
        if population then
          population.virtual_reserved = math.max(0, (population.virtual_reserved or 0) - 1)
        end
      elseif buyer_reserved_by_unit()[buyer] == office_unit_number then
        buyer_reserved_by_unit()[buyer] = nil
        if not customer_vehicle_owners()[buyer] then
          enqueue_customer_buyer(buyer, customer_home_settlements()[buyer])
        end
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

function dequeue_available_buyer(queue, office, expected_settlement_key)
  return BuyerQueues.pop_valid(queue, function(unit_number)
    local entity = customer_unit_registry()[unit_number]
    local home = customer_home_settlements()[unit_number]
    local available = entity and entity.valid and home
      and home.settlement_key == expected_settlement_key
      and entity.force.name == CUSTOMER_FORCE_NAME
      and not customer_vehicle_owners()[unit_number]
      and not buyer_reserved_by_unit()[unit_number]
    if available and entity.surface == office.surface then
      return true, false
    end
    return false, available == true
  end)
end

function eligible_customer_buyers(office, needed)
  local service = customer_service_for_force(office.force)
  local vehicle_summary = active_customer_vehicle_summary(office.force)
  local reserved_by_settlement = {}
  for unit_number, _ in pairs(buyer_reserved_by_unit()) do
    local home = customer_home_settlements()[unit_number]
    if home and home.market_force_name == office.force.name then
      reserved_by_settlement[home.settlement_key] = (reserved_by_settlement[home.settlement_key] or 0) + 1
    end
  end
  local pools = {}
  for key in pairs(service.served_keys) do
    local assigned_station = service.assignment_by_settlement_key[key]
    local config = assigned_station and station_config(assigned_station)
    local capacity = service.capacity_by_settlement_key[key] or 0
    local population = customer_settlement_populations()[key]
    local load = (vehicle_summary.by_settlement[key] or 0)
      + (reserved_by_settlement[key] or 0)
      + (population and population.virtual_reserved or 0)
    local settlement_in_office_coverage = population
      and population.surface_index == office.surface.index
      and within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS)
    if config and capacity > 0 and settlement_in_office_coverage then
      pools[#pools + 1] = {
        key = key,
        queue = buyer_queue_for(office.force.name, key),
        load = load,
        capacity = capacity,
        exhausted = false,
        virtual_available = population and math.max(
          0,
          (population.virtual_unowned or 0) - (population.virtual_reserved or 0)
        ) or 0
      }
    end
  end

  local buyers = {}
  while #buyers < needed do
    table.sort(pools, function(left, right)
      local left_utilization = left.load / left.capacity
      local right_utilization = right.load / right.capacity
      if left_utilization ~= right_utilization then return left_utilization < right_utilization end
      if left.load ~= right.load then return left.load < right.load end
      return left.key < right.key
    end)
    local pool
    for _, candidate in pairs(pools) do
      if not candidate.exhausted then
        pool = candidate
        break
      end
    end
    if not pool then
      break
    end
    local unit_number = dequeue_available_buyer(pool.queue, office, pool.key)
    if unit_number then
      buyers[#buyers + 1] = unit_number
      pool.load = pool.load + 1
    elseif pool.virtual_available > 0 then
      buyers[#buyers + 1] = {
        virtual = true,
        settlement_key = pool.key,
        market_force_name = office.force.name
      }
      pool.virtual_available = pool.virtual_available - 1
      pool.load = pool.load + 1
    else
      pool.exhausted = true
    end
  end
  return buyers
end

function sales_office_buyer_status(office)
  local service = customer_service_for_force(office.force)
  local vehicle_summary = active_customer_vehicle_summary(office.force)
  local eligible_keys = {}
  local settlements = 0
  for _, settlement in pairs(service.candidate_settlements or {}) do
    local key = settlement_key(settlement.surface, settlement)
    local population = customer_settlement_populations()[key]
    if (service.capacity_by_settlement_key[key] or 0) > 0
      and population and population.surface_index == office.surface.index
      and within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS) then
        eligible_keys[key] = true
        settlements = settlements + 1
    end
  end
  local available = 0
  local customers = 0
  local owned = 0
  local capacity = 0
  local powered_capacity = 0
  local friendly_settlements = 0
  for key in pairs(eligible_keys) do
    local population = customer_settlement_populations()[key]
    local queue = buyer_queue_for(office.force.name, key)
    available = available + math.max(0, #queue.units - queue.head + 1)
    available = available + math.max(
      0,
      (population.virtual_unowned or 0) - (population.virtual_reserved or 0)
    )
    owned = owned + (vehicle_summary.by_settlement[key] or 0)
    capacity = capacity + (service.capacity_by_settlement_key[key] or 0)
    powered_capacity = powered_capacity + (service.powered_capacity_by_settlement_key[key] or 0)
    if service.served_keys[key] then friendly_settlements = friendly_settlements + 1 end
    customers = customers + (population.physical or 0) + (population.virtual_unowned or 0)
    for _, count in pairs(population.virtual_by_vehicle or {}) do
      customers = customers + count
    end
  end
  return {
    available = available,
    settlements = settlements,
    customers = customers,
    owned = owned,
    capacity = capacity,
    powered_capacity = powered_capacity,
    underserved = math.max(0, owned - powered_capacity),
    friendly_settlements = friendly_settlements,
    unowned = math.max(0, customers - owned)
  }
end

function reserve_office_buyers(office, recipe_name, sale)
  clear_office_buyer_reservation(office.unit_number)
  local buyers = eligible_customer_buyers(office, sale.vehicles)
  if #buyers < sale.vehicles then
    for _, buyer in pairs(buyers) do
      if type(buyer) ~= "table" then
        enqueue_customer_buyer(buyer, customer_home_settlements()[buyer])
      end
    end
    return false
  end
  office_buyer_reservations()[office.unit_number] = {
    recipe_name = recipe_name,
    buyers = buyers
  }
  for _, buyer in pairs(buyers) do
    if type(buyer) == "table" and buyer.virtual then
      local population = customer_settlement_populations()[buyer.settlement_key]
      if population then
        population.virtual_reserved = (population.virtual_reserved or 0) + 1
      end
    else
      buyer_reserved_by_unit()[buyer] = office.unit_number
    end
  end
  return true
end

function sync_sales_office_buyers()
  ensure_customer_settlement_population_cache()
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
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
            for _, buyer in pairs(reservation.buyers) do
              if type(buyer) == "table" and buyer.virtual then
                local population = customer_settlement_populations()[buyer.settlement_key]
                if not population or (population.virtual_reserved or 0) <= 0 then
                  valid_reservation = false
                  break
                end
              else
                local entity = customer_unit_registry()[buyer]
                if not entity or not entity.valid or entity.force.name ~= CUSTOMER_FORCE_NAME
                  or customer_vehicle_owners()[buyer] then
                  valid_reservation = false
                  break
                end
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

function accelerate_consumer_ev_sales()
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
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
  for _, buyer in pairs(reservation.buyers) do
    if type(buyer) == "table" and buyer.virtual then
      local population = customer_settlement_populations()[buyer.settlement_key]
      if population and (population.virtual_unowned or 0) > 0 then
        population.virtual_unowned = population.virtual_unowned - 1
        population.virtual_by_vehicle[sale.item] =
          (population.virtual_by_vehicle[sale.item] or 0) + 1
        CustomerAggregates.add_virtual(storage, {
          vehicle = sale.item,
          settlement_key = buyer.settlement_key,
          market_force_name = office.force.name
        }, 1)
        assigned = assigned + 1
      end
    else
      local unit_number = buyer
      local entity = customer_unit_registry()[unit_number]
      local home = customer_home_settlements()[unit_number]
      if entity and entity.valid and home and not customer_vehicle_owners()[unit_number] then
      local ownership = {
        vehicle = sale.item,
        settlement_key = home.settlement_key,
        market_force_name = office.force.name,
        sold_tick = game.tick
      }
      add_customer_vehicle_ownership(unit_number, ownership)
      buyer_reserved_by_unit()[unit_number] = nil
      local replacement = replace_customer_vehicle_entity(entity, ownership)
      local owner_unit_number = replacement and replacement.valid and replacement.unit_number or unit_number
      customer_charging_commutes()[owner_unit_number] = {
        phase = "roaming",
        next_charge_tick = game.tick + CUSTOMER_COMMUTE_FIRST_VISIT_TICKS,
        completed_visits = 0
      }
      enqueue_customer_commute(owner_unit_number)
      assigned = assigned + 1
      end
    end
  end
  clear_office_buyer_reservation(office.unit_number)
  storage.factoryx_last_vehicle_sale_assignment = {
    recipe_name = recipe_name,
    assigned = assigned,
    tick = game.tick
  }
  mark_factoryx_market_dirty(office.force, "vehicle-sale")
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
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
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

local function count_sales_office_customer_settlements(force)
  local customers = customer_force_if_exists()
  if not customers then
    return 0
  end
  local covered = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices", force)) do
      local surface = office.surface
      local area = area_around(office.position, SALES_OFFICE_CUSTOMER_RADIUS)
      scan_biter_customer_entities(surface, customers, area, function(entity)
        if BITER_SETTLEMENT_NAMES[entity.name]
          and within_radius(office, entity, SALES_OFFICE_CUSTOMER_RADIUS) then
          covered[settlement_key(surface, entity)] = true
        end
      end)
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
  local agi = agi_training_status(force)
  local commutes = customer_commute_summary(force)
  local sales_gates = sync_ev_sales_recipe_gates(force, false)
  local sold = sold_customer_evs(force)
  return {
    industrial_supply_chain_researched = researched(force, "x-industrial-supply-chain"),
    big_mining_drill_researched = researched(force, "big-mining-drill"),
    foundry_researched = researched(force, "foundry"),
    recycling_revealed = (force.technologies.recycling and force.technologies.recycling.enabled) or false,
    recycling_researched = researched(force, "recycling"),
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
    first_sale_complete = first_sale_complete,
    premium_sale_complete = premium_sale_complete,
    mass_market_sale_complete = first_mass_market_ev_sales()[force.name] == true,
    robotaxi_sale_complete = first_robotaxi_sales()[force.name] == true,
    sales_offices = count_entities(force, SALES_OFFICE_NAME),
    big_mining_drills = count_entities(force, "big-mining-drill"),
    foundries = count_entities(force, "foundry"),
    recyclers = count_entities(force, "recycler"),
    calcite_mined = count_item_produced(force, "calcite"),
    wrecked_evs_produced = count_item_produced(force, WRECKED_EV_NAME),
    customer_settlements = count_sales_office_customer_settlements(force),
    powered_stations = market.powered_stations,
    charging_capacity = market.charging_stall_capacity,
    active_stalls = market.active_customer_stalls,
    customer_ev_fleet = market.customer_ev_fleet,
    customer_ev_sales_lifetime = lifetime_customer_ev_sales_size(force),
    roadsters_sold = sold["x-prototype-roadster"] or 0,
    premium_evs_sold = sold["x-premium-ev"] or 0,
    mass_market_evs_sold = sold["x-mass-market-ev"] or 0,
    cybertrucks_sold = sold["x-cybertruck"] or 0,
    consumer_evs_sold = consumer_ev_sales_total(force),
    premium_ev_gate = sales_gates.premium,
    mass_market_ev_gate = sales_gates.mass_market,
    cybertruck_gate = sales_gates.cybertruck,
    robotaxi_gate = sales_gates.robotaxi,
    customer_commutes_en_route = commutes.en_route,
    customer_commutes_charging = commutes.charging,
    customer_commutes_completed = commutes.completed,
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
    agi_token_gate = agi.required_ai_tokens,
    agi_training_unlocked = agi.unlocked,
    agi_training_active = agi.active_controllers,
    agi_training_progress = agi.progress,
    agi_models_produced = count_item_produced(force, AGI_MODEL_ITEM_NAME),
    grid_controllers = count_entities(force, "x-planetary-grid-controller"),
    terrestrial_ai_tokens_generated = terrestrial_ai.generated,
    terrestrial_ai_efficiency_level = terrestrial_ai.researched_level,
    terrestrial_ai_next_threshold = terrestrial_ai.next_threshold,
    dollars_produced = count_item_produced(force, DOLLAR_NAME),
    prototype_evs_produced = count_item_produced(force, PROTOTYPE_ROADSTER_NAME),
    premium_evs_produced = count_item_produced(force, PREMIUM_EV_NAME),
    gigafactory_production_gate = GIGAFACTORY_PRODUCTION_GATE,
    mass_market_evs_produced = count_item_produced(force, "x-mass-market-ev"),
    robotaxi_fleets_produced = count_item_produced(force, "x-robotaxi-fleet"),
    robotaxi_service_centers = count_entities(force, ROBOTAXI_SERVICE_CENTER_NAME),
    supercharging_level = improvements.supercharging,
    battery_level = improvements.battery,
    audio_level = improvements.audio,
    referral_level = improvements.referrals,
    solar_productivity_level = improvements.solar_productivity,
    megapack_productivity_level = improvements.megapack_productivity,
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
    return "Prototype revenue", "Run Sell hopes and dreams.", "Supply one Prototype Roadster and one EV Reservation, then remove the Dollars after the 60-second sale."
  elseif not snapshot.ev_production_researched then
    return "Premium production", "Research EV Production Line.", "Invest 250 cycles of red, green, blue science, and Dollars to unlock Premium EV pilot production."
  elseif not snapshot.premium_ev_gate.market_ready then
    return "Prototype market validation", "Sell 50 Prototype Roadsters.", string.format("Completed sales: %d / 50. Expand to multiple Sales Offices and customer settlements to increase throughput.", snapshot.roadsters_sold)
  elseif snapshot.premium_evs_produced < snapshot.gigafactory_production_gate then
    return "Premium pilot production", string.format("Build %d Premium EVs in assemblers.", snapshot.gigafactory_production_gate), string.format(
      "Pilot vehicles produced: %d / %d. Completing the pilot run unlocks Gigafactory Modules and Gigafactory construction.",
      snapshot.premium_evs_produced,
      snapshot.gigafactory_production_gate
    )
  elseif snapshot.gigafactories == 0 and snapshot.gigafactories_v2 == 0 then
    return "Premium production", "Construct the first Gigafactory.", "Build 10 Gigafactory Modules, add 2 Substations, then place the 9x9, 20 MW factory."
  elseif not snapshot.premium_sale_complete then
    return "Premium production", "Produce and sell a Premium EV.", "Select Premium EV in the Gigafactory and route the vehicle plus one EV Reservation to a Sales Office."
  elseif not snapshot.mass_market_ev_gate.market_ready then
    return "Premium market scale", "Sell 250 Premium EVs.", string.format("Completed sales: %d / 250. This market proof unlocks Mass-market EV production after its research is complete.", snapshot.premium_evs_sold)
  elseif not snapshot.energy_products_researched then
    return "Energy products", "Research Energy Products.", "Invest 500 cycles through production science plus Dollars to unlock High-density Solar Arrays and Megapacks for mass-market scale."
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
  elseif not snapshot.cybertruck_gate.market_ready then
    return "Mass-market scale", "Sell 2,000 Mass-market EVs.", string.format("Completed sales: %d / 2,000. Expand the customer network and Sales Office throughput to unlock Megatruck production.", snapshot.mass_market_evs_sold)
  elseif not snapshot.cybertruck_gate.technology_ready then
    return "Megatruck engineering", "Research Megatruck Engineering.", "Develop Tank technology, then invest science and Dollars to adapt armored-vehicle engineering for the Megatruck."
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
  elseif not snapshot.robotaxi_gate.market_ready then
    return "Autonomy market scale", "Reach 5,000 total consumer EV sales.", string.format("Completed Roadster, Premium, Mass-market, and Megatruck sales: %d / 5,000.", snapshot.consumer_evs_sold)
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
    return "Planetary grid", "Research Planetary Energy Grid.", "Invest 2,500 cycles of all pre-Promethium science plus AI Tokens and Dollars; prepare a 1 TW supply."
  elseif snapshot.grid_controllers == 0 then
    return "AGI infrastructure", "Build a Planetary Energy Grid Controller.", "The controller is the final 1 TW training facility; brownouts slow or stop its work."
  elseif not snapshot.agi_training_unlocked then
    return "AGI scale", "Generate one billion cumulative AI Tokens.", "Terrestrial compute can begin the climb, but orbital compute is required to reach this scale. Tokens already spent still count."
  elseif not snapshot.victory then
    return "AGI training", "Complete the AGI Training Run.", "Package 100M AI Tokens into 10,000 datasets and 10M Dollars into 1,000 allocations; add 10,000 Grid Segments and 1,000 Megapacks, then sustain 1 TW for 60 minutes."
  end
  return "AGI achieved", "The AGI Model is online.", "FactoryX victory achieved; you may continue building."
end

local function progress_stages(snapshot)
  return {
    {name = "Terrestrial industry", complete = snapshot.foundry_researched and snapshot.foundries > 0},
    {name = "Customer market", complete = snapshot.customer_settlements > 0 and snapshot.powered_stations > 0},
    {name = "Prototype revenue", complete = snapshot.first_sale_complete},
    {name = "Premium production", complete = snapshot.premium_sale_complete},
    {name = "Charging network", complete = snapshot.charging_network_researched and snapshot.chargers_v2 > 0},
    {name = "Mass-market scale", complete = snapshot.mass_market_sale_complete},
    {name = "Supercharging", complete = snapshot.chargers_v3 > 0 and snapshot.chargers_v4 > 0},
    {name = "Energy products", complete = snapshot.energy_products_researched and snapshot.solar_arrays > 0 and snapshot.megapacks > 0},
    {name = "AI and autonomy", complete = snapshot.autonomous_logistics_researched and snapshot.robotaxi_sale_complete},
    {name = "Orbital compute", complete = snapshot.orbital_compute_researched},
    {name = "Planetary grid", complete = snapshot.planetary_grid_researched and snapshot.grid_controllers > 0},
    {name = "Achieving AGI", complete = snapshot.victory}
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
    type = "scroll-pane",
    name = PROGRESS_CONTENT_NAME,
    direction = "vertical"
  }
  content.style.maximal_height = 760
  content.style.horizontally_stretchable = true

  local stage_label = content.add{type = "label", caption = stage, style = "bold_label"}
  stage_label.style.font_color = {r = 1.0, g = 0.72, b = 0.2}
  local objective_label = content.add{type = "label", caption = objective, single_line = false}
  objective_label.style.font = "default-bold"
  objective_label.style.maximal_width = 440
  local detail_label = content.add{type = "label", caption = detail, single_line = false}
  detail_label.style.maximal_width = 440
  content.add{type = "line"}

  add_section_heading(content, "Terrestrial industry")
  local industry = content.add{type = "table", column_count = 2}
  industry.style.horizontally_stretchable = true
  add_progress_metric(
    industry,
    "Industrial Supply Chain",
    snapshot.industrial_supply_chain_researched and "researched" or "available"
  )
  if snapshot.big_mining_drill_researched then
    add_progress_metric(industry, "Big Mining Drills", string.format("%d built", snapshot.big_mining_drills))
  end
  if snapshot.foundry_researched then
    add_progress_metric(industry, "Foundries", string.format("%d built", snapshot.foundries))
    add_progress_metric(industry, "Calcite mined", tostring(snapshot.calcite_mined))
  end
  if snapshot.recycling_revealed or snapshot.recycling_researched or snapshot.wrecked_evs_produced > 0 then
    add_progress_metric(industry, "Wrecked EVs produced", tostring(snapshot.wrecked_evs_produced))
    add_progress_metric(
      industry,
      "Vehicle Recycling",
      snapshot.recycling_researched
        and string.format("researched; %d Recyclers", snapshot.recyclers)
        or "research available"
    )
  end

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
  add_progress_metric(
    metrics,
    "Customer charging commutes",
    string.format("%d approaching, %d charging", snapshot.customer_commutes_en_route, snapshot.customer_commutes_charging)
  )
  add_progress_metric(metrics, "Completed charging visits", tostring(snapshot.customer_commutes_completed))
  add_progress_metric(metrics, "Lifetime EV sales", tostring(snapshot.customer_ev_sales_lifetime))
  add_progress_metric(metrics, "Premium EV gate", string.format("%d / 50 Roadsters", snapshot.roadsters_sold))
  if snapshot.ev_production_researched then
    add_progress_metric(metrics, "Premium pilot run", string.format(
      "%d / %d produced",
      math.min(snapshot.premium_evs_produced, snapshot.gigafactory_production_gate),
      snapshot.gigafactory_production_gate
    ))
    add_progress_metric(metrics, "Mass-market EV gate", string.format("%d / 250 Premium EVs", snapshot.premium_evs_sold))
  end
  if snapshot.mass_market_researched then
    add_progress_metric(metrics, "Megatruck gate", string.format("%d / 2,000 Mass-market EVs", snapshot.mass_market_evs_sold))
  end
  if snapshot.autonomous_logistics_researched then
    add_progress_metric(metrics, "Robotaxi gate", string.format("%d / 5,000 consumer EVs", snapshot.consumer_evs_sold))
  end
  add_progress_metric(metrics, "Reservations at chargers", tostring(snapshot.reservation_stock))
  add_progress_metric(metrics, "Reservation rate", string.format("%d / min", snapshot.reservations_per_minute))
  if snapshot.terrestrial_ai_researched then
    add_progress_metric(
      metrics,
      "Terrestrial AI milestone progress",
      snapshot.terrestrial_ai_next_threshold
        and string.format("%d / %d", snapshot.terrestrial_ai_tokens_generated, snapshot.terrestrial_ai_next_threshold)
        or string.format("%d; all milestones unlocked", snapshot.terrestrial_ai_tokens_generated)
    )
  end
  if snapshot.autonomous_logistics_researched then
    add_progress_metric(metrics, "Robotaxi Fleets", tostring(snapshot.robotaxi_fleets_produced))
    add_progress_metric(metrics, "Robotaxi Service Centers", tostring(snapshot.robotaxi_service_centers))
  end
  if snapshot.planetary_grid_researched then
    add_progress_metric(metrics, "Cumulative AI Tokens", string.format("%d / %d", snapshot.ai_tokens_produced, snapshot.agi_token_gate))
    add_progress_metric(
      metrics,
      "AGI Training",
      snapshot.victory and "complete"
        or (snapshot.agi_training_unlocked
          and string.format("%d%%", math.floor(snapshot.agi_training_progress * 100))
          or "locked")
    )
  end

  content.add{type = "line"}
  add_section_heading(content, "Terrestrial infrastructure")
  local infrastructure = content.add{type = "table", column_count = 2}
  infrastructure.style.horizontally_stretchable = true
  add_progress_metric(infrastructure, "Sales Offices", tostring(snapshot.sales_offices))
  if snapshot.energy_products_researched then
    add_progress_metric(infrastructure, "Gigafactories", string.format("%d V1, %d V2", snapshot.gigafactories, snapshot.gigafactories_v2))
    add_progress_metric(infrastructure, "Energy Products", string.format("%d solar, %d Megapacks", snapshot.solar_arrays, snapshot.megapacks))
  end
  if snapshot.terrestrial_ai_researched then
    add_progress_metric(infrastructure, "Terrestrial Datacenters", tostring(snapshot.datacenters))
  end
  if snapshot.autonomous_logistics_researched then
    add_progress_metric(infrastructure, "Robotaxi Service Centers", tostring(snapshot.robotaxi_service_centers))
  end

  local improvements_visible = snapshot.charging_network_researched
    or snapshot.ev_production_researched
    or snapshot.mass_market_researched
    or snapshot.energy_products_researched
    or snapshot.terrestrial_ai_researched
  if improvements_visible then
    content.add{type = "line"}
    add_section_heading(content, "Continuous improvement")
    local improvement_table = content.add{type = "table", column_count = 2}
    improvement_table.style.horizontally_stretchable = true
    if snapshot.charging_network_researched then
      add_progress_metric(improvement_table, "Supercharging electronics", "Level " .. snapshot.supercharging_level)
      add_progress_metric(improvement_table, "Customer referrals", "Level " .. snapshot.referral_level)
    end
    if snapshot.mass_market_researched then
      add_progress_metric(improvement_table, "Long-range battery", "Level " .. snapshot.battery_level)
    end
    if snapshot.ev_production_researched then
      add_progress_metric(improvement_table, "Premium audio", "Level " .. snapshot.audio_level)
    end
    if snapshot.energy_products_researched then
      add_progress_metric(
        improvement_table,
        "High-density solar productivity",
        "Level " .. snapshot.solar_productivity_level,
        "factoryx_solar_productivity_level_value"
      )
      add_progress_metric(
        improvement_table,
        "Megapack productivity",
        "Level " .. snapshot.megapack_productivity_level,
        "factoryx_megapack_productivity_level_value"
      )
    end
    if snapshot.terrestrial_ai_researched then
      add_progress_metric(
        improvement_table,
        "Terrestrial AI efficiency",
        snapshot.terrestrial_ai_next_threshold
          and string.format("Level %d; next at %d", snapshot.terrestrial_ai_efficiency_level, snapshot.terrestrial_ai_next_threshold)
          or string.format("Level %d; terrestrial ceiling", snapshot.terrestrial_ai_efficiency_level)
      )
    end
  end

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
  local panel = player.gui.relative[ENTITY_INFO_PANEL_NAME]
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

FACTORYX_STATE_COLORS = {
  good = {r = 0.35, g = 0.90, b = 0.35},
  warning = {r = 1.00, g = 0.72, b = 0.20},
  bad = {r = 1.00, g = 0.30, b = 0.25},
  neutral = {r = 0.75, g = 0.75, b = 0.75}
}

function entity_status_presentation(entity)
  if entity.name == SALES_OFFICE_NAME and entity.disabled_by_script then
    local buyers = sales_office_buyer_status(entity)
    if buyers.settlements == 0 then
      return "No customer settlements", FACTORYX_STATE_COLORS.bad
    elseif buyers.unowned == 0 then
      return "Market saturated", FACTORYX_STATE_COLORS.warning
    elseif buyers.friendly_settlements == 0 then
      return "Customers hostile", FACTORYX_STATE_COLORS.bad
    end
    return "Waiting for buyer", FACTORYX_STATE_COLORS.warning
  end
  local status = entity.status
  if status == defines.entity_status.working then
    return "Working", FACTORYX_STATE_COLORS.good
  elseif status == defines.entity_status.no_power or status == defines.entity_status.low_power then
    return entity_status_text(entity), FACTORYX_STATE_COLORS.bad
  elseif status == defines.entity_status.no_ingredients
    or status == defines.entity_status.item_ingredient_shortage
    or status == defines.entity_status.fluid_ingredient_shortage
    or status == defines.entity_status.full_output
    or status == defines.entity_status.disabled_by_control_behavior then
    return entity_status_text(entity), FACTORYX_STATE_COLORS.bad
  elseif status == defines.entity_status.no_recipe then
    return entity_status_text(entity), FACTORYX_STATE_COLORS.warning
  end
  return entity_status_text(entity), FACTORYX_STATE_COLORS.neutral
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

  local panel = player.gui.relative.add{
    type = "frame",
    name = ENTITY_INFO_PANEL_NAME,
    caption = {"", "FactoryX ", entity.prototype.localised_name},
    direction = "vertical",
    anchor = factoryx_relative_anchor(entity)
  }
  panel.style.width = 380
  local state_text, state_color = entity_status_presentation(entity)
  local state_row = panel.add{type = "flow", direction = "horizontal"}
  state_row.add{type = "label", caption = "State: "}
  add_station_info_label(state_row, state_text, state_color)

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
    elseif snapshot.output_blocked then
      add_station_info_label(panel, "Blocked: Dollar output is full. Remove Dollars; trips and fleet attrition are paused.")
    else
      add_station_info_label(panel, "Operating: keep the fleet stocked, power stable, and Dollar output clear.")
    end
    return
  end

  if entity.name == SALES_OFFICE_NAME then
    local buyer_status = sales_office_buyer_status(entity)
    local recipe = entity.get_recipe()
    local sale = recipe and CUSTOMER_EV_SALE_RECIPES[recipe.name]
    local buyer_reservation = office_buyer_reservations()[entity.unit_number]
    local reserved = buyer_reservation and #buyer_reservation.buyers or 0
    add_factoryx_metric_table(panel, {
      {sprite = "entity/biter-spawner", label = "Settlements", value = tostring(count_customer_settlements_near_office(entity))},
      {sprite = "entity/small-biter", label = "Buyers", value = string.format("%d available", buyer_status.available)},
      {sprite = "item/x-mass-market-ev", label = "EV owners", value = string.format("%d / %d", buyer_status.owned, buyer_status.customers)},
      {sprite = "item/x-ev-charging-station", label = "Charging", value = string.format("%d capacity", buyer_status.powered_capacity)},
      {sprite = "item/x-ev-charging-station", label = "Underserved", value = tostring(buyer_status.underserved), color = buyer_status.underserved > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good},
      {sprite = "item/x-ev-reservation", label = "Reserved", value = sale and string.format("%d / %d", reserved, sale.vehicles) or "-"}
    })

    local summary
    local summary_color
    if not recipe then
      summary, summary_color = "Select a sales contract.", FACTORYX_STATE_COLORS.warning
    elseif entity.status == defines.entity_status.no_power or entity.status == defines.entity_status.low_power then
      summary, summary_color = "Restore power.", FACTORYX_STATE_COLORS.bad
    elseif entity.status == defines.entity_status.full_output then
      summary, summary_color = "Clear the Dollar output.", FACTORYX_STATE_COLORS.bad
    elseif entity.disabled_by_script then
      if buyer_status.unowned == 0 then
        summary = "Market saturated. Expand coverage."
      elseif buyer_status.friendly_settlements == 0 then
        summary = "Restore customer charging service."
      else
        summary = "Waiting for an available buyer."
      end
      summary_color = FACTORYX_STATE_COLORS.warning
    elseif entity.status == defines.entity_status.working then
      summary, summary_color = "Sales active.", FACTORYX_STATE_COLORS.good
    else
      summary, summary_color = "Waiting for product inputs.", FACTORYX_STATE_COLORS.neutral
    end
    add_factoryx_status_strip(panel, summary, summary_color)
    return
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
    add_station_info_label(panel, next_step)
    return
  end

  add_station_info_label(panel, {"", "Recipe: ", recipe.localised_name})
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
    local buyers = sales_office_buyer_status(entity)
    if buyers.unowned == 0 then
      next_step = "Market saturated: every mobile customer in this office's coverage already owns an EV. Establish powered charging and Sales Office coverage at another biter settlement."
    elseif buyers.friendly_settlements == 0 then
      next_step = "Blocked: no friendly buyers remain here. Restore powered charging capacity to recover these settlements, or expand to another market."
    else
      next_step = "Blocked: no eligible mobile customer is ready. Waiting for an unassigned buyer from a powered settlement inside this office's coverage."
    end
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
  local population = customer_settlement_populations()[key] or {}
  local settlement_population = (population.physical or 0) + (population.virtual_unowned or 0)
  for _, count in pairs(population.virtual_by_vehicle or {}) do
    settlement_population = settlement_population + count
  end
  local panel = player.gui.relative.add{
    type = "frame",
    name = ENTITY_INFO_PANEL_NAME,
    caption = "FactoryX Customer Settlement",
    direction = "vertical",
    anchor = {
      gui = defines.relative_gui_type.additional_entity_info_gui,
      position = defines.relative_gui_position.right
    }
  }
  panel.style.width = 380

  local local_powered_capacity = service.powered_capacity_by_settlement_key[key] or 0
  local local_underserved = math.max(0, settlement_vehicles - local_powered_capacity)
  local status = friendly and (local_underserved > 0 and "customer - charging underserved" or "customer")
    or "hostile"
  add_station_info_label(panel, "Status: " .. status)
  add_station_info_label(panel, "Sales Office coverage: " .. (sales_covered and "yes" or "no"))
  add_station_info_label(panel, string.format(
    "Settlement population: %d (%d visible representatives)",
    settlement_population,
    population.physical or 0
  ))
  add_station_info_label(panel, string.format("Active vehicles at this settlement: %d", settlement_vehicles))
  add_station_info_label(panel, string.format(
    "Powered charging capacity at this settlement: %d",
    local_powered_capacity
  ))
  add_station_info_label(panel, string.format("Underserved vehicles: %d", local_underserved))
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
    reason = string.format(
      "Customer status: %d EVs lack powered charging, but this settlement remains friendly during its patience period.",
      local_underserved
    )
  elseif angry then
    reason = string.format(
      "Hostile reason: %d sold EVs exceed reachable charging capacity. Add powered stalls to restore service.",
      local_underserved
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
  end
  update_station_alerts(entity)
end

function refresh_factoryx_infrastructure_change(entity)
  if not entity or not entity.valid or not entity.force then return end
  mark_factoryx_market_dirty(entity.force, "infrastructure-changed")
  sync_customer_settlements()
  sync_sales_office_buyers()
  update_charger_stall_visuals(true)
  for _, player in pairs(entity.force.connected_players) do
    local opened = opened_factoryx_entities()[player.index]
    if is_station(opened) then
      close_entity_info_panel(player)
      show_station_info_panel(player, opened)
    elseif is_factoryx_manufacturer(opened) then
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, opened)
    elseif is_customer_settlement_entity(opened) then
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, opened)
    end
    refresh_progress_panel(player)
  end
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
  rebuild_factoryx_entity_registries()
  rebuild_electric_vehicles()
  rebuild_grid_controllers()
  rebuild_factoryx_compute_machines()
  rebuild_sales_offices()
  rebuild_customer_vehicle_aggregates()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  rebuild_customer_buyer_queues()
  rebuild_customer_commute_queue()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
  end
  track_ai_efficiency_progress()
  queue_customer_vehicle_variant_migration()
  rebuild_factoryx_runtime_visuals()
  rebuild_charger_stall_visuals()
  rebuild_sales_office_showrooms()
end)

script.on_configuration_changed(function()
  rebuild_factoryx_entity_registries()
  rebuild_electric_vehicles()
  rebuild_grid_controllers()
  rebuild_factoryx_compute_machines()
  rebuild_sales_offices()
  rebuild_customer_vehicle_aggregates()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  rebuild_customer_buyer_queues()
  rebuild_customer_commute_queue()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
  end
  track_ai_efficiency_progress()
  queue_customer_vehicle_variant_migration()
  rebuild_factoryx_runtime_visuals()
  rebuild_charger_stall_visuals()
  rebuild_sales_office_showrooms()
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
  if not element or not element.valid then
    return
  end
  local player = game.get_player(event.player_index)
  local panel_name = element.name == PROGRESS_CLOSE_BUTTON_NAME and PROGRESS_PANEL_NAME
    or element.name == "factoryx_station_info_close" and STATION_INFO_PANEL_NAME
  local panel = panel_name and player and player.gui.screen[panel_name]
  if panel then
    panel.destroy()
  end
  if panel_name == STATION_INFO_PANEL_NAME and player then
    opened_factoryx_entities()[player.index] = nil
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player then
    grant_factoryx_energy_jumpstart(player)
    seed_crash_site_salvage(player)
    sales_office_coverage_enabled()[player.index] = false
    refresh_sales_office_coverage(player)
    sync_charger_placement_overlay(player)
  end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  sync_charger_placement_overlay(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.get_player(event.player_index)
  local prior_state = player and ev_driver_overlay_states()[player.index]
  local prior_vehicle = prior_state and prior_state.vehicle
  local vehicle = player and player.vehicle
  show_ev_battery_popup(player, is_electric_vehicle(vehicle) and vehicle or prior_vehicle)
  refresh_ev_driver_overlays()
end)

function update_ev_reverse_warnings()
  storage.factoryx_ev_reverse_warning_tick = storage.factoryx_ev_reverse_warning_tick or {}
  for _, player in pairs(game.connected_players) do
    local vehicle = player.vehicle
    local reversing = vehicle and vehicle.valid and ELECTRIC_VEHICLE_BATTERIES[vehicle.name]
      and player.riding_state.acceleration == defines.riding.acceleration.reversing
      and math.abs(vehicle.speed or 0) > 0.005
    local last_tick = storage.factoryx_ev_reverse_warning_tick[player.index] or -60
    if reversing and game.tick - last_tick >= 60 then
      vehicle.surface.play_sound({
        path = "x-ev-reverse-warning",
        position = vehicle.position
      })
      storage.factoryx_ev_reverse_warning_tick[player.index] = game.tick
    elseif not reversing then
      storage.factoryx_ev_reverse_warning_tick[player.index] = nil
    end
  end
end

script.on_event(defines.events.on_entity_damaged, function(event)
  local victim = event.entity
  local attacker = event.cause
  if victim and victim.valid and attacker and attacker.valid
    and attacker.type == "unit" and attacker.force.name == CUSTOMER_FORCE_NAME
    and player_market_force(victim.force) then
    give_customer_wander_command(attacker, true)
  end
end)

script.on_event(defines.events.on_entity_spawned, function(event)
  local entity = event.entity
  local spawner = event.spawner
  if not entity or not entity.valid or entity.type ~= "unit"
    or entity.force.name ~= CUSTOMER_FORCE_NAME
    or not spawner or not spawner.valid then
    return
  end
  local key = settlement_key(spawner.surface, spawner)
  local market_force_name = customer_settlement_market_forces()[key]
  if not market_force_name then return end
  local market_force = game.forces[market_force_name]
  if not market_force then return end
  if register_customer_unit(entity, spawner, market_force) then
    give_customer_wander_command(entity, true)
  end
end)

script.on_event(defines.events.on_ai_command_completed, handle_customer_commute_command_completed)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  sync_charger_placement_overlay(player)
  refresh_sales_office_coverage(player)
  refresh_progress_panel(player)
end)

script.on_event(defines.events.on_player_left_game, function(event)
  charger_placement_overlay_states()[event.player_index] = nil
  opened_factoryx_entities()[event.player_index] = nil
  destroy_ev_driver_overlay(event.player_index)
end)

script.on_event(defines.events.on_player_removed, function(event)
  charger_placement_overlay_states()[event.player_index] = nil
  opened_factoryx_entities()[event.player_index] = nil
  destroy_ev_driver_overlay(event.player_index)
  sales_office_coverage_enabled()[event.player_index] = nil
  storage.factoryx_charger_overlay_warnings = storage.factoryx_charger_overlay_warnings or {}
  storage.factoryx_charger_overlay_warnings[event.player_index] = nil
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

script.on_event(defines.events.on_gui_opened, function(event)
  local player = event.player_index and game.get_player(event.player_index)
  local entity = event.entity
  if player and player.valid then
    opened_factoryx_entities()[player.index] = nil
    if is_station(entity) then
      player.opened = nil
      opened_factoryx_entities()[player.index] = entity
      close_entity_info_panel(player)
      show_station_info_panel(player, entity)
    elseif is_factoryx_manufacturer(entity) then
      opened_factoryx_entities()[player.index] = entity
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, entity)
    elseif is_customer_settlement_entity(entity) then
      opened_factoryx_entities()[player.index] = entity
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, entity)
    else
      close_station_info_panel(player)
      close_entity_info_panel(player)
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = event.player_index and game.get_player(event.player_index)
  if player and player.valid then
    local opened = opened_factoryx_entities()[player.index]
    if is_station(opened) and player.gui.screen[STATION_INFO_PANEL_NAME] then
      return
    end
    opened_factoryx_entities()[player.index] = nil
    close_station_info_panel(player)
    close_entity_info_panel(player)
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
	      track_factoryx_entity(entity)
	      if entity and entity.valid and (is_station(entity)
	        or entity.name == SALES_OFFICE_NAME
	        or entity.name == ROBOTAXI_SERVICE_CENTER_NAME) then
	        mark_factoryx_market_dirty(entity.force, "infrastructure-built")
	      end
	      handle_station_built(entity, event)
	      track_grid_controller(entity)
	      track_factoryx_compute_machine(entity)
	      track_sales_office(entity)
	      track_electric_vehicle(entity, true)
	      attach_factoryx_runtime_visual(entity)
	      if entity and entity.valid and GIGAFACTORY_ENTITY_NAMES[entity.name] then
	        unlock_gigafactory_logistics(entity.force, true)
	      end
	      announce_first_entity_placement(entity)
	      if entity and entity.valid and entity.name == ROBOTAXI_SERVICE_CENTER_NAME then
	        robotaxi_service_inventories(entity)
	        ensure_robotaxi_service_power(entity)
	      end
	      if entity and entity.valid and entity.name == SALES_OFFICE_NAME then
	        mark_sales_office_coverage_dirty()
	      end
	      if entity and entity.valid and (is_station(entity)
	        or entity.name == SALES_OFFICE_NAME
	        or entity.name == ROBOTAXI_SERVICE_CENTER_NAME) then
	        refresh_factoryx_infrastructure_change(entity)
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
      local refresh_infrastructure = entity and entity.valid and (is_station(entity)
        or entity.name == SALES_OFFICE_NAME
        or entity.name == ROBOTAXI_SERVICE_CENTER_NAME)
      if event_name == defines.events.on_player_mined_entity
        or event_name == defines.events.on_robot_mined_entity then
        award_small_crash_site_salvage(event)
        if event.buffer then
          local hidden_charge_count = event.buffer.get_item_count(ELECTRIC_DRIVE_FUEL_NAME)
          if hidden_charge_count > 0 then
            event.buffer.remove{name = ELECTRIC_DRIVE_FUEL_NAME, count = hidden_charge_count}
          end
        end
      end
      if entity and entity.valid and entity.unit_number and customer_unit_registry()[entity.unit_number] then
        destroy_customer_marker(entity)
        unregister_customer_unit(entity)
      end
      if entity and entity.unit_number and ELECTRIC_VEHICLE_BATTERIES[entity.name] then
        electric_vehicle_registry()[entity.unit_number] = nil
        if storage.factoryx_vehicle_charge_activity then
          storage.factoryx_vehicle_charge_activity[entity.unit_number] = nil
        end
      end
      if entity and entity.unit_number then
        untrack_factoryx_entity(entity)
        destroy_factoryx_runtime_visual(entity.unit_number)
        destroy_charger_stall_visuals(entity.unit_number)
        destroy_sales_office_showroom_rendering(entity.unit_number)
        factoryx_compute_machines()[entity.unit_number] = nil
        factoryx_compute_power_failures()[entity.unit_number] = nil
        factoryx_compute_queue().members[entity.unit_number] = nil
      end
      if entity and entity.valid then mark_factoryx_market_dirty(entity.force, "entity-removed") end
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
      if refresh_infrastructure and entity.valid then
        refresh_factoryx_infrastructure_change(entity)
      end
    end)
  end
end


script.on_nth_tick(1, reset_underpowered_compute_progress)

script.on_nth_tick(6, update_ev_battery_popups)

script.on_nth_tick(30, function()
  update_factoryx_runtime_visuals()
  update_charger_stall_visuals()
  update_sales_office_showrooms()
  refresh_ev_driver_overlays()
  update_ev_reverse_warnings()
  feed_tracked_electric_vehicles()
  sync_sales_office_buyers()
  accelerate_consumer_ev_sales()
  check_first_prototype_sales()
  for _, force in pairs(game.forces) do
    finish_completed_agi_training(force)
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
    sync_gigafactory_production_gate(force, true)
  end
  local allocations_by_force = {}
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface)) do
      local force_index = station.force.index
      if not allocations_by_force[force_index] then
        allocations_by_force[force_index] = calculate_station_utilization(station.force)
      end
      local powered = refresh_station_power_state(station, allocations_by_force[force_index])
      set_factoryx_runtime_visual_enabled(station, powered and active_station_stalls(station) > 0)
      sample_station_power_service(station)
      charge_station_vehicles(station)
      update_station_alerts(station)
      if station.valid and count_biter_settlements_near_station(station) > 0 then
        unlock_roadster_sales(station.force)
      end
    end
  end
  for _, force in pairs(game.forces) do
    generate_station_reservations(force)
  end
  process_customer_charging_commutes()
end)

script.on_nth_tick(UiRefresh.interval_ticks, function()
  for _, player in pairs(game.connected_players) do
    local opened = opened_factoryx_entities()[player.index]
    if is_station(opened) then
      close_entity_info_panel(player)
      show_station_info_panel(player, opened)
    elseif is_factoryx_manufacturer(opened) then
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, opened)
    elseif is_customer_settlement_entity(opened) then
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, opened)
    else
      close_station_info_panel(player)
      close_entity_info_panel(player)
    end
    refresh_progress_panel(player)
  end
end)

script.on_nth_tick(600, function()
  sync_biter_customer_diplomacy()
  sync_customer_service_states()
  reconcile_factoryx_entity_registry_step()
end)

remote.add_interface("factoryx", {
  open_entity_info = function(player_index, entity)
    local player = game.get_player(player_index)
    if not player or not entity or not entity.valid then return false end
    if is_station(entity) then
      player.opened = nil
      opened_factoryx_entities()[player.index] = entity
      close_entity_info_panel(player)
      show_station_info_panel(player, entity)
      return player.gui.screen[STATION_INFO_PANEL_NAME] ~= nil
    elseif is_factoryx_manufacturer(entity) then
      close_station_info_panel(player)
      show_manufacturer_info_panel(player, entity)
      return player.gui.relative[ENTITY_INFO_PANEL_NAME] ~= nil
    elseif is_customer_settlement_entity(entity) then
      close_station_info_panel(player)
      show_customer_settlement_info_panel(player, entity)
      return player.gui.relative[ENTITY_INFO_PANEL_NAME] ~= nil
    end
    return false
  end,
  grant_energy_jumpstart = function(player_index)
    local player = game.get_player(player_index)
    local chest = grant_factoryx_energy_jumpstart(player)
    return chest and chest.valid or false
  end,
  robotaxi_service_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local centers = {}
    local allocations = robotaxi_customer_allocations(force)
    for _, center in pairs(registered_factoryx_entities("robotaxi_centers", force)) do
        local snapshot = robotaxi_service_snapshot(center, allocations[center.unit_number] or 0)
        snapshot.unit_number = center.unit_number
        snapshot.surface = center.surface.name
        snapshot.position = center.position
        centers[#centers + 1] = snapshot
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
  customer_charging_commutes = function(force_name)
    local force = game.forces[force_name or "player"]
    return force and customer_commute_summary(force) or nil
  end,
  performance_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local buyer_units = 0
    for _, queue in pairs(customer_buyer_queues()[force.name] or {}) do
      buyer_units = buyer_units + math.max(0, #queue.units - queue.head + 1)
    end
    local due = customer_commute_timing_wheel()
    local performance_state = PerformanceState.ensure(storage)
    local active = 0
    for _ in pairs(customer_active_commutes()) do active = active + 1 end
    local population_records = 0
    for _ in pairs(customer_settlement_populations()) do population_records = population_records + 1 end
    return {
      counters = storage.factoryx_perf_counters or {},
      registered_stations = #registered_factoryx_entities("stations", force),
      registered_sales_offices = #registered_factoryx_entities("sales_offices", force),
      registered_robotaxi_centers = #registered_factoryx_entities("robotaxi_centers", force),
      queued_buyers = buyer_units,
      visible_customers = customer_visible_count(),
      visible_customer_limit = CUSTOMER_VISIBLE_GLOBAL_LIMIT,
      queued_commutes = due.size,
      active_commutes = active,
      customer_population_records = population_records,
      market_invalidations = performance_state.invalidations,
      compute_queue_size = #factoryx_compute_queue().units,
      robotaxi_cache_tick = storage.factoryx_robotaxi_allocation_cache
        and storage.factoryx_robotaxi_allocation_cache[force.index]
        and storage.factoryx_robotaxi_allocation_cache[force.index].tick or nil
    }
  end,
  repair_customer_populations = function()
    return rebuild_customer_settlement_population_cache()
  end,
  sync_sales_offices = function()
    sync_sales_office_buyers()
    local enabled = 0
    for _, office in pairs(registered_factoryx_entities("sales_offices")) do
      if office.valid and not office.disabled_by_script then enabled = enabled + 1 end
    end
    return enabled
  end,
  sales_office_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local rows = {}
    local service = customer_service_for_force(force)
    local vehicle_summary = active_customer_vehicle_summary(force)
    for _, office in pairs(registered_factoryx_entities("sales_offices", force)) do
      local settlements = {}
      for key in pairs(service.served_keys) do
        local population = customer_settlement_populations()[key]
        local station = service.assignment_by_settlement_key[key]
        local config = station and station_config(station)
        local queue = buyer_queue_for(force.name, key)
        local valid_entities = 0
        local customer_force_entities = 0
        local unowned_entities = 0
        local matching_homes = 0
        for index = queue.head, #queue.units do
          local unit_number = queue.units[index]
          local entity = customer_unit_registry()[unit_number]
          local home = customer_home_settlements()[unit_number]
          if entity and entity.valid then
            valid_entities = valid_entities + 1
            if entity.force.name == CUSTOMER_FORCE_NAME then customer_force_entities = customer_force_entities + 1 end
            if not customer_vehicle_owners()[unit_number] then unowned_entities = unowned_entities + 1 end
          end
          if home and home.settlement_key == key then matching_homes = matching_homes + 1 end
        end
        settlements[#settlements + 1] = {
          key = key,
          position = population and population.position,
          in_coverage = population and population.surface_index == office.surface.index
            and within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS) or false,
          queued = math.max(0, #queue.units - queue.head + 1),
          valid_entities = valid_entities,
          customer_force_entities = customer_force_entities,
          unowned_entities = unowned_entities,
          matching_homes = matching_homes,
          owned = vehicle_summary.by_settlement[key] or 0,
          capacity = service.capacity_by_settlement_key[key] or 0,
          powered_capacity = service.powered_capacity_by_settlement_key[key] or 0,
          underserved = math.max(
            0,
            (vehicle_summary.by_settlement[key] or 0)
              - (service.powered_capacity_by_settlement_key[key] or 0)
          )
        }
      end
      rows[#rows + 1] = {
        unit_number = office.unit_number,
        position = office.position,
        disabled = office.disabled_by_script,
        recipe = office.get_recipe() and office.get_recipe().name,
        has_inputs = office.get_recipe() and office_has_all_sale_inputs(office, office.get_recipe()) or false,
        crafting_progress = office.crafting_progress,
        buyer_status = sales_office_buyer_status(office),
        settlements = settlements
      }
    end
    return rows
  end,
  performance_test_seed_owner = function(entity, spawner, force_name, vehicle_name, due_tick)
    if not script.active_mods["factoryx_perf_benchmark"] then return false end
    local force = game.forces[force_name or "player"]
    if not force or not entity or not entity.valid or not spawner or not spawner.valid then return false end
    customer_settlement_market_forces()[settlement_key(spawner.surface, spawner)] = force.name
    register_customer_unit(entity, spawner, force)
    add_customer_vehicle_ownership(entity.unit_number, {
      vehicle = vehicle_name or "x-mass-market-ev",
      settlement_key = settlement_key(spawner.surface, spawner),
      market_force_name = force.name,
      sold_tick = game.tick
    })
    customer_charging_commutes()[entity.unit_number] = {
      phase = "roaming",
      next_charge_tick = due_tick or game.tick + 60 * 60 * 60,
      completed_visits = 0
    }
    schedule_customer_commute(entity.unit_number, customer_charging_commutes()[entity.unit_number].next_charge_tick)
    return true
  end,
  agi_training_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    sync_agi_training_unlock(force, false)
    return agi_training_status(force)
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

commands.add_command("factoryx-note", "Record a timestamped FactoryX playtest note.", function(command)
  local player = command.player_index and game.get_player(command.player_index)
  local text = command.parameter and string.gsub(command.parameter, "^%s*(.-)%s*$", "%1") or ""
  if not player or text == "" then
    if player then player.print("Usage: /factoryx-note <observation>") end
    return
  end
  local snapshot = progress_snapshot(player.force)
  local stage = current_progress_objective(snapshot)
  helpers.write_file("factoryx-playtest-notes.jsonl", helpers.table_to_json{
    tick = game.tick,
    player = player.name,
    surface = player.surface.name,
    position = {x = player.position.x, y = player.position.y},
    stage = stage,
    text = text
  } .. "\n", true)
  player.print("[FactoryX] Playtest note recorded.")
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
