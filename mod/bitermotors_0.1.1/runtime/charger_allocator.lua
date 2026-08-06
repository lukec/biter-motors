local ChargerAllocator = {}

local function ratio_less(left_value, left_total, right_value, right_total)
  return left_value * right_total < right_value * left_total
end

local function stable_less(left, right)
  if type(left) == type(right) then return left < right end
  return tostring(left) < tostring(right)
end

local function heap_push(heap, value, less)
  local index = #heap + 1
  heap[index] = value
  while index > 1 do
    local parent = math.floor(index / 2)
    if not less(heap[index], heap[parent]) then break end
    heap[index], heap[parent] = heap[parent], heap[index]
    index = parent
  end
end

local function heap_pop(heap, less)
  if #heap == 0 then return nil end
  local result = heap[1]
  local tail = table.remove(heap)
  if #heap > 0 then
    heap[1] = tail
    local index = 1
    while true do
      local left = index * 2
      local right = left + 1
      local best = index
      if left <= #heap and less(heap[left], heap[best]) then best = left end
      if right <= #heap and less(heap[right], heap[best]) then best = right end
      if best == index then break end
      heap[index], heap[best] = heap[best], heap[index]
      index = best
    end
  end
  return result
end

local function assignment_available(assignment, key, allow_repeat)
  return #assignment.settlements < assignment.spec.stalls
    and (allow_repeat or not assignment.assigned_keys[key])
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

local function best_available_station(pairs, key, less, allow_repeat)
  local best
  for _, pair in ipairs(pairs or {}) do
    if assignment_available(pair.assignment, key, allow_repeat)
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

  local function demand_less(left, right)
    return demand_key_less(left, right, requested_capacity, demand)
  end
  local demand_heap = {}
  for _, key in ipairs(candidate_keys) do
    if (demand[key] or 0) > 0 then heap_push(demand_heap, key, demand_less) end
  end
  while #demand_heap > 0 do
    local best_key = heap_pop(demand_heap, demand_less)
    local pair = best_available_station(
      candidate_pairs_by_key[best_key], best_key, demand_station_less, true
    )
    if pair then
      pair.demand = demand[best_key] or 0
      assign_pair(pair, assigned_capacity, requested_capacity, true)
      first_station_by_settlement[pair.candidate.key] =
        first_station_by_settlement[pair.candidate.key] or pair.assignment.station
      if (demand[best_key] or 0) > (requested_capacity[best_key] or 0) then
        heap_push(demand_heap, best_key, demand_less)
      end
    end
  end

  local function capacity_less(left, right)
    local left_capacity = assigned_capacity[left] or 0
    local right_capacity = assigned_capacity[right] or 0
    if left_capacity ~= right_capacity then return left_capacity < right_capacity end
    return stable_less(left, right)
  end
  local capacity_heap = {}
  for _, key in ipairs(candidate_keys) do heap_push(capacity_heap, key, capacity_less) end
  while #capacity_heap > 0 do
    local best_key = heap_pop(capacity_heap, capacity_less)
    local pair = best_available_station(
      candidate_pairs_by_key[best_key], best_key, capacity_station_less, false
    )
    if pair then
      assign_pair(pair, assigned_capacity, requested_capacity, false)
      first_station_by_settlement[pair.candidate.key] =
        first_station_by_settlement[pair.candidate.key] or pair.assignment.station
      heap_push(capacity_heap, best_key, capacity_less)
    end
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
