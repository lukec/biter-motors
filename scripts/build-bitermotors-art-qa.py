#!/usr/bin/env python3
"""Generate the static Biter Motors artwork QA and review index."""

from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "art/bitermotors-qa"
GRAPHICS = ROOT / "mod/bitermotors_0.1.1/graphics"

ENTITIES = [
    ("Sales Office", "sales-office/sales-office.png", "sales-office.png", 3, 512, 0.19, "generated-final"),
    ("EV Charging Station", "ev-charging-station/ev-charging-station.png", "ev-charging-station.png", 2, 512, 0.14, "aligned-final"),
    ("EV Charging Station V2", "ev-charging-station-v2/ev-charging-station-v2.png", "ev-charging-station-v2.png", 4, 512, 0.26, "aligned-final"),
    ("V3 Rapid Charger", "ev-charging-station-v3/ev-charging-station-v3.png", "ev-charging-station-v3.png", 5, 512, 0.35, "aligned-final"),
    ("V4 Solar Charging Hub", "ev-charging-station-v4/ev-charging-station-v4.png", "ev-charging-station-v4.png", 6, 512, 0.38, "aligned-final"),
    ("Biterfactory", "biterfactory/biterfactory.png", "biterfactory.png", 9, 1024, 0.325, "aligned-final"),
    ("Biterfactory V2", "biterfactory/biterfactory-v2.png", "biterfactory.png", 9, 1024, 0.325, "aligned-final"),
    ("High-density Solar Panel", "high-density-solar-array/high-density-solar-array.png", "high-density-solar-array.png", 3, 512, 0.19, "generated-final"),
    ("Grid Battery", "grid-battery/grid-battery.png", "grid-battery.png", 2, 512, 0.14, "aligned-final"),
    ("Terrestrial Datacenter", "terrestrial-datacenter/terrestrial-datacenter.png", "terrestrial-datacenter.png", 6, 512, 0.36, "generated-final"),
    ("Bitertaxi Depot", "bitertaxi-depot/bitertaxi-depot.png", "bitertaxi-depot.png", 8, 512, 0.48, "aligned-final"),
    ("Planetary Grid Controller", "planetary-grid-controller/planetary-grid-controller.png", "planetary-grid-controller.png", 3, 512, 0.19, "aligned-final"),
]

ANIMATIONS = [
    ("Sales Office working beacon", "sales-office-status-green.png", 64, 64, "Working"),
    ("Sales Office stopped beacon", "sales-office-status-red.png", 64, 64, "Stopped or blocked"),
    ("Charger stall idle", "charger-stall-idle.png", 32, 32, "Unused"),
    ("Charger stall partial", "charger-stall-medium.png", 32, 32, "Moderate utilization"),
    ("Charger stall full", "charger-stall-full.png", 32, 32, "Near capacity"),
    ("Charger stall overload", "charger-stall-overload.png", 32, 32, "Underserved customers"),
    ("Charger stall charging", "charger-stall-charging.png", 32, 32, "Physical charging visit"),
    ("Biterfactory V1 production line", "biterfactory-v1-activity.png", 512, 512, "Crafting only"),
    ("Biterfactory V2 structural_casting line", "biterfactory-v2-activity.png", 512, 512, "Crafting only"),
    ("Biterfactory loading bays", "biterfactory-loading-lights.png", 512, 128, "Crafting only"),
    ("Datacenter cooling fans", "datacenter-cooling-fans.png", 128, 64, "Compute active"),
    ("Bitertaxi dispatch lights", "bitertaxi-dispatch-lights.png", 128, 64, "Fleet allocated"),
    ("Grid charge stages", "grid-charge-stages.png", 128, 128, "Charging only"),
    ("Grid Battery charging", "grid-battery-charge.png", 512, 512, "Cyan charge sequence"),
    ("Grid Battery discharging", "grid-battery-discharge.png", 512, 512, "Amber discharge sequence"),
]

VEHICLES = [
    ("Cybertrain", "battery-cybertrain/renders/cybertrain-master.png", "cybertrain.png", "Dedicated 64-direction rail sprite"),
    ("Cybertrain Charging Stop", "battery-cybertrain/renders/charging-stop-master.png", "cybertrain-charging-stop.png", "Dedicated four-direction rail-aligned structure"),
]


def rel(path: Path) -> str:
    return "../../" + path.relative_to(ROOT).as_posix()


def review_controls(asset_id: str) -> str:
    return f"""
      <div class="review" role="group" aria-label="Review {html.escape(asset_id)}">
        <button type="button" data-review="approve" data-id="{html.escape(asset_id)}">Approve</button>
        <button type="button" data-review="revise" data-id="{html.escape(asset_id)}">Revise</button>
      </div>"""


