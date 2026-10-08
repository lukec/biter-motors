# Native Orbital Entry Validation

Date: **2026-10-08**. Source: **Biter Motors 0.1.1**, fresh isolated worlds.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
Scope: slice 1 of the [orbital ending](../feature_specs/orbital_agi_ending.md).
Compact entry and genuine normal-quality uplift pass on source and the exact ZIP.
The replacement Model ending, orbital pause/resume, new tier yields, terminal
epilogue, final satellite artwork and campaign qualification remain open.

## Implemented Contract

| Hardware | Normal footprint | Operation | Native cargo weight |
| --- | --- | --- | ---: |
| Orbital Compute Cluster | 3x3 | 250 MW; 1 Dollar produces 10,000 Tokens in 20 seconds | 100 kg |
| Orbital Radiator | 3x3 | Cools one cluster on its own platform and force | 100 kg |
| Space Solar Wing | 3x3 | 20 MW nominal; 60 MW continuously in Nauvis orbit | 25 kg |

Five wings supply 300 MW for one 250 MW cluster. Cooling is a platform-local
capacity rule, not a heat/fluid simulation or a claim about real satellite
thermal engineering. Existing graphics are scaled/reused; dedicated satellite
art is a later slice.

The cluster recipe is **8 Datacenter Racks + 40 Low-density Structures +
12 LFP Battery Packs**. A wing uses **2 HD Panels + 10 blue circuits + 5
Low-density Structures + 2 High-energy Battery Packs**. Radiator inputs are
unchanged. Dollars now weigh **10 g**, and the AGI Model **1 kg**. Tokens remain
1 g and Datasets 1 kg. Runtime masses, rather than only optional prototype
fields, are exported into the refreshed [economy catalog](economy-prototypes.json).
The native rocket inventory has 20 slots, but its cargo pod has 10. The catalog
retains both sizes and limits shipments to the tighter ten-slot capacity,
confirmed in every actual launch report.

Orbital Infrastructure and the three compute scale technologies use appropriate
terrestrial science plus Dollars and Tokens, without white science. Research
costs, later output tiers and the old controller finale otherwise remain as
implemented until slice 2. Low power or missing cooling still scraps an orbital
batch today; this document does not claim the proposed banked-work policy exists.

## Player Entry

1. Build the native Rocket Silo, manufacture a starter pack and launch it to a
   stationary Nauvis platform. Native platform construction unlocks its technology.
2. Research Orbital AI Infrastructure using terrestrial Tokens, Dollars and
   red/green/blue/purple/yellow science. The starter does not require orbital compute.
3. Manufacture one cluster, one radiator and five wings on Nauvis. Request those
   items at the platform hub, together with foundation, belts, inserters and cash.
4. Set custom minimum payloads to **1 cluster, 1 radiator, 5 wings and 100 Dollars**.
   For the fixture's other cargo, use **50 foundation, 12 belts and 4 inserters**.
   Otherwise automatic rockets may wait for a full shipment despite supplied stock.
5. Place the hardware and feed Dollars from the hub into the cluster. Extract
   Tokens back to the hub and request them at a Nauvis Cargo Landing Pad.

