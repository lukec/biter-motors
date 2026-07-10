local function icon64(path, tint)
  return {
    {
      icon = path,
      icon_size = 64,
      tint = tint
    }
  }
end

local function layered_icon64(base, overlay, base_tint, overlay_tint)
  return {
    {
      icon = base,
      icon_size = 64,
      tint = base_tint
    },
    {
      icon = overlay,
      icon_size = 64,
      scale = 0.35,
      shift = {8, 8},
      tint = overlay_tint
    }
  }
end

local function tech_icon(path)
  return {
    {
      icon = path,
      icon_size = 256
    }
  }
end

local function generated_icon(slug)
  return {
    {
      icon = "__factoryx__/graphics/icons/" .. slug .. ".png",
      icon_size = 256
    }
  }
end

local function sale_icon(product_icons)
  local icons = table.deepcopy(product_icons)
  table.insert(icons, {
    icon = "__base__/graphics/icons/coin.png",
    icon_size = 64,
    scale = 0.35,
    shift = {8, 8},
    tint = {r = 1.0, g = 0.86, b = 0.25, a = 1.0}
  })
  return icons
end

local function generated_entity_animation(slug, scale)
  return {
    animation = {
      layers = {
        {
          filename = "__factoryx__/graphics/entity/" .. slug .. "/" .. slug .. ".png",
          priority = "high",
          width = 512,
          height = 512,
          frame_count = 1,
          line_length = 1,
          shift = {0, -0.2},
          scale = scale or 0.18
        }
      }
    }
  }
end

