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
    icon = "__base__/graphics/technology/automation-2.png",
    icon_size = 256,
    prerequisites = {"automation-2", "electric-mining-drill"},
    effects = {unlock("electric-furnace")},
    unit = science(75, {"automation-science-pack", "logistic-science-pack"}, 20),
    order = "x-a-a"
  }
})

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
big_drill_tech.prerequisites = {"x-industrial-supply-chain"}
big_drill_tech.research_trigger = nil
big_drill_tech.unit = science(100, {"automation-science-pack", "logistic-science-pack"}, 30)

rewrite_recipe("foundry", {
  categories = {"crafting", "advanced-crafting"},
  ingredients = ingredients(
    {"electric-furnace", 25},
    {"electronic-circuit", 50},
    {"refined-concrete", 200}
  )
})
local foundry_tech = data.raw.technology.foundry
foundry_tech.prerequisites = {"x-industrial-supply-chain", "concrete"}
foundry_tech.research_trigger = nil
foundry_tech.unit = science(150, {"automation-science-pack", "logistic-science-pack"}, 30)

-- The Foundry's terrestrial ore/casting loop is useful; lava and tungsten
-- recipes remain planetary. Preserve the vanilla foundry effects and add the
-- two ore-melting recipes if the current Space Age version omitted them.
local foundry_effects = {}
for _, effect in ipairs(foundry_tech.effects or {}) do
  if effect.type ~= "unlock-recipe" or effect.recipe ~= "tungsten-plate" then
    foundry_effects[#foundry_effects + 1] = effect
  end
end
for _, recipe_name in ipairs({"iron-ore-melting", "copper-ore-melting"}) do
  local seen = false
  for _, effect in ipairs(foundry_effects) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then seen = true end
  end
  if not seen then foundry_effects[#foundry_effects + 1] = unlock(recipe_name) end
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
recycling_tech.prerequisites = {"x-industrial-supply-chain", "concrete"}
recycling_tech.research_trigger = nil
recycling_tech.unit = science(150, {"automation-science-pack", "logistic-science-pack"}, 30)
recycling_tech.effects = recycling_tech.effects or {}
recycling_tech.effects[#recycling_tech.effects + 1] = unlock("x-wrecked-ev-recycling")

rewrite_recipe("teslagun", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"x-battery-pack", 4},
    {"processing-unit", 10},
    {"steel-plate", 20}
  )
})
rewrite_recipe("tesla-turret", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"teslagun", 1},
    {"x-battery-pack", 10},
    {"processing-unit", 20},
    {"accumulator", 4}
  )
})
rewrite_recipe("tesla-ammo", {
  categories = {"advanced-crafting"},
  ingredients = ingredients(
    {"x-battery-pack", 1},
    {"advanced-circuit", 2},
    {"copper-cable", 10}
  ),
  energy_required = 10
})
local tesla_tech = data.raw.technology["tesla-weapons"]
tesla_tech.prerequisites = {"x-energy-products", "military-3", "processing-unit"}
tesla_tech.unit = science(500, {
  "automation-science-pack", "logistic-science-pack", "chemical-science-pack",
  "military-science-pack"
}, 45)

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

-- Mech Armor stays locked to Fulgora until the future Optimus product exists.
-- Do not adapt its recipe early or introduce a temporary holmium-free shortcut.
