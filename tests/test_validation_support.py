import json
import tempfile
import unittest
from pathlib import Path

from scripts.validation_support import check_log, check_report, discover_source


class ValidationSupportTest(unittest.TestCase):
    def test_source_resolution_uses_manifest_and_preserves_spaces(self):
        with tempfile.TemporaryDirectory(prefix="biter motors ") as temp:
            root = Path(temp)
            folder = root / "mod" / "bitermotors_1.0.0"
            folder.mkdir(parents=True)
            (folder / "info.json").write_text(json.dumps({"name": "bitermotors", "version": "1.0.0"}))
            self.assertEqual((folder.resolve(), "1.0.0"), discover_source(root))
            (folder / "info.json").write_text(json.dumps({"name": "bitermotors", "version": "0.1.1"}))
            with self.assertRaisesRegex(ValueError, "folder"):
                discover_source(root)

    def test_source_resolution_rejects_missing_or_ambiguous_mods(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaisesRegex(ValueError, "found 0"):
                discover_source(root)
            for version in ("0.1.1", "1.0.0"):
                folder = root / "mod" / f"bitermotors_{version}"
                folder.mkdir(parents=True)
                (folder / "info.json").write_text("{}")
            with self.assertRaisesRegex(ValueError, "found 2"):
                discover_source(root)

    def test_source_resolution_rejects_malformed_manifest_types(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            folder = root / "mod" / "bitermotors_0.1.1"
            folder.mkdir(parents=True)
            for info in ([], None, {"name": "bitermotors", "version": 1}):
                with self.subTest(info=info):
                    (folder / "info.json").write_text(json.dumps(info))
                    with self.assertRaises(ValueError):
                        discover_source(root)

    def test_logs_reject_errors_even_with_success_summary(self):
        errors = (
            "Error while loading item prototype", "Error while running event",
            "The mod caused a non-recoverable error", "0.123 Error Main.cpp:42",
            "LuaEntity API call when LuaEntity was invalid.", "Received SIGSEGV",
            "Unexpected error occurred", "Error: Script crashed",
        )
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "engine.log"
            for error in errors:
                with self.subTest(error=error):
                    path.write_text(f"{error}\nPerformed 600 updates in 10 ms\nGoodbye\n")
                    with self.assertRaisesRegex(ValueError, "engine error"):
                        check_log(path, 600, "Goodbye")

    def test_log_requires_exact_update_count_and_completion_marker(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "engine.log"
            path.write_text("Performed 600 updates in 10 ms\nGoodbye\n")
            check_log(path, 600, "Goodbye")
            for text in ("Performed 599 updates\nGoodbye", "Performed 600 updates",
                         "Performed 600 updates\nPerformed 600 updates\nGoodbye", ""):
                with self.subTest(text=text):
                    path.write_text(text)
                    with self.assertRaises(ValueError):
                        check_log(path, 600, "Goodbye")

    def test_report_requires_late_sentinel_and_rejects_any_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "report.jsonl"
            complete = {"status": "complete", "tick": 599}
            path.write_text(json.dumps(complete) + "\n")
            check_report(path, "complete", 599)
            cases = (
                [{"status": "setup", "tick": 1}],
                [{"status": "complete", "tick": 598}],
                [{"status": "failed", "reason": "bad setup"}, complete],
                [complete, complete],
                [complete, {"status": "setup", "tick": 600}],
                [{"status": "complete", "tick": True}],
                [],
            )
            for rows in cases:
                with self.subTest(rows=rows):
                    path.write_text("\n".join(json.dumps(row) for row in rows))
                    with self.assertRaises(ValueError):
                        check_report(path, "complete", 599)
            path.write_text('{"status":')
            with self.assertRaises(ValueError):
                check_report(path, "complete", 599)
            path.write_text(json.dumps(complete))
            with self.assertRaisesRegex(ValueError, "unterminated"):
                check_report(path, "complete", 599)
