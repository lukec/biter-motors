import copy
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("practical_checker", ROOT / "scripts/check_practical_ending.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)
P = CHECK.P


def valid_evidence():
    config = CHECK.configuration()
    config["source_sha256"] = "a" * 64
    manifest = {P + "orbital-datacenter-core": 12, P + "orbital-radiator-panel": 12,
                P + "orbital-heat-pipe": 24, P + "high-density-space-solar-panel": 60,
                "space-platform-foundation": 100, "express-transport-belt": 100, "bulk-inserter": 26}
    stock = dict(manifest, **{CHECK.RACK: 1, "space-platform-starter-pack": 1, CHECK.DOLLAR: 8363})
    catalog = {name: {"weight": 1000, "stack_size": 1000} for name in stock | {CHECK.DATASET: 1, CHECK.MODEL: 1}}
    research_catalog = {tier["technology"]: {"cycles": 1, "seconds": 60, "ingredients": {CHECK.DOLLAR: 1}}
                        for tier in config["tiers"] if "technology" in tier}
    shipments = []
    for i, (name, n) in enumerate(stock.items()):
        # Dollar cargo is not required to be the entire finite opening balance.
        amount = min(n, 100)
        shipments.append({"tick": 150, "descended_tick": 160, "delivered_tick": 170,
                          "cargo": {name: amount}, "pod": i + 1, "mass": 1000 * amount,
                          "slots": 1, "capacity": 10, "origin": "ground-rocket", "destination": "orbital-hub"})
    shipped = {name: min(n, 100) for name, n in stock.items()}
    returns = [{"tick": 350, "descended_tick": 360, "delivered_tick": 370, "cargo": {CHECK.DATASET: 1},
                "pod": 100, "mass": 1000, "slots": 1, "capacity": 10, "origin": "orbital-hub", "destination": "ground-pad"},
               {"tick": 1150, "descended_tick": 1160, "delivered_tick": 1170, "cargo": {CHECK.MODEL: 1},
                "pod": 101, "mass": 1000, "slots": 1, "capacity": 10, "origin": "orbital-hub", "destination": "ground-pad"}]
    research = [{"name": t["technology"], "started_tick": 400 + 200 * i, "tick": 520 + 200 * i, "by_script": False}
                for i, t in enumerate(config["tiers"][1:])]
    ramp = [{"cores": n, "tick": t, "earned": e, "tier": i + 1}
            for i, (n, t, e) in enumerate(zip((1, 4, 8, 12), (300, 530, 730, 930), (0, 1_000_000, 10_000_000, 100_000_000)))]
    rows = []
    for i, status in enumerate(CHECK.STATUSES):
        tick = [0, 200, 300, 1000, 1100, 1130, 1140, 1200, 1300, 1330, 3730][i]
        produced = 0 if i < 3 else 20_001
        row = dict(status=status, tick=tick, config=config, source_sha256="a" * 64, cores=12,
                   scope="native-practical-ending", limits="finite supplied ground stock; not a campaign",
                   bulk_inserter_capacity_bonus=9,
                   paused=False, game_finished=False, produced=produced, earned=produced * 50_000,
                   datasets_returned=int(i >= 3), unpacked=int(i >= 3), compute_dollars=6000 if produced else 0,
                   compute_dollars_native=6001 if produced else 0, recipe_change_discarded_dollars=1 if produced else 0,
                   research_dollars_consumed=3,
                   rockets=0 if i == 0 else len(shipments), initial_stock=stock,
                   rocket_parts=0 if i == 0 else len(shipments)*50, parts_per_rocket=50,
                   rocket_consumed={k: 0 if i == 0 else len(shipments)*50 for k in
                                    ("processing-unit", "low-density-structure", "rocket-fuel")},
                   shipped={} if i == 0 else shipped, delivered={} if i == 0 else shipped,
                   ground_stock_remaining={}, timings={"loading": 140, "assembly": 40, "activation": 100},
                   native_assemblies=int(i >= 7), native_activations=int(i >= 8),
                   models_assembled=int(i >= 7), models_returned=int(i >= 7), models_activated=int(i >= 8),
                   completed=i >= 8, victory={"tick": 1290} if i >= 8 else None,
                   low_power_samples=0, full_output_samples=0, burnouts=0, max_temperature=70,
                   orbital_eei=0, solar_multiplier=1, ghosts=0, input_datasets=0,
                   assembly_progress=0, terminal_unit=10, assembler_unit=20,
                   retained_datasets=20_000, hub={CHECK.DATASET: 20_000, CHECK.RACK: 1},
                   orbital_datasets=20_000 if i < 6 and i >= 3 else 0,
                   activation_output=int(i >= 8), freeplay_ticks=2400 if i == 10 else 0,
                   built={k: v for k, v in manifest.items() if k != "space-platform-foundation"},
                   manifest=manifest, shipments=shipments, returns=returns,
                   starter_prototype_items={"space-platform-foundation": 10}, starter_prototype_tiles=100,
                   starter_hub_items={"space-platform-foundation": 10}, starter_surface_tiles=100,
                   foundation_required_tiles=100, foundation_surface_tiles=200,
                   research=research, research_catalog=research_catalog, ramp_history=ramp, item_catalog=catalog)
        if i == 0:
            row["native_assemblies"] = row["native_activations"] = 0
        if i in (4, 5):
            row["input_datasets"] = 1000
        if i == 5:
            row["saved_tick"] = 1100
        if i == 6:
            row.update(committed_datasets=20_000, assembly_progress=0.1)
        if i >= 9:
            row["saved_tick"] = 1300
        rows.append(copy.deepcopy(row))
    rows[-1]["hub"]["space-platform-foundation"] = 10
    return rows


class PracticalEndingCheckerTests(unittest.TestCase):
    def setUp(self):
        self.rows = valid_evidence()

    def reject(self, mutate):
        mutate(self.rows)
        with self.assertRaises((ValueError, TypeError, KeyError)):
            CHECK.validate_rows(self.rows)

    def test_complete_native_contract(self):
        self.assertEqual(len(CHECK.validate_rows(self.rows)), 11)

    def test_adversarial_numbers(self):
        for key in ("earned", "produced", "rockets", "native_assemblies", "burnouts", "compute_dollars"):
            for value in (True, -1, 1.5, "1", None):
                with self.subTest(key=key, value=value):
                    rows = copy.deepcopy(self.rows)
                    rows[-1][key] = value
                    with self.assertRaises(ValueError):
                        CHECK.validate_rows(rows)

    def test_missing_and_duplicate_milestones(self):
        for rows in (self.rows[:-1], self.rows + [self.rows[-1]], list(reversed(self.rows))):
            with self.assertRaises(ValueError):
                CHECK.validate_rows(rows)

    def test_paused_benchmark_cannot_count_as_freeplay(self):
        self.reject(lambda r: r[-1].update(paused=True))

    def test_finished_benchmark_cannot_count_as_freeplay(self):
        self.reject(lambda r: r[-1].update(game_finished=True))

    def test_requested_benchmark_updates_do_not_prove_elapsed_ticks(self):
        self.reject(lambda r: r[-1].update(tick=r[-2]["tick"] + 1))

    def test_reload_is_not_just_a_second_probe(self):
        self.reject(lambda r: r[5].update(saved_tick=10))

    def test_mid_loading_must_be_partial_and_preserved(self):
        for n in (0, 20_000, True):
            rows = copy.deepcopy(self.rows)
            rows[4]["input_datasets"] = n
            with self.assertRaises(ValueError):
                CHECK.validate_rows(rows)
        self.reject(lambda r: r[5].update(input_datasets=2000))

    def test_twenty_thousand_retained_not_just_lifetime_production(self):
        self.reject(lambda r: r[3]["hub"].update({CHECK.DATASET: 19_999}))

    def test_earned_compute_not_packaging_or_item_statistics(self):
        self.reject(lambda r: r[3].update(earned=1_000_000_000))

    def test_physical_dataset_consumption(self):
        self.reject(lambda r: r[-1].update(orbital_datasets=20_000))

    def test_boolean_physical_counts_do_not_pass_as_one(self):
        self.reject(lambda r: r[-1].update(activation_output=True))
        self.rows = valid_evidence()
        self.reject(lambda r: r[3]["hub"].update({CHECK.RACK: True}))

    def test_operating_and_native_research_cash_caps(self):
        self.reject(lambda r: r[-1].update(compute_dollars_native=8001))
        self.rows = valid_evidence()
        self.reject(lambda r: r[-1].update(research_dollars_consumed=2))

    def test_forged_mass_or_counts(self):
        self.reject(lambda r: r[-1]["shipments"][0].update(mass=1))

    def test_duplicate_pod_and_wrong_destination(self):
        self.reject(lambda r: r[-1]["returns"][0].update(pod=1))
        self.rows = valid_evidence()
        self.reject(lambda r: r[-1]["returns"][0].update(destination="orbit"))

    def test_missing_hardware_rocket_or_rack(self):
        self.reject(lambda r: r[-1]["delivered"].update({CHECK.RACK: 0}))

    def test_native_starter_credit_requires_actual_fresh_observation(self):
        self.reject(lambda r: r[1].update(starter_hub_items={"space-platform-foundation": 11}))
        self.rows = valid_evidence()
        self.reject(lambda r: r[-1].update(foundation_surface_tiles=199))
        self.rows = valid_evidence()
        self.reject(lambda r: r[-1]["hub"].update({"space-platform-foundation": 9}))

    def test_scripted_or_too_fast_research(self):
        self.reject(lambda r: r[-1]["research"][0].update(by_script=True))
        self.rows = valid_evidence()
        self.reject(lambda r: r[-1]["research"][0].update(tick=401))

    def test_no_twelve_core_opening_shortcut(self):
        self.reject(lambda r: r[-1]["ramp_history"][0].update(cores=12))

    def test_ramp_cannot_precede_research(self):
        self.reject(lambda r: r[-1]["ramp_history"][1].update(tick=510))

    def test_research_catalog_and_lab_cap_are_configurable_not_old_counts(self):
        config = CHECK.configuration({"labs": 9, "lab_speed_modifier": 2.5})
        self.assertEqual(config["labs"] * (1 + config["lab_speed_modifier"]), 31.5)
        self.assertNotIn("research_count", config)
        self.assertEqual(len(CHECK.configuration({"tiers": CHECK.DEFAULTS["tiers"][:3]})["tiers"]), 3)

    def test_invalid_configuration(self):
        for config in ({"cores": True}, {"labs": 0}, {"labs": 1000}, {"ramp": [12, 12, 12, 12]},
                       {"operating_dollars": -1}, {"speed": float("nan")}, {"research_all": True}):
            with self.assertRaises(ValueError):
                CHECK.configuration(config)

    def test_report_truncation(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "report.jsonl"
            path.write_text(json.dumps(self.rows[0]))
            with self.assertRaises(ValueError):
                CHECK.read_report(path)

    def test_expected_source_binding(self):
        CHECK.validate_rows(self.rows, "a" * 64)
        with self.assertRaises(ValueError):
            CHECK.validate_rows(self.rows, "b" * 64)

    def test_rocket_materials_are_real_not_just_cargo_events(self):
        self.reject(lambda r: r[-1].update(rocket_parts=1))
        self.reject(lambda r: r[-1]["rocket_consumed"].update({"rocket-fuel": 0}))

    def test_parallel_lab_commitments_are_bounded_not_free_or_unlimited(self):
        self.rows[-1]["research_dollars_consumed"] = 5
        CHECK.validate_rows(self.rows)
        self.reject(lambda r: r[-1].update(research_dollars_consumed=0))
        self.reject(lambda r: r[-1].update(research_dollars_consumed=31))

    def test_opening_cash_is_not_an_unlimited_hidden_fixture_grant(self):
        for row in self.rows:
            row["initial_stock"][CHECK.DOLLAR] = 100000
        with self.assertRaisesRegex(ValueError, "opening cash"):
            CHECK.validate_rows(self.rows)

    def test_summary_keeps_evidence_boundaries_without_runtime_inventories(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "report.jsonl"
            path.write_text("".join(json.dumps(r) + "\n" for r in self.rows))
            summary = CHECK.evidence_summary(CHECK.validate_rows(self.rows), path)
        self.assertEqual(self.rows[-1]["rockets"], summary["rockets"])
        self.assertEqual(6002, summary["operating_dollars_used"])
        self.assertNotIn("hub", summary)
        self.assertNotIn("initial_stock", summary)
        self.assertEqual(self.rows[-1]["limits"], summary["limits"])

    def test_prepare_uses_shared_catalog_fingerprint(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, helper = root / "source", root / "helper"
            source.mkdir(); helper.mkdir()
            (source / "info.json").write_text('{"version":"0.1.1"}\n')
            (source / "control.lua").write_text("return {}\n")
            result = subprocess.run(["python3", str(ROOT / "scripts/check_practical_ending.py"),
                                     "--prepare", str(helper), "--source", str(source)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            config = json.loads((helper / "practical-config.json").read_text())
            self.assertEqual(config["source_sha256"], CHECK.source_fingerprint(source))


class PracticalEndingHarnessTests(unittest.TestCase):
    def test_no_inventory_mutation_after_initial_ground_stock(self):
        source = (ROOT / "scripts/fixtures/practical-ending-control.lua").read_text()
        self.assertEqual(source.count(".insert{"), 1)
        self.assertIn('check(storage.initializing, "all item insertion confined to initial ground setup")', source)
        for forbidden in (".remove{", ".transfer_stack", ".clear()", "crafting_progress =", "bonus_progress =",
                          "test_set_ai_token_progress", "research_all_technologies", "create_cargo_pod",
                          "force_finish_ascending", "force_finish_descending", "storage.bitermotors_"):
            self.assertNotIn(forbidden, source)
        self.assertIn('Layout.make(C.cores', source)
        self.assertIn('checkpoint("loading")', source)
        self.assertIn('checkpoint("victory")', source)
        self.assertIn('loaded = storage.stage == "checkpoint"', source)
        self.assertIn('elseif a.role == "core-output" or a.role == "hub-output" then enabled(a.entity, true)', source)
        self.assertIn('tile(math.floor(last), 8)', source)
        self.assertIn('storage.planned_tiles[key] and not storage.built_tile_positions[key]', source)
        self.assertIn('game.tick >= storage.ready_tick + 120', source)
        self.assertIn('filter(a.entity, {DOLLAR, DATASET, RACK}); enabled(a.entity, true)', source)
        self.assertIn('old.minimum_delivery_count == delivery then return end', source)
        self.assertIn('inserter_target_pickup_count', source)

    def test_runner_uses_isolation_library_and_separate_process_reloads(self):
        runner = ROOT / "scripts/validate-bitermotors-practical-ending.sh"
        source = runner.read_text()
        for marker in ('bitermotors_stage_mod "$mods"', 'bitermotors_check_log "$log" --expect-marker Goodbye',
                       '--bind 127.0.0.1 --port "$port"', 'for phase in loading victory', '--benchmark-ticks 2491',
                       'Probe only; full route and reloads NOT QUALIFIED'):
            self.assertIn(marker, source)
        self.assertNotIn("coach", source)
        self.assertEqual(subprocess.run(["bash", "-n", str(runner)], capture_output=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