local function generated_entity_picture(slug, tint, scale, extra_layers)
  local layers = {
    {
      filename = "__factoryx__/graphics/entity/" .. slug .. "/" .. slug .. ".png",
      priority = "high",
      width = 512,
      height = 512,
      shift = {0, 0},
      scale = scale or 0.18,
      tint = tint
    }
  }
  for _, layer in pairs(extra_layers or {}) do
    layers[#layers + 1] = layer
  end
  return {layers = layers}
end

local function tint_animation_masks(value, primary, secondary)
  if type(value) ~= "table" then
    return
  end
  local is_mask = false
  for _, flag in pairs(value.flags or {}) do
    if flag == "mask" then
      is_mask = true
      break
    end
  end
  if is_mask then
    value.tint = value.tint_as_overlay and secondary or primary
  end
  for key, child in pairs(value) do
    if key ~= "tint" and key ~= "flags" then
      tint_animation_masks(child, primary, secondary)
    end
  end
end

local function gigafactory_animation(filename)
  return {
    animation = {
      layers = {
        {
          filename = filename or "__factoryx__/graphics/entity/gigafactory/gigafactory.png",
          priority = "high",
          width = 1024,
          height = 1024,
          frame_count = 1,
          line_length = 1,
          shift = {0, 0},
          scale = 0.325
        }
      }
    }
  }
end

local function customer_radius_visualisation(distance)
  return {
    sprite = {
      filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
      width = 12,
      height = 12,
      priority = "extra-high-no-scale",
      tint = {r = 0.25, g = 0.85, b = 1.0, a = 0.35}
    },
    distance = distance,
    draw_in_cursor = true,
    draw_on_selection = true
  }
end

local function item(name, icons, subgroup, order, stack_size, extra)
  local prototype = {
    type = "item",
    name = name,
    icons = icons,
    subgroup = subgroup,
    order = order,
    stack_size = stack_size or 100
  }
  for key, value in pairs(extra or {}) do
    prototype[key] = value
  end
  return prototype
end

local function recipe(name, categories, subgroup, order, ingredients, results, energy_required, extra)
  if #ingredients > 4 then
    error("FactoryX recipe " .. name .. " has more than four ingredients")
  end
  local prototype = {
    type = "recipe",
    name = name,
    categories = categories,
    subgroup = subgroup,
    order = order,
    enabled = false,
    ingredients = ingredients,
    results = results,
    energy_required = energy_required or 1
  }
  for key, value in pairs(extra or {}) do
    prototype[key] = value
  end
  return prototype
end

local function unlock(recipe_name)
  return {
    type = "unlock-recipe",
    recipe = recipe_name
  }
end

local function tech(name, icon, prerequisites, effects, count, ingredients, time)
  return {
    type = "technology",
    name = name,
    icons = tech_icon(icon),
    prerequisites = prerequisites,
    effects = effects,
    unit = {
      count = count,
      ingredients = ingredients,
      time = time or 30
    }
  }
end

local function infinite_tech(name, icon, prerequisites, effects, count_formula, ingredients, time)
  return {
    type = "technology",
    name = name,
    icons = tech_icon(icon),
    prerequisites = prerequisites,
    effects = effects,
    max_level = "infinite",
    unit = {
      count_formula = count_formula,
      ingredients = ingredients,
      time = time or 30
    }
  }
end

local function add_lab_input(lab_name, input_name)
  local lab = data.raw.lab and data.raw.lab[lab_name]
  if not lab or not lab.inputs then
    return
  end
  for _, existing in pairs(lab.inputs) do
    if existing == input_name then
      return
    end
  end
  table.insert(lab.inputs, input_name)
end

local function copied_assembler(source_name, new_name, icons, minable_result, categories, energy_usage, crafting_speed)
  local prototype = table.deepcopy(data.raw["assembling-machine"][source_name])
  prototype.name = new_name
  prototype.icons = icons
  prototype.icon = nil
  prototype.minable = {mining_time = 0.2, result = minable_result}
  prototype.fast_replaceable_group = new_name
  prototype.next_upgrade = nil
  prototype.crafting_categories = categories
  prototype.crafting_speed = crafting_speed or 1
  prototype.energy_usage = energy_usage
  prototype.module_slots = 0
  prototype.allowed_effects = {"consumption", "speed", "pollution", "quality"}
  prototype.fluid_boxes = nil
  prototype.fluid_boxes_off_when_no_fluid_recipe = nil
  return prototype
end

local function copied_reservation_output_site(source_name, new_name, icons, minable_result)
  local source = data.raw["electric-pole"][source_name]
  local prototype = table.deepcopy(data.raw["logistic-container"]["passive-provider-chest"])
  prototype.name = new_name
  prototype.icons = icons
  prototype.icon = nil
  prototype.flags = {"placeable-neutral", "player-creation"}
  prototype.minable = {mining_time = 0.1, result = minable_result}
  prototype.max_health = source.max_health or 200
  prototype.corpse = source.corpse
  prototype.dying_explosion = source.dying_explosion
  prototype.resistances = table.deepcopy(source.resistances)
  prototype.collision_box = table.deepcopy(source.collision_box)
  prototype.selection_box = table.deepcopy(source.selection_box)
  prototype.damaged_trigger_effect = table.deepcopy(source.damaged_trigger_effect)
  prototype.drawing_box_vertical_extension = source.drawing_box_vertical_extension
  prototype.impact_category = source.impact_category
  prototype.inventory_size = 1
  prototype.logistic_mode = "passive-provider"
  prototype.render_not_in_network_icon = false
  prototype.fast_replaceable_group = new_name
  prototype.next_upgrade = nil
  return prototype
end

local function copied_energy_entity(prototype_type, source_name, new_name, icons, minable_result)
  local prototype = table.deepcopy(data.raw[prototype_type][source_name])
  prototype.name = new_name
  prototype.icon = nil
  prototype.icons = icons
  prototype.minable = {mining_time = 0.2, result = minable_result}
  prototype.fast_replaceable_group = new_name
  prototype.next_upgrade = nil
  return prototype
end

local function copied_electric_vehicle(name, icons, primary, secondary, consumption, weight)
  local prototype = table.deepcopy(data.raw.car.car)
  prototype.name = name
  prototype.icon = nil
  prototype.icons = icons
  prototype.minable = {mining_time = 0.4, result = name}
  prototype.equipment_grid = "medium-equipment-grid"
  prototype.energy_source = {
    type = "burner",
    fuel_categories = {"x-electric-drive"},
    effectivity = 1,
    fuel_inventory_size = 1,
    emissions_per_minute = {}
  }
  prototype.consumption = consumption
  prototype.weight = weight
  tint_animation_masks(prototype.animation, primary, secondary)
  tint_animation_masks(prototype.turret_animation, primary, secondary)
  return prototype
end

local function shifted_two_thirds_scale_sprite_layer(source, x, y)
  local layer = table.deepcopy(source)
  local shift = layer.shift or {0, 0}
  local shift_x = shift.x or shift[1] or 0
  local shift_y = shift.y or shift[2] or 0
  layer.scale = (layer.scale or 1) * (2 / 3)
  layer.shift = {x + shift_x * (2 / 3), y + shift_y * (2 / 3)}
  return layer
end

local function tiled_high_density_solar_sprite(source)
  local tiled = {layers = {}}
  for _, y in pairs({-1, 1}) do
    for _, x in pairs({-1, 1}) do
      for _, source_layer in pairs(source.layers or {}) do
        tiled.layers[#tiled.layers + 1] = shifted_two_thirds_scale_sprite_layer(source_layer, x, y)
      end
    end
  end
  return tiled
end

local function hidden_grid_connection_pole()
  local prototype = table.deepcopy(data.raw["electric-pole"]["medium-electric-pole"])
  prototype.name = "x-ev-charging-grid-connection"
  prototype.icon = nil
  prototype.icons = generated_icon("ev-charging-station")
  prototype.hidden = true
  prototype.flags = {
    "placeable-off-grid",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "not-flammable"
  }
  prototype.selectable_in_game = false
  prototype.minable = nil
  prototype.collision_box = {{0, 0}, {0, 0}}
  prototype.selection_box = {{0, 0}, {0, 0}}
  prototype.collision_mask = {layers = {}}
  prototype.maximum_wire_distance = 18
  prototype.supply_area_distance = 1
  prototype.connection_points = {
    {
      shadow = {
        copper = {0, 0},
        green = {0, 0},
        red = {0, 0}
      },
      wire = {
        copper = {0, 0},
        green = {0, 0},
        red = {0, 0}
      }
    }
  }
  prototype.pictures = {
    layers = {
      {
        filename = "__factoryx__/graphics/entity/transparent.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        direction_count = 1
      }
    }
  }
  prototype.radius_visualisation_picture = nil
  prototype.water_reflection = nil
  return prototype
end

local function hidden_ev_charging_power_sink(name, power_kw)
  local power = tostring(power_kw) .. "kW"
  local buffer = tostring(power_kw) .. "kJ"
  return {
    type = "electric-energy-interface",
    name = name,
    icon = "__factoryx__/graphics/icons/ev-charging-station.png",
    icon_size = 256,
    hidden = true,
    flags = {
      "placeable-off-grid",
      "not-on-map",
      "not-blueprintable",
      "not-deconstructable",
      "not-flammable"
    },
    selectable_in_game = false,
    max_health = 150,
    collision_box = {{0, 0}, {0, 0}},
    selection_box = {{0, 0}, {0, 0}},
    collision_mask = {layers = {}},
    gui_mode = "none",
    allow_copy_paste = false,
    energy_source = {
      type = "electric",
      buffer_capacity = buffer,
      usage_priority = "secondary-input",
      input_flow_limit = power,
      output_flow_limit = "0kW"
    },
    energy_production = "0kW",
    energy_usage = power,
    picture = {
      filename = "__factoryx__/graphics/entity/transparent.png",
      priority = "extra-high",
      width = 1,
      height = 1
    }
  }
end

local dollar_icon = icon64("__base__/graphics/icons/coin.png", {r = 1.0, g = 0.86, b = 0.25, a = 1.0})
local ev_reservation_icon = generated_icon("ev-reservation")
local ai_token_icon = generated_icon("ai-token")
local planetary_grid_segment_icon = layered_icon64(
  "__base__/graphics/icons/solar-panel.png",
  "__base__/graphics/icons/accumulator.png",
  {r = 1.0, g = 0.92, b = 0.45, a = 1.0},
  {r = 0.45, g = 0.85, b = 1.0, a = 1.0}
)
local planetary_grid_charge_icon = layered_icon64(
  "__base__/graphics/icons/signal/signal-lightning.png",
  "__base__/graphics/icons/solar-panel.png",
  {r = 1.0, g = 0.9, b = 0.25, a = 1.0},
  {r = 0.45, g = 0.85, b = 1.0, a = 1.0}
)
local gigafactory_module_icon = generated_icon("gigafactory-module")
local gigafactory_icon = generated_icon("gigafactory")
local gigacast_icon = layered_icon64(
  "__base__/graphics/icons/electric-furnace.png",
  "__base__/graphics/icons/low-density-structure.png"
)
local gigafactory_v2_icon = {
  {
    icon = "__factoryx__/graphics/icons/gigafactory.png",
    icon_size = 256,
    tint = {r = 0.72, g = 0.92, b = 1.0, a = 1.0}
  },
  {
    icon = "__base__/graphics/icons/productivity-module-3.png",
    icon_size = 64,
    scale = 0.35,
    shift = {8, 8}
  }
}
local ev_charging_station_icon = generated_icon("ev-charging-station")
local ev_charging_station_v2_icon = generated_icon("ev-charging-station-v2")
local ev_charging_station_v3_icon = generated_icon("ev-charging-station-v3")
local ev_charging_station_v4_icon = generated_icon("ev-charging-station-v4")
local sales_office_icon_path = "__factoryx__/graphics/icons/sales-office.png"
local sales_office_entity_path = "__factoryx__/graphics/entity/sales-office/sales-office.png"
local sales_office_icon = {
  {
    icon = sales_office_icon_path,
    icon_size = 256
  }
}
local datacenter_icon = generated_icon("terrestrial-datacenter")
local orbital_compute_icon = generated_icon("orbital-compute-array")
local planetary_grid_controller_icon = layered_icon64(
  "__base__/graphics/icons/substation.png",
  "__base__/graphics/icons/solar-panel.png",
  {r = 0.9, g = 0.95, b = 1.0, a = 1.0},
  {r = 1.0, g = 0.85, b = 0.25, a = 1.0}
)
local high_density_solar_array_icon = layered_icon64(
  "__base__/graphics/icons/solar-panel.png",
  "__base__/graphics/icons/processing-unit.png",
  {r = 0.65, g = 0.9, b = 1.0, a = 1.0}
)
local megapack_icon = generated_icon("megapack")
local robotaxi_service_center_icon = layered_icon64(
  "__base__/graphics/icons/roboport.png",
  "__factoryx__/graphics/icons/robotaxi-fleet.png",
  {r = 0.45, g = 0.85, b = 1.0, a = 1.0},
  {r = 1.0, g = 0.72, b = 0.12, a = 1.0}
)
local cybertruck_icon = icon64(
  "__base__/graphics/icons/car.png",
  {r = 0.72, g = 0.76, b = 0.80, a = 1.0}
)

data:extend({
  {
    type = "shortcut",
    name = "x-open-factoryx-progress",
    order = "z[factoryx]-a[progress]",
    action = "lua",
    icon = "__factoryx__/graphics/icons/factoryx-group.png",
    icon_size = 256,
    small_icon = "__factoryx__/graphics/icons/factoryx-group.png",
    small_icon_size = 256
  },
  {
    type = "shortcut",
    name = "x-toggle-sales-office-coverage",
    order = "z[factoryx]-b[sales-office-coverage]",
    action = "lua",
    toggleable = true,
    technology_to_unlock = "x-sales-office",
    icon = "__base__/graphics/icons/radar.png",
    icon_size = 64,
    small_icon = "__base__/graphics/icons/radar.png",
    small_icon_size = 64
  },
  {
    type = "item-subgroup",
    name = "x-factoryx-infrastructure",
    group = "production",
    order = "ea[factoryx-infrastructure]"
  },
  {
    type = "item-subgroup",
    name = "x-factoryx-components",
    group = "intermediate-products",
    order = "za[factoryx-components]"
  },
  {
    type = "item-subgroup",
    name = "x-factoryx-capital",
    group = "intermediate-products",
    order = "zb[factoryx-capital]"
  },
  {
    type = "recipe-category",
    name = "x-sales"
  },
  {
    type = "recipe-category",
    name = "x-vehicle-assembly"
  },
  {
    type = "recipe-category",
    name = "x-mass-vehicle-assembly"
  },
  {
    type = "recipe-category",
    name = "x-energy-products"
  },
  {
    type = "recipe-category",
    name = "x-vertical-integration"
  },
  {
    type = "recipe-category",
    name = "x-datacenter"
  },
  {
    type = "recipe-category",
    name = "x-orbital-compute"
  },
  {
    type = "recipe-category",
    name = "x-planetary-grid"
  },
  {
    type = "recipe-category",
    name = "x-robotaxi-service"
  },
  {
    type = "fuel-category",
    name = "x-electric-drive"
  }
})

data:extend({
  item("x-dollar", dollar_icon, "x-factoryx-capital", "a[dollar]", 100000),
  item("x-ev-reservation", ev_reservation_icon, "raw-material", "z[factoryx-ev-reservation]", 1000),
  item("x-gigafactory-module", gigafactory_module_icon, "x-factoryx-components", "c[gigafactory-module]", 100),
  item("x-gigacast", gigacast_icon, "x-factoryx-components", "d[gigacast]", 10),
  item("x-ai-token", ai_token_icon, "science-pack", "h[x-ai-token]", 1000000, {weight = 1}),
  item("x-planetary-grid-segment", planetary_grid_segment_icon, "x-factoryx-components", "g[planetary-grid-segment]", 2000),
  item("x-planetary-grid-charge", planetary_grid_charge_icon, "x-factoryx-components", "h[planetary-grid-charge]", 1),

  item("x-battery-pack", layered_icon64("__base__/graphics/icons/battery.png", "__base__/graphics/icons/accumulator.png"), "x-factoryx-components", "a[battery-pack]", 100),
  item("x-electric-drivetrain", layered_icon64("__base__/graphics/icons/electric-engine-unit.png", "__base__/graphics/icons/advanced-circuit.png"), "x-factoryx-components", "b[electric-drivetrain]", 50),
  item("x-prototype-roadster", generated_icon("prototype-roadster"), "transport", "x-a[prototype-roadster]", 1, {place_result = "x-prototype-roadster"}),
  item("x-premium-ev", generated_icon("premium-ev"), "transport", "x-b[premium-ev]", 1, {place_result = "x-premium-ev"}),
  item("x-mass-market-ev", generated_icon("mass-market-ev"), "transport", "x-c[mass-market-ev]", 1, {place_result = "x-mass-market-ev"}),
  item("x-cybertruck", cybertruck_icon, "transport", "x-d[cybertruck]", 1, {place_result = "x-cybertruck"}),
  item("x-autonomy-computer", layered_icon64("__base__/graphics/icons/processing-unit.png", "__base__/graphics/icons/speed-module.png"), "x-factoryx-components", "e[autonomy-computer]", 50),
  item("x-robotaxi-fleet", generated_icon("robotaxi-fleet"), "transport", "x-e[robotaxi-fleet]", 5, {place_result = "x-robotaxi-fleet"}),

  item("x-electric-drive-charge", icon64("__base__/graphics/icons/battery.png"), "other", "z[x-electric-drive-charge]", 1, {
    hidden = true,
    fuel_category = "x-electric-drive",
    fuel_value = "1MJ",
    fuel_acceleration_multiplier = 1.15,
    fuel_top_speed_multiplier = 1.05
  }),

  item("x-small-launch-service", generated_icon("small-launch-service"), "space-related", "x-a[small-launch-service]", 20),
  item("x-reusable-booster", generated_icon("reusable-booster"), "space-related", "x-b[reusable-booster]", 10),
  item("x-reusable-launch-service", generated_icon("reusable-launch-service"), "space-related", "x-c[reusable-launch-service]", 20),
  item("x-satellite-bus", generated_icon("satellite-bus"), "space-related", "x-d[satellite-bus]", 20),
  item("x-ground-station-network", generated_icon("ground-station-network"), "space-related", "x-e[ground-station-network]", 20),
  item("x-datacenter-rack", generated_icon("datacenter-rack"), "x-factoryx-components", "f[datacenter-rack]", 50),

  item("x-sales-office", sales_office_icon, "x-factoryx-infrastructure", "a[sales-office]", 10, {place_result = "x-sales-office"}),
  item("x-ev-charging-station", ev_charging_station_icon, "x-factoryx-infrastructure", "b[ev-charging-station]", 5, {place_result = "x-ev-charging-station"}),
  item("x-ev-charging-station-v2", ev_charging_station_v2_icon, "x-factoryx-infrastructure", "c[ev-charging-station-v2]", 5, {place_result = "x-ev-charging-station-v2"}),
  item("x-ev-charging-station-v3", ev_charging_station_v3_icon, "x-factoryx-infrastructure", "d[ev-charging-station-v3]", 5, {place_result = "x-ev-charging-station-v3"}),
  item("x-ev-charging-station-v4", ev_charging_station_v4_icon, "x-factoryx-infrastructure", "e[ev-charging-station-v4]", 5, {place_result = "x-ev-charging-station-v4"}),
  item("x-gigafactory-building", gigafactory_icon, "x-factoryx-infrastructure", "f[gigafactory]", 1, {place_result = "x-gigafactory-building"}),
  item("x-gigafactory-v2", gigafactory_v2_icon, "x-factoryx-infrastructure", "g[gigafactory-v2]", 1, {place_result = "x-gigafactory-v2"}),
  item("x-high-density-solar-array", high_density_solar_array_icon, "energy", "x-a[high-density-solar-array]", 10, {place_result = "x-high-density-solar-array"}),
  item("x-megapack", megapack_icon, "energy", "x-b[megapack]", 10, {place_result = "x-megapack"}),
  item("x-terrestrial-datacenter", datacenter_icon, "x-factoryx-infrastructure", "f[terrestrial-datacenter]", 1, {place_result = "x-terrestrial-datacenter"}),
  item("x-robotaxi-service-center", robotaxi_service_center_icon, "x-factoryx-infrastructure", "g[robotaxi-service-center]", 1, {place_result = "x-robotaxi-service-center"}),
  item("x-orbital-compute-array", orbital_compute_icon, "x-factoryx-infrastructure", "g[orbital-compute-array]", 1, {place_result = "x-orbital-compute-array"}),
  item("x-planetary-grid-controller", planetary_grid_controller_icon, "x-factoryx-infrastructure", "h[planetary-grid-controller]", 1, {place_result = "x-planetary-grid-controller"})
})

local sales_office = copied_assembler(
  "assembling-machine-2",
  "x-sales-office",
  sales_office_icon,
  "x-sales-office",
  {"x-sales"},
  "250kW",
  1
)
sales_office.energy_source.emissions_per_minute = nil
sales_office.graphics_set = {
  animation = {
    layers = {
      {
        filename = sales_office_entity_path,
        priority = "high",
        width = 512,
        height = 512,
        frame_count = 1,
        line_length = 1,
        shift = {0, -0.2},
        scale = 0.18
      }
    }
  }
}
sales_office.radius_visualisation_specification = customer_radius_visualisation(128)

local ev_charging_station = copied_reservation_output_site(
  "substation",
  "x-ev-charging-station",
  ev_charging_station_icon,
  "x-ev-charging-station"
)
ev_charging_station.robot_door.animation = generated_entity_picture("ev-charging-station", nil, 0.14)
ev_charging_station.radius_visualisation_specification = customer_radius_visualisation(64)

local ev_charging_station_v2 = copied_reservation_output_site(
  "substation",
  "x-ev-charging-station-v2",
  ev_charging_station_v2_icon,
  "x-ev-charging-station-v2"
)
ev_charging_station_v2.max_health = 500
ev_charging_station_v2.collision_box = {{-1.9, -1.9}, {1.9, 1.9}}
ev_charging_station_v2.selection_box = {{-2, -2}, {2, 2}}
ev_charging_station_v2.robot_door.animation = generated_entity_picture("ev-charging-station-v2", nil, 0.26)
ev_charging_station_v2.radius_visualisation_specification = customer_radius_visualisation(96)

local ev_charging_station_v3 = copied_reservation_output_site(
  "substation",
  "x-ev-charging-station-v3",
  ev_charging_station_v3_icon,
  "x-ev-charging-station-v3"
)
ev_charging_station_v3.max_health = 750
ev_charging_station_v3.collision_box = {{-2.4, -2.4}, {2.4, 2.4}}
ev_charging_station_v3.selection_box = {{-2.5, -2.5}, {2.5, 2.5}}
ev_charging_station_v3.robot_door.animation = generated_entity_picture("ev-charging-station-v3", nil, 0.35)
ev_charging_station_v3.radius_visualisation_specification = customer_radius_visualisation(128)

local ev_charging_station_v4 = copied_reservation_output_site(
  "substation",
  "x-ev-charging-station-v4",
  ev_charging_station_v4_icon,
  "x-ev-charging-station-v4"
)
ev_charging_station_v4.max_health = 1000
ev_charging_station_v4.collision_box = {{-2.9, -2.9}, {2.9, 2.9}}
ev_charging_station_v4.selection_box = {{-3, -3}, {3, 3}}
ev_charging_station_v4.robot_door.animation = generated_entity_picture("ev-charging-station-v4", nil, 0.38)
ev_charging_station_v4.radius_visualisation_specification = customer_radius_visualisation(160)

local gigafactory = copied_assembler(
  "assembling-machine-2",
  "x-gigafactory-building",
  gigafactory_icon,
  "x-gigafactory-building",
  {"advanced-crafting", "x-vehicle-assembly", "x-energy-products", "x-vertical-integration"},
  "20MW",
  1
)
gigafactory.max_health = 5000
gigafactory.collision_box = {{-4.4, -4.4}, {4.4, 4.4}}
gigafactory.selection_box = {{-4.5, -4.5}, {4.5, 4.5}}
gigafactory.drawing_box_vertical_extension = 1.0
gigafactory.energy_source.emissions_per_minute = {pollution = 12}
gigafactory.module_slots = 8
gigafactory.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
gigafactory.graphics_set = gigafactory_animation()
gigafactory.fast_replaceable_group = "x-gigafactory"
gigafactory.next_upgrade = "x-gigafactory-v2"

local gigafactory_v2 = copied_assembler(
  "assembling-machine-2",
  "x-gigafactory-v2",
  gigafactory_v2_icon,
  "x-gigafactory-v2",
  {"advanced-crafting", "x-vehicle-assembly", "x-mass-vehicle-assembly", "x-energy-products", "x-vertical-integration"},
  "30MW",
  2
)
gigafactory_v2.max_health = 7500
gigafactory_v2.collision_box = {{-4.4, -4.4}, {4.4, 4.4}}
gigafactory_v2.selection_box = {{-4.5, -4.5}, {4.5, 4.5}}
gigafactory_v2.drawing_box_vertical_extension = 1.0
gigafactory_v2.energy_source.emissions_per_minute = {pollution = 18}
gigafactory_v2.module_slots = 8
gigafactory_v2.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
gigafactory_v2.effect_receiver = {base_effect = {productivity = 1.5}}
gigafactory_v2.graphics_set = gigafactory_animation("__factoryx__/graphics/entity/gigafactory/gigafactory-v2.png")
gigafactory_v2.fast_replaceable_group = "x-gigafactory"

local high_density_solar_array = copied_energy_entity(
  "solar-panel",
  "solar-panel",
  "x-high-density-solar-array",
  high_density_solar_array_icon,
  "x-high-density-solar-array"
)
high_density_solar_array.max_health = 500
high_density_solar_array.production = "300kW"
high_density_solar_array.fast_replaceable_group = nil
high_density_solar_array.collision_box = {{-1.9, -1.9}, {1.9, 1.9}}
high_density_solar_array.selection_box = {{-2, -2}, {2, 2}}
high_density_solar_array.picture = tiled_high_density_solar_sprite(data.raw["solar-panel"]["solar-panel"].picture)
high_density_solar_array.overlay = tiled_high_density_solar_sprite(data.raw["solar-panel"]["solar-panel"].overlay)

local megapack = copied_energy_entity(
  "accumulator",
  "accumulator",
  "x-megapack",
  megapack_icon,
  "x-megapack"
)
megapack.max_health = 600
megapack.energy_source.buffer_capacity = "100MJ"
megapack.energy_source.input_flow_limit = "5MW"
megapack.energy_source.output_flow_limit = "5MW"
megapack.chargable_graphics = {
  picture = generated_entity_picture("megapack", nil, 0.14)
}
megapack.water_reflection = nil

local terrestrial_datacenter = copied_assembler(
  "assembling-machine-2",
  "x-terrestrial-datacenter",
  datacenter_icon,
  "x-terrestrial-datacenter",
  {"x-datacenter"},
  "8MW",
  1
)
terrestrial_datacenter.energy_source.emissions_per_minute = {pollution = 2}
terrestrial_datacenter.module_slots = 0
terrestrial_datacenter.allowed_effects = {"consumption", "speed", "pollution", "quality"}
terrestrial_datacenter.collision_box = {{-2.9, -2.9}, {2.9, 2.9}}
terrestrial_datacenter.selection_box = {{-3, -3}, {3, 3}}
terrestrial_datacenter.graphics_set = generated_entity_animation("terrestrial-datacenter", 0.36)

local robotaxi_service_center = table.deepcopy(data.raw["logistic-container"]["passive-provider-chest"])
robotaxi_service_center.name = "x-robotaxi-service-center"
robotaxi_service_center.icons = robotaxi_service_center_icon
robotaxi_service_center.icon = nil
robotaxi_service_center.minable = {mining_time = 1, result = "x-robotaxi-service-center"}
robotaxi_service_center.inventory_size = 41
robotaxi_service_center.collision_box = {{-3.9, -3.9}, {3.9, 3.9}}
robotaxi_service_center.selection_box = {{-4, -4}, {4, 4}}
robotaxi_service_center.picture = generated_entity_picture("terrestrial-datacenter", nil, 0.48)
robotaxi_service_center.radius_visualisation_specification = customer_radius_visualisation(256)

local robotaxi_service_power = copied_assembler(
  "assembling-machine-2",
  "x-robotaxi-service-power",
  robotaxi_service_center_icon,
  nil,
  {"x-robotaxi-service"},
  "10MW",
  1
)
robotaxi_service_power.flags = {"not-on-map", "not-blueprintable", "not-deconstructable"}
robotaxi_service_power.minable = nil
robotaxi_service_power.selectable_in_game = false
robotaxi_service_power.collision_mask = {layers = {}}
robotaxi_service_power.collision_box = {{0, 0}, {0, 0}}
robotaxi_service_power.selection_box = {{0, 0}, {0, 0}}

local orbital_compute_array = copied_assembler(
  "assembling-machine-2",
  "x-orbital-compute-array",
  orbital_compute_icon,
  "x-orbital-compute-array",
  {"x-orbital-compute"},
  "40MW",
  1.5
)
orbital_compute_array.energy_source.emissions_per_minute = nil
orbital_compute_array.module_slots = 0
orbital_compute_array.allowed_effects = {"consumption", "speed", "pollution", "quality"}
orbital_compute_array.graphics_set = generated_entity_animation("orbital-compute-array")
orbital_compute_array.surface_conditions = {
  {
    property = "gravity",
    min = 0,
    max = 0
  }
}

local planetary_grid_controller = copied_assembler(
  "assembling-machine-2",
  "x-planetary-grid-controller",
  planetary_grid_controller_icon,
  "x-planetary-grid-controller",
  {"x-planetary-grid"},
  "1GW",
  1
)
planetary_grid_controller.energy_source.emissions_per_minute = nil

local electric_vehicles = {
  copied_electric_vehicle(
    "x-prototype-roadster", generated_icon("prototype-roadster"),
    {r = 0.90, g = 0.02, b = 0.01, a = 1}, {r = 1.00, g = 0.18, b = 0.08, a = 1},
    "180kW", 650
  ),
  copied_electric_vehicle(
    "x-premium-ev", generated_icon("premium-ev"),
    {r = 0.015, g = 0.015, b = 0.015, a = 1}, {r = 0.12, g = 0.12, b = 0.12, a = 1},
    "160kW", 800
  ),
  copied_electric_vehicle(
    "x-mass-market-ev", generated_icon("mass-market-ev"),
    {r = 0.82, g = 0.82, b = 0.82, a = 1}, {r = 1.00, g = 1.00, b = 1.00, a = 1},
    "130kW", 750
  ),
  copied_electric_vehicle(
    "x-cybertruck", cybertruck_icon,
    {r = 0.58, g = 0.62, b = 0.66, a = 1}, {r = 0.90, g = 0.93, b = 0.96, a = 1},
    "210kW", 1200
  ),
  copied_electric_vehicle(
    "x-robotaxi-fleet", generated_icon("robotaxi-fleet"),
    {r = 0.85, g = 0.52, b = 0.03, a = 1}, {r = 1.00, g = 0.82, b = 0.18, a = 1},
    "120kW", 700
  )
}

data:extend({
  hidden_grid_connection_pole(),
  hidden_ev_charging_power_sink("x-ev-charging-power-sink", 50),
  hidden_ev_charging_power_sink("x-ev-charging-v2-power-sink", 150),
  hidden_ev_charging_power_sink("x-ev-charging-v3-power-sink", 250),
  hidden_ev_charging_power_sink("x-ev-charging-v4-power-sink", 500),
  sales_office,
  ev_charging_station,
  ev_charging_station_v2,
  ev_charging_station_v3,
  ev_charging_station_v4,
  gigafactory,
  gigafactory_v2,
  high_density_solar_array,
  megapack,
  terrestrial_datacenter,
  robotaxi_service_center,
  robotaxi_service_power,
  orbital_compute_array,
  planetary_grid_controller,
  electric_vehicles[1],
  electric_vehicles[2],
  electric_vehicles[3],
  electric_vehicles[4],
  electric_vehicles[5]
})

data:extend({
  recipe("x-sales-office", {"crafting"}, "x-factoryx-infrastructure", "a[sales-office]",
    {
      {type = "item", name = "assembling-machine-2", amount = 1},
      {type = "item", name = "radar", amount = 1},
      {type = "item", name = "concrete", amount = 20}
    },
    {{type = "item", name = "x-sales-office", amount = 1}}, 4
  ),
  recipe("x-ev-charging-station", {"advanced-crafting"}, "x-factoryx-infrastructure", "b[ev-charging-station]",
    {
      {type = "item", name = "substation", amount = 1},
      {type = "item", name = "accumulator", amount = 2},
      {type = "item", name = "concrete", amount = 20}
    },
    {{type = "item", name = "x-ev-charging-station", amount = 1}}, 12
  ),
  recipe("x-ev-charging-station-v2", {"advanced-crafting"}, "x-factoryx-infrastructure", "c[ev-charging-station-v2]",
    {
      {type = "item", name = "x-ev-charging-station", amount = 1},
      {type = "item", name = "substation", amount = 2},
      {type = "item", name = "processing-unit", amount = 20},
      {type = "item", name = "x-dollar", amount = 20}
    },
    {{type = "item", name = "x-ev-charging-station-v2", amount = 1}}, 30
  ),
  recipe("x-ev-charging-station-v3", {"advanced-crafting"}, "x-factoryx-infrastructure", "d[ev-charging-station-v3]",
    {
      {type = "item", name = "x-ev-charging-station-v2", amount = 1},
      {type = "item", name = "substation", amount = 4},
      {type = "item", name = "processing-unit", amount = 40},
      {type = "item", name = "x-dollar", amount = 75}
    },
    {{type = "item", name = "x-ev-charging-station-v3", amount = 1}}, 45
  ),
  recipe("x-ev-charging-station-v4", {"advanced-crafting"}, "x-factoryx-infrastructure", "e[ev-charging-station-v4]",
    {
      {type = "item", name = "x-ev-charging-station-v3", amount = 1},
      {type = "item", name = "x-high-density-solar-array", amount = 4},
      {type = "item", name = "x-megapack", amount = 4},
      {type = "item", name = "x-dollar", amount = 200}
    },
    {{type = "item", name = "x-ev-charging-station-v4", amount = 1}}, 60
  ),
  recipe("x-gigafactory-module", {"advanced-crafting"}, "x-factoryx-components", "c[gigafactory-module]",
    {
      {type = "item", name = "x-dollar", amount = 10},
      {type = "item", name = "assembling-machine-2", amount = 5},
      {type = "item", name = "lab", amount = 5},
      {type = "item", name = "refined-concrete", amount = 50}
    },
    {{type = "item", name = "x-gigafactory-module", amount = 1}}, 15
  ),
  recipe("x-gigafactory-building", {"advanced-crafting"}, "x-factoryx-infrastructure", "d[gigafactory]",
    {
      {type = "item", name = "x-gigafactory-module", amount = 10},
      {type = "item", name = "substation", amount = 2}
    },
    {{type = "item", name = "x-gigafactory-building", amount = 1}}, 120
  ),
  recipe("x-gigacast", {"advanced-crafting"}, "x-factoryx-components", "d[gigacast]",
    {
      {type = "item", name = "electric-furnace", amount = 20},
      {type = "item", name = "steel-plate", amount = 500},
      {type = "item", name = "electric-engine-unit", amount = 50},
      {type = "item", name = "x-dollar", amount = 50}
    },
    {{type = "item", name = "x-gigacast", amount = 1}}, 60
  ),
  recipe("x-gigafactory-v2", {"advanced-crafting"}, "x-factoryx-infrastructure", "e[gigafactory-v2]",
    {
      {type = "item", name = "x-gigafactory-building", amount = 1},
      {type = "item", name = "x-gigacast", amount = 1},
      {type = "item", name = "x-dollar", amount = 100}
    },
    {{type = "item", name = "x-gigafactory-v2", amount = 1}}, 180
  ),
  recipe("x-battery-pack", {"advanced-crafting"}, "x-factoryx-components", "a[battery-pack]",
    {
      {type = "item", name = "accumulator", amount = 1},
      {type = "item", name = "electronic-circuit", amount = 4},
      {type = "item", name = "copper-cable", amount = 10}
    },
    {{type = "item", name = "x-battery-pack", amount = 1}}, 4
  ),
  recipe("x-electric-drivetrain", {"advanced-crafting"}, "x-factoryx-components", "b[electric-drivetrain]",
    {
      {type = "item", name = "electric-engine-unit", amount = 1},
      {type = "item", name = "advanced-circuit", amount = 3},
      {type = "item", name = "copper-cable", amount = 10}
    },
    {{type = "item", name = "x-electric-drivetrain", amount = 1}}, 5
  ),
  recipe("x-prototype-roadster", {"advanced-crafting"}, "transport", "x-a[prototype-roadster]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "battery", amount = 12},
      {type = "item", name = "advanced-circuit", amount = 4}
    },
    {{type = "item", name = "x-prototype-roadster", amount = 1}}, 30
  ),
  recipe("x-premium-ev", {"x-vehicle-assembly"}, "transport", "x-b[premium-ev]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "x-battery-pack", amount = 8},
      {type = "item", name = "x-electric-drivetrain", amount = 2},
      {type = "item", name = "advanced-circuit", amount = 10}
    },
    {{type = "item", name = "x-premium-ev", amount = 1}}, 20
  ),
  recipe("x-mass-market-ev", {"x-mass-vehicle-assembly"}, "transport", "x-c[mass-market-ev]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "x-battery-pack", amount = 4},
      {type = "item", name = "x-electric-drivetrain", amount = 1}
    },
    {{type = "item", name = "x-mass-market-ev", amount = 1}}, 8
  ),
  recipe("x-cybertruck", {"x-mass-vehicle-assembly"}, "transport", "x-d[cybertruck]",
    {
      {type = "item", name = "x-mass-market-ev", amount = 2},
      {type = "item", name = "steel-plate", amount = 20},
      {type = "item", name = "x-battery-pack", amount = 4}
    },
    {{type = "item", name = "x-cybertruck", amount = 1}}, 15
  ),
  recipe("x-high-density-solar-array", {"x-energy-products"}, "energy", "x-a[high-density-solar-array]",
    {
      {type = "item", name = "solar-panel", amount = 4},
      {type = "item", name = "processing-unit", amount = 10},
      {type = "item", name = "low-density-structure", amount = 10},
      {type = "item", name = "x-dollar", amount = 5}
    },
    {{type = "item", name = "x-high-density-solar-array", amount = 1}}, 12
  ),
  recipe("x-megapack", {"x-energy-products"}, "energy", "x-b[megapack]",
    {
      {type = "item", name = "x-battery-pack", amount = 12},
      {type = "item", name = "accumulator", amount = 4},
      {type = "item", name = "substation", amount = 1}
    },
    {{type = "item", name = "x-megapack", amount = 1}}, 8
  ),
  recipe("x-autonomy-computer", {"advanced-crafting"}, "x-factoryx-components", "e[autonomy-computer]",
    {
      {type = "item", name = "processing-unit", amount = 4},
      {type = "item", name = "speed-module", amount = 2}
    },
    {{type = "item", name = "x-autonomy-computer", amount = 1}}, 6
  ),
  recipe("x-robotaxi-fleet", {"x-mass-vehicle-assembly"}, "transport", "x-d[robotaxi-fleet]",
    {
      {type = "item", name = "x-mass-market-ev", amount = 4},
      {type = "item", name = "x-autonomy-computer", amount = 4},
      {type = "item", name = "x-dollar", amount = 100}
    },
    {{type = "item", name = "x-robotaxi-fleet", amount = 1}}, 20
  ),
  recipe("x-robotaxi-service-center", {"advanced-crafting"}, "x-factoryx-infrastructure", "g[robotaxi-service-center]",
    {
      {type = "item", name = "x-ev-charging-station-v4", amount = 1},
      {type = "item", name = "roboport", amount = 4},
      {type = "item", name = "processing-unit", amount = 50},
      {type = "item", name = "x-dollar", amount = 200}
    },
    {{type = "item", name = "x-robotaxi-service-center", amount = 1}}, 60
  ),
  recipe("x-operate-robotaxis", {"x-robotaxi-service"}, "x-factoryx-capital", "i[operate-robotaxis]",
    {},
    {{type = "item", name = "x-dollar", amount = 1}}, 100000000
  ),

  recipe("x-small-launch-service", {"advanced-crafting"}, "space-related", "x-a[small-launch-service]",
    {
      {type = "item", name = "rocket-fuel", amount = 10},
      {type = "item", name = "low-density-structure", amount = 10},
      {type = "item", name = "processing-unit", amount = 5}
    },
    {{type = "item", name = "x-small-launch-service", amount = 1}}, 12
  ),
  recipe("x-reusable-booster", {"advanced-crafting"}, "space-related", "x-b[reusable-booster]",
    {
      {type = "item", name = "rocket-fuel", amount = 20},
      {type = "item", name = "low-density-structure", amount = 20},
      {type = "item", name = "electric-engine-unit", amount = 10},
      {type = "item", name = "processing-unit", amount = 10}
    },
    {{type = "item", name = "x-reusable-booster", amount = 1}}, 20
  ),
  recipe("x-reusable-launch-service", {"advanced-crafting"}, "space-related", "x-c[reusable-launch-service]",
    {
      {type = "item", name = "x-small-launch-service", amount = 1},
      {type = "item", name = "x-reusable-booster", amount = 1},
      {type = "item", name = "rocket-fuel", amount = 10}
    },
    {{type = "item", name = "x-reusable-launch-service", amount = 1}}, 15
  ),
  recipe("x-satellite-bus", {"advanced-crafting"}, "space-related", "x-d[satellite-bus]",
    {
      {type = "item", name = "low-density-structure", amount = 10},
      {type = "item", name = "space-platform-foundation", amount = 10},
      {type = "item", name = "solar-panel", amount = 10},
      {type = "item", name = "processing-unit", amount = 10}
    },
    {{type = "item", name = "x-satellite-bus", amount = 1}}, 15
  ),
  recipe("x-ground-station-network", {"advanced-crafting"}, "space-related", "x-e[ground-station-network]",
    {
      {type = "item", name = "radar", amount = 4},
      {type = "item", name = "processing-unit", amount = 10},
      {type = "item", name = "x-dollar", amount = 20}
    },
    {{type = "item", name = "x-ground-station-network", amount = 1}}, 20
  ),
  recipe("x-datacenter-rack", {"advanced-crafting"}, "x-factoryx-components", "f[datacenter-rack]",
    {
      {type = "item", name = "processing-unit", amount = 10},
      {type = "item", name = "battery", amount = 20},
      {type = "item", name = "low-density-structure", amount = 5}
    },
    {{type = "item", name = "x-datacenter-rack", amount = 1}}, 10
  ),
  recipe("x-terrestrial-datacenter", {"advanced-crafting"}, "x-factoryx-infrastructure", "f[terrestrial-datacenter]",
    {
      {type = "item", name = "x-gigafactory-module", amount = 1},
      {type = "item", name = "x-datacenter-rack", amount = 4},
      {type = "item", name = "substation", amount = 4},
      {type = "item", name = "refined-concrete", amount = 100}
    },
    {{type = "item", name = "x-terrestrial-datacenter", amount = 1}}, 15
  ),
  recipe("x-orbital-compute-array", {"advanced-crafting"}, "x-factoryx-infrastructure", "g[orbital-compute-array]",
    {
      {type = "item", name = "x-datacenter-rack", amount = 4},
      {type = "item", name = "x-satellite-bus", amount = 1},
      {type = "item", name = "space-platform-foundation", amount = 20}
    },
    {{type = "item", name = "x-orbital-compute-array", amount = 1}}, 20
  ),
  recipe("x-planetary-grid-controller", {"advanced-crafting"}, "x-factoryx-infrastructure", "h[planetary-grid-controller]",
    {
      {type = "item", name = "x-gigafactory-module", amount = 4},
      {type = "item", name = "x-megapack", amount = 10},
      {type = "item", name = "x-ground-station-network", amount = 4},
      {type = "item", name = "x-dollar", amount = 200}
    },
    {{type = "item", name = "x-planetary-grid-controller", amount = 1}}, 60
  ),

  recipe("x-sell-prototype-roadster", {"x-sales"}, "x-factoryx-capital", "a[sell-roadster]",
    {
      {type = "item", name = "x-prototype-roadster", amount = 1},
      {type = "item", name = "x-ev-reservation", amount = 1}
    },
    {{type = "item", name = "x-dollar", amount = 2}}, 120,
    {icons = sale_icon(generated_icon("prototype-roadster"))}
  ),
  recipe("x-sell-premium-ev", {"x-sales"}, "x-factoryx-capital", "b[sell-premium-ev]",
    {
      {type = "item", name = "x-premium-ev", amount = 1},
      {type = "item", name = "x-ev-reservation", amount = 1}
    },
    {{type = "item", name = "x-dollar", amount = 1}}, 30,
    {icons = sale_icon(generated_icon("premium-ev"))}
  ),
  recipe("x-sell-mass-market-ev", {"x-sales"}, "x-factoryx-capital", "c[sell-mass-market-ev]",
    {
      {type = "item", name = "x-mass-market-ev", amount = 1},
      {type = "item", name = "x-ev-reservation", amount = 1}
    },
    {{type = "item", name = "x-dollar", amount = 1}}, 5,
    {icons = sale_icon(generated_icon("mass-market-ev"))}
  ),
  recipe("x-sell-cybertruck", {"x-sales"}, "x-factoryx-capital", "d[sell-cybertruck]",
    {
      {type = "item", name = "x-cybertruck", amount = 1},
      {type = "item", name = "x-ev-reservation", amount = 1}
    },
    {{type = "item", name = "x-dollar", amount = 2}}, 10,
    {icons = sale_icon(cybertruck_icon)}
  ),
  recipe("x-sell-megapack", {"x-sales"}, "x-factoryx-capital", "e[sell-megapack]",
    {{type = "item", name = "x-megapack", amount = 1}},
    {{type = "item", name = "x-dollar", amount = 24}}, 8,
    {icons = sale_icon(megapack_icon)}
  ),
  recipe("x-sell-small-launch", {"x-sales"}, "x-factoryx-capital", "f[sell-small-launch]",
    {{type = "item", name = "x-small-launch-service", amount = 1}},
    {{type = "item", name = "x-dollar", amount = 75}}, 12,
    {icons = sale_icon(generated_icon("small-launch-service"))}
  ),
  recipe("x-sell-reusable-launch", {"x-sales"}, "x-factoryx-capital", "g[sell-reusable-launch]",
    {{type = "item", name = "x-reusable-launch-service", amount = 1}},
    {{type = "item", name = "x-dollar", amount = 160}}, 12,
    {icons = sale_icon(generated_icon("reusable-launch-service"))}
  ),
  recipe("x-sell-robotaxi-fleet", {"x-sales"}, "x-factoryx-capital", "h[sell-robotaxi-fleet]",
    {{type = "item", name = "x-robotaxi-fleet", amount = 3}},
    {{type = "item", name = "x-dollar", amount = 1}}, 3,
    {icons = sale_icon(generated_icon("robotaxi-fleet"))}
  ),

  recipe("x-terrestrial-ai-token", {"x-datacenter"}, "science-pack", "x-c[terrestrial-ai-token]",
    {{type = "item", name = "x-dollar", amount = 20}},
    {{type = "item", name = "x-ai-token", amount = 20}}, 30
  ),
  recipe("x-orbital-ai-token", {"x-orbital-compute"}, "science-pack", "x-d[orbital-ai-token]",
    {
      {type = "item", name = "x-datacenter-rack", amount = 1},
      {type = "item", name = "x-satellite-bus", amount = 1}
    },
    {{type = "item", name = "x-ai-token", amount = 40}}, 30,
    {
      surface_conditions = {
        {
          property = "gravity",
          min = 0,
          max = 0
        }
      }
    }
  ),
  recipe("x-planetary-grid-segment", {"x-planetary-grid"}, "x-factoryx-components", "g[planetary-grid-segment]",
    {
      {type = "item", name = "x-ai-token", amount = 200},
      {type = "item", name = "x-megapack", amount = 5},
      {type = "item", name = "x-satellite-bus", amount = 1},
      {type = "item", name = "x-ground-station-network", amount = 1}
    },
    {{type = "item", name = "x-planetary-grid-segment", amount = 1}}, 60
  ),
  recipe("x-charge-planetary-grid", {"x-planetary-grid"}, "x-factoryx-components", "h[charge-planetary-grid]",
    {
      {type = "item", name = "x-planetary-grid-segment", amount = 100},
      {type = "item", name = "x-ai-token", amount = 5000},
      {type = "item", name = "x-megapack", amount = 100},
      {type = "item", name = "x-dollar", amount = 1000}
    },
    {{type = "item", name = "x-planetary-grid-charge", amount = 1}}, 600
  )
})

