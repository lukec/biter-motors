from pathlib import Path
import copy
import json
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from model_save_endgame import normal_stock, summarize, budget, sample_mod_identity
from model_orbital_logistics import load_layouts
from bitermotors_economy_catalog import EconomyCatalog, DOLLAR, TOKEN


class SaveEndgameTests(unittest.TestCase):
    def snapshot(self, kind="initial", tick=1, produced=10):
        return dict(kind=kind, tick=tick, play_ticks=tick, factorio_version="2.1.24", mod_version="0.1.1",
                    inventory={b: {} for b in ("containers", "players", "cargo", "machine_outputs", "machine_inputs", "labs")},
                    technologies={}, entities={}, force_modifiers={}, limits="fixture",
                    surfaces=[dict(name="nauvis", items_produced={DOLLAR: {"normal": dict(total=produced, per_minute={})}},
                                   items_consumed={}, fluids_produced={}, fluids_consumed={})])

    def test_stock_does_not_downgrade_quality_or_credit_arbitrary_committed_inputs(self):
        row = self.snapshot()
        row["inventory"]["containers"][DOLLAR] = {"normal": 5, "legendary": 100}
        row["inventory"]["machine_outputs"][DOLLAR] = {"normal": 3}
        row["inventory"]["machine_inputs"][DOLLAR] = {"normal": 200}
        row["inventory"]["labs"][TOKEN] = {"normal": 2}
        self.assertEqual({DOLLAR: 8, TOKEN: 2}, normal_stock(row))

    def test_native_counter_delta_is_distinct_from_historical_flow_and_wallet(self):
        first, last = self.snapshot(), self.snapshot("final", 36001, 110)
        first["surfaces"][0]["items_produced"][DOLLAR]["normal"]["per_minute"] = {"one_hour": 999}
        last["inventory"]["containers"][DOLLAR] = {"normal": 50}
        result = summarize([first, last], {"name": "fixture"})
        self.assertEqual(10, result["sample_minutes"])
        self.assertEqual(10, result["rates_per_minute"][DOLLAR]["observed_produced"])
        self.assertEqual(999, result["rates_per_minute"][DOLLAR]["historical_hour_produced"])
        self.assertEqual(5, result["wallet_change_per_minute"])

    def test_incomplete_paused_and_reset_samples_fail(self):
        cases = [[self.snapshot()], [self.snapshot(), self.snapshot("final", 1)],
                 [self.snapshot(), self.snapshot("final", 36001, 0)]]
        for rows in cases:
            with self.assertRaises(ValueError):
                summarize(rows, {})

    def test_budget_excludes_completed_research_and_existing_launch_buildings(self):
        catalog = EconomyCatalog.load()
        baseline = summarize([self.snapshot(), self.snapshot("final", 36001, 110)], {})
        baseline["technologies"] = {name: True for name in catalog.data["technologies"]}
        baseline["entities"] = {"rocket-silo": {"normal": 1}, "cargo-landing-pad": {"normal": 1}}
        baseline["opening_stock"] = {DOLLAR: 100000, TOKEN: 100000}
        layouts = load_layouts([ROOT / f"docs/orbital-layout-{n}.json" for n in (1, 4, 8, 12)])
        result = budget(catalog, baseline, layouts)
        self.assertEqual([], result["research"])
        self.assertEqual(0, result["entry_tokens_missing"])
        self.assertEqual(0, result["cash_gap"])
        self.assertEqual(0, result["materials"]["recipe_batches"].get("rocket-silo", 0))
        self.assertEqual(0, result["materials"]["recipe_batches"].get("cargo-landing-pad", 0))
        self.assertIn("rocket-fuel", result["unrated_materials"])

    def test_entry_platform_trigger_is_free_but_unknown_trigger_fails(self):
        catalog = EconomyCatalog.load()
        baseline = summarize([self.snapshot(), self.snapshot("final", 36001, 110)], {})
        baseline["technologies"] = {name: True for name in catalog.data["technologies"]}
        baseline["technologies"]["space-platform"] = False
        layouts = load_layouts([ROOT / f"docs/orbital-layout-{n}.json" for n in (1, 4, 8, 12)])
        self.assertEqual({}, budget(catalog, baseline, layouts)["science_before_stock"])
        catalog.data["technologies"]["space-platform"]["research_trigger"]["type"] = "invented"
        with self.assertRaisesRegex(ValueError, "unsupported entry research"):
            budget(catalog, baseline, layouts)

    def test_sampler_never_targets_a_live_server_or_original_save(self):
        script = (ROOT / "scripts/sample-bitermotors-save.sh").read_text()
        self.assertIn('cp "$save" "$tmp/saves/sample.zip"', script)
        self.assertIn('--benchmark "$tmp/saves/sample.zip"', script)
        self.assertIn('"Original save changed during sample"', script)
        self.assertNotIn("--start-server", script)
        self.assertNotIn("rcon", script.lower())
        lua = (ROOT / "scripts/fixtures/save-sample-control.lua").read_text()
        self.assertIn('electric and "watts" or "per_minute"', lua)
        self.assertIn('electric and rate * 60 or rate', lua)
        self.assertIn('consumed = flow(stats, "input", false, true)', lua)

    def test_versioned_archive_and_directory_share_standard_source_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory) / "bitermotors_0.1.1"
            staged.mkdir()
            (staged / "info.json").write_text('{"version":"0.1.1"}')
            (staged / "control.lua").write_text("return {}")
            expected = sample_mod_identity(staged)
            archive = Path(str(staged) + ".zip")
            with zipfile.ZipFile(archive, "w") as package:
                for path in staged.iterdir():
                    package.write(path, staged.name + "/" + path.name)
            for path in staged.iterdir():
                path.unlink()
            staged.rmdir()
            actual = sample_mod_identity(staged)
            self.assertEqual(expected["sample_mod_source_sha256"], actual["sample_mod_source_sha256"])
            self.assertRegex(actual["sample_mod_archive_sha256"], "^[0-9a-f]{64}$")

    def test_does_not_silently_rebuy_an_existing_orbital_campaign(self):
        baseline = summarize([self.snapshot(), self.snapshot("final", 36001, 110)], {})
        baseline["entities"]["space-platform-hub"] = {"normal": 1}
        with self.assertRaisesRegex(ValueError, "before orbital construction"):
            budget(EconomyCatalog.load(), baseline, None)

    def test_native_route_replaces_paper_costs_includes_final_io_and_keeps_stock_credit(self):
        catalog = EconomyCatalog.load()
        baseline = json.loads((ROOT / "docs/endgame-save-baseline.json").read_text())
        observed = json.loads((ROOT / "docs/endgame-practical-hyperscale.json").read_text())
        layouts = load_layouts([ROOT / f"docs/orbital-layout-{n}.json" for n in (1, 4, 8, 12)])
        result = budget(catalog, baseline, layouts, observed=observed)
        self.assertEqual(4900 + observed["operating_dollars_used"] + observed["research_dollars_consumed"] - 3900,
                         result["direct_dollars_before_stock"])
        self.assertEqual(45, result["native_rehearsal_rockets"])
        self.assertNotIn("rocket-fuel", result["materials"]["supplies"])
        self.assertEqual(observed["manifest"]["bulk-inserter"], result["materials"]["recipe_batches"]["bulk-inserter"]
                         + result["materials"]["stock_credited"].get("bulk-inserter", 0))
        for field, value in (("source_sha256", "wrong"), ("operating_dollars_used", 0), ("native_rocket_parts", 1)):
            bad = copy.deepcopy(observed)
            bad[field] = value
            with self.assertRaises(ValueError):
                budget(catalog, baseline, layouts, observed=bad)


if __name__ == "__main__":
    unittest.main()
