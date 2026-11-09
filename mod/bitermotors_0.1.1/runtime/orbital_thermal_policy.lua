local P = {
  core = "bitermotors-orbital-datacenter-core",
  buffer = "bitermotors-orbital-heat-buffer",
  radiator = "bitermotors-orbital-radiator-panel",
  pipe = "bitermotors-orbital-heat-pipe",
  target_c = 97, radiator_reference_c = 91.6,
  warning_c = 105, critical_c = 120, burnout_c = 130, floor_c = 15,
  core_watts = 250000000, idle_watts = 250000000 / 30,
  radiator_max_watts = 300000000,
  core_joules_per_c = 1200000000, radiator_joules_per_c = 100000000,
  conduit_joules_per_c = 20000000,
  interval_ticks = 15, batch_limit = 64, alert_interval_ticks = 120
}

function P.radiated_watts(temperature)
  return math.min(P.radiator_max_watts,
    P.core_watts * ((temperature + 273.15) / (P.radiator_reference_c + 273.15)) ^ 4)
end

function P.cool(temperature, seconds)
  local available = math.max(0, temperature - P.floor_c) * P.radiator_joules_per_c
  local removed = math.min(available, P.radiated_watts(temperature) * seconds)
  return temperature - removed / P.radiator_joules_per_c, removed
end

function P.state(temperature)
  if temperature >= P.burnout_c then return "burnout" end
  if temperature >= P.critical_c then return "critical" end
  if temperature >= P.warning_c then return "warning" end
  return "normal"
end

function P.work_seconds(previous, current, speed, elapsed)
  if speed <= 0 then return 0 end
  return math.max(0, math.min(elapsed, (current - previous) / speed))
end

function P.heat_joules(work_seconds, elapsed, consumption_bonus, idle_fraction)
  return work_seconds * P.core_watts * math.max(0.2, 1 + consumption_bonus)
    + elapsed * P.idle_watts * math.max(0, math.min(1, idle_fraction))
end

function P.contract()
  local result = {}
  for key, value in pairs(P) do
    if type(value) ~= "function" then result[key] = value end
  end
  return result
end

return P
