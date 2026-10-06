local CustomerSales = {}

function CustomerSales.ensure(storage, force_name)
  storage.bitermotors_customer_ev_sales = storage.bitermotors_customer_ev_sales or {}
  local sales = storage.bitermotors_customer_ev_sales
  sales[force_name] = sales[force_name] or {}
  return sales[force_name]
end

function CustomerSales.record(storage, force_name, item_name, assigned)
  local vehicles = math.max(0, math.floor(tonumber(assigned) or 0))
  local totals = CustomerSales.ensure(storage, force_name)
  totals[item_name] = (totals[item_name] or 0) + vehicles
  return vehicles
end

function CustomerSales.total(totals)
  local count = 0
  for _, value in pairs(totals) do count = count + value end
  return math.max(0, math.floor(count))
end

function CustomerSales.consumer_total(totals)
  return math.max(0, math.floor(
    (totals["bitermotors-prototype-roadster"] or 0)
    + (totals["bitermotors-premium-ev"] or 0)
    + (totals["bitermotors-mass-market-ev"] or 0)
    + (totals["bitermotors-megatruck"] or 0)
  ))
end

function CustomerSales.gate_progress(totals, gate)
  if gate.total_consumer_sales then return CustomerSales.consumer_total(totals) end
  return math.max(0, math.floor(totals[gate.item] or 0))
end

return CustomerSales