add_lab_input("lab", "x-dollar")
add_lab_input("lab", "x-ai-token")
add_lab_input("biolab", "x-dollar")
add_lab_input("biolab", "x-ai-token")

data:extend({
  tech("x-sales-office",
    "__base__/graphics/technology/automation-2.png",
    {"automation-2", "electronics"},
    {
      unlock("x-sales-office"),
      unlock("x-ev-charging-station"),
      unlock("x-sell-prototype-roadster")
    },
    75,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    },
    20
  ),
  tech("x-premium-ev-program",
    "__base__/graphics/technology/electric-engine.png",
    {
      "x-sales-office",
      "battery",
      "electric-engine",
      "logistics-2",
      "electric-energy-distribution-2",
      "concrete"
    },
    {
      unlock("x-battery-pack"),
      unlock("x-electric-drivetrain"),
      unlock("x-gigafactory-module"),
      unlock("x-premium-ev"),
      unlock("x-sell-premium-ev")
    },
    250,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"x-dollar", 1}
    },
    30
  ),
  tech("x-capital-scaling",
    "__base__/graphics/technology/logistics-2.png",
    {
      "x-ev-charging-network",
      "x-energy-products",
      "production-science-pack",
      "utility-science-pack"
    },
    {
      unlock("x-gigacast"),
      unlock("x-gigafactory-v2"),
      unlock("x-mass-market-ev"),
      unlock("x-sell-mass-market-ev"),
      unlock("x-cybertruck"),
      unlock("x-sell-cybertruck"),
      unlock("x-ev-charging-station-v3")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-ev-charging-network",
    "__base__/graphics/technology/electric-energy-distribution-2.png",
    {"x-premium-ev-program", "electric-energy-distribution-2", "concrete"},
    {
      unlock("x-ev-charging-station-v2")
    },
    300,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"x-dollar", 1}
    },
    30
  ),
  tech("x-energy-products",
    "__base__/graphics/technology/electric-energy-acumulators.png",
    {"x-premium-ev-program", "electric-energy-accumulators", "solar-energy", "production-science-pack"},
    {
      unlock("x-gigafactory-building"),
      unlock("x-high-density-solar-array"),
      unlock("x-megapack"),
      unlock("x-sell-megapack")
    },
    500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"x-dollar", 1}
    },
    45
  ),
  tech("x-small-orbital-launch",
    "__base__/graphics/technology/rocket-silo.png",
    {"rocket-silo", "x-autonomous-logistics"},
    {
      unlock("x-small-launch-service"),
      unlock("x-sell-small-launch")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-reusable-launch",
    "__space-age__/graphics/technology/rocket-part-productivity.png",
    {"x-small-orbital-launch", "space-science-pack"},
    {
      unlock("x-reusable-booster"),
      unlock("x-reusable-launch-service"),
      unlock("x-sell-reusable-launch")
    },
    1500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-satellite-constellation",
    "__space-age__/graphics/technology/space-platform.png",
    {"x-reusable-launch", "space-platform"},
    {
      unlock("x-satellite-bus"),
      unlock("x-ground-station-network")
    },
    2000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-terrestrial-ai",
    "__base__/graphics/technology/processing-unit.png",
    {"x-capital-scaling", "x-energy-products", "processing-unit"},
    {
      unlock("x-autonomy-computer"),
      unlock("x-datacenter-rack"),
      unlock("x-terrestrial-datacenter"),
      unlock("x-terrestrial-ai-token")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-orbital-compute",
    "__base__/graphics/technology/space-science-pack.png",
    {"x-satellite-constellation", "x-terrestrial-ai", "space-platform", "electromagnetic-science-pack"},
    {
      unlock("x-orbital-compute-array"),
      unlock("x-orbital-ai-token")
    },
    2000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"electromagnetic-science-pack", 1},
      {"x-ai-token", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-autonomous-logistics",
    "__base__/graphics/technology/logistic-robotics.png",
    {"x-terrestrial-ai", "logistic-robotics", "production-science-pack", "utility-science-pack"},
    {
      unlock("x-robotaxi-fleet"),
      unlock("x-ev-charging-station-v4"),
      unlock("x-robotaxi-service-center"),
      unlock("x-operate-robotaxis"),
      unlock("x-sell-robotaxi-fleet")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"x-ai-token", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-planetary-energy-grid",
    "__base__/graphics/technology/solar-energy.png",
    {"x-orbital-compute", "x-autonomous-logistics", "fusion-reactor"},
    {
      unlock("x-planetary-grid-controller"),
      unlock("x-planetary-grid-segment")
    },
    2500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"metallurgic-science-pack", 1},
      {"electromagnetic-science-pack", 1},
      {"agricultural-science-pack", 1},
      {"cryogenic-science-pack", 1},
      {"x-ai-token", 1},
      {"x-dollar", 1}
    },
    60
  ),
  tech("x-kardashev-type-1",
    "__space-age__/graphics/technology/solar-system-edge.png",
    {"x-planetary-energy-grid"},
    {
      unlock("x-charge-planetary-grid")
    },
    5000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"metallurgic-science-pack", 1},
      {"electromagnetic-science-pack", 1},
      {"agricultural-science-pack", 1},
      {"cryogenic-science-pack", 1},
      {"x-ai-token", 1}
    },
    60
  )
})

