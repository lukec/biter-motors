local function icon64(path, tint)
  return {
    {
      icon = path,
      icon_size = 64,
      tint = tint
    }
  }
end

local function tech_icon(path)
  return {
    {
      icon = path,
      icon_size = 256
    },
    {
      icon = "__bitermotors__/graphics/technology/bitermotors-tech-badge.png",
      icon_size = 64,
      scale = 0.78,
      shift = {88, 88}
    }
  }
end

local function generated_icon(slug)
  return {
    {
      icon = "__bitermotors__/graphics/icons/" .. slug .. ".png",
      icon_size = 256
    }
  }
end

local function dirty_battery_process_recipe_icon(product_slug)
  local icons = generated_icon(product_slug)
  table.insert(icons, {
    icon = "__bitermotors__/graphics/icons/acidic-tailings.png",
    icon_size = 256,
    scale = 0.105,
    shift = {8, 8}
  })
  return icons
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

local function working_animation(slug, width, height, scale, shift, animation_speed, additive)
  local animation = {
    filename = "__bitermotors__/graphics/animation/" .. slug .. ".png",
    priority = "high",
    width = width,
    height = height,
    frame_count = 8,
    line_length = 8,
    animation_speed = animation_speed or 0.25,
    scale = scale or 0.5,
    shift = shift or {0, 0}
  }
  if additive then
    animation.blend_mode = "additive"
    animation.draw_as_glow = true
  end
  return {animation = animation}
end

local function generated_entity_animation(slug, scale, working_visualisations)
  return {
    animation = {
      layers = {
        {
          filename = "__bitermotors__/graphics/entity/" .. slug .. "/" .. slug .. ".png",
          priority = "high",
          width = 512,
          height = 512,
          frame_count = 1,
          line_length = 1,
          shift = {0, -0.2},
          scale = scale or 0.18
        }
      }
    },
    working_visualisations = working_visualisations
  }
end

