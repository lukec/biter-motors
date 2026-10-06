local Population = require("__bitermotors__/runtime/customer_population")
local REPORT = "bitermotors-customers.jsonl"
local ROADSTER = "bitermotors-prototype-roadster"
local PREMIUM = "bitermotors-premium-ev"
local MASS = "bitermotors-mass-market-ev"
local TRUCK = "bitermotors-megatruck"
local TAXI = "bitermotors-bitertaxi-fleet"
local MODELS = {ROADSTER, PREMIUM, MASS, TRUCK, TAXI}
local assertions = 0

local function equal(actual, expected, label)
  assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  assertions = assertions + 1
end

local function report(status, extra)
  local row = extra or {}
  row.status, row.tick, row.assertions = status, game.tick, assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function sum(values)
  local total = 0
  for _, count in pairs(values or {}) do total = total + count end
  return total
end

local function pure_fixtures()
  local population = {physical = 1}
  Population.add_unowned(population, 1)
  Population.record_physical_purchase(population, ROADSTER, 1)
  equal(Population.capacity(population, ROADSTER), 1, "physical sale leaves virtual prospect eligible")
  local ticket = assert(Population.reserve(population, ROADSTER))
  equal(Population.capacity(population, ROADSTER), 0, "reserved customer is not available")
  equal(Population.capacity(population, PREMIUM), 0, "same customer cannot reserve two models concurrently")
  equal(Population.virtual_purchase_count(population, ROADSTER), 0, "reservation is not a purchase")
  Population.release(population, ticket)
  equal(Population.capacity(population, ROADSTER), 1, "cancel restores prospect")
  equal(population.virtual_reserved, 0, "cancel removes reserved capacity")
  for index, model in ipairs(MODELS) do
    local completed, previous = Population.purchase(population, model)
    equal(completed, true, "each virtual generation can be bought")
    equal(previous, index > 1 and MODELS[index - 1] or nil, "replacement changes current model")
    equal(sum(population.virtual_by_vehicle), 1, "replacement does not multiply owners")
    equal(population.virtual_unowned, 0, "owned customer is no longer an unowned prospect")
    equal(Population.virtual_purchase_count(population, model), 1, "one virtual purchase per model")
    equal(Population.capacity(population, model), 0, "owned model cannot be bought again")
  end
  for _, model in ipairs(MODELS) do
    equal(Population.purchase(population, model), false, "replaced historical models cannot be bought twice")
  end
  Population.record_physical_purchase(population, ROADSTER, -1)
  equal(population.purchases_by_vehicle[ROADSTER], 1, "physical death preserves virtual purchase")

  local mixed = {}
  Population.add_unowned(mixed, 1)
  Population.purchase(mixed, ROADSTER)
  Population.purchase(mixed, PREMIUM)
  Population.add_unowned(mixed, 1)
  Population.purchase(mixed, MASS)
  equal(Population.capacity(mixed, ROADSTER), 1, "different histories retain an eligible customer")
  local completed, previous = Population.purchase(mixed, ROADSTER)
  equal(completed, true, "eligible history buys older model")
  equal(previous, MASS, "do not give duplicate Roadster to Premium owner")
  equal(sum(mixed.virtual_by_vehicle), 2, "different-history replacement conserves owners")
  equal(Population.capacity(mixed, ROADSTER), 0, "both histories now remember Roadster")
  mixed = helpers.json_to_table(helpers.table_to_json(mixed))
  Population.rebuild_history(mixed)
  equal(mixed.virtual_purchases_by_vehicle[ROADSTER], 2, "serialized cohorts retain all historical purchases")
  equal(mixed.virtual_purchases_by_vehicle[PREMIUM], 1, "serialized cohorts retain replaced Premium")
  equal(mixed.virtual_by_vehicle[PREMIUM], 1, "rebuild keeps current Premium owner")
  equal(mixed.virtual_by_vehicle[ROADSTER], 1, "rebuild keeps current Roadster owner")

  local concurrent = {}
  Population.add_unowned(concurrent, 2)
  local roadster = assert(Population.reserve(concurrent, ROADSTER))
  local premium = assert(Population.reserve(concurrent, PREMIUM))
  equal(Population.reserve(concurrent, MASS), nil, "third office cannot over-reserve two customers")
  equal(concurrent.virtual_reserved, 2, "different models reserve distinct customer slots")
  Population.purchase(concurrent, ROADSTER, roadster)
  equal(Population.purchase(concurrent, ROADSTER, roadster), false, "duplicate completion cannot consume another reserved customer")
  Population.release(concurrent, roadster)
  equal(Population.release(concurrent, roadster), false, "duplicate cancellation cannot release another customer")
  equal(concurrent.virtual_reserved, 1, "one completion leaves other office reservation")
  Population.release(concurrent, premium)
  equal(Population.capacity(concurrent, MASS), 2, "cancellation restores both eligible histories")
  for _, invalid in ipairs({-1, 0.5, 32}) do
    equal(Population.reserve(concurrent, MASS, {history = invalid, vehicle = MASS}), nil,
      "invalid reservation history rejected")
  end
  equal(concurrent.virtual_reserved, 0, "invalid tickets do not leak reservations")

  local large = {}
  Population.add_unowned(large, 1000000)
  for _, model in ipairs(MODELS) do Population.purchase(large, model) end
  equal(large.virtual_unowned + sum(large.virtual_by_vehicle), 1000000, "million-customer aggregate conserves population")
  local entries = 0
  for _, group in pairs(large.virtual_cohorts) do for _ in pairs(group) do entries = entries + 1 end end
  equal(entries, 6, "million customers use six cohort counters, not individual records")
  report("lua_fixtures_passed")
  assertions = 0
