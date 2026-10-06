local RecipeRecycling = {rewritten = {}}

function RecipeRecycling.track(name)
  RecipeRecycling.rewritten[name] = true
end

function RecipeRecycling.refresh()
  local recycling = require("__recycler__.recycling")
  local reverse_names = {}
  local names = {}
  for name in pairs(RecipeRecycling.rewritten) do
    names[#names + 1] = name
    reverse_names[name .. "-recycling"] = true
  end
  table.sort(names)

  -- The upstream generator adds unlocks as well as replacing the recipes.
  local effects = data.raw.technology.recycling.effects
  for index = #effects, 1, -1 do
    local effect = effects[index]
    if effect.type == "unlock-recipe" and reverse_names[effect.recipe] then
      table.remove(effects, index)
    end
  end

  local util = require("util")
  for _, name in ipairs(names) do
    local forward = data.raw.recipe[name]
    local products = util.normalize_recipe_products(forward)
    assert(#products == 1 and products[1].type == "item" and products[1].name == name,
      "Biter Motors rewritten recycling needs one matching item product: " .. name)
    local reverse_name = name .. "-recycling"
    data.raw.recipe[reverse_name] = nil
    recycling.generate_recycling_recipe(forward)
    local reverse = assert(data.raw.recipe[reverse_name],
      "Biter Motors could not regenerate recycling for " .. name)
    reverse.allow_productivity = false
  end
end

return RecipeRecycling
