# Orbital Logistics Budget

Numerical results: [measured report](orbital-logistics-measured.md),
[modeled budget JSON](orbital-logistics-measured.json), and
[compact native summary](orbital-platform-measurements.json).
[Synthetic frontier rates](orbital-frontier-example.json) cover every non-Dollar
joint frontier item and are not measured campaign production.

## Status And Scope

`scripts/model_orbital_logistics.py` is a pure budgeting/report layer over the
existing native economy catalog, research, recipe expansion and business model.
It changes no gameplay, Lua, prototypes or existing models. **Campaign pacing is
unqualified.** No native throughput or transit measurement is invented here.
Synthetic test layout counts and measurements are arithmetic fixtures only.

The chapter starts before Autonomous Logistics, after earlier EV and terrestrial
research/factory construction. It includes the remaining five research projects
(four without optional Hyperscale), terrestrial research Tokens, orbital compute,
the physical Model Rack, platform hardware, staged rockets, one new silo and one
new landing pad. Earlier vanilla technology and existing ground manufacturing and
power infrastructure are assumed available, not costed as new construction.

The script can run without layout or measurement inputs. Without layouts,
hardware/rocket costs are absent, material and cash totals are **partial**, and
finite-market funding sufficiency is `null`. Without measurements, throughput
projections and transit are explicitly unqualified. An ideal prototype clock is
not measured/native throughput and is never actual player time.

## Commands

```sh
python3 scripts/model_orbital_logistics.py
python3 scripts/model_orbital_logistics.py --layouts /tmp/layouts.json --json
python3 scripts/model_orbital_logistics.py \
  --layouts /tmp/layouts.json --measurements /tmp/measurements.json \
  --frontier-rates /tmp/frontier-rates.json --json --output /tmp/budget.json
python3 scripts/model_orbital_logistics.py \
  --layouts /tmp/orbital-layout-1.json --layouts /tmp/orbital-layout-4.json \
  --layouts /tmp/orbital-layout-8.json --layouts /tmp/orbital-layout-12.json \
  --measurements /tmp/raw-case/bitermotors-platform.jsonl \
  --measurements /tmp/dataset-case/bitermotors-platform.jsonl --json
python3 -m unittest tests.test_orbital_logistics_model
python3 -m unittest tests.test_orbital_platform_validation
python3 scripts/check_orbital_platform.py /tmp/native-case/bitermotors-platform.jsonl \
  --catalog docs/economy-prototypes.json --expected-source-sha256 '<native-source-sha256>'
```

`--catalog` selects a captured economy catalog. The CLI refuses a stale catalog
source hash. The pure `analyze(catalog, manifest=None, measurements=None,
frontier_rates=None)` function returns freshness errors rather than reading or
writing files itself. Its output is deterministic for the same inputs/source.

## Layout Interface

Layout schema 1 is a cumulative, retained platform hardware manifest:

```json
{
  "schema": 1,
  "stages": [
    {"cores": 1, "payload": {}},
    {"cores": 4, "payload": {}},
    {"cores": 8, "payload": {}},
    {"cores": 12, "payload": {}}
  ]
}
```

The empty mappings above are structural placeholders, not valid layouts. Replace
each with concrete item/count totals from the layout fixture. Every stage must
include its exact cumulative core count, one starter pack, shipped foundation,
solar and radiators. Include all physical I/O hardware: belts, inserters and any
other construction cargo. Counts must be nonnegative integers and cannot decrease.
This interface describes one growing platform, not four independently started
platforms. Native foundation supplied by the starter is not shipped foundation.

Alternatively, repeat `--layouts` for the four canonical exports written by
`platform-control.lua`, or provide a collection accepted by
`render_orbital_layout.read_layouts`. The CLI reuses that reader and validator,
sorts by core count, strips fixture operating Dollars and adds the one native
starter pack omitted from each exported `layout.manifest`. Exported foundation
is already the actual `foundation_added`, not a guessed tile count. Geometry
hashes exclude recipe/role metadata so raw and Dataset rehearsals of the same
physical layout can be reconciled.

Exclude fixture-injected inventories, supplied EEIs, operating Dollars and the
final Model Rack from `payload`. The budget adds staged operating Dollars and one
final Rack itself. Unknown cargo needs native item weights/stack sizes in the
catalog; it is not silently assigned a mass or ignored. Concrete hardware counts
do not alone qualify power sufficiency, actual tile occupancy or working I/O.

