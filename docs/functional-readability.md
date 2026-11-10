# Functional Artwork And UI Readability

Completed 2026-11-10 on Factorio 2.1.24, build 87808, mac-arm64 Space Age.
Development evidence contains ending spoilers.

## Changes

- Orbital Compute Cluster: compact, axis-aligned server banks rather than a
  diagonally projected ground building. Radiators use grey fins/copper piping;
  Solar Wings use blue cells/gold busbars. All retain 3x3 footprints, powers,
  costs and thermal behavior. Visible sprite width is 96 base pixels.
- Matching item icons and deterministic alpha-preserving build derivatives.
  See [generation and licensing provenance](orbital-art-provenance.md).
- Manufacturer inspectors wrap native label styles and have a bounded vertical
  scroll pane. Recipe, craft progress and inventory duplicates are removed.
- Committed Model crafts say the payload is committed, rather than asking for
  replacement inputs. Selected compute recipes determine actual displayed rates;
  an empty recipe selection no longer fabricates a default rate.
- Final payload guidance is hidden until unlocked; payload tooltips are retained.
  Logistic System is not advertised before its prerequisites are researched.
- Populated Progress frames are explicitly recentered. The native test caught
  a real case where the frame grew downward from its earlier short position.
- The Grid-scale Dataset recipe uses a plural label. The orbital build guide
  now shows the current 33.33/6.67-second times, not superseded 100/20-second times.

## Graphical Checks

An isolated graphical client loaded a copied native-player save and a dedicated
visual helper. Only that disposable client was restarted. No live player/world
was moved, restarted or replaced. This supplied scene is not campaign evidence.

| Check | Evidence |
| --- | --- |
| Distinct silhouettes and footprint use, zoom 1.5 | [Close render](readability/orbital-close.png) |
| Distant readability, zoom 0.65 | [Far render](readability/orbital-far.png) |
| Night rendering | [Night render](readability/orbital-night.png) |
| Early Progress hides future economy/compute details | [Early panel](readability/progress-early.png) |
| Native committed-input inspector, no reload-input request | [Assembly inspector](readability/assembly-inspector.png) |
| Centered final-stage Progress, banked work and payload state | [Assembly Progress](readability/progress-assembly.png) |

GUI captures use the real 1920x1022 display resolution at 100% GUI scale.
Artwork captures explicitly use 0.65/1.5 screenshot zoom at 1280x800. These are
native renders, not composited mockups. Dark unlit machines remain dark at night,
as in vanilla; no free lighting or power effect was added. Remote-view chrome
was checked in the isolated platform scene. This is not a complete matrix of
all resolutions, GUI scales or simultaneous multiplayer clients.

The reproducible scene logic is in
`scripts/fixtures/visual-readability-control.lua`; install it only in a
disposable helper named `bitermotors_smoke` to enable the guarded visual fixture
milestone hook. `/bm-visual` supports early, core, assembly, progress, overview,
far, night and capture. It deliberately supplies hardware, research and final
payload. Never install this helper in a real campaign.

## Native Qualification

Exact candidate ZIP SHA-256:
`f0bb344d843b54aec3aeb55fd5400933a8eebcc5431ffa89429c4bd4b2b1349d`.
Lua/source fingerprint:
`fba062bcbde0c52bf155cc2ff881f666113faef33f38733eb4a56aa9c2429bf3`.

Full-mod native smoke and progressed-save GUI smoke pass on that archive.
The GUI smoke's profit assertion was corrected to read the native business
profit ledger, not all Dollar production (which includes non-profit inflow).
Both complete physical ending routes were rerun, including partial payload
and victory reloads. Their time, money, launches and 20,000-Dataset consumption
are unchanged; refreshed source-bound evidence is linked from the
[pacing freeze](endgame-pacing.md). This does not requalify multiplayer or replace
the remaining release soaks and clean-install tests.
