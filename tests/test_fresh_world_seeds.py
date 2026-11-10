"""Focused seed input and resource-evidence rejection tests; no engine required."""

import copy
import importlib.util
import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("fresh_world_support", ROOT / "scripts/fresh_world_support.py")
SUPPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SUPPORT)


def valid_report():
    resources = {name: {"nearest": 100.5, "count": 2, "total_amount": 1000}
                 for name in SUPPORT.RESOURCES}
    resources.update({name: {"nearest": 200, "count": 3, "total_amount": None}
                      for name in ("water", "enemy-spawners")})
    return dict(status="battery_resources_complete", radius=1024, seed=1092026,
                peaceful_mode=False, enemy_expansion=True, pollution=True,
                enemy_base_frequency=1, resources=resources,
                nickel_tiles=2, nickel_distance=100.5, lithium_wells=2,
                lithium_distance=100.5, uranium_tiles=2, uranium_distance=100.5)


class FreshWorldSeeds(unittest.TestCase):
    def test_uint32_decimal_boundaries(self):
        for text, expected in (("0", 0), ("4294967295", 4294967295),
                               ("00042", 42), ("1092026", 1092026),
                               ("424242", 424242), ("8675309", 8675309)):
            self.assertEqual(SUPPORT.parse_seed(text), expected)

    def test_reject_invalid_seeds(self):
        for value in ("", "-1", "+1", " 1", "1\n", "1.0", "1e2", "0xff",
                      "4294967296", "１２", None, True, 12):
            with self.subTest(value=value), self.assertRaises(ValueError):
                SUPPORT.parse_seed(value)

    def test_both_entrypoints_reject_invalid_seed_before_engine(self):
        for script in ("fresh-start", "battery-resources"):
            result = subprocess.run(
                ["bash", str(ROOT / f"scripts/validate-bitermotors-{script}.sh")],
                env={**os.environ, "BITERMOTORS_SEED": "4294967296",
                     "FACTORIO_BINARY": "/does-not-exist"}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("decimal uint32", result.stderr)
            self.assertNotIn("does-not-exist", result.stderr)

    def test_default_and_seeded_args_reach_engine_under_system_bash_nounset(self):
        for script in ("fresh-start", "battery-resources"):
            for seed in (None, "1092026"):
                env = {**os.environ, "FACTORIO_BINARY": "/usr/bin/true"}
                env.pop("BITERMOTORS_MOD_ARCHIVE", None)
                env.pop("BITERMOTORS_SEED", None)
                if seed is not None:
                    env["BITERMOTORS_SEED"] = seed
                result = subprocess.run(
                    ["/bin/bash", str(ROOT / f"scripts/validate-bitermotors-{script}.sh")],
                    env=env, capture_output=True, text=True)
                with self.subTest(script=script, seed=seed):
                    # true produces no engine log: reaching that validation proves
                    # the command expanded, without needing a licensed game here.
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("empty engine log", result.stderr)
                    self.assertNotIn("unbound variable", result.stderr)

    def test_complete_report_passes(self):
        SUPPORT.check_resources(valid_report(), 1092026)

    def test_missing_or_invalid_resource_evidence_fails_closed(self):
        for name in (*SUPPORT.RESOURCES, "water", "enemy-spawners"):
            for key, value in (("count", 0), ("count", True), ("nearest", None),
                               ("nearest", float("nan")), ("nearest", -1),
                               ("nearest", 2000), ("total_amount", 0)):
                with self.subTest(name=name, key=key, value=value):
                    row = valid_report()
                    row["resources"][name][key] = value
                    with self.assertRaises(ValueError):
                        SUPPORT.check_resources(row)
            row = valid_report()
            del row["resources"][name]
            with self.assertRaises(ValueError):
                SUPPORT.check_resources(row)

    def test_amounts_must_be_finite_and_positive(self):
        for amount in (None, False, -1, float("inf"), float("nan"), "100"):
            row = valid_report()
            row["resources"]["iron-ore"]["total_amount"] = amount
            with self.assertRaises(ValueError):
                SUPPORT.check_resources(row)

    def test_settings_status_seed_scope_and_legacy_fields_fail_closed(self):
        for key, value in (("status", "failed"), ("radius", 512), ("seed", True),
                           ("seed", 424242), ("peaceful_mode", True),
                           ("enemy_expansion", False), ("pollution", False),
                           ("enemy_base_frequency", 0), ("nickel_tiles", 1)):
            with self.subTest(key=key):
                row = valid_report()
                row[key] = value
                with self.assertRaises(ValueError):
                    SUPPORT.check_resources(row, 1092026)
        for key in valid_report():
            row = copy.deepcopy(valid_report())
            del row[key]
            with self.subTest(missing=key), self.assertRaises(ValueError):
                SUPPORT.check_resources(row, 1092026)


if __name__ == "__main__":
    unittest.main()