local function generated_entity_picture(slug, tint, scale, extra_layers)
  local layers = {
    {
      filename = "__bitermotors__/graphics/entity/" .. slug .. "/" .. slug .. ".png",
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

local function biterfactory_animation(filename, tier)
  local activity_slug = tier == 2 and "biterfactory-v2-activity" or "biterfactory-v1-activity"
  local activity_speed = tier == 2 and 0.38 or 0.22
  local loading_speed = tier == 2 and 0.48 or 0.3
  return {
    animation = {
      layers = {
        {
          filename = filename or "__bitermotors__/graphics/entity/biterfactory/biterfactory.png",
          priority = "high",
          width = 1024,
          height = 1024,
          frame_count = 1,
          line_length = 1,
          shift = {0, 0},
          scale = 0.325
        }
      }
    },
    working_visualisations = {
      working_animation(activity_slug, 512, 512, 0.325, {0, 0}, activity_speed, false),
      working_animation("biterfactory-loading-lights", 512, 128, 0.325, {0, 3.9}, loading_speed, true)
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
      tint = {r = 0.18, g = 0.48, b = 0.24, a = 0.16}
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
    error("Biter Motors recipe " .. name .. " has more than four ingredients")
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

local function tech(name, icon, prerequisites, effects, count, ingredients, time, extra)
  local prototype = {
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
  for key, value in pairs(extra or {}) do
    prototype[key] = value
  end
  return prototype
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
  prototype.inventory_size = 2
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

local function copied_electric_vehicle(name, icons, primary, secondary, profile)
  local prototype = table.deepcopy(data.raw.car.car)
  prototype.name = name
  prototype.icon = nil
  prototype.icons = icons
  prototype.minable = {mining_time = 0.4, result = name}
  prototype.equipment_grid = profile.equipment_grid or "medium-equipment-grid"
  prototype.energy_source = {
    type = "burner",
    fuel_categories = {"bitermotors-electric-drive"},
    effectivity = 1,
    fuel_inventory_size = 1,
    emissions_per_minute = {}
  }
  prototype.consumption = profile.consumption
  prototype.weight = profile.weight
  prototype.max_health = profile.max_health
  prototype.rotation_speed = prototype.rotation_speed * profile.rotation_multiplier
  prototype.braking_force = prototype.braking_force * profile.braking_multiplier
  prototype.friction_force = profile.friction_force
  prototype.energy_per_hit_point = profile.energy_per_hit_point
  prototype.inventory_size = profile.inventory_size
  prototype.resistances = profile.resistances or prototype.resistances
  prototype.working_sound = {
    main_sounds = {
      {
        sound = {
          filename = "__bitermotors__/sound/ev-drivetrain-loop.wav",
          volume = 0.72,
          audible_distance_modifier = 0.9
        },
        match_volume_to_activity = true,
        activity_to_volume_modifiers = {
          multiplier = 1.25,
          offset = 0.12
        },
        match_speed_to_activity = true,
        activity_to_speed_modifiers = {
          multiplier = 1.15,
          minimum = 0.72,
          maximum = 1.9,
          offset = 0.05
        }
      }
    }
  }
  if profile.artwork then
    local animation_layers = {
      {
        filename = "__bitermotors__/graphics/entity/vehicles/" .. profile.artwork .. ".png",
        priority = "high",
        width = 192,
        height = 192,
        direction_count = 64,
        line_length = 8,
        scale = profile.sprite_scale or 0.72
      }
    }
    if profile.artwork then
      animation_layers[#animation_layers + 1] = {
        filename = "__bitermotors__/graphics/entity/vehicles/" .. profile.artwork .. "-shadow.png",
        priority = "high",
        width = 192,
        height = 192,
        direction_count = 64,
        line_length = 8,
        scale = profile.sprite_scale or 0.72,
        draw_as_shadow = true
      }
    end
    prototype.animation = {
      layers = animation_layers
    }
    prototype.turret_animation = nil
    prototype.light_animation = nil
  else
    tint_animation_masks(prototype.animation, primary, secondary)
    tint_animation_masks(prototype.turret_animation, primary, secondary)
  end
  return prototype
end

data:extend({
  {
    type = "sound",
    name = "bitermotors-ev-reverse-warning",
    filename = "__bitermotors__/sound/ev-reverse-warning.wav",
    volume = 0.58,
    audible_distance_modifier = 0.75
  }
})

local function hidden_grid_connection_pole()
  local prototype = table.deepcopy(data.raw["electric-pole"]["medium-electric-pole"])
  prototype.name = "bitermotors-ev-charging-grid-connection"
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
  prototype.maximum_wire_distance = 0
  prototype.auto_connect_up_to_n_wires = 0
  prototype.rewire_neighbours_when_destroying = false
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
        filename = "__bitermotors__/graphics/entity/transparent.png",
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
    icon = "__bitermotors__/graphics/icons/ev-charging-station.png",
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
      filename = "__bitermotors__/graphics/entity/transparent.png",
      priority = "extra-high",
      width = 1,
      height = 1
    }
  }
end

local dollar_icon = icon64("__base__/graphics/icons/coin.png", {r = 1.0, g = 0.86, b = 0.25, a = 1.0})
local ev_reservation_icon = generated_icon("ev-reservation")
local wrecked_ev_icon = generated_icon("wrecked-ev")
local ai_token_icon = generated_icon("ai-token")
local agi_model_icon = generated_icon("agi-model")
local biterfactory_module_icon = generated_icon("biterfactory-module")
local biterfactory_icon = generated_icon("biterfactory")
local structural_casting_icon = generated_icon("structural-casting")
local biterfactory_v2_icon = generated_icon("biterfactory-v2")
local ev_charging_station_icon = generated_icon("ev-charging-station")
local ev_charging_station_v2_icon = generated_icon("ev-charging-station-v2")
local ev_charging_station_v3_icon = generated_icon("ev-charging-station-v3")
local ev_charging_station_v4_icon = generated_icon("ev-charging-station-v4")
local sales_office_icon_path = "__bitermotors__/graphics/icons/sales-office.png"
local sales_office_entity_path = "__bitermotors__/graphics/entity/sales-office/sales-office.png"
local sales_office_icon = {
  {
    icon = sales_office_icon_path,
    icon_size = 256
  }
}
local datacenter_icon = generated_icon("terrestrial-datacenter")
local orbital_datacenter_core_icon = generated_icon("orbital-datacenter-core")
local orbital_radiator_panel_icon = generated_icon("orbital-radiator-panel")
local high_density_space_solar_panel_icon = generated_icon("high-density-space-solar-panel")
local planetary_grid_controller_icon = generated_icon("planetary-grid-controller")
local high_density_solar_array_icon = generated_icon("high-density-solar-array")
local tandem_solar_array_icon = generated_icon("tandem-solar-array")
local grid_battery_icon = generated_icon("grid-battery")
local grid_battery_array_icon = generated_icon("grid-battery-array")
local bitertaxi_depot_icon = generated_icon("bitertaxi-depot")
local megatruck_icon = generated_icon("megatruck")
local espider_icon = generated_icon("espider")

local runtime_visual_sprites = {}
for frame_index = 1, 8 do
  for _, visual in pairs({
    {name = "bitertaxi-dispatch-lights", width = 128, height = 64}
  }) do
    runtime_visual_sprites[#runtime_visual_sprites + 1] = {
      type = "sprite",
      name = "bitermotors-" .. visual.name .. "-frame-" .. frame_index,
      filename = "__bitermotors__/graphics/animation/" .. visual.name .. "-frame-" .. frame_index .. ".png",
      width = visual.width,
      height = visual.height,
      blend_mode = "additive",
      draw_as_glow = true
    }
  end
end
data:extend(runtime_visual_sprites)

local charger_stall_visual_sprites = {}
for frame_index = 1, 8 do
  for _, visual in pairs({
    {state = "idle", filename = "__bitermotors__/graphics/animation/charger-stall-idle.png"},
    {state = "low", filename = "__bitermotors__/graphics/animation/charger-stall-low.png"},
    {state = "medium", filename = "__bitermotors__/graphics/animation/charger-stall-medium.png"},
    {state = "full", filename = "__bitermotors__/graphics/animation/charger-stall-full.png"},
    {state = "overload", filename = "__bitermotors__/graphics/animation/charger-stall-overload.png"},
    {state = "charging", filename = "__bitermotors__/graphics/animation/charger-stall-charging.png"}
  }) do
    charger_stall_visual_sprites[#charger_stall_visual_sprites + 1] = {
      type = "sprite",
      name = "bitermotors-charger-stall-" .. visual.state .. "-frame-" .. frame_index,
      filename = visual.filename,
      width = 32,
      height = 32,
      x = (frame_index - 1) * 32
    }
  end
end
data:extend(charger_stall_visual_sprites)

local sales_office_status_sprites = {}
for frame_index = 1, 8 do
  for _, status in pairs({
    {color = "green", filename = "__bitermotors__/graphics/animation/sales-office-status-green.png"},
    {color = "amber", filename = "__bitermotors__/graphics/animation/sales-office-status-amber.png"},
    {color = "red", filename = "__bitermotors__/graphics/animation/sales-office-status-red.png"}
  }) do
    sales_office_status_sprites[#sales_office_status_sprites + 1] = {
      type = "sprite",
      name = "bitermotors-sales-office-status-" .. status.color .. "-frame-" .. frame_index,
      filename = status.filename,
      width = 64,
      height = 64,
      x = (frame_index - 1) * 64
    }
  end
end
data:extend(sales_office_status_sprites)

local sales_office_showroom_sprites = {}
for _, vehicle in pairs({
  {
    name = "prototype-roadster",
    filename = "__bitermotors__/graphics/animation/sales-office-showroom-prototype-roadster.png"
  },
  {
    name = "premium-ev",
    filename = "__bitermotors__/graphics/animation/sales-office-showroom-premium-ev.png"
  },
  {
    name = "mass-market-ev",
    filename = "__bitermotors__/graphics/animation/sales-office-showroom-mass-market-ev.png"
  },
  {
    name = "megatruck",
    filename = "__bitermotors__/graphics/animation/sales-office-showroom-megatruck.png"
  }
}) do
  for frame_index = 1, 8 do
    sales_office_showroom_sprites[#sales_office_showroom_sprites + 1] = {
      type = "sprite",
      name = "bitermotors-sales-office-showroom-" .. vehicle.name .. "-frame-" .. frame_index,
      filename = vehicle.filename,
      width = 512,
      height = 512,
      x = (frame_index - 1) * 512
    }
  end
end
data:extend(sales_office_showroom_sprites)

data:extend({
  {
    type = "selection-tool",
    name = "bitermotors-ev-self-driving-destination",
    icon = "__bitermotors__/graphics/icons/mass-market-ev.png",
    icon_size = 256,
    flags = {"only-in-cursor", "not-stackable", "spawnable", "always-show"},
    hidden = true,
    subgroup = "spawnables",
    order = "z[bitermotors]-c[ev-self-driving-destination]",
    stack_size = 1,
    always_include_tiles = true,
    select = {
      border_color = {r = 0.15, g = 0.85, b = 0.55},
      mode = {"any-tile"},
      cursor_box_type = "copy"
    },
    alt_select = {
      border_color = {r = 0.15, g = 0.85, b = 0.55},
      mode = {"any-tile"},
      cursor_box_type = "copy"
    }
  },
  {
    type = "shortcut",
    name = "bitermotors-open-progress",
    order = "z[bitermotors]-a[progress]",
    action = "lua",
    icon = "__bitermotors__/graphics/icons/bitermotors-group.png",
    icon_size = 256,
    small_icon = "__bitermotors__/graphics/icons/bitermotors-group.png",
    small_icon_size = 256
  },
  {
    type = "shortcut",
    name = "bitermotors-toggle-sales-office-coverage",
    order = "z[bitermotors]-b[sales-office-coverage]",
    action = "lua",
    toggleable = true,
    technology_to_unlock = "bitermotors-sales-office",
    icon = "__bitermotors__/graphics/icons/sales-office-coverage.png",
    icon_size = 256,
    small_icon = "__bitermotors__/graphics/icons/sales-office-coverage.png",
    small_icon_size = 256
  },
  {
    type = "shortcut",
    name = "bitermotors-toggle-bitertaxi-coverage",
    order = "z[bitermotors]-c[bitertaxi-coverage]",
    action = "lua",
    toggleable = true,
    technology_to_unlock = "bitermotors-autonomous-logistics",
    icon = "__bitermotors__/graphics/icons/bitertaxi-depot.png",
    icon_size = 256,
    small_icon = "__bitermotors__/graphics/icons/bitertaxi-depot.png",
    small_icon_size = 256
  },
  {
    type = "shortcut",
    name = "bitermotors-route-ev",
    order = "z[bitermotors]-d[route]",
    action = "spawn-item",
    item_to_spawn = "bitermotors-ev-self-driving-destination",
    technology_to_unlock = "bitermotors-autonomous-logistics",
    icon = "__bitermotors__/graphics/icons/mass-market-ev.png",
    icon_size = 256,
    small_icon = "__bitermotors__/graphics/icons/mass-market-ev.png",
    small_icon_size = 256
  },
  {
    type = "shortcut",
    name = "bitermotors-summon-ev",
    order = "z[bitermotors]-e[summon]",
    action = "lua",
    technology_to_unlock = "bitermotors-autonomous-logistics",
    icon = "__bitermotors__/graphics/icons/bitertaxi-fleet.png",
    icon_size = 256,
    small_icon = "__bitermotors__/graphics/icons/bitertaxi-fleet.png",
    small_icon_size = 256
  },
  {
    type = "custom-input",
    name = "bitermotors-open-settlement-inspector",
    key_sequence = "",
    linked_game_control = "open-gui",
    consuming = "none",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "bitermotors-ev-self-driving-manual-up",
    key_sequence = "",
    linked_game_control = "move-up",
    consuming = "none",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "bitermotors-ev-self-driving-manual-down",
    key_sequence = "",
    linked_game_control = "move-down",
    consuming = "none",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "bitermotors-ev-self-driving-manual-left",
    key_sequence = "",
    linked_game_control = "move-left",
    consuming = "none",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "bitermotors-ev-self-driving-manual-right",
    key_sequence = "",
    linked_game_control = "move-right",
    consuming = "none",
    action = "lua"
  },
  {
    type = "item-subgroup",
    name = "bitermotors-infrastructure",
    group = "production",
    order = "ea[bitermotors-infrastructure]"
  },
  {
    type = "item-subgroup",
    name = "bitermotors-charging",
    group = "production",
    order = "eb[bitermotors-charging]"
  },
  {
    type = "item-subgroup",
    name = "bitermotors-components",
    group = "intermediate-products",
    order = "za[bitermotors-components]"
  },
  {
    type = "item-subgroup",
    name = "bitermotors-capital",
    group = "intermediate-products",
    order = "zb[bitermotors-capital]"
  },
  {
    type = "recipe-category",
    name = "bitermotors-sales"
  },
  {
    type = "recipe-category",
    name = "bitermotors-vehicle-assembly"
  },
  {
    type = "recipe-category",
    name = "bitermotors-mass-vehicle-assembly"
  },
  {
    type = "recipe-category",
    name = "bitermotors-energy-products"
  },
  {
    type = "recipe-category",
    name = "bitermotors-energy-products-batch"
  },
  {
    type = "recipe-category",
    name = "bitermotors-vertical-integration"
  },
  {
    type = "recipe-category",
    name = "bitermotors-datacenter"
  },
  {
    type = "recipe-category",
    name = "bitermotors-orbital-compute"
  },
  {
    type = "recipe-category",
    name = "bitermotors-planetary-grid"
  },
  {
    type = "recipe-category",
    name = "bitermotors-bitertaxi-depot"
  },
  {
    type = "fuel-category",
    name = "bitermotors-electric-drive"
  },
  {
    type = "fuel-category",
    name = "bitermotors-cybertrain-drive"
  },
  {
    type = "fuel-category",
    name = "bitermotors-espider-drive"
  }
})

local nickel_ore = table.deepcopy(data.raw.resource["uranium-ore"])
nickel_ore.name = "bitermotors-nickel-ore"
nickel_ore.icon = "__bitermotors__/graphics/icons/nickel-ore.png"
nickel_ore.icon_size = 256
nickel_ore.icons = nil
nickel_ore.minable.result = "bitermotors-nickel-ore"
nickel_ore.minable.mining_particle = nil
nickel_ore.autoplace = nil
nickel_ore.map_color = {r = 0.36, g = 0.62, b = 0.54}
nickel_ore.mining_visualisation_tint = {r = 0.52, g = 0.82, b = 0.68, a = 1}

local lithium_brine = table.deepcopy(data.raw.fluid["crude-oil"])
lithium_brine.name = "bitermotors-lithium-brine"
lithium_brine.icon = "__bitermotors__/graphics/icons/lithium-brine.png"
lithium_brine.icon_size = 256
lithium_brine.icons = nil
lithium_brine.base_color = {r = 0.58, g = 0.82, b = 0.86}
lithium_brine.flow_color = {r = 0.78, g = 0.96, b = 1.0}
lithium_brine.default_temperature = 25

local acidic_tailings = table.deepcopy(data.raw.fluid["sulfuric-acid"])
acidic_tailings.name = "bitermotors-acidic-tailings"
acidic_tailings.icon = "__bitermotors__/graphics/icons/acidic-tailings.png"
acidic_tailings.icon_size = 256
acidic_tailings.icons = nil
acidic_tailings.base_color = {r = 0.32, g = 0.42, b = 0.16}
acidic_tailings.flow_color = {r = 0.55, g = 0.62, b = 0.22}

local lithium_brine_resource = table.deepcopy(data.raw.resource["crude-oil"])
lithium_brine_resource.name = "bitermotors-lithium-brine"
lithium_brine_resource.icon = "__bitermotors__/graphics/icons/lithium-brine.png"
lithium_brine_resource.icon_size = 256
lithium_brine_resource.icons = nil
lithium_brine_resource.minable.results[1].name = "bitermotors-lithium-brine"
lithium_brine_resource.autoplace = nil
lithium_brine_resource.map_color = {r = 0.42, g = 0.78, b = 0.88}

data:extend({
  {type = "autoplace-control", name = "bitermotors-nickel-ore", category = "resource", richness = true, order = "b-f"},
  {type = "autoplace-control", name = "bitermotors-lithium-brine", category = "resource", richness = true, order = "c-b"},
  nickel_ore,
  lithium_brine,
  acidic_tailings,
  lithium_brine_resource
})

local espider_item = table.deepcopy(data.raw["item-with-entity-data"].spidertron)
espider_item.name = "bitermotors-espider"
espider_item.icon = nil
espider_item.icon_tintable = nil
espider_item.icon_tintable_mask = nil
espider_item.icons = espider_icon
espider_item.order = "bitermotors-h[espider]"
espider_item.place_result = "bitermotors-espider"
espider_item.stack_size = 1

data:extend({
  item("bitermotors-dollar", dollar_icon, "bitermotors-capital", "a[dollar]", 100000, {
    flags = {"always-show"}
  }),
  item("bitermotors-ev-reservation", ev_reservation_icon, "raw-material", "z[bitermotors-ev-reservation]", 1000, {
    flags = {"always-show"}
  }),
  item("bitermotors-wrecked-ev", wrecked_ev_icon, "bitermotors-components", "z[wrecked-ev]", 1, {
    flags = {"always-show"}
  }),
  item("bitermotors-biterfactory-module", biterfactory_module_icon, "bitermotors-components", "c[biterfactory-module]", 1),
  item("bitermotors-structural-casting", structural_casting_icon, "bitermotors-components", "d[structural-casting]", 10),
  item("bitermotors-ai-token", ai_token_icon, "science-pack", "h[bitermotors-ai-token]", 1000000, {
    flags = {"always-show"},
    weight = 1
  }),
  item("bitermotors-agi-training-dataset", ai_token_icon, "science-pack", "h[agi-training-dataset]", 10000),
  item("bitermotors-capital-allocation", dollar_icon, "bitermotors-capital", "b[capital-allocation]", 10000),
  item("bitermotors-agi-model", agi_model_icon, "science-pack", "i[agi-model]", 1),

  item("bitermotors-nickel-ore", generated_icon("nickel-ore"), "raw-resource", "z-a[nickel-ore]", 50),
  item("bitermotors-nickel-sulfate", generated_icon("nickel-sulfate"), "bitermotors-components", "a-a[nickel-sulfate]", 100),
  item("bitermotors-lithium-carbonate", generated_icon("lithium-carbonate"), "bitermotors-components", "a-b[lithium-carbonate]", 100),
  item("bitermotors-battery-graphite", generated_icon("battery-graphite"), "bitermotors-components", "a-c[battery-graphite]", 100),
  item("bitermotors-cobalt-concentrate", generated_icon("cobalt-concentrate"), "bitermotors-components", "a-d[cobalt-concentrate]", 100),
  item("bitermotors-phosphate", generated_icon("phosphate"), "bitermotors-components", "a-e[phosphate]", 100),
  item("bitermotors-high-nickel-cell", generated_icon("high-nickel-cell"), "bitermotors-components", "b-a[high-nickel-cell]", 100),
  item("bitermotors-lfp-cell", generated_icon("lfp-cell"), "bitermotors-components", "b-b[lfp-cell]", 100),
  item("bitermotors-high-energy-battery-pack", generated_icon("high-energy-battery-pack"), "bitermotors-components", "c-a[high-energy-pack]", 20),
  item("bitermotors-lfp-battery-pack", generated_icon("lfp-battery-pack"), "bitermotors-components", "c-b[lfp-pack]", 20),
  item("bitermotors-damaged-high-energy-battery-pack", generated_icon("damaged-high-energy-battery-pack"), "bitermotors-components", "d-a[damaged-high-energy-pack]", 20, {
    flags = {"always-show"}
  }),
  item("bitermotors-damaged-lfp-battery-pack", generated_icon("damaged-lfp-battery-pack"), "bitermotors-components", "d-b[damaged-lfp-pack]", 20, {
    flags = {"always-show"}
  }),
  item("bitermotors-electric-drivetrain", generated_icon("electric-drivetrain"), "bitermotors-components", "b[electric-drivetrain]", 50),
  item("bitermotors-prototype-roadster", generated_icon("prototype-roadster"), "transport", "bitermotors-a[prototype-roadster]", 1, {place_result = "bitermotors-prototype-roadster"}),
  item("bitermotors-premium-ev", generated_icon("premium-ev"), "transport", "bitermotors-b[premium-ev]", 1, {place_result = "bitermotors-premium-ev"}),
  item("bitermotors-mass-market-ev", generated_icon("mass-market-ev"), "transport", "bitermotors-c[mass-market-ev]", 1, {place_result = "bitermotors-mass-market-ev"}),
  item("bitermotors-megatruck", megatruck_icon, "transport", "bitermotors-d[megatruck]", 1, {place_result = "bitermotors-megatruck"}),
  item("bitermotors-autonomy-computer", generated_icon("autonomy-computer"), "bitermotors-components", "e[autonomy-computer]", 50),
  item("bitermotors-bitertaxi-fleet", generated_icon("bitertaxi-fleet"), "transport", "bitermotors-e[bitertaxi-fleet]", 5, {place_result = "bitermotors-bitertaxi-fleet"}),
  espider_item,

  item("bitermotors-electric-drive-charge", icon64("__base__/graphics/icons/battery.png"), "other", "z[bitermotors-electric-drive-charge]", 1, {
    hidden = true,
    fuel_category = "bitermotors-electric-drive",
    fuel_value = "1MJ",
    fuel_acceleration_multiplier = 1.15,
    fuel_top_speed_multiplier = 1.05
  }),
  item("bitermotors-cybertrain-drive-charge", generated_icon("cybertrain-drive-charge"), "other", "z[bitermotors-cybertrain-drive-charge]", 1000, {
    hidden = true,
    fuel_category = "bitermotors-cybertrain-drive",
    fuel_value = "1MJ",
    fuel_acceleration_multiplier = 2.0,
    fuel_top_speed_multiplier = 1.5
  }),
  item("bitermotors-espider-drive-charge", icon64("__space-age__/graphics/icons/battery-mk3-equipment.png"), "other", "z[bitermotors-espider-drive-charge]", 1, {
    hidden = true,
    fuel_category = "bitermotors-espider-drive",
    fuel_value = "10MJ",
    fuel_acceleration_multiplier = 1,
    fuel_top_speed_multiplier = 1
  }),
  item("bitermotors-espider-reserve-charge", icon64("__base__/graphics/icons/battery.png", {r = 1.0, g = 0.55, b = 0.18, a = 1.0}), "other", "z[bitermotors-espider-reserve-charge]", 1, {
    hidden = true,
    fuel_category = "bitermotors-espider-drive",
    fuel_value = "10MJ",
    fuel_acceleration_multiplier = 0.2,
    fuel_top_speed_multiplier = 0.1
  }),

  item("bitermotors-datacenter-rack", generated_icon("datacenter-rack"), "bitermotors-components", "f[datacenter-rack]", 50),

  item("bitermotors-sales-office", sales_office_icon, "bitermotors-infrastructure", "a[sales-office]", 10, {place_result = "bitermotors-sales-office"}),
  item("bitermotors-ev-charging-station", ev_charging_station_icon, "bitermotors-charging", "a[ev-charging-station]", 5, {place_result = "bitermotors-ev-charging-station"}),
  item("bitermotors-ev-charging-station-v2", ev_charging_station_v2_icon, "bitermotors-charging", "b[ev-charging-station-v2]", 5, {place_result = "bitermotors-ev-charging-station-v2"}),
  item("bitermotors-ev-charging-station-v3", ev_charging_station_v3_icon, "bitermotors-charging", "c[ev-charging-station-v3]", 5, {place_result = "bitermotors-ev-charging-station-v3"}),
  item("bitermotors-ev-charging-station-v4", ev_charging_station_v4_icon, "bitermotors-charging", "d[ev-charging-station-v4]", 5, {place_result = "bitermotors-ev-charging-station-v4"}),
  item("bitermotors-biterfactory-building", biterfactory_icon, "bitermotors-infrastructure", "f[biterfactory]", 1, {place_result = "bitermotors-biterfactory-building"}),
  item("bitermotors-biterfactory-v2", biterfactory_v2_icon, "bitermotors-infrastructure", "g[biterfactory-v2]", 1, {place_result = "bitermotors-biterfactory-v2"}),
  item("bitermotors-high-density-solar-array", high_density_solar_array_icon, "energy", "bitermotors-a[high-density-solar-array]", 10, {place_result = "bitermotors-high-density-solar-array"}),
  item("bitermotors-tandem-solar-array", tandem_solar_array_icon, "energy", "bitermotors-a2[tandem-solar-array]", 10, {place_result = "bitermotors-tandem-solar-array"}),
  item("bitermotors-grid-battery", grid_battery_icon, "energy", "bitermotors-b[grid-battery]", 10, {place_result = "bitermotors-grid-battery"}),
  item("bitermotors-grid-battery-array", grid_battery_array_icon, "energy", "bitermotors-b2[grid-battery-array]", 10, {place_result = "bitermotors-grid-battery-array"}),
  item("bitermotors-terrestrial-datacenter", datacenter_icon, "bitermotors-infrastructure", "f[terrestrial-datacenter]", 1, {place_result = "bitermotors-terrestrial-datacenter"}),
  item("bitermotors-bitertaxi-depot", bitertaxi_depot_icon, "bitermotors-infrastructure", "g[bitertaxi-depot]", 1, {place_result = "bitermotors-bitertaxi-depot"}),
  item("bitermotors-cybertrain", generated_icon("cybertrain"), "transport", "bitermotors-f[cybertrain]", 5, {place_result = "bitermotors-cybertrain"}),
  item("bitermotors-cybertrain-charging-stop", generated_icon("cybertrain-charging-stop"), "transport", "bitermotors-g[cybertrain-charging-stop]", 10, {place_result = "bitermotors-cybertrain-charging-stop"}),
  item("bitermotors-orbital-datacenter-core", orbital_datacenter_core_icon, "bitermotors-infrastructure", "h[orbital-datacenter-core]", 1, {place_result = "bitermotors-orbital-datacenter-core"}),
  item("bitermotors-orbital-radiator-panel", orbital_radiator_panel_icon, "energy", "c[orbital-radiator-panel]", 10, {place_result = "bitermotors-orbital-radiator-panel"}),
  item("bitermotors-high-density-space-solar-panel", high_density_space_solar_panel_icon, "energy", "d[high-density-space-solar-panel]", 10, {place_result = "bitermotors-high-density-space-solar-panel"}),
  item("bitermotors-planetary-grid-controller", planetary_grid_controller_icon, "bitermotors-infrastructure", "h[planetary-grid-controller]", 1, {place_result = "bitermotors-planetary-grid-controller"})
})

local sales_office = copied_assembler(
  "assembling-machine-2",
  "bitermotors-sales-office",
  sales_office_icon,
  "bitermotors-sales-office",
  {"bitermotors-sales"},
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
        shift = {0, 0},
        scale = 0.19
      }
    }
  }
}
sales_office.radius_visualisation_specification = customer_radius_visualisation(128)

