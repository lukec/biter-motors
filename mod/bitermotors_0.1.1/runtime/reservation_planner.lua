local ReservationPlanner = {}

function ReservationPlanner.allocate(stations, retry_minutes, maximum_rate)
  local rates_by_station = {}
  local uncapped_rate = 0
  local prospects = 0
  retry_minutes = math.max(1, retry_minutes or 1)

  for _, station in pairs(stations or {}) do
    local station_prospects = math.max(0, station.prospects or 0)
    prospects = prospects + station_prospects
    uncapped_rate = uncapped_rate + station_prospects / retry_minutes
  end

  local capped_rate = math.min(uncapped_rate, math.max(0, maximum_rate or 0))
  local scale = uncapped_rate > 0 and capped_rate / uncapped_rate or 0
  for _, station in pairs(stations or {}) do
    rates_by_station[station.key] = math.max(0, station.prospects or 0)
      / retry_minutes * scale
  end

  return {
    rates_by_station = rates_by_station,
    prospects = prospects,
    uncapped_rate = uncapped_rate,
    capped_rate = capped_rate,
    maximum_rate = math.max(0, maximum_rate or 0),
    scale = scale
  }
end

return ReservationPlanner
