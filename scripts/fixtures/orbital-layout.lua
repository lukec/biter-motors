local M = {}
local P = "bitermotors-"

function M.make(count, recipe)
  assert(count == 1 or count == 4 or count == 8 or count == 12, "supported cluster ramp")
  local layout = {cores = count, entities = {}, tiles = {}, manifest = {}}
  local occupied, foundation = {}, {}
  local function tile_key(x, y) return string.format("%d:%d", x, y) end
  local function tile(x, y)
    -- The starter already supplies this solid region; manifest only additions.
    if x >= -4 and x <= 4 and y >= -4 and y <= 4 then return end
    local key = tile_key(x, y)
    if not foundation[key] then
      foundation[key] = true
      layout.tiles[#layout.tiles + 1] = {name = "space-platform-foundation", position = {x = x, y = y}}
    end
  end
  local function entity(name, x, y, direction, role, size)
    layout.entities[#layout.entities + 1] = {name = name, position = {x = x, y = y},
      direction = direction or 0, role = role, recipe = role == "core" and recipe or nil}
    layout.manifest[name] = (layout.manifest[name] or 0) + 1
    size = size or 1
    for tx = x - size / 2, x + size / 2 - 1 do
      for ty = y - size / 2, y + size / 2 - 1 do
        local key = tile_key(tx, ty)
        assert(not occupied[key], "overlapping layout footprint " .. key)
        occupied[key] = true
        tile(tx, ty)
      end
    end
  end
  -- Coordinates use native 2.1 cardinal directions: N=0, E=4, S=8, W=12.
  local function belt(x, y, direction) entity("express-transport-belt", x, y, direction, "output") end
  entity("bulk-inserter", -3.5, 4.5, 0, "hub-input")
  entity("transport-belt", -3.5, 5.5, 8, "input")
  entity("transport-belt", -3.5, 6.5, 12, "input")
  for x = -4.5, -5.5, -1 do entity("transport-belt", x, 6.5, 12, "input") end
  entity("transport-belt", -6.5, 6.5, 8, "input")
  local stride = 9
  local last = -3.5 + (count - 1) * stride
  for x = -6.5, last - 1, 1 do entity("transport-belt", x, 7.5, 4, "input") end
  for x = last + 1, -7.5, -1 do belt(x, 13.5, 12) end
  belt(-8.5, 13.5, 0)
  for y = 12.5, 3.5, -1 do belt(-8.5, y, 0) end
  belt(-8.5, 2.5, 4)
  for x = -7.5, -5.5, 1 do belt(x, 2.5, 4) end
  entity("bulk-inserter", -4.5, 2.5, 12, "hub-output")
  for i = 0, count - 1 do
    local x = -3.5 + i * stride
    entity(P .. "orbital-datacenter-core", x, 10.5, 0, "core", 3)
    entity("bulk-inserter", x - 1, 8.5, 0, "core-input")
    entity("bulk-inserter", x + 1, 12.5, 0, "core-output")
    for j = 0, 4 do entity(P .. "high-density-space-solar-panel", x, 17.5 + j * 3, 0, "solar", 3) end
    -- East core port (x+1) -> two pipes -> west radiator port (x+4).
    entity(P .. "orbital-heat-pipe", x + 2, 10.5, 0, "heat-pipe")
    entity(P .. "orbital-heat-pipe", x + 3, 10.5, 0, "heat-pipe")
    entity(P .. "orbital-radiator-panel", x + 5, 10.5, 0, "radiator", 3)
    tile(math.floor(x), 14); tile(math.floor(x), 15)
  end
  -- Native platforms cannot enclose empty space. Fill holes in the footprint
  -- union (including the solid starter hub), retaining open solar-column gaps.
  local solid = {}
  for key in pairs(foundation) do solid[key] = true end
  for x = -4, 4 do for y = -4, 4 do solid[tile_key(x, y)] = true end end
  local outside, queue, cursor = {}, {{-11, -6}}, 1
  outside["-11:-6"] = true
  while cursor <= #queue do
    local pos = queue[cursor]; cursor = cursor + 1
    for _, delta in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
      local x, y = pos[1] + delta[1], pos[2] + delta[2]
      local key = tile_key(x, y)
      if x >= -11 and x <= last + 9 and y >= -6 and y <= 32 and not solid[key] and not outside[key] then
        outside[key] = true; queue[#queue + 1] = {x, y}
      end
    end
  end
  for x = -10, last + 8 do for y = -5, 31 do
    local key = tile_key(x, y)
    if not solid[key] and not outside[key] then tile(x, y) end
  end end
  table.sort(layout.tiles, function(a, b)
    return a.position.y == b.position.y and a.position.x < b.position.x or a.position.y < b.position.y
  end)
  layout.manifest["space-platform-foundation"] = #layout.tiles
  return layout
end

return M