local ev_charging_station = copied_reservation_output_site(
  "substation",
  "bitermotors-ev-charging-station",
  ev_charging_station_icon,
  "bitermotors-ev-charging-station"
)
ev_charging_station.robot_door.animation = generated_entity_picture("ev-charging-station", nil, 0.14)
ev_charging_station.radius_visualisation_specification = customer_radius_visualisation(64)

local ev_charging_station_v2 = copied_reservation_output_site(
  "substation",
  "bitermotors-ev-charging-station-v2",
  ev_charging_station_v2_icon,
  "bitermotors-ev-charging-station-v2"
)
ev_charging_station_v2.max_health = 500
ev_charging_station_v2.collision_box = {{-1.9, -1.9}, {1.9, 1.9}}
ev_charging_station_v2.selection_box = {{-2, -2}, {2, 2}}
ev_charging_station_v2.robot_door.animation = generated_entity_picture("ev-charging-station-v2", nil, 0.26)
ev_charging_station_v2.radius_visualisation_specification = customer_radius_visualisation(128)

local ev_charging_station_v3 = copied_reservation_output_site(
  "substation",
  "bitermotors-ev-charging-station-v3",
  ev_charging_station_v3_icon,
  "bitermotors-ev-charging-station-v3"
)
ev_charging_station_v3.max_health = 750
ev_charging_station_v3.collision_box = {{-2.4, -2.4}, {2.4, 2.4}}
ev_charging_station_v3.selection_box = {{-2.5, -2.5}, {2.5, 2.5}}
ev_charging_station_v3.robot_door.animation = generated_entity_picture("ev-charging-station-v3", nil, 0.35)
ev_charging_station_v3.radius_visualisation_specification = customer_radius_visualisation(192)

local ev_charging_station_v4 = copied_reservation_output_site(
  "substation",
  "bitermotors-ev-charging-station-v4",
  ev_charging_station_v4_icon,
  "bitermotors-ev-charging-station-v4"
)
ev_charging_station_v4.max_health = 1000
ev_charging_station_v4.collision_box = {{-2.9, -2.9}, {2.9, 2.9}}
ev_charging_station_v4.selection_box = {{-3, -3}, {3, 3}}
ev_charging_station_v4.robot_door.animation = generated_entity_picture("ev-charging-station-v4", nil, 0.38)
ev_charging_station_v4.radius_visualisation_specification = customer_radius_visualisation(256)

local biterfactory = copied_assembler(
  "assembling-machine-2",
  "bitermotors-biterfactory-building",
  biterfactory_icon,
  "bitermotors-biterfactory-building",
  {"advanced-crafting", "bitermotors-vehicle-assembly", "bitermotors-energy-products", "bitermotors-energy-products-batch", "bitermotors-vertical-integration"},
  "20MW",
  4
)
biterfactory.max_health = 5000
biterfactory.collision_box = {{-4.4, -4.4}, {4.4, 4.4}}
biterfactory.selection_box = {{-4.5, -4.5}, {4.5, 4.5}}
biterfactory.drawing_box_vertical_extension = 1.0
biterfactory.energy_source.emissions_per_minute = {pollution = 12}
biterfactory.module_slots = 8
biterfactory.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
biterfactory.effect_receiver = {base_effect = {productivity = 0.5}}
biterfactory.graphics_set = biterfactory_animation()
biterfactory.fast_replaceable_group = "bitermotors-biterfactory"
biterfactory.next_upgrade = "bitermotors-biterfactory-v2"

local biterfactory_v2 = copied_assembler(
  "assembling-machine-2",
  "bitermotors-biterfactory-v2",
  biterfactory_v2_icon,
  "bitermotors-biterfactory-v2",
  {"advanced-crafting", "bitermotors-vehicle-assembly", "bitermotors-mass-vehicle-assembly", "bitermotors-energy-products", "bitermotors-energy-products-batch", "bitermotors-vertical-integration"},
  "30MW",
  8
)
biterfactory_v2.max_health = 7500
biterfactory_v2.collision_box = {{-4.4, -4.4}, {4.4, 4.4}}
biterfactory_v2.selection_box = {{-4.5, -4.5}, {4.5, 4.5}}
biterfactory_v2.drawing_box_vertical_extension = 1.0
biterfactory_v2.energy_source.emissions_per_minute = {pollution = 18}
biterfactory_v2.module_slots = 8
biterfactory_v2.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
biterfactory_v2.effect_receiver = {base_effect = {productivity = 1.5}}
biterfactory_v2.graphics_set = biterfactory_animation("__bitermotors__/graphics/entity/biterfactory/biterfactory-v2.png", 2)
biterfactory_v2.fast_replaceable_group = "bitermotors-biterfactory"

local high_density_solar_array = copied_energy_entity(
  "solar-panel",
  "solar-panel",
  "bitermotors-high-density-solar-array",
  high_density_solar_array_icon,
  "bitermotors-high-density-solar-array"
)
high_density_solar_array.max_health = 500
high_density_solar_array.production = "300kW"
high_density_solar_array.fast_replaceable_group = "solar-panel"
high_density_solar_array.next_upgrade = "bitermotors-tandem-solar-array"
high_density_solar_array.collision_box = {{-1.35, -1.35}, {1.35, 1.35}}
high_density_solar_array.selection_box = {{-1.5, -1.5}, {1.5, 1.5}}
high_density_solar_array.picture = {
  layers = {
    {
      filename = "__bitermotors__/graphics/entity/high-density-solar-array/high-density-solar-array.png",
      priority = "high",
      width = 512,
      height = 512,
      scale = 0.19
    },
    {
      filename = "__bitermotors__/graphics/entity/high-density-solar-array/high-density-solar-array-shadow.png",
      priority = "high",
      width = 512,
      height = 512,
      scale = 0.19,
      draw_as_shadow = true
    }
  }
}
high_density_solar_array.overlay = nil
high_density_solar_array.water_reflection = nil
data.raw["solar-panel"]["solar-panel"].fast_replaceable_group = "solar-panel"
data.raw["solar-panel"]["solar-panel"].next_upgrade = "bitermotors-high-density-solar-array"

local tandem_solar_array = table.deepcopy(high_density_solar_array)
tandem_solar_array.name = "bitermotors-tandem-solar-array"
tandem_solar_array.icons = tandem_solar_array_icon
tandem_solar_array.minable = {mining_time = 0.2, result = "bitermotors-tandem-solar-array"}
tandem_solar_array.production = "3MW"
tandem_solar_array.next_upgrade = nil

