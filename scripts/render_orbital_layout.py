#!/usr/bin/env python3
"""Deterministic coordinate schematics from native orbital-layout report JSON.

Requires Pillow. Repeat --layout for separate reports; --output may be an HTML
index (with adjacent PNGs) or a PNG for one layout. No coordinates are generated.
"""

import argparse
import base64
from collections import Counter
import copy
import hashlib
import html
import json
import math
from pathlib import Path
import zlib

from PIL import Image, ImageDraw, ImageFont

SCALE = 22
MARGIN = 54
COLORS = {"hub": "#d7dae0", "core": "#dc754c", "radiator": "#51b8ac", "heat-pipe": "#f27b55",
          "solar": "#668bdc", "belt": "#d4b34f", "inserter": "#e1a1ce",
          "input": "#f0ce63", "output": "#a0d5aa", "other": "#a0a8b1"}
LABELS = {"hub": "Hub", "core": "Compute core", "radiator": "Radiator", "heat-pipe": "Heat pipe",
          "solar": "Solar", "belt": "Belt / direction", "inserter": "Inserter / facing",
          "input": "Input belt", "output": "Output belt",
          "other": "Other / unknown"}
FONT = ImageFont.load_default(size=13)
TITLE_FONT = ImageFont.load_default(size=21)


def kind(name):
    if name == "space-platform-hub":
        return "hub"
    if "datacenter-core" in name:
        return "core"
    if "radiator" in name:
        return "radiator"
    if "heat-pipe" in name:
        return "heat-pipe"
    if "solar" in name:
        return "solar"
    if "belt" in name or "loader" in name:
        return "belt"
    if "inserter" in name:
        return "inserter"
    return "other"


def footprint(entity):
    # Schematic nominal footprints, not native collision/placement assertions.
    category = kind(entity["name"])
    return {"hub": 8, "core": 3, "radiator": 3, "solar": 3}.get(category, 1)


def direction_vector(direction):
    """Native 2.x direction mapped to screen axes (+y down), not cargo flow."""
    angle = direction * math.tau / 16
    return math.sin(angle), -math.cos(angle)


def review_notes(layout):
    notes = []
    if "blueprint_review" in layout:
        review = layout["blueprint_review"]
        notes.append(f"Native blueprint geometry matched {review['matched_entities']} layout entities and all layout tiles. "
                     f"Display includes {review['added_hubs']} blueprint hub(s) and "
                     f"{review['added_tiles']} additional blueprint foundation tiles. This is geometry review, not throughput qualification.")
    if not any(kind(entity["name"]) == "hub" for entity in layout["entities"]):
        notes.append("Hub absent from exported entities; its position is not inferred.")
    count = sum(kind(entity["name"]) == "core" for entity in layout["entities"])
    if count != layout["cores"]:
        notes.append(f"Declared {layout['cores']} cores but exported {count} core entities.")
    return notes


def validate_layout(layout):
    if not isinstance(layout, dict):
        raise ValueError("layout must be an object")
    if type(layout.get("cores")) is not int or layout["cores"] < 1:
        raise ValueError("layout.cores must be a positive integer")
    for field in ("entities", "tiles"):
        if not isinstance(layout.get(field), list):
            raise ValueError(f"layout.{field} must be an array")
        for entry in layout[field]:
            if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
                raise ValueError(f"{field} entry requires a name")
            if "role" in entry and not isinstance(entry["role"], str):
                raise ValueError("entity role must be a string")
            position = entry.get("position", {})
            if not isinstance(position, dict) or any(
                type(position.get(axis)) not in (int, float)
                or not math.isfinite(position[axis]) for axis in ("x", "y")
            ):
                raise ValueError(f"{field} entry requires finite position.x/y")
            direction = entry.get("direction", 0)
            if type(direction) is not int or not 0 <= direction < 16:
                raise ValueError("direction must be a Factorio 2.x integer in 0..15")
    if not layout["entities"] and not layout["tiles"]:
        raise ValueError("layout has no geometry")
    manifest = layout.get("manifest")
    if not isinstance(manifest, dict) or any(
        not isinstance(key, str) or type(value) is not int or value < 0
        for key, value in manifest.items()
    ):
        raise ValueError("layout.manifest must map item names to nonnegative counts")
    return layout


