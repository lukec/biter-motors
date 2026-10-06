local CustomerPopulation = {}

local VEHICLES = {
  "bitermotors-prototype-roadster",
  "bitermotors-premium-ev",
  "bitermotors-mass-market-ev",
  "bitermotors-megatruck",
  "bitermotors-bitertaxi-fleet"
}
local BITS = {}
-- These persisted bit assignments are append-only; never reorder the models.
for index, vehicle in ipairs(VEHICLES) do BITS[vehicle] = 2 ^ (index - 1) end
local HISTORY_COUNT = 2 ^ #VEHICLES
local UNOWNED = "unowned"

local function purchased(history, vehicle)
  local bit = BITS[vehicle]
  return bit and history % (bit * 2) >= bit
end

function CustomerPopulation.ensure(population)
  population.virtual_cohorts = population.virtual_cohorts or {}
  population.virtual_reserved_by_cohort = population.virtual_reserved_by_cohort or {}
  population.virtual_reserved_by_vehicle = population.virtual_reserved_by_vehicle or {}
  population.virtual_reserved = population.virtual_reserved or 0
  population.virtual_by_vehicle = population.virtual_by_vehicle or {}
  population.virtual_unowned = population.virtual_unowned or 0
  population.virtual_purchases_by_vehicle = population.virtual_purchases_by_vehicle or {}
  population.physical_purchases_by_vehicle = population.physical_purchases_by_vehicle or {}
  population.purchases_by_vehicle = population.purchases_by_vehicle or {}
  return population
end

local function group_count(groups, history, current)
  local group = groups[tostring(history)]
  return group and group[current] or 0
end

local function add_group(groups, history, current, amount)
  local key = tostring(history)
  groups[key] = groups[key] or {}
  local count = (groups[key][current] or 0) + amount
  groups[key][current] = count > 0 and count or nil
  if next(groups[key]) == nil then groups[key] = nil end
end

function CustomerPopulation.add_unowned(population, count)
  CustomerPopulation.ensure(population)
  count = math.max(0, math.floor(count or 0))
  if count == 0 then return end
  add_group(population.virtual_cohorts, 0, UNOWNED, count)
  population.virtual_unowned = population.virtual_unowned + count
end

function CustomerPopulation.record_physical_purchase(population, vehicle, amount)
  if not population or not vehicle or amount == 0 then return end
  CustomerPopulation.ensure(population)
  local physical = population.physical_purchases_by_vehicle
  physical[vehicle] = math.max(0, (physical[vehicle] or 0) + amount)
  population.purchases_by_vehicle[vehicle] = physical[vehicle]
    + (population.virtual_purchases_by_vehicle[vehicle] or 0)
end

function CustomerPopulation.virtual_purchase_count(population, vehicle)
  return population and population.virtual_purchases_by_vehicle
    and population.virtual_purchases_by_vehicle[vehicle] or 0
end

local function available(population, history, current, vehicle)
  return BITS[vehicle] and not purchased(history, vehicle)
    and group_count(population.virtual_cohorts, history, current)
      > group_count(population.virtual_reserved_by_cohort, history, current)
end

function CustomerPopulation.capacity(population, vehicle)
  if not population or not BITS[vehicle] then return 0 end
  CustomerPopulation.ensure(population)
  local count = 0
  for history = 0, HISTORY_COUNT - 1 do
    if not purchased(history, vehicle) then
      for current, total in pairs(population.virtual_cohorts[tostring(history)] or {}) do
        count = count + math.max(0, total
          - group_count(population.virtual_reserved_by_cohort, history, current))
      end
    end
  end
  return count
end

function CustomerPopulation.reserve(population, vehicle, ticket)
  if not population or not BITS[vehicle] then return nil end
  CustomerPopulation.ensure(population)
  local history, current
  if ticket then
    history = ticket.history
    current = ticket.previous_vehicle or UNOWNED
    if ticket.completed or ticket.vehicle ~= vehicle or type(history) ~= "number"
      or history < 0 or history >= HISTORY_COUNT or history ~= math.floor(history)
      or not available(population, history, current, vehicle) then return nil end
  elseif available(population, 0, UNOWNED, vehicle) then
    history, current = 0, UNOWNED
  else
    for _, candidate in ipairs(VEHICLES) do
      for mask = 1, HISTORY_COUNT - 1 do
        if available(population, mask, candidate, vehicle) then
          history, current = mask, candidate
          break
        end
      end
      if history then break end
    end
  end
  if not history then return nil end
  add_group(population.virtual_reserved_by_cohort, history, current, 1)
  population.virtual_reserved = population.virtual_reserved + 1
  population.virtual_reserved_by_vehicle[vehicle] =
    (population.virtual_reserved_by_vehicle[vehicle] or 0) + 1
  if ticket then
    ticket.released = false
    return ticket
  end
  return {history = history, previous_vehicle = current ~= UNOWNED and current or nil,
    vehicle = vehicle}