local grid_battery = copied_energy_entity(
  "accumulator",
  "accumulator",
  "bitermotors-grid-battery",
  grid_battery_icon,
  "bitermotors-grid-battery"
)
grid_battery.max_health = 600
grid_battery.energy_source.buffer_capacity = "100MJ"
grid_battery.energy_source.input_flow_limit = "5MW"
grid_battery.energy_source.output_flow_limit = "5MW"
grid_battery.fast_replaceable_group = "bitermotors-grid-battery"
grid_battery.next_upgrade = "bitermotors-grid-battery-array"
grid_battery.chargable_graphics = {
  picture = {
    layers = {
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery.png",
        priority = "high",
        width = 512,
        height = 512,
        scale = 0.14
      },
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery-shadow.png",
        priority = "high",
        width = 512,
        height = 512,
        scale = 0.14,
        draw_as_shadow = true
      }
    }
  },
  charge_animation = {
    layers = {
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery.png",
        priority = "high",
        width = 512,
        height = 512,
        repeat_count = 8,
        scale = 0.14
      },
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery-shadow.png",
        priority = "high",
        width = 512,
        height = 512,
        repeat_count = 8,
        scale = 0.14,
        draw_as_shadow = true
      },
      {
        filename = "__bitermotors__/graphics/animation/grid-battery-charge.png",
        priority = "high",
        width = 512,
        height = 512,
        frame_count = 8,
        line_length = 8,
        animation_speed = 0.22,
        scale = 0.14,
        blend_mode = "additive",
        draw_as_glow = true
      }
    }
  },
  charge_cooldown = 30,
  discharge_animation = {
    layers = {
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery.png",
        priority = "high",
        width = 512,
        height = 512,
        repeat_count = 8,
        scale = 0.14
      },
      {
        filename = "__bitermotors__/graphics/entity/grid-battery/grid-battery-shadow.png",
        priority = "high",
        width = 512,
        height = 512,
        repeat_count = 8,
        scale = 0.14,
        draw_as_shadow = true
      },
      {
        filename = "__bitermotors__/graphics/animation/grid-battery-discharge.png",
        priority = "high",
        width = 512,
        height = 512,
        frame_count = 8,
        line_length = 8,
        animation_speed = 0.22,
        scale = 0.14,
        blend_mode = "additive",
        draw_as_glow = true
      }
    }
  },
  discharge_cooldown = 60
}
grid_battery.water_reflection = nil

local grid_battery_array = table.deepcopy(grid_battery)
grid_battery_array.name = "bitermotors-grid-battery-array"
grid_battery_array.icons = grid_battery_array_icon
grid_battery_array.minable = {mining_time = 0.2, result = "bitermotors-grid-battery-array"}
grid_battery_array.energy_source.buffer_capacity = "1GJ"
grid_battery_array.energy_source.input_flow_limit = "50MW"
grid_battery_array.energy_source.output_flow_limit = "50MW"
grid_battery_array.next_upgrade = nil

local terrestrial_datacenter = copied_assembler(
  "assembling-machine-2",
  "bitermotors-terrestrial-datacenter",
  datacenter_icon,
  "bitermotors-terrestrial-datacenter",
  {"bitermotors-datacenter"},
  "8MW",
  1
)
terrestrial_datacenter.energy_source.emissions_per_minute = {pollution = 2}
terrestrial_datacenter.module_slots = 0
terrestrial_datacenter.allowed_effects = {"consumption", "speed", "pollution", "quality"}
terrestrial_datacenter.collision_box = {{-2.9, -2.9}, {2.9, 2.9}}
terrestrial_datacenter.selection_box = {{-3, -3}, {3, 3}}
terrestrial_datacenter.graphics_set = generated_entity_animation("terrestrial-datacenter", 0.36, {
  working_animation("datacenter-cooling-fans", 128, 64, 0.55, {0, -1.65}, 0.4, false)
})

-- The operating fleet is private machine inventory. A logistic provider would
-- let requester chests remove Bitertaxis that are actively serving customers.
local bitertaxi_depot = table.deepcopy(data.raw.container["steel-chest"])
bitertaxi_depot.name = "bitermotors-bitertaxi-depot"
bitertaxi_depot.icons = bitertaxi_depot_icon
bitertaxi_depot.icon = nil
bitertaxi_depot.minable = {mining_time = 1, result = "bitermotors-bitertaxi-depot"}
bitertaxi_depot.inventory_size = 43
bitertaxi_depot.collision_box = {{-3.9, -3.9}, {3.9, 3.9}}
bitertaxi_depot.selection_box = {{-4, -4}, {4, 4}}
bitertaxi_depot.picture = generated_entity_picture("bitertaxi-depot", nil, 0.48)
bitertaxi_depot.radius_visualisation_specification = customer_radius_visualisation(256)

local bitertaxi_depot_power = copied_assembler(
  "assembling-machine-2",
  "bitermotors-bitertaxi-depot-power",
  bitertaxi_depot_icon,
  nil,
  {"bitermotors-bitertaxi-depot"},
  "10MW",
  1
)
bitertaxi_depot_power.flags = {
  "placeable-off-grid",
  "not-on-map",
  "not-blueprintable",
  "not-deconstructable"
}
bitertaxi_depot_power.minable = nil
bitertaxi_depot_power.selectable_in_game = false
bitertaxi_depot_power.collision_mask = {layers = {}}
bitertaxi_depot_power.collision_box = {{0, 0}, {0, 0}}
bitertaxi_depot_power.selection_box = {{0, 0}, {0, 0}}

local cybertrain_icon = generated_icon("cybertrain")
local cybertrain = table.deepcopy(data.raw.locomotive.locomotive)
cybertrain.name = "bitermotors-cybertrain"
cybertrain.icon = nil
cybertrain.icons = cybertrain_icon
cybertrain.minable = {mining_time = 0.5, result = "bitermotors-cybertrain"}
cybertrain.color = {r = 0.25, g = 0.65, b = 0.78, a = 1}
cybertrain.max_health = 1500
cybertrain.weight = 2400
cybertrain.max_speed = 3.0
cybertrain.max_power = "6MW"
cybertrain.reversing_power_modifier = 0.8
cybertrain.braking_force = 40
cybertrain.friction_force = 0.35
cybertrain.air_resistance = 0.0045
cybertrain.energy_source = {
  type = "burner",
  fuel_categories = {"bitermotors-cybertrain-drive"},
  effectivity = 1,
  fuel_inventory_size = 1,
  emissions_per_minute = {}
}
cybertrain.burner = nil
cybertrain.pictures = {
  rotated = {
    layers = {
      {
        filename = "__bitermotors__/graphics/entity/cybertrain/cybertrain.png",
        priority = "very-low",
        width = 256,
        height = 256,
        direction_count = 64,
        line_length = 8,
        allow_low_quality_rotation = true,
        usage = "train"
      },
      {
        filename = "__bitermotors__/graphics/entity/cybertrain/cybertrain-shadow.png",
        priority = "very-low",
        width = 256,
        height = 256,
        direction_count = 64,
        line_length = 8,
        allow_low_quality_rotation = true,
        draw_as_shadow = true,
        usage = "train"
      }
    }
  }
}
cybertrain.front_light_pictures = nil

local cybertrain_charging_stop_icon = generated_icon("cybertrain-charging-stop")
local cybertrain_charging_stop = table.deepcopy(data.raw["train-stop"]["train-stop"])
cybertrain_charging_stop.name = "bitermotors-cybertrain-charging-stop"
cybertrain_charging_stop.icon = nil
cybertrain_charging_stop.icons = cybertrain_charging_stop_icon
cybertrain_charging_stop.minable = {mining_time = 0.5, result = "bitermotors-cybertrain-charging-stop"}
cybertrain_charging_stop.color = {r = 0.25, g = 0.78, b = 0.92, a = 1}
local function cybertrain_stop_direction(frame)
  return {
    layers = {
      {
        filename = "__bitermotors__/graphics/entity/cybertrain-charging-stop/charging-stop.png",
        priority = "high",
        width = 256,
        height = 256,
        x = frame * 256,
        scale = 0.5,
        shift = {0, -0.15}
      },
      {
        filename = "__bitermotors__/graphics/entity/cybertrain-charging-stop/charging-stop-shadow.png",
        priority = "high",
        width = 256,
        height = 256,
        x = frame * 256,
        scale = 0.5,
        shift = {0, -0.15},
        draw_as_shadow = true
      }
    }
  }
end
cybertrain_charging_stop.animations = {
  north = cybertrain_stop_direction(0),
  east = cybertrain_stop_direction(1),
  south = cybertrain_stop_direction(2),
  west = cybertrain_stop_direction(3)
}
cybertrain_charging_stop.top_animations = nil
cybertrain_charging_stop.light1 = nil
cybertrain_charging_stop.light2 = nil

local cybertrain_charging_power = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
cybertrain_charging_power.name = "bitermotors-cybertrain-charging-power"
cybertrain_charging_power.icon = nil
cybertrain_charging_power.icons = cybertrain_charging_stop_icon
cybertrain_charging_power.flags = {"not-on-map", "not-blueprintable", "not-deconstructable"}
cybertrain_charging_power.minable = nil
cybertrain_charging_power.selectable_in_game = false
cybertrain_charging_power.collision_mask = {layers = {}}
cybertrain_charging_power.collision_box = {{0, 0}, {0, 0}}
cybertrain_charging_power.selection_box = {{0, 0}, {0, 0}}
cybertrain_charging_power.energy_source.buffer_capacity = "10MJ"
cybertrain_charging_power.energy_source.input_flow_limit = "50MW"
cybertrain_charging_power.energy_source.output_flow_limit = "0W"
cybertrain_charging_power.energy_production = "0W"
cybertrain_charging_power.energy_usage = "0W"
cybertrain_charging_power.picture = {
  filename = "__bitermotors__/graphics/entity/transparent.png",
  priority = "extra-high",
  width = 1,
  height = 1
}

local orbital_datacenter_core = copied_assembler(
  "assembling-machine-2",
  "bitermotors-orbital-datacenter-core",
  orbital_datacenter_core_icon,
  "bitermotors-orbital-datacenter-core",
  {"bitermotors-orbital-compute"},
  "250MW",
  1.5
)
orbital_datacenter_core.energy_source.emissions_per_minute = nil
orbital_datacenter_core.module_slots = 0
orbital_datacenter_core.allowed_effects = {"consumption", "speed", "pollution", "quality"}
orbital_datacenter_core.collision_box = {{-2.9, -2.9}, {2.9, 2.9}}
orbital_datacenter_core.selection_box = {{-3, -3}, {3, 3}}
orbital_datacenter_core.graphics_set = generated_entity_animation("orbital-datacenter-core", 0.36)
orbital_datacenter_core.surface_conditions = {
  {
    property = "gravity",
    min = 0,
    max = 0
  }
}

local orbital_radiator_panel = copied_energy_entity(
  "solar-panel",
  "solar-panel",
  "bitermotors-orbital-radiator-panel",
  orbital_radiator_panel_icon,
  "bitermotors-orbital-radiator-panel"
)
orbital_radiator_panel.production = "1kW"
orbital_radiator_panel.surface_conditions = {
  {
    property = "gravity",
    min = 0,
    max = 0
  }
}

local high_density_space_solar_panel = copied_energy_entity(
  "solar-panel",
  "solar-panel",
  "bitermotors-high-density-space-solar-panel",
  high_density_space_solar_panel_icon,
  "bitermotors-high-density-space-solar-panel"
)
high_density_space_solar_panel.max_health = 500
high_density_space_solar_panel.production = "50MW"
high_density_space_solar_panel.surface_conditions = {
  {
    property = "gravity",
    min = 0,
    max = 0
  }
}

local planetary_grid_controller = copied_assembler(
  "assembling-machine-2",
  "bitermotors-planetary-grid-controller",
  planetary_grid_controller_icon,
  "bitermotors-planetary-grid-controller",
  {"bitermotors-planetary-grid"},
  "10GW",
  1
)
planetary_grid_controller.energy_source.emissions_per_minute = nil
planetary_grid_controller.graphics_set = generated_entity_animation("planetary-grid-controller", 0.19, {
  working_animation("grid-charge-stages", 128, 128, 0.42, {0, -0.25}, 0.12, true)
})