The layer differences adjacent manifests, projects conservative single-item rocket
loads separately per stage, and obeys both mass and the smaller native
rocket/ascent-pod inventory limit. It charges rocket-part ingredients once for
every modeled uplift. Model descent is not another manufactured rocket.

**Packing is a modeling policy, not a statement of observed native behavior.**
The fixture may uplift mixed cargo and partial loads. Its measured rockets belong
to an independently started platform with finite fixture operating Dollars, not
the budget's cumulative campaign ramp. `native_observations.launch_comparisons`
keeps actual fixture flights beside a single-item projection for exactly that
fixture manifest. Neither replaces the campaign count in `hardware.rockets`.
Do not sum independent 1/4/8/12 fixture launches to cost a growing platform, or
subtract mixed-packing differences as if they proved campaign rocket savings.

Rocket-part material costs and silo timing in the budget use its projected
single-item count throughout. The silo part-crafting lower bound is conditional
on that policy, not a universal lower bound over possible cargo packing. A
serialized transit projection likewise uses that modeled count and an explicit
per-flight delay assumption; real fixture delays stay separately observed.

Both cases cost the complete 12-core hardware manifest. The non-taxi case uses
Grid-scale/8 from 10M to 100M and Grid-scale/12 afterward; this splits the same
required native work and Dollars, not extra research or a free fourth recipe.
Its unchanged old minute business simulation remains an ideal 8-core sensitivity
and is not used for the physical compute projection. Early raw-equivalent bands
are converted to native compact Dataset batches; their time, cash and equivalent
work are preserved, while batch granularity and physical shipping differ.

## Measurement Interface

Schema 1 accepts normalized native fixture observations:

```json
{
  "schema": 1,
  "source_sha256": "catalog source_sha256",
  "layouts_sha256": "fingerprint(manifest)",
  "evidence": "path or identifier of native fixture report",
  "runs": [],
  "transit": null
}
```

Each `runs` entry contains `cores` (1/4/8/12), `recipe` (exact native orbital
recipe name), `elapsed_ticks` (positive advancing game ticks), and
`completed_batches` (nonnegative native recipe completions, not output stack
counts). `fingerprint(manifest)` hashes sorted compact JSON, including metadata.
Do not hash pretty-printed file bytes. The source hash must match the catalog and
the layout hash must match the exact input manifest. Duplicate recipe/layout
samples and impossible native batch rates are rejected. All measurements in unit
tests are synthetic; passing tests does not produce qualification evidence.

Rates use 60 game ticks per simulated second, not benchmark wall time. Each sample
applies only to its exact recipe/layout pair; missing pairs stay unqualified.
A zero-completion sample does not fall back to ideal throughput. A projected band
duration uses native sample rate but remains a **modeled projection**, not measured
end-to-end chapter duration. A source/layout match is provenance checking, not
independent verification that a fixture ran correctly.

Optional `transit` contains `uplift_seconds_per_rocket` and
`model_return_seconds`, both nonnegative simulated seconds measured separately
from rocket-part assembly. The report multiplies uplift delay by rocket count
under an explicitly serialized, identical-flight assumption. It does not invent
an additional ascent delay when native delivery occurs in the same tick, nor
schedule rocket manufacturing/flight overlaps. Omit `transit` when unmeasured.

The CLI also accepts repeated `--measurements` paths to complete native
`bitermotors-platform.jsonl` reports. It reuses
`check_orbital_platform.read_report` and `validation_support.check_report` to reject
failed, truncated or incomplete reports and reconcile all eight lifecycle rows.
The CLI supplies the native catalog for independent cargo mass/stack-slot
recomputation. It selects exactly one
`measured_passed` row per report, checks the concrete manifest and exported
geometry (when available), and maps `measured_ticks` and `completions` directly.
The sample interval is `tick - operation_tick`, including I/O drain and fixture
checkpoint/reload simulation ticks, not just first-to-last completion time.

Full measured rows remain in the in-memory `native_observations.fixture_rows`, including
native production, physical returns, per-core counts, shipments, built entities,
solar, cooling/power samples and explicit fixture limits. Native fixture
assertions and the parent validator remain responsible for mechanical
qualification; the budget adapter does not replace engine execution. Serialized
reports omit raw fixture snapshots. `--summary-json` writes small native counters,
source/geometry identities, and first/last completion and midpoint observations.
Full-window/drain and startup-to-midpoint extrapolations are both finite-window
sensitivities, not steady plateaus, confidence intervals or actual campaign time.

