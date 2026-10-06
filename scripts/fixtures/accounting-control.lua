local ProductionHistory = require("__bitermotors__/runtime/production_history")
local CustomerSales = require("__bitermotors__/runtime/customer_sales")
local REPORT = "bitermotors-accounting.jsonl"
local ROADSTER = "bitermotors-prototype-roadster"
local PREMIUM = "bitermotors-premium-ev"
local MASS = "bitermotors-mass-market-ev"
local TAXI = "bitermotors-bitertaxi-fleet"
local DOLLAR = "bitermotors-dollar"
local assertions = 0

local function serialized_copy(value)
  return helpers.json_to_table(helpers.table_to_json(value))
end

local function equal(actual, expected, label)
  assert(actual == expected, label .. ": expected " .. tostring(expected)
    .. ", got " .. tostring(actual))
  assertions = assertions + 1
end

local function report(status, extra)
  local row = extra or {}
  row.status = status
  row.tick = game.tick
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function pure_fixtures()
  local state
  for _, count in ipairs({0, 99, 100, 249, 250}) do
    local total
    total, state = ProductionHistory.observe(state, count)
    equal(total, count, "observed production boundary")
  end
  local total
  total, state = ProductionHistory.observe(state, 2)
  equal(total, 252, "post-reset production is not discarded")
  equal(state.reset_count, 1, "one reset epoch")
  total, state = ProductionHistory.observe(serialized_copy(state), 3)
  equal(total, 253, "serialized history remains monotonic")
  total, state = ProductionHistory.observe(state, 3)
  equal(total, 253, "repeated observation is idempotent")

  for _, case in ipairs({
    {item = ROADSTER, threshold = 50},
    {item = PREMIUM, threshold = 250},
    {item = MASS, threshold = 2000},
    {total_consumer_sales = true, threshold = 5000}
  }) do
    local fixture = {}
    local sales = CustomerSales.ensure(fixture, "player")
    equal(CustomerSales.gate_progress(sales, case), 0, "new ledger is empty")
    local item = case.item or ROADSTER
    equal(CustomerSales.record(fixture, "player", item, 0), 0, "no assignment, no sale")
    CustomerSales.record(fixture, "player", item, case.threshold - 1)
    equal(CustomerSales.gate_progress(sales, case), case.threshold - 1,
      "below exact sold-car boundary")
    CustomerSales.record(fixture, "player", item, 1)
    equal(CustomerSales.gate_progress(sales, case), case.threshold,
      "at exact sold-car boundary")
    equal(CustomerSales.gate_progress(CustomerSales.ensure(serialized_copy(fixture), "player"), case),
      case.threshold, "saved ledger preserves sold-car boundary")
    equal(CustomerSales.total(CustomerSales.ensure(fixture, "other-force")), 0,
      "sales are force-local")
    CustomerSales.record(fixture, "player", TAXI, 10000)
    equal(CustomerSales.gate_progress(sales, case), case.threshold,
      "taxi fleet production/adoption does not advance consumer gates")
  end
  local fixture = {}
  CustomerSales.record(fixture, "player", TAXI, 2)
  equal(CustomerSales.total(CustomerSales.ensure(fixture, "player")), 2,
    "partial assignment records assigned vehicles, not recipe batch size")
  equal(CustomerSales.consumer_total(CustomerSales.ensure(fixture, "player")), 0,
    "legacy taxi transactions are not consumer car sales")
  report("lua_fixtures_passed", {assertions = assertions})
end

local function snapshot(force)
  return remote.call("bitermotors", "progress_status", (force or game.forces.player).name).snapshot
end

local function make(surface, name, position, force)
  local entity = assert(surface.create_entity{name = name, position = position, force = force})
  script.raise_event(defines.events.script_raised_built, {entity = entity})
  return entity
end

local function input(machine)
  return machine.get_inventory(defines.inventory.crafter_input)
end

local function output(machine)
  return machine.get_inventory(defines.inventory.crafter_output)
end

