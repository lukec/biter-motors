local Allocator = require("__bitermotors__/runtime/charger_allocator")
local Service = require("__bitermotors__/runtime/settlement_service")
local REPORT = "bitermotors-charging.jsonl"
local ROADSTER = "bitermotors-prototype-roadster"
local PREMIUM = "bitermotors-premium-ev"
local assertions = 0

local function check(condition, label)
  if not condition and storage.stage then
    local power = {}
    for _, entity in pairs(game.surfaces.nauvis.find_entities_filtered{name = "electric-energy-interface"}) do
      power[#power + 1] = {position = entity.position, energy = entity.energy,
        status = entity.status, connected = entity.is_connected_to_electric_network()}
    end
    helpers.write_file("bitermotors-charging-failure.json", helpers.table_to_json{
      label = label, tick = game.tick, stage = storage.stage, power = power,
      service = remote.call("bitermotors", "customer_service_status", "player")
    })
  end
  assert(condition, label)
  assertions = assertions + 1
end

local function equal(actual, expected, label)
  check(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function report(status, extra)
  local row = extra or {}
  row.status, row.tick, row.assertions = status, game.tick, assertions
  helpers.write_file(REPORT, helpers.table_to_json(row) .. "\n", true)
end

local function spec(key, capacity, candidates)
  local result = {key = key, station = key, stalls = 4, evs_per_stall = 12,
    ev_capacity = capacity, candidates = {}}
  for index, name in ipairs(candidates) do
    result.candidates[index] = {key = name, settlement = name, distance = index}
  end
  return result
end

local function allocation_check(specs, demand, expected, prospects)
  local allocation = Allocator.allocate(specs, demand, {admit_prospects = prospects == true})
  local total, requested = 0, 0
  for _, station in ipairs(specs) do
    local row = allocation.assignments[station.key]
    check(row.remaining_capacity >= 0, "capacity is not overdrawn")
    check(row.total_requested_evs <= row.total_capacity, "station load stays bounded")
    check(row.requested_stalls <= station.stalls, "stall count stays bounded")
    local used = 0
    for _, count in pairs(row.load_by_settlement_key) do used = used + count end
    equal(used, row.total_requested_evs, "per-home loads reconcile station totals")
    total = total + row.total_requested_evs
  end
  for key, amount in pairs(allocation.requested_capacity_by_settlement_key) do
    check(amount <= (demand[key] or 0), "settlement allocation does not exceed owned EVs")
    requested = requested + amount
  end
  equal(requested, total, "pooled and station capacities reconcile")
  for key, amount in pairs(expected) do
    equal(allocation.requested_capacity_by_settlement_key[key] or 0, amount, "expected fair allocation for " .. key)
  end
  return allocation
end

local function policy_fixtures()
  allocation_check({spec(1, 48, {"a", "b"})}, {a = 48, b = 48}, {a = 24, b = 24})
  allocation_check({spec(1, 48, {"b", "a"})}, {b = 48, a = 48}, {a = 24, b = 24})
  allocation_check({spec(1, 48, {"a", "b"})}, {a = 48, b = 96}, {a = 12, b = 36})
  allocation_check({spec(1, 24, {"a", "b"})}, {a = 48, b = 48}, {a = 12, b = 12})
  allocation_check({spec(1, 0, {"a", "b"})}, {a = 48, b = 48}, {a = 0, b = 0})
  allocation_check({spec(1, 48, {"a", "b"}), spec(2, 48, {"a", "b"})},
    {a = 48, b = 48}, {a = 48, b = 48})
  allocation_check({spec(2, 48, {"b", "a"}), spec(1, 48, {"b", "a"})},
    {a = 48, b = 48}, {a = 48, b = 48})
  local bulk = allocation_check({spec(1, 48, {"a", "p"})}, {a = 1000000}, {a = 48})
  equal(#bulk.assignments[1].load_chunks, 1, "genuinely uncontested demand retains bulk optimization")
  local admission = allocation_check({spec(1, 48, {"a", "p"})}, {a = 24}, {a = 24}, true)
  equal(admission.assigned_capacity_by_settlement_key.p, 1, "empty prospects get admission without occupied stalls")
  equal(admission.assignments[1].requested_stalls, 2, "only owned cars occupy stalls")
  local large = {}
  local demand = {}
  for index = 1, 128 do
    local key = "home-" .. index
    large[#large + 1], demand[key] = key, 1000000
  end
  local bounded = allocation_check({spec(1, 48, large)}, demand, {})
  equal(bounded.assignments[1].total_requested_evs, 48, "large aggregate demand cannot invent capacity")
  equal(#bounded.assignments[1].load_chunks, 4, "contested heap work is bounded by available stalls")
  for _, case in ipairs({
    {0, 1, 0, false, true, 0, 0, 0, "private"},
    {0, 0, 0, false, false, 0, 0, 0, "deficient"},
    {48, 48, 48, false, true, 0, 0, 0, "private"},
    {48, 24, 12, false, false, 36, 24, 12, "deficient"},
    {48, 48, 0, false, false, 48, 0, 48, "deficient"},
    {48, 0, 0, true, true, 0, 0, 0, "bitertaxi"},
    {48, 24, 12, true, true, 0, 0, 0, "bitertaxi"},
    {48, 24, 48, false, false, 24, 24, 0, "deficient"}
  }) do
    local health = Service.evaluate(case[1], case[2], case[3], case[4])
    equal(health.operational, case[5], "one service-health rule")
    equal(health.missing, case[6], "service deficit")
    equal(health.capacity_missing, case[7], "physical capacity deficit")
    equal(health.power_missing, case[8], "grid deficit")
    equal(health.route, case[9], "alternative service route")
  end
  report("policy_passed", {allocator_cases = 10, service_cases = 8})
  assertions = 0
end

local function call(name, ...)
  return remote.call("bitermotors", name, ...)
end

local function make(name, position, force)
  return assert(game.surfaces.nauvis.create_entity{
    name = name, position = position, force = force or game.forces.player, raise_built = true
  }, "could not create " .. name)
end

local function scene(x, watts)
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({x, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{x - 280, -280}, {x + 280, 280}}}) do entity.destroy() end
  local tiles = {}
  for dx = -80, 80 do for y = -80, 80 do tiles[#tiles + 1] = {name = "landfill", position = {x + dx, y}} end end
  surface.set_tiles(tiles)
  make("substation", {x, -4})
  local power = make("electric-energy-interface", {x, -8})
  power.electric_interface_mode = defines.electric_interface_mode.primary_output
  power.power_production, power.output_flow_limit = watts / 60, watts / 60
  return power
end

local function home(x, owned, prospects)
  local spawner = make("biter-spawner", {x, 32}, game.forces.enemy)
  script.raise_event(defines.events.on_biter_base_built, {entity = spawner})
  local key = assert(call("test_charging_seed_population", spawner, owned, prospects))
  return {entity = spawner, key = key}
end

local function state()
  return call("customer_service_status", "player")
end

local function row(home, snapshot)
  for _, candidate in ipairs((snapshot or state()).settlements) do
    if candidate.key == home.key then return candidate end
  end
  error("missing home " .. home.key)
end

local function stage(name)
  storage.completed_native_cases = storage.completed_native_cases or {}
  if storage.stage and storage.stage ~= "reload" then
    storage.completed_native_cases[#storage.completed_native_cases + 1] = storage.stage
  end
  storage.stage, storage.stage_tick = name, game.tick
end

local function watts(power, value)
  power.power_production, power.output_flow_limit = value / 60, value / 60
  power.energy = 0
end

local function taxi_healthy(snapshot)
  local taxi = row(storage.taxi, snapshot)
  equal(taxi.operational, true, "taxi-only home stays operational")
  equal(taxi.route, "bitertaxi", "taxi service does not need an office")
  equal(taxi.missing, 0, "adequate taxi fleet suppresses private charging deficit")
  equal(taxi.friendly, true, "taxi-only home remains friendly")
  equal(taxi.deficit_since, nil, "taxi-only cache cycles never start a false grace timer")
end

script.on_init(function()
  policy_fixtures()
  game.tick_paused, game.speed = false, 100
  game.surfaces.nauvis.peaceful_mode = true
  game.map_settings.enemy_expansion.enabled = false
  for _, name in ipairs({"bitermotors-sales-office", "bitermotors-premium-ev-program", "bitermotors-ev-charging-network"}) do
    game.forces.player.technologies[name].researched = true
  end
  storage.power = scene(0, 100000000)
  storage.office = make("bitermotors-sales-office", {0, -16})
  storage.charger = make("bitermotors-ev-charging-station", {-6, 0})
  storage.extra = make("bitermotors-ev-charging-station", {6, 0})
  storage.a, storage.b = home(-16, 48, 4), home(16, 48, 4)
  scene(600, 100000000)
  storage.depot = make("bitermotors-bitertaxi-depot", {600, 4})
  equal(storage.depot.get_inventory(defines.inventory.chest).insert{name = "bitermotors-bitertaxi-fleet", count = 20},
    20, "taxi fleet supplied as setup")
  storage.taxi = home(600, 48, 4)
  storage.neighbor_power = scene(1200, 660000)
  make("bitermotors-sales-office", {1200, -16})
  storage.neighbor_charger = make("bitermotors-ev-charging-station-v2", {1200, 4})
  storage.healthy, storage.deficient = home(1184, 12, 4), home(1216, 120, 4)
  scene(1800, 100000000)
  make("bitermotors-ev-charging-station", {1800, 4})
  storage.pool_a, storage.pool_b = home(1784, 0, 6), home(1816, 12, 6)
  storage.pool_offices = {}
  for index = 1, 3 do
    storage.pool_offices[index] = make("bitermotors-sales-office", {1788 + (index - 1) * 12, -16})
  end
  call("refresh_biter_customer_market", "player")
  storage.started, storage.cache_cycles = game.tick, 0
  stage("full")
end)

local loaded = false
script.on_load(function() loaded = storage.stage == "reload" end)

local function reserved_home(office)
  for _, transaction in ipairs(state().transactions) do
    if transaction.office == office.unit_number then
      equal(transaction.virtual, true, "native office holds a real virtual customer ticket")
      return transaction.key
    end
  end
  error("office has not reserved its supplied prospect")
end

local function prepare_pending_sale(office, model)
  office.set_recipe(model == ROADSTER and "bitermotors-sell-prototype-roadster" or "bitermotors-sell-premium-ev")
  local inventory = office.get_inventory(defines.inventory.crafter_input)
  equal(inventory.insert{name = model, count = 1}, 1, "real vehicle supplied to office")
  equal(inventory.insert{name = "bitermotors-ev-reservation", count = 1}, 1, "real paperwork supplied to office")
  local behavior = office.get_or_create_control_behavior()
  behavior.circuit_enable_disable = true
  behavior.circuit_condition = {condition = {comparator = "<", first_signal = {type = "virtual", name = "signal-A"}, constant = -1}}
  call("sync_sales_offices")
end

local function persistence()
  local snapshot = state()
  taxi_healthy(snapshot)
  equal(row(storage.a, snapshot).missing, 0, "restored private service persists")
  equal(row(storage.a, snapshot).deficit_since, nil, "restored mood persists")
  equal(row(storage.pool_a, snapshot).pending, 1, "canceled sale stays released after reload")
  equal(row(storage.pool_b, snapshot).pending, 1, "other-model reservation survives reload")
  equal(reserved_home(storage.pool_offices[2]), storage.pool_a.key, "same-model reservation keeps its home")
  equal(reserved_home(storage.pool_offices[3]), storage.pool_b.key, "other-model reservation keeps its home")
  equal(storage.pool_offices[2].products_finished, 0, "paused reservation was not injected as a completed sale")
end

script.on_nth_tick(30, function()
  if loaded and storage.stage == "reload" then
    assertions = 0
    persistence()
    report("reload_passed", {saved_tick = storage.saved_tick, cache_cycles = storage.cache_cycles})
    stage("done")
    return
  end
  if storage.stage == "done" or storage.stage == "reload" or game.tick == 0 then return end
  assert(game.tick - storage.started < 90000, "charging fixture timed out in " .. storage.stage)
  if game.tick - storage.stage_tick < 120 then return end
  local snapshot = state()
  if storage.stage == "full" then
    equal(row(storage.a, snapshot).powered, 48, "two native chargers fully cover first home")
    equal(row(storage.b, snapshot).powered, 48, "two native chargers fully cover second home")
    taxi_healthy(snapshot)
    equal(row(storage.healthy, snapshot).operational, true, "partial-power pool has a healthy neighbor")
    equal(row(storage.deficient, snapshot).operational, false, "same pool has an allocation-deficient neighbor")
    check(row(storage.deficient, snapshot).missing > 0, "deficient neighbor is reported locally")
    local before_healthy = row(storage.healthy, snapshot).virtual_unowned
    local before_deficient = row(storage.deficient, snapshot).virtual_unowned
    local before_taxi = row(storage.taxi, snapshot).virtual_unowned
    check(call("test_charging_growth_due", "player"), "prepare due growth timers only")
    snapshot = state()
    equal(row(storage.healthy, snapshot).virtual_unowned, before_healthy + 1, "only healthy neighbor grows")
    equal(row(storage.deficient, snapshot).virtual_unowned, before_deficient, "deficient neighbor growth is suspended")
    equal(row(storage.taxi, snapshot).virtual_unowned, before_taxi + 1, "taxi-only healthy home grows too")
    for _, station in ipairs(snapshot.stations) do
      if station.unit_number == storage.neighbor_charger.unit_number then
        equal(station.healthy, 1, "only healthy owned demand contributes expansion utilization")
      end
    end
    local chest = make("steel-chest", {20, -16})
    check(storage.extra.mine{inventory = chest.get_inventory(defines.inventory.chest)}, "native charger removal")
    -- Exercise the engine mining lifecycle, not a direct registry edit.
    stage("removed")
  elseif storage.stage == "removed" then
    equal(row(storage.a, snapshot).assigned, 24, "shared native capacity splits equally after removal")
    equal(row(storage.b, snapshot).assigned, 24, "neighbor receives equal share after removal")
    watts(storage.power, 135000)
    stage("brownout")
  elseif storage.stage == "brownout" then
    equal(row(storage.a, snapshot).powered, 12, "brownout shares two powered stalls")
    equal(row(storage.b, snapshot).powered, 12, "brownout does not starve equal neighbor")
    check(row(storage.a, snapshot).power_missing > 0, "partial power has an actionable grid deficit")
    equal(row(storage.a, snapshot).angry, false, "brownout does not immediately trigger anger")
    taxi_healthy(snapshot)
    watts(storage.power, 100000000)
    storage.extra = make("bitermotors-ev-charging-station", {6, 0})
    stage("restored")
  elseif storage.stage == "restored" then
    equal(row(storage.a, snapshot).missing, 0, "added charger repairs first home immediately")
    equal(row(storage.b, snapshot).missing, 0, "added charger repairs second home immediately")
    equal(row(storage.a, snapshot).deficit_since, nil, "service restoration clears grace timer")
    equal(row(storage.b, snapshot).angry, false, "service restoration clears anger")
    local pole = make("medium-electric-pole", {610, -4})
    pole.destroy{raise_destroy = true}
    stage("pools")
  elseif storage.stage == "pools" then
    taxi_healthy(snapshot)
    for _, entity in pairs(game.surfaces.nauvis.find_entities_filtered{
      type = "unit", area = {{1720, -80}, {1880, 80}}
    }) do entity.die() end
    call("refresh_biter_customer_market", "player")
    prepare_pending_sale(storage.pool_offices[1], ROADSTER)
    equal(reserved_home(storage.pool_offices[1]), storage.pool_a.key, "first office picks empty home")
    prepare_pending_sale(storage.pool_offices[2], ROADSTER)
    equal(reserved_home(storage.pool_offices[2]), storage.pool_a.key, "pending virtual buyer counts once, not twice")
    prepare_pending_sale(storage.pool_offices[3], PREMIUM)
    equal(reserved_home(storage.pool_offices[3]), storage.pool_b.key, "different models share one pending load")
    equal(row(storage.pool_a).pending, 2, "two distinct prospects reserved at first home")
    equal(row(storage.pool_b).pending, 1, "other-model prospect reserved at second home")
    storage.pool_offices[1].set_recipe(nil)
    call("sync_sales_offices")
    equal(row(storage.pool_a).pending, 1, "cancel releases one pending buyer")
    watts(storage.power, 0)
    stage("outage")
  elseif storage.stage == "outage" then
    local a = row(storage.a, snapshot)
    equal(a.powered, 0, "native outage removes powered private capacity")
    if game.tick - a.deficit_since < 10800 then
      equal(a.angry, false, "full outage respects three-minute grace")
    end
    if game.tick % 3600 == 0 then
      taxi_healthy(snapshot)
      storage.cache_cycles = storage.cache_cycles + 1
      local pole = make("medium-electric-pole", {610, -4})
      pole.destroy{raise_destroy = true}
    end
    if a.angry or row(storage.b, snapshot).angry then
      check(game.tick - a.deficit_since >= 10800, "hostility occurs only after the native grace period")
      check(storage.cache_cycles >= 3, "taxi-only coverage survives multiple market cache cycles")
      watts(storage.power, 100000000)
      stage("recover")
    end
  elseif storage.stage == "recover" then
    equal(row(storage.a, snapshot).operational, true, "power restoration repairs service")
    equal(row(storage.b, snapshot).operational, true, "neighbor also repairs service")
    equal(row(storage.a, snapshot).angry, false, "restored service has short memory")
    equal(row(storage.b, snapshot).angry, false, "both moods recover")
    persistence()
    equal(call("progress_status", "player").snapshot.consumer_evs_sold, 0, "seeded demand and paused tickets do not fake sale gates")
    storage.saved_tick = game.tick
    stage("reload")
    game.server_save("bitermotors-charging-reload")
    report("service_passed", {cache_cycles = storage.cache_cycles, allocator_cases = 10,
      native_scenes = #game.surfaces.nauvis.find_entities_filtered{name = "electric-energy-interface"},
      pending_transactions = #snapshot.transactions, native_cases = storage.completed_native_cases,
      saved_tick = storage.saved_tick})
  end
end)
