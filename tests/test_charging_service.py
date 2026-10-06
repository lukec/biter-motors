"""Runtime contracts and negative qualification gates; native Lua runs in Factorio."""

import copy
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"


class ChargingServiceTest(unittest.TestCase):
    def test_bulk_allocation_checks_both_reachability_and_competing_demand(self):
        allocator = (MOD / "runtime/charger_allocator.lua").read_text()
        self.assertIn("#candidate_pairs == 1 and pair.assignment.demanding_settlements == 1", allocator)
        self.assertIn("assignment.demanding_settlements = assignment.demanding_settlements + 1", allocator)
        self.assertIn("or pair.assignment.spec.evs_per_stall", allocator)
        self.assertIn("heap_push(demand_heap, key, demand_less)", allocator)

    def test_health_policy_is_pure_and_taxi_is_an_alternative_service(self):
        policy = (MOD / "runtime/settlement_service.lua").read_text()
        for dependency in ("game.", "storage.", "rendering.", "find_entities", "unit_number"):
            self.assertNotIn(dependency, policy)
        self.assertIn('taxi_served == true and "bitertaxi"', policy)
        self.assertIn("local operational = taxi_served == true or private_service", policy)
        self.assertIn("math.min(assigned_capacity, powered_capacity or 0)", policy)

    def test_rebuild_refresh_and_mood_share_one_health_function(self):
        control = (MOD / "control.lua").read_text()
        health = control[control.index("function refresh_customer_settlement_health"):
                         control.index("customer_service_for_force = function")]
        self.assertIn("SettlementService.evaluate", health)
        self.assertIn("service.bitertaxi_service = bitertaxi_service_for_force(force)", health)
        self.assertIn("health.operational, advance_mood == true", health)
        self.assertIn("service.stranded_evs = service.stranded_evs + health.missing", health)
        refresh = control[control.index("function refresh_customer_service_power_capacity"):
                          control.index("local function next_customer_charging_step")]
        self.assertIn("refresh_customer_settlement_health(force, service, advance_mood)", refresh)
        self.assertNotIn("vehicle_count >", refresh)
        cache = control[control.index("customer_service_for_force = function"):
                        control.index("function refresh_customer_service_power_capacity")]
        self.assertIn("refresh_customer_service_power_capacity(force, cached.service, true)", cache)
        self.assertIn("refresh_customer_settlement_health(force, service, advance_mood)", cache)

    def test_growth_and_alerts_consume_settlement_health_not_charger_status(self):
        control = (MOD / "control.lua").read_text()
        growth = control[control.index("local function process_customer_growth"):
                         control.index("local function customer_growth_summary")]
        self.assertIn("customer_assignment_healthy_stalls(service, assignment)", growth)
        self.assertIn("for _, settlement in pairs(service.candidate_settlements or {})", growth)
        self.assertIn("if service.operational_keys[key]", growth)
        self.assertNotIn("local_service_healthy", growth)
        alerts = control[control.index("function update_customer_settlement_alerts"):
                         control.index("function ensure_seed_customer")]
        self.assertIn("local health = service.health_by_settlement_key[key]", alerts)
        self.assertIn("missing = health.missing", alerts)
        self.assertNotIn("active_customer_vehicle_summary", alerts)

    def test_inspectors_use_the_same_effective_service_deficit(self):
        control = (MOD / "control.lua").read_text()
        station = control[control.index("local function show_station_info_panel"):
                          control.index("local function biter_customer_market_summary")]
        office = control[control.index("function sales_office_buyer_status"):
                         control.index("function classify_sales_office_market")]
        self.assertIn("underserved_here + (health and health.missing or 0)", station)
        self.assertIn("underserved = underserved + (health and health.missing or 0)", office)
        self.assertIn("local local_underserved = health.missing", control)

    def test_pool_load_counts_pending_buyers_once_across_all_models(self):
        control = (MOD / "control.lua").read_text()
        selection = control[control.index("function eligible_customer_buyers"):
                            control.index("function sales_office_buyer_status")]
        self.assertIn("reserved_customer_buyers_by_settlement(office.force)", selection)
        self.assertIn("+ (reserved_by_settlement[key] or 0)", selection)
        self.assertNotIn("population.virtual_reserved", selection)
        self.assertNotIn("office.force,\n    sale.item", selection)

    def test_native_fixture_uses_actual_power_and_real_save(self):
        fixture = (ROOT / "scripts/fixtures/charging-control.lua").read_text()
        self.assertIn("watts / 60, watts / 60", fixture)
        self.assertIn("value / 60, value / 60", fixture)
        self.assertIn("power.energy = 0", fixture)
        self.assertIn("storage.extra.mine", fixture)
        self.assertIn("get_or_create_control_behavior", fixture)
        self.assertIn('game.server_save("bitermotors-charging-reload")', fixture)
        self.assertIn("three-minute grace", fixture)
        self.assertIn("storage.completed_native_cases", fixture)
        self.assertNotIn(".set_input_count", fixture)
        self.assertNotIn(".set_output_count", fixture)
        self.assertNotIn("energy_required", fixture)

    def test_broad_outage_fixture_disables_both_alternative_service_routes(self):
        runner = (ROOT / "scripts/validate-bitermotors-mod.sh").read_text()
        outage = runner[runner.index("script.on_nth_tick(18200"):
                        runner.index("script.on_nth_tick(18500")]
        self.assertEqual(outage.count("storage.bitertaxi_power_source_unit_number"), 2)
        self.assertIn("power_source.energy = 0", outage)
        self.assertIn('"customer_service_status"', outage)

    def test_fixture_mutation_helpers_are_guarded_and_update_both_ownership_records(self):
        control = (MOD / "control.lua").read_text()
        seed = control[control.index("test_charging_seed_population = function"):
                       control.index("sync_sales_offices = function", control.index("test_charging_seed_population"))]
        self.assertEqual(seed.count('if not script.active_mods["bitermotors_charging"] then return false end'), 2)
        self.assertIn("CustomerPopulation.purchase", seed)
        self.assertIn("CustomerAggregates.add_virtual", seed)
        self.assertIn("process_customer_growth(force)", seed)
        self.assertNotIn("statistics.on_flow", seed)

    def test_runner_rejects_incomplete_or_stale_qualification_reports(self):
        runner = (ROOT / "scripts/validate-bitermotors-charging.sh").read_text()
        gate = runner.split("<<'EOF_CHECK'\n", 1)[1].split("\nEOF_CHECK", 1)[0]
        gate = gate[gate.index("expected = "):]
        compiled = compile(gate, "charging-report-gate", "exec")
        rows = [
            {"status": "policy_passed", "assertions": 137, "tick": 0,
             "allocator_cases": 10, "service_cases": 8},
            {"status": "service_passed", "assertions": 100, "tick": 20000,
             "saved_tick": 20000, "allocator_cases": 10, "native_scenes": 4,
             "pending_transactions": 2, "cache_cycles": 3,
             "native_cases": ["full", "removed", "brownout", "restored", "pools", "outage", "recover"]},
            {"status": "reload_passed", "assertions": 14, "tick": 20030,
             "saved_tick": 20000, "cache_cycles": 3},
        ]
        run = lambda candidate: exec(compiled, {"rows": candidate, "json": json,
                                               "print": lambda *args: None})
        run(rows)
        broken = [rows[:-1], rows + [rows[-1]], [rows[1], rows[0], rows[2]]]
        for index in range(len(rows)):
            candidate = copy.deepcopy(rows)
            candidate[index]["assertions"] -= 1
            broken.append(candidate)
        for index, field, value in (
            (0, "allocator_cases", 9), (0, "service_cases", 7),
            (1, "native_cases", rows[1]["native_cases"][:-1]),
            (1, "allocator_cases", 9), (1, "native_scenes", 3),
            (1, "pending_transactions", 1), (1, "cache_cycles", 2),
            (1, "tick", 0), (1, "saved_tick", 19999),
            (2, "tick", 20000), (2, "saved_tick", 19999), (2, "cache_cycles", 4),
        ):
            candidate = copy.deepcopy(rows)
            candidate[index][field] = value
            broken.append(candidate)
        for candidate in broken:
            with self.subTest(report=candidate):
                with self.assertRaises(AssertionError):
                    run(candidate)


if __name__ == "__main__":
    unittest.main()
