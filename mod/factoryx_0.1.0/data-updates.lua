local resource_autoplace = require("resource-autoplace")

local function ingredients(...)
  local result = {}
  for _, entry in ipairs({...}) do
    result[#result + 1] = {type = "item", name = entry[1], amount = entry[2]}
  end
  return result
end

local function science(count, packs, time)
  local values = {}
  for _, pack in ipairs(packs) do
    values[#values + 1] = {pack, 1}
  end
  return {count = count, ingredients = values, time = time or 30}
end

local function unlock(recipe)
  return {type = "unlock-recipe", recipe = recipe}
end

local function mark_factoryx_technology(technology, icon)
  technology.icon = nil
  technology.icon_size = nil
  technology.icons = {
    {icon = icon, icon_size = 256},
    {
      icon = "__factoryx__/graphics/technology/factoryx-tech-badge.png",
      icon_size = 64,
      scale = 0.78,
      shift = {88, 88}
    }
  }
end

local function rewrite_recipe(name, values)
  local recipe = data.raw.recipe[name]
  if not recipe then return end
  for key, value in pairs(values) do recipe[key] = value end
  recipe.enabled = false
  recipe.surface_conditions = nil
end

-- FactoryX is a fresh-world overhaul. Move selected Space Age machines into a
-- self-contained terrestrial industrial branch instead of preserving planet gates.
data:extend({
  {
    type = "technology",
    name = "x-industrial-supply-chain",
    icons = {
      {icon = "__base__/graphics/technology/automation-2.png", icon_size = 256},
      {icon = "__factoryx__/graphics/technology/factoryx-tech-badge.png", icon_size = 64, scale = 0.78, shift = {88, 88}}
    },
    prerequisites = {"automation-2", "electric-mining-drill", "steel-processing"},
    effects = {unlock("electric-furnace")},
    unit = science(75, {"automation-science-pack", "logistic-science-pack"}, 20),
    order = "x-a-a"
  }
})

local advanced_materials = data.raw.technology["advanced-material-processing-2"]
if advanced_materials then
  local retained_effects = {}
  for _, effect in ipairs(advanced_materials.effects or {}) do
    if effect.type ~= "unlock-recipe" or effect.recipe ~= "electric-furnace" then
      retained_effects[#retained_effects + 1] = effect
    end
  end
  advanced_materials.effects = retained_effects
end

rewrite_recipe("electric-furnace", {
  ingredients = ingredients(
    {"steel-plate", 10},
    {"electronic-circuit", 10},
    {"stone-brick", 10}
  )
})

rewrite_recipe("big-mining-drill", {
  categories = {"crafting", "advanced-crafting"},
  ingredients = ingredients(
    {"electric-mining-drill", 4},
    {"engine-unit", 20},
    {"electronic-circuit", 20}
  )
})
local big_drill_tech = data.raw.technology["big-mining-drill"]
mark_factoryx_technology(big_drill_tech, "__space-age__/graphics/technology/big-mining-drill.png")
big_drill_tech.prerequisites = {"x-industrial-supply-chain", "engine"}
big_drill_tech.research_trigger = nil
big_drill_tech.unit = science(100, {"automation-science-pack", "logistic-science-pack"}, 30)

-- The terrestrial drill must not drag Vulcanus tungsten into the Nauvis
-- progression. Restore tungsten steel to an actual Vulcanus discovery.
local tungsten_steel_tech = data.raw.technology["tungsten-steel"]
if tungsten_steel_tech then
  tungsten_steel_tech.prerequisites = {"planet-discovery-vulcanus"}
  tungsten_steel_tech.unit = nil
  tungsten_steel_tech.research_trigger = {
    type = "mine-entity",
    entities = {"tungsten-ore"}
  }
end

-- Terrestrial recycling must not expose Fulgora's material branch early.
local holmium_tech = data.raw.technology["holmium-processing"]
if holmium_tech then
  holmium_tech.prerequisites = {"recycling", "planet-discovery-fulgora"}
end

rewrite_recipe("foundry", {
  categories = {"crafting", "advanced-crafting"},
  ingredients = ingredients(
    {"electric-furnace", 25},
    {"electronic-circuit", 50},
    {"refined-concrete", 200}
  )
})
local foundry_tech = data.raw.technology.foundry
mark_factoryx_technology(foundry_tech, "__space-age__/graphics/technology/foundry.png")
foundry_tech.prerequisites = {"x-industrial-supply-chain", "concrete"}
foundry_tech.research_trigger = nil
foundry_tech.unit = science(150, {"automation-science-pack", "logistic-science-pack"}, 30)

-- The Foundry's terrestrial ore/casting loop is useful; lava and tungsten
-- recipes remain planetary. Preserve the vanilla foundry effects and add the
-- two ore-melting recipes if the current Space Age version omitted them.
local foundry_effects = {}
for _, recipe_name in ipairs({
  "foundry",
  "iron-ore-melting",
  "copper-ore-melting",
  "concrete-from-molten-iron",
  "casting-iron",
  "casting-steel",
  "casting-copper",
  "casting-iron-gear-wheel",
  "casting-iron-stick",
  "casting-pipe",
  "casting-pipe-to-ground",
  "casting-copper-cable"
}) do
  foundry_effects[#foundry_effects + 1] = unlock(recipe_name)
end
foundry_tech.effects = foundry_effects

rewrite_recipe("recycler", {
  categories = {"crafting", "advanced-crafting"},
  ingredients = ingredients(
    {"steel-plate", 20},
    {"iron-gear-wheel", 40},
    {"electronic-circuit", 20},
    {"concrete", 20}
  )
})
local recycling_tech = data.raw.technology.recycling
mark_factoryx_technology(recycling_tech, "__recycler__/graphics/technology/recycling.png")
recycling_tech.prerequisites = {"x-industrial-supply-chain", "concrete"}
recycling_tech.research_trigger = nil
recycling_tech.unit = science(150, {"automation-science-pack", "logistic-science-pack"}, 30)
recycling_tech.enabled = false
recycling_tech.effects = recycling_tech.effects or {}
recycling_tech.effects[#recycling_tech.effects + 1] = unlock("x-wrecked-ev-recycling")

rewrite_recipe("teslagun", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"x-high-energy-battery-pack", 4},
    {"processing-unit", 10},
    {"steel-plate", 20}
  )
})
rewrite_recipe("tesla-turret", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"teslagun", 1},
    {"x-high-energy-battery-pack", 10},
    {"processing-unit", 20},
    {"accumulator", 4}
  )
})
rewrite_recipe("tesla-ammo", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"x-high-energy-battery-pack", 1},
    {"advanced-circuit", 2},
    {"copper-cable", 10}
  ),
  energy_required = 10
})
local tesla_tech = data.raw.technology["tesla-weapons"]
mark_factoryx_technology(tesla_tech, "__space-age__/graphics/technology/tesla-weapons.png")
tesla_tech.prerequisites = {"x-energy-products", "military-3", "processing-unit"}
tesla_tech.unit = science(500, {
  "automation-science-pack", "logistic-science-pack", "chemical-science-pack",
  "military-science-pack"
}, 45)