local espider_legs = {}
for index = 1, 8 do
  local leg = table.deepcopy(data.raw["spider-leg"]["spidertron-leg-" .. index])
  leg.name = "bitermotors-espider-leg-" .. index
  leg.initial_movement_speed = leg.initial_movement_speed * 1.6
  leg.movement_acceleration = leg.movement_acceleration * 2
  espider_legs[#espider_legs + 1] = leg
end
data:extend(espider_legs)

local espider = table.deepcopy(data.raw["spider-vehicle"].spidertron)
espider.name = "bitermotors-espider"
espider.icon = nil
espider.icons = espider_icon
espider.minable = {mining_time = 1, result = "bitermotors-espider"}
espider.factoriopedia_simulation = nil
espider.guns = {"teslagun", "teslagun", "teslagun", "teslagun"}
espider.energy_source = {
  type = "burner",
  fuel_categories = {"bitermotors-espider-drive"},
  effectivity = 1,
  fuel_inventory_size = 1,
  emissions_per_minute = {}
}
espider.movement_energy_consumption = "8MW"
espider.torso_rotation_speed = 0.012
espider.spider_engine.walking_group_overlap = 0.25
for index, leg in ipairs(espider.spider_engine.legs) do
  leg.leg = "bitermotors-espider-leg-" .. index
end
tint_animation_masks(
  espider.graphics_set,
  {r = 0.08, g = 0.72, b = 0.88, a = 1.0},
  {r = 0.18, g = 0.95, b = 1.0, a = 1.0}
)

local electric_vehicles = {
  copied_electric_vehicle(
    "bitermotors-prototype-roadster", generated_icon("prototype-roadster"),
    {r = 0.90, g = 0.02, b = 0.01, a = 1}, {r = 1.00, g = 0.18, b = 0.08, a = 1},
    {consumption = "600kW", weight = 450, max_health = 240, rotation_multiplier = 1.35,
      braking_multiplier = 8.0, friction_force = 1.6e-3, energy_per_hit_point = 1.5, inventory_size = 20,
      artwork = "prototype-roadster", resistances = {
        {type = "impact", percent = -50},
        {type = "acid", percent = 10},
        {type = "fire", percent = 20}
      }}
  ),
  copied_electric_vehicle(
    "bitermotors-premium-ev", generated_icon("premium-ev"),
    {r = 0.015, g = 0.015, b = 0.015, a = 1}, {r = 0.12, g = 0.12, b = 0.12, a = 1},
    {consumption = "540kW", weight = 750, max_health = 550, rotation_multiplier = 1.1,
      braking_multiplier = 6.4, friction_force = 1.8e-3, energy_per_hit_point = 0.9, inventory_size = 40,
      artwork = "premium-ev"}
  ),
  copied_electric_vehicle(
    "bitermotors-mass-market-ev", generated_icon("mass-market-ev"),
    {r = 0.82, g = 0.82, b = 0.82, a = 1}, {r = 1.00, g = 1.00, b = 1.00, a = 1},
    {consumption = "240kW", weight = 800, max_health = 500, rotation_multiplier = 1.0,
      braking_multiplier = 5.5, friction_force = 1.9e-3, energy_per_hit_point = 1.0, inventory_size = 50,
      artwork = "mass-market-ev"}
  ),
  copied_electric_vehicle(
    "bitermotors-megatruck", megatruck_icon,
    {r = 0.58, g = 0.62, b = 0.66, a = 1}, {r = 0.90, g = 0.93, b = 0.96, a = 1},
    {consumption = "1.4MW", weight = 1200, max_health = 1400, rotation_multiplier = 0.72,
      braking_multiplier = 4.5, friction_force = 1.5e-3, energy_per_hit_point = 0.35, inventory_size = 100,
      artwork = "megatruck", sprite_scale = 0.76,
      equipment_grid = "large-equipment-grid", resistances = {
        {type = "impact", decrease = 150, percent = 70},
        {type = "acid", percent = 40},
        {type = "fire", percent = 70}
      }}
  ),
  copied_electric_vehicle(
    "bitermotors-bitertaxi-fleet", generated_icon("bitertaxi-fleet"),
    {r = 0.85, g = 0.52, b = 0.03, a = 1}, {r = 1.00, g = 0.82, b = 0.18, a = 1},
    {consumption = "270kW", weight = 850, max_health = 650, rotation_multiplier = 1.15,
      braking_multiplier = 6.0, friction_force = 1.75e-3, energy_per_hit_point = 0.8, inventory_size = 30,
      artwork = "bitertaxi-fleet", sprite_scale = 0.68}
  )
}

data:extend({
  hidden_grid_connection_pole(),
  hidden_ev_charging_power_sink("bitermotors-ev-charging-power-sink", 50),
  hidden_ev_charging_power_sink("bitermotors-ev-charging-v2-power-sink", 150),
  hidden_ev_charging_power_sink("bitermotors-ev-charging-v3-power-sink", 250),
  hidden_ev_charging_power_sink("bitermotors-ev-charging-v4-power-sink", 500),
  sales_office,
  ev_charging_station,
  ev_charging_station_v2,
  ev_charging_station_v3,
  ev_charging_station_v4,
  biterfactory,
  biterfactory_v2,
  high_density_solar_array,
  tandem_solar_array,
  grid_battery,
  grid_battery_array,
  terrestrial_datacenter,
  bitertaxi_depot,
  bitertaxi_depot_power,
  cybertrain,
  cybertrain_charging_stop,
  cybertrain_charging_power,
  orbital_datacenter_core,
  orbital_radiator_panel,
  high_density_space_solar_panel,
  planetary_grid_controller,
  espider,
  electric_vehicles[1],
  electric_vehicles[2],
  electric_vehicles[3],
  electric_vehicles[4],
  electric_vehicles[5]
})

data:extend({
  recipe("bitermotors-sales-office", {"crafting"}, "bitermotors-infrastructure", "a[sales-office]",
    {
      {type = "item", name = "assembling-machine-2", amount = 1},
      {type = "item", name = "radar", amount = 1},
      {type = "item", name = "concrete", amount = 20}
    },
    {{type = "item", name = "bitermotors-sales-office", amount = 1}}, 4
  ),
  recipe("bitermotors-ev-charging-station", {"advanced-crafting"}, "bitermotors-charging", "a[ev-charging-station]",
    {
      {type = "item", name = "substation", amount = 1},
      {type = "item", name = "accumulator", amount = 2},
      {type = "item", name = "concrete", amount = 20}
    },
    {{type = "item", name = "bitermotors-ev-charging-station", amount = 1}}, 12
  ),
  recipe("bitermotors-ev-charging-station-v2", {"advanced-crafting"}, "bitermotors-charging", "b[ev-charging-station-v2]",
    {
      {type = "item", name = "bitermotors-ev-charging-station", amount = 1},
      {type = "item", name = "substation", amount = 2},
      {type = "item", name = "processing-unit", amount = 20}
    },
    {{type = "item", name = "bitermotors-ev-charging-station-v2", amount = 1}}, 30
  ),
  recipe("bitermotors-ev-charging-station-v3", {"advanced-crafting"}, "bitermotors-charging", "c[ev-charging-station-v3]",
    {
      {type = "item", name = "bitermotors-ev-charging-station-v2", amount = 1},
      {type = "item", name = "substation", amount = 4},
      {type = "item", name = "processing-unit", amount = 40}
    },
    {{type = "item", name = "bitermotors-ev-charging-station-v3", amount = 1}}, 45
  ),
  recipe("bitermotors-ev-charging-station-v4", {"advanced-crafting"}, "bitermotors-charging", "d[ev-charging-station-v4]",
    {
      {type = "item", name = "bitermotors-ev-charging-station-v3", amount = 1},
      {type = "item", name = "bitermotors-high-density-solar-array", amount = 4},
      {type = "item", name = "bitermotors-grid-battery", amount = 4}
    },
    {{type = "item", name = "bitermotors-ev-charging-station-v4", amount = 1}}, 60
  ),
  recipe("bitermotors-biterfactory-module", {"advanced-crafting"}, "bitermotors-components", "c[biterfactory-module]",
    {
      {type = "item", name = "bitermotors-dollar", amount = 10},
      {type = "item", name = "assembling-machine-2", amount = 5},
      {type = "item", name = "lab", amount = 5},
      {type = "item", name = "refined-concrete", amount = 50}
    },
    {{type = "item", name = "bitermotors-biterfactory-module", amount = 1}}, 15
  ),
  recipe("bitermotors-biterfactory-building", {"advanced-crafting"}, "bitermotors-infrastructure", "d[biterfactory]",
    {
      {type = "item", name = "bitermotors-biterfactory-module", amount = 10},
      {type = "item", name = "substation", amount = 2}
    },
    {{type = "item", name = "bitermotors-biterfactory-building", amount = 1}}, 120
  ),
  recipe("bitermotors-structural-casting", {"advanced-crafting"}, "bitermotors-components", "d[structural-casting]",
    {
      {type = "item", name = "electric-furnace", amount = 20},
      {type = "item", name = "steel-plate", amount = 500},
      {type = "item", name = "electric-engine-unit", amount = 50},
      {type = "item", name = "bitermotors-dollar", amount = 50}
    },
    {{type = "item", name = "bitermotors-structural-casting", amount = 1}}, 60
  ),
  recipe("bitermotors-biterfactory-v2", {"advanced-crafting"}, "bitermotors-infrastructure", "e[biterfactory-v2]",
    {
      {type = "item", name = "bitermotors-biterfactory-building", amount = 1},
      {type = "item", name = "bitermotors-structural-casting", amount = 1},
      {type = "item", name = "bitermotors-dollar", amount = 100}
    },
    {{type = "item", name = "bitermotors-biterfactory-v2", amount = 1}}, 180
  ),
  recipe("bitermotors-dirty-nickel-refining", {"chemistry"}, "bitermotors-components", "a-a[dirty-nickel]",
    {
      {type = "item", name = "bitermotors-nickel-ore", amount = 10},
      {type = "fluid", name = "sulfuric-acid", amount = 100}
    },
    {
      {type = "item", name = "bitermotors-nickel-sulfate", amount = 4},
      {type = "item", name = "bitermotors-cobalt-concentrate", amount = 1},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 200}
    }, 10, {
      allow_productivity = true,
      main_product = "bitermotors-nickel-sulfate",
      icons = dirty_battery_process_recipe_icon("nickel-sulfate")
    }
  ),
  recipe("bitermotors-lithium-extraction", {"chemistry"}, "bitermotors-components", "a-b[lithium]",
    {
      {type = "fluid", name = "bitermotors-lithium-brine", amount = 100},
      {type = "item", name = "calcite", amount = 5}
    },
    {
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 4},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 100}
    }, 10, {
      allow_productivity = true,
      main_product = "bitermotors-lithium-carbonate",
      icons = dirty_battery_process_recipe_icon("lithium-carbonate")
    }
  ),
  recipe("bitermotors-battery-graphite", {"chemistry"}, "bitermotors-components", "a-c[graphite]",
    {{type = "item", name = "coal", amount = 5}},
    {{type = "item", name = "bitermotors-battery-graphite", amount = 2}}, 5,
    {allow_productivity = true}
  ),
  recipe("bitermotors-phosphate-extraction", {"chemistry"}, "bitermotors-components", "a-d[phosphate]",
    {
      {type = "item", name = "stone", amount = 10},
      {type = "fluid", name = "sulfuric-acid", amount = 50}
    },
    {
      {type = "item", name = "bitermotors-phosphate", amount = 4},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 100}
    }, 8, {
      allow_productivity = true,
      main_product = "bitermotors-phosphate",
      icons = dirty_battery_process_recipe_icon("phosphate")
    }
  ),
  recipe("bitermotors-tailings-neutralization", {"chemistry"}, "bitermotors-components", "a-e[tailings]",
    {
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 100},
      {type = "item", name = "calcite", amount = 2}
    },
    {{type = "item", name = "stone", amount = 2}}, 5,
    {allow_productivity = true}
  ),
  recipe("bitermotors-high-nickel-cell", {"chemistry"}, "bitermotors-components", "b-a[high-nickel-cell]",
    {
      {type = "item", name = "bitermotors-nickel-sulfate", amount = 4},
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 1},
      {type = "item", name = "bitermotors-battery-graphite", amount = 2},
      {type = "item", name = "bitermotors-cobalt-concentrate", amount = 1}
    },
    {{type = "item", name = "bitermotors-high-nickel-cell", amount = 4}}, 8,
    {allow_productivity = true}
  ),
  recipe("bitermotors-cell-scale-high-nickel", {"bitermotors-vertical-integration"}, "bitermotors-components", "b-b[cell-scale-high-nickel]",
    {
      {type = "item", name = "bitermotors-nickel-sulfate", amount = 4},
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 1},
      {type = "item", name = "bitermotors-battery-graphite", amount = 2},
      {type = "item", name = "bitermotors-cobalt-concentrate", amount = 1}
    },
    {{type = "item", name = "bitermotors-high-nickel-cell", amount = 5}}, 6,
    {allow_productivity = true}
  ),
  recipe("bitermotors-lfp-cell", {"chemistry"}, "bitermotors-components", "b-c[lfp-cell]",
    {
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 2},
      {type = "item", name = "iron-plate", amount = 4},
      {type = "item", name = "bitermotors-phosphate", amount = 2}
    },
    {{type = "item", name = "bitermotors-lfp-cell", amount = 4}}, 6,
    {allow_productivity = true}
  ),
  recipe("bitermotors-cell-scale-lfp", {"bitermotors-vertical-integration"}, "bitermotors-components", "b-d[cell-scale-lfp]",
    {
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 2},
      {type = "item", name = "iron-plate", amount = 4},
      {type = "item", name = "bitermotors-phosphate", amount = 2}
    },
    {{type = "item", name = "bitermotors-lfp-cell", amount = 5}}, 5,
    {allow_productivity = true}
  ),
  recipe("bitermotors-high-energy-battery-pack", {"advanced-crafting", "bitermotors-vertical-integration"}, "bitermotors-components", "c-a[high-energy-pack]",
    {
      {type = "item", name = "bitermotors-high-nickel-cell", amount = 4},
      {type = "item", name = "steel-plate", amount = 4},
      {type = "item", name = "advanced-circuit", amount = 2}
    },
    {{type = "item", name = "bitermotors-high-energy-battery-pack", amount = 1}}, 8,
    {allow_productivity = true, maximum_productivity = 0.1}
  ),
  recipe("bitermotors-lfp-battery-pack", {"advanced-crafting", "bitermotors-vertical-integration"}, "bitermotors-components", "c-b[lfp-pack]",
    {
      {type = "item", name = "bitermotors-lfp-cell", amount = 4},
      {type = "item", name = "steel-plate", amount = 4},
      {type = "item", name = "electronic-circuit", amount = 2}
    },
    {{type = "item", name = "bitermotors-lfp-battery-pack", amount = 1}}, 6,
    {allow_productivity = true, maximum_productivity = 0.1}
  ),
  recipe("bitermotors-clean-nickel-refining", {"chemistry"}, "bitermotors-components", "e-a[clean-nickel]",
    {
      {type = "item", name = "bitermotors-nickel-ore", amount = 10},
      {type = "fluid", name = "sulfuric-acid", amount = 75}
    },
    {
      {type = "item", name = "bitermotors-nickel-sulfate", amount = 5},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 50}
    }, 8, {
      allow_productivity = true,
      main_product = "bitermotors-nickel-sulfate",
      icons = generated_icon("clean-nickel-refining")
    }
  ),
  recipe("bitermotors-clean-lithium-extraction", {"chemistry"}, "bitermotors-components", "e-b[clean-lithium]",
    {
      {type = "fluid", name = "bitermotors-lithium-brine", amount = 100},
      {type = "item", name = "calcite", amount = 4}
    },
    {
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 5},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 25}
    }, 8, {
      allow_productivity = true,
      main_product = "bitermotors-lithium-carbonate",
      icons = generated_icon("clean-lithium-extraction")
    }
  ),
  recipe("bitermotors-clean-phosphate-extraction", {"chemistry"}, "bitermotors-components", "e-c[clean-phosphate]",
    {
      {type = "item", name = "stone", amount = 10},
      {type = "fluid", name = "sulfuric-acid", amount = 40}
    },
    {
      {type = "item", name = "bitermotors-phosphate", amount = 5},
      {type = "fluid", name = "bitermotors-acidic-tailings", amount = 25}
    }, 6, {
      allow_productivity = true,
      main_product = "bitermotors-phosphate",
      icons = generated_icon("clean-phosphate-extraction")
    }
  ),
  recipe("bitermotors-dry-high-nickel-cell", {"bitermotors-vertical-integration"}, "bitermotors-components", "e-d[dry-high-nickel]",
    {
      {type = "item", name = "bitermotors-nickel-sulfate", amount = 4},
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 1},
      {type = "item", name = "bitermotors-battery-graphite", amount = 2}
    },
    {{type = "item", name = "bitermotors-high-nickel-cell", amount = 6}}, 4,
    {
      allow_productivity = true,
      icons = generated_icon("dry-high-nickel-cell")
    }
  ),
  recipe("bitermotors-dry-lfp-cell", {"bitermotors-vertical-integration"}, "bitermotors-components", "e-e[dry-lfp]",
    {
      {type = "item", name = "bitermotors-lithium-carbonate", amount = 2},
      {type = "item", name = "iron-plate", amount = 4},
      {type = "item", name = "bitermotors-phosphate", amount = 2}
    },
    {{type = "item", name = "bitermotors-lfp-cell", amount = 6}}, 4,
    {
      allow_productivity = true,
      icons = generated_icon("dry-lfp-cell")
    }
  ),
  recipe("bitermotors-electric-drivetrain", {"advanced-crafting"}, "bitermotors-components", "b[electric-drivetrain]",
    {
      {type = "item", name = "electric-engine-unit", amount = 1},
      {type = "item", name = "advanced-circuit", amount = 3},
      {type = "item", name = "copper-cable", amount = 10}
    },
    {{type = "item", name = "bitermotors-electric-drivetrain", amount = 1}}, 5
  ),
  recipe("bitermotors-prototype-roadster", {"advanced-crafting"}, "transport", "bitermotors-a[prototype-roadster]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "battery", amount = 12},
      {type = "item", name = "advanced-circuit", amount = 4}
    },
    {{type = "item", name = "bitermotors-prototype-roadster", amount = 1}}, 30
  ),
  recipe("bitermotors-premium-ev", {"advanced-crafting", "bitermotors-vehicle-assembly"}, "transport", "bitermotors-b[premium-ev-legacy]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "battery", amount = 48},
      {type = "item", name = "bitermotors-electric-drivetrain", amount = 2},
      {type = "item", name = "advanced-circuit", amount = 10}
    },
    {{type = "item", name = "bitermotors-premium-ev", amount = 1}}, 30
  ),
  recipe("bitermotors-premium-ev-cell-scale", {"advanced-crafting", "bitermotors-vehicle-assembly"}, "transport", "bitermotors-b2[premium-ev-cell-scale]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "bitermotors-high-energy-battery-pack", amount = 8},
      {type = "item", name = "bitermotors-electric-drivetrain", amount = 2},
      {type = "item", name = "advanced-circuit", amount = 10}
    },
    {{type = "item", name = "bitermotors-premium-ev", amount = 1}}, 20
  ),
  recipe("bitermotors-mass-market-ev", {"bitermotors-mass-vehicle-assembly"}, "transport", "bitermotors-c[mass-market-ev]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "bitermotors-lfp-battery-pack", amount = 4},
      {type = "item", name = "bitermotors-electric-drivetrain", amount = 1}
    },
    {{type = "item", name = "bitermotors-mass-market-ev", amount = 1}}, 8
  ),
  recipe("bitermotors-megatruck", {"bitermotors-mass-vehicle-assembly"}, "transport", "bitermotors-d[megatruck]",
    {
      {type = "item", name = "car", amount = 1},
      {type = "item", name = "steel-plate", amount = 40},
      {type = "item", name = "bitermotors-high-energy-battery-pack", amount = 8},
      {type = "item", name = "bitermotors-electric-drivetrain", amount = 2}
    },
    {{type = "item", name = "bitermotors-megatruck", amount = 1}}, 15
  ),
  recipe("bitermotors-high-density-solar-array", {"advanced-crafting"}, "energy", "bitermotors-a[high-density-solar-array]",
    {
      {type = "item", name = "solar-panel", amount = 1},
      {type = "item", name = "processing-unit", amount = 2},
      {type = "item", name = "low-density-structure", amount = 2}
    },
    {{type = "item", name = "bitermotors-high-density-solar-array", amount = 1}}, 12
  ),
  recipe("bitermotors-high-density-solar-array-batch", {"bitermotors-energy-products-batch"}, "energy", "bitermotors-a2[high-density-solar-array-batch]",
    {
      {type = "item", name = "solar-panel", amount = 4},
      {type = "item", name = "processing-unit", amount = 6},
      {type = "item", name = "low-density-structure", amount = 6}
    },
    {{type = "item", name = "bitermotors-high-density-solar-array", amount = 4}}, 30,
    {
      allow_productivity = false,
      localised_name = {"recipe-name.bitermotors-high-density-solar-array-batch"}
    }
  ),
  recipe("bitermotors-tandem-solar-array", {"advanced-crafting", "bitermotors-energy-products-batch"}, "energy", "bitermotors-a3[tandem-solar-array]",
    {
      {type = "item", name = "bitermotors-high-density-solar-array", amount = 1},
      {type = "item", name = "processing-unit", amount = 10},
      {type = "item", name = "low-density-structure", amount = 10}
    },
    {{type = "item", name = "bitermotors-tandem-solar-array", amount = 1}}, 10,
    {allow_productivity = false}
  ),
  recipe("bitermotors-grid-battery", {"bitermotors-energy-products"}, "energy", "bitermotors-b[grid-battery]",
    {
      {type = "item", name = "bitermotors-lfp-battery-pack", amount = 12},
      {type = "item", name = "accumulator", amount = 4},
      {type = "item", name = "substation", amount = 1}
    },
    {{type = "item", name = "bitermotors-grid-battery", amount = 1}}, 8
  ),
  recipe("bitermotors-grid-battery-array", {"advanced-crafting", "bitermotors-energy-products"}, "energy", "bitermotors-b2[grid-battery-array]",
    {
      {type = "item", name = "bitermotors-grid-battery", amount = 1},
      {type = "item", name = "bitermotors-lfp-battery-pack", amount = 24},
      {type = "item", name = "processing-unit", amount = 20},
      {type = "item", name = "bitermotors-dollar", amount = 5}
    },
    {{type = "item", name = "bitermotors-grid-battery-array", amount = 1}}, 20,
    {allow_productivity = false}
  ),
  recipe("bitermotors-autonomy-computer", {"advanced-crafting"}, "bitermotors-components", "e[autonomy-computer]",
    {
      {type = "item", name = "processing-unit", amount = 4},
      {type = "item", name = "speed-module", amount = 2}
    },
    {{type = "item", name = "bitermotors-autonomy-computer", amount = 1}}, 6
  ),
  recipe("bitermotors-bitertaxi-fleet", {"bitermotors-mass-vehicle-assembly"}, "transport", "bitermotors-d[bitertaxi-fleet]",
    {
      {type = "item", name = "bitermotors-mass-market-ev", amount = 4},
      {type = "item", name = "bitermotors-autonomy-computer", amount = 4},
      {type = "item", name = "bitermotors-dollar", amount = 20}
    },
    {{type = "item", name = "bitermotors-bitertaxi-fleet", amount = 1}}, 20
  ),
  recipe("bitermotors-bitertaxi-depot", {"advanced-crafting"}, "bitermotors-infrastructure", "g[bitertaxi-depot]",
    {
      {type = "item", name = "bitermotors-ev-charging-station-v4", amount = 1},
      {type = "item", name = "roboport", amount = 4},
      {type = "item", name = "processing-unit", amount = 50},
      {type = "item", name = "bitermotors-dollar", amount = 200}
    },
    {{type = "item", name = "bitermotors-bitertaxi-depot", amount = 1}}, 60
  ),
  recipe("bitermotors-operate-bitertaxi-fleet", {"bitermotors-bitertaxi-depot"}, "bitermotors-capital", "i[operate-bitertaxi-fleet]",
    {},
    {{type = "item", name = "bitermotors-dollar", amount = 1}}, 100000000
  ),
  recipe("bitermotors-wrecked-ev-recycling", {"recycling"}, "intermediate-product", "z[bitermotors-wrecked-ev-recycling]",
    {{type = "item", name = "bitermotors-wrecked-ev", amount = 1}},
    {
      {type = "item", name = "steel-plate", amount = 5, independent_probability = 0.8},
      {type = "item", name = "electronic-circuit", amount = 4, independent_probability = 0.5},
      {type = "item", name = "battery", amount = 4, independent_probability = 0.5}
    }, 4, {allow_productivity = false, auto_recycle = false, icons = wrecked_ev_icon}
  ),
  recipe("bitermotors-high-energy-battery-recovery", {"recycling"}, "bitermotors-components", "z-a[high-energy-recovery]",
    {{type = "item", name = "bitermotors-damaged-high-energy-battery-pack", amount = 10}},
    {{type = "item", name = "bitermotors-high-nickel-cell", amount = 36}}, 20,
    {allow_productivity = false, auto_recycle = false}
  ),
  recipe("bitermotors-lfp-battery-recovery", {"recycling"}, "bitermotors-components", "z-b[lfp-recovery]",
    {{type = "item", name = "bitermotors-damaged-lfp-battery-pack", amount = 10}},
    {{type = "item", name = "bitermotors-lfp-cell", amount = 36}}, 20,
    {allow_productivity = false, auto_recycle = false}
  ),
  recipe("bitermotors-cybertrain", {"advanced-crafting", "bitermotors-vertical-integration"}, "transport", "bitermotors-f[cybertrain]",
    {
      {type = "item", name = "locomotive", amount = 1},
      {type = "item", name = "bitermotors-high-energy-battery-pack", amount = 8},
      {type = "item", name = "bitermotors-electric-drivetrain", amount = 4},
      {type = "item", name = "bitermotors-dollar", amount = 100}
    },
    {{type = "item", name = "bitermotors-cybertrain", amount = 1}}, 60,
    {allow_productivity = false}
  ),
  recipe("bitermotors-cybertrain-charging-stop", {"advanced-crafting"}, "transport", "bitermotors-g[cybertrain-charging-stop]",
    {
      {type = "item", name = "train-stop", amount = 1},
      {type = "item", name = "substation", amount = 2},
      {type = "item", name = "bitermotors-lfp-battery-pack", amount = 4},
      {type = "item", name = "bitermotors-dollar", amount = 50}
    },
    {{type = "item", name = "bitermotors-cybertrain-charging-stop", amount = 1}}, 30,
    {allow_productivity = false}
  ),
  recipe("bitermotors-espider", {"bitermotors-mass-vehicle-assembly"}, "transport", "bitermotors-h[espider]",
    {
      {type = "item", name = "bitermotors-megatruck", amount = 1},
      {type = "item", name = "battery-mk3-equipment", amount = 4},
      {type = "item", name = "exoskeleton-equipment", amount = 4},
      {type = "item", name = "processing-unit", amount = 20}
    },
    {{type = "item", name = "bitermotors-espider", amount = 1}}, 120,
    {allow_productivity = false}
  ),

  recipe("bitermotors-datacenter-rack", {"advanced-crafting"}, "bitermotors-components", "f[datacenter-rack]",
    {
      {type = "item", name = "processing-unit", amount = 10},
      {type = "item", name = "battery", amount = 20},
      {type = "item", name = "low-density-structure", amount = 5}
    },
    {{type = "item", name = "bitermotors-datacenter-rack", amount = 1}}, 10
  ),
  recipe("bitermotors-terrestrial-datacenter", {"advanced-crafting"}, "bitermotors-infrastructure", "f[terrestrial-datacenter]",
    {
      {type = "item", name = "bitermotors-biterfactory-module", amount = 1},
      {type = "item", name = "bitermotors-datacenter-rack", amount = 4},
      {type = "item", name = "substation", amount = 4},
      {type = "item", name = "refined-concrete", amount = 100}
    },
    {{type = "item", name = "bitermotors-terrestrial-datacenter", amount = 1}}, 15
  ),
  recipe("bitermotors-orbital-datacenter-core", {"advanced-crafting"}, "bitermotors-infrastructure", "h[orbital-datacenter-core]",
    {
      {type = "item", name = "bitermotors-datacenter-rack", amount = 20},
      {type = "item", name = "processing-unit", amount = 100},
      {type = "item", name = "low-density-structure", amount = 100},
      {type = "item", name = "bitermotors-lfp-battery-pack", amount = 50}
    },
    {{type = "item", name = "bitermotors-orbital-datacenter-core", amount = 1}}, 60
  ),
  recipe("bitermotors-orbital-radiator-panel", {"advanced-crafting"}, "energy", "c[orbital-radiator-panel]",
    {
      {type = "item", name = "heat-pipe", amount = 20},
      {type = "item", name = "copper-plate", amount = 100},
      {type = "item", name = "electric-engine-unit", amount = 10},
      {type = "item", name = "low-density-structure", amount = 10}
    },
    {{type = "item", name = "bitermotors-orbital-radiator-panel", amount = 1}}, 20
  ),
  recipe("bitermotors-high-density-space-solar-panel", {"advanced-crafting"}, "energy", "d[high-density-space-solar-panel]",
    {
      {type = "item", name = "bitermotors-high-density-solar-array", amount = 4},
      {type = "item", name = "processing-unit", amount = 20},
      {type = "item", name = "low-density-structure", amount = 10},
      {type = "item", name = "bitermotors-high-energy-battery-pack", amount = 4}
    },
    {{type = "item", name = "bitermotors-high-density-space-solar-panel", amount = 1}}, 30
  ),
  recipe("bitermotors-planetary-grid-controller", {"advanced-crafting"}, "bitermotors-infrastructure", "h[planetary-grid-controller]",
    {
      {type = "item", name = "bitermotors-biterfactory-module", amount = 100},
      {type = "item", name = "bitermotors-grid-battery-array", amount = 10},
      {type = "item", name = "substation", amount = 100},
      {type = "item", name = "bitermotors-dollar", amount = 10000}
    },
    {{type = "item", name = "bitermotors-planetary-grid-controller", amount = 1}}, 600
  ),

  recipe("bitermotors-sell-prototype-roadster", {"bitermotors-sales"}, "bitermotors-capital", "a[sell-roadster]",
    {
      {type = "item", name = "bitermotors-prototype-roadster", amount = 1},
      {type = "item", name = "bitermotors-ev-reservation", amount = 1}
    },
    {{type = "item", name = "bitermotors-dollar", amount = 2}}, 60,
    {icons = sale_icon(generated_icon("prototype-roadster"))}
  ),
  recipe("bitermotors-sell-premium-ev", {"bitermotors-sales"}, "bitermotors-capital", "b[sell-premium-ev]",
    {
      {type = "item", name = "bitermotors-premium-ev", amount = 1},
      {type = "item", name = "bitermotors-ev-reservation", amount = 1}
    },
    {{type = "item", name = "bitermotors-dollar", amount = 1}}, 30,
    {icons = sale_icon(generated_icon("premium-ev"))}
  ),
  recipe("bitermotors-sell-mass-market-ev", {"bitermotors-sales"}, "bitermotors-capital", "c[sell-mass-market-ev]",
    {
      {type = "item", name = "bitermotors-mass-market-ev", amount = 1},
      {type = "item", name = "bitermotors-ev-reservation", amount = 1}
    },
    {{type = "item", name = "bitermotors-dollar", amount = 1}}, 5,
    {icons = sale_icon(generated_icon("mass-market-ev"))}
  ),
  recipe("bitermotors-sell-megatruck", {"bitermotors-sales"}, "bitermotors-capital", "d[sell-megatruck]",
    {
      {type = "item", name = "bitermotors-megatruck", amount = 1},
      {type = "item", name = "bitermotors-ev-reservation", amount = 1}
    },
    {{type = "item", name = "bitermotors-dollar", amount = 2}}, 10,
    {icons = sale_icon(megatruck_icon)}
  ),
  recipe("bitermotors-sell-grid-battery", {"bitermotors-sales"}, "bitermotors-capital", "e[sell-grid-battery]",
    {{type = "item", name = "bitermotors-grid-battery", amount = 1}},
    {{type = "item", name = "bitermotors-dollar", amount = 20}}, 30,
    {icons = sale_icon(grid_battery_icon)}
  ),
  recipe("bitermotors-sell-bitertaxi-fleet", {"bitermotors-sales"}, "bitermotors-capital", "h[sell-bitertaxi-fleet]",
    {{type = "item", name = "bitermotors-bitertaxi-fleet", amount = 3}},
    {{type = "item", name = "bitermotors-dollar", amount = 1}}, 3,
    {icons = sale_icon(generated_icon("bitertaxi-fleet"))}
  ),

  recipe("bitermotors-terrestrial-ai-token", {"bitermotors-datacenter"}, "science-pack", "bitermotors-c[terrestrial-ai-token]",
    {{type = "item", name = "bitermotors-dollar", amount = 20}},
    {{type = "item", name = "bitermotors-ai-token", amount = 20}}, 30
  ),
  recipe("bitermotors-orbital-ai-token", {"bitermotors-orbital-compute"}, "science-pack", "bitermotors-d[orbital-ai-token]",
    {{type = "item", name = "bitermotors-dollar", amount = 1}},
    {{type = "item", name = "bitermotors-ai-token", amount = 10000}}, 30,
    {
      main_product = "bitermotors-ai-token",
      surface_conditions = {
        {
          property = "gravity",
          min = 0,
          max = 0
        }
      }
    }
  ),
  recipe("bitermotors-orbital-ai-token-cluster", {"bitermotors-orbital-compute"}, "science-pack", "bitermotors-d2[orbital-ai-token-cluster]",
    {{type = "item", name = "bitermotors-dollar", amount = 1}},
    {{type = "item", name = "bitermotors-ai-token", amount = 25000}}, 30,
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
  recipe("bitermotors-orbital-ai-token-grid-scale", {"bitermotors-orbital-compute"}, "science-pack", "bitermotors-d3[orbital-ai-token-grid-scale]",
    {{type = "item", name = "bitermotors-dollar", amount = 1}},
    {{type = "item", name = "bitermotors-ai-token", amount = 50000}}, 30,
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
  recipe("bitermotors-orbital-ai-token-hyperscale", {"bitermotors-orbital-compute"}, "science-pack", "bitermotors-d4[orbital-ai-token-hyperscale]",
    {{type = "item", name = "bitermotors-dollar", amount = 1}},
    {
      {type = "item", name = "bitermotors-ai-token", amount = 50000},
      {type = "item", name = "bitermotors-ai-token", amount = 50000}
    }, 30,
    {
      main_product = "bitermotors-ai-token",
      surface_conditions = {
        {
          property = "gravity",
          min = 0,
          max = 0
        }
      }
    }
  ),
  recipe("bitermotors-package-agi-training-dataset", {"bitermotors-planetary-grid"}, "science-pack", "h[agi-training-dataset]",
    {{type = "item", name = "bitermotors-ai-token", amount = 50000}},
    {{type = "item", name = "bitermotors-agi-training-dataset", amount = 1}}, 1,
    {allow_productivity = false, allow_quality = false}
  ),
  recipe("bitermotors-package-capital-allocation", {"bitermotors-planetary-grid"}, "bitermotors-capital", "b[capital-allocation]",
    {{type = "item", name = "bitermotors-dollar", amount = 500}},
    {{type = "item", name = "bitermotors-capital-allocation", amount = 1}}, 1,
    {allow_productivity = false, allow_quality = false}
  ),
  recipe("bitermotors-agi-training-run", {"bitermotors-planetary-grid"}, "science-pack", "i[agi-training-run]",
    {
      {type = "item", name = "bitermotors-agi-training-dataset", amount = 20000},
      {type = "item", name = "bitermotors-capital-allocation", amount = 100},
      {type = "item", name = "bitermotors-grid-battery-array", amount = 100},
      {type = "item", name = "processing-unit", amount = 10000}
    },
    {{type = "item", name = "bitermotors-agi-model", amount = 1}}, 3600,
    {allow_productivity = false, allow_quality = false}
  )
})

