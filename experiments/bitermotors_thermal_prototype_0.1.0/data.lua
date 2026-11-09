local P = require("thermal-policy")
local prefix = "bitermotors-thermal-"
local core = table.deepcopy(data.raw["assembling-machine"]["bitermotors-orbital-datacenter-core"])
core.name = prefix .. "core"
core.localised_name = {"entity-name." .. core.name}
core.minable = {mining_time = 0.5, result = core.name}
core.next_upgrade = nil
core.fast_replaceable_group = nil
core.create_ghost_on_death = true
-- Isolate active compute electricity/heat; production's idle drain is unchanged.
core.energy_source.drain = "0W"

local function buffer(capacity, size)
  local offset = (size - 1) / 2
  return {max_temperature = 500, default_temperature = P.floor_c,
    specific_heat = capacity, max_transfer = "5GW", min_temperature_gradient = 0.01,
    connections = {
      {position = {0, -offset}, direction = defines.direction.north},
      {position = {offset, 0}, direction = defines.direction.east},
      {position = {0, offset}, direction = defines.direction.south},
      {position = {-offset, 0}, direction = defines.direction.west}
    }}
end

local sensor = {type = "heat-interface", name = prefix .. "buffer",
  hidden = true, flags = {"not-on-map", "not-blueprintable", "not-deconstructable", "not-selectable-in-game"},
  collision_mask = {layers = {}}, collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}}, gui_mode = "none",
  heat_buffer = buffer("500MJ", 3), heating_radius = 0}

local radiator = table.deepcopy(data.raw["heat-interface"]["heat-interface"])
radiator.name = prefix .. "radiator"
radiator.localised_name = {"entity-name." .. radiator.name}
radiator.hidden, radiator.flags = false, {"placeable-player", "player-creation"}
radiator.minable = {mining_time = 0.2, result = radiator.name}
radiator.max_health = 500
radiator.collision_box, radiator.selection_box = {{-1.4, -1.4}, {1.4, 1.4}}, {{-1.5, -1.5}, {1.5, 1.5}}
radiator.gui_mode, radiator.heating_radius = "none", 0
radiator.heat_buffer = buffer("100MJ", 3)
radiator.picture = {filename = "__bitermotors__/graphics/icons/orbital-radiator-panel.png", size = 64, scale = 1.5}
radiator.icon = "__bitermotors__/graphics/icons/orbital-radiator-panel.png"

local conduit = table.deepcopy(data.raw["heat-pipe"]["heat-pipe"])
conduit.name = prefix .. "conduit"
conduit.localised_name = {"entity-name." .. conduit.name}
conduit.minable = {mining_time = 0.1, result = conduit.name}
conduit.heat_buffer = buffer("20MJ", 1)
conduit.heat_buffer.minimum_glow_temperature = 90
conduit.heating_radius = 0

local prototypes = {core, sensor, radiator, conduit}
for _, spec in ipairs{{core, "bitermotors-orbital-datacenter-core"},
  {radiator, "bitermotors-orbital-radiator-panel"}, {conduit, "heat-pipe"}} do
  local item = table.deepcopy(data.raw.item[spec[2]])
  item.name, item.place_result = spec[1].name, spec[1].name
  item.localised_name = {"entity-name." .. item.name}
  item.flags = {"always-show"}
  prototypes[#prototypes + 1] = item
  prototypes[#prototypes + 1] = {type = "recipe", name = item.name, enabled = true,
    energy_required = 1, ingredients = {{type = "item", name = spec[2], amount = 1}},
    results = {{type = "item", name = item.name, amount = 1}}, allow_productivity = false,
    allow_quality = false, auto_recycle = false}
end
data:extend(prototypes)