data:extend({
  infinite_tech(
    "x-supercharging-power-electronics",
    "__base__/graphics/technology/electric-energy-distribution-2.png",
    {"x-ev-charging-network"},
    {{type = "nothing", effect_description = {"technology-effect-description.x-supercharging-power-electronics"}}},
    "200*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"x-dollar", 1}
    },
    30
  ),
  infinite_tech(
    "x-long-range-battery",
    "__base__/graphics/technology/battery.png",
    {"x-capital-scaling"},
    {{type = "nothing", effect_description = {"technology-effect-description.x-long-range-battery"}}},
    "300*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"x-dollar", 1}
    },
    60
  ),
  infinite_tech(
    "x-premium-audio-systems",
    "__base__/graphics/technology/circuit-network.png",
    {"x-premium-ev-program"},
    {{type = "nothing", effect_description = {"technology-effect-description.x-premium-audio-systems"}}},
    "150*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"x-dollar", 1}
    },
    30
  ),
  infinite_tech(
    "x-customer-referral-program",
    "__base__/graphics/technology/worker-robots-speed.png",
    {"x-ev-charging-network"},
    {{type = "nothing", effect_description = {"technology-effect-description.x-customer-referral-program"}}},
    "200*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"military-science-pack", 1},
      {"x-dollar", 1}
    },
    30
  )
})

