local BitertaxiDepot = {}

function BitertaxiDepot.consider_nearest(selected_by_unit, unit_number, center, distance)
  local previous = selected_by_unit[unit_number]
  if not previous or distance < previous.distance then
    selected_by_unit[unit_number] = {center = center, distance = distance}
  end
end

function BitertaxiDepot.metrics(args)
  local fleet = math.min(args.max_fleet, args.stored)
  local allocated = math.min(fleet, math.ceil(args.customers / args.customers_per_vehicle))
  local served = math.min(args.customers, allocated * args.customers_per_vehicle)
  return {
    fleet = fleet,
    allocated = allocated,
    served = served,
    revenue_per_minute = allocated / args.vehicle_minutes_per_dollar
      * args.power_factor * args.revenue_multiplier
  }
end

return BitertaxiDepot