def read_layouts(path):
    data = json.loads(Path(path).read_text())
    # A native report wraps a layout. Collections may contain reports or layouts.
    if not isinstance(data, (dict, list)):
        raise ValueError("report must be an object or array")
    rows = data if isinstance(data, list) else data.get("layouts", [data])
    if not isinstance(rows, list):
        raise ValueError("layouts must be an array")
    if any(not isinstance(row, dict) for row in rows):
        raise ValueError("each report must be an object")
    return [validate_layout(row.get("layout", row)) for row in rows]


def with_native_blueprint(layout, path):
    """Reject mismatched geometry; include real starter context from a blueprint."""
    encoded = Path(path).read_text().strip()
    if not encoded.startswith("0"):
        raise ValueError("expected a version-0 native blueprint string")
    try:
        blueprint = json.loads(zlib.decompress(base64.b64decode(encoded[1:], validate=True)))["blueprint"]
    except (ValueError, KeyError, zlib.error) as error:
        raise ValueError("invalid native blueprint") from error
    native = {"cores": layout["cores"], "entities": blueprint.get("entities", []),
              "tiles": blueprint.get("tiles", []), "manifest": {}}
    validate_layout(native)

    def entity_key(entity):
        return (entity["name"], entity["position"]["x"], entity["position"]["y"], entity.get("direction", 0))

    def tile_key(tile):
        return (tile["name"], tile["position"]["x"], tile["position"]["y"])

    expected = Counter(entity_key(entity) for entity in layout["entities"])
    actual = Counter(entity_key(entity) for entity in native["entities"])
    missing = expected - actual
    extra = actual - expected
    if missing or any(key[0] != "space-platform-hub" for key in extra):
        raise ValueError("native blueprint entity positions/directions do not match layout")
    expected_tiles = {tile_key(tile) for tile in layout["tiles"]}
    actual_tiles = {tile_key(tile) for tile in native["tiles"]}
    if expected_tiles - actual_tiles:
        raise ValueError("native blueprint is missing layout tiles")
    result = copy.deepcopy(layout)
    hubs = [entity for entity in native["entities"] if entity_key(entity) in extra]
    additional_tiles = [tile for tile in native["tiles"] if tile_key(tile) not in expected_tiles]
    for hub in hubs:
        result["entities"].append({"name": hub["name"], "position": hub["position"],
                                   "direction": hub.get("direction", 0), "role": "native-blueprint-hub"})
    result["tiles"].extend(additional_tiles)
    result["blueprint_review"] = {"matched_entities": len(layout["entities"]),
                                  "added_hubs": len(hubs), "added_tiles": len(additional_tiles),
                                  "blueprint_sha256": hashlib.sha256(encoded.encode()).hexdigest()}
    return result


def geometry_bounds(layout):
    boxes = []
    for tile in layout["tiles"]:
        x, y = (tile["position"][axis] for axis in ("x", "y"))
        boxes.append((x, y, x + 1, y + 1))
    for entity in layout["entities"]:
        x, y = (entity["position"][axis] for axis in ("x", "y"))
        half = footprint(entity) / 2
        boxes.append((x - half, y - half, x + half, y + half))
    return (math.floor(min(b[0] for b in boxes)) - 1,
            math.floor(min(b[1] for b in boxes)) - 1,
            math.ceil(max(b[2] for b in boxes)) + 1,
            math.ceil(max(b[3] for b in boxes)) + 1)