`uplift_observations` preserves each shipment's actual delivery delay and the
reported rocket/part counts. Same-tick delivery remains zero. These samples do
not manufacture a Model-return delay or automatically become an average
serialized-flight assumption. An explicit normalized `transit` remains required
for the full transit projection described above.

The raw-Token `raw_baseline` case deliberately has less returned output than
produced output. Its rates and physical backlog are preserved, but it is **not**
used for practical compute-duration projections. Dataset samples apply only to
their exact recipe/core pair; Hyperscale Dataset throughput is not silently
relabelled as Cluster Token throughput.

If a fixture does not record a mod source hash, its reports are accepted
as source-unbound observations and explicitly marked **unqualified source
provenance**, rather than assigned the current catalog hash as if it were
measured. Source-unbound samples do not produce native-rate duration projections.
If the fixture records `row.source_sha256` on its measured row, that hash is
preserved and must match the catalog. Hashes recorded elsewhere in the same
report must agree, and multiple native reports must agree on source provenance.
Native output amounts, Dollar ingredients and cycle ticks are checked against
the catalog when the fixture supplies its batch contract. Native observations
may be supplied while campaign pacing remains unqualified.

New compact orbital recipe variants can be observed when present in the catalog
with the native orbital crafting category and Token/Dataset output. They retain
their exact recipe identity; they are not automatically substituted into the
campaign plan or used to qualify a different recipe's throughput. Unknown or
non-orbital variants are rejected. A zero-completion sample stays unqualified.

## Joint Material And Cash Accounting

The budget expands hardware, launch ingredients, all selected research science,
finite battery-sales stock, sales offices, fleet and depots **together** through
the existing `supply_bill` graph. Native clean chemistry routes and co-product
crediting are reused. Science is not treated as free merely because the old
business model accepted a science-sets/minute input.

`joint_material_bill.supplies` is the one manufacturing frontier. Processing units
(blue circuits) remain a frontier input, so hardware, rockets, science and business
stock all draw from one shared blue-circuit allocation. Do not add the old model's
hardware bill or science bill to this joint bill again. Material Dollars plus
research/compute Dollars form `total_before_recurring_wear`; fleet capital from
the old cash simulation is not charged a second time.

`--frontier-rates` accepts an item-to-sustained-units/minute JSON mapping. These
are explicit **assumptions**, not native throughput evidence. Demand/rate yields
per-item lower bounds; the maximum known bound identifies a frontier bottleneck.
Unrated items remain listed. Zero, negative and nonfinite rates are rejected.
Rates must describe simultaneously sustainable outputs, not mutually exclusive
peak rates sharing upstream inputs. Even complete frontier rates do not qualify
assembly, build, lab or cargo schedules.

## Business Comparison And Limits

- Modest recurring: ten settlements, 2,000 population, 500 remaining battery
  buyers, one office, one depot, 120 allocated fleet, 2,000 opening Dollars.
  The native 5,000 consumer-sales taxi gate is explicitly assumed already met;
  ten settlements alone do not establish eligibility.
- Finite non-taxi: ten settlements, 2,000 population, 1,000 remaining battery
  buyers, one office, no depot/fleet, 2,000 opening Dollars; skips Hyperscale but
  retains required Grid-scale research. Buyers and revenue never replenish.
- Both reuse native adoption/referral rules and current fleet/customer capacity
  policy. The business simulation remains an ideal-input sensitivity: available
  hardware and its science rate are not qualified factory capacities.
- The joint bill conservatively buys all remaining battery-sales inventory and
  the specified business capacity. No opening hardware/material inventory is
  credited. Finite revenue is a ceiling, not immediate available cash.
- `finite_funding_gap` compares that ceiling and opening wallet with the bill.
  A gap proves those finite sales cannot fund it under the assumptions; no gap
  does not prove timely financing or successful construction.
- `steady_service_hours_lower_bound` divides the gap by the existing native-policy
  net taxi rate. It assumes immediate full-fleet service and does not replace the
  separate ideal-input minute simulation, which models incremental fleet startup.
- Native business wear is amortized in Dollars. Replacement fleet manufacturing
  materials, infrastructure power, lab capacity, construction, travel, optional
  purchases, terrestrial failed runs and uncertain cargo behavior are not included.
  Do not call the result a complete resource or elapsed-time forecast.

Independent manufacturing, compute, cash, silo and transit clocks must not simply
be added: real overlap and prerequisite dependencies need a separate schedule.
Neither the roadmap's 4-6 active-hour goal nor an actual player's time is qualified
by this report. No gameplay tuning is performed or recommended from missing data.