data.raw.technology["x-small-orbital-launch"].enabled = false

local ai_efficiency_thresholds = {1000, 10000, 100000, 1000000, 10000000, 100000000}
local terrestrial_efficiency_science = {
  {"automation-science-pack", 1},
  {"logistic-science-pack", 1},
  {"chemical-science-pack", 1},
  {"production-science-pack", 1},
  {"utility-science-pack", 1},
  {"x-dollar", 1}
}
local orbital_efficiency_science = table.deepcopy(terrestrial_efficiency_science)
table.insert(orbital_efficiency_science, 6, {"space-science-pack", 1})
table.insert(orbital_efficiency_science, 7, {"electromagnetic-science-pack", 1})

for level, threshold in pairs(ai_efficiency_thresholds) do
  for _, track in pairs({
    {
      slug = "terrestrial",
      label = "Terrestrial AI Efficiency",
      recipe = "x-terrestrial-ai-token",
      prerequisite = level == 1 and "x-terrestrial-ai" or "x-terrestrial-ai-efficiency-" .. (level - 1),
      icon = "__base__/graphics/technology/processing-unit.png",
      science = terrestrial_efficiency_science
    },
    {
      slug = "orbital",
      label = "Orbital AI Efficiency",
      recipe = "x-orbital-ai-token",
      prerequisite = level == 1 and "x-orbital-compute" or "x-orbital-ai-efficiency-" .. (level - 1),
      icon = "__base__/graphics/technology/space-science-pack.png",
      science = orbital_efficiency_science
    }
  }) do
    local name = "x-" .. track.slug .. "-ai-efficiency-" .. level
    local prototype = tech(
      name,
      track.icon,
      {track.prerequisite},
      {{type = "nothing", effect_description = {"", "+10% AI Tokens per cycle"}}},
      math.floor(threshold / 10),
      track.science,
      30
    )
    prototype.enabled = false
    prototype.localised_name = {"", track.label, " ", tostring(level)}
    prototype.localised_description = {
      "",
      "Unlocked after this track generates ",
      tostring(threshold),
      " AI Tokens. Research adds 10% output without increasing Dollars or power per cycle."
    }
    data:extend({prototype})
  end