add_lab_input("lab", "bitermotors-dollar")
add_lab_input("lab", "bitermotors-ai-token")
add_lab_input("biolab", "bitermotors-dollar")
add_lab_input("biolab", "bitermotors-ai-token")

data:extend({
  tech("bitermotors-sales-office",
    "__bitermotors__/graphics/icons/sales-office.png",
    {"automobilism", "electric-engine", "chemical-science-pack"},
    {
      unlock("bitermotors-sales-office"),
      unlock("bitermotors-ev-charging-station"),
      unlock("bitermotors-sell-prototype-roadster")
    },
    75,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1}
    },
    20
  ),
  tech("bitermotors-premium-ev-program",
    "__bitermotors__/graphics/icons/premium-ev.png",
    {
      "bitermotors-sales-office",
      "battery",
      "electric-engine",
      "logistics-2",
      "electric-energy-distribution-2",
      "concrete"
    },
    {
      unlock("bitermotors-electric-drivetrain"),
      unlock("bitermotors-premium-ev"),
      unlock("bitermotors-sell-premium-ev")
    },
    250,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  tech("bitermotors-advanced-battery-chemistry",
    "__bitermotors__/graphics/icons/high-energy-battery-pack.png",
    {"bitermotors-premium-ev-program", "sulfur-processing"},
    {
      unlock("bitermotors-dirty-nickel-refining"),
      unlock("bitermotors-lithium-extraction"),
      unlock("bitermotors-battery-graphite"),
      unlock("bitermotors-tailings-neutralization"),
      unlock("bitermotors-high-nickel-cell"),
      unlock("bitermotors-cell-scale-high-nickel"),
      unlock("bitermotors-high-energy-battery-pack"),
      unlock("bitermotors-premium-ev-cell-scale")
    },
    300,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30,
    {enabled = false}
  ),
  tech("bitermotors-capital-scaling",
    "__bitermotors__/graphics/icons/mass-market-ev.png",
    {
      "bitermotors-ev-charging-network",
      "bitermotors-energy-products",
      "production-science-pack",
      "utility-science-pack"
    },
    {
      unlock("bitermotors-structural-casting"),
      unlock("bitermotors-biterfactory-v2"),
      unlock("bitermotors-clean-nickel-refining"),
      unlock("bitermotors-clean-lithium-extraction"),
      unlock("bitermotors-clean-phosphate-extraction"),
      unlock("bitermotors-dry-high-nickel-cell"),
      unlock("bitermotors-dry-lfp-cell"),
      unlock("bitermotors-mass-market-ev"),
      unlock("bitermotors-sell-mass-market-ev"),
      unlock("bitermotors-ev-charging-station-v3")
    },
    600,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  tech("bitermotors-megatruck-engineering",
    "__bitermotors__/graphics/icons/megatruck.png",
    {"bitermotors-capital-scaling", "tank"},
    {
      unlock("bitermotors-megatruck"),
      unlock("bitermotors-sell-megatruck")
    },
    250,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"military-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  tech("bitermotors-ev-charging-network",
    "__bitermotors__/graphics/icons/ev-charging-station-v2.png",
    {"bitermotors-premium-ev-program", "electric-energy-distribution-2", "concrete"},
    {
      unlock("bitermotors-ev-charging-station-v2")
    },
    150,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  tech("bitermotors-energy-products",
    "__bitermotors__/graphics/icons/grid-battery.png",
    {"bitermotors-advanced-battery-chemistry", "electric-energy-accumulators", "solar-energy"},
    {
      unlock("bitermotors-high-density-solar-array"),
      unlock("bitermotors-phosphate-extraction"),
      unlock("bitermotors-lfp-cell"),
      unlock("bitermotors-cell-scale-lfp"),
      unlock("bitermotors-lfp-battery-pack"),
      unlock("bitermotors-grid-battery"),
      unlock("bitermotors-sell-grid-battery")
    },
    200,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  tech("bitermotors-terrestrial-ai",
    "__bitermotors__/graphics/icons/terrestrial-datacenter.png",
    {"bitermotors-capital-scaling", "bitermotors-energy-products", "processing-unit"},
    {
      unlock("bitermotors-autonomy-computer"),
      unlock("bitermotors-datacenter-rack"),
      unlock("bitermotors-terrestrial-datacenter"),
      unlock("bitermotors-terrestrial-ai-token")
    },
    750,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  tech("bitermotors-orbital-compute",
    "__bitermotors__/graphics/icons/orbital-datacenter-core.png",
    {"rocket-silo", "bitermotors-terrestrial-ai", "bitermotors-autonomous-logistics", "space-platform", "space-science-pack", "bitermotors-energy-products"},
    {
      unlock("bitermotors-orbital-datacenter-core"),
      unlock("bitermotors-orbital-radiator-panel"),
      unlock("bitermotors-high-density-space-solar-panel"),
      unlock("bitermotors-orbital-ai-token")
    },
    1500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  tech("bitermotors-orbital-cluster-training",
    "__base__/graphics/technology/space-science-pack.png",
    {"bitermotors-orbital-compute"},
    {
      unlock("bitermotors-orbital-ai-token-cluster")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 5}
    },
    60,
    {enabled = false}
  ),
  tech("bitermotors-grid-scale-energy",
    "__base__/graphics/technology/solar-energy.png",
    {"bitermotors-orbital-cluster-training"},
    {
      unlock("bitermotors-orbital-ai-token-grid-scale"),
      unlock("bitermotors-tandem-solar-array"),
      unlock("bitermotors-grid-battery-array")
    },
    1500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 10}
    },
    60,
    {enabled = false}
  ),
  tech("bitermotors-hyperscale-training",
    "__base__/graphics/technology/processing-unit.png",
    {"bitermotors-grid-scale-energy"},
    {
      unlock("bitermotors-orbital-ai-token-hyperscale")
    },
    3000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 10}
    },
    60,
    {enabled = false}
  ),
  tech("bitermotors-autonomous-logistics",
    "__bitermotors__/graphics/icons/bitertaxi-depot.png",
    {"bitermotors-terrestrial-ai", "logistic-robotics", "production-science-pack", "utility-science-pack"},
    {
      unlock("bitermotors-bitertaxi-fleet"),
      unlock("bitermotors-ev-charging-station-v4"),
      unlock("bitermotors-bitertaxi-depot"),
      unlock("bitermotors-operate-bitertaxi-fleet"),
      unlock("bitermotors-sell-bitertaxi-fleet")
    },
    750,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  tech("bitermotors-espider-engineering",
    "__base__/graphics/technology/spidertron.png",
    {
      "bitermotors-autonomous-logistics",
      "bitermotors-megatruck-engineering",
      "battery-mk3-equipment",
      "exoskeleton-equipment",
      "tesla-weapons"
    },
    {
      unlock("bitermotors-espider")
    },
    1000,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-ai-token", 1},
      {"bitermotors-dollar", 2}
    },
    60
  ),
  tech("bitermotors-planetary-energy-grid",
    "__bitermotors__/graphics/icons/planetary-grid-controller.png",
    {"bitermotors-hyperscale-training", "bitermotors-autonomous-logistics", "nuclear-power"},
    {
      unlock("bitermotors-planetary-grid-controller"),
      unlock("bitermotors-package-agi-training-dataset"),
      unlock("bitermotors-package-capital-allocation")
    },
    2500,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"bitermotors-ai-token", 1}
    },
    60
  )
})

