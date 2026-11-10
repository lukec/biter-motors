# Endgame Pacing Freeze

Development evidence, with ending spoilers. This is an engineering rehearsal
and a pacing target, not a claim that a natural campaign has been completed.

## Starting Point

The sample is Luke's named `Biter-Motors-recovered-after-worm-fix-20260806.zip`,
at about 32.9 played hours. A later autosave has the same simulation tick,
production history and stock, only more played time. Both originals were hashed;
only disposable copies were loaded. No client, live server or original save was
changed. The native engine was **2.1.24, build 87808, mac-arm64, Space Age**.

The [compact observations](endgame-save-baseline.json) retain the save and
sampling hashes, normal-quality accessible stock, native production counters
and research state. The ten-minute advancing run supplied no items, power,
research or business income and ran no external automation. Current-mod
configuration reconciliation ran on this older save, so customer counts after
reconciliation are not an untouched historical observation.

| Starting resource | Observed |
| --- | ---: |
| Usable Dollars, including labs | 4,535 |
| Blue circuits in accessible stock | 693 |
| Rocket fuel | 2,521 |
| Low-density structures | 908 |
| Datacenter Racks | 54 |
| Existing terrestrial datacenters | 1 |
| Rocket Silo research | Already completed |
| Built rocket silos / platforms | 0 / 0 |
| Blue circuits produced | 52.7/min |
| Low-density structures produced | 76.1/min |
| Dollars produced / consumed | 128.3 / 69.0 per minute |
| Usable wallet increase | 46.7/min |
| Immediately waiting Grid Battery buyers | 447 |

The [one-hour follow-up](endgame-save-hour-check.json) supplied nothing and
passed on the preceding pacing archive. Its usable wallet grew **4,535 to 9,528**;
gross output averaged 155.45 Dollars/min and 103.95 blue circuits/min. That
window included the original queue completing Long-range Battery level 1 and
then running out of research; science production was idle at the end. These
are demand-dependent observations, not permission to spend every gross circuit
on two tasks at once. The budget deliberately keeps the slower initial sample.

That longer run first exposed a genuine runtime crash after about 28 minutes:
nonzero charger quality/battery bonuses called an unavailable `table.deepcopy`.
The production fix copies the flat configuration explicitly. A Lua regression
executes every charger tier across five quality levels and three battery levels
without that helper; the repeated full hour passes the formerly crashing upgrade.

Gross production is not spare capacity. In particular, nearly all observed blue
circuits already have destinations. The endgame needs a deliberate allocation
away from optional stockpiling/infinite research, or a modest expansion of that
line. Rocket fuel was idle with substantial stock, not proven to have zero
production capacity. Purple science was output-blocked; its zero observed rate
is not a recipe or progression defect. No extra terrestrial AI plant or giant
new ground solar field is required to activate the returned Model.

## Frozen Numbers

Luke rejected the preceding roughly six-hour forecast as too optimistic about
human building time. The revised target is **roughly four active hours** from
this established save's stage. Do not call an automated rehearsal player time.
The recommended native route plus entry research now takes about 3 h 15 min,
leaving roughly 45 minutes for player construction and troubleshooting inside
that target. This is an allowance, not a guarantee; disconnected supply lines,
defence, redesign and exploration can still take longer.

| Orbital research | Previous freeze: cycles / Dollars | Frozen: cycles / Dollars |
| --- | ---: | ---: |
| Infrastructure | 1,000 / 1,000 | 500 / 500 |
| Cluster Training | 600 / 600 | 300 / 300 |
| Grid-scale Energy | 900 / 900 | 450 / 450 |
| Hyperscale, optional | 1,200 / 2,400 | 600 / 1,200 |
| Total, after Autonomy | 3,700 / 4,900 | 1,850 / 2,450 |

Each cycle still uses the five terrestrial science types and AI Tokens. No white
science, removed-planet material or new currency was added. Orbital batches now
take one third as long: 10 recipe-seconds / about 6.67 normal seconds, with the
entry five-Dollar Dataset taking 50 recipe-seconds / about 33.33 normal seconds.
Per-batch output and Dollar costs, 250 MW core load, five Solar Wings and one
short-loop Radiator per core remain unchanged. The earned billion-equivalent
gate, physical **20,000 Datasets plus
one Rack**, one-minute orbital assembly and 30-second existing-datacenter
activation remain unchanged. Hyperscale is the recommended shorter ending;
stopping at Grid remains possible but takes longer and uses more operating cash.

