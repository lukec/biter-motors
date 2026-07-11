local BuyerQueues = {}

function BuyerQueues.ensure(storage)
  storage.factoryx_customer_buyer_queues = storage.factoryx_customer_buyer_queues or {}
  return storage.factoryx_customer_buyer_queues
end

function BuyerQueues.queue_for(storage, force_name, settlement_key)
  local by_force = BuyerQueues.ensure(storage)
  by_force[force_name] = by_force[force_name] or {}
  by_force[force_name][settlement_key] = by_force[force_name][settlement_key]
    or {units = {}, head = 1, members = {}}
  return by_force[force_name][settlement_key]
end

function BuyerQueues.enqueue(queue, unit_number)
  if not unit_number or queue.members[unit_number] then return false end
  queue.units[#queue.units + 1] = unit_number
  queue.members[unit_number] = true
  return true
end

function BuyerQueues.compact(queue)
  if queue.head <= 256 or queue.head <= #queue.units / 2 then return end
  local compacted = {}
  for index = queue.head, #queue.units do compacted[#compacted + 1] = queue.units[index] end
  queue.units = compacted
  queue.head = 1
end

function BuyerQueues.pop_valid(queue, validator)
  local checks = math.max(0, #queue.units - queue.head + 1)
  while checks > 0 and queue.head <= #queue.units do
    local unit_number = queue.units[queue.head]
    queue.head = queue.head + 1
    queue.members[unit_number] = nil
    checks = checks - 1
    local valid, retry = validator(unit_number)
    if valid then
      BuyerQueues.compact(queue)
      return unit_number
    elseif retry then
      BuyerQueues.enqueue(queue, unit_number)
    end
  end
  BuyerQueues.compact(queue)
  return nil
end

return BuyerQueues