end

local function add_recipe_category(recipe_name, category_name)
  local prototype = data.raw.recipe[recipe_name]
  if not prototype then
    error("FactoryX vertical integration recipe does not exist: " .. recipe_name)
  end
  prototype.categories = prototype.categories or {prototype.category or "crafting"}
  prototype.category = nil
  for _, existing in pairs(prototype.categories) do
    if existing == category_name then
      return prototype
    end
  end
  table.insert(prototype.categories, category_name)
  return prototype
end

local vertically_integrated_intermediates = {
  "copper-cable",
  "electronic-circuit",
  "advanced-circuit",
  "low-density-structure",
  "x-gigafactory-module",
  "x-gigacast",
  "x-battery-pack",
  "x-electric-drivetrain",
  "x-autonomy-computer",
  "x-datacenter-rack",
  "x-reusable-booster",
  "x-satellite-bus",
  "x-ground-station-network"
}

for _, recipe_name in pairs(vertically_integrated_intermediates) do
  add_recipe_category(recipe_name, "x-vertical-integration").allow_productivity = true
end

for _, recipe_name in pairs({
  "x-premium-ev",
  "x-mass-market-ev",
  "x-cybertruck",
  "x-high-density-solar-array",
  "x-megapack",
  "x-robotaxi-fleet"
}) do
  data.raw.recipe[recipe_name].allow_productivity = false