end

local function call(name, ...)
  return remote.call("bitermotors", name, ...)
end

local function snapshot()
  return call("progress_status", "player").snapshot
end

local function population()
  local key = storage.spawner.surface.index .. ":" .. storage.spawner.unit_number
  for _, row in ipairs(call("customer_population_status", "player")) do
    if row.key == key then return row end
  end
  error("fixture settlement population was lost")
end

local function make(name, position, force)
  local entity = assert(game.surfaces.nauvis.create_entity{name = name, position = position, force = force})
  script.raise_event(defines.events.script_raised_built, {entity = entity})
  return entity
end

local function add_units(count)
  for index = 1, count do
    make("small-biter", {-16 + (index % 16) * 2, 28 + math.floor(index / 16) * 2}, game.forces.enemy)
  end
end

local function customers()
  return game.surfaces.nauvis.find_entities_filtered{
    force = "bitermotors-customers", type = "unit", area = {{-64, -64}, {64, 64}}
  }
end

local function feed(model)
  local inventory = storage.office.get_inventory(defines.inventory.crafter_input)
  equal(inventory.insert{name = model, count = 1}, 1, "native sale receives vehicle")
  equal(inventory.insert{name = "bitermotors-ev-reservation", count = 1}, 1, "native sale receives paperwork")
end

script.on_init(function()
  pure_fixtures()
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  game.tick_paused = false
  game.speed = 100
  force.technologies["bitermotors-sales-office"].researched = true
  force.technologies["bitermotors-premium-ev-program"].researched = true
  force.technologies["bitermotors-ev-charging-network"].researched = true
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-64, -64}, {64, 64}}}) do entity.destroy() end
  local tiles = {}
  for x = -64, 64 do for y = -64, 64 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  surface.set_tiles(tiles)
  make("substation", {0, 0}, force)
  local power = make("electric-energy-interface", {0, -4}, force)
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production, power.output_flow_limit = 100000000, 100000000
  storage.spawner = make("biter-spawner", {0, 24}, game.forces.enemy)
  script.raise_event(defines.events.on_biter_base_built, {entity = storage.spawner})
  -- The market seeds its initial mobile prospect, giving 129 customers in all.
  add_units(128)
  storage.office = make("bitermotors-sales-office", {6, -4}, force)
  make("bitermotors-ev-charging-station-v2", {-4, 0}, force)
  call("refresh_biter_customer_market", "player")
  storage.office.set_recipe("bitermotors-sell-prototype-roadster")
  storage.stage, storage.started = "bootstrap", game.tick
  storage.pending, storage.waiting_for_sale = 50, 0
end)

local loaded, configured = false, false
script.on_load(function() loaded = storage.stage == "reload" end)
script.on_configuration_changed(function() configured = storage.stage == "reload" end)

local function persistence_assertions()
  local pop = population()
  equal(pop.physical, 0, "zero physical representatives remain")
  equal(pop.virtual_unowned, 1, "virtual unowned prospect persists")
  equal(pop.virtual_by_vehicle[PREMIUM], 1, "virtual Premium owner persists")
  equal(pop.virtual_purchases[ROADSTER], 1, "virtual Roadster history persists after replacement")
  equal(pop.virtual_purchases[PREMIUM], 1, "virtual Premium history persists")
  equal(pop.virtual_reserved, 1, "pending virtual reservation persists")
  equal(call("customer_vehicle_ownership", "player").active, 1, "one active owner persists")
  equal(snapshot().roadsters_sold, 51, "lifetime sales persist independently of population death")
end