script.on_init(function()
  pure_fixtures()
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  game.tick_paused = false
  game.speed = 100
  for _, name in ipairs({"bitermotors-sales-office", "bitermotors-premium-ev-program",
    "bitermotors-ev-charging-network"}) do
    force.technologies[name].researched = true
  end
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-64, -64}, {64, 64}}}) do
    entity.destroy()
  end
  local tiles = {}
  for x = -64, 64 do
    for y = -64, 64 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end
  end
  surface.set_tiles(tiles)
  make(surface, "substation", {0, 0}, force)
  make(surface, "substation", {16, 0}, force)
  local power = make(surface, "electric-energy-interface", {0, -4}, force)
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production = 100000000
  power.output_flow_limit = 100000000
  local assembler = make(surface, "assembling-machine-2", {16, -4}, force)
  assembler.set_recipe("bitermotors-accounting-premium")
  input(assembler).insert{name = "copper-plate", count = 99}
  local office = make(surface, "bitermotors-sales-office", {4, -4}, force)
  office.set_recipe("bitermotors-sell-prototype-roadster")
  local charger = make(surface, "bitermotors-ev-charging-station", {-4, 0}, force)
  local spawner = make(surface, "biter-spawner", {-4, 20}, game.forces.enemy)
  script.raise_event(defines.events.on_biter_base_built, {entity = spawner})
  for index = 1, 55 do
    make(surface, "small-biter", {-14 + index % 11 * 2, 24 + math.floor(index / 11) * 2},
      game.forces.enemy)
  end
  local chest = make(surface, "steel-chest", {12, -8}, force)
  chest.get_inventory(defines.inventory.chest).insert{name = PREMIUM, count = 100}
  local parked = make(surface, PREMIUM, {20, -10}, force)
  parked.destructible = false
  storage.assembler = assembler
  storage.office = office
  storage.charger = charger
  storage.stage = "produce99"
  storage.started = game.tick
end)

