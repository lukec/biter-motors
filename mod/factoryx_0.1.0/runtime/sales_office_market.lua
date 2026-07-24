local SalesOfficeMarket = {}

local function stable_less(left, right)
  if type(left) == type(right) then return left < right end
  return tostring(left) < tostring(right)
end

function SalesOfficeMarket.classify(office_specs)
  local ordered = {}
  for _, spec in pairs(office_specs or {}) do
    ordered[#ordered + 1] = spec
  end
  table.sort(ordered, function(left, right)
    return stable_less(left.key, right.key)
  end)

  local by_office = {}
  local offices_by_settlement = {}
  for _, spec in pairs(ordered) do
    local state = {
      settlement_keys = {},
      settlement_count = 0,
      duplicated_settlements = 0,
      market_office_count = 0,
      surplus_office = false
    }
    by_office[spec.key] = state
    for settlement_key in pairs(spec.settlement_keys or {}) do
      state.settlement_keys[settlement_key] = true
      state.settlement_count = state.settlement_count + 1
      offices_by_settlement[settlement_key] =
        offices_by_settlement[settlement_key] or {}
      offices_by_settlement[settlement_key][#offices_by_settlement[settlement_key] + 1] =
        spec.key
    end
  end

  for _, office_keys in pairs(offices_by_settlement) do
    table.sort(office_keys, stable_less)
  end

  for office_key, state in pairs(by_office) do
    local peers = {[office_key] = true}
    local preserves_settlement = false
    for settlement_key in pairs(state.settlement_keys) do
      local office_keys = offices_by_settlement[settlement_key] or {}
      if office_keys[1] == office_key then preserves_settlement = true end
      if #office_keys > 1 then
        state.duplicated_settlements = state.duplicated_settlements + 1
      end
      for _, peer_key in pairs(office_keys) do peers[peer_key] = true end
    end
    for _ in pairs(peers) do
      state.market_office_count = state.market_office_count + 1
    end
    state.surplus_office = state.settlement_count > 0
      and state.market_office_count > 1
      and not preserves_settlement
  end

  return {
    by_office = by_office,
    offices_by_settlement = offices_by_settlement
  }
end

return SalesOfficeMarket
