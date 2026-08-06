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

local function add_assignment_settlement(assignment, candidate)
  local key = candidate.key
  if assignment.assigned_keys[key] then return end
  assignment.assigned_keys[key] = true
  assignment.settlements[#assignment.settlements + 1] = candidate.settlement
end

local function station_less(left, right)
  local left_spec = left.assignment.spec
  local right_spec = right.assignment.spec
  if left_spec.evs_per_stall ~= right_spec.evs_per_stall then
    return left_spec.evs_per_stall > right_spec.evs_per_stall
  end
  local left_used = left.assignment.total_capacity - left.assignment.remaining_capacity
  local right_used = right.assignment.total_capacity - right.assignment.remaining_capacity
  if left_used * right.assignment.total_capacity
    ~= right_used * left.assignment.total_capacity then
    return ratio_less(
      left_used,
      left.assignment.total_capacity,
      right_used,
      right.assignment.total_capacity
    )
  end
  if left.candidate.distance ~= right.candidate.distance then
    return left.candidate.distance < right.candidate.distance
  end
  return stable_less(left_spec.key, right_spec.key)
end

local function best_available_station(pairs)
  local best
  for _, pair in ipairs(pairs or {}) do
    if pair.assignment.remaining_capacity > 0
      and (not best or station_less(pair, best)) then
      best = pair
    end
  end
  return best
end

local function demand_key_less(left, right, allocated, demand)
  local left_allocated = allocated[left] or 0
  local right_allocated = allocated[right] or 0
  local left_demand = demand[left] or 0
  local right_demand = demand[right] or 0
  if left_allocated * right_demand ~= right_allocated * left_demand then
    return ratio_less(left_allocated, left_demand, right_allocated, right_demand)
  end
  local left_unmet = left_demand - left_allocated
  local right_unmet = right_demand - right_allocated
  if left_unmet ~= right_unmet then return left_unmet > right_unmet end
  return stable_less(left, right)
end

local function assign_demand(pair, amount, allocated, first_station)
  local assignment = pair.assignment
  local candidate = pair.candidate
  local key = candidate.key
  assignment.remaining_capacity = assignment.remaining_capacity - amount
  assignment.total_requested_evs = assignment.total_requested_evs + amount
  assignment.load_by_settlement_key[key] =
    (assignment.load_by_settlement_key[key] or 0) + amount
  assignment.requested_settlement_keys[key] = true
  assignment.load_chunks[#assignment.load_chunks + 1] = {
    settlement = candidate.settlement,
    amount = amount
  }
  add_assignment_settlement(assignment, candidate)
  allocated[key] = (allocated[key] or 0) + amount
  first_station[key] = first_station[key] or assignment.station
end

local function admit_prospect(pair, assigned_capacity, first_station, admitted_keys)
  local assignment = pair.assignment
  local candidate = pair.candidate
  local key = candidate.key
  assignment.remaining_capacity = assignment.remaining_capacity - 1
  add_assignment_settlement(assignment, candidate)
  assigned_capacity[key] = 1
  first_station[key] = first_station[key] or assignment.station
  admitted_keys[key] = true
end

local function finalize_assignment(assignment)
  local evs_per_stall = assignment.spec.evs_per_stall
  local stall_index = 1
  local stall_remaining = evs_per_stall
  for _, chunk in ipairs(assignment.load_chunks) do
    local remaining = chunk.amount
    while remaining > 0 do
      local amount = math.min(remaining, stall_remaining)
      assignment.stall_loads[stall_index] =
        (assignment.stall_loads[stall_index] or 0) + amount
      assignment.stall_settlements[stall_index] =
        assignment.stall_settlements[stall_index] or chunk.settlement
      remaining = remaining - amount
      stall_remaining = stall_remaining - amount
      if stall_remaining == 0 then
        stall_index = stall_index + 1
        stall_remaining = evs_per_stall
      end
    end
  end
  assignment.customer_requested_stalls = assignment.total_requested_evs > 0
    and math.ceil(assignment.total_requested_evs / evs_per_stall) or 0
  assignment.requested_stalls = assignment.customer_requested_stalls
end

function ChargerAllocator.allocate(station_specs, demand, options)
  demand = demand or {}
  options = options or {}
  local assignments = {}
  local candidate_pairs_by_key = {}
  local candidate_keys = {}
  local assigned_capacity = {}
  local requested_capacity = {}
  local first_station_by_settlement = {}
  local admitted_keys = {}

  for _, spec in ipairs(station_specs or {}) do
    local total_capacity = math.max(
      0,
      math.floor(spec.ev_capacity or (spec.stalls * spec.evs_per_stall))
    )
    local assignment = {
      spec = spec,
      station = spec.station,
      settlements = {},
      assigned_keys = {},
      operational_settlements = {},
      requested_settlement_keys = {},
      load_by_settlement_key = {},
      load_chunks = {},
      stall_loads = {},
      stall_settlements = {},
      total_capacity = total_capacity,
      remaining_capacity = total_capacity,
      total_requested_evs = 0,
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
    local key = heap_pop(demand_heap, demand_less)
    local pair = best_available_station(candidate_pairs_by_key[key])
    if pair then
      local unmet = (demand[key] or 0) - (requested_capacity[key] or 0)
      local amount = math.min(
        unmet,
        pair.assignment.remaining_capacity,
        pair.assignment.spec.evs_per_stall
      )
      if amount > 0 then
        assign_demand(pair, amount, requested_capacity, first_station_by_settlement)
        assigned_capacity[key] = requested_capacity[key]
      end
      if (requested_capacity[key] or 0) < (demand[key] or 0) then
        heap_push(demand_heap, key, demand_less)
      else
        admitted_keys[key] = true
      end
    end
  end

  if options.admit_prospects ~= false then
    for _, key in ipairs(candidate_keys) do
      if (demand[key] or 0) == 0 then
        local pair = best_available_station(candidate_pairs_by_key[key])
        if pair then
          admit_prospect(
            pair,
            assigned_capacity,
            first_station_by_settlement,
            admitted_keys
          )
        end
      end
    end
  end

  for _, assignment in pairs(assignments) do finalize_assignment(assignment) end

  return {
    assignments = assignments,
    assigned_capacity_by_settlement_key = assigned_capacity,
    requested_capacity_by_settlement_key = requested_capacity,
    first_station_by_settlement_key = first_station_by_settlement,
    admitted_keys = admitted_keys
  }
end

return ChargerAllocator
