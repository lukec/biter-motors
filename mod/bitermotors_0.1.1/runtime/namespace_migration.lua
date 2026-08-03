local NamespaceMigration = {}

local CURRENT_VERSION = 1

local HYPHEN_RENAMES = {
  {"grid-megapack", "grid-battery-array"},
  {"megapack", "grid-battery"},
  {"robotaxi-service-center", "bitertaxi-depot"},
  {"robotaxi-service-power", "bitertaxi-depot-power"},
  {"robotaxi-service", "bitertaxi-depot"},
  {"operate-robotaxis", "operate-bitertaxi-fleet"},
  {"robotaxis", "bitertaxis"},
  {"robotaxi", "bitertaxi"},
  {"gigafactory", "biterfactory"},
  {"gigacast", "structural-casting"},
  {"supercharging", "rapid-charging"},
  {"ev-autopilot", "ev-self-driving"},
  {"navigate-ev", "route-ev"}
}

local SNAKE_RENAMES = {
  {"grid_megapack", "grid_battery_array"},
  {"megapack", "grid_battery"},
  {"robotaxi_service_centers", "bitertaxi_depots"},
  {"robotaxi_service_center", "bitertaxi_depot"},
  {"robotaxi_service", "bitertaxi_depot"},
  {"robotaxis", "bitertaxis"},
  {"robotaxi", "bitertaxi"},
  {"gigafactory", "biterfactory"},
  {"gigacast", "structural_casting"},
  {"supercharging", "rapid_charging"},
  {"ev_autopilot", "ev_self_driving"}
}

local function replace_plain(value, old, new)
  local chunks = {}
  local cursor = 1
  while true do
    local first, last = string.find(value, old, cursor, true)
    if not first then
      chunks[#chunks + 1] = string.sub(value, cursor)
      return table.concat(chunks)
    end
    chunks[#chunks + 1] = string.sub(value, cursor, first - 1)
    chunks[#chunks + 1] = new
    cursor = last + 1
  end
end

function NamespaceMigration.rewrite_string(value)
  if value == "navigate" then return "route" end
  local renames = string.find(value, "bitermotors-", 1, true)
    and HYPHEN_RENAMES or SNAKE_RENAMES
  for _, rename in ipairs(renames) do
    value = replace_plain(value, rename[1], rename[2])
  end
  return value
end

local function rewrite_table(target, seen)
  if type(target) ~= "table" or seen[target] then return end
  seen[target] = true

  local key_moves = {}
  for key, value in pairs(target) do
    if type(value) == "table" then
      rewrite_table(value, seen)
    elseif type(value) == "string" then
      target[key] = NamespaceMigration.rewrite_string(value)
    end

    if type(key) == "string" then
      local rewritten = NamespaceMigration.rewrite_string(key)
      if rewritten ~= key then
        key_moves[#key_moves + 1] = {old = key, new = rewritten, value = target[key]}
      end
    end
  end

  for _, move in ipairs(key_moves) do
    if target[move.new] == nil then target[move.new] = move.value end
    target[move.old] = nil
  end
end

function NamespaceMigration.migrate(runtime)
  if runtime.bitermotors_internal_namespace_version == CURRENT_VERSION then
    return false
  end
  rewrite_table(runtime, {})
  runtime.bitermotors_internal_namespace_version = CURRENT_VERSION
  return true
end

function NamespaceMigration.audit(runtime)
  local result = {
    version = runtime.bitermotors_internal_namespace_version or 0,
    stale_keys = 0,
    stale_values = 0
  }
  local seen = {}
  local function inspect(target)
    if type(target) ~= "table" or seen[target] then return end
    seen[target] = true
    for key, value in pairs(target) do
      if type(key) == "string" and NamespaceMigration.rewrite_string(key) ~= key then
        result.stale_keys = result.stale_keys + 1
      end
      if type(value) == "table" then
        inspect(value)
      elseif type(value) == "string" and NamespaceMigration.rewrite_string(value) ~= value then
        result.stale_values = result.stale_values + 1
      end
    end
  end
  inspect(runtime)
  return result
end

return NamespaceMigration
