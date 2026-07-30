local ChargerAllocator = {}

local function ratio_less(left_value, left_total, right_value, right_total)
  return left_value * right_total < right_value * left_total
end

local function stable_less(left, right)
  if type(left) == type(right) then return left < right end
  return tostring(left) < tostring(right)
end

local function pair_less(left, right, demand_phase)
  local left_assignment = left.assignment
  local right_assignment = right.assignment
  local left_station = left_assignment.spec
  local right_station = right_assignment.spec

  if demand_phase then
    local left_requested = left.requested_capacity
    local right_requested = right.requested_capacity
    if left_requested * right.demand ~= right_requested * left.demand then
      return ratio_less(left_requested, left.demand, right_requested, right.demand)
    end
    if left_station.evs_per_stall ~= right_station.evs_per_stall then
      return left_station.evs_per_stall > right_station.evs_per_stall
    end
    local left_active = left_assignment.customer_requested_stalls
    local right_active = right_assignment.customer_requested_stalls
    if left_active * right_station.stalls ~= right_active * left_station.stalls then
      return ratio_less(left_active, left_station.stalls, right_active, right_station.stalls)
    end
    local left_unmet = left.demand - left_requested
    local right_unmet = right.demand - right_requested
    if left_unmet ~= right_unmet then return left_unmet > right_unmet end
  else
    if left.assigned_capacity ~= right.assigned_capacity then
      return left.assigned_capacity < right.assigned_capacity
    end
    local left_filled = #left_assignment.settlements
    local right_filled = #right_assignment.settlements
    if left_filled * right_station.stalls ~= right_filled * left_station.stalls then
      return ratio_less(left_filled, left_station.stalls, right_filled, right_station.stalls)
    end
  end

  if left.candidate.distance ~= right.candidate.distance then
    return left.candidate.distance < right.candidate.distance
  end
  if left_station.key ~= right_station.key then
    return stable_less(left_station.key, right_station.key)
  end
  return stable_less(left.candidate.key, right.candidate.key)
end

local function best_pair(assignments, assigned_capacity, requested_capacity, demand, demand_phase)
  local best
  for _, assignment in pairs(assignments) do
    local spec = assignment.spec
    if #assignment.settlements < spec.stalls then
      for _, candidate in pairs(spec.candidates) do
        local key = candidate.key
        local requested = requested_capacity[key] or 0
        local has_demand = (demand[key] or 0) > requested
        if not assignment.assigned_keys[key] and (not demand_phase or has_demand) then
          local pair = {
            assignment = assignment,
            candidate = candidate,
            demand = demand[key] or 0,
            assigned_capacity = assigned_capacity[key] or 0,
            requested_capacity = requested
          }
          if not best or pair_less(pair, best, demand_phase) then best = pair end
        end
      end
    end
  end
  return best
end

local function assign_pair(pair, assigned_capacity, requested_capacity, demand_phase)
  local assignment = pair.assignment
  local candidate = pair.candidate
  local spec = assignment.spec
  local key = candidate.key
  local stall_index = #assignment.settlements + 1

  assignment.settlements[stall_index] = candidate.settlement
  assignment.assigned_keys[key] = true
  assigned_capacity[key] = (assigned_capacity[key] or 0) + spec.evs_per_stall
  assignment.stall_loads[stall_index] = 0

  if demand_phase then
    local requested = requested_capacity[key] or 0
    assignment.stall_loads[stall_index] = math.max(
      0,
      math.min(spec.evs_per_stall, (pair.demand or 0) - requested)
    )
    assignment.customer_requested_stalls = assignment.customer_requested_stalls + 1
    assignment.requested_settlement_keys[key] = true
    requested_capacity[key] = requested + spec.evs_per_stall
  end
end

function ChargerAllocator.allocate(station_specs, demand)
  local assignments = {}
  local assigned_capacity = {}
  local requested_capacity = {}
  local first_station_by_settlement = {}

  for _, spec in pairs(station_specs or {}) do
    assignments[spec.key] = {
      spec = spec,
      station = spec.station,
      settlements = {},
      assigned_keys = {},
      operational_settlements = {},
      requested_settlement_keys = {},
      stall_loads = {},
      customer_requested_stalls = 0,
      requested_stalls = 0,
      powered_stalls = 0
    }
  end

  while true do
    local pair = best_pair(
      assignments,
      assigned_capacity,
      requested_capacity,
      demand or {},
      true
    )
    if not pair then break end
    assign_pair(pair, assigned_capacity, requested_capacity, true)
    first_station_by_settlement[pair.candidate.key] =
      first_station_by_settlement[pair.candidate.key] or pair.assignment.station
  end

  while true do
    local pair = best_pair(
      assignments,
      assigned_capacity,
      requested_capacity,
      demand or {},
      false
    )
    if not pair then break end
    assign_pair(pair, assigned_capacity, requested_capacity, false)
    first_station_by_settlement[pair.candidate.key] =
      first_station_by_settlement[pair.candidate.key] or pair.assignment.station
  end

  for _, assignment in pairs(assignments) do
    assignment.requested_stalls = assignment.customer_requested_stalls
  end

  return {
    assignments = assignments,
    assigned_capacity_by_settlement_key = assigned_capacity,
    requested_capacity_by_settlement_key = requested_capacity,
    first_station_by_settlement_key = first_station_by_settlement
  }
end

return ChargerAllocator