end

function CustomerPopulation.clear_reservations(population)
  population.virtual_reserved = 0
  population.virtual_reserved_by_vehicle = {}
  population.virtual_reserved_by_cohort = {}
end

function CustomerPopulation.release(population, ticket)
  if not population or not ticket or ticket.released then return false end
  CustomerPopulation.ensure(population)
  local current = ticket.previous_vehicle or UNOWNED
  if group_count(population.virtual_reserved_by_cohort, ticket.history, current) <= 0
    or (population.virtual_reserved_by_vehicle[ticket.vehicle] or 0) <= 0 then return false end
  add_group(population.virtual_reserved_by_cohort, ticket.history, current, -1)
  population.virtual_reserved = math.max(0, population.virtual_reserved - 1)
  population.virtual_reserved_by_vehicle[ticket.vehicle] = math.max(0,
    population.virtual_reserved_by_vehicle[ticket.vehicle] - 1)
  ticket.released = true
  return true
end

function CustomerPopulation.purchase(population, vehicle, ticket)
  if not population or not BITS[vehicle] then return false, nil end
  CustomerPopulation.ensure(population)
  local temporary = ticket == nil
  ticket = ticket or CustomerPopulation.reserve(population, vehicle)
  if not ticket then return false, nil end
  local history = ticket.history
  local current = ticket.previous_vehicle or UNOWNED
  if ticket.released or ticket.completed or ticket.vehicle ~= vehicle or type(history) ~= "number"
    or history < 0 or history >= HISTORY_COUNT or history ~= math.floor(history)
    or purchased(history, vehicle)
    or group_count(population.virtual_cohorts, history, current) <= 0
    or group_count(population.virtual_reserved_by_cohort, history, current) <= 0
    or (population.virtual_reserved_by_vehicle[vehicle] or 0) <= 0 then
    return false, nil
  end
  -- At most 32 histories x five current models, regardless of population size.
  add_group(population.virtual_cohorts, history, current, -1)
  add_group(population.virtual_cohorts, history + BITS[vehicle], vehicle, 1)
  if current == UNOWNED then
    population.virtual_unowned = population.virtual_unowned - 1
  else
    population.virtual_by_vehicle[current] = population.virtual_by_vehicle[current] - 1
  end
  population.virtual_by_vehicle[vehicle] = (population.virtual_by_vehicle[vehicle] or 0) + 1
  population.virtual_purchases_by_vehicle[vehicle] =
    (population.virtual_purchases_by_vehicle[vehicle] or 0) + 1
  population.purchases_by_vehicle[vehicle] = population.virtual_purchases_by_vehicle[vehicle]
    + (population.physical_purchases_by_vehicle[vehicle] or 0)
  ticket.completed = true
  if temporary then CustomerPopulation.release(population, ticket) end
  return true, ticket.previous_vehicle
end

function CustomerPopulation.rebuild_history(population)
  CustomerPopulation.ensure(population)
  population.virtual_unowned = 0
  population.virtual_by_vehicle = {}
  population.virtual_purchases_by_vehicle = {}
  population.physical_purchases_by_vehicle = {}
  population.purchases_by_vehicle = {}
  for history, group in pairs(population.virtual_cohorts) do
    local mask = tonumber(history)
    for current, count in pairs(group) do
      if current == UNOWNED then population.virtual_unowned = population.virtual_unowned + count
      else population.virtual_by_vehicle[current] = (population.virtual_by_vehicle[current] or 0) + count end
      for _, vehicle in ipairs(VEHICLES) do
        if purchased(mask, vehicle) then
          population.virtual_purchases_by_vehicle[vehicle] =
            (population.virtual_purchases_by_vehicle[vehicle] or 0) + count
        end
      end
    end
  end
  for vehicle, count in pairs(population.virtual_purchases_by_vehicle) do
    population.purchases_by_vehicle[vehicle] = count
  end
end

return CustomerPopulation
