local P = {
  target_c = 97, radiator_reference_c = 94.65,
  warning_c = 105, critical_c = 120, burnout_c = 130, floor_c = 15,
  core_watts = 250000000, radiator_max_watts = 300000000,
  core_joules_per_c = 500000000, radiator_joules_per_c = 100000000,
  conduit_joules_per_c = 20000000, interval_ticks = 15
}

function P.radiated_watts(temperature)
  local kelvin, reference = temperature + 273.15, P.radiator_reference_c + 273.15
  return math.min(P.radiator_max_watts, P.core_watts * (kelvin / reference)^4)
end

function P.cool(temperature, seconds)
  local available = math.max(0, temperature - P.floor_c) * P.radiator_joules_per_c
  local removed = math.min(available, P.radiated_watts(temperature) * seconds)
  return temperature - removed / P.radiator_joules_per_c, removed
end

function P.work_delta(previous, current, elapsed)
  return math.max(0, math.min(elapsed, current - previous))
end

function P.state(temperature)
  if temperature >= P.burnout_c then return "burnout" end
  if temperature >= P.critical_c then return "critical" end
  if temperature >= P.warning_c then return "warning" end
  return "normal"
end

return P