-- Requester logistics supports the complex terrestrial supply chains that
-- begin with Biter Motors. Keep it terrestrial and available before EV sales.
local logistic_system_tech = data.raw.technology["logistic-system"]
mark_factoryx_technology(logistic_system_tech, "__base__/graphics/technology/logistic-system.png")
logistic_system_tech.prerequisites = {"logistic-robotics", "x-industrial-supply-chain"}
logistic_system_tech.unit = science(500, {
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack"
}, 30)
logistic_system_tech.enabled = true

-- Tier 2 modules are terrestrial FactoryX capital investments. Space Age
-- normally gates them on the first orbital science pack even though their
-- recipes use only Nauvis materials.
for _, technology_name in ipairs({
  "speed-module-2",
  "productivity-module-2",
  "efficiency-module-2",
  "quality-module-2"
}) do
  local technology = data.raw.technology[technology_name]
  if technology then
    local prerequisites = {}
    for _, prerequisite in ipairs(technology.prerequisites or {}) do
      if prerequisite ~= "space-science-pack" then
        prerequisites[#prerequisites + 1] = prerequisite
      end
    end
    prerequisites[#prerequisites + 1] = "x-sales-office"
    technology.prerequisites = prerequisites

    local research_ingredients = {}
    for _, ingredient in ipairs(technology.unit.ingredients or {}) do
      local ingredient_name = ingredient.name or ingredient[1]
      if ingredient_name == "space-science-pack" then
        research_ingredients[#research_ingredients + 1] = {"x-dollar", ingredient.amount or ingredient[2] or 1}
      else
        research_ingredients[#research_ingredients + 1] = ingredient
      end
    end
    technology.unit.ingredients = research_ingredients
    mark_factoryx_technology(technology, technology.icon)
  end
end

-- FactoryX uses tier-3 modules heavily, so replace Space Age's off-world
-- ingredients and science gates with an expensive terrestrial capital step.
for _, module_family in ipairs({"speed", "productivity", "efficiency", "quality"}) do
  local module_2 = module_family .. "-module-2"
  local module_3 = module_family .. "-module-3"
  rewrite_recipe(module_3, {
    categories = {"advanced-crafting"},
    ingredients = ingredients(
      {module_2, 4},
      {"advanced-circuit", 5},
      {"processing-unit", 5},
      {"x-dollar", 10}
    )
  })
  local technology = data.raw.technology[module_3]
  technology.prerequisites = {module_2, "x-capital-scaling"}
  technology.unit = science(1500, {
    "automation-science-pack",
    "logistic-science-pack",
    "chemical-science-pack",
    "production-science-pack",
    "utility-science-pack",
    "x-dollar"
  }, 60)
  mark_factoryx_technology(technology, technology.icon)
end

local epic_quality = data.raw.technology["epic-quality"]
epic_quality.prerequisites = {"quality-module-3", "x-terrestrial-ai"}
epic_quality.unit = science(2500, {
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack",
  "utility-science-pack",
  "space-science-pack",
  "x-ai-token",
  "x-dollar"
}, 60)

local legendary_quality = data.raw.technology["legendary-quality"]
legendary_quality.prerequisites = {"epic-quality", "x-orbital-compute"}
legendary_quality.unit = science(5000, {
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack",
  "utility-science-pack",
  "space-science-pack",
  "x-ai-token",
  "x-dollar"
}, 60)

-- Preserve useful base-game Nauvis tools that Space Age normally moves behind
-- planetary science. Their recipes revert to terrestrial materials.
rewrite_recipe("personal-roboport-mk2-equipment", {
  ingredients = ingredients(
    {"personal-roboport-equipment", 5},
    {"processing-unit", 100},
    {"low-density-structure", 20}
  )
})
local personal_roboport_mk2 = data.raw.technology["personal-roboport-mk2-equipment"]
personal_roboport_mk2.prerequisites = {"personal-roboport-equipment", "utility-science-pack"}
personal_roboport_mk2.unit = science(250, {
  "automation-science-pack", "logistic-science-pack",
  "chemical-science-pack", "utility-science-pack"
}, 30)

local energy_shield_mk2 = data.raw.technology["energy-shield-mk2-equipment"]
energy_shield_mk2.prerequisites = {
  "energy-shield-equipment", "military-3", "low-density-structure", "power-armor"
}
energy_shield_mk2.unit = science(200, {
  "automation-science-pack", "logistic-science-pack",
  "chemical-science-pack", "military-science-pack"
}, 30)

rewrite_recipe("cliff-explosives", {
  ingredients = ingredients(
    {"explosives", 10},
    {"grenade", 1},
    {"barrel", 1}
  )
})
local cliff_explosives = data.raw.technology["cliff-explosives"]
cliff_explosives.prerequisites = {"explosives", "military-2"}
cliff_explosives.unit = science(200, {
  "automation-science-pack", "logistic-science-pack", "military-science-pack"
}, 30)

local coal_liquefaction = data.raw.technology["coal-liquefaction"]
coal_liquefaction.prerequisites = {"advanced-oil-processing", "production-science-pack"}
coal_liquefaction.unit = science(500, {
  "automation-science-pack", "logistic-science-pack",
  "chemical-science-pack", "production-science-pack"
}, 30)

rewrite_recipe("artillery-wagon", {
  ingredients = ingredients(
    {"engine-unit", 64},
    {"iron-gear-wheel", 10},
    {"steel-plate", 40},
    {"advanced-circuit", 20}
  )
})
rewrite_recipe("artillery-turret", {
  ingredients = ingredients(
    {"steel-plate", 60},
    {"concrete", 60},
    {"iron-gear-wheel", 40},
    {"advanced-circuit", 20}
  )
})
rewrite_recipe("artillery-shell", {
  ingredients = ingredients(
    {"explosive-cannon-shell", 4},
    {"radar", 1},
    {"explosives", 8}
  )
})
local artillery = data.raw.technology.artillery
artillery.prerequisites = {"military-4", "tank", "concrete", "radar"}
artillery.unit = science(2000, {
  "automation-science-pack", "logistic-science-pack", "chemical-science-pack",
  "military-science-pack", "utility-science-pack"
}, 30)

-- Sparse calcite makes terrestrial casting finite initially; asteroid
-- processing remains the renewable space source later.
resource_autoplace.initialize_patch_set("calcite", false)
data.raw.resource.calcite.autoplace = resource_autoplace.resource_autoplace_settings({
  name = "calcite",
  order = "d",
  base_density = 1.5,
  base_spots_per_km2 = 0.35,
  has_starting_area_placement = true,
  regular_rq_factor_multiplier = 0.7,
  starting_rq_factor_multiplier = 0.8,
  candidate_spot_count = 8
})
local nauvis = data.raw.planet.nauvis
nauvis.map_gen_settings.autoplace_controls.calcite = {frequency = 0.5, size = 0.7, richness = 0.8}
nauvis.map_gen_settings.autoplace_settings.entity.settings.calcite = {}

resource_autoplace.initialize_patch_set("x-nickel-ore", false)
-- Uranium's regular-resource fade-in distance is 300 tiles. Battery minerals
-- use ordinary patches but a 240-tile fade, allowing them to begin at exactly
-- 80% of uranium's exclusion distance without putting a guaranteed patch in
-- the starting area. Actual nearest deposits remain seed-dependent.
local battery_mineral_fade = "clamp((distance - 240) / 60, 0, 1)"
local function battery_mineral_autoplace(parameters)
  local autoplace = resource_autoplace.resource_autoplace_settings(parameters)
  autoplace.probability_expression = "(" .. autoplace.probability_expression .. ") * " .. battery_mineral_fade
  autoplace.richness_expression = "(" .. autoplace.richness_expression .. ") * " .. battery_mineral_fade
  return autoplace
end

data.raw.resource["x-nickel-ore"].autoplace = battery_mineral_autoplace({
  name = "x-nickel-ore",
  order = "d",
  base_density = 2.0,
  base_spots_per_km2 = 1.25,
  random_spot_size_minimum = 2,
  random_spot_size_maximum = 4,
  regular_rq_factor_multiplier = 1.0,
  candidate_spot_count = 21
})
resource_autoplace.initialize_patch_set("x-lithium-brine", false)
data.raw.resource["x-lithium-brine"].autoplace = battery_mineral_autoplace({
  name = "x-lithium-brine",
  order = "e",
  base_density = 5.0,
  base_spots_per_km2 = 1.25,
  random_probability = 1 / 48,
  random_spot_size_minimum = 1,
  random_spot_size_maximum = 1,
  additional_richness = 160000,
  regular_rq_factor_multiplier = 1.0
})
nauvis.map_gen_settings.autoplace_controls["x-nickel-ore"] = {frequency = 1.0, size = 1.0, richness = 1.0}
nauvis.map_gen_settings.autoplace_controls["x-lithium-brine"] = {frequency = 1.0, size = 1.0, richness = 1.0}
nauvis.map_gen_settings.autoplace_settings.entity.settings["x-nickel-ore"] = {}
nauvis.map_gen_settings.autoplace_settings.entity.settings["x-lithium-brine"] = {}

-- Mech Armor stays locked to Fulgora until the future Optimus product exists.
-- Do not adapt its recipe early or introduce a temporary holmium-free shortcut.