local function native_stage()
  local force = game.forces.player
  local surface = game.surfaces.nauvis
  local office = storage.office
  local assembler = storage.assembler
  if (storage.pending_copper or 0) > 0 then
    storage.pending_copper = storage.pending_copper - input(assembler).insert{
      name = "copper-plate", count = storage.pending_copper
    }
  end
  if (storage.pending_sales or 0) > 0 then
    local inserted = input(office).insert{name = ROADSTER, count = storage.pending_sales}
    if inserted > 0 then
      input(office).insert{name = "bitermotors-ev-reservation", count = inserted}
    end
    storage.pending_sales = storage.pending_sales - inserted
  end
  -- Drain the test crafter so physical stock cannot back-pressure its counter.
  output(assembler).clear()
  local progress = snapshot()
  local manufactured = progress.premium_evs_produced
  storage.last_native_tick = game.tick
  if storage.stage == "produce99" and manufactured == 99 then
    equal(progress.roadsters_sold, 0, "unsold production does not imply Roadster sales")
    equal(progress.premium_evs_sold, 0, "stored/parked Premiums are not sales")
    equal(force.recipes["bitermotors-premium-ev"].enabled, false,
      "manufacturing does not bypass 50 Roadster sales")
    equal(force.recipes["bitermotors-biterfactory-building"].enabled, false,
      "99 is below Biterfactory gate")
    input(assembler).insert{name = "copper-plate", count = 1}
    storage.stage = "produce100"
  elseif storage.stage == "produce100" and manufactured == 100 then
    remote.call("bitermotors", "progression_integrity", force.name)
    equal(force.recipes["bitermotors-biterfactory-building"].enabled, true,
      "100 manufactured unlocks Biterfactory")
    equal(progress.advanced_battery_chemistry_available, false, "100 does not reveal advanced chemistry")
    storage.pending_copper = 149 - input(assembler).insert{name = "copper-plate", count = 149}
    storage.stage = "produce249"
  elseif storage.stage == "produce249" and manufactured == 249 then
    equal(progress.advanced_battery_chemistry_available, false, "249 is below chemistry gate")
    input(assembler).insert{name = "copper-plate", count = 1}
    storage.stage = "produce250"
  elseif storage.stage == "produce250" and manufactured == 250 then
    equal(progress.advanced_battery_chemistry_available, true, "250 reveals chemistry")
    equal(progress.customer_ev_sales_lifetime, 0, "250 manufactured, no customers sold")
    storage.pending_sales = 49
    storage.stage = "sell49"
    remote.call("bitermotors", "refresh_biter_customer_market", force.name)
    remote.call("bitermotors", "sync_sales_offices")
  elseif storage.stage == "sell49" and progress.roadsters_sold == 49 then
    equal(progress.premium_ev_gate.enabled, false, "49 real Roadster sales do not unlock Premium")
    equal(progress.dollars_produced, 98, "native sales profit matches Progress")
    storage.pending_sales = 1
    storage.stage = "sell50"
  elseif storage.stage == "sell50" and progress.roadsters_sold == 50 then
    equal(progress.premium_ev_gate.enabled, true, "50 actual Roadster sales unlock Premium")
    equal(progress.dollars_produced, 100, "50 sales produce 100 Dollars")
    office.set_recipe("bitermotors-sell-premium-ev")
    input(office).insert{name = PREMIUM, count = 1}
    input(office).insert{name = "bitermotors-ev-reservation", count = 1}
    storage.stage = "cancel_premium"
  elseif storage.stage == "cancel_premium" and office.crafting_progress > 0 then
    office.set_recipe(nil)
    storage.stage = "canceled"
    storage.stage_tick = game.tick
  elseif storage.stage == "canceled" and game.tick > storage.stage_tick then
    equal(progress.premium_evs_sold, 0, "canceled in-progress Premium sale is not counted")
    equal(progress.customer_ev_sales_lifetime, 50, "recipe change does not invent a completed sale")
    equal(progress.dollars_produced, 100, "canceled sale generates no profit")
    local stats = force.get_item_production_statistics(surface)
    stats.clear()
    stats.on_flow(PREMIUM, 2)
    stats.on_flow(PREMIUM, -10)
    stats.on_flow({name = PREMIUM, quality = "rare"}, 3)
    stats.on_flow(DOLLAR, 13)
    stats.on_flow("bitermotors-nickel-ore", 7)
    stats.on_flow("bitermotors-nickel-ore", -3)
    local fluid_stats = force.get_fluid_production_statistics(surface)
    fluid_stats.on_flow("bitermotors-lithium-brine", 7)
    fluid_stats.on_flow("bitermotors-lithium-brine", -3)
    local extra = game.create_surface("accounting-other-surface", {width = 32, height = 32})
    force.get_item_production_statistics(extra).on_flow({name = PREMIUM, quality = "legendary"}, 4)
    local other_force = game.create_force("accounting-other-force")
    other_force.get_item_production_statistics(extra).on_flow(PREMIUM, 500)
    storage.stage = "statistics"
    storage.stage_tick = game.tick
  elseif storage.stage == "statistics" and game.tick > storage.stage_tick then
    local history = remote.call("bitermotors", "premium_ev_production_history", force.name)
    equal(manufactured, 259, "production survives clear and includes rare/legendary and other surface")
    equal(history.raw, 9, "raw production includes every quality")
    equal(history.consumed, 10, "consumption is a separate statistic")
    equal(history.reset_count, 1, "only the cleared surface starts a new epoch")
    equal(progress.dollars_produced, 113, "scripted positive flow adds income after statistics clear")
    equal(progress.nickel_ore_mined, 7, "stored Nickel production, not consumption")
    equal(progress.lithium_brine_pumped, 7, "stored Lithium production, not consumption")
    equal(progress.roadsters_sold, 50, "statistics clear does not clear real sales")
    equal(snapshot(game.forces["accounting-other-force"]).premium_evs_produced, 500,
      "other force has its own production history")
    equal(snapshot(game.forces["accounting-other-force"]).customer_ev_sales_lifetime, 0,
      "another force's manufacturing is not sales")
    storage.stage = "reload"
    storage.saved_tick = game.tick
    game.server_save("bitermotors-accounting-reload")
    report("accounting_passed", {history = history, assertions = assertions,
      manufactured = manufactured, sold = progress.roadsters_sold, profit = progress.dollars_produced})
  end
end

local loaded = false
script.on_load(function() loaded = storage.stage == "reload" end)
script.on_nth_tick(30, function()
  if loaded and storage.stage == "reload" then
    local progress = snapshot()
    equal(progress.premium_evs_produced, 259, "production survives native save/reload")
    equal(progress.roadsters_sold, 50, "sales survive native save/reload")
    equal(progress.dollars_produced, 113, "profit survives native save/reload")
    report("reload_passed", {saved_tick = storage.saved_tick, assertions = assertions})
    storage.stage = "done"
    return
  end
  if storage.stage == "reload" or storage.stage == "done" then return end
  assert(game.tick - storage.started < 11000, "accounting fixture did not finish: "
    .. storage.stage .. " " .. helpers.table_to_json{
      progress = snapshot(), offices = remote.call("bitermotors", "sales_office_status", "player")
    })
  native_stage()
end)