end

for _, recipe_name in pairs({
  "x-sell-prototype-roadster",
  "x-sell-premium-ev",
  "x-sell-mass-market-ev",
  "x-sell-cybertruck",
  "x-sell-megapack",
  "x-sell-small-launch",
  "x-sell-reusable-launch",
  "x-sell-robotaxi-fleet",
  "x-terrestrial-ai-token",
  "x-orbital-ai-token",
  "x-charge-planetary-grid"
}) do
  data.raw.recipe[recipe_name].allow_quality = false
end

local customer_vehicle_classes = {
  roadster = {
    label = "Roadster",
    primary = {r = 0.90, g = 0.02, b = 0.01, a = 1},
    secondary = {r = 1.00, g = 0.18, b = 0.08, a = 1}
  },
  premium = {
    label = "Premium EV",
    primary = {r = 0.015, g = 0.015, b = 0.015, a = 1},
    secondary = {r = 0.12, g = 0.12, b = 0.12, a = 1}
  },
  ["mass-market"] = {
    label = "Mass-market EV",
    primary = {r = 0.82, g = 0.82, b = 0.82, a = 1},
    secondary = {r = 1.00, g = 1.00, b = 1.00, a = 1}
  },
  robotaxi = {
    label = "Robotaxi",
    primary = {r = 0.85, g = 0.52, b = 0.03, a = 1},
    secondary = {r = 1.00, g = 0.82, b = 0.18, a = 1}
  },
  cybertruck = {
    label = "Cybertruck",
    primary = {r = 0.58, g = 0.62, b = 0.66, a = 1},
    secondary = {r = 0.90, g = 0.93, b = 0.96, a = 1}
  }
}
local customer_mobile_bases = {
  "small-biter", "medium-biter", "big-biter", "behemoth-biter",
  "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter"
}

