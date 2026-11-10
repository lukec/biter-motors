# Orbital Art Provenance

## Generation

Generated on 2026-11-10 for Biter Motors with three separate successful calls to
the built-in `image_gen.imagegen` tool, each with
`transparent_background: true`. No reference images, CLI/API fallback, Blender,
or simulated generation was used. No prompt was blocked. The tool did not expose
a model/version identifier. Although the requests asked for 1024x1024, all three
returned source PNGs are **1254x1254 RGBA**.

The local tool-output directory is
`/Users/lukec/.codex/generated_images/01a1c72f-819d-7213-b7dc-28380ac12751/`.
The portable retained masters are under `art/bitermotors-masters/final/`.

| Device / retained master filename | Original tool-output filename | Source alpha crop, threshold >8, right/bottom exclusive |
| --- | --- | --- |
| `orbital-datacenter-core.png` | `exec-8ae60b78-ac4e-4015-a496-6b8412f056f2.png` | `(83, 91, 1172, 1159)` |
| `orbital-radiator-panel.png` | `exec-49eaa490-06e2-404f-9ceb-c43fba36b9c3.png` | `(57, 75, 1197, 1186)` |
| `high-density-space-solar-panel.png` | `exec-55658625-fd21-44fd-b129-033ed0e73861.png` | `(65, 83, 1188, 1154)` |

## Request Specifications

Each request used `Use case: stylized-concept`, a single isolated transparent
Factorio entity sprite, a square canvas, upper-left lighting, industrial
pre-rendered 3D styling, no lettering/watermark/floor, and no external shadow.
All specified an elevated south-facing orthographic camera with **no yaw**,
horizontal front edges, vertical projected side edges, no diamond/isometric
rotation, a compact shallow 3x3 square footprint, full-object framing with
small transparent margins, and readability at 96 pixels wide.

- Compute: "weathered off-white spacecraft metal, dark graphite server racks,
  cyan tiny status lights and copper coolant pipes"; "low rectangular compute
  enclosure with three visible server banks, shallow height, no tall tower";
  explicitly not a solar panel.
- Radiator: "three broad banks of silver-grey parallel cooling fins with dark
  gaps, copper coolant header pipes across the front and rear, weathered
  off-white squared frame, small orange thermal couplings"; explicitly not blue
  photovoltaic cells or a solar panel.
- Solar: "Three broad banks of deep navy-blue solar cells with clear bright
  blue fine grid, weathered off-white low metal frame, gold busbars and small
  gold connectors"; explicitly distinct from radiator/server art, no large
  wings, satellite, or poles.

These are request specifications, not claims of exact camera geometry inferred
from the generated raster. Native visual acceptance is handled separately.

## Crop Mapping And Integration

`scripts/build-bitermotors-art.py::build_orbital_entity_art` crops each retained
master to the above alpha bounds, proportionally resizes to **480 pixels wide**
using Lanczos, then centers it on a transparent **512x512** canvas. It preserves
the generated alpha channel, including soft edges; no chroma-keying, background
painting, alpha replacement, or additional shadow is applied. The threshold is
only used to select the crop rectangle. Crop heights after resizing are 471,
468, and 458 pixels respectively (compute, radiator, solar).

World output mapping for each slug is
`mod/bitermotors_0.1.1/graphics/entity/<slug>/<slug>.png`.
Icons are derived from the same normalized world art, fitted inside 218 pixels
on transparent 256x256 canvases, and saved at
`mod/bitermotors_0.1.1/graphics/icons/<slug>.png`.

`data.lua` uses `generated_entity_animation` for the core and
`generated_entity_picture` for radiator/solar, all at **scale 0.2**:
480 visible pixels become **96 base-zoom pixels / three tiles**. The full canvas
renders at 102.4 pixels; sprite height includes the machinery height. Core keeps
the existing animation helper's `{0, -0.2}` shift; pictures use `{0, 0}`.
The core is a single static frame with painted cyan lights, not a moving fan or
working-state light overlay. Existing terrestrial animations are untouched.
Footprints, power, heat, recipes, and runtime logic are unchanged by this art pass.

To rebuild only these six derivatives without regenerating old animations:

```bash
python3 -c 'import runpy; m = runpy.run_path("scripts/build-bitermotors-art.py"); m["build_orbital_entity_art"]()'
```

Focused tests reproduce derivatives in a temporary directory, without modifying
the assets frozen for native QA. PNG shape/alpha/hash tests are not a substitute
for native visual QA.

## License

These are AI-generated project artwork, not packaged vanilla solar-panel art.
They follow the repository's original-media policy in `ASSET-LICENSE.md`
(all rights reserved; source-code MIT does not apply to artwork). This records
project licensing intent, not a legal determination of copyrightability of
AI-generated output. Wube's Factorio assets and trademarks remain excluded as
described in `ATTRIBUTION.md` and `ASSET-LICENSE.md`.
