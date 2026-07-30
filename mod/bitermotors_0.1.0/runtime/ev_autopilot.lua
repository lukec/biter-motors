local EvAutopilot = {}

EvAutopilot.config = {
  max_active = 32,
  updates_per_tick = 16,
  recent_vehicle_limit = 8,
  path_retry_limit = 3,
  path_retry_ticks = 60,
  stuck_ticks = 3 * 60,
  safety_check_ticks = 30,
  safety_radius = 20,
  summon_start_charge = 0.10,
  cancel_charge = 0.03,
  summon_stop_distance = 1.5,
  navigate_stop_distance = 1.5
}

EvAutopilot.eligible_names = {
  ["bitermotors-premium-ev"] = true,
  ["bitermotors-mass-market-ev"] = true,
  ["bitermotors-megatruck"] = true,
  ["bitermotors-robotaxi-fleet"] = true
}

function EvAutopilot.ensure(runtime)
  runtime = runtime or {}
  runtime.active = runtime.active or {}
  runtime.order = runtime.order or {}
  runtime.order_index = runtime.order_index or 1
  runtime.path_requests = runtime.path_requests or {}
  runtime.recent_by_player = runtime.recent_by_player or {}
  runtime.owner_by_vehicle = runtime.owner_by_vehicle or {}
  runtime.stats = runtime.stats or {
    completed = 0,
    canceled = 0,
    canceled_by_reason = {}
  }
  runtime.stats.canceled_by_reason = runtime.stats.canceled_by_reason or {}
  return runtime
end

function EvAutopilot.is_eligible_name(name)
  return EvAutopilot.eligible_names[name] == true
end

function EvAutopilot.distance_squared(left, right)
  local dx = left.x - right.x
  local dy = left.y - right.y
  return dx * dx + dy * dy
end

function EvAutopilot.area_center(area)
  return {
    x = (area.left_top.x + area.right_bottom.x) / 2,
    y = (area.left_top.y + area.right_bottom.y) / 2
  }
end

function EvAutopilot.remember_vehicle(runtime, player_index, unit_number)
  runtime = EvAutopilot.ensure(runtime)
  local previous_owner = runtime.owner_by_vehicle[unit_number]
  if previous_owner and previous_owner ~= player_index then
    local previous = runtime.recent_by_player[previous_owner] or {}
    for index = #previous, 1, -1 do
      if previous[index] == unit_number then table.remove(previous, index) end
    end
  end
  local recent = runtime.recent_by_player[player_index] or {}
  for index = #recent, 1, -1 do
    if recent[index] == unit_number then table.remove(recent, index) end
  end
  table.insert(recent, 1, unit_number)
  while #recent > EvAutopilot.config.recent_vehicle_limit do table.remove(recent) end
  runtime.recent_by_player[player_index] = recent
  runtime.owner_by_vehicle[unit_number] = player_index
  return recent
end

function EvAutopilot.forget_vehicle(runtime, unit_number)
  runtime = EvAutopilot.ensure(runtime)
  local owner = runtime.owner_by_vehicle[unit_number]
  runtime.owner_by_vehicle[unit_number] = nil
  if owner then
    local recent = runtime.recent_by_player[owner] or {}
    for index = #recent, 1, -1 do
      if recent[index] == unit_number then table.remove(recent, index) end
    end
  end
end

function EvAutopilot.track_active(runtime, unit_number)
  runtime = EvAutopilot.ensure(runtime)
  for _, existing in pairs(runtime.order) do
    if existing == unit_number then return end
  end
  runtime.order[#runtime.order + 1] = unit_number
end

function EvAutopilot.next_active(runtime)
  runtime = EvAutopilot.ensure(runtime)
  if #runtime.order == 0 then return nil end
  local attempts = #runtime.order
  while attempts > 0 do
    if runtime.order_index > #runtime.order then runtime.order_index = 1 end
    local unit_number = runtime.order[runtime.order_index]
    runtime.order_index = runtime.order_index + 1
    if runtime.active[unit_number] then return unit_number end
    table.remove(runtime.order, runtime.order_index - 1)
    runtime.order_index = runtime.order_index - 1
    attempts = attempts - 1
  end
  return nil
end

function EvAutopilot.active_count(runtime)
  local count = 0
  for _ in pairs(EvAutopilot.ensure(runtime).active) do count = count + 1 end
  return count
end

function EvAutopilot.target_orientation(position, target)
  local orientation = math.atan2(target.x - position.x, position.y - target.y)
    / (2 * math.pi)
  if orientation < 0 then orientation = orientation + 1 end
  return orientation
end

function EvAutopilot.orientation_delta(current, target)
  local delta = target - current
  if delta > 0.5 then delta = delta - 1 end
  if delta < -0.5 then delta = delta + 1 end
  return delta
end

function EvAutopilot.drive_decision(vehicle, waypoint, final_waypoint, stop_distance)
  local distance = math.sqrt(EvAutopilot.distance_squared(vehicle.position, waypoint))
  local target = EvAutopilot.target_orientation(vehicle.position, waypoint)
  local delta = EvAutopilot.orientation_delta(vehicle.orientation, target)
  local speed = math.abs(vehicle.speed or 0)
  local turn = math.abs(delta)
  local desired_speed = 0.28

  if turn > 0.16 then
    desired_speed = 0.055
  elseif turn > 0.08 then
    desired_speed = 0.10
  elseif turn > 0.035 then
    desired_speed = 0.17
  end
  if final_waypoint then
    if distance <= stop_distance then
      desired_speed = 0
    elseif distance < stop_distance + 2 then
      desired_speed = math.min(desired_speed, 0.025)
    elseif distance < stop_distance + 7 then
      desired_speed = math.min(desired_speed, 0.07)
    elseif distance < stop_distance + 18 then
      desired_speed = math.min(desired_speed, 0.14)
    end
  end

  local acceleration = "nothing"
  if desired_speed == 0 or speed > desired_speed + 0.012 then
    acceleration = "braking"
  elseif speed < desired_speed - 0.008 then
    acceleration = "accelerating"
  end
  local direction = "straight"
  if delta > 0.008 then
    direction = "right"
  elseif delta < -0.008 then
    direction = "left"
  end
  return {
    acceleration = acceleration,
    direction = direction,
    distance = distance,
    orientation_delta = delta,
    desired_speed = desired_speed
  }
end

return EvAutopilot
