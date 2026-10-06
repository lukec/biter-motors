import copy
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod" / "bitermotors_0.1.1"


class CustomerPopulationTest(unittest.TestCase):
    def test_runtime_purchase_capacity_is_not_settlement_wide_history(self):
        control = (MOD / "control.lua").read_text()
        start = control.index("function customer_virtual_purchase_capacity(")
        end = control.index("function customer_population_available_purchase_accounts(", start)
        self.assertIn("CustomerPopulation.capacity(population, vehicle)", control[start:end])
        self.assertNotIn("customer_population_purchase_count", control[start:end])

    def test_virtual_history_policy_is_pure_and_population_bounded(self):
        policy = (MOD / "runtime" / "customer_population.lua").read_text()
        for dependency in ("game.", "rendering.", "find_entities", "unit_number"):
            self.assertNotIn(dependency, policy)
        self.assertIn("HISTORY_COUNT = 2 ^ #VEHICLES", policy)
        self.assertIn("virtual_reserved_by_cohort", policy)
        self.assertIn("physical_purchases_by_vehicle", policy)
        self.assertIn("virtual_purchases_by_vehicle", policy)
        self.assertIn("ticket.completed = true", policy)
        self.assertIn("ticket.released = true", policy)

    def test_caller_carries_virtual_ticket_through_sale_and_cancellation(self):
        control = (MOD / "control.lua").read_text()
        selection = control[control.index("function eligible_customer_buyers("):
                            control.index("function sales_office_buyer_status(")]
        completion = control[control.index("function complete_reserved_vehicle_sale("):
                             control.index("function process_sales_office_completions(")]
        self.assertIn("CustomerPopulation.reserve", selection)
        self.assertIn("ticket.settlement_key = pool.key", selection)
        self.assertIn("sale.item,\n        buyer", completion)
        self.assertIn("office.disabled_by_script = true", completion)
        self.assertIn("CustomerPopulation.release(population, buyer)", control)

    def test_paperwork_capacity_does_not_deadlock_waiting_for_inputs(self):
        control = (MOD / "control.lua").read_text()
        start = control.index("function sales_office_reservation_capacity_per_minute(")
        end = control.index("function reservation_print_plan(", start)
        capacity = control[start:end]
        self.assertNotIn("not office.disabled_by_script", capacity)
        self.assertIn("not office.disabled_by_control_behavior", capacity)
        self.assertNotIn("office.energy", capacity)
        self.assertIn("not office.to_be_deconstructed(force)", capacity)
        sync = control[control.index("function sync_sales_office_buyer("):
                       control.index("function sync_sales_office_buyers(")]
        self.assertIn("valid_reservation = false", sync)
        self.assertNotIn("valid_reservation = nil", sync)

    def test_native_fixture_uses_actual_population_and_real_save(self):
        fixture = (ROOT / "scripts" / "fixtures" / "customer-control.lua").read_text()
        self.assertIn("Population.purchase", fixture)
        self.assertIn("Population.add_unowned(large, 1000000)", fixture)
        self.assertIn("entity.die()", fixture)
        self.assertIn("storage.spawner.die()", fixture)
        self.assertIn('game.server_save("bitermotors-customers-reload")', fixture)
        self.assertIn("script.on_configuration_changed", fixture)
        self.assertNotIn(".set_input_count", fixture)
        self.assertNotIn(".set_output_count", fixture)
        self.assertNotIn("performance_test_seed_owner", fixture)

    def test_customer_runner_rejects_bad_qualification_reports(self):
        runner = (ROOT / "scripts" / "validate-bitermotors-customers.sh").read_text()
        gate = runner.split("<<'EOF_CHECK'\n", 1)[1].split("\nEOF_CHECK", 1)[0]
        gate = gate[gate.index("expected = "):]
        compiled = compile(gate, "customer-report-gate", "exec")
        rows = [
            {"status": "lua_fixtures_passed", "assertions": 63, "tick": 0},
            {"status": "customers_passed", "assertions": 134, "tick": 100},
            {"status": "reload_passed", "assertions": 9, "tick": 101, "saved_tick": 100},
            {"status": "configuration_passed", "assertions": 12, "tick": 101, "saved_tick": 100},
        ]
        exec(compiled, {"rows": rows, "json": json, "print": lambda *args: None})
        broken = [rows[:-1], rows + [rows[-1]], [rows[1], rows[0], *rows[2:]]]
        for index in range(len(rows)):
            candidate = copy.deepcopy(rows)
            candidate[index]["assertions"] -= 1
            broken.append(candidate)
        for field, value in (("assertions", 0), ("tick", 100), ("saved_tick", 102)):
            candidate = copy.deepcopy(rows)
            candidate[-1][field] = value
            broken.append(candidate)
        for candidate in broken:
            with self.subTest(report=candidate):
                with self.assertRaises(AssertionError):
                    exec(compiled, {"rows": candidate, "json": json, "print": lambda *args: None})


if __name__ == "__main__":
    unittest.main()