The [stock-aware budget](endgame-save-budget.json) excludes completed research,
credits extractable normal-quality stock once before expanding recipes, and
combines science, hardware and rocket materials into one shared supply bill.
It does not credit deployed solar equipment, arbitrary machine inputs, higher
quality as normal, or inaccessible items on belts/in flight.

The instant-upgrade Hyperscale floor is **8,131 Dollars**, versus **10,581**
under the preceding freeze. The qualified normal-logistics run instead
uses **8,806 Dollars from the sample's stage**, down from 11,228, including entry research,
continued older-tier computation during research, committed batches, native
lab rounding and two Dollars discarded by the fixture's recipe reconfiguration.
The usable starting stock leaves a **4,271-Dollar** gap. Already-eligible battery
buyers represent **8,940 Dollars gross**, so another wave of nest expansion is
not required just to cover that project gap. This is a finite ceiling, not
immediate revenue or funding for unrelated spending.

With the measured final I/O layout and **all 2,250 natively manufactured rocket
parts**, including the silo's 100 unused buffered parts, the joint remaining
bill needs **3,825 more blue circuits**, down from 5,157. At the slower 52.7/min
observation, that is a 73-minute gross-production lower bound, not spare-capacity time.
The existing **2,521 rocket fuel covers the entire recommended route**. The
model still expands all hardware/science jointly and does not allocate those
same circuits a second time. The conservative separate-item launch projection
is retained for comparison, not substituted for measured mixed-load part use.

The target is **roughly four focused active hours from an established factory at
this stage**, not from the crash landing. Research and hardware expansion can
overlap live computation, but do not assume perfect overlap or omit the explicit
player-work allowance. Manufacturing capacity, financing, research and compute
clocks overlap and must not simply be added.
The supplied-hardware rehearsal cannot qualify time spent designing a factory,
defending it, finding resources or correcting unrelated bottlenecks.

## Qualified Native Route

Both cases passed on the exact **0.1.1** archive, SHA-256
`f0bb344d843b54aec3aeb55fd5400933a8eebcc5431ffa89429c4bd4b2b1349d`.
The 2026-11-10 [readability pass](functional-readability.md) reran both routes
on this presentation-updated archive; measured pacing and costs are unchanged.
Compact source, fixture, runner, checker and report identities are retained in
the [Hyperscale](endgame-practical-hyperscale.json) and
[Grid-only](endgame-practical-grid.json) records. Raw logs and saves remain local.

| Case | Whole route | Dataset loading | Real launches | Orbital Dollars used | Later research Dollars |
| --- | ---: | ---: | ---: | ---: | ---: |
| Recommended Hyperscale | 2 h 59 min | 21.13 min | 43 | 6,353 | 1,953 |
| Optional Grid only | 3 h 36 min | 21.15 min | 49 | 10,374 | 756 |

The preceding qualified archive took 5 h 18 min / 7 h 7 min after the same
unlock (commit `26ecf90`). Merely halving compute durations produced a 3 h 30 min
Hyperscale route before entry research, leaving too little human-work allowance;
the final one-third-duration version is what is qualified here.

The clock begins **after Orbital Infrastructure research** and includes starter
uplift, native staged construction, the 1/4/8/12 compute ramp, scale research,
cash transport, final loading, assembly, return, activation and 40 seconds of
verified freeplay. Nine normal labs at the save's 2.5 speed modifier cap research
at 31.5 cycles/minute. The save's bulk-capacity bonus of nine is also matched.
Scale technologies finish through native research, not scripted unlocks.

Budget roughly **another 16 minutes for the 500-cycle entry research** at that
cap, giving about **3 h 15 min of machine-driven work** from the sampled stage.
The sample already has its required terrestrial Tokens. The recommended route
therefore leaves about **45 minutes below the four-hour player target**; the
slower Grid-only route leaves only about eight minutes and is not recommended
for that target. Neither figure is a measured human playthrough.

The archive, physical **20,000-Dataset consumption**, reused assembly core,
rocket-uplifted Rack, real Model cargo pod, existing 8 MW ground datacenter and
once-only victory all reconcile. Both cases reload a genuinely partial loading
inventory in a separate process, then reload victory and advance freeplay.
No orbital electrical interface, solar multiplier, injected Dataset/Token/Model,
post-bootstrap item transfer or earned-compute injection is allowed. Maximum
core temperature stays about 96.2 C, with no low-power, full-output or burnout
samples. These are normal-route checks, not a replacement for destructive
thermal qualification or simultaneous-multiplayer tests.