local function animation_mask_tint(value, class)
  if type(value) ~= "table" then
    return
  end
  local is_mask = false
  for _, flag in pairs(value.flags or {}) do
    if flag == "mask" then
      is_mask = true
      break
    end
  end
  if is_mask then
    value.tint = value.tint_as_overlay and class.secondary or class.primary
  end
  for key, child in pairs(value) do
    if key ~= "tint" and key ~= "flags" then
      animation_mask_tint(child, class)
    end
  end
end

local customer_vehicle_units = {}
for _, base_name in pairs(customer_mobile_bases) do
  local base = data.raw.unit[base_name]
  for class_name, class in pairs(customer_vehicle_classes) do
    local prototype = table.deepcopy(base)
    prototype.name = "x-" .. base_name .. "-" .. class_name
    prototype.localised_name = {"", class.label, " customer ", base.localised_name or {"entity-name." .. base_name}}
    prototype.autoplace = nil
    prototype.icons = {{icon = base.icon, icon_size = base.icon_size or 64, tint = class.primary}}
    prototype.icon = nil
    animation_mask_tint(prototype.run_animation, class)
    animation_mask_tint(prototype.attack_parameters and prototype.attack_parameters.animation, class)
    customer_vehicle_units[#customer_vehicle_units + 1] = prototype
  end
end
data:extend(customer_vehicle_units)