script.on_nth_tick(1, function()
  if loaded and storage.stage == "reload" then
    persistence_assertions()
    equal(storage.office.get_control_behavior().circuit_enable_disable, true,
      "native circuit pause survives loading")
    if configured then
      local key = population().key
      storage.spawner.die()
      call("repair_customer_populations")
      local found = false
      for _, row in ipairs(call("customer_population_status", "player")) do
        if row.key == key then found = true end
      end
      equal(found, false, "destroyed settlement does not retain virtual population")
      equal(call("customer_vehicle_ownership", "player").active, 0, "destroyed settlement removes virtual owner from aggregate")
      equal(snapshot().roadsters_sold, 51, "settlement destruction does not erase lifetime sales")
    end
    report(configured and "configuration_passed" or "reload_passed", {saved_tick = storage.saved_tick})
    storage.stage = "done"
    return
  end
  if storage.stage == "reload" or storage.stage == "done" then return end
  assert(game.tick - storage.started < 6000, "customer fixture timed out in " .. storage.stage)
  local progress = snapshot()
  local pop = population()
  if storage.stage == "bootstrap" then
    if progress.roadsters_sold >= storage.waiting_for_sale and storage.pending > 0 then
      feed(ROADSTER)
      storage.pending = storage.pending - 1
      storage.waiting_for_sale = progress.roadsters_sold + 1
    end
    if progress.roadsters_sold == 50 then
      equal(pop.physical, 128, "native representation cap holds physical population")
      equal(pop.virtual_unowned, 1, "native overflow becomes one untouched virtual prospect")
      local keeper
      for _, entity in pairs(customers()) do
        if not keeper and string.find(entity.name, "roadster", 1, true) then keeper = entity end
      end
      assert(keeper, "no native Roadster owner to retain")
      storage.keeper = keeper
      for _, entity in pairs(customers()) do if entity ~= keeper then entity.die() end end
      storage.stage = "mixed"
    end
  elseif storage.stage == "mixed" and pop.physical == 1 then
    equal(pop.physical_purchases[ROADSTER], 1, "one living physical Roadster purchase remains")
    equal(pop.virtual_purchases[ROADSTER] or 0, 0, "physical sale does not consume virtual history")
    feed(ROADSTER)
    storage.stage = "virtual_roadster"
  elseif storage.stage == "virtual_roadster" and progress.roadsters_sold == 51 then
    equal(pop.virtual_by_vehicle[ROADSTER], 1, "untouched virtual prospect buys native Roadster")
    equal(call("customer_vehicle_ownership", "player").active, 2, "mixed owners both count")
    storage.office.set_recipe("bitermotors-sell-premium-ev")
    feed(PREMIUM)
    storage.stage = "physical_premium"
  elseif storage.stage == "physical_premium" and progress.premium_evs_sold == 1 then
    equal(pop.physical_purchases[PREMIUM], 1, "physical replacement records its own history")
    equal(pop.virtual_purchases[PREMIUM] or 0, 0, "physical Premium does not consume virtual eligibility")
    equal(call("customer_vehicle_ownership", "player").active, 2, "physical replacement preserves owner count")
    feed(PREMIUM)
    storage.stage = "cancel_virtual"
  elseif storage.stage == "cancel_virtual" and storage.office.crafting_progress > 0 then
    equal(pop.virtual_reserved, 1, "in-progress native sale reserves virtual buyer")
    storage.office.set_recipe(nil)
    call("sync_sales_offices")
    equal(population().virtual_reserved, 0, "recipe cancellation frees virtual reservation")
    equal(snapshot().premium_evs_sold, 1, "canceled virtual sale does not enter lifetime ledger")
    storage.office.get_inventory(defines.inventory.crafter_input).clear()
    storage.office.set_recipe("bitermotors-sell-premium-ev")
    feed(PREMIUM)
    storage.stage = "virtual_premium"
  elseif storage.stage == "virtual_premium" and progress.premium_evs_sold == 2 then
    equal(pop.virtual_purchases[PREMIUM], 1, "virtual replacement records independent Premium purchase")
    equal(pop.virtual_by_vehicle[ROADSTER], 0, "replacement retires virtual Roadster")
    equal(call("customer_vehicle_ownership", "player").active, 2, "virtual replacement preserves owner count")
    for _, entity in pairs(customers()) do entity.die() end
    add_units(129)
    call("refresh_biter_customer_market", "player")
    equal(population().virtual_unowned, 1, "new native overflow creates fresh virtual prospect")
    for _, entity in pairs(customers()) do entity.die() end
    storage.office.set_recipe("bitermotors-sell-prototype-roadster")
    feed(ROADSTER)
    storage.stage = "pending_virtual"
  elseif storage.stage == "pending_virtual" and storage.office.crafting_progress > 0 then
    local control = storage.office.get_or_create_control_behavior()
    control.circuit_enable_disable = true
    control.circuit_condition = {condition = {
      first_signal = {type = "virtual", name = "signal-A"}, comparator = ">", constant = 0
    }}
    call("repair_customer_populations")
    call("repair_customer_populations")
    persistence_assertions()
    storage.saved_tick, storage.stage = game.tick, "reload"
    game.server_save("bitermotors-customers-reload")
    report("customers_passed", {saved_tick = storage.saved_tick, population = population()})
  end
end)
