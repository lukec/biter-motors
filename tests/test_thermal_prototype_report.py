import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class ThermalPrototypeReportTests(unittest.TestCase):
    def test_renders_measured_traces_and_labels_scope(self):
        # Arithmetic renderer fixture only, not native-game evidence.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            samples = [{"tick": tick, "thermal": {"cores": [{"temperature": temp}],
                        "radiators": [{"temperature": 90}]}}
                       for tick, temp in ((60, 15), (120, 97), (180, 110), (240, 129))]
            report = [{"status": "steady_passed", "tick": 60, "thermal": {"cores": [{"temperature": 97}]}},
                      {"status": "repair_passed", "tick": 120},
                      {"status": "burnout_passed", "tick": 270, "seconds_from_hot_checkpoint": 41.75,
                       "thermal": {"burnout_events": [{"tick": 270, "temperature": 130.1}]}},
                      {"status": "reload_passed", "tick": 330, "native_deaths": 1}]
            (root / "samples.jsonl").write_text("\n".join(map(json.dumps, samples)))
            (root / "report.jsonl").write_text("\n".join(map(json.dumps, report)))
            result = subprocess.run([sys.executable, str(ROOT / "scripts/render_thermal_prototype.py"),
                            "--samples", str(root / "samples.jsonl"), "--report", str(root / "report.jsonl"),
                            "--output", str(root / "review.html")], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("not gameplay screenshots", (root / "review.html").read_text())
            for name in ("overview", "failure"):
                with Image.open(root / f"orbital-thermal-{name}.png") as image:
                    self.assertEqual(image.size, (1120, 470))
                    self.assertGreater(len(image.getcolors(image.width * image.height)), 20)
            self.assertEqual(json.loads((root / "review.json").read_text())["native_deaths"], 1)


if __name__ == "__main__":
    unittest.main()