local battery_material_recovery = tech(
  "bitermotors-battery-material-recovery",
  "__bitermotors__/graphics/icons/damaged-lfp-battery-pack.png",
  {"recycling", "bitermotors-energy-products"},
  {
    unlock("bitermotors-high-energy-battery-recovery"),
    unlock("bitermotors-lfp-battery-recovery")
  },
  250,
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
    {"bitermotors-dollar", 1}
  },
  30
)
battery_material_recovery.enabled = false

data:extend({
  battery_material_recovery,
  tech(
    "bitermotors-cybertrain-logistics",
    "__bitermotors__/graphics/icons/cybertrain.png",
    {"bitermotors-autonomous-logistics", "railway", "electric-energy-distribution-2"},
    {unlock("bitermotors-cybertrain"), unlock("bitermotors-cybertrain-charging-stop")},
    750,
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    45
  )
})

data:extend({
  infinite_tech(
    "bitermotors-rapid-charging-power-electronics",
    "__base__/graphics/technology/electric-energy-distribution-2.png",
    {"bitermotors-ev-charging-network"},
    {{type = "nothing", effect_description = {"technology-effect-description.bitermotors-rapid-charging-power-electronics"}}},
    "200*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  infinite_tech(
    "bitermotors-long-range-battery",
    "__base__/graphics/technology/battery.png",
    {"bitermotors-capital-scaling"},
    {{type = "nothing", effect_description = {"technology-effect-description.bitermotors-long-range-battery"}}},
    "300*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  infinite_tech(
    "bitermotors-premium-audio-systems",
    "__base__/graphics/technology/circuit-network.png",
    {"bitermotors-premium-ev-program"},
    {{type = "nothing", effect_description = {"technology-effect-description.bitermotors-premium-audio-systems"}}},
    "150*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  infinite_tech(
    "bitermotors-customer-referral-program",
    "__base__/graphics/technology/worker-robots-speed.png",
    {"bitermotors-ev-charging-network"},
    {{type = "nothing", effect_description = {"technology-effect-description.bitermotors-customer-referral-program"}}},
    "200*2^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"military-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    30
  ),
  infinite_tech(
    "bitermotors-high-density-solar-productivity",
    "__base__/graphics/technology/solar-energy.png",
    {"bitermotors-energy-products"},
    {
      {type = "change-recipe-productivity", recipe = "bitermotors-high-density-solar-array", change = 0.1},
      {type = "change-recipe-productivity", recipe = "bitermotors-high-density-solar-array-batch", change = 0.1},
      {type = "change-recipe-productivity", recipe = "bitermotors-tandem-solar-array", change = 0.1}
    },
    "750*1.5^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    60
  ),
  infinite_tech(
    "bitermotors-grid-battery-productivity",
    "__base__/graphics/technology/electric-energy-acumulators.png",
    {"bitermotors-energy-products"},
    {
      {type = "change-recipe-productivity", recipe = "bitermotors-grid-battery", change = 0.1},
      {type = "change-recipe-productivity", recipe = "bitermotors-grid-battery-array", change = 0.1}
    },
    "750*1.5^(L-1)",
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"bitermotors-dollar", 1}
    },
    60
  )
})