def entity_cards() -> str:
    cards = []
    for index, (name, entity_path, icon_path, tiles, source_width, sprite_scale, status) in enumerate(ENTITIES):
        footprint = tiles * 32
        sprite_width = round(source_width * sprite_scale)
        asset_id = f"entity-{index}"
        cards.append(f"""
    <article class="asset entity-card" data-kind="entities" data-id="{asset_id}">
      <header><img class="mini-icon" src="{rel(GRAPHICS / 'icons' / icon_path)}" alt=""><div><h2>{html.escape(name)}</h2><p>{tiles}x{tiles} tiles | {html.escape(status)}</p></div></header>
      <div class="entity-stage terrain-grass" style="--footprint:{footprint}px;--sprite:{sprite_width}px">
        <div class="footprint-grid" aria-hidden="true"></div>
        <img class="entity-sprite" src="{rel(GRAPHICS / 'entity' / entity_path)}" alt="{html.escape(name)} entity sprite">
      </div>
      <div class="belt" aria-label="Inventory and belt scale">{''.join(f'<img src="{rel(GRAPHICS / "icons" / icon_path)}" alt="">' for _ in range(5))}</div>
      {review_controls(asset_id)}
    </article>""")
    return "".join(cards)


def icon_cards() -> str:
    cards = []
    for index, path in enumerate(sorted((GRAPHICS / "icons").glob("*.png"))):
        name = path.stem.replace("-", " ").title()
        asset_id = f"icon-{index}"
        cards.append(f"""
    <article class="asset icon-card" data-kind="icons" data-id="{asset_id}">
      <header><h2>{html.escape(name)}</h2><p>256px normalized master</p></header>
      <div class="icon-scales"><img class="i64" src="{rel(path)}" alt="{html.escape(name)} at 64 pixels"><img class="i32" src="{rel(path)}" alt=""><img class="i20" src="{rel(path)}" alt=""></div>
      <div class="belt">{''.join(f'<img src="{rel(path)}" alt="">' for _ in range(5))}</div>
      {review_controls(asset_id)}
    </article>""")
    return "".join(cards)


def vehicle_cards() -> str:
    cards = []
    for index, (name, preview_path, icon_path, status) in enumerate(VEHICLES):
        asset_id = f"vehicle-{index}"
        cards.append(f"""
    <article class="asset vehicle-card" data-kind="vehicles" data-id="{asset_id}">
      <header><img class="mini-icon" src="{rel(GRAPHICS / 'icons' / icon_path)}" alt=""><div><h2>{html.escape(name)}</h2><p>{html.escape(status)}</p></div></header>
      <div class="vehicle-stage"><img src="{rel(ROOT / 'art/blender' / preview_path)}" alt="{html.escape(name)} north-facing sprite"></div>
      <div class="belt" aria-label="Inventory and belt scale">{''.join(f'<img src="{rel(GRAPHICS / "icons" / icon_path)}" alt="">' for _ in range(5))}</div>
      {review_controls(asset_id)}
    </article>""")
    return "".join(cards)


def animation_cards() -> str:
    cards = []
    for index, (name, filename, width, height, trigger) in enumerate(ANIMATIONS):
        path = GRAPHICS / "animation" / filename
        asset_id = f"animation-{index}"
        cards.append(f"""
    <article class="asset animation-card" data-kind="animations" data-id="{asset_id}">
      <header><h2>{html.escape(name)}</h2><p>{html.escape(trigger)} | 8 frames</p></header>
      <div class="animation-stage"><div class="sprite-animation" style="--sheet:url('{rel(path)}');--fw:{width}px;--fh:{height}px"></div></div>
      {review_controls(asset_id)}
    </article>""")
    return "".join(cards)


