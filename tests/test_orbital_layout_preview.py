import copy
from collections import Counter
import base64
import csv
import io
import json
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import unittest
import zlib

try:
    from lupa.lua52 import LuaRuntime
except ImportError:
    LuaRuntime = None

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import render_orbital_layout as preview


def tiny_layout():
    """Synthetic renderer fixture only; not a proposed orbital design."""
    return {"cores": 1, "entities": [
        {"name": "space-platform-hub", "position": {"x": 0, "y": 0}},
        {"name": "bitermotors-orbital-datacenter-core", "position": {"x": -3.5, "y": 7.5}},
        {"name": "transport-belt", "position": {"x": -3.5, "y": 5.5}, "direction": 4},
        {"name": "inserter", "position": {"x": -3.5, "y": 6.5}, "direction": 8},
        {"name": "bitermotors-orbital-radiator-panel", "position": {"x": 0.5, "y": 7.5}},
        {"name": "bitermotors-high-density-space-solar-panel", "position": {"x": 4.5, "y": 7.5}}],
        "tiles": [{"name": "space-platform-foundation", "position": {"x": -4, "y": 5}}],
        "manifest": {"transport-belt": 1, "<unsafe&item>": 2}}


class OrbitalLayoutPreviewTests(unittest.TestCase):
    def test_deterministic_and_does_not_mutate_input(self):
        layout = tiny_layout()
        before = copy.deepcopy(layout)
        first = preview.render_layout(layout)
        self.assertEqual(first.tobytes(), preview.render_layout(layout).tobytes())
        self.assertEqual(before, layout)
        layout["entities"].reverse()
        self.assertEqual(first.tobytes(), preview.render_layout(layout).tobytes())
        for color in preview.COLORS.values():
            if color not in (preview.COLORS["other"], preview.COLORS["input"], preview.COLORS["output"]):
                self.assertIn(tuple(bytes.fromhex(color[1:])),
                              {color for _, color in first.getcolors(first.width * first.height)})

    def test_direction_changes_pixels(self):
        layout = tiny_layout()
        before = preview.render_layout(layout).tobytes()
        layout["entities"][2]["direction"] = 12
        self.assertNotEqual(before, preview.render_layout(layout).tobytes())

    def test_native_cardinal_direction_matrix(self):
        for direction, expected in ((0, (0, -1)), (4, (1, 0)),
                                    (8, (0, 1)), (12, (-1, 0))):
            actual = preview.direction_vector(direction)
            for component, target in zip(actual, expected):
                self.assertAlmostEqual(component, target)

    def test_roles_and_missing_hub_are_explicit(self):
        layout = tiny_layout()
        self.assertEqual([], preview.review_notes(layout))
        layout["entities"] = layout["entities"][1:]
        self.assertIn("Hub absent", preview.review_notes(layout)[0])
        layout["entities"][1]["role"] = "input"
        first = preview.render_layout(layout).tobytes()
        layout["entities"][1]["role"] = "output"
        self.assertNotEqual(first, preview.render_layout(layout).tobytes())

    def canonical_layouts(self):
        lua = shutil.which("lua5.2") or shutil.which("lua")
        if not LuaRuntime and not lua:
            self.skipTest("Lua or lupa.lua52 required")
        fixture = ROOT / "scripts/fixtures/orbital-layout.lua"
        if not fixture.exists():
            self.skipTest("canonical fixture not supplied yet")
        # Execute the source of truth; TSV carries its coordinates without a
        # second implementation of layout arithmetic or a Lua JSON dependency.
        script = '''
local layout = dofile(arg[1])
for _, count in ipairs{1, 4, 8, 12} do
  local row = layout.make(count, "test-recipe")
  for _, e in ipairs(row.entities) do
    print(table.concat({count, "entity", e.name, e.position.x, e.position.y,
      e.direction or 0, e.role or ""}, "\\t"))
  end
  for _, t in ipairs(row.tiles) do
    print(table.concat({count, "tile", t.name, t.position.x, t.position.y}, "\\t"))
  end
  for item, amount in pairs(row.manifest) do
    print(table.concat({count, "manifest", item, amount}, "\\t"))
  end
end
'''
        if LuaRuntime:
            runtime = LuaRuntime()
            lines = []
            runtime.globals()["print"] = lambda value: lines.append(str(value))
            runtime.globals()["arg"] = runtime.table_from({1: str(fixture)})
            runtime.execute(script)
            output = "\n".join(lines)
        else:
            output = subprocess.run([lua, "-", str(fixture)], input=script,
                                    text=True, capture_output=True, check=True).stdout
        layouts = {count: {"cores": count, "entities": [], "tiles": [], "manifest": {}}
                   for count in (1, 4, 8, 12)}
        for fields in csv.reader(io.StringIO(output), delimiter="\t"):
            count, category, name, *values = fields
            row = layouts[int(count)]
            if category == "manifest":
                row["manifest"][name] = int(values[0])
            else:
                entry = {"name": name, "position": {"x": float(values[0]), "y": float(values[1])}}
                if category == "entity":
                    entry.update(direction=int(values[2]), role=values[3])
                row["entities" if category == "entity" else "tiles"].append(entry)
        return layouts

    def test_canonical_fixture_schema_without_generating_coordinates(self):
        for count, layout in self.canonical_layouts().items():
            self.assertEqual(count, sum(e.get("role") == "core" for e in layout["entities"]))
            self.assertEqual(5 * count, sum(e.get("role") == "solar" for e in layout["entities"]))
            preview.validate_layout(layout)
            self.assertGreater(preview.render_layout(layout).height, 0)
            self.assertTrue(all(not (-5 <= t["position"]["x"] <= 4 and -5 <= t["position"]["y"] <= 4)
                                for t in layout["tiles"]), "do not bill the native 10x10 starter twice")
            self.assertTrue(all(e["name"] == "express-transport-belt" for e in layout["entities"]
                                if e.get("role") == "input"), "large final inputs need the tested express bus")

    def assert_footprints_and_manifest(self, layout):
        solid = {(tile['position']['x'], tile['position']['y']) for tile in layout['tiles']}
        solid |= {(x, y) for x in range(-5, 5) for y in range(-5, 5)}
        occupied = {}
        sizes = {'core': 3, 'radiator': 3, 'solar': 3}
        for entity in layout['entities']:
            size = sizes.get(entity.get('role'), 1)
            x, y = entity['position']['x'], entity['position']['y']
            left, top = x - size / 2, y - size / 2
            self.assertEqual((int(left), int(top)), (left, top), 'off-grid footprint')
            for dx in range(size):
                for dy in range(size):
                    point = left + dx, top + dy
                    self.assertNotIn(point, occupied, 'overlapping entity footprints')
                    occupied[point] = entity['name']
                    self.assertIn(point, solid, 'entity missing foundation')
        manifest = dict(Counter(entity['name'] for entity in layout['entities']))
        manifest['space-platform-foundation'] = len(layout['tiles'])
        self.assertEqual(manifest, layout['manifest'])
        self.assertEqual(len(layout['tiles']), len({(t['position']['x'], t['position']['y'])
                                                   for t in layout['tiles']}), 'duplicate foundation')

    def assert_thermal_routes(self, layout):
        # Native center-edge ports: two opposite ports must be exactly one tile
        # apart and face each other, not merely touch somewhere along an edge.
        sizes = {'bitermotors-orbital-datacenter-core': 3,
                 'bitermotors-orbital-radiator-panel': 3,
                 'bitermotors-orbital-heat-pipe': 1}
        thermal = [entity for entity in layout['entities'] if entity['name'] in sizes]
        ports, graph = {}, {i: set() for i in range(len(thermal))}
        for i, entity in enumerate(thermal):
            offset = (sizes[entity['name']] - 1) / 2
            x, y = entity['position']['x'], entity['position']['y']
            for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                key = x + dx * offset, y + dy * offset, dx, dy
                self.assertNotIn(key, ports, 'overlapping native heat ports')
                ports[key] = i
        for (x, y, dx, dy), i in ports.items():
            neighbor = ports.get((x + dx, y + dy, -dx, -dy))
            if neighbor is not None:
                graph[i].add(neighbor)
        seen_routes = set()
        for i, entity in enumerate(thermal):
            if entity['name'] != 'bitermotors-orbital-datacenter-core':
                continue
            visited, pending = {i}, [i]
            while pending:
                for neighbor in graph[pending.pop()] - visited:
                    visited.add(neighbor)
                    pending.append(neighbor)
            self.assertTrue(any(thermal[n]['name'] == 'bitermotors-orbital-radiator-panel'
                                for n in visited), 'core lacks native heat route to radiator')
            self.assertTrue(any(thermal[n]['name'] == 'bitermotors-orbital-heat-pipe'
                                for n in visited), 'route lacks physical orbital pipe')
            seen_routes |= visited
        self.assertEqual(set(graph), seen_routes, 'orphan radiator or heat pipe')

    def test_canonical_physical_thermal_routes_and_no_footprint_overlaps(self):
        for count, layout in self.canonical_layouts().items():
            with self.subTest(cores=count):
                self.assert_footprints_and_manifest(layout)
                self.assert_thermal_routes(layout)
                self.assertEqual(2 * count, layout['manifest']['bitermotors-orbital-heat-pipe'])
                self.assertEqual(count, layout['manifest']['bitermotors-orbital-radiator-panel'])

    def test_thermal_checks_reject_broken_pipe_and_off_center_radiator(self):
        layout = self.canonical_layouts()[1]
        broken = copy.deepcopy(layout)
        pipe = next(e for e in broken['entities'] if e.get('role') == 'heat-pipe')
        broken['entities'].remove(pipe)
        with self.assertRaisesRegex(AssertionError, 'lacks native heat route'):
            self.assert_thermal_routes(broken)
        offset = copy.deepcopy(layout)
        radiator = next(e for e in offset['entities'] if e.get('role') == 'radiator')
        radiator['position']['y'] += 1
        with self.assertRaisesRegex(AssertionError, 'lacks native heat route'):
            self.assert_thermal_routes(offset)

    def test_footprint_check_rejects_noncenter_overlap(self):
        layout = self.canonical_layouts()[1]
        pipe = next(e for e in layout['entities'] if e.get('role') == 'heat-pipe')
        pipe['position']['x'] -= 1
        with self.assertRaisesRegex(AssertionError, 'overlapping entity footprints'):
            self.assert_footprints_and_manifest(layout)

    def test_thermal_bays_remain_present_during_cumulative_ramp(self):
        previous_entities, previous_tiles = set(), set()
        for layout in self.canonical_layouts().values():
            entities = {(e['name'], e['position']['x'], e['position']['y'], e['direction'])
                        for e in layout['entities']}
            tiles = {(t['position']['x'], t['position']['y']) for t in layout['tiles']}
            self.assertTrue(previous_entities <= entities, 'ramp removes retained hardware')
            self.assertTrue(previous_tiles <= tiles, 'ramp removes retained foundation')
            previous_entities, previous_tiles = entities, tiles

    def assert_foundation_structure(self, layout):
        tiles = {(tile["position"]["x"], tile["position"]["y"]) for tile in layout["tiles"]}
        self.assertTrue(all(x == int(x) and y == int(y) for x, y in tiles))
        # The canonical fixture explicitly treats the starter hub as this solid
        # 9x9 region; it is context, not hardware added to its layout manifest.
        solid = tiles | {(x, y) for x in range(-5, 5) for y in range(-5, 5)}
        neighbors = ((0, -1), (1, 0), (0, 1), (-1, 0))

        def flood(start, allowed):
            visited, pending = {start}, [start]
            while pending:
                x, y = pending.pop()
                for dx, dy in neighbors:
                    point = x + dx, y + dy
                    if point in allowed and point not in visited:
                        visited.add(point)
                        pending.append(point)
            return visited

        self.assertEqual(solid, flood((0, 0), solid), "foundation disconnected from starter hub")
        left, right = int(min(x for x, _ in solid)) - 1, int(max(x for x, _ in solid)) + 1
        top, bottom = int(min(y for _, y in solid)) - 1, int(max(y for _, y in solid)) + 1
        empty = {(x, y) for x in range(left, right + 1) for y in range(top, bottom + 1)} - solid
        self.assertEqual(empty, flood((left, top), empty), "enclosed foundation holes")

    def assert_belt_structure(self, layout):
        directions = {0: (0, -1), 4: (1, 0), 8: (0, 1), 12: (-1, 0)}

        def position(entity):
            return entity["position"]["x"], entity["position"]["y"]

        def arm_point(entity, pickup):
            x, y = position(entity)
            dx, dy = directions[entity["direction"]]
            sign = 1 if pickup else -1
            return x + sign * dx, y + sign * dy

        def role(name):
            return [entity for entity in layout["entities"] if entity.get("role") == name]

        def trace(belts, start, terminal):
            by_position = {position(entity): entity for entity in belts}
            self.assertEqual(len(belts), len(by_position), "duplicate belt positions")
            visited, current = set(), start
            while current in by_position:
                self.assertNotIn(current, visited, "belt cycle")
                visited.add(current)
                last = current
                dx, dy = directions[by_position[current]["direction"]]
                current = current[0] + dx, current[1] + dy
            self.assertEqual(set(by_position), visited, "disconnected or branched belt route")
            self.assertEqual(terminal, last, "belt route ends beyond the last pickup")
            return visited

        input_arms = role("core-input")
        self.assertEqual(layout["cores"], len(input_arms))
        pickups = {arm_point(arm, True) for arm in input_arms}
        last_pickup = max(pickups, key=lambda point: point[0])
        hub_inputs, hub_outputs = role("hub-input"), role("hub-output")
        self.assertEqual(1, len(hub_inputs))
        self.assertEqual(1, len(hub_outputs))
        input_route = trace(role("input"), arm_point(hub_inputs[0], False), last_pickup)
        self.assertTrue(pickups <= input_route, "core pickup not on Dollar bus")
        bus = {point for point in input_route if point[1] == last_pickup[1]}
        self.assertEqual(last_pickup[0], max(x for x, _ in bus), "Dollar dead leg after last input arm")
        output_arms = role("core-output")
        self.assertEqual(layout["cores"], len(output_arms))
        drops = {arm_point(arm, False) for arm in output_arms}
        output_route = trace(role("output"), max(drops, key=lambda point: point[0]),
                             arm_point(hub_outputs[0], True))
        self.assertTrue(drops <= output_route, "core output not on return bus")

    def test_canonical_foundation_connectivity_and_no_enclosed_holes(self):
        for count, layout in self.canonical_layouts().items():
            with self.subTest(cores=count):
                self.assert_foundation_structure(layout)

    def test_canonical_belt_connectivity_and_input_bus_cutoff(self):
        for count, layout in self.canonical_layouts().items():
            with self.subTest(cores=count):
                self.assert_belt_structure(layout)

    def test_documented_native_exports_have_sound_structure(self):
        paths = [ROOT / f"docs/orbital-layout-{count}.json" for count in (1, 4, 8, 12)]
        if not all(path.exists() for path in paths):
            self.skipTest("final native exports not supplied yet")
        for path in paths:
            layout, = preview.read_layouts(path)
            with self.subTest(cores=layout["cores"]):
                self.assert_foundation_structure(layout)
                self.assert_belt_structure(layout)
                self.assert_thermal_routes(layout)

    def test_published_blueprints_match_documented_exports(self):
        for count in (1, 4, 8, 12):
            with self.subTest(cores=count):
                layout, = preview.read_layouts(ROOT / f"docs/orbital-layout-{count}.json")
                reviewed = preview.with_native_blueprint(
                    layout, ROOT / f"blueprints/orbital-compute-{count}.txt")
                self.assertEqual(len(layout["entities"]), reviewed["blueprint_review"]["matched_entities"])
                self.assertEqual(1, reviewed["blueprint_review"]["added_hubs"])
                self.assert_foundation_structure(reviewed)
                self.assert_thermal_routes(reviewed)

    def test_structural_checks_reject_holes_disconnections_and_dollar_dead_leg(self):
        layout = self.canonical_layouts()[1]
        disconnected = copy.deepcopy(layout)
        disconnected["tiles"].append({"name": "space-platform-foundation", "position": {"x": 100, "y": 100}})
        with self.assertRaisesRegex(AssertionError, "disconnected"):
            self.assert_foundation_structure(disconnected)
        hole = copy.deepcopy(layout)
        # Find a fully surrounded non-hub tile so the regression does not depend
        # on one particular floodfilled interior coordinate.
        solid = {(tile["position"]["x"], tile["position"]["y"]) for tile in hole["tiles"]}
        candidate = next((x, y) for x, y in sorted(solid)
                         if not (-4 <= x <= 4 and -4 <= y <= 4)
                         and all((x + dx, y + dy) in solid for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0))))
        hole["tiles"] = [tile for tile in hole["tiles"]
                         if (tile["position"]["x"], tile["position"]["y"]) != candidate]
        with self.assertRaisesRegex(AssertionError, "enclosed"):
            self.assert_foundation_structure(hole)
        dead_leg = copy.deepcopy(layout)
        last = max((entity for entity in dead_leg["entities"] if entity.get("role") == "input"),
                   key=lambda entity: (entity["position"]["y"], entity["position"]["x"]))
        extra = copy.deepcopy(last)
        extra["position"]["x"] += 1
        dead_leg["entities"].append(extra)
        with self.assertRaisesRegex(AssertionError, "last pickup"):
            self.assert_belt_structure(dead_leg)

    def test_bounds_use_actual_negative_and_far_coordinates(self):
        layout = tiny_layout()
        layout["tiles"].append({"name": "space-platform-foundation", "position": {"x": -20, "y": 35}})
        self.assertEqual((-21, -5, 7, 37), preview.geometry_bounds(layout))

    def test_bad_geometry_is_rejected_not_invented(self):
        for bad in (None, float("nan"), float("inf"), True, "1"):
            layout = tiny_layout()
            layout["entities"][0]["position"]["x"] = bad
            with self.assertRaisesRegex(ValueError, "finite"):
                preview.render_layout(layout)
        layout = tiny_layout()
        del layout["tiles"]
        with self.assertRaisesRegex(ValueError, "tiles"):
            preview.render_layout(layout)

    def test_pixel_budget(self):
        layout = tiny_layout()
        layout["entities"][0]["position"]["x"] = 1e9
        with self.assertRaisesRegex(ValueError, "budget"):
            preview.render_layout(layout)

    def test_bad_report_and_manifest_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "bad.json"
            for value in (None, 4, [None], {"layouts": {}}, {"layout": None}):
                source.write_text(json.dumps(value))
                with self.assertRaises(ValueError):
                    preview.read_layouts(source)
        for value in ({"item": -1}, {"item": True}, [], None):
            layout = tiny_layout()
            layout["manifest"] = value
            with self.assertRaisesRegex(ValueError, "manifest"):
                preview.render_layout(layout)
        for value in (-1, 16, 4.0, True):
            layout = tiny_layout()
            layout["entities"][2]["direction"] = value
            with self.assertRaisesRegex(ValueError, "direction"):
                preview.render_layout(layout)

    def test_native_blueprint_review_preserves_layout_and_adds_real_context(self):
        layout = tiny_layout()
        hub = layout["entities"].pop(0)
        before = copy.deepcopy(layout)
        blueprint = {"entities": copy.deepcopy(layout["entities"]) + [hub],
                     "tiles": copy.deepcopy(layout["tiles"]) + [
                         {"name": "space-platform-foundation", "position": {"x": 0, "y": 0}}]}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "native.txt"

            def write(value):
                path.write_text("0" + base64.b64encode(zlib.compress(json.dumps({"blueprint": value}).encode())).decode())

            write(blueprint)
            reviewed = preview.with_native_blueprint(layout, path)
            self.assertEqual(before, layout)
            self.assertEqual(1, reviewed["blueprint_review"]["added_hubs"])
            self.assertEqual(1, reviewed["blueprint_review"]["added_tiles"])
            self.assertEqual(layout["manifest"], reviewed["manifest"])
            self.assertIn("geometry review, not throughput", preview.review_notes(reviewed)[0])
            self.assertEqual("native-blueprint-hub", reviewed["entities"][-1]["role"])
            bad = copy.deepcopy(blueprint)
            bad["entities"][1]["direction"] = 12
            write(bad)
            with self.assertRaisesRegex(ValueError, "positions/directions"):
                preview.with_native_blueprint(layout, path)
            bad = copy.deepcopy(blueprint)
            bad["tiles"] = []
            write(bad)
            with self.assertRaisesRegex(ValueError, "missing layout tiles"):
                preview.with_native_blueprint(layout, path)

    def test_cli_report_and_collection_html(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "report.json"
            source.write_text(json.dumps({"layout": tiny_layout()}))
            output = root / "one.png"
            command = [sys.executable, str(ROOT / "scripts/render_orbital_layout.py"),
                       "--layout", str(source), "--output", str(output)]
            subprocess.run(command, check=True, capture_output=True)
            self.assertTrue(output.read_bytes().startswith(b"\x89PNG"))
            first = output.read_bytes()
            subprocess.run(command, check=True, capture_output=True)
            self.assertEqual(first, output.read_bytes())
            layouts = []
            for count in (12, 1, 8, 4):
                layout = tiny_layout()
                layout["cores"] = count  # Collection handling, not real scaled geometry.
                layouts.append(layout)
            source.write_text(json.dumps({"layouts": [{"layout": row} for row in layouts]}))
            loaded = preview.read_layouts(source)
            preview.write_previews(loaded, root / "index.html")
            page = (root / "index.html").read_text()
            self.assertIn("not in-game screenshots", page)
            self.assertIn("&lt;unsafe&amp;item&gt;", page)
            self.assertIn('href="../blueprints/orbital-compute-1.txt"', page)
            self.assertIn('href="orbital-layout-1.json"', page)
            self.assertIn('href="orbital-platform-guide.md"', page)
            self.assertNotIn("pending the final operating guide", page)
            self.assertLess(page.index('id="cores-1"'), page.index('id="cores-4"'))
            for count in (1, 4, 8, 12):
                self.assertTrue((root / f"orbital-layout-{count}.png").exists())
            with self.assertRaisesRegex(ValueError, "exactly one"):
                preview.write_previews(loaded, root / "many.png")
            with self.assertRaisesRegex(ValueError, "unique"):
                preview.write_previews([loaded[0], loaded[0]], root / "duplicate.html")


if __name__ == "__main__":
    unittest.main()
