local ProgressGuidance = {}

ProgressGuidance.technologies = {
  "bitermotors-premium-ev-program", "bitermotors-advanced-battery-chemistry",
  "bitermotors-energy-products", "bitermotors-ev-charging-network",
  "bitermotors-capital-scaling", "bitermotors-terrestrial-ai",
  "bitermotors-autonomous-logistics", "bitermotors-orbital-compute",
  "bitermotors-orbital-cluster-training", "bitermotors-grid-scale-energy",
  "bitermotors-hyperscale-training", "bitermotors-planetary-energy-grid"
}

function ProgressGuidance.research_cost(technology)
  local cost = {cycles = technology.research_unit_count, ingredients = {}}
  for _, ingredient in pairs(technology.research_unit_ingredients) do
    cost.ingredients[ingredient.name] = ingredient.amount * cost.cycles
  end
  return cost
end

function ProgressGuidance.research_summary(cost)
  local parts = {string.format("%d science cycles", cost.cycles)}
  local dollars = cost.ingredients["bitermotors-dollar"] or 0
  local tokens = cost.ingredients["bitermotors-ai-token"] or 0
  if dollars > 0 then parts[#parts + 1] = string.format("%d Dollars", dollars) end
  if tokens > 0 then parts[#parts + 1] = string.format("%d AI Tokens", tokens) end
  return "Invest " .. table.concat(parts, ", ") .. ". Use the science types shown in the technology tree."
end

function ProgressGuidance.recipe_seconds(recipe, crafting_speed)
  assert(crafting_speed and crafting_speed > 0, "Missing machine crafting speed")
  return recipe.energy / crafting_speed
end

return ProgressGuidance
