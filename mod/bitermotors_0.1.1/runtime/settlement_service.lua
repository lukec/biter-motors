local SettlementService = {}

function SettlementService.evaluate(vehicles, assigned_capacity, powered_capacity, taxi_served)
  vehicles = math.max(0, vehicles or 0)
  assigned_capacity = math.max(0, assigned_capacity or 0)
  powered_capacity = math.max(0, math.min(assigned_capacity, powered_capacity or 0))
  local private_service = vehicles == 0 and assigned_capacity > 0
    or vehicles > 0 and powered_capacity >= vehicles
  local operational = taxi_served == true or private_service
  return {
    operational = operational,
    route = taxi_served == true and "bitertaxi" or private_service and "private" or "deficient",
    missing = taxi_served == true and 0 or math.max(0, vehicles - powered_capacity),
    capacity_missing = taxi_served == true and 0 or math.max(0, vehicles - assigned_capacity),
    power_missing = taxi_served == true and 0
      or math.max(0, math.min(vehicles, assigned_capacity) - powered_capacity)
  }
end

return SettlementService
