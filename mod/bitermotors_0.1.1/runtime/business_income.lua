local BusinessIncome = {}

BusinessIncome.sale_recipes = {
  ["bitermotors-sell-prototype-roadster"] = true,
  ["bitermotors-sell-premium-ev"] = true,
  ["bitermotors-sell-mass-market-ev"] = true,
  ["bitermotors-sell-megatruck"] = true,
  ["bitermotors-sell-grid-battery"] = true,
  ["bitermotors-sell-bitertaxi-fleet"] = true
}

function BusinessIncome.ensure(storage, force_name)
  storage.bitermotors_business_income = storage.bitermotors_business_income or {}
  local accounts = storage.bitermotors_business_income
  accounts[force_name] = accounts[force_name] or {profit = 0, by_source = {}}
  return accounts[force_name]
end

function BusinessIncome.record(storage, force_name, source, dollars)
  local amount = math.max(0, math.floor(dollars or 0))
  local account = BusinessIncome.ensure(storage, force_name)
  account.profit = account.profit + amount
  account.by_source[source] = (account.by_source[source] or 0) + amount
  return amount
end

function BusinessIncome.dollar_output(products)
  local dollars = 0
  for _, product in pairs(products or {}) do
    if product.name == "bitermotors-dollar" then
      assert(product.amount and (not product.probability or product.probability == 1),
        "Business profit requires deterministic Dollar output")
      dollars = dollars + product.amount
    end
  end
  return dollars
end

return BusinessIncome
