local CustomerAggregates = {}

function CustomerAggregates.ensure(storage)
  storage.bitermotors_customer_vehicle_aggregates = storage.bitermotors_customer_vehicle_aggregates or {}
  return storage.bitermotors_customer_vehicle_aggregates
end

function CustomerAggregates.summary(storage, force_name)
  local aggregates = CustomerAggregates.ensure(storage)
  aggregates[force_name] = aggregates[force_name]
    or {total = 0, by_vehicle = {}, by_settlement = {}}
  return aggregates[force_name]
end

function CustomerAggregates.add(storage, owners, unit_number, ownership)
  if not unit_number or not ownership or owners[unit_number] then return false end
  owners[unit_number] = ownership
  local aggregate = CustomerAggregates.summary(storage, ownership.market_force_name)
  aggregate.total = aggregate.total + 1
  aggregate.by_vehicle[ownership.vehicle] = (aggregate.by_vehicle[ownership.vehicle] or 0) + 1
  aggregate.by_settlement[ownership.settlement_key] =
    (aggregate.by_settlement[ownership.settlement_key] or 0) + 1
  return true
end

function CustomerAggregates.remove(storage, owners, unit_number)
  local ownership = unit_number and owners[unit_number]
  if not ownership then return nil end
  owners[unit_number] = nil
  local aggregate = CustomerAggregates.summary(storage, ownership.market_force_name)
  aggregate.total = math.max(0, aggregate.total - 1)
  aggregate.by_vehicle[ownership.vehicle] = math.max(0, (aggregate.by_vehicle[ownership.vehicle] or 0) - 1)
  aggregate.by_settlement[ownership.settlement_key] = math.max(
    0,
    (aggregate.by_settlement[ownership.settlement_key] or 0) - 1
  )
  return ownership
end

function CustomerAggregates.add_virtual(storage, ownership, count)
  count = math.max(0, count or 0)
  if count == 0 or not ownership then return false end
  local aggregate = CustomerAggregates.summary(storage, ownership.market_force_name)
  aggregate.total = aggregate.total + count
  aggregate.by_vehicle[ownership.vehicle] = (aggregate.by_vehicle[ownership.vehicle] or 0) + count
  aggregate.by_settlement[ownership.settlement_key] =
    (aggregate.by_settlement[ownership.settlement_key] or 0) + count
  return true
end

function CustomerAggregates.replace_virtual(storage, market_force_name, old_vehicle, new_vehicle, count)
  count = math.max(0, count or 0)
  if count == 0 or not market_force_name or not new_vehicle then return false end
  local aggregate = CustomerAggregates.summary(storage, market_force_name)
  if old_vehicle then
    aggregate.by_vehicle[old_vehicle] = math.max(
      0,
      (aggregate.by_vehicle[old_vehicle] or 0) - count
    )
  else
    aggregate.total = aggregate.total + count
  end
  aggregate.by_vehicle[new_vehicle] = (aggregate.by_vehicle[new_vehicle] or 0) + count
  return true
end

function CustomerAggregates.rebuild(storage, owners, units, populations)
  storage.bitermotors_customer_vehicle_aggregates = {}
  for unit_number, ownership in pairs(owners) do
    local entity = units[unit_number]
    if ownership and entity and entity.valid then
      local aggregate = CustomerAggregates.summary(storage, ownership.market_force_name)
      aggregate.total = aggregate.total + 1
      aggregate.by_vehicle[ownership.vehicle] = (aggregate.by_vehicle[ownership.vehicle] or 0) + 1
      aggregate.by_settlement[ownership.settlement_key] =
        (aggregate.by_settlement[ownership.settlement_key] or 0) + 1
    else
      owners[unit_number] = nil
    end
  end
  for settlement_key, population in pairs(populations or {}) do
    for vehicle, count in pairs(population.virtual_by_vehicle or {}) do
      CustomerAggregates.add_virtual(storage, {
        vehicle = vehicle,
        settlement_key = settlement_key,
        market_force_name = population.market_force_name
      }, count)
    end
  end
end

return CustomerAggregates
