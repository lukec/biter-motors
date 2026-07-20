local removed_locations = {
  "vulcanus",
  "fulgora",
  "gleba",
  "aquilo",
  "solar-system-edge",
  "shattered-planet"
}

-- Keep Space Age's platform engine, quality system, and prototype references,
-- but present FactoryX as a Nauvis-and-Nauvis-orbit game.
for _, location_name in pairs(removed_locations) do
  local location = data.raw.planet[location_name]
    or data.raw["space-location"][location_name]
  if location then
    location.hidden = true
    location.hidden_in_factoriopedia = true
  end
end

local retained_planet_overrides = {
  ["speed-module-3"] = true,
  ["productivity-module-3"] = true,
  ["efficiency-module-3"] = true,
  ["quality-module-3"] = true,
  ["epic-quality"] = true,
  ["legendary-quality"] = true,
  ["personal-roboport-mk2-equipment"] = true,
  ["energy-shield-mk2-equipment"] = true,
  ["cliff-explosives"] = true,
  ["coal-liquefaction"] = true,
  ["artillery"] = true
}

local removed_technologies = {
  ["space-platform-thruster"] = true,
  ["planet-discovery-vulcanus"] = true,
  ["planet-discovery-fulgora"] = true,
  ["planet-discovery-gleba"] = true,
  ["planet-discovery-aquilo"] = true,
  ["metallurgic-science-pack"] = true,
  ["electromagnetic-science-pack"] = true,
  ["agricultural-science-pack"] = true,
  ["cryogenic-science-pack"] = true,
  ["x-small-orbital-launch"] = true,
  ["x-reusable-launch"] = true,
  ["x-satellite-constellation"] = true,
  ["artillery-shell-range-1"] = true,
  ["artillery-shell-speed-1"] = true,
  ["artillery-shell-damage-1"] = true
}

-- Any technology whose prerequisite chain enters a removed planetary branch is
-- also irrelevant. Iterate to a fixed point so indirect descendants disappear.
local changed = true
while changed do
  changed = false
  for technology_name, technology in pairs(data.raw.technology) do
    if not removed_technologies[technology_name]
      and not retained_planet_overrides[technology_name] then
      for _, prerequisite in pairs(technology.prerequisites or {}) do
        if removed_technologies[prerequisite] then
          removed_technologies[technology_name] = true
          changed = true
          break
        end
      end
    end
  end
end

for technology_name in pairs(removed_technologies) do
  local technology = data.raw.technology[technology_name]
  if technology then
    technology.hidden = true
    technology.hidden_in_factoriopedia = true
    technology.enabled = false
  end
end

for _, category_name in pairs({"space-age", "spoilables"}) do
  local category = data.raw["tips-and-tricks-item-category"][category_name]
  if category then category.hidden = true end
  for _, tip in pairs(data.raw["tips-and-tricks-item"]) do
    if tip.category == category_name then tip.hidden = true end
  end
end

local removed_achievements = {
  ["fusion-power"] = true,
  ["visit-vulcanus"] = true,
  ["visit-fulgora"] = true,
  ["visit-gleba"] = true,
  ["visit-aquilo"] = true,
  ["second-star-to-the-right-and-straight-on-till-morning"] = true,
  ["it-stinks-and-they-do-like-it"] = true,
  ["get-off-my-lawn"] = true,
  ["shattered-planet-1"] = true,
  ["shattered-planet-2"] = true,
  ["shattered-planet-3"] = true,
  ["research-with-metallurgics"] = true,
  ["research-with-agriculture"] = true,
  ["research-with-electromagnetics"] = true,
  ["research-with-cryogenics"] = true,
  ["research-with-promethium"] = true,
  ["if-it-bleeds"] = true,
  ["we-need-bigger-guns"] = true,
  ["size-doesnt-matter"] = true,
  ["work-around-the-clock"] = true,
  ["express-delivery"] = true
}

for _, prototypes in pairs(data.raw) do
  for prototype_name, prototype in pairs(prototypes) do
    if removed_achievements[prototype_name]
      and string.find(prototype.type or "", "achievement", 1, true) then
      prototype.hidden = true
    end
  end
end

for _, recipe_name in pairs({
  "x-small-launch-service",
  "x-reusable-booster",
  "x-reusable-launch-service",
  "x-sell-small-launch",
  "x-sell-reusable-launch"
}) do
  local recipe = data.raw.recipe[recipe_name]
  if recipe then
    recipe.hidden = true
    recipe.enabled = false
  end
end

for _, item_name in pairs({
  "x-small-launch-service",
  "x-reusable-booster",
  "x-reusable-launch-service"
}) do
  local item = data.raw.item[item_name]
  if item then item.hidden = true end
end
