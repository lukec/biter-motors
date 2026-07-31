local ChargerAllocator = {}

local function ratio_less(left_value, left_total, right_value, right_total)
  return left_value * right_total < right_value * left_total
end

local function stable_less(left, right)
  if type(left) == type(right) then return left < right end
  return tostring(left) < tostring(right)
end

local function assignment_available(assignment, key)
  return #assignment.settlements < assignment.spec.stalls
    and not assignment.assigned_keys[key]
end

local function demand_station_less(left, right)
  local left_spec = left.assignment.spec
  local right_spec = right.assignment.spec
  if left_spec.evs_per_stall ~= right_spec.evs_per_stall then
    return left_spec.evs_per_stall > right_spec.evs_per_stall
  end
  local left_active = left.assignment.customer_requested_stalls
  local right_active = right.assignment.customer_requested_stalls
  if left_active * right_spec.stalls ~= right_active * left_spec.stalls then
    return ratio_less(left_active, left_spec.stalls, right_active, right_spec.stalls)
  end
  if left.candidate.distance ~= right.candidate.distance then
    return left.candidate.distance < right.candidate.distance
  end
  return stable_less(left_spec.key, right_spec.key)
end

local function capacity_station_less(left, right)
  local left_spec = left.assignment.spec
  local right_spec = right.assignment.spec
  local left_filled = #left.assignment.settlements
  local right_filled = #right.assignment.settlements
  if left_filled * right_spec.stalls ~= right_filled * left_spec.stalls then
    return ratio_less(left_filled, left_spec.stalls, right_filled, right_spec.stalls)
  end
  if left.candidate.distance ~= right.candidate.distance then
    return left.candidate.distance < right.candidate.distance
  end
  return stable_less(left_spec.key, right_spec.key)
end

local function best_available_station(pairs, key, less)
  local best
  for _, pair in ipairs(pairs or {}) do
    if assignment_available(pair.assignment, key)
      and (not best or less(pair, best)) then
      best = pair
    end
  end
  return best
end

local function demand_key_less(left, right, requested_capacity, demand)
  local left_requested = requested_capacity[left] or 0
  local right_requested = requested_capacity[right] or 0
  local left_demand = demand[left] or 0
  local right_demand = demand[right] or 0
  if left_requested * right_demand ~= right_requested * left_demand then
    return ratio_less(left_requested, left_demand, right_requested, right_demand)
  end
  local left_unmet = left_demand - left_requested
  local right_unmet = right_demand - right_requested
  if left_unmet ~= right_unmet then return left_unmet > right_unmet end
  return stable_less(left, right)
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
  demand = demand or {}
  local assignments = {}
  local candidate_pairs_by_key = {}
  local candidate_keys = {}
  local assigned_capacity = {}
  local requested_capacity = {}
  local first_station_by_settlement = {}

  for _, spec in ipairs(station_specs or {}) do
    local assignment = {
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
    assignments[spec.key] = assignment
    for _, candidate in ipairs(spec.candidates or {}) do
      if not candidate_pairs_by_key[candidate.key] then
        candidate_pairs_by_key[candidate.key] = {}
        candidate_keys[#candidate_keys + 1] = candidate.key
      end
      candidate_pairs_by_key[candidate.key][#candidate_pairs_by_key[candidate.key] + 1] = {
        assignment = assignment,
        candidate = candidate
      }
    end
  end
  table.sort(candidate_keys, stable_less)

  while true do
    local best_key
    local pair
    for _, key in ipairs(candidate_keys) do
      if (demand[key] or 0) > (requested_capacity[key] or 0) then
        local available = best_available_station(
          candidate_pairs_by_key[key], key, demand_station_less
        )
        if available and (not best_key
          or demand_key_less(key, best_key, requested_capacity, demand)) then
          best_key = key
          pair = available
        end
      end
    end
    if not pair then break end
    pair.demand = demand[best_key] or 0
    assign_pair(pair, assigned_capacity, requested_capacity, true)
    first_station_by_settlement[pair.candidate.key] =
      first_station_by_settlement[pair.candidate.key] or pair.assignment.station
  end

  while true do
    local best_key
    local pair
    for _, key in ipairs(candidate_keys) do
      local available = best_available_station(
        candidate_pairs_by_key[key], key, capacity_station_less
      )
      if available and (not best_key
        or (assigned_capacity[key] or 0) < (assigned_capacity[best_key] or 0)
        or ((assigned_capacity[key] or 0) == (assigned_capacity[best_key] or 0)
          and stable_less(key, best_key))) then
        best_key = key
        pair = available
      end
    end
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