Native starter provenance is explicit: **100 prebuilt tiles plus ten loose
foundations**, observed immediately after deployment and checked against the
runtime prototype. Extra floor must equal rocket-delivered plus those ten,
minus hub leftovers. Parallel labs' small committed-pack overrun is bounded
per lab/technology and counted as actual expenditure, not silently refunded.

The preceding shorter-pacing archive also passed the full-mod smoke, native AI accounting,
production accounting, power-interruption recovery and the 20-phase thermal
hardening suite, including warmed 12/128-core arrays and separate-process
reloads. These thermal/accounting results remain historical qualification, not
a new run of those suites on the readability archive. Faster recipes exposed
two timing assumptions in test fixtures: progress
probes now scale with batch duration, and packaging waits for unrelated physical
bonus delivery before asserting no new compute. Neither repair supplies fresh
inputs or bypasses retained native progress. A regression preserves at least
40 minutes of player-work allowance below four hours for the reference route.

## Practical Logistics

Use the native-exported [cluster blueprints](orbital-platform-guide.md). Both
buses now use express belts. One yellow lane would take at least 44.4 minutes
to carry 20,000 Datasets; an express lane's corresponding floor is 14.8 minutes.
Neither number includes inserter limits, travel, the Rack or the assembly craft.
The final recipe's one-minute tooltip is not the entire loading operation.
These unstacked single-lane floors use the official
[yellow](https://wiki.factorio.com/Transport_belt) and
[express](https://wiki.factorio.com/Express_transport_belt) throughputs.

Start one cluster, build the next stage while its scale research runs, and
retain the archive in orbit. Return one Dataset for research and unpack it on
Nauvis; do not ship the whole archive down and then launch it again. Stop
unnecessary compute after the archive is sufficient. Before assembly, stop
Dollar input and use real belts/inserters to drain residual currency to the hub.
Use full bulk hands for payload input rather than the one-Dollar operating
hand. The [assembly overlay](../blueprints/orbital-model-assembly.txt) supplies
two hub/input arms and a return loop for items that pass a busy pickup. Without
that loop the first attempt stranded the last 16 Datasets at the far end.
The reference requires no quality items or module overclocking.

Use a stable lower/upper Dollar request window rather than restocking every
coin consumed. The tested entry/Cluster/Grid/Hyperscale windows are
**50-200 / 125-500 / 250-1,000 / 250-1,000**, with minimum deliveries
**100 / 250 / 500 / 500**. This reduced the faulty exact-target refill's
115 launches to 45 in the previous freeze; the shorter current route uses 43.
The helper changes requests only when their values change;
ordinary manual settings do not need a per-tick rewrite. Keep ground research
money separate. The total finite 8,000-Dollar orbital reserve need not be sent
up front; native batches replenish it as the platform works.

## Reproduce

```bash
scripts/sample-bitermotors-save.sh /absolute/path/to/campaign.zip 36001
python3 scripts/model_save_endgame.py \
  --baseline docs/endgame-save-baseline.json \
  --practical-evidence docs/endgame-practical-hyperscale.json \
  --practical-evidence docs/endgame-practical-grid.json \
  --output /tmp/endgame-budget.json
BITERMOTORS_MOD_ARCHIVE=/absolute/path/to/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-practical-ending.sh
# The slower alternative:
scripts/validate-bitermotors-practical-ending.sh \
  --config scripts/fixtures/practical-ending-grid.json
```

The sampler loads only a copied save and verifies the original hash afterward.
It performs two expensive read-only inventory/statistics captures, not a new
recurring scan in the production mod. Sampling a paused save explicitly unpauses
the disposable copy; it never unpauses the original world.

The practical runner supplies a finite manufactured ground bill, science,
operating Dollars, rocket ingredients and ground electrical power. Every
platform item must travel by rocket; native platform construction, sunlight,
heat networks, compute, research, belts, inserters and cargo delivery do the
work. It does not inject Tokens, Datasets, Models or earned compute. Separate
processes reload a partially loaded assembly and the completed victory.

Natural fresh-seed onboarding, full campaign playtime, simultaneous multiplayer,
and long customer-population soaks remain separate release gates.