def render_layout(layout):
    validate_layout(layout)
    left, top, right, bottom = geometry_bounds(layout)
    width = max(740, (right - left) * SCALE + MARGIN * 2)
    height = (bottom - top) * SCALE + 235
    if width * height > 32_000_000:
        raise ValueError("layout exceeds preview pixel budget")
    image = Image.new("RGB", (width, height), "#14191f")
    draw = ImageDraw.Draw(image)

    def point(x, y):
        return (MARGIN + (x - left) * SCALE, 86 + (y - top) * SCALE)

    def box(x1, y1, x2, y2):
        return (*point(x1, y1), *point(x2, y2))

    draw.text((22, 16), f"ORBITAL ARRAY / {layout['cores']} CORE" +
              ("S" if layout["cores"] != 1 else ""), fill="#f2f4f7", font=TITLE_FONT)
    draw.text((22, 47), "Coordinate schematic | exported positions | not an in-game screenshot",
              fill="#b8c2ce", font=FONT)
    for x in range(left, right + 1):
        draw.line((*point(x, top), *point(x, bottom)), fill="#252d36")
        if x % 5 == 0:
            draw.text((point(x, top)[0], 68), str(x), fill="#a5afba", font=FONT)
    for y in range(top, bottom + 1):
        draw.line((*point(left, y), *point(right, y)), fill="#252d36")
        if y % 5 == 0:
            draw.text((12, point(left, y)[1]), str(y), fill="#a5afba", font=FONT)
    for tile in sorted(layout["tiles"], key=lambda t: (t["position"]["y"], t["position"]["x"], t["name"])):
        x, y = (tile["position"][axis] for axis in ("x", "y"))
        draw.rectangle(box(x, y, x + 1, y + 1), fill="#343e49", outline="#596574")
    entities = sorted(layout["entities"], key=lambda e: (
        kind(e["name"]) in ("belt", "inserter"), e["position"]["y"],
        e["position"]["x"], e["name"], e.get("direction", 0)))
    for entity in entities:
        category = kind(entity["name"])
        x, y = (entity["position"][axis] for axis in ("x", "y"))
        half = footprint(entity) / 2
        rect = box(x - half, y - half, x + half, y + half)
        rect = (rect[0] + 2, rect[1] + 2, rect[2] - 2, rect[3] - 2)
        color_key = entity.get("role") if category == "belt" else category
        color = COLORS.get(color_key, COLORS[category])
        draw.rectangle(rect, fill=color, outline="#10151a", width=2)
        cx, cy = point(x, y)
        if category in ("belt", "inserter") and "direction" in entity:
            dx, dy = direction_vector(entity["direction"])
            tip = (cx + dx * 8, cy + dy * 8)
            draw.line((cx - dx * 7, cy - dy * 7, *tip), fill="#14191f", width=2)
            draw.polygon([tip, (tip[0] - dx * 5 + dy * 3, tip[1] - dy * 5 - dx * 3),
                          (tip[0] - dx * 5 - dy * 3, tip[1] - dy * 5 + dx * 3)], fill="#14191f")
        elif category in ("hub", "core", "radiator", "solar"):
            label = {"hub": "HUB", "core": "CORE", "radiator": "RAD", "solar": "SOL"}[category]
            if entity.get("role") == "native-blueprint-hub":
                label = "HUB (BP)"
            draw.text((cx, cy), label, fill="#10151a", font=FONT, anchor="mm")
    legend_y = height - 125
    for index, category in enumerate(COLORS):
        x = 22 + (index % 4) * 178
        y = legend_y + (index // 4) * 25
        draw.rectangle((x, y, x + 13, y + 13), fill=COLORS[category])
        draw.text((x + 19, y), LABELS[category], fill="#e0e6ec", font=FONT)
    draw.text((22, height - 35), "1 grid cell = 1 tile | +x right, +y down | nominal footprints",
              fill="#b8c2ce", font=FONT)
    draw.text((22, height - 18), "Arrows = facing, not throughput | BP = native blueprint context",
              fill="#b8c2ce", font=FONT)
    return image


def write_previews(layouts, output):
    output = Path(output)
    layouts = sorted(layouts, key=lambda row: row["cores"])
    if not layouts or len({row["cores"] for row in layouts}) != len(layouts):
        raise ValueError("provide nonempty layouts with unique core counts")
    if output.suffix.lower() not in (".png", ".html"):
        raise ValueError("output must end in .png or .html")
    if output.suffix.lower() == ".png" and len(layouts) != 1:
        raise ValueError("PNG output requires exactly one layout")
    output.parent.mkdir(parents=True, exist_ok=True)
    sections = []
    for layout in layouts:
        target = output if output.suffix.lower() == ".png" else output.with_name(f"orbital-layout-{layout['cores']}.png")
        render_layout(layout).save(target, optimize=False, compress_level=9)
        digest = hashlib.sha256(json.dumps(layout, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        manifest = "".join(f"<tr><td>{html.escape(name)}</td><td>{count:,}</td></tr>"
                           for name, count in sorted(layout["manifest"].items()))
        notes = "".join(f'<p class="warning">{html.escape(note)}</p>' for note in review_notes(layout))
        positions = "".join(
            f'<tr><td>{html.escape(entity["name"])}</td><td>{html.escape(entity.get("role", ""))}</td>'
            f'<td>{entity["position"]["x"]}, {entity["position"]["y"]}</td>'
            f'<td>{entity.get("direction", "not exported")}</td></tr>'
            for entity in sorted(layout["entities"], key=lambda e: (
                e["position"]["y"], e["position"]["x"], e["name"])))
        recipes = ", ".join(sorted({entity["recipe"] for entity in layout["entities"] if entity.get("recipe")}))
        sections.append(f'<section id="cores-{layout["cores"]}"><h2>{layout["cores"]} cores</h2>'
                        f'<p><a href="../blueprints/orbital-compute-{layout["cores"]}.txt">Native blueprint string</a>'
                        f' | <a href="orbital-layout-{layout["cores"]}.json">Canonical layout JSON</a></p>'
                        f'<p>Core recipe: <code>{html.escape(recipes or "not exported")}</code></p>'
                        f'<a href="{target.name}"><img src="{target.name}" alt="{layout["cores"]}-core coordinate schematic"></a>'
                        f'<p>{len(layout["entities"]):,} entities / {len(layout["tiles"]):,} tiles</p>'
                        f'{notes}<details><summary>Entity coordinate review</summary><div class="scroll">'
                        f'<table><tr><th>Entity</th><th>Role</th><th>x, y</th><th>Direction (0=N, 4=E, 8=S, 12=W)</th></tr>'
                        f'{positions}</table></div></details>'
                        f'<details><summary>Exported manifest</summary><table><tr><th>Item</th><th>Count</th></tr>{manifest}</table></details>'
                        f'<details><summary>Layout SHA-256</summary><code>{digest}</code></details></section>')
    if output.suffix.lower() == ".html":
        nav = " | ".join(f'<a href="#cores-{row["cores"]}">{row["cores"]} cores</a>' for row in layouts)
        output.write_text('<!doctype html><html lang="en"><meta charset="utf-8">'
                          '<meta name="viewport" content="width=device-width,initial-scale=1">'
                          '<title>Orbital layout previews</title><style>'
                          'body{font:16px/1.5 system-ui;margin:0;background:#14191f;color:#e0e6ec}'
                          'main{max-width:1400px;margin:auto;padding:24px}a{color:#88bfff}'
                          'section{border-top:1px solid #596574;margin-top:28px;padding-top:12px}'
                          'img{display:block;max-width:100%;height:auto}table{border-collapse:collapse}'
                          'th,td{text-align:left;padding:4px 24px 4px 0}code{overflow-wrap:anywhere}'
                          '.warning{color:#f0ce63}.scroll{overflow-x:auto}td{white-space:nowrap}'
                          'details{margin:12px 0}</style><main><h1>Orbital Layout Previews</h1>'
                          '<p>Deterministic schematics from exported report coordinates, not in-game screenshots. '
                          'Nominal footprints and direction arrows do not prove placement, power, or throughput. '
                          'Inserter arrows show native facing, not item-transfer direction. '
                          'Manifest counts are reported as supplied, not inferred from the drawing.</p>'
                          '<h2>Build Reference</h2><p>Gold belts carry inputs from the hub to core input arms; '
                          'green belts return core outputs to the hub. Blue panels are solar; teal panels are radiators. '
                          'Orange heat pipes physically connect each core to its radiator. '
                          'The native blueprint includes starter context omitted from the canonical construction manifest. '
                          'Blueprint links refer to the matching native export, not a reconstructed blueprint.</p>'
                          '<p><a href="orbital-platform-guide.md">Operating guide: supply, provider and landing-pad settings, '
                          'recipe progression and Model return</a>.</p>'
                          f'<nav>{nav}</nav>' + "".join(sections) + '</main></html>')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", action="append", required=True, type=Path,
                        help="JSON report, raw layout, or collection; repeat for separate reports")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--blueprint", action="append", type=Path,
                        help="optional native blueprint for each layout, in input order; validates geometry and adds starter context")
    args = parser.parse_args()
    try:
        layouts = [row for path in args.layout for row in read_layouts(path)]
        if args.blueprint:
            if len(args.blueprint) != len(layouts):
                raise ValueError("provide one --blueprint per layout, in input order")
            layouts = [with_native_blueprint(row, path) for row, path in zip(layouts, args.blueprint)]
        write_previews(layouts, args.output)
    except (ValueError, OSError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
