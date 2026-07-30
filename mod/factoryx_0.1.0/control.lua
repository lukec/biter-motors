TimingWheel = require("runtime.timing_wheel")
PerformanceState = require("runtime.performance_state")
CustomerAggregates = require("runtime.customer_aggregates")
BuyerQueues = require("runtime.buyer_queues")
RobotaxiService = require("runtime.robotaxi_service")
PowerQueue = require("runtime.power_queue")
UiRefresh = require("runtime.ui_refresh")
EvAutopilot = require("runtime.ev_autopilot")
ProductionHistory = require("runtime.production_history")
ChargerAllocator = require("runtime.charger_allocator")
SalesOfficeMarket = require("runtime.sales_office_market")

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
EV_AUTOPILOT_DESTINATION_ITEM = "x-ev-autopilot-destination"
EV_AUTOPILOT_SUMMON_SHORTCUT = "x-summon-factoryx-ev"
EV_AUTOPILOT_TECH_NAME = "x-autonomous-logistics"
EV_AUTOPILOT_MANUAL_INPUTS = {
  ["x-ev-autopilot-manual-up"] = true,
  ["x-ev-autopilot-manual-down"] = true,
  ["x-ev-autopilot-manual-left"] = true,
  ["x-ev-autopilot-manual-right"] = true
}
local SALES_OFFICE_NAME = "x-sales-office"
SALES_OFFICE_LOW_PROSPECT_FRACTION = 0.20
SALES_OFFICE_LOW_PROSPECT_MINIMUM = 5
SALES_OFFICE_RESERVATION_RECONCILE_TICKS = 10 * 60
local LOGISTIC_SYSTEM_TECH_NAME = "logistic-system"
local GIGAFACTORY_CONFIGS = {
  ["x-gigafactory-building"] = {
    display_name = "Gigafactory",
    power = "20 MW",
    default_product = "Premium EV",
    productivity = "4x crafting speed; 50% built-in productivity"
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
local HIGH_DENSITY_SOLAR_BATCH_RECIPE = "x-high-density-solar-array-batch"
local MEGAPACK_NAME = "x-megapack"
MEGAPACK_SALE_RECIPE = "x-sell-megapack"
local TERRESTRIAL_DATACENTER_NAME = "x-terrestrial-datacenter"
ROBOTAXI_SERVICE_CENTER_NAME = "x-robotaxi-service-center"
ROBOTAXI_SERVICE_RECIPE = "x-operate-robotaxis"
ROBOTAXI_SERVICE_POWER_NAME = "x-robotaxi-service-power"
ROBOTAXI_ITEM_NAME = "x-robotaxi-fleet"
ROBOTAXI_SERVICE_RADIUS = 256
ROBOTAXI_CUSTOMERS_PER_VEHICLE = 5
ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 100
ROBOTAXI_ATTRITION_VEHICLE_HOURS = 60
ROBOTAXI_SAFETY_RIDES_SCALE = 1000
ROBOTAXI_ROUTINE_WEAR_FLOOR = 0.20
local RESERVATION_NAME = "x-ev-reservation"
WRECKED_EV_NAME = "x-wrecked-ev"
DAMAGED_HIGH_ENERGY_PACK_NAME = "x-damaged-high-energy-battery-pack"
DAMAGED_LFP_PACK_NAME = "x-damaged-lfp-battery-pack"
BATTERY_RECOVERY_TECH_NAME = "x-battery-material-recovery"
ELECTRIC_SEMI_NAME = "x-electric-semi"
ELECTRIC_SEMI_FUEL_NAME = "x-electric-semi-drive-charge"
SEMI_CHARGING_STOP_NAME = "x-semi-charging-stop"
SEMI_CHARGING_POWER_NAME = "x-semi-charging-power"
SEMI_BATTERY_CAPACITY = 1000000000
SEMI_CHARGING_POWER = 50000000
SEMI_KINETIC_ENERGY_SCALE = 10000
SEMI_REGEN_EFFICIENCY = 0.65
SEMI_PROCESS_BUDGET = 32
SEMI_RESERVE_THRESHOLD = 10000000
SEMI_RESERVE_SPEED = 0.08
local CUSTOMER_FORCE_NAME = "factoryx-customers"
ROAD_RAGE_FORCE_NAME = "factoryx-road-rage"
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
local ADVANCED_BATTERY_CHEMISTRY_TECH_NAME = "x-advanced-battery-chemistry"
local ADVANCED_BATTERY_CHEMISTRY_RECIPES = {
  "x-dirty-nickel-refining",
  "x-lithium-extraction",
  "x-battery-graphite",
  "x-tailings-neutralization",
  "x-high-nickel-cell",
  "x-cell-scale-high-nickel",
  "x-high-energy-battery-pack",
  "x-premium-ev-cell-scale"
}
PLAYER_VEHICLE_BATTERY_SCRAP = {
  [PREMIUM_EV_NAME] = {[DAMAGED_HIGH_ENERGY_PACK_NAME] = 8},
  ["x-mass-market-ev"] = {[DAMAGED_LFP_PACK_NAME] = 4},
  ["x-cybertruck"] = {[DAMAGED_HIGH_ENERGY_PACK_NAME] = 4, [DAMAGED_LFP_PACK_NAME] = 8},
  [ROBOTAXI_ITEM_NAME] = {[DAMAGED_LFP_PACK_NAME] = 16},
  [ELECTRIC_SEMI_NAME] = {[DAMAGED_HIGH_ENERGY_PACK_NAME] = 8}
}
PREMIUM_PILOT_PRODUCTION_GATE = 100
ADVANCED_BATTERY_CHEMISTRY_PRODUCTION_GATE = 250
FOUNDRY_POWER_GATE = {
  solar_panels = 25,
  megapacks = 5
}
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
  [FIRST_PROTOTYPE_SALE_RECIPE] = "x-sales-office-showroom-prototype-roadster-frame-",
  [PREMIUM_EV_SALE_RECIPE] = "x-sales-office-showroom-premium-ev-frame-",
  [MASS_MARKET_EV_SALE_RECIPE] = "x-sales-office-showroom-mass-market-ev-frame-",
  [CYBERTRUCK_SALE_RECIPE] = "x-sales-office-showroom-cybertruck-frame-"
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
local PROSPECT_RESERVATION_RETRY_MINUTES = 5
local RESERVATION_SAMPLES_PER_PRINT = 60
local CUSTOMER_GROWTH_STALL_MINUTES = 4
local CUSTOMER_GROWTH_PROGRESS_REQUIRED = CUSTOMER_GROWTH_STALL_MINUTES * 60
local CUSTOMER_VISIBLE_GLOBAL_LIMIT = 2000
local CUSTOMER_VISIBLE_PER_SETTLEMENT_LIMIT = 128
CUSTOMER_LIFECYCLE_VERSION = 1
local CUSTOMER_MARKET_CACHE_TICKS = 120
CUSTOMER_SERVICE_GRACE_TICKS = 3 * 60 * 60
CUSTOMER_MOOD_CHECK_TICKS = 60 * 60
CUSTOMER_MOOD_BASE_ANGER_CHANCE = 0.05
CUSTOMER_MOOD_MAX_ANGER_CHANCE = 0.25
FACTORYX_ENEMY_PRESSURE_VERSION = 2
FACTORYX_ENEMY_ATTACK_POLLUTION_COST = 4
FACTORYX_MAX_GATHERING_ATTACK_GROUPS = 10
FACTORYX_MAX_ATTACK_GROUP_SIZE = 80
FACTORYX_MIN_EXPANSION_COOLDOWN_TICKS = 10 * 60 * 60
FACTORYX_MAX_EXPANSION_COOLDOWN_TICKS = 60 * 60 * 60
FACTORYX_POLLUTION_EVOLUTION_FACTOR = 3e-7
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
    technology = "x-terrestrial-ai",
    recipe = "x-terrestrial-ai-token",
    technology_prefix = "x-terrestrial-ai-efficiency-",
    tokens_per_cycle = 20
  },
  orbital = {
    entity = "x-orbital-compute-array",
    technology = "x-orbital-compute",
    recipe = "x-orbital-ai-token",
    technology_prefix = "x-orbital-ai-efficiency-",
    tokens_per_cycle = 40
  }
}
local AI_EFFICIENCY_MACHINE_NAMES = {
  ["x-terrestrial-datacenter"] = true,
  ["x-orbital-compute-array"] = true
}
FACTORYX_REGISTRY_RECONCILIATION_VERSION = 1
FACTORYX_REGISTRY_RECONCILIATION_CHUNKS_PER_STEP = 2
FACTORYX_REGISTRY_ENTITY_NAMES = {
  "x-ev-charging-station",
  "x-ev-charging-station-v2",
  "x-ev-charging-station-v3",
  "x-ev-charging-station-v4",
  "x-sales-office",
  "x-robotaxi-service-center",
  "x-terrestrial-datacenter",
  "x-orbital-compute-array"
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
  ["storage-chest"] = 25,
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
FACTORYX_ENERGY_JUMPSTART_NORMAL_QUALITY_ITEMS = {
  ["passive-provider-chest"] = true,
  ["storage-chest"] = true
}
local FACTORYX_RUNTIME_VISUAL_CONFIGS = {
  ["x-sales-office"] = {
    status = true,
    sprite_prefix = "x-sales-office-status-red-frame-",
    working_sprite_prefix = "x-sales-office-status-green-frame-",
    warning_sprite_prefix = "x-sales-office-status-amber-frame-",
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
MEGAPACK_SALES_RADIUS = 384
MEGAPACK_INITIAL_ADOPTION_FRACTION = 0.05
MEGAPACK_REFERRAL_FRACTION = 0.05
MEGAPACK_REFERRAL_WAVE_TICKS = 5 * 60 * 60
MEGAPACK_BUYER_MAX_ACTIVE = 32
MEGAPACK_BUYER_STARTS_PER_SECOND = 4
MEGAPACK_BUYER_PATH_TIMEOUT_TICKS = 3 * 60 * 60
local CUSTOMER_MOBILE_SERVICE_RADIUS = 48
local CUSTOMER_WANDER_RADIUS = 8
local ENEMY_RELEASE_WANDER_TICKS = 60
ROAD_RAGE = {
  duration_ticks = 45 * 60,
  nearby_duration_ticks = 30 * 60,
  response_radius = 12,
  nearby_limit = 2,
  megatruck_duration_ticks = 60 * 60,
  megatruck_response_radius = 15,
  megatruck_nearby_limit = 5,
  max_active = 256,
  process_limit = 64
}
CUSTOMER_UNIT_COLOR = {r = 0.25, g = 0.95, b = 0.35, a = 1}
CUSTOMER_VEHICLE_CLASS_BY_ITEM = {
  ["x-prototype-roadster"] = "roadster",
  ["x-premium-ev"] = "premium",
  ["x-mass-market-ev"] = "mass-market",
  ["x-cybertruck"] = "cybertruck",
  ["x-robotaxi-fleet"] = "robotaxi"
}
ELECTRIC_VEHICLE_BATTERIES = {
  ["x-prototype-roadster"] = 1,
  ["x-premium-ev"] = 2,
  ["x-mass-market-ev"] = 1,
  ["x-cybertruck"] = 4,
  ["x-robotaxi-fleet"] = 2
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
  if not station or not station.valid then
    return nil
  end
  local base = STATION_CONFIGS[station.name]
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
    warning_sprite_prefix = config.warning_sprite_prefix,
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
        local market_state = storage.factoryx_sales_office_market_states
          and storage.factoryx_sales_office_market_states[unit_number]
        local market_warning = market_state
          and (market_state.kind == "low"
            or market_state.kind == "committed"
            or market_state.kind == "saturated")
          and market_state.surplus_office
          and (entry.entity.status == defines.entity_status.working
            or entry.entity.disabled_by_script)
        local quiet_mature_market = market_state
          and (market_state.kind == "saturated" or market_state.kind == "committed")
          and not market_state.surplus_office
        local prefix = market_warning and entry.warning_sprite_prefix
          or (quiet_mature_market and entry.working_sprite_prefix)
          or (entry.entity.status == defines.entity_status.working
            and entry.working_sprite_prefix or entry.stopped_sprite_prefix)
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
  local key = settlement and settlement.valid and (
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
  local frame_index = math.floor(game.tick / 30) % 8 + 1
  local seen = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
    if office.valid and office.unit_number then
      seen[office.unit_number] = true
      local recipe = office.get_recipe()
      local sprite_prefix = recipe and SALES_OFFICE_SHOWROOM_SPRITES[recipe.name]
      local active = sprite_prefix and office.status == defines.entity_status.working
      local entry = sales_office_showroom_renderings()[office.unit_number]
      if active and (
          not entry
          or entry.sprite_prefix ~= sprite_prefix
          or not entry.object
          or not entry.object.valid
        ) then
        destroy_sales_office_showroom_rendering(office.unit_number)
        local object = rendering.draw_sprite{
          sprite = sprite_prefix .. frame_index,
          surface = office.surface,
          target = office,
          target_offset = {0, 0},
          x_scale = 0.19,
          y_scale = 0.19,
          render_layer = "higher-object-above"
        }
        sales_office_showroom_renderings()[office.unit_number] = {
          object = object,
          sprite_prefix = sprite_prefix
        }
      elseif active and entry then
        entry.object.sprite = sprite_prefix .. frame_index
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
  if item_name == PREMIUM_EV_NAME then
    return count_premium_evs_produced(force)
  end
  return count_item_produced_raw(force, item_name)
end

function count_item_produced_raw(force, item_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_item_production_statistics(surface)
    count = count + (statistics.output_counts[item_name] or 0)
  end
  return count
end

function count_item_consumed_raw(force, item_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_item_production_statistics(surface)
    count = count + (statistics.input_counts[item_name] or 0)
  end
  return count
end

function production_history_by_force()
  storage.factoryx_production_history_by_force =
    storage.factoryx_production_history_by_force or {}
  return storage.factoryx_production_history_by_force
end

TRANSPORT_LINE_ENTITY_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true
}

function unique_inventory_ids()
  if factoryx_unique_inventory_ids then return factoryx_unique_inventory_ids end
  local seen = {}
  factoryx_unique_inventory_ids = {}
  for _, inventory_id in pairs(defines.inventory) do
    if not seen[inventory_id] then
      seen[inventory_id] = true
      factoryx_unique_inventory_ids[#factoryx_unique_inventory_ids + 1] = inventory_id
    end
  end
  table.sort(factoryx_unique_inventory_ids)
  return factoryx_unique_inventory_ids
end

function count_premium_ev_stock(force)
  local count = 0
  local inventory_ids = unique_inventory_ids()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{force = force}) do
      if entity.type ~= "character" then
        if entity.name == PREMIUM_EV_NAME then count = count + 1 end
        for _, inventory_id in pairs(inventory_ids) do
          local ok, inventory = pcall(function()
            return entity.get_inventory(inventory_id)
          end)
          if ok and inventory and inventory.valid then
            count = count + inventory.get_item_count(PREMIUM_EV_NAME)
          end
        end
        if entity.type == "inserter"
          and entity.held_stack.valid_for_read
          and entity.held_stack.name == PREMIUM_EV_NAME then
          count = count + entity.held_stack.count
        end
        if TRANSPORT_LINE_ENTITY_TYPES[entity.type] then
          local max_line = entity.get_max_transport_line_index()
          for line_index = 1, max_line do
            count = count + entity.get_transport_line(line_index)
              .get_item_count(PREMIUM_EV_NAME)
          end
        end
      end
    end
    for _, entity in pairs(surface.find_entities_filtered{type = "item-entity"}) do
      if entity.stack and entity.stack.valid_for_read
        and entity.stack.name == PREMIUM_EV_NAME then
        count = count + entity.stack.count
      end
    end
  end
  for _, player in pairs(force.players) do
    local main = player.get_main_inventory()
    if main then count = count + main.get_item_count(PREMIUM_EV_NAME) end
    local ok, trash = pcall(function()
      return player.get_inventory(defines.inventory.character_trash)
    end)
    if ok and trash then count = count + trash.get_item_count(PREMIUM_EV_NAME) end
  end
  return count
end

function premium_ev_production_history(force)
  local histories = production_history_by_force()
  histories[force.name] = ProductionHistory.ensure(histories[force.name])
  return histories[force.name]
end

function count_premium_evs_produced(force)
  local raw = count_item_produced_raw(force, PREMIUM_EV_NAME)
  local consumed = count_item_consumed_raw(force, PREMIUM_EV_NAME)
  local state = premium_ev_production_history(force)
  local statistics_reset = state.reconciled and raw < state.last_raw
  local proven_floor = consumed
  if not state.reconciled or statistics_reset then
    proven_floor = consumed + count_premium_ev_stock(force)
  end
  local was_reconciled = state.reconciled
  local total
  total, state = ProductionHistory.observe(state, raw, proven_floor)
  production_history_by_force()[force.name] = state
  if not was_reconciled and total > raw and not state.announced then
    state.announced = true
    force.print(string.format(
      "[Biter Motors] Reconciled Premium EV production history: %d lifetime vehicles (%d native production-stat count).",
      total,
      raw
    ))
  end
  return total
end

function premium_ev_production_history_status(force)
  local total = count_premium_evs_produced(force)
  local state = premium_ev_production_history(force)
  return {
    total = total,
    raw = count_item_produced_raw(force, PREMIUM_EV_NAME),
    consumed = count_item_consumed_raw(force, PREMIUM_EV_NAME),
    offset = state.offset,
    reset_count = state.reset_count,
    last_proven_floor = state.last_proven_floor,
    reconciled = state.reconciled
  }
end

function count_fluid_produced(force, fluid_name)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local statistics = force.get_fluid_production_statistics(surface)
    count = count + (statistics.output_counts[fluid_name] or 0)
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
      force.print("[Biter Motors] One billion cumulative AI Tokens generated. AGI Training Run is now available in the Planetary Energy Grid Controller.")
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
        if researched(force, config.technology) then
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
          for _, machine in pairs(registered_factoryx_entities("ai_machines", force)) do
            if machine.name == config.entity and machine.valid and machine.unit_number then
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
    local quality = FACTORYX_ENERGY_JUMPSTART_NORMAL_QUALITY_ITEMS[item_name]
      and "normal"
      or FACTORYX_ENERGY_JUMPSTART_QUALITY
    inventory.insert{name = item_name, count = count, quality = quality}
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
  return ELECTRIC_VEHICLE_BATTERIES[entity.name] + math.floor(quality_level / 2)
end

function install_vehicle_batteries(entity, charge_new_batteries)
  if not is_electric_vehicle(entity) or not entity.grid then
    return
  end
  local existing = {}
  for _, equipment in pairs(entity.grid.equipment) do
    if equipment.name == "battery-equipment" then
      existing[#existing + 1] = equipment
    end
  end
  local target = electric_vehicle_battery_target(entity)
  table.sort(existing, function(left, right) return left.energy > right.energy end)
  for index = #existing, target + 1, -1 do
    entity.grid.take{equipment = existing[index]}
  end
  local needed = target - math.min(#existing, target)
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

function ev_autopilot_runtime()
  storage.factoryx_ev_autopilot = EvAutopilot.ensure(storage.factoryx_ev_autopilot)
  return storage.factoryx_ev_autopilot
end

function is_ev_autopilot_eligible(entity)
  return is_electric_vehicle(entity)
    and entity.unit_number
    and EvAutopilot.is_eligible_name(entity.name)
end

function player_is_vehicle_driver(player, vehicle)
  if not player or not player.valid or not vehicle or not vehicle.valid then return false end
  local driver = vehicle.get_driver()
  return driver == player or driver == player.character
end

function set_ev_autopilot_status(vehicle, text, diode)
  if not vehicle or not vehicle.valid then return end
  pcall(function()
    vehicle.custom_status = {
      diode = diode or defines.entity_status_diode.green,
      label = text
    }
  end)
end

function clear_ev_autopilot_status(vehicle)
  if vehicle and vehicle.valid then pcall(function() vehicle.custom_status = nil end) end
end

function destroy_ev_autopilot_rendering(state)
  for _, object in pairs(state and state.render_objects or {}) do
    if object and object.valid then object.destroy() end
  end
  if state then state.render_objects = {} end
end

function draw_ev_autopilot_destination(state)
  destroy_ev_autopilot_rendering(state)
  local player = state.player_index and game.get_player(state.player_index)
  local vehicle = state.vehicle
  if not player or not vehicle or not vehicle.valid or not state.goal then return end
  state.render_objects = {
    rendering.draw_circle{
      color = {r = 0.10, g = 0.90, b = 0.55, a = 0.22},
      radius = state.mode == "summon" and 3 or 2,
      width = 3,
      filled = true,
      draw_on_ground = true,
      target = state.goal,
      surface = vehicle.surface,
      players = {player}
    },
    rendering.draw_circle{
      color = {r = 0.15, g = 1.0, b = 0.65, a = 0.95},
      radius = state.mode == "summon" and 3 or 2,
      width = 4,
      filled = false,
      draw_on_ground = true,
      target = state.goal,
      surface = vehicle.surface,
      players = {player}
    },
    rendering.draw_text{
      text = state.mode == "summon" and "SUMMON" or "NAVIGATE",
      color = {r = 0.55, g = 1.0, b = 0.72, a = 1},
      alignment = "center",
      target = state.goal,
      target_offset = {0, -2.5},
      surface = vehicle.surface,
      players = {player},
      scale = 0.9
    }
  }
end

function remember_player_ev(player, vehicle)
  if not player or not player.valid or not is_ev_autopilot_eligible(vehicle) then return false end
  local runtime = ev_autopilot_runtime()
  local active = runtime.active[vehicle.unit_number]
  if active and active.player_index ~= player.index then
    cancel_ev_autopilot(vehicle.unit_number, "another player took control", {notify = true})
  end
  EvAutopilot.remember_vehicle(runtime, player.index, vehicle.unit_number)
  return true
end

function remove_ev_from_autopilot_history(unit_number)
  if not unit_number then return end
  local runtime = ev_autopilot_runtime()
  if runtime.active[unit_number] then
    cancel_ev_autopilot(unit_number, "vehicle is no longer available", {notify = true})
  end
  EvAutopilot.forget_vehicle(runtime, unit_number)
end

function cancel_player_ev_autopilots(player_index, reason, notify)
  local runtime = ev_autopilot_runtime()
  local unit_numbers = {}
  for unit_number, state in pairs(runtime.active) do
    if state.player_index == player_index then
      unit_numbers[#unit_numbers + 1] = unit_number
    end
  end
  for _, unit_number in pairs(unit_numbers) do
    cancel_ev_autopilot(unit_number, reason, {notify = notify == true})
  end
end

function remove_player_ev_autopilot_history(player_index)
  local runtime = ev_autopilot_runtime()
  cancel_player_ev_autopilots(player_index, "controlling player disconnected", false)
  for _, unit_number in pairs(runtime.recent_by_player[player_index] or {}) do
    if runtime.owner_by_vehicle[unit_number] == player_index then
      runtime.owner_by_vehicle[unit_number] = nil
    end
  end
  runtime.recent_by_player[player_index] = nil
end

function reset_active_ev_autopilots()
  local runtime = ev_autopilot_runtime()
  local unit_numbers = {}
  for unit_number in pairs(runtime.active) do unit_numbers[#unit_numbers + 1] = unit_number end
  for _, unit_number in pairs(unit_numbers) do
    cancel_ev_autopilot(unit_number, nil, {notify = false, record = false})
  end
  runtime.active = {}
  runtime.order = {}
  runtime.order_index = 1
  runtime.path_requests = {}
end

function ev_autopilot_charge_ratio(vehicle)
  local energy, capacity = vehicle_total_charge_energy(vehicle)
  return capacity > 0 and energy / capacity or 0
end

function ev_autopilot_nearest_enemy(surface, force, position, radius)
  if not surface or not surface.valid then return nil end
  return surface.find_nearest_enemy{
    position = position,
    max_distance = radius or EvAutopilot.config.safety_radius,
    force = force
  }
end

function ev_autopilot_path_is_safe(state, path)
  local vehicle = state.vehicle
  if not vehicle or not vehicle.valid then return false, "vehicle is no longer available" end
  for _, waypoint in pairs(path or {}) do
    if waypoint.needs_destroy_to_reach then
      return false, "route requires destroying an obstacle"
    end
  end
  local stride = math.max(1, math.ceil(#path / 64))
  for index = 1, #path, stride do
    local enemy = ev_autopilot_nearest_enemy(
      vehicle.surface,
      vehicle.force,
      path[index].position,
      EvAutopilot.config.safety_radius
    )
    if enemy then return false, "hostile activity makes the route unsafe" end
  end
  return true
end

function ev_autopilot_safe_goal(vehicle, requested, stand_off)
  local target = {x = requested.x, y = requested.y}
  if stand_off and stand_off > 0 then
    local dx = vehicle.position.x - target.x
    local dy = vehicle.position.y - target.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001 then
      dx, dy, length = 1, 0, 1
    end
    target.x = target.x + dx * stand_off / length
    target.y = target.y + dy * stand_off / length
  end
  return vehicle.surface.find_non_colliding_position(
    vehicle.name,
    target,
    8,
    0.5,
    false
  )
end

function cancel_ev_autopilot(unit_number, reason, options)
  options = options or {}
  local runtime = ev_autopilot_runtime()
  local state = runtime.active[unit_number]
  if not state then return false end
  runtime.active[unit_number] = nil
  if state.path_request_id then runtime.path_requests[state.path_request_id] = nil end
  destroy_ev_autopilot_rendering(state)
  local vehicle = state.vehicle
  if vehicle and vehicle.valid then
    if not options.manual then
      vehicle.riding_state = {
        acceleration = defines.riding.acceleration.braking,
        direction = defines.riding.direction.straight
      }
    end
    clear_ev_autopilot_status(vehicle)
  end
  local player = state.player_index and game.get_player(state.player_index)
  if player and options.notify ~= false and reason then
    local prefix = options.completed and "[Biter Motors] " or "[Biter Motors] Autopilot canceled: "
    player.print(prefix .. reason, options.completed
      and {r = 0.35, g = 1.0, b = 0.55}
      or {r = 1.0, g = 0.65, b = 0.20})
  end
  if options.record ~= false then
    if options.completed then
      runtime.stats.completed = (runtime.stats.completed or 0) + 1
    else
      runtime.stats.canceled = (runtime.stats.canceled or 0) + 1
      local reason_key = reason or "unspecified"
      runtime.stats.canceled_by_reason[reason_key] =
        (runtime.stats.canceled_by_reason[reason_key] or 0) + 1
    end
  end
  return true
end

function request_ev_autopilot_path(state)
  local vehicle = state and state.vehicle
  if not vehicle or not vehicle.valid then
    if state then cancel_ev_autopilot(state.unit_number, "vehicle is no longer available", {notify = true}) end
    return false
  end
  if ev_autopilot_nearest_enemy(
    vehicle.surface,
    vehicle.force,
    vehicle.position,
    EvAutopilot.config.safety_radius
  ) or ev_autopilot_nearest_enemy(
    vehicle.surface,
    vehicle.force,
    state.goal,
    EvAutopilot.config.safety_radius
  ) then
    cancel_ev_autopilot(state.unit_number, "hostile activity makes the route unsafe", {notify = true})
    return false
  end
  local runtime = ev_autopilot_runtime()
  if state.path_request_id then runtime.path_requests[state.path_request_id] = nil end
  local ok, request_id = pcall(function()
    return vehicle.surface.request_path{
      bounding_box = vehicle.prototype.collision_box,
      collision_mask = vehicle.prototype.collision_mask,
      start = vehicle.position,
      goal = state.goal,
      force = vehicle.force,
      radius = 1.5,
      can_open_gates = true,
      max_gap_size = 0,
      entity_to_ignore = vehicle
    }
  end)
  if not ok or not request_id then
    cancel_ev_autopilot(state.unit_number, "route request failed", {notify = true})
    return false
  end
  state.path_request_id = request_id
  state.status = "pathing"
  state.path = nil
  state.next_path_tick = nil
  runtime.path_requests[request_id] = state.unit_number
  set_ev_autopilot_status(vehicle, "Autopilot: calculating route", defines.entity_status_diode.yellow)
  return true
end

function activate_ev_autopilot(vehicle, goal, mode, player_index, smoke_test)
  local runtime = ev_autopilot_runtime()
  if not runtime.active[vehicle.unit_number]
    and EvAutopilot.active_count(runtime) >= EvAutopilot.config.max_active then
    return false
  end
  if runtime.active[vehicle.unit_number] then
    cancel_ev_autopilot(vehicle.unit_number, nil, {notify = false, manual = true})
  end
  local state = {
    unit_number = vehicle.unit_number,
    vehicle = vehicle,
    player_index = player_index,
    mode = mode,
    goal = {x = goal.x, y = goal.y},
    surface_index = vehicle.surface.index,
    smoke_test = smoke_test == true,
    path_retry_count = 0,
    stuck_repaths = 0,
    started_tick = game.tick,
    progress_tick = game.tick,
    progress_position = {x = vehicle.position.x, y = vehicle.position.y},
    next_safety_tick = game.tick
  }
  runtime.active[vehicle.unit_number] = state
  EvAutopilot.track_active(runtime, vehicle.unit_number)
  draw_ev_autopilot_destination(state)
  return request_ev_autopilot_path(state)
end

function start_ev_autopilot(player, vehicle, goal, mode)
  if not player or not player.valid or not is_ev_autopilot_eligible(vehicle) then
    if player then player.print("[Biter Motors] This vehicle does not support Autopilot.") end
    return false
  end
  if not researched(player.force, EV_AUTOPILOT_TECH_NAME) then
    player.print("[Biter Motors] Research Autonomous Logistics to unlock EV Autopilot.")
    return false
  end
  if player.surface ~= vehicle.surface then
    player.print("[Biter Motors] Vehicle and destination must be on the same surface.")
    return false
  end
  if mode == "navigate" and not player_is_vehicle_driver(player, vehicle) then
    player.print("[Biter Motors] Enter an eligible Biter Motors EV before selecting Navigate.")
    return false
  end
  if mode == "summon" and (vehicle.get_driver() or vehicle.get_passenger()) then
    player.print("[Biter Motors] The selected EV is occupied.")
    return false
  end
  if ev_autopilot_charge_ratio(vehicle) < EvAutopilot.config.summon_start_charge then
    player.print("[Biter Motors] EV battery is below 10%; charge it before using Autopilot.")
    return false
  end
  local runtime = ev_autopilot_runtime()
  if not runtime.active[vehicle.unit_number]
    and EvAutopilot.active_count(runtime) >= EvAutopilot.config.max_active then
    player.print("[Biter Motors] Autopilot controller is at its 32-vehicle safety limit.")
    return false
  end
  remember_player_ev(player, vehicle)
  return activate_ev_autopilot(vehicle, goal, mode, player.index, false)
end

function nearest_recent_ev_for_player(player)
  local runtime = ev_autopilot_runtime()
  local best = nil
  local best_distance = nil
  local saw_low_battery = false
  for _, unit_number in pairs(runtime.recent_by_player[player.index] or {}) do
    local vehicle = electric_vehicle_registry()[unit_number]
    if runtime.owner_by_vehicle[unit_number] == player.index
      and is_ev_autopilot_eligible(vehicle)
      and vehicle.surface == player.surface
      and not vehicle.get_driver()
      and not vehicle.get_passenger() then
      if ev_autopilot_charge_ratio(vehicle) >= EvAutopilot.config.summon_start_charge then
        local distance = EvAutopilot.distance_squared(vehicle.position, player.position)
        if not best_distance or distance < best_distance then
          best = vehicle
          best_distance = distance
        end
      else
        saw_low_battery = true
      end
    end
  end
  return best, saw_low_battery
end

function summon_recent_ev(player)
  if not player or not player.valid then return false end
  if player.vehicle then
    player.print("[Biter Motors] Exit your current vehicle before summoning another EV.")
    return false
  end
  local vehicle, saw_low_battery = nearest_recent_ev_for_player(player)
  if not vehicle then
    player.print(saw_low_battery
      and "[Biter Motors] Recent EVs on this surface are below 10% battery."
      or "[Biter Motors] No unoccupied recent EV is available on this surface.")
    return false
  end
  local goal = ev_autopilot_safe_goal(vehicle, player.position, 6)
  if not goal then
    player.print("[Biter Motors] No safe parking position was found near you.")
    return false
  end
  return start_ev_autopilot(player, vehicle, goal, "summon")
end

function apply_ev_autopilot_drive(vehicle, decision)
  local acceleration = defines.riding.acceleration[decision.acceleration]
  local direction = defines.riding.direction[decision.direction]
  vehicle.riding_state = {acceleration = acceleration, direction = direction}
end

function process_ev_autopilot_state(state)
  local vehicle = state.vehicle
  local player = state.player_index and game.get_player(state.player_index)
  if not vehicle or not vehicle.valid then
    cancel_ev_autopilot(state.unit_number, "vehicle was destroyed", {notify = true})
    return
  end
  if not state.smoke_test and (not player or not player.valid or not player.connected) then
    cancel_ev_autopilot(state.unit_number, "controlling player disconnected", {notify = false})
    return
  end
  if vehicle.surface.index ~= state.surface_index
    or (player and player.surface ~= vehicle.surface) then
    cancel_ev_autopilot(state.unit_number, "player and EV are no longer on the same surface", {notify = true})
    return
  end
  if state.mode == "navigate" and not player_is_vehicle_driver(player, vehicle) then
    cancel_ev_autopilot(state.unit_number, "player left the EV", {notify = false})
    return
  end
  if state.mode == "summon" and (vehicle.get_driver() or vehicle.get_passenger()) then
    cancel_ev_autopilot(state.unit_number, "someone entered the summoned EV", {notify = true, manual = true})
    return
  end
  if game.tick >= (state.next_safety_tick or game.tick) then
    state.next_safety_tick = game.tick + EvAutopilot.config.safety_check_ticks
    if ev_autopilot_charge_ratio(vehicle) <= EvAutopilot.config.cancel_charge then
      cancel_ev_autopilot(state.unit_number, "battery reached 3%", {notify = true})
      return
    end
    if ev_autopilot_nearest_enemy(
      vehicle.surface,
      vehicle.force,
      vehicle.position,
      EvAutopilot.config.safety_radius
    ) then
      cancel_ev_autopilot(state.unit_number, "hostile activity detected within 20 tiles", {notify = true})
      return
    end
  end
  if state.status == "retry" then
    if game.tick >= (state.next_path_tick or game.tick) then request_ev_autopilot_path(state) end
    return
  end
  if state.status ~= "driving" or not state.path then return end

  while state.waypoint_index < #state.path
    and EvAutopilot.distance_squared(
      vehicle.position,
      state.path[state.waypoint_index].position
    ) <= 2.25 do
    state.waypoint_index = state.waypoint_index + 1
  end
  local final_waypoint = state.waypoint_index >= #state.path
  local waypoint = state.path[state.waypoint_index].position
  local stop_distance = state.mode == "summon"
    and EvAutopilot.config.summon_stop_distance
    or EvAutopilot.config.navigate_stop_distance
  local decision = EvAutopilot.drive_decision(vehicle, waypoint, final_waypoint, stop_distance)
  if final_waypoint and decision.distance <= stop_distance and math.abs(vehicle.speed or 0) <= 0.025 then
    cancel_ev_autopilot(
      state.unit_number,
      state.mode == "summon" and "Summoned EV arrived." or "Destination reached.",
      {notify = true, completed = true}
    )
    return
  end
  apply_ev_autopilot_drive(vehicle, decision)

  if EvAutopilot.distance_squared(vehicle.position, state.progress_position) >= 4 then
    state.progress_position = {x = vehicle.position.x, y = vehicle.position.y}
    state.progress_tick = game.tick
  elseif game.tick - (state.progress_tick or game.tick) >= EvAutopilot.config.stuck_ticks then
    state.stuck_repaths = (state.stuck_repaths or 0) + 1
    if state.stuck_repaths > EvAutopilot.config.path_retry_limit then
      cancel_ev_autopilot(state.unit_number, "EV remained stuck after three route attempts", {notify = true})
    else
      state.progress_tick = game.tick
      state.progress_position = {x = vehicle.position.x, y = vehicle.position.y}
      request_ev_autopilot_path(state)
    end
  end
end

function process_ev_autopilots()
  local runtime = ev_autopilot_runtime()
  for _ = 1, EvAutopilot.config.updates_per_tick do
    local unit_number = EvAutopilot.next_active(runtime)
    if not unit_number then return end
    local state = runtime.active[unit_number]
    if state then process_ev_autopilot_state(state) end
  end
end

function handle_ev_autopilot_path_result(event)
  local runtime = ev_autopilot_runtime()
  local unit_number = runtime.path_requests[event.id]
  if not unit_number then return end
  runtime.path_requests[event.id] = nil
  local state = runtime.active[unit_number]
  if not state or state.path_request_id ~= event.id then return end
  state.path_request_id = nil
  if event.try_again_later then
    state.path_retry_count = (state.path_retry_count or 0) + 1
    if state.path_retry_count > EvAutopilot.config.path_retry_limit then
      cancel_ev_autopilot(unit_number, "pathfinder remained busy after three retries", {notify = true})
    else
      state.status = "retry"
      state.next_path_tick = game.tick + EvAutopilot.config.path_retry_ticks
      set_ev_autopilot_status(state.vehicle, "Autopilot: waiting to retry route", defines.entity_status_diode.yellow)
    end
    return
  end
  if not event.path or #event.path == 0 then
    cancel_ev_autopilot(unit_number, "no route found", {notify = true})
    return
  end
  local safe, reason = ev_autopilot_path_is_safe(state, event.path)
  if not safe then
    cancel_ev_autopilot(unit_number, reason or "no safe route found", {notify = true})
    return
  end
  state.path = event.path
  state.waypoint_index = 1
  state.status = "driving"
  state.progress_position = {x = state.vehicle.position.x, y = state.vehicle.position.y}
  state.progress_tick = game.tick
  set_ev_autopilot_status(state.vehicle, state.mode == "summon"
    and "Autopilot: summoning"
    or "Autopilot: navigating", defines.entity_status_diode.green)
end

function handle_ev_autopilot_destination(event)
  if event.item ~= EV_AUTOPILOT_DESTINATION_ITEM then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local vehicle = player.vehicle
  if not is_ev_autopilot_eligible(vehicle) then
    player.print("[Biter Motors] Navigate supports Premium, Mass-market, Megatruck, and Robotaxi EVs. The Prototype Roadster has no Autopilot.")
    player.clear_cursor()
    return
  end
  if event.surface ~= vehicle.surface then
    player.print("[Biter Motors] Select a destination on the EV's current surface.")
    player.clear_cursor()
    return
  end
  local requested = EvAutopilot.area_center(event.area)
  local goal = ev_autopilot_safe_goal(vehicle, requested, 0)
  player.clear_cursor()
  if not goal then
    player.print("[Biter Motors] No safe stopping position was found near that destination.")
    return
  end
  start_ev_autopilot(player, vehicle, goal, "navigate")
end

function cancel_player_ev_autopilot_manual(player)
  if not player or not player.valid or not player.vehicle or not player.vehicle.unit_number then return end
  local state = ev_autopilot_runtime().active[player.vehicle.unit_number]
  if state and state.mode == "navigate" and state.player_index == player.index then
    cancel_ev_autopilot(state.unit_number, "manual control", {notify = true, manual = true})
  end
end

function ev_autopilot_status(player_index)
  local runtime = ev_autopilot_runtime()
  local recent = {}
  for _, unit_number in pairs(runtime.recent_by_player[player_index] or {}) do
    local vehicle = electric_vehicle_registry()[unit_number]
    recent[#recent + 1] = {
      unit_number = unit_number,
      valid = vehicle and vehicle.valid or false,
      name = vehicle and vehicle.valid and vehicle.name or nil,
      owner = runtime.owner_by_vehicle[unit_number]
    }
  end
  local active = {}
  for unit_number, state in pairs(runtime.active) do
    active[#active + 1] = {
      unit_number = unit_number,
      player_index = state.player_index,
      mode = state.mode,
      status = state.status,
      waypoint_index = state.waypoint_index,
      path_length = state.path and #state.path or 0
    }
  end
  return {
    recent = recent,
    active = active,
    active_count = #active,
    stats = runtime.stats
  }
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
      settlement = settlement,
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
    population.settlement = settlement
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
  elseif AI_EFFICIENCY_MACHINE_NAMES[entity.name] then
    PerformanceState.track(PerformanceState.ensure(storage), "ai_machines", entity)
  end
end

function untrack_factoryx_entity(entity)
  if not entity or not entity.unit_number then return end
  PerformanceState.untrack(PerformanceState.ensure(storage), entity)
end

function registered_factoryx_entities(kind, force, surface)
  return PerformanceState.entities(PerformanceState.ensure(storage), kind, force, surface)
end

function electric_semi_runtime()
  storage.factoryx_electric_semi_runtime = storage.factoryx_electric_semi_runtime or {
    semis = {}, semi_order = {}, semi_cursor = 1,
    stops = {}, stop_order = {}, stop_cursor = 1,
    batteries = {}, stop_power = {}, stop_ticks = {}
  }
  return storage.factoryx_electric_semi_runtime
end

function track_electric_semi_runtime(entity, factory_new)
  if not entity or not entity.valid or not entity.unit_number then return end
  local runtime = electric_semi_runtime()
  if entity.name == ELECTRIC_SEMI_NAME then
    if not runtime.semis[entity.unit_number] then
      runtime.semis[entity.unit_number] = entity
      runtime.semi_order[#runtime.semi_order + 1] = entity.unit_number
    end
    local battery = runtime.batteries[entity.unit_number]
    if not battery then
      runtime.batteries[entity.unit_number] = {
        energy = factory_new == false and 0 or SEMI_BATTERY_CAPACITY,
        last_speed = math.abs(entity.speed or 0),
        last_tick = game.tick,
        traction_used = 0,
        regenerated = 0
      }
    end
  elseif entity.name == SEMI_CHARGING_STOP_NAME and not runtime.stops[entity.unit_number] then
    runtime.stops[entity.unit_number] = entity
    runtime.stop_order[#runtime.stop_order + 1] = entity.unit_number
  end
end

function clear_semi_drive_permission(entity)
  if not entity or not entity.valid or not entity.burner then return end
  entity.burner.inventory.clear()
  entity.burner.currently_burning = nil
end

function set_semi_drive_permission(entity, enabled)
  if not entity or not entity.valid or not entity.burner then return end
  if not enabled then
    clear_semi_drive_permission(entity)
    return
  end
  if not entity.burner.currently_burning
    and entity.burner.inventory.get_item_count(ELECTRIC_SEMI_FUEL_NAME) == 0 then
    entity.burner.inventory.insert{name = ELECTRIC_SEMI_FUEL_NAME, count = 1}
  end
end

function electric_semis_in_train(train)
  local result = {}
  if not train or not train.valid then return result end
  for _, group in pairs(train.locomotives or {}) do
    for _, locomotive in pairs(group) do
      if locomotive.valid and locomotive.name == ELECTRIC_SEMI_NAME then
        result[#result + 1] = locomotive
      end
    end
  end
  return result
end

function process_electric_semi(entity, battery)
  local tick_delta = math.max(1, game.tick - (battery.last_tick or game.tick))
  local seconds = tick_delta / 60
  local speed = math.abs(entity.speed or 0)
  if battery.energy <= SEMI_RESERVE_THRESHOLD and speed > SEMI_RESERVE_SPEED then
    local train = entity.train
    if train and train.valid then
      train.speed = train.speed < 0 and -SEMI_RESERVE_SPEED or SEMI_RESERVE_SPEED
    end
    speed = SEMI_RESERVE_SPEED
    battery.last_speed = math.min(battery.last_speed or speed, SEMI_RESERVE_SPEED)
  end
  local train = entity.train
  local semis = electric_semis_in_train(train)
  local mass_share = train and train.valid and train.weight / math.max(1, #semis) or entity.prototype.weight
  local previous_kinetic = mass_share * (battery.last_speed or speed) ^ 2 * SEMI_KINETIC_ENERGY_SCALE
  local current_kinetic = mass_share * speed ^ 2 * SEMI_KINETIC_ENERGY_SCALE
  local kinetic_delta = current_kinetic - previous_kinetic
  if kinetic_delta > 0 then
    local draw = kinetic_delta / 0.9
    battery.energy = battery.energy - draw
    battery.traction_used = (battery.traction_used or 0) + draw
  elseif kinetic_delta < 0 then
    local recovered = math.min(-kinetic_delta * SEMI_REGEN_EFFICIENCY, SEMI_BATTERY_CAPACITY - battery.energy)
    battery.energy = battery.energy + recovered
    battery.regenerated = (battery.regenerated or 0) + recovered
  end
  if speed > 0.001 then
    local speed_ratio = math.min(1, speed / 3.0)
    local rolling_draw = (200000 + 800000 * speed_ratio * speed_ratio) * seconds
    battery.energy = battery.energy - rolling_draw
    battery.traction_used = (battery.traction_used or 0) + rolling_draw
  end
  battery.energy = math.max(0, math.min(SEMI_BATTERY_CAPACITY, battery.energy))
  battery.reserve_mode = battery.energy <= SEMI_RESERVE_THRESHOLD
  if battery.reserve_mode and speed > SEMI_RESERVE_SPEED then
    local train = entity.train
    if train and train.valid then
      train.speed = train.speed < 0 and -SEMI_RESERVE_SPEED or SEMI_RESERVE_SPEED
    end
    speed = SEMI_RESERVE_SPEED
  end
  battery.last_speed = speed
  battery.last_tick = game.tick
  set_semi_drive_permission(entity, true)
end

function ensure_semi_charging_power(stop)
  local runtime = electric_semi_runtime()
  local power = runtime.stop_power[stop.unit_number]
  if power and power.valid then return power end
  for _, candidate in pairs(stop.surface.find_entities_filtered{
    name = SEMI_CHARGING_POWER_NAME, position = stop.position, radius = 0.25, force = stop.force
  }) do
    if candidate.valid and not power then power = candidate
    elseif candidate.valid then candidate.destroy() end
  end
  if not power then
    power = stop.surface.create_entity{
      name = SEMI_CHARGING_POWER_NAME,
      position = stop.position,
      force = stop.force,
      quality = stop.quality,
      create_build_effect_smoke = false
    }
  end
  runtime.stop_power[stop.unit_number] = power
  return power
end

function process_semi_charging_stop(stop)
  local runtime = electric_semi_runtime()
  local power = ensure_semi_charging_power(stop)
  if not power or not power.valid then return end
  local train = stop.get_stopped_train()
  local semis = electric_semis_in_train(train)
  local charging = {}
  for _, semi in pairs(semis) do
    local battery = runtime.batteries[semi.unit_number]
    if battery and battery.energy < SEMI_BATTERY_CAPACITY then charging[#charging + 1] = battery end
  end
  local tick_delta = math.max(1, game.tick - (runtime.stop_ticks[stop.unit_number] or game.tick))
  runtime.stop_ticks[stop.unit_number] = game.tick
  if #charging == 0 then
    power.power_usage = 0
    return
  end
  power.power_usage = SEMI_CHARGING_POWER
  local power_factor = 1
  if power.status == defines.entity_status.no_power then power_factor = 0
  elseif power.status == defines.entity_status.low_power then power_factor = 0.5
  elseif not power.is_connected_to_electric_network() then power_factor = 0 end
  local available = SEMI_CHARGING_POWER * tick_delta / 60 * power_factor
  for _, battery in pairs(charging) do
    local delivered = math.min(available / #charging, SEMI_BATTERY_CAPACITY - battery.energy)
    battery.energy = battery.energy + delivered
  end
end

function process_bounded_semi_queue(order, members, cursor_name, callback)
  local runtime = electric_semi_runtime()
  local attempts = 0
  local budget = math.min(#order, SEMI_PROCESS_BUDGET)
  while #order > 0 and attempts < budget do
    if runtime[cursor_name] > #order then runtime[cursor_name] = 1 end
    local index = runtime[cursor_name]
    local unit_number = order[index]
    local entity = members[unit_number]
    attempts = attempts + 1
    if not entity or not entity.valid then
      members[unit_number] = nil
      table.remove(order, index)
    else
      callback(entity)
      runtime[cursor_name] = index + 1
    end
  end
end

function process_electric_semi_runtime()
  local runtime = electric_semi_runtime()
  process_bounded_semi_queue(runtime.semi_order, runtime.semis, "semi_cursor", function(entity)
    local battery = runtime.batteries[entity.unit_number]
    if battery then process_electric_semi(entity, battery) end
  end)
  process_bounded_semi_queue(runtime.stop_order, runtime.stops, "stop_cursor", process_semi_charging_stop)
end

function rebuild_electric_semi_runtime()
  local old = storage.factoryx_electric_semi_runtime
  storage.factoryx_electric_semi_runtime = {
    semis = {}, semi_order = {}, semi_cursor = 1,
    stops = {}, stop_order = {}, stop_cursor = 1,
    batteries = old and old.batteries or {}, stop_power = {}, stop_ticks = {}
  }
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = {ELECTRIC_SEMI_NAME, SEMI_CHARGING_STOP_NAME}}) do
      track_electric_semi_runtime(entity, true)
    end
  end
end

function rebuild_factoryx_entity_registries()
  PerformanceState.ensure(storage).registries = {
    stations = {},
    sales_offices = {},
    robotaxi_centers = {},
    ai_machines = {}
  }
  local names = {
    SALES_OFFICE_NAME,
    ROBOTAXI_SERVICE_CENTER_NAME,
    "x-terrestrial-datacenter",
    "x-orbital-compute-array"
  }
  for _, name in pairs(STATION_NAMES) do names[#names + 1] = name end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = names}) do
      track_factoryx_entity(entity)
    end
  end
  rebuild_factoryx_registry_reconciliation_chunks()
end

function rebuild_factoryx_registry_reconciliation_chunks()
  local state = {
    version = FACTORYX_REGISTRY_RECONCILIATION_VERSION,
    by_surface = {},
    surface_order = {},
    surface_cursor = 1
  }
  for _, surface in pairs(game.surfaces) do
    local surface_state = {chunks = {}, keys = {}, cursor = 1}
    state.by_surface[surface.index] = surface_state
    state.surface_order[#state.surface_order + 1] = surface.index
    for chunk in surface.get_chunks() do
      local key = chunk.x .. ":" .. chunk.y
      surface_state.keys[key] = true
      surface_state.chunks[#surface_state.chunks + 1] = {x = chunk.x, y = chunk.y}
    end
  end
  table.sort(state.surface_order)
  storage.factoryx_registry_reconciliation = state
  return state
end

function factoryx_registry_reconciliation_state()
  local state = storage.factoryx_registry_reconciliation
  if not state or state.version ~= FACTORYX_REGISTRY_RECONCILIATION_VERSION then
    state = rebuild_factoryx_registry_reconciliation_chunks()
  end
  return state
end

function register_factoryx_reconciliation_chunk(surface, position)
  if not surface or not surface.valid or not position then return end
  local state = factoryx_registry_reconciliation_state()
  local surface_state = state.by_surface[surface.index]
  if not surface_state then
    surface_state = {chunks = {}, keys = {}, cursor = 1}
    state.by_surface[surface.index] = surface_state
    state.surface_order[#state.surface_order + 1] = surface.index
    table.sort(state.surface_order)
  end
  local key = position.x .. ":" .. position.y
  if surface_state.keys[key] then return end
  surface_state.keys[key] = true
  surface_state.chunks[#surface_state.chunks + 1] = {x = position.x, y = position.y}
end

function next_factoryx_reconciliation_chunk(state)
  local attempts = #state.surface_order
  while attempts > 0 and #state.surface_order > 0 do
    if state.surface_cursor > #state.surface_order then state.surface_cursor = 1 end
    local surface_index = state.surface_order[state.surface_cursor]
    local surface = game.surfaces[surface_index]
    local surface_state = state.by_surface[surface_index]
    if not surface or not surface.valid or not surface_state then
      table.remove(state.surface_order, state.surface_cursor)
      state.by_surface[surface_index] = nil
    elseif #surface_state.chunks == 0 then
      state.surface_cursor = state.surface_cursor + 1
    else
      if surface_state.cursor > #surface_state.chunks then surface_state.cursor = 1 end
      local chunk = surface_state.chunks[surface_state.cursor]
      surface_state.cursor = surface_state.cursor + 1
      if surface_state.cursor > #surface_state.chunks then
        surface_state.cursor = 1
        state.surface_cursor = state.surface_cursor + 1
      end
      return surface, chunk
    end
    attempts = attempts - 1
  end
  return nil, nil
end

function reconcile_factoryx_entity_registry_step()
  local reconciliation = factoryx_registry_reconciliation_state()
  local performance_state = PerformanceState.ensure(storage)
  local discovered = 0
  local scanned = 0
  for _ = 1, FACTORYX_REGISTRY_RECONCILIATION_CHUNKS_PER_STEP do
    local surface, chunk = next_factoryx_reconciliation_chunk(reconciliation)
    if not surface then break end
    local area = {
      {chunk.x * 32, chunk.y * 32},
      {(chunk.x + 1) * 32, (chunk.y + 1) * 32}
    }
    for _, entity in pairs(surface.find_entities_filtered{
      name = FACTORYX_REGISTRY_ENTITY_NAMES,
      area = area
    }) do
      local unit_number = entity.unit_number
      local registries = performance_state.registries
      local tracked = unit_number and (
        registries.stations[unit_number]
        or registries.sales_offices[unit_number]
        or registries.robotaxi_centers[unit_number]
        or registries.ai_machines[unit_number]
      )
      if unit_number and not tracked then
        track_factoryx_entity(entity)
        mark_factoryx_market_dirty(entity.force, "registry-reconciled")
        discovered = discovered + 1
      end
    end
    scanned = scanned + 1
  end
  storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
  storage.factoryx_perf_counters.registry_reconciliation_steps =
    (storage.factoryx_perf_counters.registry_reconciliation_steps or 0) + 1
  storage.factoryx_perf_counters.registry_reconciliation_chunks =
    (storage.factoryx_perf_counters.registry_reconciliation_chunks or 0) + scanned
  storage.factoryx_perf_counters.registry_reconciliation_discoveries =
    (storage.factoryx_perf_counters.registry_reconciliation_discoveries or 0) + discovered
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
      and not buyer_reserved_by_unit()[unit_number]
      and not megapack_buyer_reservations()[unit_number] then
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

function customer_road_rage_states()
  storage.factoryx_customer_road_rage_states = storage.factoryx_customer_road_rage_states or {}
  return storage.factoryx_customer_road_rage_states
end

function customer_road_rage_timing_wheel()
  storage.factoryx_customer_road_rage_timing_wheel = TimingWheel.ensure(
    storage.factoryx_customer_road_rage_timing_wheel,
    600
  )
  return storage.factoryx_customer_road_rage_timing_wheel
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

function megapack_adoption_states()
  storage.factoryx_megapack_adoption_states = storage.factoryx_megapack_adoption_states or {}
  return storage.factoryx_megapack_adoption_states
end

function megapack_office_reservations()
  storage.factoryx_megapack_office_reservations =
    storage.factoryx_megapack_office_reservations or {}
  return storage.factoryx_megapack_office_reservations
end

function megapack_buyer_trips()
  storage.factoryx_megapack_buyer_trips = storage.factoryx_megapack_buyer_trips or {}
  return storage.factoryx_megapack_buyer_trips
end

function megapack_buyer_reservations()
  storage.factoryx_megapack_buyer_reservations =
    storage.factoryx_megapack_buyer_reservations or {}
  return storage.factoryx_megapack_buyer_reservations
end

function megapack_installation_renderings()
  storage.factoryx_megapack_installation_renderings =
    storage.factoryx_megapack_installation_renderings or {}
  return storage.factoryx_megapack_installation_renderings
end

function sales_office_market_states()
  storage.factoryx_sales_office_market_states = storage.factoryx_sales_office_market_states or {}
  return storage.factoryx_sales_office_market_states
end

function sales_office_market_alert_states()
  storage.factoryx_sales_office_market_alert_states =
    storage.factoryx_sales_office_market_alert_states or {}
  return storage.factoryx_sales_office_market_alert_states
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
      local megapack_market = current_recipe_name(office) == MEGAPACK_SALE_RECIPE
      local radius = megapack_market and MEGAPACK_SALES_RADIUS or SALES_OFFICE_CUSTOMER_RADIUS
      local fill_color = megapack_market
        and {r = 0.10, g = 0.20, b = 0.08, a = 0.10}
        or {r = 0.03, g = 0.16, b = 0.18, a = 0.18}
      local edge_color = megapack_market
        and {r = 0.42, g = 0.72, b = 0.30, a = 0.62}
        or {r = 0.18, g = 0.62, b = 0.58, a = 0.72}
      objects[#objects + 1] = rendering.draw_circle{
        color = fill_color,
        radius = radius,
        width = 1,
        filled = true,
        target = office,
        surface = surface,
        players = {player},
        render_mode = "chart"
      }
      objects[#objects + 1] = rendering.draw_circle{
        color = edge_color,
        radius = radius,
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
    and force.name ~= ROAD_RAGE_FORCE_NAME
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

function road_rage_force()
  local force = game.forces[ROAD_RAGE_FORCE_NAME]
  if not force then force = game.create_force(ROAD_RAGE_FORCE_NAME) end
  return force
end

local function is_biter_customer_entity(entity)
  return entity and entity.valid and BITER_CUSTOMER_ENTITY_NAMES[entity.name]
end

local function is_hostile_worm_entity(entity)
  return entity and entity.valid and HOSTILE_WORM_ENTITY_NAMES[entity.name]
end

local function nearby_real_power_pole(station)
  storage.factoryx_station_power_pole_cache = storage.factoryx_station_power_pole_cache or {}
  local cache = storage.factoryx_station_power_pole_cache
  local unit_number = station.unit_number
  local cached = unit_number and cache[unit_number]
  if cached and cached.tick == game.tick then
    return cached.pole and cached.pole.valid and cached.pole or nil
  end
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
      local supply_distance = pole.prototype.get_supply_area_distance(pole.quality)
      local distance_squared = dx * dx + dy * dy
      if math.abs(dx) <= supply_distance + 0.001
        and math.abs(dy) <= supply_distance + 0.001
        and (not nearest_distance_squared or distance_squared < nearest_distance_squared) then
        nearest = pole
        nearest_distance_squared = distance_squared
      end
    end
  end
  if unit_number then
    cache[unit_number] = {tick = game.tick, pole = nearest}
  end
  return nearest
end

local function station_has_grid_access(station)
  return station and station.valid and nearby_real_power_pole(station) ~= nil
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

  local connections = storage.factoryx_station_grid_connections or {}
  local connector = connections[station.unit_number]
  if connector and connector.valid then
    connector.destroy()
  end
  connections[station.unit_number] = nil
end

local function cleanup_legacy_station_grid_connections()
  for _, surface in pairs(game.surfaces) do
    for _, connector in pairs(surface.find_entities_filtered{name = STATION_GRID_CONNECTION_NAME}) do
      if connector.valid then connector.destroy() end
    end
  end
  storage.factoryx_station_grid_connections = {}
  storage.factoryx_station_power_pole_cache = {}
  storage.factoryx_station_power_model = "native-supply-area-v1"
end

local function ensure_native_station_power_model()
  if storage.factoryx_station_power_model ~= "native-supply-area-v1" then
    cleanup_legacy_station_grid_connections()
  end
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

function apply_factoryx_enemy_pressure_settings()
  if not biter_customer_mode_enabled() then return false end
  local map_settings = game.map_settings
  map_settings.pollution.enemy_attack_pollution_consumption_modifier =
    FACTORYX_ENEMY_ATTACK_POLLUTION_COST
  map_settings.unit_group.max_gathering_unit_groups =
    FACTORYX_MAX_GATHERING_ATTACK_GROUPS
  map_settings.unit_group.max_unit_group_size = FACTORYX_MAX_ATTACK_GROUP_SIZE
  map_settings.enemy_expansion.min_expansion_cooldown =
    FACTORYX_MIN_EXPANSION_COOLDOWN_TICKS
  map_settings.enemy_expansion.max_expansion_cooldown =
    FACTORYX_MAX_EXPANSION_COOLDOWN_TICKS
  map_settings.enemy_evolution.pollution_factor =
    FACTORYX_POLLUTION_EVOLUTION_FACTOR
  storage.factoryx_enemy_pressure_version = FACTORYX_ENEMY_PRESSURE_VERSION
  return true
end

function relieve_factoryx_enemy_pressure(max_evolution)
  apply_factoryx_enemy_pressure_settings()
  local enemy = game.forces.enemy
  if not enemy then return {dispersed_units = 0, adjusted_surfaces = 0} end
  local dispersed_units = 0
  local adjusted_surfaces = 0
  local evolution_cap = max_evolution or 0.70
  for _, surface in pairs(game.surfaces) do
    if enemy.get_evolution_factor(surface) > evolution_cap then
      enemy.set_evolution_factor(evolution_cap, surface)
      adjusted_surfaces = adjusted_surfaces + 1
    end
    for _, entity in pairs(surface.find_entities_filtered{force = enemy, type = "unit"}) do
      local commandable = entity.commandable
      local command = commandable and commandable.command
      if command and command.type ~= defines.command.wander then
        commandable.set_command{
          type = defines.command.wander,
          distraction = defines.distraction.none,
          radius = 16
        }
        dispersed_units = dispersed_units + 1
      end
    end
  end
  return {
    dispersed_units = dispersed_units,
    adjusted_surfaces = adjusted_surfaces,
    evolution_cap = evolution_cap
  }
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

function watch_customer_unit_destruction(entity)
  if not entity or not entity.valid or not entity.unit_number then return end
  storage.factoryx_customer_destruction_watches =
    storage.factoryx_customer_destruction_watches or {}
  if storage.factoryx_customer_destruction_watches[entity.unit_number] then return end
  storage.factoryx_customer_destruction_watches[entity.unit_number] =
    script.register_on_object_destroyed(entity)
end

function register_customer_unit(entity, settlement, market_force)
  if not entity or not entity.valid or entity.type ~= "unit" or not entity.unit_number then
    return false
  end
  local home_key, population = customer_settlement_population(settlement, market_force)
  if customer_unit_registry()[entity.unit_number] then
    watch_customer_unit_destruction(entity)
    customer_home_settlements()[entity.unit_number] =
      customer_home_settlements()[entity.unit_number] or {
        settlement_key = home_key,
        market_force_name = market_force.name
      }
    if not customer_population_members()[entity.unit_number] then
      population.physical = (population.physical or 0) + 1
      customer_population_members()[entity.unit_number] = home_key
    end
    if not customer_vehicle_owners()[entity.unit_number]
      and not buyer_reserved_by_unit()[entity.unit_number] then
      enqueue_customer_buyer(entity.unit_number, customer_home_settlements()[entity.unit_number])
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
  watch_customer_unit_destruction(entity)
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

function unregister_customer_unit_number(unit_number)
  if not unit_number then return nil end
  local registry = customer_unit_registry()
  local was_registered = registry[unit_number] ~= nil
  local home = customer_home_settlements()[unit_number]
  local member_key = customer_population_members()[unit_number]
  local ownership = remove_customer_vehicle_ownership(unit_number)
  local reserved_office = buyer_reserved_by_unit()[unit_number]

  clear_megapack_buyer_trip(unit_number, false)
  customer_charging_commutes()[unit_number] = nil
  customer_active_commutes()[unit_number] = nil
  TimingWheel.cancel(customer_commute_timing_wheel(), unit_number)
  TimingWheel.cancel(customer_road_rage_timing_wheel(), unit_number)
  customer_road_rage_states()[unit_number] = nil
  registry[unit_number] = nil
  if storage.factoryx_customer_destruction_watches then
    storage.factoryx_customer_destruction_watches[unit_number] = nil
  end
  customer_home_settlements()[unit_number] = nil
  customer_population_members()[unit_number] = nil
  buyer_reserved_by_unit()[unit_number] = nil

  if member_key then
    local population = customer_settlement_populations()[member_key]
    if population then population.physical = math.max(0, (population.physical or 0) - 1) end
  end
  if was_registered then
    storage.factoryx_customer_visible_count = math.max(0, customer_visible_count() - 1)
  end
  if reserved_office and clear_office_buyer_reservation then
    clear_office_buyer_reservation(reserved_office)
  end

  local market_force_name = ownership and ownership.market_force_name
    or home and home.market_force_name
  local market_force = market_force_name and game.forces[market_force_name]
  if market_force then mark_factoryx_market_dirty(market_force, "customer-removed") end
  return ownership
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
  local stale_units = {}
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    local settlement = home and settlements[home.settlement_key]
    local market_force = home and game.forces[home.market_force_name]
    if entity and entity.valid and settlement and market_force then
      local _, population = customer_settlement_population(settlement, market_force)
      population.physical = (population.physical or 0) + 1
      customer_population_members()[unit_number] = home.settlement_key
      watch_customer_unit_destruction(entity)
      restored = restored + 1
    else
      stale_units[#stale_units + 1] = unit_number
    end
  end
  for _, unit_number in pairs(stale_units) do unregister_customer_unit_number(unit_number) end

  for key, old in pairs(previous) do
    local population = customer_settlement_populations()[key]
    if population then
      population.virtual_unowned = old.virtual_unowned or 0
      population.virtual_reserved = old.virtual_reserved or 0
      population.virtual_by_vehicle = old.virtual_by_vehicle or {}
    end
  end
  storage.factoryx_customer_visible_count = restored
  rebuild_customer_vehicle_aggregates()
  rebuild_customer_buyer_queues()
  return restored, #stale_units
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
  return unregister_customer_unit_number(entity.unit_number)
end

function reconcile_customer_lifecycle_state()
  if storage.factoryx_customer_lifecycle_version == CUSTOMER_LIFECYCLE_VERSION then
    return {repaired = false, restored = customer_visible_count(), removed = 0}
  end
  local restored, removed = rebuild_customer_settlement_population_cache()
  reconcile_office_buyer_reservations()
  rebuild_customer_buyer_queues()
  for _, force in pairs(game.forces) do
    if player_market_force(force) then
      mark_factoryx_market_dirty(force, "customer-lifecycle-repaired")
    end
  end
  storage.factoryx_customer_lifecycle_version = CUSTOMER_LIFECYCLE_VERSION
  storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
  storage.factoryx_perf_counters.customer_lifecycle_repairs =
    (storage.factoryx_perf_counters.customer_lifecycle_repairs or 0) + 1
  storage.factoryx_perf_counters.stale_customer_units_removed =
    (storage.factoryx_perf_counters.stale_customer_units_removed or 0) + removed
  return {repaired = true, restored = restored, removed = removed}
end

function active_customer_vehicle_summary(force)
  return customer_vehicle_aggregate(force.name)
end

function settlement_vehicle_count(vehicle_summary, settlement)
  if not settlement or not settlement.valid then return 0 end
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
          "[Biter Motors] Market milestone reached: %d/%d qualifying EV sales. %s production is now available%s.",
          count,
          gate.threshold,
          gate.label,
          technology_ready and "" or " after its technology is researched"
        ))
        if gate_name == "premium" and technology_ready then
          force.print("[Biter Motors] Premium pilot production uses expensive commodity Batteries. Build 100 Premium EVs to unlock Gigafactory construction, then scale factory output to 250 vehicles to make Advanced Battery Chemistry research available.")
        end
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

function advanced_battery_chemistry_gate_announcements()
  storage.factoryx_advanced_battery_chemistry_gate_announcements =
    storage.factoryx_advanced_battery_chemistry_gate_announcements or {}
  return storage.factoryx_advanced_battery_chemistry_gate_announcements
end

function sync_advanced_battery_chemistry_gate(force, announce)
  if not force or not force.valid then return false end
  local technology = force.technologies and force.technologies[ADVANCED_BATTERY_CHEMISTRY_TECH_NAME]
  if not technology then return false end
  local produced = count_item_produced(force, PREMIUM_EV_NAME)
  local available = technology.researched or produced >= ADVANCED_BATTERY_CHEMISTRY_PRODUCTION_GATE
  technology.enabled = available
  for _, recipe_name in pairs(ADVANCED_BATTERY_CHEMISTRY_RECIPES) do
    local recipe = force.recipes and force.recipes[recipe_name]
    if recipe then recipe.enabled = technology.researched end
  end
  local announcements = advanced_battery_chemistry_gate_announcements()
  if available and not technology.researched and not announcements[force.name] then
    announcements[force.name] = true
    if announce ~= false then
      force.print(string.format(
        "[Biter Motors] Commodity battery supply has reached its scale limit after %d Premium EVs. Advanced Battery Chemistry research is now available: develop nickel-rich cells, lithium processing, and a scalable pack architecture.",
        ADVANCED_BATTERY_CHEMISTRY_PRODUCTION_GATE
      ))
    end
  end
  return available
end

function sync_gigafactory_production_gate(force, announce)
  if not force or not force.valid then return false end
  local produced = count_item_produced(force, PREMIUM_EV_NAME)
  local unlocked = researched(force, "x-premium-ev-program")
    and produced >= PREMIUM_PILOT_PRODUCTION_GATE
  for _, recipe_name in pairs({
    "x-gigafactory-module", "x-gigafactory-building"
  }) do
    local recipe = force.recipes and force.recipes[recipe_name]
    if recipe then recipe.enabled = unlocked end
  end
  local solar_batch_recipe = force.recipes and force.recipes[HIGH_DENSITY_SOLAR_BATCH_RECIPE]
  if solar_batch_recipe then
    solar_batch_recipe.enabled = unlocked and researched(force, "x-energy-products")
  end
  local announcements = gigafactory_gate_announcements()
  if unlocked and not announcements[force.name] then
    announcements[force.name] = true
    if announce ~= false then
      force.print(string.format(
        "[Biter Motors] Premium pilot proven: %d Premium EVs produced. Gigafactory construction is now available; use its scale to reach 250 vehicles and unlock Advanced Battery Chemistry.",
        PREMIUM_PILOT_PRODUCTION_GATE
      ))
    end
  end
  return unlocked
end

function foundry_power_gate_announcements()
  storage.factoryx_foundry_power_gate_announcements =
    storage.factoryx_foundry_power_gate_announcements or {}
  return storage.factoryx_foundry_power_gate_announcements
end

function foundry_power_gate_status(force)
  local solar_panels = count_item_produced(force, HIGH_DENSITY_SOLAR_ARRAY_NAME)
  local megapacks = count_item_produced(force, MEGAPACK_NAME)
  local energy_ready = researched(force, "x-energy-products") == true
  return {
    solar_panels = solar_panels,
    solar_target = FOUNDRY_POWER_GATE.solar_panels,
    megapacks = megapacks,
    megapack_target = FOUNDRY_POWER_GATE.megapacks,
    energy_ready = energy_ready,
    qualified = energy_ready
      and solar_panels >= FOUNDRY_POWER_GATE.solar_panels
      and megapacks >= FOUNDRY_POWER_GATE.megapacks
  }
end

function sync_foundry_power_gate(force, announce)
  if not force or not force.valid then return nil end
  local technology = force.technologies and force.technologies.foundry
  if not technology then return nil end
  local gate = foundry_power_gate_status(force)
  technology.enabled = technology.researched or gate.qualified
  local announcements = foundry_power_gate_announcements()
  if gate.qualified and not technology.researched and not announcements[force.name]
    and announce ~= false then
    announcements[force.name] = true
    force.print(string.format(
      "[Biter Motors] Industrial power qualified: %d High-density Solar Panels and %d Megapacks produced. Metallurgical Scaling research is now available; budget 2.5 MW per Foundry.",
      FOUNDRY_POWER_GATE.solar_panels,
      FOUNDRY_POWER_GATE.megapacks
    ))
  end
  return gate
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

function build_sales_office_market_topology(
  offices,
  settlements,
  capacity_by_settlement_key
)
  local specs = {}
  local specs_by_unit_number = {}
  for _, office in pairs(offices or {}) do
    if office.valid and office.unit_number then
      local spec = {
        key = office.unit_number,
        settlement_keys = {}
      }
      specs[#specs + 1] = spec
      specs_by_unit_number[office.unit_number] = spec
    end
  end

  for _, settlement in pairs(settlements or {}) do
    if settlement and settlement.valid then
      local key = settlement_key(settlement.surface, settlement)
      local population = customer_settlement_populations()[key]
      if population and (capacity_by_settlement_key[key] or 0) > 0 then
        for _, office in pairs(offices or {}) do
          if office.valid and office.surface == settlement.surface
            and within_radius(office, settlement, SALES_OFFICE_CUSTOMER_RADIUS) then
            specs_by_unit_number[office.unit_number].settlement_keys[key] = true
          end
        end
      end
    end
  end

  return SalesOfficeMarket.classify(specs)
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

function market_service_references_valid(service)
  if not service then return false end
  if not service.assignments
    or not service.assignment_by_settlement_key
    or not service.operational_keys
    or not service.prospects_by_settlement_key then
    return false
  end
  for _, settlement in pairs(service.candidate_settlements or {}) do
    if not settlement or not settlement.valid then return false end
  end
  for _, assignment in pairs(service.assignments or {}) do
    if not assignment.station or not assignment.station.valid then return false end
  end
  return true
end

customer_service_for_force = function(force, advance_mood)
  local generation = factoryx_market_generation()[force.index] or 0
  local cached = factoryx_market_cache()[force.index]
  if not advance_mood and cached and game.tick - cached.tick < CUSTOMER_MARKET_CACHE_TICKS
    and cached.generation == generation then
    if market_service_references_valid(cached.service) then
      storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
      storage.factoryx_perf_counters.market_snapshot_cache_hits =
        (storage.factoryx_perf_counters.market_snapshot_cache_hits or 0) + 1
      return cached.service
    end
    storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
    storage.factoryx_perf_counters.invalid_market_snapshot_rebuilds =
      (storage.factoryx_perf_counters.invalid_market_snapshot_rebuilds or 0) + 1
    mark_factoryx_market_dirty(force, "invalid-market-snapshot")
    generation = factoryx_market_generation()[force.index] or 0
  end
  local service = {
    assignments = {},
    assignment_by_settlement_key = {},
    assigned_capacity_by_settlement_key = {},
    requested_capacity_by_settlement_key = {},
    powered_capacity_by_settlement_key = {},
    capacity_by_settlement_key = {},
    prospects_by_settlement_key = {},
    operational_keys = {},
    served_keys = {},
    served_settlements = {},
    angry_keys = {},
    accessible_stall_capacity = 0,
    powered_stall_capacity = 0,
    supported_ev_capacity = 0,
    average_evs_per_stall = 0,
    stranded_evs = 0,
    underserved_settlements = 0,
    sales_office_market = {by_office = {}}
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

  local demand_by_settlement_key = {}
  for _, settlement in pairs(candidates) do
    local key = settlement_key(settlement.surface, settlement)
    local vehicle_count = settlement_vehicle_count(vehicle_summary, settlement)
    local population = customer_settlement_populations()[key]
    local customer_count = population and (
      (population.physical or 0) + (population.virtual_unowned or 0)
    ) or 0
    for _, count in pairs(population and population.virtual_by_vehicle or {}) do
      customer_count = customer_count + count
    end
    demand_by_settlement_key[key] = vehicle_count
    service.prospects_by_settlement_key[key] =
      math.max(0, customer_count - vehicle_count)
  end

  local station_specs = {}
  for _, station in pairs(stations) do
    local config = station_config(station)
    local station_candidates = {}
    for _, settlement in pairs(candidates) do
      if settlement.valid and settlement.surface == station.surface
        and within_radius(station, settlement, config.customer_radius) then
        local dx = settlement.position.x - station.position.x
        local dy = settlement.position.y - station.position.y
        station_candidates[#station_candidates + 1] = {
          key = settlement_key(station.surface, settlement),
          settlement = settlement,
          distance = dx * dx + dy * dy
        }
      end
    end
    table.sort(station_candidates, function(left, right)
      if left.distance ~= right.distance then return left.distance < right.distance end
      return left.key < right.key
    end)
    station_specs[#station_specs + 1] = {
      key = station.unit_number,
      station = station,
      stalls = config.stalls,
      evs_per_stall = config.evs_per_stall,
      candidates = station_candidates
    }
  end

  local allocation = ChargerAllocator.allocate(station_specs, demand_by_settlement_key)
  service.assignment_by_settlement_key = allocation.first_station_by_settlement_key
  service.assigned_capacity_by_settlement_key =
    allocation.assigned_capacity_by_settlement_key
  service.requested_capacity_by_settlement_key =
    allocation.requested_capacity_by_settlement_key

  for _, spec in pairs(station_specs) do
    local station = spec.station
    local config = station_config(station)
    local assignment = allocation.assignments[spec.key]
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
    if #spec.candidates > 0 then
      service.accessible_stall_capacity = service.accessible_stall_capacity + config.stalls
      service.powered_stall_capacity = service.powered_stall_capacity + assignment.powered_stalls
      service.supported_ev_capacity = service.supported_ev_capacity
        + assignment.powered_stalls * config.evs_per_stall
    end
    service.assignments[spec.key] = assignment
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
  service.sales_office_market = build_sales_office_market_topology(
    offices,
    candidates,
    service.capacity_by_settlement_key
  )
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

local function next_customer_charging_step(service, office)
  local assignments = {}
  for _, assignment in pairs(service.assignments or {}) do
    if assignment.station and assignment.station.valid then
      assignments[#assignments + 1] = assignment
    end
  end
  table.sort(assignments, function(left, right)
    if left.station.surface.index ~= right.station.surface.index then
      return left.station.surface.index < right.station.surface.index
    end
    return (left.station.unit_number or 0) < (right.station.unit_number or 0)
  end)

  local eligible_keys = {}
  local eligible_settlements = 0
  for _, settlement in pairs(service.candidate_settlements or {}) do
    if settlement.valid then
      local key = settlement_key(settlement.surface, settlement)
      local population = customer_settlement_populations()[key]
      local in_market = not office or (
        population
        and population.surface_index == office.surface.index
        and within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS)
      )
      if in_market and (service.capacity_by_settlement_key[key] or 0) > 0 then
        eligible_keys[key] = true
        eligible_settlements = eligible_settlements + 1
      end
    end
  end

  local best = nil
  local recorded_keys = {}
  for _, assignment in ipairs(assignments) do
    local station = assignment.station
    local config = station_config(station)
    if config then
      for _, settlement in ipairs(assignment.settlements or {}) do
        if settlement and settlement.valid then
          local key = settlement_key(settlement.surface, settlement)
          if eligible_keys[key]
            and not recorded_keys[key]
            and not assignment.requested_settlement_keys[key] then
            recorded_keys[key] = true
            local vehicle_count = settlement_vehicle_count(service.vehicle_summary, settlement)
            local requested_capacity = service.requested_capacity_by_settlement_key[key] or 0
            local candidate = {
              available = true,
              ev_owners_until = math.max(1, requested_capacity - vehicle_count + 1),
              ev_capacity_added = config.evs_per_stall,
              evs_per_stall = config.evs_per_stall,
              power_kw = station_stall_power_watts(station) / 1000,
              station_name = config.display_name,
              settlement_key = key
            }
            if not best
              or candidate.ev_owners_until < best.ev_owners_until
              or (candidate.ev_owners_until == best.ev_owners_until
                and (station.unit_number or 0) < (best.station_unit_number or math.huge)) then
              candidate.station_unit_number = station.unit_number
              best = candidate
            end
          end
        end
      end
    end
  end

  if best then
    return best
  end
  return {
    available = false,
    eligible_settlements = eligible_settlements,
    needs_charger = eligible_settlements > 0
  }
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
  if not player or not player.valid or not vehicle or not vehicle.valid
    or (not is_electric_vehicle(vehicle) and vehicle.name ~= ELECTRIC_SEMI_NAME) then return end
  destroy_ev_battery_popup(player.index)
  local energy
  local capacity
  if vehicle.name == ELECTRIC_SEMI_NAME then
    local battery = electric_semi_runtime().batteries[vehicle.unit_number]
    energy = battery and battery.energy or 0
    capacity = SEMI_BATTERY_CAPACITY
  else
    energy, capacity = vehicle_total_charge_energy(vehicle)
  end
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
      local pulse = 0.48 + (math.floor(game.tick / 10) % 2) * 0.14
      state.charge_icon.visible = charging
      state.charge_icon.x_scale = pulse
      state.charge_icon.y_scale = pulse
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

function draw_settlement_marker(entity, marker_type)
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
    color = marker_type == "blocked"
      and {r = 1, g = 0.2, b = 0.12, a = 1}
      or {r = 0.75, g = 1, b = 0.25, a = 1},
    scale = 1.1,
    alignment = "center",
    vertical_alignment = "middle"
  }
  markers[key] = {render_object = render_object, marker_type = marker_type}
end

function draw_customer_marker(entity)
  draw_settlement_marker(entity, "market")
end

function draw_blocked_settlement_marker(entity)
  draw_settlement_marker(entity, "blocked")
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

function player_driven_factoryx_ev_near(event, victim)
  local vehicle = event.cause
  if not vehicle or not vehicle.valid or not ELECTRIC_VEHICLE_BATTERIES[vehicle.name] then
    vehicle = event.source
  end
  if vehicle and vehicle.valid and ELECTRIC_VEHICLE_BATTERIES[vehicle.name] then
    for _, player in pairs(game.connected_players) do
      if player.vehicle == vehicle and player.character and player.character.valid then
        return vehicle, player.character, player
      end
    end
  end
  if vehicle and vehicle.valid and vehicle.unit_number then
    local state = ev_autopilot_runtime().active[vehicle.unit_number]
    local player = state and state.player_index and game.get_player(state.player_index)
    if state and state.mode == "summon" and player then
      return vehicle, vehicle, player
    end
  end

  -- Impact events from some vehicle prototypes identify the driver rather than the car.
  for _, player in pairs(game.connected_players) do
    local candidate = player.vehicle
    if candidate and candidate.valid and ELECTRIC_VEHICLE_BATTERIES[candidate.name]
      and candidate.surface == victim.surface then
      local dx = candidate.position.x - victim.position.x
      local dy = candidate.position.y - victim.position.y
      if dx * dx + dy * dy <= 16 and player.character and player.character.valid then
        return candidate, player.character, player
      end
    end
  end
  return nil, nil, nil
end

function pause_customer_commute_for_road_rage(unit_number, expires_tick)
  customer_active_commutes()[unit_number] = nil
  TimingWheel.cancel(customer_commute_timing_wheel(), unit_number)
  local commute = customer_charging_commutes()[unit_number]
  if commute then
    commute.phase = "road_rage"
    commute.station = nil
    commute.station_unit_number = nil
    commute.destination = nil
    commute.return_destination = nil
    commute.charge_progress = 0
    commute.retry_tick = nil
    commute.next_charge_tick = expires_tick + 60
  end
end

function set_customer_road_rage_status(entity)
  pcall(function()
    entity.custom_status = {
      diode = defines.entity_status_diode.red,
      label = "Road rage"
    }
  end)
end

function clear_customer_road_rage_status(entity)
  pcall(function() entity.custom_status = nil end)
end

function enrage_customer(entity, target, player, duration_ticks)
  if not entity or not entity.valid or not entity.unit_number or not entity.commandable
    or not customer_unit_registry()[entity.unit_number] or not target or not target.valid then
    return false, false
  end
  local unit_number = entity.unit_number
  local states = customer_road_rage_states()
  local state = states[unit_number]
  local first_anger = state == nil
  if first_anger then
    local active = 0
    for _ in pairs(states) do active = active + 1 end
    if active >= ROAD_RAGE.max_active then return false, false end
  end
  local expires_tick = game.tick + duration_ticks
  if state then expires_tick = math.max(expires_tick, state.expires_tick or 0) end
  states[unit_number] = {
    entity = entity,
    expires_tick = expires_tick,
    player_index = player and player.index or nil
  }
  entity.force = road_rage_force()
  set_customer_road_rage_status(entity)
  entity.commandable.set_command{
    type = defines.command.attack,
    target = target,
    distraction = defines.distraction.none
  }
  pause_customer_commute_for_road_rage(unit_number, expires_tick)
  TimingWheel.schedule(customer_road_rage_timing_wheel(), unit_number, expires_tick)
  return true, first_anger
end

function recruit_nearby_road_rage_customers(victim, target, player, radius, limit)
  local candidates = {}
  for _, entity in pairs(victim.surface.find_entities_filtered{
    type = "unit",
    force = CUSTOMER_FORCE_NAME,
    area = area_around(victim.position, radius)
  }) do
    if entity.valid and entity.unit_number ~= victim.unit_number
      and customer_unit_registry()[entity.unit_number]
      and not customer_road_rage_states()[entity.unit_number] then
      local dx = entity.position.x - victim.position.x
      local dy = entity.position.y - victim.position.y
      local distance = dx * dx + dy * dy
      if distance <= radius * radius then
        candidates[#candidates + 1] = {entity = entity, distance = distance}
      end
    end
  end
  table.sort(candidates, function(left, right)
    if left.distance == right.distance then
      return left.entity.unit_number < right.entity.unit_number
    end
    return left.distance < right.distance
  end)
  local recruited = 0
  for index = 1, math.min(limit, #candidates) do
    if enrage_customer(candidates[index].entity, target, player, ROAD_RAGE.nearby_duration_ticks) then
      recruited = recruited + 1
    end
  end
  return recruited
end

function trigger_customer_road_rage(event)
  local victim = event.entity
  if not victim or not victim.valid or victim.type ~= "unit" or not victim.unit_number
    or not customer_unit_registry()[victim.unit_number]
    or not event.damage_type or event.damage_type.name ~= "impact" then
    return false
  end
  local vehicle, target, player = player_driven_factoryx_ev_near(event, victim)
  if not vehicle then return false end
  local megatruck = vehicle.name == "x-cybertruck"
  local duration = megatruck and ROAD_RAGE.megatruck_duration_ticks or ROAD_RAGE.duration_ticks
  local enraged, first_anger = enrage_customer(victim, target, player, duration)
  if not enraged then return false end
  if first_anger then
    recruit_nearby_road_rage_customers(
      victim,
      target,
      player,
      megatruck and ROAD_RAGE.megatruck_response_radius or ROAD_RAGE.response_radius,
      megatruck and ROAD_RAGE.megatruck_nearby_limit or ROAD_RAGE.nearby_limit
    )
  end
  return true
end

function restore_customer_after_road_rage(unit_number)
  local states = customer_road_rage_states()
  local state = states[unit_number]
  if not state then return end
  local entity = customer_unit_registry()[unit_number]
  if state.expires_tick and state.expires_tick > game.tick then
    TimingWheel.schedule(customer_road_rage_timing_wheel(), unit_number, state.expires_tick)
    return
  end
  states[unit_number] = nil
  if not entity or not entity.valid then return end
  entity.force = customer_force()
  clear_customer_road_rage_status(entity)
  give_customer_wander_command(entity, true)
  local ownership = customer_vehicle_owners()[unit_number]
  if ownership then
    local commute = customer_charging_commutes()[unit_number]
    if commute then
      commute.phase = "roaming"
      commute.next_charge_tick = math.max(commute.next_charge_tick or 0, game.tick + 60)
    end
    enqueue_customer_commute(unit_number)
  end
  enqueue_customer_variant_migration(unit_number)
end

function process_customer_road_rage()
  for _, unit_number in pairs(TimingWheel.pop_due(
    customer_road_rage_timing_wheel(),
    game.tick,
    ROAD_RAGE.process_limit
  )) do
    restore_customer_after_road_rage(unit_number)
  end
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
      if megapack_buyer_reservations()[unit_number] then
        schedule_customer_commute(unit_number, game.tick + 60)
        goto continue_customer_commute
      end
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
    ::continue_customer_commute::
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
  watch_customer_unit_destruction(replacement)
  customer_home_settlements()[replacement.unit_number] = home
  customer_population_members()[replacement.unit_number] = customer_population_members()[old_unit_number]
  if home then
    local queue = buyer_queue_for(home.market_force_name, home.settlement_key)
    for index = queue.head, #queue.units do
      if queue.units[index] == old_unit_number then queue.units[index] = replacement.unit_number end
    end
    if queue.members[old_unit_number] then
      queue.members[old_unit_number] = nil
      queue.members[replacement.unit_number] = true
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
  if storage.factoryx_customer_destruction_watches then
    storage.factoryx_customer_destruction_watches[old_unit_number] = nil
  end
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
  watch_customer_unit_destruction(replacement)
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
  if storage.factoryx_customer_destruction_watches then
    storage.factoryx_customer_destruction_watches[old_unit_number] = nil
  end
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
      if customer_road_rage_states()[unit_number] then
        -- Restoration requeues migration; replacing now would orphan rage state.
      elseif megapack_buyer_reservations()[unit_number] then
        -- Restoration/completion requeues migration; replacing now would orphan trip state.
      elseif ownership then
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

function charger_hover_overlay_states()
  storage.factoryx_charger_hover_overlay_states = storage.factoryx_charger_hover_overlay_states or {
    by_player = {},
    by_station = {}
  }
  return storage.factoryx_charger_hover_overlay_states
end

function release_charger_hover_overlay(player_index)
  local states = charger_hover_overlay_states()
  local unit_number = states.by_player[player_index]
  if not unit_number then return end
  states.by_player[player_index] = nil

  local state = states.by_station[unit_number]
  if not state then return end
  state.viewers = math.max(0, (state.viewers or 1) - 1)
  if state.viewers > 0 then return end

  if state.entity and state.entity.valid and not state.was_disabled_by_script then
    pcall(function() state.entity.disabled_by_script = false end)
  end
  states.by_station[unit_number] = nil
end

function reset_charger_hover_overlays()
  local states = charger_hover_overlay_states()
  for _, state in pairs(states.by_station) do
    if state.entity and state.entity.valid and not state.was_disabled_by_script then
      pcall(function() state.entity.disabled_by_script = false end)
    end
  end
  storage.factoryx_charger_hover_overlay_states = {
    by_player = {},
    by_station = {}
  }
end

function sync_charger_hover_overlay(player)
  if not player or not player.valid then return end
  local selected = player.selected
  local unit_number = is_station(selected) and selected.unit_number or nil
  local states = charger_hover_overlay_states()
  if states.by_player[player.index] == unit_number then return end

  release_charger_hover_overlay(player.index)
  if not unit_number then return end

  local state = states.by_station[unit_number]
  if state then
    state.viewers = state.viewers + 1
    states.by_player[player.index] = unit_number
    return
  end

  local was_disabled_by_script = selected.disabled_by_script
  local suppressed = pcall(function() selected.disabled_by_script = true end)
  if suppressed then
    states.by_station[unit_number] = {
      entity = selected,
      viewers = 1,
      was_disabled_by_script = was_disabled_by_script
    }
    states.by_player[player.index] = unit_number
  end
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
      log("[Biter Motors] Charger placement overlay unavailable for player "
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
    -- MapViewSettings is write-only, so Biter Motors can only clear the overlay it enabled.
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
    if not megapack_buyer_reservations()[entity.unit_number]
      and (not commute or (commute.phase ~= "to_charger" and commute.phase ~= "charging"
        and commute.phase ~= "returning_home")) then
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

function customer_settlement_map_tag_states()
  storage.factoryx_customer_settlement_map_tag_states =
    storage.factoryx_customer_settlement_map_tag_states or {}
  return storage.factoryx_customer_settlement_map_tag_states
end

function update_customer_settlement_map_tags(force, disrupted)
  local states_by_force = customer_settlement_map_tag_states()
  states_by_force[force.index] = states_by_force[force.index] or {}
  local states = states_by_force[force.index]

  for key, state in pairs(states) do
    if not disrupted[key] then
      local tag = type(state) == "table" and state.tag or state
      if tag and tag.valid then tag.destroy() end
      states[key] = nil
    end
  end

  for key, disruption in pairs(disrupted) do
    local text
    if disruption.kind == "capacity" then
      text = string.format("%d EVs underserved - add charger", disruption.missing)
    elseif disruption.kind == "power" then
      text = string.format("%d EVs underserved - restore power", disruption.missing)
    else
      text = string.format("%d EVs underserved - charger + power", disruption.missing)
    end

    local state = states[key]
    local tag = type(state) == "table" and state.tag or state
    local changed = not tag or not tag.valid
      or type(state) ~= "table"
      or state.kind ~= disruption.kind
      or state.missing ~= disruption.missing
    if changed then
      if tag and tag.valid then tag.destroy() end
      tag = force.add_chart_tag(disruption.settlement.surface, {
        position = disruption.settlement.position,
        icon = {type = "virtual", name = "signal-red"},
        text = text
      })
      states[key] = tag and {
        tag = tag,
        kind = disruption.kind,
        missing = disruption.missing
      } or nil
    end
  end
end

function update_customer_settlement_alerts(force, service)
  local vehicle_summary = active_customer_vehicle_summary(force)
  local disrupted = {}
  for _, settlement in pairs(service.candidate_settlements or {}) do
    if settlement.valid then
      local key = settlement_key(settlement.surface, settlement)
      local vehicle_count = vehicle_summary.by_settlement[key] or 0
      local assigned_capacity = service.assigned_capacity_by_settlement_key[key] or 0
      local powered_capacity = service.powered_capacity_by_settlement_key[key] or 0
      if vehicle_count > powered_capacity then
        local capacity_missing = math.max(0, vehicle_count - assigned_capacity)
        local power_missing = math.max(
          0,
          math.min(vehicle_count, assigned_capacity) - powered_capacity
        )
        disrupted[key] = {
          settlement = settlement,
          kind = capacity_missing > 0
            and (power_missing > 0 and "mixed" or "capacity") or "power",
          missing = vehicle_count - powered_capacity,
          capacity_missing = capacity_missing,
          power_missing = power_missing
        }
      end
    end
  end

  update_customer_settlement_map_tags(force, disrupted)

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
    for key, disruption in pairs(disrupted) do
      local settlement = disruption.settlement
      -- Custom alerts expire. Refresh persistent disruptions each service sync.
      if player_states[key] then
        player.remove_alert{entity = settlement, type = defines.alert_type.custom}
      end
      if disruption.kind == "capacity" then
        player.add_custom_alert(
          settlement,
          {type = "item", name = "x-ev-charging-station"},
          {
            "",
            "Customer settlement needs charging capacity for ",
            disruption.missing,
            " more EVs. Place or upgrade an EV charger near this settlement."
          },
          true
        )
      elseif disruption.kind == "power" then
        player.add_custom_alert(
          settlement,
          {type = "item", name = "accumulator"},
          {
            "",
            disruption.missing,
            " EVs lack powered charging service. Restore grid power."
          },
          true
        )
      else
        player.add_custom_alert(
          settlement,
          {type = "virtual", name = "signal-red"},
          {
            "",
            "Customer settlement is short charging capacity for ",
            disruption.capacity_missing,
            " EVs and powered service for ",
            disruption.power_missing,
            " more. Add or upgrade a charger and restore grid power."
          },
          true
        )
      end
      player_states[key] = settlement
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
              if settlement.valid then
                local dx = settlement.position.x - entity.position.x
                local dy = settlement.position.y - entity.position.y
                local distance = dx * dx + dy * dy
                if not nearest_distance or distance < nearest_distance then
                  nearest = settlement
                  nearest_distance = distance
                end
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
  local blocked_settlements = {}
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
      for _, settlement in pairs(service.candidate_settlements or {}) do
        if settlement.valid then
          local key = settlement_key(settlement.surface, settlement)
          if not service.served_keys[key] then
            blocked_settlements[key] = settlement
          end
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
  for _, settlement in pairs(blocked_settlements) do
    if settlement.valid then draw_blocked_settlement_marker(settlement) end
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
            draw_blocked_settlement_marker(settlement)
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
  if not is_station(station) then return 0 end
  service = service or customer_service_for_force(station.force)
  local assignment = service.assignments[station.unit_number]
  local stale_assignment = false
  local count = 0
  for _, settlement in pairs(assignment and assignment.settlements or {}) do
    if settlement and settlement.valid then
      local key = settlement_key(settlement.surface, settlement)
      if service.operational_keys[key]
        and service.assignment_by_settlement_key[key] == station then
        count = count + (service.prospects_by_settlement_key[key] or 0)
      end
    else
      stale_assignment = true
    end
  end
  if stale_assignment then
    mark_factoryx_market_dirty(station.force, "invalid-assigned-settlement")
  end
  return count
end

function station_reservation_rate_per_minute(station, service)
  return waiting_market_buyers_at_station(station, service)
    / PROSPECT_RESERVATION_RETRY_MINUTES
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
  local waiting_prospects = waiting_market_buyers_at_station(station, service)
  local reservation_rate = station_reservation_rate_per_minute(station, service)
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
    if settlement and settlement.valid then
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
  titlebar.add{type = "label", caption = "Biter Motors " .. config.display_name, style = "frame_title"}
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
    {sprite = "item/x-premium-ev", label = "Prospects", value = tostring(waiting_prospects), tooltip = string.format("Each unsold prospect files one EV Reservation every %d minutes until purchasing.", PROSPECT_RESERVATION_RETRY_MINUTES)},
    {sprite = "item/x-ev-charging-station", label = "Underserved", value = tostring(underserved_here), color = underserved_here > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good},
    {sprite = "item/x-prototype-roadster", label = "Commutes", value = string.format("%d in / %d charging", commute_counts.en_route, commute_counts.charging)},
    {sprite = "item/accumulator", label = "Power", value = string.format("%.0f / %.0f kW", power_draw_kw, config.stalls * researched_power_per_stall_kw)},
    {sprite = "item/x-ev-reservation", label = "Reservations", value = string.format("%.1f / min", reservation_rate)},
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
  local reservation_rate = powered_stations
  local customer_prospects = 0
  local reservation_prospects = 0
  local active_customer_stalls = powered_stations
  local service = nil

  if customer_mode then
    covered_settlements = count_covered_biter_settlements(force)
    active_customer_stalls = count_active_customer_stalls(force)
    reservation_rate = 0
    service = customer_service_for_force(force)
    for _, prospects in pairs(service.prospects_by_settlement_key or {}) do
      customer_prospects = customer_prospects + prospects
    end
    for _, surface in pairs(game.surfaces) do
      for _, station in pairs(find_stations(surface, force)) do
        local prospects = waiting_market_buyers_at_station(station, service)
        reservation_prospects = reservation_prospects + prospects
        reservation_rate = reservation_rate
          + prospects / PROSPECT_RESERVATION_RETRY_MINUTES
      end
    end
  end

  local requested_customer_stalls = 0
  local powered_customer_stalls = 0
  local charging_power_demand_kw = 0
  local charging_power_served_kw = 0
  if service then
    for _, assignment in pairs(service.assignments or {}) do
      local power_per_stall_kw = station_stall_power_watts(assignment.station) / 1000
      local requested = assignment.requested_stalls or 0
      local powered = assignment.powered_stalls or 0
      requested_customer_stalls = requested_customer_stalls + requested
      powered_customer_stalls = powered_customer_stalls + powered
      charging_power_demand_kw = charging_power_demand_kw + requested * power_per_stall_kw
      charging_power_served_kw = charging_power_served_kw + powered * power_per_stall_kw
    end
  end

  local next_charging_step = service and next_customer_charging_step(service) or nil

  local _, growth = customer_growth_summary(force)
  return {
    biter_customer_mode = customer_mode,
    powered_stations = powered_stations,
    covered_biter_settlements = covered_settlements,
    active_customer_stalls = active_customer_stalls,
    charging_stall_capacity = charging_stall_capacity,
    requested_customer_stalls = requested_customer_stalls,
    powered_customer_stalls = powered_customer_stalls,
    charging_power_demand_kw = charging_power_demand_kw,
    charging_power_served_kw = charging_power_served_kw,
    next_charging_step = next_charging_step,
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
    customer_prospects = customer_prospects,
    reservation_prospects = reservation_prospects,
    demand_units = reservation_rate,
    reservations_per_minute = reservation_rate
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

function unlock_battery_material_recovery(force)
  unlock_vehicle_recycling(force)
  local technology = force.technologies and force.technologies[BATTERY_RECOVERY_TECH_NAME]
  if not technology or technology.enabled or technology.researched then return false end
  technology.enabled = true
  return true
end

function insert_battery_retirement_scrap(inventory, force, wrecks)
  if not inventory or wrecks <= 0 then return 0 end
  local sales = sold_customer_evs(force)
  local high_weight = (sales[PREMIUM_EV_NAME] or 0) * 8 + (sales["x-cybertruck"] or 0) * 4
  local lfp_weight = (sales["x-mass-market-ev"] or 0) * 4 + (sales["x-cybertruck"] or 0) * 8
  local total_weight = high_weight + lfp_weight
  if total_weight <= 0 then return 0 end
  local inserted = 0
  for _ = 1, wrecks do
    local high_energy = math.random() * total_weight < high_weight
    local item_name = high_energy and DAMAGED_HIGH_ENERGY_PACK_NAME or DAMAGED_LFP_PACK_NAME
    local count = high_energy and 8 or 4
    inserted = inserted + inventory.insert{name = item_name, count = count}
  end
  if inserted > 0 then unlock_battery_material_recovery(force) end
  return inserted
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
    insert_battery_retirement_scrap(inventory, station.force, inserted)
  end
  return inserted
end

local function reservation_print_progress()
  storage.factoryx_reservation_print_progress = storage.factoryx_reservation_print_progress or {}
  return storage.factoryx_reservation_print_progress
end

local function generate_station_reservations(force, service)
  if not researched(force, "x-ev-charging-network") and not first_prototype_sale_unlocked(force) then
    return
  end

  service = service or customer_service_for_force(force)
  local progress = reservation_print_progress()
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface, force)) do
      local reservation_rate = station_reservation_rate_per_minute(station, service)
      if reservation_rate > 0 and station_has_grid_access(station) then
        local key = station.unit_number
        local accumulated = (progress[key] or 0) + reservation_rate
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
  if inventory and inventory.valid and #inventory >= 43 then
    for slot = 1, 40 do pcall(function() inventory.set_filter(slot, ROBOTAXI_ITEM_NAME) end) end
    pcall(function() inventory.set_filter(41, DOLLAR_NAME) end)
    pcall(function() inventory.set_filter(42, WRECKED_EV_NAME) end)
    pcall(function() inventory.set_filter(43, DAMAGED_LFP_PACK_NAME) end)
  end
  return inventory, inventory
end

function robotaxi_safety_states()
  storage.factoryx_robotaxi_safety = storage.factoryx_robotaxi_safety or {}
  return storage.factoryx_robotaxi_safety
end

function robotaxi_safety_snapshot(force)
  local state = robotaxi_safety_states()[force.index] or {completed_rides = 0}
  robotaxi_safety_states()[force.index] = state
  local learning = math.log(1 + state.completed_rides / ROBOTAXI_SAFETY_RIDES_SCALE) / math.log(10)
  local collision_multiplier = 1 / (1 + learning)
  local retirement_multiplier = ROBOTAXI_ROUTINE_WEAR_FLOOR
    + (1 - ROBOTAXI_ROUTINE_WEAR_FLOOR) * collision_multiplier
  return {
    completed_rides = state.completed_rides,
    collision_multiplier = collision_multiplier,
    retirement_multiplier = retirement_multiplier,
    risk_reduction = 1 - retirement_multiplier,
    expected_vehicle_hours = ROBOTAXI_ATTRITION_VEHICLE_HOURS / retirement_multiplier
  }
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

function robotaxi_dollar_output_blocked(inventory)
  local slot = inventory and inventory[41]
  if not slot then return true end
  if not slot.valid_for_read then return false end
  return slot.name ~= DOLLAR_NAME
    or (slot.quality and slot.quality.name ~= "normal")
    or slot.count >= slot.prototype.stack_size
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
  local safety = robotaxi_safety_snapshot(center.force)
  return {
    stored = metrics.fleet,
    allocated = metrics.allocated,
    customers = customers,
    served = metrics.served,
    power_factor = power_factor,
    revenue_per_minute = metrics.revenue_per_minute,
    output_dollars = output and output.get_item_count(DOLLAR_NAME) or 0,
    output_blocked = robotaxi_dollar_output_blocked(output),
    revenue_progress = state.revenue or 0,
    attrition_progress = state.attrition or 0,
    lifetime_dollars = state.dollars or 0,
    vehicles_retired = state.vehicles_retired or 0,
    completed_rides = safety.completed_rides,
    safety_risk_reduction = safety.risk_reduction,
    expected_vehicle_hours = safety.expected_vehicle_hours
  }
end

function process_robotaxi_service_centers()
  local centers = registered_factoryx_entities("robotaxi_centers")
  if #centers == 0 and next(robotaxi_service_states()) == nil
    and next(robotaxi_service_power_entities()) == nil then
    return
  end
  local seen = {}
  local active_power_units = {}
  local allocations_by_force = {}
  local safety_by_force = {}
  local completed_rides_by_force = {}
  for _, center in pairs(centers) do
      if center.valid and center.unit_number then
        allocations_by_force[center.force.index] = allocations_by_force[center.force.index]
          or robotaxi_customer_allocations(center.force)
        local customer_allocations = allocations_by_force[center.force.index]
        safety_by_force[center.force.index] = safety_by_force[center.force.index]
          or robotaxi_safety_snapshot(center.force)
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
          completed_rides_by_force[center.force.index] = (completed_rides_by_force[center.force.index] or 0)
            + snapshot.allocated * snapshot.power_factor / 60
          state.revenue = state.revenue + snapshot.revenue_per_minute / 60
          state.attrition = state.attrition
            + snapshot.allocated * snapshot.power_factor
              * safety_by_force[center.force.index].retirement_multiplier
              / (ROBOTAXI_ATTRITION_VEHICLE_HOURS * 3600)
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
            local wreck_capacity = math.min(
              output.get_insertable_count(WRECKED_EV_NAME),
              math.floor(output.get_insertable_count(DAMAGED_LFP_PACK_NAME) / 16)
            )
            local removed = input.remove{
              name = ROBOTAXI_ITEM_NAME,
              count = math.min(retirements, wreck_capacity)
            }
            state.attrition = state.attrition - removed
            state.vehicles_retired = state.vehicles_retired + removed
            if removed > 0 then
              local wrecks = output.insert{name = WRECKED_EV_NAME, count = removed}
              local damaged_packs = output.insert{name = DAMAGED_LFP_PACK_NAME, count = removed * 16}
              if wrecks > 0 then
                local statistics = center.force.get_item_production_statistics(center.surface)
                statistics.set_output_count(WRECKED_EV_NAME, statistics.get_output_count(WRECKED_EV_NAME) + wrecks)
                unlock_vehicle_recycling(center.force)
              end
              if damaged_packs > 0 then unlock_battery_material_recovery(center.force) end
            end
          end
        end
      end
  end
  for force_index, rides in pairs(completed_rides_by_force) do
    local state = robotaxi_safety_states()[force_index] or {completed_rides = 0}
    state.completed_rides = state.completed_rides + rides
    robotaxi_safety_states()[force_index] = state
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
    force.print("[Biter Motors] First biter customer charging site covered. Prototype Roadsters are now available for Sell hopes and dreams.")
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

  force.print("[Biter Motors] First Dollars earned. Next: research EV Production Line to unlock EV components, Premium EV pilot production, and Sell premium product.")
end

local function announce_ev_production_line_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[Biter Motors] EV Production Line researched. Premium EV tooling is ready after 50 completed Prototype Roadster sales. Build 100 commodity-battery Premium EVs to unlock Gigafactory construction.")
end

local function announce_mass_market_production_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[Biter Motors] Mass-market EV Production researched. Gigafactory V2 tooling is ready. Mass-market EVs require 250 Premium EV sales; Megatruck Engineering requires Tank technology and 2,000 Mass-market EV sales.")
end

local function announce_ev_charging_network_researched(force)
  if not force or not force.valid then
    return
  end

  force.print("[Biter Motors] EV Charging Network researched. Craft a separate V2 charger from 1 V1 charger, 2 Substations, and 20 Processing Units, then place it. V2 has 8 stalls, 96-tile customer range, and up to 1.2 MW demand.")
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

  force.print("[Biter Motors] Premium EV sales are working. Build 100 pilot vehicles to unlock the Gigafactory, then use factory scale to reach 250 vehicles and unlock Advanced Battery Chemistry.")
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

  force.print("[Biter Motors] Mass-market EV sales are online. Build High-density Solar Panels and Megapacks through Energy Products, then research Terrestrial AI.")
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
  force.print("[Biter Motors] Robotaxi service is producing recurring profit. Next: launch vanilla cargo rockets and establish orbital compute over Nauvis.")
end

local RESEARCH_COMPLETION_MESSAGES = {
  ["x-sales-office"] = "[Biter Motors] Sales Office researched. Place one within 128 tiles of enemy spawners, then place a grid-connected EV Charging Station within 64 tiles of the converted customer settlement.",
  ["x-advanced-battery-chemistry"] = "[Biter Motors] Advanced Battery Chemistry researched. Refine Nickel Ore and Lithium Brine. Make four-cell batches in Chemical Plants or five-cell batches in a Gigafactory; both consume the cobalt from dirty nickel refining. Four cells, four Steel Plates, and two Advanced Circuits make one High-energy Battery Pack.",
  ["x-energy-products"] = "[Biter Motors] Energy Products researched. Upgrade conventional solar fields with High-density Solar Panels and build Megapacks for mass-market power demand.",
  ["x-terrestrial-ai"] = "[Biter Motors] Terrestrial AI researched. Build 4 Datacenter Racks, then construct an 8 MW Terrestrial Datacenter. Supply 20 Dollars per cycle to produce 20 AI Tokens every 30 seconds; stockpile 1,000 for Autonomous Logistics.",
  ["x-autonomous-logistics"] = "[Biter Motors] Autonomous Logistics researched. The toolbar now has Navigate and Summon controls for Premium, Mass-market, Megatruck, and Robotaxi EVs. Robotaxi production still requires 5,000 total consumer EV sales.",
  ["x-orbital-compute"] = "[Biter Motors] Orbital Compute researched. Build Orbital Compute Arrays on space platforms and return their high-volume AI Tokens to the planet.",
  ["x-planetary-energy-grid"] = "[Biter Motors] Planetary Energy Grid researched. Build the 1 TW controller, scale cumulative AI Token production to one billion, then complete the final AGI Training Run."
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
  ["x-gigafactory-building"] = "[Biter Motors] First Gigafactory online. Its 4x crafting speed and 50% built-in productivity make every two Premium EV input sets produce three vehicles. Run the commodity-cell recipe to reach 250 Premium EVs, then switch to cell-scale packs after Advanced Battery Chemistry.",
  ["x-gigafactory-v2"] = "[Biter Motors] First Gigafactory V2 online. It runs twice as fast with 150% built-in productivity while drawing 30 MW. Mass-market production appears after 250 Premium EV sales.",
  [HIGH_DENSITY_SOLAR_ARRAY_NAME] = "[Biter Motors] First High-density Solar Panel online: 300 kW peak output. Upgrade existing panels before chargers, Gigafactories, and datacenters compete for power.",
  [MEGAPACK_NAME] = "[Biter Motors] First Megapack online: 100 MJ storage with 5 MW charge and discharge. Pair it with daytime generation to stabilize Biter Motors loads.",
  [TERRESTRIAL_DATACENTER_NAME] = "[Biter Motors] First Terrestrial Datacenter online. Supply Dollars and select AI Token production: each 30-second cycle consumes 20 Dollars, draws 8 MW, and produces 20 AI Tokens.",
  [ROBOTAXI_SERVICE_CENTER_NAME] = "[Biter Motors] Robotaxi Service Center online. Load up to 200 Robotaxis; its built-in V4 fleet charging draws 10 MW while Operate Robotaxis converts nearby customer service into recurring profit."
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
    and count_item_produced(force, PREMIUM_EV_NAME) >= PREMIUM_PILOT_PRODUCTION_GATE then
    for _, recipe_name in pairs({"x-gigafactory-module", "x-gigafactory-building"}) do
      local recipe = force.recipes and force.recipes[recipe_name]
      if recipe and not recipe.enabled then table.insert(disabled, recipe_name) end
    end
    if researched(force, "x-energy-products") then
      local solar_batch_recipe = force.recipes and force.recipes[HIGH_DENSITY_SOLAR_BATCH_RECIPE]
      if solar_batch_recipe and not solar_batch_recipe.enabled then
        table.insert(disabled, HIGH_DENSITY_SOLAR_BATCH_RECIPE)
      end
    end
  end
  table.sort(disabled)
  return {ok = #disabled == 0, disabled_recipes = disabled}
end

local function sync_force_unlocks(force)
  repair_researched_factoryx_unlocks(force)
  local logistic_system = force.technologies and force.technologies[LOGISTIC_SYSTEM_TECH_NAME]
  if logistic_system and not logistic_system.researched then
    logistic_system.enabled = true
  end
  sync_advanced_battery_chemistry_gate(force, false)
  sync_gigafactory_production_gate(force, false)
  sync_foundry_power_gate(force, false)
  sync_agi_training_unlock(force, false)
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

  force.print("[Biter Motors] AGI achieved. The trained model is online, and humanity now has a new tool for deciding what comes next.")
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

function reconcile_office_buyer_reservations()
  local populations = customer_settlement_populations()
  for _, population in pairs(populations) do
    population.virtual_reserved = 0
  end

  local offices = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
    if office.valid and office.unit_number then
      offices[office.unit_number] = office
    end
  end

  local reservations = office_buyer_reservations()
  local physical_reservations = {}
  local virtual_reservations = {}
  local cleared = 0
  for office_unit_number, reservation in pairs(reservations) do
    local office = offices[office_unit_number]
    local recipe = office and office.get_recipe()
    local sale = recipe and CUSTOMER_EV_SALE_RECIPES[recipe.name]
    local valid = office and recipe and sale and type(reservation.buyers) == "table"
      and reservation.recipe_name == recipe.name
      and #reservation.buyers == sale.vehicles
    local pending_physical = {}
    local pending_virtual = {}
    if valid then
      for _, buyer in pairs(reservation.buyers) do
        if type(buyer) == "table" and buyer.virtual then
          local population = populations[buyer.settlement_key]
          local already_reserved = (virtual_reservations[buyer.settlement_key] or 0)
            + (pending_virtual[buyer.settlement_key] or 0)
          if not population or population.market_force_name ~= office.force.name
            or already_reserved >= (population.virtual_unowned or 0) then
            valid = false
            break
          end
          pending_virtual[buyer.settlement_key] =
            (pending_virtual[buyer.settlement_key] or 0) + 1
        else
          local entity = customer_unit_registry()[buyer]
          local home = customer_home_settlements()[buyer]
          if not entity or not entity.valid or entity.force.name ~= CUSTOMER_FORCE_NAME
            or not home or home.market_force_name ~= office.force.name
            or customer_vehicle_owners()[buyer]
            or physical_reservations[buyer] or pending_physical[buyer] then
            valid = false
            break
          end
          pending_physical[buyer] = office_unit_number
        end
      end
    end
    if valid then
      for unit_number, reserved_office in pairs(pending_physical) do
        physical_reservations[unit_number] = reserved_office
      end
      for settlement_key_value, count in pairs(pending_virtual) do
        virtual_reservations[settlement_key_value] =
          (virtual_reservations[settlement_key_value] or 0) + count
      end
    else
      reservations[office_unit_number] = nil
      cleared = cleared + 1
    end
  end

  storage.factoryx_buyer_reserved_by_unit = physical_reservations
  for settlement_key_value, count in pairs(virtual_reservations) do
    local population = populations[settlement_key_value]
    if population then population.virtual_reserved = count end
  end
  if cleared > 0 then rebuild_customer_buyer_queues() end
  return cleared
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

function customer_population_size(population)
  if not population then return 0 end
  local total = (population.physical or 0) + (population.virtual_unowned or 0)
  for _, count in pairs(population.virtual_by_vehicle or {}) do
    total = total + count
  end
  return math.max(0, math.floor(total))
end

function ensure_megapack_adoption_state(key, population)
  local total = customer_population_size(population)
  if total <= 0 then return nil end
  local states = megapack_adoption_states()
  local state = states[key]
  if not state then
    state = {
      eligible = math.max(1, math.ceil(total * MEGAPACK_INITIAL_ADOPTION_FRACTION)),
      installed = 0,
      reserved = 0
    }
    states[key] = state
  end
  state.installed = math.min(total, math.max(0, state.installed or 0))
  state.reserved = math.min(
    math.max(0, total - state.installed),
    math.max(0, state.reserved or 0)
  )
  state.eligible = math.min(
    total,
    math.max(state.installed + state.reserved, state.eligible or 0)
  )
  return state
end

function population_in_megapack_office_market(office, population)
  return population and population.market_force_name == office.force.name
    and population.surface_index == office.surface.index
    and within_radius(office, {position = population.position}, MEGAPACK_SALES_RADIUS)
end

function destroy_megapack_installation_rendering(key)
  local rendering_state = megapack_installation_renderings()[key]
  if not rendering_state then return end
  for _, object in pairs(rendering_state) do
    if object and object.valid then object.destroy() end
  end
  megapack_installation_renderings()[key] = nil
end

function refresh_megapack_installation_rendering(key)
  destroy_megapack_installation_rendering(key)
  local adoption = megapack_adoption_states()[key]
  local population = customer_settlement_populations()[key]
  if not adoption or (adoption.installed or 0) <= 0 or not population then return end
  local surface = game.surfaces[population.surface_index]
  if not surface then return end
  local position = {
    x = population.position.x + 3.25,
    y = population.position.y + 1.75
  }
  megapack_installation_renderings()[key] = {
    rendering.draw_sprite{
      sprite = "item/" .. MEGAPACK_NAME,
      surface = surface,
      target = position,
      x_scale = 0.55,
      y_scale = 0.55,
      render_layer = "air-object"
    },
    rendering.draw_text{
      surface = surface,
      target = {x = position.x, y = position.y + 0.75},
      text = tostring(adoption.installed),
      color = {r = 0.62, g = 0.94, b = 0.64, a = 1},
      scale = 0.75,
      alignment = "center",
      vertical_alignment = "top"
    }
  }
end

function sync_megapack_adoption_waves()
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
    if office.valid and current_recipe_name(office) == MEGAPACK_SALE_RECIPE then
      for key, population in pairs(customer_settlement_populations()) do
        if population_in_megapack_office_market(office, population) then
          ensure_megapack_adoption_state(key, population)
        end
      end
    end
  end
  for key, state in pairs(megapack_adoption_states()) do
    local population = customer_settlement_populations()[key]
    if not population then
      destroy_megapack_installation_rendering(key)
      megapack_adoption_states()[key] = nil
    else
      state = ensure_megapack_adoption_state(key, population)
      local total = customer_population_size(population)
      if state and (state.installed or 0) > 0 and state.eligible < total then
        state.next_referral_tick = state.next_referral_tick
          or (game.tick + MEGAPACK_REFERRAL_WAVE_TICKS)
        if game.tick >= state.next_referral_tick then
          local remaining = total - state.eligible
          state.eligible = math.min(
            total,
            state.eligible + math.max(1, math.ceil(remaining * MEGAPACK_REFERRAL_FRACTION))
          )
          state.next_referral_tick = game.tick + MEGAPACK_REFERRAL_WAVE_TICKS
        end
      elseif state then
        state.next_referral_tick = nil
      end
    end
  end
end

function megapack_office_status(office)
  local status = {
    settlements = 0,
    population = 0,
    eligible = 0,
    waiting = 0,
    reserved = 0,
    installed = 0,
    to_office = 0,
    waiting_product = 0,
    returning_home = 0,
    next_referral_tick = nil
  }
  if not office or not office.valid then return status end
  for key, population in pairs(customer_settlement_populations()) do
    if population_in_megapack_office_market(office, population) then
      local state = ensure_megapack_adoption_state(key, population)
      if state then
        status.settlements = status.settlements + 1
        status.population = status.population + customer_population_size(population)
        status.eligible = status.eligible + state.eligible
        status.reserved = status.reserved + state.reserved
        status.installed = status.installed + state.installed
        status.waiting = status.waiting
          + math.max(0, state.eligible - state.installed - state.reserved)
        if state.next_referral_tick
          and (not status.next_referral_tick
            or state.next_referral_tick < status.next_referral_tick) then
          status.next_referral_tick = state.next_referral_tick
        end
      end
    end
  end
  for _, trip in pairs(megapack_buyer_trips()) do
    if trip.force_name == office.force.name and trip.office_unit_number == office.unit_number then
      if trip.phase == "to_office" then status.to_office = status.to_office + 1
      elseif trip.phase == "waiting_product" then
        status.waiting_product = status.waiting_product + 1
      elseif trip.phase == "returning_home" then
        status.returning_home = status.returning_home + 1
      end
    end
  end
  status.adoption_percent = status.population > 0
    and math.floor(status.installed * 1000 / status.population + 0.5) / 10 or 0
  return status
end

function megapack_adoption_summary(force)
  local summary = {
    settlements = 0,
    population = 0,
    eligible = 0,
    waiting = 0,
    reserved = 0,
    installed = 0,
    in_transit = 0,
    to_office = 0,
    waiting_product = 0,
    returning_home = 0
  }
  if not force then return summary end
  for key, state in pairs(megapack_adoption_states()) do
    local population = customer_settlement_populations()[key]
    if population and population.market_force_name == force.name then
      state = ensure_megapack_adoption_state(key, population)
      summary.settlements = summary.settlements + 1
      summary.population = summary.population + customer_population_size(population)
      summary.eligible = summary.eligible + state.eligible
      summary.reserved = summary.reserved + state.reserved
      summary.installed = summary.installed + state.installed
      summary.waiting = summary.waiting
        + math.max(0, state.eligible - state.installed - state.reserved)
    end
  end
  for _, trip in pairs(megapack_buyer_trips()) do
    if trip.force_name == force.name then
      if trip.phase == "to_office" then
        summary.to_office = summary.to_office + 1
        summary.in_transit = summary.in_transit + 1
      elseif trip.phase == "waiting_product" then
        summary.waiting_product = summary.waiting_product + 1
      elseif trip.phase == "returning_home" then
        summary.returning_home = summary.returning_home + 1
        summary.in_transit = summary.in_transit + 1
      end
    end
  end
  summary.adoption_percent = summary.population > 0
    and math.floor(summary.installed * 1000 / summary.population + 0.5) / 10 or 0
  return summary
end

function clear_megapack_buyer_trip(unit_number, resume_wandering)
  local trips = megapack_buyer_trips()
  local trip = trips[unit_number]
  if not trip then return false end
  if trip.carry_icon and trip.carry_icon.valid then trip.carry_icon.destroy() end
  local office_reservations = megapack_office_reservations()
  if office_reservations[trip.office_unit_number] == unit_number then
    office_reservations[trip.office_unit_number] = nil
  end
  megapack_buyer_reservations()[unit_number] = nil
  local adoption = megapack_adoption_states()[trip.settlement_key]
  if adoption then
    adoption.reserved = math.max(0, (adoption.reserved or 0) - 1)
    adoption.retry_tick = game.tick + 30 * 60
  end
  trips[unit_number] = nil
  local entity = customer_unit_registry()[unit_number]
  if resume_wandering and entity and entity.valid then
    give_customer_wander_command(entity, true)
    enqueue_customer_variant_migration(unit_number)
    if not customer_vehicle_owners()[unit_number] then
      enqueue_customer_buyer(unit_number, customer_home_settlements()[unit_number])
    end
  end
  return true
end

function megapack_buyer_destination(entity, target, radius, salt)
  local angle = ((entity.unit_number or 0) * 0.61803398875 + (salt or 0)) % (2 * math.pi)
  local position = {
    x = target.x + math.cos(angle) * radius,
    y = target.y + math.sin(angle) * radius
  }
  return entity.surface.find_non_colliding_position(entity.name, position, 16, 0.5)
    or position
end

function begin_megapack_buyer_trip(office, key, population, unit_number)
  local entity = customer_unit_registry()[unit_number]
  local adoption = ensure_megapack_adoption_state(key, population)
  if not entity or not entity.valid or not entity.commandable or not adoption then return false end
  local destination = megapack_buyer_destination(entity, office.position, 4.5, office.unit_number)
  entity.commandable.set_command{
    type = defines.command.go_to_location,
    destination = destination,
    distraction = defines.distraction.none,
    radius = 1.5
  }
  local trip = {
    unit_number = unit_number,
    office = office,
    office_unit_number = office.unit_number,
    settlement_key = key,
    force_name = office.force.name,
    phase = "to_office",
    destination = destination,
    command_started_tick = game.tick
  }
  megapack_buyer_trips()[unit_number] = trip
  megapack_buyer_reservations()[unit_number] = office.unit_number
  megapack_office_reservations()[office.unit_number] = unit_number
  adoption.reserved = (adoption.reserved or 0) + 1
  return true
end

function available_megapack_representatives()
  local by_settlement = {}
  for unit_number, entity in pairs(customer_unit_registry()) do
    local home = customer_home_settlements()[unit_number]
    local commute = customer_charging_commutes()[unit_number]
    local commute_busy = commute and (
      commute.phase == "to_charger"
      or commute.phase == "charging"
      or commute.phase == "returning_home"
    )
    if entity and entity.valid and home and entity.force.name == CUSTOMER_FORCE_NAME
      and not megapack_buyer_reservations()[unit_number]
      and not buyer_reserved_by_unit()[unit_number]
      and not customer_road_rage_states()[unit_number]
      and not commute_busy then
      by_settlement[home.settlement_key] = by_settlement[home.settlement_key] or {}
      by_settlement[home.settlement_key][#by_settlement[home.settlement_key] + 1] = unit_number
    end
  end
  return by_settlement
end

function reserve_megapack_buyer(office, representatives)
  local candidates = {}
  for key, population in pairs(customer_settlement_populations()) do
    if population_in_megapack_office_market(office, population) then
      local adoption = ensure_megapack_adoption_state(key, population)
      local waiting = adoption
        and math.max(0, adoption.eligible - adoption.installed - adoption.reserved) or 0
      local units = representatives[key]
      if waiting > 0 and units and #units > 0
        and (not adoption.retry_tick or game.tick >= adoption.retry_tick) then
        local dx = population.position.x - office.position.x
        local dy = population.position.y - office.position.y
        candidates[#candidates + 1] = {
          key = key,
          population = population,
          distance = dx * dx + dy * dy,
          unit_number = units[#units]
        }
      end
    end
  end
  table.sort(candidates, function(left, right)
    if left.distance ~= right.distance then return left.distance < right.distance end
    return left.key < right.key
  end)
  local candidate = candidates[1]
  if not candidate then return false end
  table.remove(representatives[candidate.key])
  return begin_megapack_buyer_trip(
    office,
    candidate.key,
    candidate.population,
    candidate.unit_number
  )
end

function send_megapack_buyer_home(trip)
  local entity = customer_unit_registry()[trip.unit_number]
  local population = customer_settlement_populations()[trip.settlement_key]
  if not entity or not entity.valid or not entity.commandable or not population
    or entity.surface.index ~= population.surface_index then
    return false
  end
  local destination = megapack_buyer_destination(
    entity,
    population.position,
    8 + ((trip.unit_number * 7) % 13),
    trip.office_unit_number
  )
  entity.commandable.set_command{
    type = defines.command.go_to_location,
    destination = destination,
    distraction = defines.distraction.none,
    radius = 2
  }
  trip.phase = "returning_home"
  trip.destination = destination
  trip.command_started_tick = game.tick
  trip.carry_icon = rendering.draw_sprite{
    sprite = "item/" .. MEGAPACK_NAME,
    surface = entity.surface,
    target = entity,
    target_offset = {0, -1.6},
    x_scale = 0.42,
    y_scale = 0.42,
    render_layer = "air-object"
  }
  return true
end

function complete_megapack_sale(office)
  local unit_number = megapack_office_reservations()[office.unit_number]
  local trip = unit_number and megapack_buyer_trips()[unit_number]
  if not trip or trip.phase ~= "waiting_product" then return false end
  megapack_office_reservations()[office.unit_number] = nil
  office.disabled_by_script = true
  if not send_megapack_buyer_home(trip) then
    clear_megapack_buyer_trip(unit_number, true)
    return false
  end
  return true
end

function install_megapack_at_settlement(unit_number)
  local trip = megapack_buyer_trips()[unit_number]
  if not trip then return false end
  local adoption = megapack_adoption_states()[trip.settlement_key]
  if not adoption then
    clear_megapack_buyer_trip(unit_number, true)
    return false
  end
  if trip.carry_icon and trip.carry_icon.valid then trip.carry_icon.destroy() end
  adoption.reserved = math.max(0, (adoption.reserved or 0) - 1)
  adoption.installed = math.min(adoption.eligible, (adoption.installed or 0) + 1)
  adoption.retry_tick = nil
  adoption.next_referral_tick = adoption.next_referral_tick
    or (game.tick + MEGAPACK_REFERRAL_WAVE_TICKS)
  megapack_buyer_reservations()[unit_number] = nil
  megapack_buyer_trips()[unit_number] = nil
  refresh_megapack_installation_rendering(trip.settlement_key)
  local entity = customer_unit_registry()[unit_number]
  if entity and entity.valid then
    give_customer_wander_command(entity, true)
    enqueue_customer_variant_migration(unit_number)
    if not customer_vehicle_owners()[unit_number] then
      enqueue_customer_buyer(unit_number, customer_home_settlements()[unit_number])
    end
  end
  return true
end

function complete_megapack_buyer_arrival(unit_number)
  local trip = megapack_buyer_trips()[unit_number]
  local entity = customer_unit_registry()[unit_number]
  if not trip or not entity or not entity.valid or not trip.destination then return false end
  local dx = entity.position.x - trip.destination.x
  local dy = entity.position.y - trip.destination.y
  if dx * dx + dy * dy > 64 then return false end

  if trip.phase == "to_office" then
    trip.phase = "waiting_product"
    trip.destination = nil
    trip.command_started_tick = nil
    entity.commandable.set_command{
      type = defines.command.wander,
      distraction = defines.distraction.none,
      radius = 0.25,
      ticks_to_wait = 60
    }
    return true
  elseif trip.phase == "returning_home" then
    install_megapack_at_settlement(unit_number)
    return true
  end
  return false
end

function handle_megapack_buyer_command_completed(event)
  local trip = event.unit_number and megapack_buyer_trips()[event.unit_number]
  if not trip then return false end
  local entity = customer_unit_registry()[event.unit_number]
  if not entity or not entity.valid then
    clear_megapack_buyer_trip(event.unit_number, false)
    return true
  end
  if not complete_megapack_buyer_arrival(event.unit_number) then
    clear_megapack_buyer_trip(event.unit_number, true)
  end
  return true
end

function process_megapack_buyer_trips()
  local active = 0
  for unit_number, trip in pairs(megapack_buyer_trips()) do
    local entity = customer_unit_registry()[unit_number]
    local office = trip.office
    local invalid = not entity or not entity.valid or entity.force.name ~= CUSTOMER_FORCE_NAME
      or not customer_settlement_populations()[trip.settlement_key]
    if trip.phase == "to_office" or trip.phase == "waiting_product" then
      invalid = invalid or not office or not office.valid
        or current_recipe_name(office) ~= MEGAPACK_SALE_RECIPE
    end
    if invalid then
      clear_megapack_buyer_trip(unit_number, true)
    elseif (trip.phase == "to_office" or trip.phase == "returning_home")
      and complete_megapack_buyer_arrival(unit_number) then
      if megapack_buyer_trips()[unit_number] then active = active + 1 end
    elseif (trip.phase == "to_office" or trip.phase == "returning_home")
      and game.tick - (trip.command_started_tick or game.tick)
        >= MEGAPACK_BUYER_PATH_TIMEOUT_TICKS then
      clear_megapack_buyer_trip(unit_number, true)
    else
      active = active + 1
    end
  end
  return active
end

function sync_megapack_sales_offices()
  sync_megapack_adoption_waves()
  local active = process_megapack_buyer_trips()
  local representatives = available_megapack_representatives()
  local starts = 0
  storage.factoryx_sales_office_coverage_recipes =
    storage.factoryx_sales_office_coverage_recipes or {}
  local coverage_recipes = storage.factoryx_sales_office_coverage_recipes
  local seen_offices = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
    if office.valid and office.unit_number then
      seen_offices[office.unit_number] = true
      local recipe_name = current_recipe_name(office)
      local megapack_market = recipe_name == MEGAPACK_SALE_RECIPE
      if coverage_recipes[office.unit_number] ~= megapack_market then
        coverage_recipes[office.unit_number] = megapack_market
        mark_sales_office_coverage_dirty()
      end
      local reserved_unit = megapack_office_reservations()[office.unit_number]
      local trip = reserved_unit and megapack_buyer_trips()[reserved_unit]
      if recipe_name ~= MEGAPACK_SALE_RECIPE then
        if trip and trip.phase ~= "returning_home" then
          clear_megapack_buyer_trip(reserved_unit, true)
        end
      else
        if not trip and starts < MEGAPACK_BUYER_STARTS_PER_SECOND
          and active + starts < MEGAPACK_BUYER_MAX_ACTIVE
          and reserve_megapack_buyer(office, representatives) then
          reserved_unit = megapack_office_reservations()[office.unit_number]
          trip = reserved_unit and megapack_buyer_trips()[reserved_unit]
          starts = starts + 1
        end
        office.disabled_by_script = not trip or trip.phase ~= "waiting_product"
        local status = megapack_office_status(office)
        local label
        local diode
        if trip and trip.phase == "to_office" then
          label, diode = "Energy buyer en route", defines.entity_status_diode.yellow
        elseif trip and trip.phase == "waiting_product" then
          label, diode = "Energy buyer waiting", defines.entity_status_diode.green
        elseif status.waiting <= 0 and status.installed < status.population then
          label, diode = "Waiting for referral wave", defines.entity_status_diode.green
        elseif status.population > 0 and status.installed >= status.population then
          label, diode = "Energy market fully adopted", defines.entity_status_diode.green
        elseif status.settlements == 0 then
          label, diode = "No customer settlements in energy market", defines.entity_status_diode.red
        else
          label, diode = "Waiting for an energy buyer", defines.entity_status_diode.yellow
        end
        pcall(function() office.custom_status = {diode = diode, label = label} end)
      end
    end
  end
  for unit_number in pairs(coverage_recipes) do
    if not seen_offices[unit_number] then coverage_recipes[unit_number] = nil end
  end
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
      and not megapack_buyer_reservations()[unit_number]
    if available and entity.surface == office.surface then
      return true, false
    end
    return false, available == true
  end)
end

function reserved_customer_buyers_by_settlement(force)
  local reserved = {}
  for unit_number in pairs(buyer_reserved_by_unit()) do
    local home = customer_home_settlements()[unit_number]
    if home and home.market_force_name == force.name then
      reserved[home.settlement_key] = (reserved[home.settlement_key] or 0) + 1
    end
  end
  return reserved
end

function eligible_customer_buyers(office, needed)
  local service = customer_service_for_force(office.force)
  local vehicle_summary = active_customer_vehicle_summary(office.force)
  local reserved_by_settlement = reserved_customer_buyers_by_settlement(office.force)
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
  if not office or not office.valid then
    return {
      available = 0,
      assigned = 0,
      service_blocked = 0,
      settlements = 0,
      customers = 0,
      owned = 0,
      capacity = 0,
      powered_capacity = 0,
      underserved = 0,
      friendly_settlements = 0,
      unowned = 0,
      market_office_count = 0,
      duplicated_settlements = 0,
      surplus_office = false
    }
  end
  local service = customer_service_for_force(office.force)
  local vehicle_summary = active_customer_vehicle_summary(office.force)
  local reserved_by_settlement = reserved_customer_buyers_by_settlement(office.force)
  local office_market = service.sales_office_market
    and service.sales_office_market.by_office[office.unit_number]
  local eligible_keys = office_market and office_market.settlement_keys or {}
  local settlements = office_market and office_market.settlement_count or 0
  local stale_snapshot = false
  for _, settlement in pairs(service.candidate_settlements or {}) do
    if settlement and settlement.valid then
      if not office_market then
        local key = settlement_key(settlement.surface, settlement)
        local population = customer_settlement_populations()[key]
        if (service.capacity_by_settlement_key[key] or 0) > 0
          and population and population.surface_index == office.surface.index
          and within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS) then
          eligible_keys[key] = true
          settlements = settlements + 1
        end
      end
    else
      stale_snapshot = true
    end
  end
  if stale_snapshot then mark_factoryx_market_dirty(office.force, "invalid-market-settlement") end
  local available = 0
  local customers = 0
  local owned = 0
  local capacity = 0
  local powered_capacity = 0
  local friendly_settlements = 0
  local assigned = 0
  local service_blocked = 0
  for key in pairs(eligible_keys) do
    local population = customer_settlement_populations()[key]
    local key_owned = vehicle_summary.by_settlement[key] or 0
    local key_customers = (population.physical or 0) + (population.virtual_unowned or 0)
    for _, count in pairs(population.virtual_by_vehicle or {}) do
      key_customers = key_customers + count
    end
    local key_prospects = math.max(0, key_customers - key_owned)
    local key_assigned = math.min(
      key_prospects,
      (reserved_by_settlement[key] or 0) + (population.virtual_reserved or 0)
    )
    local key_unassigned = math.max(0, key_prospects - key_assigned)
    assigned = assigned + key_assigned
    if service.served_keys[key] then
      available = available + key_unassigned
      friendly_settlements = friendly_settlements + 1
    else
      service_blocked = service_blocked + key_unassigned
    end
    owned = owned + key_owned
    customers = customers + key_customers
    capacity = capacity + (service.capacity_by_settlement_key[key] or 0)
    powered_capacity = powered_capacity + (service.powered_capacity_by_settlement_key[key] or 0)
  end
  return {
    available = available,
    assigned = assigned,
    service_blocked = service_blocked,
    settlements = settlements,
    customers = customers,
    owned = owned,
    capacity = capacity,
    powered_capacity = powered_capacity,
    underserved = math.max(0, owned - powered_capacity),
    friendly_settlements = friendly_settlements,
    unowned = math.max(0, customers - owned),
    market_office_count = office_market and office_market.market_office_count
      or (settlements > 0 and 1 or 0),
    duplicated_settlements = office_market and office_market.duplicated_settlements or 0,
    surplus_office = office_market and office_market.surplus_office == true or false
  }
end

function classify_sales_office_market(buyer_status)
  local customers = math.max(0, buyer_status.customers or 0)
  local remaining = math.max(0, buyer_status.unowned or 0)
  local available = math.max(0, buyer_status.available or 0)
  local assigned = math.max(0, buyer_status.assigned or 0)
  local service_blocked = math.max(0, buyer_status.service_blocked or 0)
  local threshold = math.max(
    SALES_OFFICE_LOW_PROSPECT_MINIMUM,
    math.ceil(customers * SALES_OFFICE_LOW_PROSPECT_FRACTION)
  )
  local percent = customers > 0 and math.floor(remaining * 100 / customers + 0.5) or 0
  local kind = "healthy"
  if (buyer_status.settlements or 0) == 0 or customers == 0 then
    kind = "no-market"
  elseif remaining == 0 then
    kind = "saturated"
  elseif available == 0 and service_blocked > 0 then
    kind = "service-blocked"
  elseif available == 0 and assigned >= remaining then
    kind = "committed"
  elseif available == 0 then
    kind = "unavailable"
  elseif remaining <= threshold then
    kind = "low"
  end
  return {
    kind = kind,
    customers = customers,
    remaining = remaining,
    available = available,
    assigned = assigned,
    service_blocked = service_blocked,
    percent = percent,
    threshold = threshold,
    market_office_count = buyer_status.market_office_count or 0,
    duplicated_settlements = buyer_status.duplicated_settlements or 0,
    surplus_office = buyer_status.surplus_office == true
  }
end

function update_sales_office_market_feedback(office, buyer_status)
  if not office or not office.valid or not office.unit_number then return nil end
  local state = classify_sales_office_market(buyer_status)
  sales_office_market_states()[office.unit_number] = state
  local recipe = office.get_recipe()
  local sale = recipe and CUSTOMER_EV_SALE_RECIPES[recipe.name]
  local label
  local diode
  if sale and (office.status == defines.entity_status.working or office.disabled_by_script) then
    if state.kind == "saturated" then
      if state.surplus_office then
        label = "Surplus office - market saturated"
        diode = defines.entity_status_diode.yellow
      else
        label = "Waiting for market growth"
        diode = defines.entity_status_diode.green
      end
    elseif state.kind == "service-blocked" then
      label = string.format("Charging service blocks %d prospects", state.service_blocked)
      diode = defines.entity_status_diode.red
    elseif state.kind == "committed" then
      if state.surplus_office then
        label = string.format("Surplus office - %d prospects remain", state.remaining)
        diode = defines.entity_status_diode.yellow
      else
        label = string.format("%d prospects reserved by active sales", state.remaining)
        diode = defines.entity_status_diode.green
      end
    elseif state.kind == "unavailable" then
      label = "Refreshing prospect assignments"
      diode = defines.entity_status_diode.yellow
    elseif state.kind == "low" and state.surplus_office then
      label = string.format("Surplus office - %d prospects remain", state.remaining)
      diode = defines.entity_status_diode.yellow
    elseif state.kind == "no-market" and office.disabled_by_script then
      label = "No customer market"
      diode = defines.entity_status_diode.red
    end
  end
  pcall(function()
    office.custom_status = label and {diode = diode, label = label} or nil
  end)
  return state
end

function sales_office_market_alert_message(state)
  if state.kind == "saturated" then
    return "Surplus Sales Office in a saturated market. Deconstruct this office; another Sales Office preserves local coverage for future growth."
  elseif state.kind == "service-blocked" then
    return string.format(
      "Sales Office has %d prospects blocked by inadequate charging service. Restore powered charging near their settlements.",
      state.service_blocked
    )
  elseif state.kind == "committed" then
    return string.format(
      "Surplus Sales Office shares %d prospects already reserved by active sales. Deconstruct this office; another Sales Office preserves local coverage.",
      state.remaining
    )
  end
  return string.format(
    "Surplus Sales Office shares a nearly saturated market with only %d prospects remaining (%d%%). Deconstruct this office; another Sales Office preserves local coverage.",
    state.remaining,
    state.percent
  )
end

function update_sales_office_market_alerts()
  local states = sales_office_market_states()
  local alerts_by_player = sales_office_market_alert_states()
  for _, player in pairs(game.connected_players) do
    alerts_by_player[player.index] = alerts_by_player[player.index] or {}
    local prior = alerts_by_player[player.index]
    local active = {}
    for _, office in pairs(registered_factoryx_entities("sales_offices", player.force)) do
      local state = office.valid and office.unit_number and states[office.unit_number]
      local recipe = office.valid and office.get_recipe()
      local sale = recipe and CUSTOMER_EV_SALE_RECIPES[recipe.name]
      local saturation_warning = state and state.surplus_office
        and (state.kind == "low"
          or state.kind == "committed"
          or state.kind == "saturated")
      local warning = state and (state.kind == "service-blocked" or saturation_warning)
      if sale and warning and office.surface == player.surface
        and (office.status == defines.entity_status.working or office.disabled_by_script) then
        active[office.unit_number] = office
        if prior[office.unit_number] then
          player.remove_alert{entity = office, type = defines.alert_type.custom}
        end
        player.add_custom_alert(
          office,
          {type = "item", name = DOLLAR_NAME},
          sales_office_market_alert_message(state),
          true
        )
      end
    end
    for unit_number, office in pairs(prior) do
      if not active[unit_number] and office.valid then
        player.remove_alert{entity = office, type = defines.alert_type.custom}
      end
    end
    alerts_by_player[player.index] = active
  end
end

function reserve_office_buyers(office, recipe_name, sale)
  clear_office_buyer_reservation(office.unit_number)
  local buyers = eligible_customer_buyers(office, sale.vehicles)
  if #buyers < sale.vehicles
    and sales_office_buyer_status(office).available >= sale.vehicles then
    rebuild_customer_buyer_queues()
    buyers = eligible_customer_buyers(office, sale.vehicles)
    storage.factoryx_perf_counters = storage.factoryx_perf_counters or {}
    storage.factoryx_perf_counters.buyer_queue_self_repairs =
      (storage.factoryx_perf_counters.buyer_queue_self_repairs or 0) + 1
  end
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
  if not storage.factoryx_last_reservation_reconcile_tick
    or game.tick - storage.factoryx_last_reservation_reconcile_tick
      >= SALES_OFFICE_RESERVATION_RECONCILE_TICKS then
    reconcile_office_buyer_reservations()
    storage.factoryx_last_reservation_reconcile_tick = game.tick
  end
  local seen = {}
  for _, office in pairs(registered_factoryx_entities("sales_offices")) do
      if office.valid and office.unit_number then
        seen[office.unit_number] = true
        local recipe = office.get_recipe()
        local recipe_name = recipe and recipe.name
        local sale = recipe_name and CUSTOMER_EV_SALE_RECIPES[recipe_name]
        local reservation = office_buyer_reservations()[office.unit_number]
        if recipe_name == MEGAPACK_SALE_RECIPE then
          clear_office_buyer_reservation(office.unit_number)
        elseif not sale then
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
        if recipe_name ~= MEGAPACK_SALE_RECIPE then
          update_sales_office_market_feedback(office, sales_office_buyer_status(office))
        end
      end
  end
  for unit_number in pairs(sales_office_market_states()) do
    if not seen[unit_number] then sales_office_market_states()[unit_number] = nil end
  end
  sync_megapack_sales_offices()
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
          if recipe_name == MEGAPACK_SALE_RECIPE then
            complete_megapack_sale(office)
          else
            complete_reserved_vehicle_sale(office, recipe_name)
          end
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
  local megapack_adoption = megapack_adoption_summary(force)
  local premium_evs_produced = count_item_produced(force, PREMIUM_EV_NAME)
  local advanced_battery_chemistry_available = sync_advanced_battery_chemistry_gate(force, false)
  local foundry_gate = sync_foundry_power_gate(force, false)
  local logistic_system = force.technologies and force.technologies[LOGISTIC_SYSTEM_TECH_NAME]
  return {
    industrial_supply_chain_researched = researched(force, "x-industrial-supply-chain"),
    big_mining_drill_researched = researched(force, "big-mining-drill"),
    foundry_researched = researched(force, "foundry"),
    foundry_power_gate = foundry_gate,
    recycling_revealed = (force.technologies.recycling and force.technologies.recycling.enabled) or false,
    recycling_researched = researched(force, "recycling"),
    sales_office_researched = researched(force, "x-sales-office"),
    ev_production_researched = researched(force, "x-premium-ev-program"),
    advanced_battery_chemistry_available = advanced_battery_chemistry_available,
    advanced_battery_chemistry_researched = researched(force, ADVANCED_BATTERY_CHEMISTRY_TECH_NAME),
    charging_network_researched = researched(force, "x-ev-charging-network"),
    mass_market_researched = researched(force, "x-capital-scaling"),
    energy_products_researched = researched(force, "x-energy-products"),
    logistic_system_available = logistic_system and logistic_system.enabled or false,
    logistic_system_researched = logistic_system and logistic_system.researched or false,
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
    nickel_ore_mined = count_item_produced(force, "x-nickel-ore"),
    lithium_brine_pumped = count_fluid_produced(force, "x-lithium-brine"),
    acidic_tailings_produced = count_fluid_produced(force, "x-acidic-tailings"),
    nickel_sulfate_produced = count_item_produced(force, "x-nickel-sulfate"),
    lithium_carbonate_produced = count_item_produced(force, "x-lithium-carbonate"),
    high_nickel_cells_produced = count_item_produced(force, "x-high-nickel-cell"),
    high_energy_battery_packs_produced = count_item_produced(force, "x-high-energy-battery-pack"),
    lfp_cells_produced = count_item_produced(force, "x-lfp-cell"),
    lfp_battery_packs_produced = count_item_produced(force, "x-lfp-battery-pack"),
    wrecked_evs_produced = count_item_produced(force, WRECKED_EV_NAME),
    customer_settlements = count_sales_office_customer_settlements(force),
    powered_stations = market.powered_stations,
    charging_capacity = market.charging_stall_capacity,
    active_stalls = market.active_customer_stalls,
    requested_customer_stalls = market.requested_customer_stalls,
    powered_customer_stalls = market.powered_customer_stalls,
    charging_power_demand_kw = market.charging_power_demand_kw,
    charging_power_served_kw = market.charging_power_served_kw,
    next_charging_step = market.next_charging_step,
    supported_ev_capacity = market.supported_ev_capacity,
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
    customer_prospects = market.customer_prospects,
    reservation_prospects = market.reservation_prospects,
    reservation_stock = market.charger_reservation_stock,
    gigafactories = count_entities(force, "x-gigafactory-building"),
    gigafactories_v2 = count_entities(force, "x-gigafactory-v2"),
    chargers_v1 = count_entities(force, "x-ev-charging-station"),
    chargers_v2 = count_entities(force, "x-ev-charging-station-v2"),
    chargers_v3 = count_entities(force, "x-ev-charging-station-v3"),
    chargers_v4 = count_entities(force, "x-ev-charging-station-v4"),
    solar_arrays = count_entities(force, HIGH_DENSITY_SOLAR_ARRAY_NAME),
    megapacks = count_entities(force, MEGAPACK_NAME),
    megapack_energy_settlements = megapack_adoption.settlements,
    megapack_energy_population = megapack_adoption.population,
    megapack_believers_waiting = megapack_adoption.waiting,
    megapack_buyers_reserved = megapack_adoption.reserved,
    megapack_buyers_in_transit = megapack_adoption.in_transit,
    megapacks_installed_by_customers = megapack_adoption.installed,
    megapack_adoption_percent = megapack_adoption.adoption_percent,
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
    premium_evs_produced = premium_evs_produced,
    premium_pilot_production_gate = PREMIUM_PILOT_PRODUCTION_GATE,
    advanced_battery_chemistry_production_gate = ADVANCED_BATTERY_CHEMISTRY_PRODUCTION_GATE,
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
  elseif snapshot.premium_evs_produced < snapshot.premium_pilot_production_gate then
    return "Premium pilot production", string.format("Build %d Premium EVs with commodity Batteries.", snapshot.premium_pilot_production_gate), string.format(
      "Pilot vehicles produced: %d / %d. Each early vehicle consumes 48 conventional Batteries; completing the pilot unlocks Gigafactory construction.",
      snapshot.premium_evs_produced,
      snapshot.premium_pilot_production_gate
    )
  elseif snapshot.gigafactories == 0 and snapshot.gigafactories_v2 == 0 then
    return "Premium production", "Construct the first Gigafactory.",
      "Build 10 Gigafactory Modules, add 2 Substations, then place the 9x9, 20 MW factory. Its first job is scaling the commodity-cell Premium EV."
  elseif not snapshot.premium_sale_complete then
    return "Premium production", "Produce and sell a Premium EV.",
      "Select the commodity-cell Premium EV in the Gigafactory and route the vehicle plus one EV Reservation to a Sales Office."
  elseif snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate then
    return "Gigafactory scale", string.format(
      "Produce %d Premium EVs before changing battery technology.",
      snapshot.advanced_battery_chemistry_production_gate
    ), string.format(
      "Factory-scale vehicles produced: %d / %d. Keep the conventional Battery supply running until its cost and throughput limits are proven at Gigafactory scale.",
      snapshot.premium_evs_produced,
      snapshot.advanced_battery_chemistry_production_gate
    )
  elseif not snapshot.advanced_battery_chemistry_researched then
    return "Battery breakthrough", "Research Advanced Battery Chemistry.",
      "Producing 250 Premium EVs exposed the commodity-cell bottleneck. Invest 300 cycles of red, green, blue science, and Dollars to develop nickel-rich cells, lithium processing, and scalable packs."
  elseif snapshot.nickel_ore_mined == 0 or snapshot.lithium_brine_pumped == 0 then
    local missing = {}
    if snapshot.nickel_ore_mined == 0 then missing[#missing + 1] = "Nickel Ore" end
    if snapshot.lithium_brine_pumped == 0 then missing[#missing + 1] = "Lithium Brine" end
    return "Battery minerals", "Find and extract " .. table.concat(missing, " and ") .. ".",
      "Both deposits begin outside the starting area, at roughly 80% of uranium's typical distance. Nickel requires sulfuric-acid mining; Lithium Brine uses Pumpjacks."
  elseif snapshot.nickel_sulfate_produced == 0 or snapshot.lithium_carbonate_produced == 0 then
    return "Battery refining", "Refine Nickel Sulfate and Lithium Carbonate.",
      "Use Chemical Plants. Route Acidic Tailings into tanks, then neutralize it with Calcite instead of allowing byproduct backpressure to stop refining."
  elseif snapshot.high_nickel_cells_produced == 0 then
    return "Battery cells", "Manufacture the first High-nickel Cells.",
      "Use High-nickel cells (Chemical Plant) for a four-cell batch, or High-nickel cells (Gigafactory) for five. Both consume Nickel Sulfate, Lithium Carbonate, Battery Graphite, and the Cobalt Concentrate from dirty refining."
  elseif snapshot.high_energy_battery_packs_produced == 0 then
    return "Battery packs", "Assemble the first High-energy Battery Pack.",
      "Combine four High-nickel Cells, four Steel Plates, and two Advanced Circuits. One Chemical Plant cell batch fills one pack; the Gigafactory route yields one spare cell per cycle."
  elseif not snapshot.energy_products_researched then
    return "Energy products", "Research Energy Products for industrial expansion.",
      "Charging demand grows with every customer EV. Unlock High-density Solar Panels, LFP chemistry, and Megapacks before Foundry and mass-market expansion."
  elseif snapshot.foundry_power_gate and not snapshot.foundry_power_gate.qualified then
    local gate = snapshot.foundry_power_gate
    return "Industrial electrification", "Prove a 5 MW solar industrial block.", string.format(
      "Produce %d / %d High-density Solar Panels and %d / %d Megapacks. Landing-kit equipment does not count; this milestone proves new Energy Products manufacturing before Foundries arrive.",
      gate.solar_panels,
      gate.solar_target,
      gate.megapacks,
      gate.megapack_target
    )
  elseif not snapshot.foundry_researched then
    return "Metallurgical scaling", "Research Metallurgical Scaling.",
      "Invest 250 cycles of red, green, blue science, and Dollars. Each Foundry draws 2.5 MW; an ore-melting and casting pair draws 5 MW before modules."
  elseif not snapshot.mass_market_ev_gate.market_ready then
    return "Premium market scale", "Sell 250 Premium EVs.", string.format("Completed sales: %d / 250. This market proof unlocks Mass-market EV production after its research is complete.", snapshot.premium_evs_sold)
  elseif not snapshot.charging_network_researched then
    return "Charging network", "Research EV Charging Network.", "Invest 300 cycles of red, green, blue science, and Dollars to unlock the eight-stall V2 charger."
  elseif snapshot.chargers_v2 == 0 then
    return "Charging network", "Craft and place a V2 charger.", "In an Assembling Machine 2 or 3, craft it from 1 V1 charger, 2 Substations, and 20 Processing Units."
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
    return "Energy products", "Build a High-density Solar Panel and a Megapack.", "Upgrade a conventional panel in an assembler; Gigafactories can mass-produce panels more cheaply. Build Megapacks in either Gigafactory tier."
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
    return "Supercharging", "Craft and place a solar-canopy V4 Supercharger.", "Craft it from 1 V3 Supercharger, 4 High-density Solar Panels, 4 Megapacks, and 200 Dollars. Twenty occupied stalls can draw 10 MW."
  elseif snapshot.robotaxi_service_centers == 0 then
    return "Autonomy", "Build a Robotaxi Service Center.", "Combine a V4 Supercharger, 4 Roboports, 50 Processing Units, and 200 Dollars. The center stores 200 Robotaxis and draws 10 MW."
  elseif not snapshot.robotaxi_sale_complete then
    return "Autonomy", "Operate the Robotaxi service.", "Load Robotaxis into the 40-slot fleet inventory. Each vehicle serves five nearby mobile customers; recurring profit unlocks launch services."
  elseif not snapshot.orbital_compute_researched then
    return "Orbital compute", "Establish Nauvis orbit and research Orbital Compute.", "Use the vanilla Rocket Silo and a stationary platform over Nauvis, then invest 2,000 cycles through space science plus AI Tokens and Dollars."
  elseif not snapshot.planetary_grid_researched then
    return "Planetary grid", "Research Planetary Energy Grid.", "Invest 2,500 cycles through space science plus AI Tokens and Dollars; prepare a 1 TW supply."
  elseif snapshot.grid_controllers == 0 then
    return "AGI infrastructure", "Build a Planetary Energy Grid Controller.", "The controller is the final 1 TW training facility; brownouts slow or stop its work."
  elseif not snapshot.agi_training_unlocked then
    return "AGI scale", "Generate one billion cumulative AI Tokens.", "Terrestrial compute can begin the climb, but orbital compute is required to reach this scale. Tokens already spent still count."
  elseif not snapshot.victory then
    return "AGI training", "Complete the AGI Training Run.", "Package 100M AI Tokens into 10,000 datasets and 10M Dollars into 1,000 allocations; add 10,000 Grid Segments and 1,000 Megapacks, then sustain 1 TW for 60 minutes."
  end
  return "AGI achieved", "The AGI Model is online.", "Biter Motors victory achieved; you may continue building."
end

local function progress_stages(snapshot)
  return {
    {name = "Customer market", sprite = "item/x-sales-office", complete = snapshot.first_sale_complete},
    {name = "Premium EVs", sprite = "item/x-premium-ev", complete = snapshot.premium_sale_complete
      and snapshot.premium_evs_produced >= snapshot.premium_pilot_production_gate
      and snapshot.gigafactories + snapshot.gigafactories_v2 > 0},
    {name = "Mass-market EVs", sprite = "item/x-mass-market-ev", complete = snapshot.mass_market_sale_complete},
    {name = "AI and autonomy", sprite = "item/x-ai-token", complete = snapshot.robotaxi_sale_complete},
    {name = "Orbital compute", sprite = "item/x-orbital-compute-array", complete = snapshot.orbital_compute_researched},
    {name = "AGI", sprite = "item/x-agi-model", complete = snapshot.victory}
  }
end

local function add_section_heading(parent, caption)
  parent.add{type = "label", caption = caption, style = "bold_label"}
end

function progress_objective_icon(stage)
  local icons = {
    ["Customer discovery"] = "item/x-sales-office",
    ["Prototype revenue"] = "item/x-prototype-roadster",
    ["Prototype market validation"] = "item/x-prototype-roadster",
    ["Battery breakthrough"] = "item/x-high-energy-battery-pack",
    ["Battery minerals"] = "item/x-nickel-ore",
    ["Battery refining"] = "item/x-nickel-sulfate",
    ["Battery cells"] = "item/x-high-nickel-cell",
    ["Battery packs"] = "item/x-high-energy-battery-pack",
    ["Premium pilot production"] = "item/x-premium-ev",
    ["Gigafactory scale"] = "item/x-gigafactory-building",
    ["Premium production"] = "item/x-premium-ev",
    ["Premium market scale"] = "item/x-premium-ev",
    ["Energy products"] = "item/x-high-density-solar-array",
    ["Industrial electrification"] = "item/x-high-density-solar-array",
    ["Metallurgical scaling"] = "item/foundry",
    ["Charging network"] = "item/x-ev-charging-station-v2",
    ["Mass-market scale"] = "item/x-mass-market-ev",
    ["Megatruck engineering"] = "item/x-cybertruck",
    ["Supercharging"] = "item/x-ev-charging-station-v3",
    ["Terrestrial AI"] = "item/x-terrestrial-datacenter",
    ["Autonomy"] = "item/x-robotaxi-fleet",
    ["Autonomy market scale"] = "item/x-robotaxi-fleet",
    ["Launch services"] = "item/x-small-launch-service",
    ["Orbital infrastructure"] = "item/x-satellite-bus",
    ["Orbital compute"] = "item/x-orbital-compute-array",
    ["Planetary grid"] = "item/x-planetary-grid-controller",
    ["AGI infrastructure"] = "item/x-planetary-grid-controller",
    ["AGI scale"] = "item/x-ai-token",
    ["AGI training"] = "item/x-agi-training-dataset",
    ["AGI achieved"] = "item/x-agi-model"
  }
  return icons[stage] or "item/x-dollar"
end

function progress_health(snapshot)
  if snapshot.victory then
    return "Complete", "AGI achieved.", FACTORYX_STATE_COLORS.good
  elseif snapshot.sales_office_researched and snapshot.sales_offices == 0 then
    return "Blocked", "Build a Sales Office to open the customer market.", FACTORYX_STATE_COLORS.bad
  elseif snapshot.sales_offices > 0 and snapshot.customer_settlements == 0 then
    return "Blocked", "No customer settlements are covered.", FACTORYX_STATE_COLORS.bad
  elseif snapshot.customer_settlements > 0 and snapshot.powered_stations == 0 then
    return "Blocked", "Customer settlements need a powered charger.", FACTORYX_STATE_COLORS.bad
  elseif snapshot.angry_settlements > 0 then
    return "Service alert", string.format(
      "%d customer settlements lack reliable charging.", snapshot.angry_settlements
    ), FACTORYX_STATE_COLORS.bad
  elseif snapshot.stranded_evs > 0 then
    return "Capacity alert", string.format(
      "%d customer EVs lack powered charging capacity.", snapshot.stranded_evs
    ), FACTORYX_STATE_COLORS.bad
  elseif snapshot.powered_stations > 0 and snapshot.first_sale_complete then
    return "Operating", "Customer market and charging are online.", FACTORYX_STATE_COLORS.good
  elseif snapshot.powered_stations > 0 then
    return "Ready", "Charging is online; complete the first sale.", FACTORYX_STATE_COLORS.good
  end
  return "Next milestone", "Build the terrestrial business.", FACTORYX_STATE_COLORS.warning
end

function current_progress_measure(snapshot)
  if snapshot.victory then return "AGI training", 1, 1 end
  if snapshot.planetary_grid_researched and not snapshot.agi_training_unlocked then
    return "Cumulative AI Tokens", snapshot.ai_tokens_produced, snapshot.agi_token_gate
  end
  if snapshot.agi_training_unlocked and not snapshot.victory then
    return "AGI training", snapshot.agi_training_progress, 1, true
  end
  if snapshot.autonomous_logistics_researched and not snapshot.robotaxi_gate.market_ready then
    return "Consumer EV sales", snapshot.consumer_evs_sold, 5000
  end
  if snapshot.terrestrial_ai_researched and snapshot.ai_tokens_produced < 1000 then
    return "AI Tokens", snapshot.ai_tokens_produced, 1000
  end
  if snapshot.mass_market_researched and not snapshot.cybertruck_gate.market_ready then
    return "Mass-market EV sales", snapshot.mass_market_evs_sold, 2000
  end
  if snapshot.ev_production_researched and snapshot.premium_ev_gate.market_ready
    and snapshot.premium_evs_produced < snapshot.premium_pilot_production_gate then
    return "Premium pilot production", snapshot.premium_evs_produced, snapshot.premium_pilot_production_gate
  end
  if snapshot.gigafactories + snapshot.gigafactories_v2 > 0
    and snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate then
    return "Gigafactory scale", snapshot.premium_evs_produced, snapshot.advanced_battery_chemistry_production_gate
  end
  if snapshot.advanced_battery_chemistry_researched then
    if snapshot.nickel_ore_mined == 0 or snapshot.lithium_brine_pumped == 0 then
      return "Battery minerals", (snapshot.nickel_ore_mined > 0 and 1 or 0)
        + (snapshot.lithium_brine_pumped > 0 and 1 or 0), 2
    end
    if snapshot.nickel_sulfate_produced == 0 or snapshot.lithium_carbonate_produced == 0 then
      return "Battery refining", (snapshot.nickel_sulfate_produced > 0 and 1 or 0)
        + (snapshot.lithium_carbonate_produced > 0 and 1 or 0), 2
    end
    if snapshot.high_nickel_cells_produced == 0 then
      return "High-nickel Cells", 0, 1
    end
    if snapshot.high_energy_battery_packs_produced == 0 then
      return "High-energy Battery Packs", 0, 1
    end
  end
  if snapshot.premium_sale_complete and not snapshot.mass_market_ev_gate.market_ready then
    return "Premium EV sales", snapshot.premium_evs_sold, 250
  end
  if snapshot.first_sale_complete and not snapshot.premium_ev_gate.market_ready then
    return "Prototype Roadster sales", snapshot.roadsters_sold, 50
  end
  return nil
end

function add_progress_metrics(parent, rows)
  if #rows == 0 then return nil end
  local metrics = parent.add{type = "table", column_count = 3}
  metrics.style.horizontal_spacing = 8
  metrics.style.vertical_spacing = 5
  metrics.style.horizontally_stretchable = true
  for _, row in ipairs(rows) do
    local status = row.color == FACTORYX_STATE_COLORS.bad and "Red: action is required."
      or row.color == FACTORYX_STATE_COLORS.warning and "Orange: prepare or keep progressing."
      or row.color == FACTORYX_STATE_COLORS.good and "Green: healthy or complete."
      or "Gray: informational."
    local tooltip = (row.tooltip or (row.label .. " reports the current Biter Motors state."))
      .. "\n\n" .. status
    local icon = metrics.add{type = "sprite", sprite = row.sprite, tooltip = tooltip}
    icon.style.width = 24
    icon.style.height = 24
    icon.style.stretch_image_to_widget_size = true
    local label = metrics.add{type = "label", caption = row.label, tooltip = tooltip}
    label.style.width = 190
    local value = metrics.add{
      type = "label", name = row.name, caption = row.value, tooltip = tooltip
    }
    value.style.width = 230
    value.style.horizontal_align = "right"
    if row.color then value.style.font_color = row.color end
  end
  return metrics
end

function add_progress_section(parent, caption, rows)
  if #rows == 0 then return end
  parent.add{type = "line"}
  add_section_heading(parent, caption)
  add_progress_metrics(parent, rows)
end

local function format_represented_usd(dollars)
  local amount = math.floor(math.max(0, dollars or 0) * 10000 + 0.5)
  local grouped = tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  return "$" .. grouped
end

local function refresh_progress_panel(player)
  if not player or not player.valid then
    return
  end
  local panel = player.gui.screen[PROGRESS_PANEL_NAME]
  if not panel then
    return
  end
  local display_scale = math.max(0.5, player.display_scale or 1)
  local gui_width = math.floor(player.display_resolution.width / display_scale)
  local gui_height = math.floor(player.display_resolution.height / display_scale)
  local panel_width = math.max(540, math.min(600, gui_width - 80))
  local content_height = math.max(480, math.min(1100, gui_height - 160))
  panel.style.width = panel_width
  storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}

  local snapshot = progress_snapshot(player.force)
  local signature_parts = {}
  local ignored = {
    customer_commutes_en_route = true,
    customer_commutes_charging = true,
    customer_commutes_completed = true
  }
  local function append_signature(prefix, value)
    if type(value) ~= "table" then
      signature_parts[#signature_parts + 1] = prefix .. "=" .. tostring(value)
      return
    end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
    for _, key in ipairs(keys) do
      append_signature(prefix .. "." .. tostring(key), value[key])
    end
  end
  for key, value in pairs(snapshot) do
    if not ignored[key] then append_signature(tostring(key), value) end
  end
  signature_parts[#signature_parts + 1] = string.format(
    "display=%dx%d@%.2f",
    player.display_resolution.width,
    player.display_resolution.height,
    display_scale
  )
  table.sort(signature_parts)
  local signature = table.concat(signature_parts, "|")
  if storage.factoryx_progress_panel_signatures[player.index] == signature then
    return
  end
  storage.factoryx_progress_panel_signatures[player.index] = signature

  local old_content = panel[PROGRESS_CONTENT_NAME]
  if old_content then
    old_content.destroy()
  end

  local stage, objective, detail = current_progress_objective(snapshot)
  local content = panel.add{
    type = "scroll-pane",
    name = PROGRESS_CONTENT_NAME,
    direction = "vertical"
  }
  content.style.maximal_height = content_height
  content.style.horizontally_stretchable = true

  local objective_row = content.add{type = "flow", direction = "horizontal"}
  objective_row.style.vertical_align = "center"
  local objective_icon = objective_row.add{type = "sprite", sprite = progress_objective_icon(stage)}
  objective_icon.style.width = 40
  objective_icon.style.height = 40
  objective_icon.style.stretch_image_to_widget_size = true
  local objective_text = objective_row.add{type = "flow", direction = "vertical"}
  objective_text.style.left_margin = 8
  local stage_label = objective_text.add{type = "label", caption = stage, style = "bold_label"}
  stage_label.style.font_color = FACTORYX_STATE_COLORS.warning
  local objective_label = objective_text.add{type = "label", caption = objective, single_line = false}
  objective_label.style.font = "default-bold"
  objective_label.style.maximal_width = 440
  local detail_label = content.add{type = "label", caption = detail, single_line = false}
  detail_label.style.maximal_width = 485
  detail_label.style.top_margin = 6

  local health_state, health_detail, health_color = progress_health(snapshot)
  local health = content.add{type = "flow", direction = "horizontal"}
  health.style.top_margin = 8
  local health_label = health.add{type = "label", caption = health_state, style = "bold_label"}
  health_label.style.font_color = health_color
  local health_text = health.add{type = "label", caption = health_detail, single_line = false}
  health_text.style.left_margin = 8
  health_text.style.maximal_width = 390

  local measure_name, measure_current, measure_target, measure_fraction = current_progress_measure(snapshot)
  if measure_name then
    local progress_header = content.add{type = "flow", direction = "horizontal"}
    progress_header.style.top_margin = 8
    local progress_name = progress_header.add{type = "label", caption = measure_name}
    progress_name.style.horizontally_stretchable = true
    local progress_value = progress_header.add{
      type = "label",
      caption = measure_fraction
        and string.format("%d%%", math.floor(math.min(1, measure_current) * 100))
        or string.format("%d / %d", math.floor(measure_current), measure_target)
    }
    progress_value.style.font_color = measure_current >= measure_target
      and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning
    local progress_bar = content.add{
      type = "progressbar",
      value = math.max(0, math.min(1, measure_current / math.max(1, measure_target)))
    }
    progress_bar.style.width = 485
    progress_bar.style.color = measure_current >= measure_target
      and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning
  end

  local industry_rows = {}
  if snapshot.industrial_supply_chain_researched or snapshot.big_mining_drill_researched
    or snapshot.foundry_researched or snapshot.recycling_revealed then
    industry_rows[#industry_rows + 1] = {
      sprite = "item/electric-mining-drill", label = "Industrial supply chain",
      value = snapshot.industrial_supply_chain_researched and "Researched" or "Available",
      color = snapshot.industrial_supply_chain_researched and FACTORYX_STATE_COLORS.good
        or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.industrial_supply_chain_researched
        and "The terrestrial industrial branch is unlocked. Its drills, furnaces, and Foundries accelerate the pre-EV factory."
        or "Research Industrial Supply Chain next to unlock Biter Motors's early terrestrial production tools."
    }
  end
  if snapshot.big_mining_drill_researched then
    industry_rows[#industry_rows + 1] = {
      sprite = "item/big-mining-drill", label = "Big Mining Drills",
      value = string.format("%d built", snapshot.big_mining_drills),
      color = snapshot.big_mining_drills > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.big_mining_drills > 0
        and "Big Mining Drills extract ore faster and consume resource patches more slowly."
        or "Big Mining Drills are researched but none are built. Replace high-throughput Electric Mining Drills first."
    }
  end
  if snapshot.foundry_researched then
    industry_rows[#industry_rows + 1] = {
      sprite = "item/foundry", label = "Foundries", value = string.format("%d built", snapshot.foundries),
      color = snapshot.foundries > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.foundries > 0
        and "Foundries multiply terrestrial metal output. Ore-melting Foundries favor productivity modules; downstream casting Foundries favor efficiency modules."
        or "Foundries are researched but none are built. Start with the plate supply that is constraining expansion."
    }
  elseif snapshot.energy_products_researched and snapshot.foundry_power_gate then
    local gate = snapshot.foundry_power_gate
    industry_rows[#industry_rows + 1] = {
      sprite = "item/x-high-density-solar-array", label = "Industrial power qualification",
      value = gate.qualified and "Research available" or string.format(
        "%d/%d panels; %d/%d packs",
        gate.solar_panels,
        gate.solar_target,
        gate.megapacks,
        gate.megapack_target
      ),
      color = FACTORYX_STATE_COLORS.warning,
      tooltip = gate.qualified
        and "New Energy Products manufacturing has demonstrated a 5 MW solar industrial block. Research Metallurgical Scaling to unlock Foundries."
        or "Produce 25 new High-density Solar Panels and 5 new Megapacks. Starter equipment does not count. This approximates 5.25 MW average Nauvis solar output plus 500 MJ storage."
    }
  end
  if snapshot.logistic_system_available or snapshot.logistic_system_researched then
    industry_rows[#industry_rows + 1] = {
      sprite = "item/requester-chest", label = "Logistic System",
      value = snapshot.logistic_system_researched and "Researched" or "Research available",
      color = snapshot.logistic_system_researched and FACTORYX_STATE_COLORS.good
        or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.logistic_system_researched
        and "Requester chests and full logistics are available for multi-ingredient Biter Motors production."
        or "Logistic System is available to research. It simplifies supplying Sales Offices and Gigafactories."
    }
  end
  add_progress_section(content, "Terrestrial industry", industry_rows)

  local grid_rows = {}
  if snapshot.charging_capacity > 0 or snapshot.requested_customer_stalls > 0 then
    local demand_kw = snapshot.charging_power_demand_kw or 0
    local served_kw = snapshot.charging_power_served_kw or 0
    local power_color = demand_kw <= 0 and FACTORYX_STATE_COLORS.neutral
      or (served_kw >= demand_kw * 0.95 and FACTORYX_STATE_COLORS.good
        or FACTORYX_STATE_COLORS.bad)
    grid_rows[#grid_rows + 1] = {
      sprite = "item/accumulator", label = "EV grid load",
      value = string.format("%.1f / %.1f MW delivered", served_kw / 1000, demand_kw / 1000),
      color = power_color,
      tooltip = served_kw >= demand_kw * 0.95
        and "Powered charging stalls are receiving their requested electricity. This load rises as more sold EVs activate stalls."
        or string.format(
          "Chargers are short %.1f MW. Add generation or storage, repair disconnected grids, or temporarily stop expanding EV sales.",
          math.max(0, demand_kw - served_kw) / 1000
        )
    }
    grid_rows[#grid_rows + 1] = {
      sprite = "item/x-ev-charging-station", label = "Charging stalls",
      value = string.format(
        "%d / %d powered",
        snapshot.powered_customer_stalls,
        snapshot.requested_customer_stalls
      ),
      color = snapshot.powered_customer_stalls >= snapshot.requested_customer_stalls
        and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.bad,
      tooltip = snapshot.powered_customer_stalls >= snapshot.requested_customer_stalls
        and "Every stall currently requested by EV owners has enough grid power. Unused physical stalls draw no customer load."
        or "Some owner-requested stalls are unpowered. Restore electricity at affected chargers before settlements lose patience."
    }
    grid_rows[#grid_rows + 1] = {
      sprite = "item/x-mass-market-ev", label = "Powered capacity",
      value = string.format(
        "%d EVs; %d spare",
        snapshot.supported_ev_capacity,
        math.max(0, snapshot.supported_ev_capacity - snapshot.customer_ev_fleet)
      ),
      color = snapshot.supported_ev_capacity >= snapshot.customer_ev_fleet
        and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.bad,
      tooltip = snapshot.supported_ev_capacity >= snapshot.customer_ev_fleet
        and "Powered stalls can support the current EV fleet. Spare capacity is how many additional sold EVs fit before another stall is needed."
        or "The sold EV fleet exceeds powered charging capacity. Add or power chargers near the underserved settlements."
    }
  end
  if snapshot.first_sale_complete then
    local supported_owners = math.max(0, snapshot.customer_ev_fleet - snapshot.stranded_evs)
    grid_rows[#grid_rows + 1] = {
      sprite = "item/x-premium-ev", label = "EV owners",
      value = snapshot.stranded_evs > 0
        and string.format(
          "%d / %d supported; %d stranded",
          supported_owners,
          snapshot.customer_ev_fleet,
          snapshot.stranded_evs
        )
        or string.format("%d / %d supported", supported_owners, snapshot.customer_ev_fleet),
      color = snapshot.stranded_evs > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good,
      tooltip = snapshot.stranded_evs > 0
        and "These sold EVs currently lack powered charging capacity. Follow the red settlement map tags to the missing local capacity or power."
        or "Every active EV owner currently has powered charging capacity near its home settlement."
    }
    local step = snapshot.next_charging_step
    if step and step.available then
      grid_rows[#grid_rows + 1] = {
        sprite = "item/x-ev-charging-station", label = "Next charger activation",
        value = string.format(
          "%d EV sale%s: +%.0f kW",
          step.ev_owners_until,
          step.ev_owners_until == 1 and "" or "s",
          step.power_kw
        ),
        color = FACTORYX_STATE_COLORS.neutral,
        tooltip = string.format(
          "Information only: after %d more EV sale%s, the next settlement will activate another %s stall and add %.0f kW of grid load. No action is required while EV grid load and Powered capacity remain green; otherwise add generation or storage. The new stall supports %d more EVs.",
          step.ev_owners_until,
          step.ev_owners_until == 1 and "" or "s",
          step.station_name,
          step.power_kw,
          step.ev_capacity_added
        )
      }
    elseif step and step.needs_charger then
      grid_rows[#grid_rows + 1] = {
        sprite = "item/x-ev-charging-station", label = "Next charger activation",
        value = "No spare stalls; add a charger",
        color = snapshot.stranded_evs > 0 and FACTORYX_STATE_COLORS.bad
          or FACTORYX_STATE_COLORS.warning,
        tooltip = "No existing charger near the next constrained settlement has a free physical stall. Place another powered charger there before selling more EVs."
      }
    end
  end
  add_progress_section(content, "Grid power", grid_rows)

  local market_rows = {}
  if snapshot.sales_office_researched or snapshot.sales_offices > 0 then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-dollar", label = "Profit generated",
      value = string.format(
        "%s (%d $)",
        format_represented_usd(snapshot.dollars_produced),
        snapshot.dollars_produced
      ),
      name = "factoryx_dollars_produced_value",
      color = snapshot.dollars_produced > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.neutral,
      tooltip = "Lifetime profit generated by Biter Motors businesses. One in-game Dollar represents approximately $10,000 USD of profit, not revenue."
    }
    market_rows[#market_rows + 1] = {
      sprite = "entity/biter-spawner", label = "Customer settlements",
      value = tostring(snapshot.customer_settlements),
      color = snapshot.customer_settlements > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.bad,
      tooltip = snapshot.customer_settlements > 0
        and "Settlements converted into customer markets by Sales Office coverage. Expand to new settlements when local buyer growth limits sales."
        or "No customer settlement is covered. Build a Sales Office and powered charger near biter spawners."
    }
  end
  if snapshot.charging_capacity > 0 or snapshot.powered_stations > 0 then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-ev-charging-station", label = "Charging stalls",
      value = string.format("%d / %d active", snapshot.active_stalls, snapshot.charging_capacity),
      color = snapshot.powered_stations == 0 and FACTORYX_STATE_COLORS.bad
        or (snapshot.active_stalls > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning),
      tooltip = snapshot.powered_stations == 0
        and "No charger is operational. Connect chargers to a powered electric grid."
        or "Active stalls are the portion of installed stalls currently serving sold EVs. Idle stalls consume no customer charging load."
    }
    market_rows[#market_rows + 1] = {
      sprite = "item/x-ev-reservation", label = "EV Reservations",
      value = string.format("%d stored, %.1f/min", snapshot.reservation_stock, snapshot.reservations_per_minute),
      color = snapshot.reservations_per_minute > 0 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.reservations_per_minute > 0
        and string.format("%d charger-served prospects retry every %d minutes. Move their physical paperwork to Sales Offices with belts or logistic bots.", snapshot.reservation_prospects, PROSPECT_RESERVATION_RETRY_MINUTES)
        or "No reservations are being printed. Chargers need reachable unsold prospects in operational customer settlements."
    }
  end
  if snapshot.prototype_evs_produced > 0 or snapshot.first_sale_complete then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-prototype-roadster", label = "Roadsters sold",
      value = string.format("%d / 50", snapshot.roadsters_sold),
      color = snapshot.roadsters_sold >= 50 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.roadsters_sold >= 50
        and "Prototype market validation is complete; Premium EV progression may proceed."
        or string.format("Sell %d more Prototype Roadsters to unlock the Premium EV market gate.", math.max(0, 50 - snapshot.roadsters_sold))
    }
  end
  if snapshot.ev_production_researched then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-premium-ev", label = "Premium EVs",
      value = snapshot.premium_evs_produced < snapshot.premium_pilot_production_gate
        and string.format("%d / %d pilot built", snapshot.premium_evs_produced, snapshot.premium_pilot_production_gate)
        or snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate
          and string.format(
            "%d / %d factory built",
            snapshot.premium_evs_produced,
            snapshot.advanced_battery_chemistry_production_gate
          )
          or string.format("%d / 250 sold", snapshot.premium_evs_sold),
      color = snapshot.premium_evs_sold >= 250 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.premium_evs_produced < snapshot.premium_pilot_production_gate
        and string.format(
          "Build %d more Premium EVs with the commodity-battery pilot line to unlock Gigafactory construction.",
          math.max(0, snapshot.premium_pilot_production_gate - snapshot.premium_evs_produced)
        )
        or snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate
          and string.format(
            "Build %d more Premium EVs at factory scale to unlock Advanced Battery Chemistry.",
            math.max(0, snapshot.advanced_battery_chemistry_production_gate - snapshot.premium_evs_produced)
          )
          or string.format(
            "Sell %d more Premium EVs to unlock Mass-market EV production.",
            math.max(0, 250 - snapshot.premium_evs_sold)
          )
    }
  end
  if snapshot.mass_market_researched then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-mass-market-ev", label = "Mass-market EVs",
      value = string.format("%d / 2,000 sold", snapshot.mass_market_evs_sold),
      color = snapshot.mass_market_evs_sold >= 2000 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.mass_market_evs_sold >= 2000
        and "Mass-market scale is proven; Megatruck engineering may proceed."
        or string.format("Sell %d more Mass-market EVs to unlock the Megatruck market gate.", math.max(0, 2000 - snapshot.mass_market_evs_sold))
    }
  end
  if snapshot.autonomous_logistics_researched then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-robotaxi-fleet", label = "Consumer EV scale",
      value = string.format("%d / 5,000 sold", snapshot.consumer_evs_sold),
      color = snapshot.consumer_evs_sold >= 5000 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.consumer_evs_sold >= 5000
        and "Consumer market scale is sufficient for Robotaxi deployment."
        or string.format("Sell %d more consumer EVs of any type to unlock the Robotaxi market gate.", math.max(0, 5000 - snapshot.consumer_evs_sold))
    }
  end
  if snapshot.first_sale_complete then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-mass-market-ev", label = "Active customer EVs", value = tostring(snapshot.customer_ev_fleet),
      tooltip = "Living mobile customers currently assigned a sold EV. Only completed sales add owners; customer deaths remove their vehicle and charging demand."
    }
    market_rows[#market_rows + 1] = {
      sprite = "item/x-ev-charging-station", label = "Charging service",
      value = snapshot.stranded_evs > 0 and string.format("%d EVs underserved", snapshot.stranded_evs)
        or "All owners served",
      color = snapshot.stranded_evs > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good,
      tooltip = snapshot.stranded_evs > 0
        and "Some owners lack powered capacity near their home settlement. Follow the red settlement map tags and add local chargers or grid power."
        or "All EV owners have powered charging capacity near their home settlements."
    }
    if snapshot.angry_settlements > 0 then
      market_rows[#market_rows + 1] = {
        sprite = "entity/biter-spawner", label = "Unhappy settlements",
        value = tostring(snapshot.angry_settlements), color = FACTORYX_STATE_COLORS.bad,
        tooltip = "These settlements exceeded their charging-service patience period. Restore powered local capacity; their hostility clears after service recovers."
      }
    end
    if snapshot.customer_commutes_en_route > 0 or snapshot.customer_commutes_charging > 0
      or snapshot.customer_commutes_completed > 0 then
      market_rows[#market_rows + 1] = {
        sprite = "item/x-prototype-roadster", label = "Charging commutes",
        value = string.format("%d inbound, %d charging", snapshot.customer_commutes_en_route, snapshot.customer_commutes_charging),
        tooltip = "Physical EV owners currently walking to chargers or charging. This is a bounded visual simulation; settlement capacity remains authoritative."
      }
    end
  end
  if snapshot.terrestrial_ai_researched then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-ai-token", label = "AI Tokens generated",
      value = snapshot.terrestrial_ai_next_threshold
        and string.format("%d / %d", snapshot.terrestrial_ai_tokens_generated, snapshot.terrestrial_ai_next_threshold)
        or string.format("%d; terrestrial ceiling", snapshot.terrestrial_ai_tokens_generated),
      tooltip = snapshot.terrestrial_ai_next_threshold
        and "Cumulative terrestrial AI Tokens toward the next automatic 10% efficiency level. Keep Datacenters powered and supplied with Dollars."
        or "Terrestrial AI efficiency has reached its current ceiling. Orbital compute is required for endgame token scale."
    }
  end
  if snapshot.energy_products_researched
    and (snapshot.megapack_energy_settlements > 0
      or snapshot.megapacks_installed_by_customers > 0) then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-megapack",
      label = "Megapack adoption",
      value = string.format(
        "%d / %d installed (%.1f%%)",
        snapshot.megapacks_installed_by_customers,
        snapshot.megapack_energy_population,
        snapshot.megapack_adoption_percent
      ),
      color = snapshot.megapack_adoption_percent >= 99.9 and FACTORYX_STATE_COLORS.good
        or FACTORYX_STATE_COLORS.warning,
      tooltip = "Households inside the 384-tile Megapack market buy once. After the first installation, referrals make another 5% of remaining households eligible every five minutes."
    }
    market_rows[#market_rows + 1] = {
      sprite = "entity/small-biter",
      label = "Energy buyers",
      value = string.format(
        "%d waiting; %d reserved; %d travelling",
        snapshot.megapack_believers_waiting,
        snapshot.megapack_buyers_reserved,
        snapshot.megapack_buyers_in_transit
      ),
      color = snapshot.megapack_believers_waiting > 0 and FACTORYX_STATE_COLORS.good
        or FACTORYX_STATE_COLORS.neutral,
      tooltip = "The physical biter is the Megapack reservation. Buyers walk to the Sales Office, wait for product, then carry it home before the installation is counted."
    }
  end
  if snapshot.planetary_grid_researched then
    market_rows[#market_rows + 1] = {
      sprite = "item/x-agi-training-dataset", label = "AGI training",
      value = snapshot.victory and "Complete"
        or (snapshot.agi_training_unlocked
          and string.format("%d%%", math.floor(snapshot.agi_training_progress * 100))
          or string.format("%d / %d AI Tokens", snapshot.ai_tokens_produced, snapshot.agi_token_gate)),
      color = snapshot.victory and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = snapshot.victory
        and "AGI training completed. Biter Motors's victory condition has been achieved."
        or (snapshot.agi_training_unlocked
          and "The AGI training run is active. Any power shortage resets this run to zero, so maintain full grid reliability."
          or "Generate the required cumulative AI Tokens to unlock the final AGI training run. Orbital compute is intended to provide the necessary scale.")
    }
  end
  add_progress_section(content, "Business", market_rows)

  content.add{type = "line"}
  add_section_heading(content, "Journey")
  local journey_rows = {}
  for _, stage_info in ipairs(progress_stages(snapshot)) do
    journey_rows[#journey_rows + 1] = {
      sprite = stage_info.sprite,
      label = stage_info.name,
      value = stage_info.complete and "Complete" or "Current",
      color = stage_info.complete and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning,
      tooltip = stage_info.complete
        and (stage_info.name .. " is complete.")
        or (stage_info.name .. " is the current progression stage. Follow the objective at the top of this panel.")
    }
    if not stage_info.complete then
      break
    end
  end
  add_progress_metrics(content, journey_rows)
end

local function open_progress_panel(player)
  if not player or not player.valid then
    return
  end
  local existing = player.gui.screen[PROGRESS_PANEL_NAME]
  if existing then
    existing.destroy()
    storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}
    storage.factoryx_progress_panel_signatures[player.index] = nil
    return
  end
  local panel = player.gui.screen.add{
    type = "frame",
    name = PROGRESS_PANEL_NAME,
    direction = "vertical"
  }
  storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}
  storage.factoryx_progress_panel_signatures[player.index] = nil
  panel.auto_center = true
  local titlebar = panel.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = panel
  titlebar.add{type = "label", caption = "Biter Motors Progress", style = "frame_title"}
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
  storage.factoryx_progress_refresh_ticks = storage.factoryx_progress_refresh_ticks or {}
  storage.factoryx_progress_refresh_ticks[player.index] = game.tick
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
    local market = classify_sales_office_market(buyers)
    if market.kind == "no-market" then
      return "No customer settlements", FACTORYX_STATE_COLORS.bad
    elseif market.kind == "saturated" then
      if market.surplus_office then
        return "Surplus Sales Office", FACTORYX_STATE_COLORS.warning
      end
      return "Waiting for market growth", FACTORYX_STATE_COLORS.neutral
    elseif market.kind == "service-blocked" then
      return "Prospects need charging", FACTORYX_STATE_COLORS.bad
    elseif market.kind == "committed" then
      if market.surplus_office then
        return "Surplus Sales Office", FACTORYX_STATE_COLORS.warning
      end
      return "Prospects reserved", FACTORYX_STATE_COLORS.neutral
    elseif market.kind == "unavailable" then
      return "Refreshing prospects", FACTORYX_STATE_COLORS.warning
    elseif buyers.friendly_settlements == 0 then
      return "Customers hostile", FACTORYX_STATE_COLORS.bad
    end
    return "Waiting for buyer", FACTORYX_STATE_COLORS.warning
  end
  local status = entity.status
  if entity.name == SALES_OFFICE_NAME and status == defines.entity_status.working then
    local market = classify_sales_office_market(sales_office_buyer_status(entity))
    if market.kind == "service-blocked" then
      return "Prospects need charging", FACTORYX_STATE_COLORS.bad
    elseif market.surplus_office and (market.kind == "committed" or market.kind == "low") then
      return "Surplus Sales Office", FACTORYX_STATE_COLORS.warning
    end
  end
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
    caption = {"", "Biter Motors ", entity.prototype.localised_name},
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
    add_station_info_label(panel, string.format(
      "Safety learning: %.0f completed rides; %.1f%% lower retirement risk",
      snapshot.completed_rides,
      snapshot.safety_risk_reduction * 100
    ), snapshot.safety_risk_reduction > 0.25 and FACTORYX_STATE_COLORS.good or FACTORYX_STATE_COLORS.warning)
    add_station_info_label(panel, string.format(
      "Expected retirement: one per %.0f operating Robotaxi-hours",
      snapshot.expected_vehicle_hours
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
    local recipe = entity.get_recipe()
    if recipe and recipe.name == MEGAPACK_SALE_RECIPE then
      local energy = megapack_office_status(entity)
      local reserved_unit = megapack_office_reservations()[entity.unit_number]
      local trip = reserved_unit and megapack_buyer_trips()[reserved_unit]
      local trip_text = "None"
      local trip_color = FACTORYX_STATE_COLORS.neutral
      if trip and trip.phase == "to_office" then
        trip_text, trip_color = "Buyer travelling to office", FACTORYX_STATE_COLORS.warning
      elseif trip and trip.phase == "waiting_product" then
        trip_text, trip_color = "Buyer waiting in showroom", FACTORYX_STATE_COLORS.good
      end
      local next_wave = "-"
      if energy.next_referral_tick then
        next_wave = string.format(
          "%d:%02d",
          math.max(0, math.floor((energy.next_referral_tick - game.tick) / 3600)),
          math.max(0, math.floor((energy.next_referral_tick - game.tick) / 60)) % 60
        )
      elseif energy.population > 0 and energy.installed >= energy.population then
        next_wave = "Fully adopted"
      elseif energy.installed == 0 then
        next_wave = "Starts after first install"
      end
      add_factoryx_metric_table(panel, {
        {
          sprite = "entity/biter-spawner",
          label = "Energy settlements",
          value = tostring(energy.settlements),
          color = energy.settlements > 0 and FACTORYX_STATE_COLORS.good
            or FACTORYX_STATE_COLORS.bad,
          tooltip = string.format(
            "Megapack buyers may travel up to %d tiles, three times the normal EV sales radius.",
            MEGAPACK_SALES_RADIUS
          )
        },
        {
          sprite = "entity/small-biter",
          label = "Believers",
          value = string.format("%d waiting; %d reserved", energy.waiting, energy.reserved),
          color = energy.waiting > 0 and FACTORYX_STATE_COLORS.good
            or FACTORYX_STATE_COLORS.neutral,
          tooltip = "Believers are eligible households that have not installed a Megapack. The first 5% are seeded immediately; referrals add 5% of remaining households every five minutes after the first installation."
        },
        {
          sprite = "item/x-megapack",
          label = "Buyer trip",
          value = trip_text,
          color = trip_color,
          tooltip = "The physical buyer is the reservation. The contract starts only after the buyer reaches this Sales Office."
        },
        {
          sprite = "item/x-megapack",
          label = "Installed",
          value = string.format("%d / %d households", energy.installed, energy.population),
          color = energy.installed > 0 and FACTORYX_STATE_COLORS.good
            or FACTORYX_STATE_COLORS.warning,
          tooltip = "A sale counts as installed only after the buyer carries the Megapack home. Each household buys once."
        },
        {
          sprite = "item/x-dollar",
          label = "Energy adoption",
          value = string.format("%.1f%%", energy.adoption_percent),
          color = energy.adoption_percent >= 99.9 and FACTORYX_STATE_COLORS.good
            or FACTORYX_STATE_COLORS.warning
        },
        {
          sprite = "item/x-ev-reservation",
          label = "Next referral wave",
          value = next_wave,
          color = energy.next_referral_tick and FACTORYX_STATE_COLORS.warning
            or FACTORYX_STATE_COLORS.neutral
        }
      })
      local summary
      local summary_color
      if energy.settlements == 0 then
        summary, summary_color = "No customer settlements within the 384-tile energy market.", FACTORYX_STATE_COLORS.bad
      elseif entity.status == defines.entity_status.no_power
        or entity.status == defines.entity_status.low_power then
        summary, summary_color = "Restore Sales Office power.", FACTORYX_STATE_COLORS.bad
      elseif entity.status == defines.entity_status.full_output then
        summary, summary_color = "Clear the Dollar output.", FACTORYX_STATE_COLORS.bad
      elseif trip and trip.phase == "to_office" then
        summary, summary_color = "Energy buyer is travelling to the showroom.", FACTORYX_STATE_COLORS.warning
      elseif trip and trip.phase == "waiting_product" then
        if office_has_all_sale_inputs(entity, recipe) then
          summary, summary_color = "Buyer present. Megapack sale active.", FACTORYX_STATE_COLORS.good
        else
          summary, summary_color = "Buyer present. Deliver one Megapack.", FACTORYX_STATE_COLORS.warning
        end
      elseif energy.installed >= energy.population and energy.population > 0 then
        summary, summary_color = "Energy market fully adopted.", FACTORYX_STATE_COLORS.good
      elseif energy.waiting == 0 then
        summary, summary_color = "Waiting for the next referral wave.", FACTORYX_STATE_COLORS.neutral
      else
        summary, summary_color = "Waiting for a physical energy buyer.", FACTORYX_STATE_COLORS.warning
      end
      add_factoryx_status_strip(panel, summary, summary_color)
      return
    end
    local buyer_status = sales_office_buyer_status(entity)
    local market_state = classify_sales_office_market(buyer_status)
    local sale = recipe and CUSTOMER_EV_SALE_RECIPES[recipe.name]
    local buyer_reservation = office_buyer_reservations()[entity.unit_number]
    local reserved = buyer_reservation and #buyer_reservation.buyers or 0
    local prospect_color = FACTORYX_STATE_COLORS.good
    if market_state.kind == "service-blocked" or market_state.kind == "no-market" then
      prospect_color = FACTORYX_STATE_COLORS.bad
    elseif market_state.kind == "unavailable"
      or (market_state.surplus_office and (
        market_state.kind == "saturated"
          or market_state.kind == "committed"
          or market_state.kind == "low"
      )) then
      prospect_color = FACTORYX_STATE_COLORS.warning
    elseif market_state.kind == "saturated" or market_state.kind == "committed" then
      prospect_color = FACTORYX_STATE_COLORS.neutral
    end
    local prospect_value
    if market_state.remaining == 0 then
      prospect_value = "None remaining"
    elseif market_state.kind == "service-blocked" then
      prospect_value = string.format(
        "%d remaining; %d need charging",
        market_state.remaining,
        market_state.service_blocked
      )
    elseif market_state.available == 0 and market_state.assigned > 0 then
      prospect_value = string.format(
        "%d remaining; %d reserved",
        market_state.remaining,
        market_state.assigned
      )
    else
      prospect_value = string.format(
        "%d remaining; %d unassigned",
        market_state.remaining,
        market_state.available
      )
    end
    local metric_rows = {
      {sprite = "entity/biter-spawner", label = "Settlements", value = tostring(count_customer_settlements_near_office(entity))},
      {
        sprite = "entity/small-biter",
        label = "Prospects",
        value = prospect_value,
        color = prospect_color,
        tooltip = "Prospects have not purchased an EV. Reserved prospects belong to a sale already in progress. Prospects that need charging cannot buy until powered service returns. Overlapping Sales Offices share one prospect pool. Only an office whose entire settlement coverage is duplicated is flagged as surplus; one local office remains for future growth."
      },
      {sprite = "item/x-mass-market-ev", label = "EV owners", value = string.format("%d / %d", buyer_status.owned, buyer_status.customers)},
      {
        sprite = "item/x-ev-charging-station",
        label = "Charging",
        value = string.format(
          "%d EVs; %d spare",
          buyer_status.powered_capacity,
          math.max(0, buyer_status.powered_capacity - buyer_status.owned)
        )
      },
      {sprite = "item/x-ev-charging-station", label = "Underserved", value = tostring(buyer_status.underserved), color = buyer_status.underserved > 0 and FACTORYX_STATE_COLORS.bad or FACTORYX_STATE_COLORS.good},
      {sprite = "item/x-ev-reservation", label = "Reserved", value = sale and string.format("%d / %d", reserved, sale.vehicles) or "-"}
    }
    local next_step = next_customer_charging_step(customer_service_for_force(entity.force), entity)
    if next_step.available then
      metric_rows[#metric_rows + 1] = {
        sprite = "item/accumulator",
        label = "Next charger activation",
        value = string.format(
          "%d EV sale%s: +%.0f kW",
          next_step.ev_owners_until,
          next_step.ev_owners_until == 1 and "" or "s",
          next_step.power_kw
        ),
        color = FACTORYX_STATE_COLORS.neutral,
        tooltip = string.format(
          "Information only: this is the nearest charging threshold in this Sales Office market. No action is required while Charging and Underserved remain healthy. The next %s stall supports %d EVs.",
          next_step.station_name,
          next_step.ev_capacity_added
        )
      }
    elseif next_step.needs_charger then
      metric_rows[#metric_rows + 1] = {
        sprite = "item/accumulator",
        label = "Next charger activation",
        value = "No spare stalls; add charger",
        color = buyer_status.underserved > 0 and FACTORYX_STATE_COLORS.bad
          or FACTORYX_STATE_COLORS.warning
      }
    end
    add_factoryx_metric_table(panel, metric_rows)

    local summary
    local summary_color
    if not recipe then
      summary, summary_color = "Select a sales contract.", FACTORYX_STATE_COLORS.warning
    elseif entity.status == defines.entity_status.no_power or entity.status == defines.entity_status.low_power then
      summary, summary_color = "Restore power.", FACTORYX_STATE_COLORS.bad
    elseif entity.status == defines.entity_status.full_output then
      summary, summary_color = "Clear the Dollar output.", FACTORYX_STATE_COLORS.bad
    elseif entity.disabled_by_script then
      if market_state.kind == "saturated" then
        if market_state.surplus_office then
          summary = "Market saturated. Deconstruct this surplus office; another local office preserves coverage."
          summary_color = FACTORYX_STATE_COLORS.warning
        else
          summary = "Market saturated. Keep this office for future growth or expand sales elsewhere."
          summary_color = FACTORYX_STATE_COLORS.neutral
        end
      elseif market_state.kind == "service-blocked" then
        summary = string.format(
          "Restore charging service for %d prospects.",
          market_state.service_blocked
        )
        summary_color = FACTORYX_STATE_COLORS.bad
      elseif market_state.kind == "committed" then
        if market_state.surplus_office then
          summary = string.format(
            "This surplus office shares %d prospects already reserved by active sales.",
            market_state.remaining
          )
          summary_color = FACTORYX_STATE_COLORS.warning
        else
          summary = string.format(
            "All %d remaining prospects are reserved by active sales.",
            market_state.remaining
          )
          summary_color = FACTORYX_STATE_COLORS.neutral
        end
      elseif market_state.kind == "unavailable" then
        summary = "Refreshing prospect assignments."
        summary_color = FACTORYX_STATE_COLORS.warning
      elseif buyer_status.friendly_settlements == 0 then
        summary = "Restore customer charging service."
        summary_color = FACTORYX_STATE_COLORS.bad
      else
        summary = "Waiting for a prospect."
        summary_color = FACTORYX_STATE_COLORS.neutral
      end
    elseif entity.status == defines.entity_status.working then
      if market_state.surplus_office and market_state.kind == "committed" then
        summary, summary_color = string.format(
          "Sales active, but this office duplicates coverage for all %d remaining prospects.",
          market_state.remaining
        ), FACTORYX_STATE_COLORS.warning
      elseif market_state.surplus_office and market_state.kind == "low" then
        summary, summary_color = string.format(
          "This surplus office shares a nearly saturated market: %d prospects remain (%d%%).",
          market_state.remaining,
          market_state.percent
        ), FACTORYX_STATE_COLORS.warning
      else
        summary, summary_color = "Sales active.", FACTORYX_STATE_COLORS.good
      end
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
    local market = classify_sales_office_market(buyers)
    if market.kind == "saturated" then
      next_step = market.surplus_office
        and "Market saturated: deconstruct this surplus office; another local Sales Office preserves coverage for future growth."
        or "Market saturated: keep this office for future growth, and establish powered charging and Sales Office coverage at another biter settlement."
    elseif market.kind == "service-blocked" then
      next_step = string.format(
        "Blocked: restore powered charging service for %d prospects.",
        market.service_blocked
      )
    elseif market.kind == "committed" then
      next_step = "Waiting: every remaining prospect is reserved by a sale already in progress."
    elseif market.kind == "unavailable" then
      next_step = "Waiting: Biter Motors is refreshing this office's prospect assignments."
    else
      next_step = "Waiting for a prospect."
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
    caption = "Biter Motors Customer Settlement",
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

  if researched(force, "x-energy-products") then
    local energy_covered = false
    for _, office in pairs(offices) do
      if current_recipe_name(office) == MEGAPACK_SALE_RECIPE
        and within_radius(office, settlement, MEGAPACK_SALES_RADIUS) then
        energy_covered = true
        break
      end
    end
    local adoption = megapack_adoption_states()[key]
    if energy_covered then adoption = ensure_megapack_adoption_state(key, population) end
    if adoption then
      local waiting = math.max(
        0,
        (adoption.eligible or 0) - (adoption.installed or 0) - (adoption.reserved or 0)
      )
      add_station_info_label(panel, string.format(
        "Megapack adoption: %d / %d households installed; %d believers waiting",
        adoption.installed or 0,
        settlement_population,
        waiting
      ))
      add_station_info_label(panel, "Megapack energy market: " .. (
        energy_covered and "inside 384-tile sales radius" or "outside current coverage"
      ))
      if adoption.next_referral_tick then
        add_station_info_label(panel, string.format(
          "Next energy referral wave: %d:%02d",
          math.max(0, math.floor((adoption.next_referral_tick - game.tick) / 3600)),
          math.max(0, math.floor((adoption.next_referral_tick - game.tick) / 60)) % 60
        ))
      end
    end
  end

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
  local grid_connected = station_has_grid_access(station)
  local power_state = station.unit_number and station_power_service()[station.unit_number] or nil
  local requested_stalls = power_state and power_state.requested_stalls or 0
  local powered_stalls = power_state and power_state.powered_stalls or 0
  for _, player in pairs(game.connected_players) do
    if player.valid and player.surface == station.surface and player.force == station.force then
      player.remove_alert{
        entity = station,
        type = defines.alert_type.custom
      }
      if not grid_connected then
        player.add_custom_alert(
          station,
          {type = "item", name = station.name},
          {"", station.prototype.localised_name, " is not connected to power."},
          true
        )
      elseif requested_stalls > powered_stalls then
        player.add_custom_alert(
          station,
          {type = "item", name = "accumulator"},
          {
            "",
            station.prototype.localised_name,
            " has power for ",
            powered_stalls,
            " / ",
            requested_stalls,
            " active stalls. Increase grid generation or storage."
          },
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
    message = "[Biter Motors] " .. config.display_name .. " placed. Connect it within 18 tiles of your electric grid before it can create biter customer demand."
  elseif covered_settlements > 0 then
    local active_stalls = active_station_stalls(entity)
    unlock_roadster_sales(entity.force)
    message = string.format(
      "[Biter Motors] %s online: %d/%d stalls active from %d covered biter customer settlements. %s",
      config.display_name,
      active_stalls,
      config.stalls,
      covered_settlements,
      station_next_step(entity, covered_settlements, hostile_settlements, #find_sales_offices(entity.force))
    )
  else
    if hostile_settlements > 0 then
      message = string.format(
        "[Biter Motors] %s online, but %d nearby spawners are still hostile. Put a Sales Office within %d tiles to convert them into customers.",
        config.display_name,
        hostile_settlements,
        SALES_OFFICE_CUSTOMER_RADIUS
      )
    else
      message = string.format("[Biter Motors] %s online, but no Sales Office-converted customer settlements are within %d tiles.", config.display_name, config.customer_radius)
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
  local road_rage = road_rage_force()

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
      force.set_cease_fire(road_rage, false)
      road_rage.set_cease_fire(force, false)
      force.set_friend(road_rage, false)
      road_rage.set_friend(force, false)
    end
  end
  customers.set_cease_fire(road_rage, true)
  road_rage.set_cease_fire(customers, true)
  customers.set_friend(road_rage, true)
  road_rage.set_friend(customers, true)
  if enemy then
    customers.set_cease_fire(enemy, true)
    enemy.set_cease_fire(customers, true)
    customers.set_friend(enemy, false)
    enemy.set_friend(customers, false)
    road_rage.set_cease_fire(enemy, true)
    enemy.set_cease_fire(road_rage, true)
    road_rage.set_friend(enemy, false)
    enemy.set_friend(road_rage, false)
  end
end

script.on_init(function()
  storage.factoryx_ev_autopilot = EvAutopilot.ensure(nil)
  configure_factoryx_new_game()
  apply_factoryx_enemy_pressure_settings()
  cleanup_legacy_station_grid_connections()
  rebuild_factoryx_entity_registries()
  rebuild_electric_vehicles()
  rebuild_electric_semi_runtime()
  rebuild_grid_controllers()
  rebuild_factoryx_compute_machines()
  rebuild_sales_offices()
  rebuild_customer_vehicle_aggregates()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  storage.factoryx_customer_lifecycle_version = CUSTOMER_LIFECYCLE_VERSION
  storage.factoryx_last_reservation_reconcile_tick = nil
  reconcile_office_buyer_reservations()
  storage.factoryx_last_reservation_reconcile_tick = game.tick
  rebuild_customer_buyer_queues()
  sync_sales_office_buyers()
  rebuild_customer_commute_queue()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
    if player.gui.screen[PROGRESS_PANEL_NAME] then
      storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}
      storage.factoryx_progress_panel_signatures[player.index] = nil
      refresh_progress_panel(player)
      storage.factoryx_progress_refresh_ticks = storage.factoryx_progress_refresh_ticks or {}
      storage.factoryx_progress_refresh_ticks[player.index] = game.tick
    end
  end
  track_ai_efficiency_progress()
  queue_customer_vehicle_variant_migration()
  rebuild_factoryx_runtime_visuals()
  rebuild_charger_stall_visuals()
  rebuild_sales_office_showrooms()
end)

script.on_configuration_changed(function()
  reset_active_ev_autopilots()
  apply_factoryx_enemy_pressure_settings()
  reset_charger_hover_overlays()
  cleanup_legacy_station_grid_connections()
  rebuild_factoryx_entity_registries()
  rebuild_electric_vehicles()
  rebuild_electric_semi_runtime()
  rebuild_grid_controllers()
  rebuild_factoryx_compute_machines()
  rebuild_sales_offices()
  rebuild_customer_vehicle_aggregates()
  sync_all_force_unlocks()
  sync_biter_customer_diplomacy()
  sync_customer_settlements()
  storage.factoryx_customer_lifecycle_version = nil
  reconcile_customer_lifecycle_state()
  storage.factoryx_last_reservation_reconcile_tick = nil
  reconcile_office_buyer_reservations()
  storage.factoryx_last_reservation_reconcile_tick = game.tick
  rebuild_customer_buyer_queues()
  sync_sales_office_buyers()
  rebuild_customer_commute_queue()
  refresh_all_sales_office_coverage()
  for _, player in pairs(game.players) do
    sync_charger_placement_overlay(player)
    if player.gui.screen[PROGRESS_PANEL_NAME] then
      storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}
      storage.factoryx_progress_panel_signatures[player.index] = nil
      refresh_progress_panel(player)
      storage.factoryx_progress_refresh_ticks = storage.factoryx_progress_refresh_ticks or {}
      storage.factoryx_progress_refresh_ticks[player.index] = game.tick
    end
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
  if event.prototype_name == EV_AUTOPILOT_SUMMON_SHORTCUT then
    summon_recent_ev(player)
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

script.on_event(defines.events.on_selected_entity_changed, function(event)
  sync_charger_hover_overlay(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.get_player(event.player_index)
  local prior_state = player and ev_driver_overlay_states()[player.index]
  local prior_vehicle = prior_state and prior_state.vehicle
  local vehicle = player and player.vehicle
  local changed_vehicle = event.entity
  if changed_vehicle and changed_vehicle.valid and changed_vehicle.unit_number then
    local state = ev_autopilot_runtime().active[changed_vehicle.unit_number]
    if state and state.mode == "summon" and vehicle == changed_vehicle then
      cancel_ev_autopilot(state.unit_number, nil, {notify = false, manual = true})
    elseif state and state.mode == "navigate"
      and state.player_index == player.index
      and vehicle ~= changed_vehicle then
      cancel_ev_autopilot(state.unit_number, nil, {notify = false})
    end
  end
  if is_ev_autopilot_eligible(vehicle) and player_is_vehicle_driver(player, vehicle) then
    remember_player_ev(player, vehicle)
  end
  if vehicle then
    destroy_ev_battery_popup(player.index)
  else
    show_ev_battery_popup(player, prior_vehicle)
  end
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
  if trigger_customer_road_rage(event) then return end
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

script.on_event(defines.events.on_chunk_generated, function(event)
  register_factoryx_reconciliation_chunk(event.surface, event.position)
end)

script.on_event(defines.events.on_ai_command_completed, function(event)
  if not handle_megapack_buyer_command_completed(event) then
    handle_customer_commute_command_completed(event)
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  release_charger_hover_overlay(event.player_index)
  sync_charger_placement_overlay(player)
  refresh_sales_office_coverage(player)
  refresh_progress_panel(player)
end)

script.on_event(defines.events.on_player_left_game, function(event)
  cancel_player_ev_autopilots(event.player_index, "controlling player disconnected", false)
  release_charger_hover_overlay(event.player_index)
  charger_placement_overlay_states()[event.player_index] = nil
  opened_factoryx_entities()[event.player_index] = nil
  destroy_ev_driver_overlay(event.player_index)
end)

script.on_event(defines.events.on_player_removed, function(event)
  remove_player_ev_autopilot_history(event.player_index)
  release_charger_hover_overlay(event.player_index)
  charger_placement_overlay_states()[event.player_index] = nil
  opened_factoryx_entities()[event.player_index] = nil
  destroy_ev_driver_overlay(event.player_index)
  sales_office_coverage_enabled()[event.player_index] = nil
  storage.factoryx_charger_overlay_warnings = storage.factoryx_charger_overlay_warnings or {}
  storage.factoryx_charger_overlay_warnings[event.player_index] = nil
  storage.factoryx_progress_panel_signatures = storage.factoryx_progress_panel_signatures or {}
  storage.factoryx_progress_panel_signatures[event.player_index] = nil
  storage.factoryx_progress_refresh_ticks = storage.factoryx_progress_refresh_ticks or {}
  storage.factoryx_progress_refresh_ticks[event.player_index] = nil
end)

script.on_event(defines.events.on_player_changed_force, function(event)
  local player = game.get_player(event.player_index)
  cancel_player_ev_autopilots(event.player_index, "player changed force", true)
  refresh_sales_office_coverage(player)
  refresh_progress_panel(player)
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  cancel_player_ev_autopilots(event.player_index, "player changed surface", true)
end)

script.on_event(defines.events.on_player_selected_area, handle_ev_autopilot_destination)
script.on_event(defines.events.on_player_alt_selected_area, handle_ev_autopilot_destination)
script.on_event(defines.events.on_script_path_request_finished, handle_ev_autopilot_path_result)

for input_name in pairs(EV_AUTOPILOT_MANUAL_INPUTS) do
  script.on_event(input_name, function(event)
    cancel_player_ev_autopilot_manual(game.get_player(event.player_index))
  end)
end

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
	      track_electric_semi_runtime(entity, true)
	      attach_factoryx_runtime_visual(entity)
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

function spill_player_vehicle_battery_scrap(entity)
  local scrap = entity and entity.valid and PLAYER_VEHICLE_BATTERY_SCRAP[entity.name]
  if not scrap then return end
  local produced = false
  for item_name, count in pairs(scrap) do
    entity.surface.spill_item_stack{
      position = entity.position,
      stack = {name = item_name, count = count},
      enable_looted = true,
      force = entity.force
    }
    produced = true
  end
  if produced then unlock_battery_material_recovery(entity.force) end
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
	      local removed_customer_settlement =
	        entity and entity.valid and BITER_SETTLEMENT_NAMES[entity.name] or false
	      if event_name == defines.events.on_entity_died then spill_player_vehicle_battery_scrap(entity) end
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
          local semi_charge_count = event.buffer.get_item_count(ELECTRIC_SEMI_FUEL_NAME)
          if semi_charge_count > 0 then
            event.buffer.remove{name = ELECTRIC_SEMI_FUEL_NAME, count = semi_charge_count}
          end
        end
      end
      if entity and entity.valid and entity.unit_number and customer_unit_registry()[entity.unit_number] then
        destroy_customer_marker(entity)
        unregister_customer_unit(entity)
      end
      if entity and entity.unit_number and ELECTRIC_VEHICLE_BATTERIES[entity.name] then
        remove_ev_from_autopilot_history(entity.unit_number)
        electric_vehicle_registry()[entity.unit_number] = nil
        if storage.factoryx_vehicle_charge_activity then
          storage.factoryx_vehicle_charge_activity[entity.unit_number] = nil
        end
      end
      if entity and entity.unit_number then
	        local semi_runtime = electric_semi_runtime()
	        semi_runtime.semis[entity.unit_number] = nil
	        semi_runtime.batteries[entity.unit_number] = nil
	        semi_runtime.stops[entity.unit_number] = nil
	        semi_runtime.stop_ticks[entity.unit_number] = nil
	        local semi_power = semi_runtime.stop_power[entity.unit_number]
	        if semi_power and semi_power.valid then semi_power.destroy() end
	        semi_runtime.stop_power[entity.unit_number] = nil
        untrack_factoryx_entity(entity)
        destroy_factoryx_runtime_visual(entity.unit_number)
        destroy_charger_stall_visuals(entity.unit_number)
        destroy_sales_office_showroom_rendering(entity.unit_number)
        factoryx_compute_machines()[entity.unit_number] = nil
        factoryx_compute_power_failures()[entity.unit_number] = nil
        factoryx_compute_queue().members[entity.unit_number] = nil
      end
      if removed_customer_settlement then
        for _, force in pairs(game.forces) do
          if player_market_force(force) then
            mark_factoryx_market_dirty(force, "settlement-removed")
          end
        end
      elseif entity and entity.valid then
        mark_factoryx_market_dirty(entity.force, "entity-removed")
      end
      if is_station(entity) then
        reservation_print_progress()[entity.unit_number] = nil
        customer_growth_states()[entity.unit_number] = nil
        remove_station_support_entities(entity)
      elseif entity and entity.name == SALES_OFFICE_NAME then
        local megapack_unit = megapack_office_reservations()[entity.unit_number]
        if megapack_unit then clear_megapack_buyer_trip(megapack_unit, true) end
        clear_office_buyer_reservation(entity.unit_number)
        sales_office_market_states()[entity.unit_number] = nil
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

script.on_event(defines.events.on_object_destroyed, function(event)
  if event.type == defines.target_type.entity and event.useful_id
    and customer_unit_registry()[event.useful_id] then
    unregister_customer_unit_number(event.useful_id)
  end
end)


script.on_nth_tick(1, function()
  reset_underpowered_compute_progress()
  process_ev_autopilots()
end)

script.on_nth_tick(6, update_ev_battery_popups)
script.on_nth_tick(6, process_electric_semi_runtime)

script.on_nth_tick(30, function()
  reconcile_factoryx_entity_registry_step()
  update_factoryx_runtime_visuals()
  update_charger_stall_visuals()
  update_sales_office_showrooms()
  refresh_ev_driver_overlays()
  update_ev_reverse_warnings()
  feed_tracked_electric_vehicles()
  accelerate_consumer_ev_sales()
  check_first_prototype_sales()
  for _, force in pairs(game.forces) do
    finish_completed_agi_training(force)
  end
end)

script.on_nth_tick(60, function()
  process_customer_road_rage()
  ensure_native_station_power_model()
  track_ai_efficiency_progress()
  process_robotaxi_service_centers()
  process_customer_vehicle_variant_migration(50)
  if storage.factoryx_sales_office_coverage_dirty then
    refresh_all_sales_office_coverage()
  end
  for _, force in pairs(game.forces) do
    if player_market_force(force) then
      sync_foundry_power_gate(force, true)
      process_customer_growth(force)
      sync_advanced_battery_chemistry_gate(force, true)
      sync_gigafactory_production_gate(force, true)
    end
  end
  sync_sales_office_buyers()
  local allocations_by_force = {}
  local services_by_force = {}
  for _, surface in pairs(game.surfaces) do
    for _, station in pairs(find_stations(surface)) do
      local force_index = station.force.index
      if not allocations_by_force[force_index] then
        allocations_by_force[force_index] = calculate_station_utilization(station.force)
        services_by_force[force_index] = customer_service_for_force(station.force)
      end
      refresh_station_power_state(station, allocations_by_force[force_index])
      sample_station_power_service(station)
      charge_station_vehicles(station)
      update_station_alerts(station)
      if not first_prototype_sale_unlocked(station.force)
        and station.valid and count_biter_settlements_near_station(station) > 0 then
        unlock_roadster_sales(station.force)
      end
    end
  end
  for force_index in pairs(allocations_by_force) do
    local force = game.forces[force_index]
    generate_station_reservations(force, services_by_force[force_index])
  end
  process_customer_charging_commutes()
end)

script.on_nth_tick(UiRefresh.interval_ticks, function()
  storage.factoryx_progress_refresh_ticks = storage.factoryx_progress_refresh_ticks or {}
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
    if player.gui.screen[PROGRESS_PANEL_NAME]
      and UiRefresh.should_refresh_progress(
        storage.factoryx_progress_refresh_ticks[player.index],
        game.tick
      ) then
      refresh_progress_panel(player)
      storage.factoryx_progress_refresh_ticks[player.index] = game.tick
    end
  end
end)

script.on_nth_tick(600, function()
  if storage.factoryx_enemy_pressure_version ~= FACTORYX_ENEMY_PRESSURE_VERSION then
    apply_factoryx_enemy_pressure_settings()
  end
  local lifecycle = reconcile_customer_lifecycle_state()
  if lifecycle.repaired then sync_sales_office_buyers() end
  sync_biter_customer_diplomacy()
  sync_customer_service_states()
  update_sales_office_market_alerts()
end)

remote.add_interface("factoryx", {
  relieve_enemy_pressure = function(max_evolution)
    return relieve_factoryx_enemy_pressure(max_evolution)
  end,
  enemy_pressure_status = function()
    local map_settings = game.map_settings
    return {
      attack_pollution_cost =
        map_settings.pollution.enemy_attack_pollution_consumption_modifier,
      max_gathering_groups = map_settings.unit_group.max_gathering_unit_groups,
      max_group_size = map_settings.unit_group.max_unit_group_size,
      min_expansion_cooldown =
        map_settings.enemy_expansion.min_expansion_cooldown,
      max_expansion_cooldown =
        map_settings.enemy_expansion.max_expansion_cooldown,
      pollution_evolution_factor =
        map_settings.enemy_evolution.pollution_factor
    }
  end,
  premium_ev_production_history = function(force_name)
    local force = game.forces[force_name or "player"]
    return force and premium_ev_production_history_status(force) or nil
  end,
  ev_autopilot_status = function(player_index)
    return ev_autopilot_status(player_index or 1)
  end,
  test_ev_autopilot_start = function(player_index, unit_number, goal, mode)
    if not script.active_mods["factoryx_smoke"] then return false end
    local vehicle = electric_vehicle_registry()[unit_number]
    if not is_ev_autopilot_eligible(vehicle) or not goal then return false end
    return activate_ev_autopilot(vehicle, goal, mode or "summon", player_index, true)
  end,
  test_ev_autopilot_remember = function(player_index, unit_number)
    if not script.active_mods["factoryx_smoke"] then return false end
    local player = game.get_player(player_index or 1)
    local vehicle = electric_vehicle_registry()[unit_number]
    return remember_player_ev(player, vehicle)
  end,
  test_ev_autopilot_summon = function(player_index)
    if not script.active_mods["factoryx_smoke"] then return false end
    return summon_recent_ev(game.get_player(player_index or 1))
  end,
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
  electric_semi_status = function(force_name)
    local force = game.forces[force_name or "player"]
    if not force then return nil end
    local runtime = electric_semi_runtime()
    local result = {}
    for unit_number, semi in pairs(runtime.semis) do
      if semi and semi.valid and semi.force == force then
        local battery = runtime.batteries[unit_number] or {}
        result[#result + 1] = {
          unit_number = unit_number,
          surface = semi.surface.name,
          position = semi.position,
          battery_joules = battery.energy or 0,
          battery_percent = math.floor((battery.energy or 0) * 1000 / SEMI_BATTERY_CAPACITY + 0.5) / 10,
          traction_used_joules = battery.traction_used or 0,
          regenerated_joules = battery.regenerated or 0,
          reserve_mode = battery.reserve_mode == true,
          reserve_speed_limit = SEMI_RESERVE_SPEED,
          speed = semi.speed
        }
      end
    end
    return result
  end,
  test_electric_semi_reserve = function(unit_number, energy, speed)
    if not script.active_mods["factoryx_smoke"] then return false end
    local runtime = electric_semi_runtime()
    local semi = runtime.semis[unit_number]
    local battery = runtime.batteries[unit_number]
    if not semi or not semi.valid or not battery then return false end
    battery.energy = math.max(0, math.min(SEMI_BATTERY_CAPACITY, energy or 0))
    battery.last_speed = math.abs(speed or 0)
    battery.last_tick = game.tick - 6
    local train = semi.train
    if not train or not train.valid then return false end
    train.speed = speed or 0
    process_electric_semi(semi, battery)
    return {
      reserve_mode = battery.reserve_mode == true,
      speed = math.abs(semi.speed or 0),
      speed_limit = SEMI_RESERVE_SPEED,
      has_drive_permission = semi.burner and (
        semi.burner.currently_burning ~= nil
          or semi.burner.inventory.get_item_count(ELECTRIC_SEMI_FUEL_NAME) > 0
      ) or false
    }
  end,
  test_customer_road_rage = function(unit_number, target, duration_ticks)
    if not script.active_mods["factoryx_smoke"] then return false end
    local entity = customer_unit_registry()[unit_number]
    if not entity or not entity.valid or not target or not target.valid then return false end
    local enraged = enrage_customer(entity, target, nil, duration_ticks or 120)
    local command = entity.commandable and entity.commandable.command
    return {
      enraged = enraged == true,
      force = entity.force.name,
      attacking = command and command.type == defines.command.attack or false,
      scheduled = customer_road_rage_states()[unit_number] ~= nil
    }
  end,
  test_charger_allocator = function()
    if not script.active_mods["factoryx_smoke"] then return nil end
    local specs = {}
    for station_key = 1, 3 do
      specs[#specs + 1] = {
        key = station_key,
        station = station_key,
        stalls = 4,
        evs_per_stall = 12,
        candidates = {{key = "settlement", settlement = "settlement", distance = station_key}}
      }
    end
    local allocation = ChargerAllocator.allocate(specs, {settlement = 44})
    local active_by_station = {}
    for station_key = 1, 3 do
      active_by_station[station_key] =
        allocation.assignments[station_key].customer_requested_stalls
    end
    local requested_capacity =
      allocation.requested_capacity_by_settlement_key.settlement or 0
    return {
      active_by_station = active_by_station,
      requested_capacity = requested_capacity,
      underserved = math.max(0, 44 - requested_capacity)
    }
  end,
  test_sales_office_market = function()
    if not script.active_mods["factoryx_smoke"] then return nil end
    local market = SalesOfficeMarket.classify({
      {key = 10, settlement_keys = {a = true, b = true}},
      {key = 20, settlement_keys = {a = true, b = true}},
      {key = 30, settlement_keys = {c = true}},
      {key = 40, settlement_keys = {b = true, d = true}},
      {key = 50, settlement_keys = {a = true}}
    })
    return {
      keeper_retained = not market.by_office[10].surplus_office,
      duplicate_flagged = market.by_office[20].surplus_office,
      isolated_retained = not market.by_office[30].surplus_office,
      unique_edge_retained = not market.by_office[40].surplus_office,
      partial_duplicate_flagged = market.by_office[50].surplus_office,
      shared_market_offices = market.by_office[10].market_office_count
    }
  end,
  test_customer_registered = function(unit_number)
    if not script.active_mods["factoryx_smoke"] then return nil end
    local entity = customer_unit_registry()[unit_number]
    return entity ~= nil and entity.valid
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
  megapack_adoption_status = function(force_name)
    local force = game.forces[force_name or "player"]
    return force and megapack_adoption_summary(force) or nil
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
      local buyer_status = sales_office_buyer_status(office)
      rows[#rows + 1] = {
        unit_number = office.unit_number,
        position = office.position,
        disabled = office.disabled_by_script,
        recipe = office.get_recipe() and office.get_recipe().name,
        has_inputs = office.get_recipe() and office_has_all_sale_inputs(office, office.get_recipe()) or false,
        crafting_progress = office.crafting_progress,
        buyer_status = buyer_status,
        market_state = classify_sales_office_market(buyer_status),
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

commands.add_command("factoryx-status", "Open or report Biter Motors progression status.", function(command)
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
  rcon.print(string.format("[Biter Motors] %s: %s %s", stage, objective, detail))
end)

commands.add_command("factoryx-note", "Record a timestamped Biter Motors playtest note.", function(command)
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
  player.print("[Biter Motors] Playtest note recorded.")
end)

commands.add_command("factoryx-coverage", "Report Biter Motors EV charging grid connections.", function(command)
  local player = command.player_index and game.get_player(command.player_index)
  local force = player and player.force or game.forces.player
  local stations = count_entities(force, STATION_NAMES)
  local market = biter_customer_market_summary(force)
  local offices = #find_sales_offices(force)

  local message
  if market.biter_customer_mode then
    message = string.format(
      "[Biter Motors] Biter customer market: %d customer EVs, %d prospects, %d/%d stations grid-connected, %d covered biter settlements, %d/%d active charging stalls, %d active EV Sales Offices, %.1f EV Reservations printed at chargers per minute.",
      market.customer_ev_fleet,
      market.customer_prospects,
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
      "[Biter Motors] EV charging capacity: %d customer EVs, %d/%d stations grid-connected, %d active EV Sales Offices, %.1f EV Reservations printed at chargers per minute.",
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