local ai_efficiency_thresholds = {1000, 10000, 100000, 1000000, 10000000, 100000000}
local terrestrial_efficiency_science = {
  {"automation-science-pack", 1},
  {"logistic-science-pack", 1},
  {"chemical-science-pack", 1},
  {"production-science-pack", 1},
  {"utility-science-pack", 1},
  {"bitermotors-dollar", 1}
}

for level, threshold in pairs(ai_efficiency_thresholds) do
  local name = "bitermotors-terrestrial-ai-efficiency-" .. level
  local prototype = tech(
    name,
    "__base__/graphics/technology/processing-unit.png",
    {level == 1 and "bitermotors-terrestrial-ai" or "bitermotors-terrestrial-ai-efficiency-" .. (level - 1)},
    {{type = "nothing", effect_description = {"", "+10% AI Tokens per cycle"}}},
    math.floor(threshold / 10),
    terrestrial_efficiency_science,
    30
  )
  prototype.enabled = false
  prototype.localised_name = {"", "Terrestrial AI Efficiency ", tostring(level)}
  prototype.localised_description = {
    "",
    "Unlocked after terrestrial compute generates ",
    tostring(threshold),
    " AI Tokens. Research adds 10% output without increasing Dollars or power per cycle."
  }
  data:extend({prototype})
end

local function add_recipe_category(recipe_name, category_name)
  local prototype = data.raw.recipe[recipe_name]
  if not prototype then
    error("Biter Motors vertical integration recipe does not exist: " .. recipe_name)
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
  "bitermotors-biterfactory-module",
  "bitermotors-structural-casting",
  "bitermotors-electric-drivetrain",
  "bitermotors-autonomy-computer",
  "bitermotors-datacenter-rack"
}

for _, recipe_name in pairs(vertically_integrated_intermediates) do
  add_recipe_category(recipe_name, "bitermotors-vertical-integration").allow_productivity = true
end

for _, recipe_name in pairs({
  "bitermotors-premium-ev",
  "bitermotors-mass-market-ev",
  "bitermotors-megatruck",
  "bitermotors-high-density-solar-array",
  "bitermotors-high-density-solar-array-batch",
  "bitermotors-tandem-solar-array",
  "bitermotors-grid-battery",
  "bitermotors-grid-battery-array",
  "bitermotors-bitertaxi-fleet"
}) do
  data.raw.recipe[recipe_name].allow_productivity = false
end

for _, recipe_name in pairs({
  "bitermotors-sell-prototype-roadster",
  "bitermotors-sell-premium-ev",
  "bitermotors-sell-mass-market-ev",
  "bitermotors-sell-megatruck",
  "bitermotors-sell-grid-battery",
  "bitermotors-sell-bitertaxi-fleet",
  "bitermotors-terrestrial-ai-token",
  "bitermotors-orbital-ai-token",
  "bitermotors-orbital-ai-token-cluster",
  "bitermotors-orbital-ai-token-grid-scale",
  "bitermotors-orbital-ai-token-hyperscale",
  "bitermotors-package-agi-training-dataset",
  "bitermotors-package-capital-allocation",
  "bitermotors-agi-training-run"
}) do
  data.raw.recipe[recipe_name].allow_quality = false
end

local customer_vehicle_classes = {
  prospect = {
    label = "EV prospect (friendly)",
    prospect = true,
    primary = {r = 0.25, g = 0.95, b = 0.35, a = 1},
    secondary = {r = 0.55, g = 1.00, b = 0.62, a = 1}
  },
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
  bitertaxi = {
    label = "Bitertaxi",
    primary = {r = 0.85, g = 0.52, b = 0.03, a = 1},
    secondary = {r = 1.00, g = 0.82, b = 0.18, a = 1}
  },
  megatruck = {
    label = "Megatruck",
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
    prototype.name = "bitermotors-" .. base_name .. "-" .. class_name
    prototype.localised_name = class.prospect
      and {"", class.label, " - ", base.localised_name or {"entity-name." .. base_name}}
      or {"", class.label, " customer - ", base.localised_name or {"entity-name." .. base_name}}
    prototype.autoplace = nil
    prototype.icons = {{icon = base.icon, icon_size = base.icon_size or 64, tint = class.primary}}
    prototype.icon = nil
    animation_mask_tint(prototype.run_animation, class)
    animation_mask_tint(prototype.attack_parameters and prototype.attack_parameters.animation, class)
    customer_vehicle_units[#customer_vehicle_units + 1] = prototype
  end
end
data:extend(customer_vehicle_units)