def technology_cards() -> str:
    cards = []
    for index, path in enumerate(sorted((GRAPHICS / "technology").glob("*.png"))):
        name = path.stem.replace("-", " ").title()
        asset_id = f"technology-{index}"
        cards.append(f"""
    <article class="asset technology-card" data-kind="technology" data-id="{asset_id}">
      <header><h2>{html.escape(name)}</h2><p>Locally composed technology art</p></header>
      <div class="technology-preview"><img src="{rel(path)}" alt="{html.escape(name)} technology icon"></div>
      {review_controls(asset_id)}
    </article>""")
    return "".join(cards)


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {
        "entities": [entry[0] for entry in ENTITIES],
        "vehicles": [entry[0] for entry in VEHICLES],
        "icons": [path.name for path in sorted((GRAPHICS / "icons").glob("*.png"))],
        "animations": [entry[0] for entry in ANIMATIONS],
        "technology": [path.name for path in sorted((GRAPHICS / "technology").glob("*.png"))],
        "paid_generation_count": 3,
        "blender": {
            "installed": True,
            "break_even": "Worthwhile for directional drivable sprites; not worthwhile for icons alone.",
            "image_generation_estimate": "10-15 attempts for five coherent directional sheets after retries.",
            "local_pipeline_estimate": "One scripted camera/material rig plus five low-poly models; all rotations and recolors then render locally.",
        },
    }
    (OUTPUT_DIR / "art-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Biter Motors Artwork QA</title>
<style>
:root{{--ink:#e9edf0;--muted:#9ca7ad;--panel:#252729;--line:#454a4d;--orange:#f69a2b;--cyan:#45d5ec;--green:#7ed987;--red:#f07167}}
*{{box-sizing:border-box;letter-spacing:0}} body{{margin:0;background:#171819;color:var(--ink);font:14px/1.4 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}}
header.page{{padding:22px clamp(16px,4vw,48px) 14px;border-bottom:1px solid var(--line);display:flex;gap:18px;align-items:end;justify-content:space-between;flex-wrap:wrap}}
h1{{margin:0;font-size:28px}} .lede{{margin:4px 0 0;color:var(--muted);max-width:760px}} .summary{{font-variant-numeric:tabular-nums;color:var(--cyan)}}
.toolbar{{position:sticky;top:0;z-index:4;background:#1d1f20eF;padding:10px clamp(16px,4vw,48px);border-bottom:1px solid var(--line);display:flex;gap:8px;flex-wrap:wrap;backdrop-filter:blur(8px)}}
button{{border:1px solid #555b5f;background:#292c2e;color:var(--ink);padding:7px 10px;border-radius:4px;cursor:pointer}} button:hover,button.active{{border-color:var(--cyan);background:#30383a}} button[data-review="approve"].selected{{border-color:var(--green);color:var(--green)}} button[data-review="revise"].selected{{border-color:var(--red);color:var(--red)}}
main{{padding:18px clamp(16px,4vw,48px) 60px}} .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:12px}}
.asset{{background:var(--panel);border:1px solid var(--line);border-radius:6px;overflow:hidden}} .asset>header{{min-height:58px;padding:10px 12px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #3b3f41}} .asset h2{{font-size:14px;margin:0}} .asset p{{font-size:12px;color:var(--muted);margin:2px 0 0}} .mini-icon{{width:38px;height:38px;object-fit:contain}}
.entity-stage{{height:390px;position:relative;overflow:hidden;display:grid;place-items:center;background-color:#526b43;background-image:linear-gradient(#ffffff10 1px,transparent 1px),linear-gradient(90deg,#ffffff10 1px,transparent 1px);background-size:32px 32px}}
.entity-stage.terrain-concrete{{background-color:#77756c}} .entity-stage.terrain-dark{{background-color:#25292b}} .footprint-grid{{position:absolute;width:var(--footprint);height:var(--footprint);border:2px solid var(--cyan);background-image:linear-gradient(#45d5ec55 1px,transparent 1px),linear-gradient(90deg,#45d5ec55 1px,transparent 1px);background-size:32px 32px;opacity:.55}}
.entity-sprite{{position:absolute;width:var(--sprite);height:var(--sprite);object-fit:contain;image-rendering:auto}} body.show-bounds .entity-sprite{{outline:1px dashed var(--orange);background:#f69a2b10}}
.vehicle-stage{{height:260px;display:grid;place-items:center;background-color:#526b43;background-image:linear-gradient(#ffffff10 1px,transparent 1px),linear-gradient(90deg,#ffffff10 1px,transparent 1px);background-size:32px 32px}} .vehicle-stage img{{width:224px;height:224px;object-fit:contain}}
.belt{{height:64px;background:#111416;display:flex;align-items:center;justify-content:space-evenly;border-top:1px solid #3b3f41;border-bottom:1px solid #3b3f41;overflow:hidden}} .belt img{{width:42px;height:42px;object-fit:contain}}
.review{{padding:9px 10px;display:flex;gap:7px;justify-content:flex-end}} .review button{{font-size:12px;padding:5px 8px}}
.icon-scales{{height:150px;display:flex;gap:26px;align-items:center;justify-content:center;background:#1b1d1e}} .icon-scales img{{object-fit:contain}} .i64{{width:64px;height:64px}} .i32{{width:32px;height:32px}} .i20{{width:20px;height:20px}}
.animation-stage{{height:190px;display:grid;place-items:center;background:#111416}} .sprite-animation{{width:var(--fw);height:var(--fh);background-image:var(--sheet);background-size:calc(var(--fw) * 8) var(--fh);animation:play .9s steps(8) infinite;transform:scale(1.7);transform-origin:center}} @keyframes play{{to{{background-position-x:calc(var(--fw) * -8)}}}}
.technology-preview{{height:230px;display:grid;place-items:center;background:#191b1c}} .technology-preview img{{width:190px;height:190px;object-fit:contain}}
.section-title{{margin:28px 0 10px;font-size:18px}} .math{{margin-top:28px;border-top:1px solid var(--line);padding-top:20px;max-width:900px}} .math table{{width:100%;border-collapse:collapse}} th,td{{padding:8px;text-align:left;border-bottom:1px solid #3c4042}} th{{color:var(--cyan)}} code{{color:#ffd078}}
.hidden{{display:none}} @media(max-width:600px){{.entity-stage{{height:330px}}h1{{font-size:22px}}}}
</style>
</head>
<body>
<header class="page"><div><h1>Biter Motors Artwork QA</h1><p class="lede">Production index at entity footprint, inventory, belt, animation, and technology scales. Review decisions persist in this browser.</p></div><div class="summary" id="summary">0 approved / 0 revise</div></header>
<nav class="toolbar" aria-label="Artwork filters">
  <button class="active" data-filter="all">All</button><button data-filter="entities">Entities</button><button data-filter="vehicles">Vehicles</button><button data-filter="icons">Icons</button><button data-filter="animations">Animations</button><button data-filter="technology">Technology</button>
  <button id="terrain" title="Cycle entity preview terrain">Terrain</button><button id="bounds" title="Show transparent image bounds">Bounds</button><button id="copy" title="Copy review decisions">Copy review</button>
</nav>
<main>
<section class="grid" id="assets">{entity_cards()}{vehicle_cards()}{icon_cards()}{animation_cards()}{technology_cards()}</section>
<section class="math"><h2 class="section-title">Directional vehicle production math</h2><p>Biter Motors vehicle and battery art now uses a deterministic Blender pipeline. Directional sprites, shadows, chemistry variants, damaged packs, and inventory icons can be reproduced locally without additional image-generation calls.</p><p>Generated masters: <a href="../bitermotors-masters/final/sales-office.png">Sales Office</a>, <a href="../bitermotors-masters/final/terrestrial-datacenter.png">Terrestrial Datacenter</a>, and <a href="../bitermotors-masters/final/agi-model.png">AGI Model</a>.</p></section>
</main>
<script>
const key='bitermotors-art-qa-v1';const state=JSON.parse(localStorage.getItem(key)||'{{}}');
function renderState(){{document.querySelectorAll('[data-review]').forEach(b=>b.classList.toggle('selected',state[b.dataset.id]===b.dataset.review));const values=Object.values(state);document.querySelector('#summary').textContent=`${{values.filter(v=>v==='approve').length}} approved / ${{values.filter(v=>v==='revise').length}} revise`;localStorage.setItem(key,JSON.stringify(state));}}
document.querySelectorAll('[data-review]').forEach(b=>b.onclick=()=>{{state[b.dataset.id]=b.dataset.review;renderState()}});
document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{{document.querySelectorAll('[data-filter]').forEach(x=>x.classList.remove('active'));b.classList.add('active');document.querySelectorAll('.asset').forEach(x=>x.classList.toggle('hidden',b.dataset.filter!=='all'&&x.dataset.kind!==b.dataset.filter));}});
const terrains=['terrain-grass','terrain-concrete','terrain-dark'];let terrainIndex=0;document.querySelector('#terrain').onclick=()=>{{terrainIndex=(terrainIndex+1)%terrains.length;document.querySelectorAll('.entity-stage').forEach(x=>{{terrains.forEach(t=>x.classList.remove(t));x.classList.add(terrains[terrainIndex])}})}};
document.querySelector('#bounds').onclick=()=>document.body.classList.toggle('show-bounds');
document.querySelector('#copy').onclick=async()=>{{const rows=[...document.querySelectorAll('.asset')].map(x=>`- ${{x.querySelector('h2').textContent}}: ${{state[x.dataset.id]||'unreviewed'}}`);await navigator.clipboard.writeText('Biter Motors art QA\\n'+rows.join('\\n'));}};
renderState();
</script>
</body></html>"""
    document = "\n".join(line.rstrip() for line in document.splitlines()) + "\n"
    (OUTPUT_DIR / "index.html").write_text(document)
    print(OUTPUT_DIR / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