Minimum payload is a **native platform request setting**, not an invented item
prototype property or a mod-owned rewrite of player request sections. See the
official [Space platform](https://wiki.factorio.com/Space_platform) and
[Rocket silo](https://wiki.factorio.com/Rocket_silo) mechanics.

## Genuine Uplift Fixture

`scripts/fixtures/uplift-control.lua` provides a bounded native chain:

- Supplies prerequisite research and ground ingredients/power, but leaves the
  native create-platform trigger and entry research unfinished.
- Manufactures the starter pack; actual silo rocket parts and a real starter
  launch create the hub and complete the native platform trigger.
- Consumes the full 1,500-cycle entry research in normal labs without white science.
- Manufactures the cluster, radiator, five wings, foundation, belts and inserters
  through their unchanged native recipes, then supplies the outputs to ground bots.
- Uses native platform requests, automatic launches and platform ghost construction.
  No platform inventory insertion, starter-pack application, real platform entity
  creation, scripted cargo pods, rocket-part writes or crafting-progress writes
  substitute for this chain.
- Computes one native Token batch using the shipped Dollar and only the five
  native solar wings for orbital power, returns it through hub/pad cargo pods,
  and writes a checkpoint for a separate-process reload.

The manifest is **one starter + 100 additional foundation + one cluster + one
radiator + five wings + 12 belts + four inserters + 100 Dollars**. At 50
foundation per rocket, this requires **nine separate-item automatic launches**,
not eight. The fixture expects 450 actual native rocket parts consuming 450
each of processing units, low-density structures and rocket fuel.

Ten spare foundation arrive with the native starter; the requests distinguish
those from the additional 100. Construction must consume exactly 100 additional
tiles, leaving the original ten. One compute completion must return 10,000
physical Tokens, earn exactly 10,000 equivalents and leave 99 physical Dollars.
These are acceptance assertions; see the run evidence below for qualification.

## Run Evidence

All runs use private temporary user directories and loopback sockets. The live
server, desktop client, installed mod and player save are unchanged.

| Check | Source | Exact ZIP | Scope |
| --- | --- | --- | --- |
| Broad prototypes/graphics/smoke | Pass | Pass | Current engine, recipes, reverse recipes, runtime smoke |
| Cooling/failure/reload | Pass | Pass | Zero/one radiator, force/platform isolation, native outages and exact recovery |
| AI accounting/reload | Pass | Pass | Native completions, quality, bonuses, real output extraction and conservation |
| Existing full delivery/finale | Earlier baseline | Pass | Compact-core extraction, native Dataset delivery and the old controller ending |
| New manufactured rocket uplift/return/reload | Pass | Pass | Actual manufacture, nine launches, construction, compute, return and separate reload |

Both uplift runs recorded the same native milestones:

| Milestone | Simulation tick |
| --- | ---: |
| Real starter deployment and native platform research | 15,049 |
| Entry research complete in labs | 123,059 |
| All ground hardware manufactured | 171,120 |
| Nine uplifts delivered; native construction complete | 264,780 |
| One computed batch fully returned to Nauvis | 527,880 |
| Separate-process reload assertions | 527,940 |

Reports confirm **450 native rocket parts**, exactly 450 each of the three
rocket ingredients consumed, **100 added foundation tiles**, all manifested
hardware built, **10,000 earned/physical Tokens** and **99 remaining Dollars**.
Reload checks the live earned ledger and the actual inventories, not only a
stored report. Assertion counters are cumulative and include repeated checks;
they are not independent test cases.

This deliberately basic belt/inserter layout uses the disclosed **+2 ordinary
inserter-capacity prerequisite** and takes about **146.6 simulation minutes**
overall. Returning the complete 10,000-Token batch takes about 73 minutes and
145 automatic partial cargo pods. That is not compute time or a campaign
estimate: basic extraction is the bottleneck. Practical layouts should use
faster/bulk inserters, and only research-needed Tokens need return immediately.
Later Datasets avoid moving every Token equivalent as an individual belt item.
Include upgraded I/O in the final blueprint/pacing qualification; do not treat
the ideal-input economy model as a transport-throughput measurement.

Local retained artifacts: source uplift `/tmp/bitermotors-uplift.Cqio1o`, ZIP
uplift `/tmp/bitermotors-uplift.2pOlrI`, source smoke
`/tmp/bitermotors-validate.I3oADe`, ZIP smoke
`/tmp/bitermotors-validate.JwVHJs`, source/ZIP cooling
`/tmp/bitermotors-cooling.UWuXI3` and `/tmp/bitermotors-cooling.oHAv7f`,
source/ZIP accounting `/tmp/bitermotors-ai.tlQd4J` and
`/tmp/bitermotors-ai.nxlLOs`, and existing-finale ZIP delivery
`/tmp/bitermotors-delivery.rJPOBP`. These temporary paths are local evidence,
not files shipped in the archive or required by another checkout.

Exact archive SHA-256:

```text
7a39d9e4a5208fcb5d8df1209cc2f59b29a386722e0ba36a6bd3a486d56c30dc
```

The new harness rejects incomplete/out-of-order reports, canceled or fabricated
shipments, overweight cargo, incorrect minima, missing actual consumption,
failed conservation, nonadvancing reloads and zero-exit Lua errors. Its
evidence-only mode validates a report without starting the engine.

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
scripts/validate-bitermotors-uplift.sh
scripts/validate-bitermotors-cooling.sh
scripts/validate-bitermotors-ai.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-entry
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-entry/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-uplift.sh
```

## Evidence Limits

Only the normal-quality first-cluster uplift is covered here. Ground industry,
raw-material extraction, earnings, prerequisite science production, silo
construction and land power are supplied. Native crafting, research, rocket
parts, launches, construction and cargo return are not accelerated by recipe
changes; `game.speed` changes wall time only. This is not a measured campaign
duration, a twelve-cluster blueprint, all-quality qualification, multiplayer
testing, a long soak, Model cargo/activation or approval of the reused artwork.

The remaining ending slice must bank orbital work, retune scale tiers, create
the Model in orbit, return and activate it on Nauvis, remove the obsolete
controller/capital path and then requalify victory and persistence. Do not start
the final acceptance playthrough on the strength of this first-cluster fixture.
