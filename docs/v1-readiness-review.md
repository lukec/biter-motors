# V1 Readiness Review And Project Plan

Review date: **2026-10-05**. Reviewed source: **54c12ac** on `main`.
Installed engine: **Factorio 2.1.20, build 87512, mac-arm64, Space Age**.
This review supersedes older release-readiness conclusions, not the campaign
vision. The review commit itself implemented no recommendations; subsequent
implementation status is recorded below.

## Verdict

**Do not start the final acceptance playthrough yet.** The terrestrial game has
enough content for v1. Finish and stabilize it rather than add another branch.
The initial compatibility defect is fixed in Phase 1; Phase 2 is complete with
accounting, mixed-population persistence, recycling/salvage, and charging/service
fixes. Native victory and the fixed finale are implemented in Phase 3. Real
payload delivery and complete cooling qualification remain open before a
campaign can fairly test endgame balance.

The target is a frozen, finishable Nauvis-and-orbit campaign, one complete fresh
playthrough with only small numerical tuning, then a **1.0.0** public release.
An optional public beta is a distribution choice, not a substitute for proving
the ending. Existing private alpha saves are useful regression fixtures; their
preservation is not a prerequisite for Luke's proposed fresh campaign.

## Scope And Evidence

This section and the finding references record the original review of
`54c12ac`, not the subsequent repaired baseline.

Reviewed the prototypes and technology changes, runtime and customer modules,
progression/economy contracts, tests, validators, soak tools, packaging, legal
notices, documentation, icons, entity assets, and vehicle/artwork pipelines.
Four focused read-only agent reviews supplemented the main inspection.

All engine experiments used an isolated temporary user directory. **No live
server, desktop client, installed mod, or player save was changed.**

| Check | Result | What it establishes |
| --- | --- | --- |
| Python suite | 121 tests passed | Current static, simulator, artifact, and harness assertions pass; not campaign correctness. |
| Unmodified main engine validator | Failed on 2.1.20 | The shipped source currently cannot load; see R01. |
| Final prototype dump | Loaded with a temporary compatibility shim | Allowed further inspection; not a release-archive pass. |
| Existing 18,580-tick smoke scenario | Assertions passed with that shim | Broad fixture coverage exists, but injected milestones/model output hide important defects. |
| Targeted controller experiment | Reproduced victory extraction race and quality/beacon changes | Native crafting completion can be missed; final challenge is not fixed-duration/fixed-draw. |
| Pure Lua customer fixtures | Reproduced mixed purchase accounting and allocator unfairness | These are behavioral defects, not just source-pattern concerns. |
| Icon review | Viewed all 63 icons at 16, 32, and 64 pixels | Readability observations below; not an in-game animation or audio sign-off. |
| Technology dump check | 30 custom technologies; no visible technology with a hidden prerequisite found | Useful structural check, not proof of recipe/material reachability. |
| Full current-version campaign/soaks | Not completed | No claim that the current campaign, final hour, or large-world performance passed. |

The temporary shim translated the four obsolete item `fuel_category` fields.
It was outside the repository and is not a fix or distributable build. An
extended controller benchmark did not produce its final completion sentinel;
benchmark update counts alone are not accepted as successful game-time or
victory evidence. The attempted partial-power controller fixture was also
inconclusive; the existing smoke proves a power-cut reset, not every brownout.

Historical 2.1.14 performance results remain useful comparisons. They are not
validation of 2.1.20 or of the next release archive.

## Findings

Severity: **P0** prevents starting; **P1** invalidates a core campaign contract
or its release evidence; **P2** is correctness, clarity, or scaling work to
address before freezing the affected mechanic. Source paths below are relative
to the repository and line numbers refer to the reviewed commit.

### R01: Current Factorio Cannot Load The Mod [P0]

**Evidence:** engine reproduction. `mod/bitermotors_0.1.1/data.lua:933`, `940`,
`947`, and `954` define hidden drive-charge items using removed `fuel_category`.
2.1.20 aborts loading `bitermotors-electric-drive-charge` and requests
`fuel_categories` instead.

**Work:** update these prototypes against the chosen engine's schema, then run
every relevant engine validator and the exact packaged ZIP without shims.
Record the supported build; do not promise every later experimental release.

**Acceptance:** clean load, new world, save/reload, and EV/Cybertrain/eSpider
charging on the selected version. See the official
[Item prototype reference](https://lua-api.factorio.com/latest/prototypes/ItemPrototype.html).

### R02: Production, Consumption, And Completed Sales Are Confused [P1]

**Evidence:** source trace plus the current API contract. Item/fluid production
statistics use `input` for production and `output` for consumption. The helpers
at `control.lua:984`, `993`, and `1121` read the opposite direction. Historical
sales at `4141` read production, and `4190` repeatedly promotes those values
into the sales ledger. Manufacturing cars can therefore satisfy sold-car gates.
The official [flow-statistics reference](https://lua-api.factorio.com/latest/classes/LuaFlowStatistics.html)
documents this direction explicitly.

Premium production reconciliation at `1083` can count production and later
consumption twice. Profit, Nickel extraction, Lithium pumping, and battery
objectives can remain unchanged until the products are consumed. Scripted
income/bonus/wreck accounting also writes the wrong side, including `8166` and
`10001`. A test at `tests/test_bitermotors_mod.py:2080` asserts the wrong direction.

**Work:** audit each read/write by intent, not a global search-and-replace.
Make completed Sales Office transactions authoritative for sales. Recycling,
placing, manufacturing, and consuming vehicles are not sales. Correct native
production reads and scripted production writes; remove unnecessary legacy
reconciliation from fresh-world logic or repair its invariants explicitly.
First-sale history at `8258`/`8275` already reads consumption in the correct
direction, although generic consumption is still imperfect sale evidence.

**Acceptance:** actual production crosses 99/100 and 249/250 independently of
sales; actual sales cross 49/50, 249/250, 1,999/2,000, and 4,999/5,000. Stockpiling,
recycling, vehicle placement, and Bitertaxi assembly must not advance sale gates.
Native and scripted profit immediately agree with the Progress panel. Test
isolated mineral/intermediate storage, quality variants, save/reload, and a
deliberate statistics reset.

**Accounting slice implemented 2026-10-05:** production reads now sum every
quality on each surface, consumption is separate, and recorded production
survives an observed statistics reset without scanning inventories. Sales start
at zero and only successful customer assignments advance the ledger. Completion
is processed before replacing a buyer reservation; inserted coins and generic
vehicle consumption no longer establish first-sale history. Scripted output
uses positive production flow. See [accounting validation](accounting-validation.md)
for native 99/100 and 249/250 production, native 49/50 Roadster sales, remaining
sold-car boundary policy fixtures, canceled-sale and persistence evidence. This
does not qualify mixed populations, every customer lifecycle race, or the AI
recipe/provenance boundaries in R16; those remain in the subsequent phases.

### R03: The Finale Moves A Billion Items And Packages Them At 10 GW [P1]

**Evidence:** recipe/prototype arithmetic, not a full logistics benchmark.
`data.lua:2195` converts 50,000 AI Token items into one Dataset in one second.
It is exclusive to the final controller's category. That machine at `1478`
draws 10 GW. Twenty thousand Datasets require **5 h 33 min 20 s** of normal-speed
controller packaging, before its final one-hour run. Parallel packaging means
building and powering more 10 GW controllers.

Storage stack size and rocket weight do not multiply inserter, belt, or robot
throughput. Moving one billion items down one 45-item/s express belt takes
about **6,173 hours**; even an optimistic 240-item/s fully stacked turbo belt
takes about **1,157 hours**. These are single-belt lower-bound examples, not a
claim that every player must use that layout. Bots do not carry a million-item
stack per trip. See [belt throughput](https://wiki.factorio.com/Belt_transport_system)
and [robot cargo capacity](https://wiki.factorio.com/Logistic_robot).

**Work:** settle the compressed-payload design below, separate cheap packaging
from the final controller, and benchmark a real supply chain. This is an
endgame design correction, not a small mid-playthrough balance patch.

**Acceptance:** native inserters, platform hub requests, rockets/cargo pods,
landing-pad unloading, and controller loading move the complete intended final
payload without direct inventory insertion. Keep logistics meaningful, but do
not require billions of identical transport operations.

**Partial implementation 2026-10-06:** Luke approved 50,000-equivalent Datasets.
Grid-scale/hyperscale cores now produce one/two directly per unchanged compute
batch; existing Token outputs remain for science. Packaging moved to ordinary
assemblers/Biterfactories. Native Dataset output and inserter extraction are
tested in [AI accounting validation](ai-accounting-validation.md). Full hub,
cargo-pod, landing-pad, and final-controller delivery remains open; R03 is not
yet a closed logistics gate.

### R04: Removing The Finished Model Can Prevent Victory [P1]

**Evidence:** engine reproduction. `controller_has_agi_model` at
`control.lua:8690` checks current output inventory; `8703` polls it every 30
ticks. In the isolated boundary test, native crafting completed one AGI Model
and immediate extraction removed it. `products_finished` was one, but victory
remained false at tick 610. Existing smoke inserts a Model into the output at
its final milestone rather than testing this completion boundary.

**Work:** latch a successful training completion independently of whether the
Model remains in the machine. A Model arbitrarily inserted into an output
inventory must not count as a completed run. Keep victory idempotent per force.

**Acceptance:** real completion wins exactly once with a working output
inserter, immediate pickup, controller removal, and save/reload around the
completion boundary. Zero completed runs must never win.

**Implemented 2026-10-06:** native AGI recipe completion now latches victory
once per force after the earned billion-equivalent gate. Output insertion
cannot win; later extraction, recipe changes, removal, or Continue cannot
cancel/replay completion. The [finale fixture](finale-validation.md) exercises
full native runs, immediate extraction, a real output inserter, controller
removal, near-completion checkpoint, and completed-world reload.

### R05: Quality And Beacons Bypass The Advertised Final Challenge [P1]

**Evidence:** engine reproduction. The controller inherits quality speed and
beacon effects through `copied_assembler` at `data.lua:268` and its definition
at `1478`. Its slots are zero, but that does not prohibit beacon effects.
A legendary controller ran at crafting speed **2.5**. A normal controller with
one two-Speed-Module-3 beacon also ran at **2.5**: 24 minutes rather than 60.
Efficiency effects reached **-80%**, undermining the nominal 10 GW requirement.

**Work:** recommended contract is a deliberate final-machine exception:
**20 uninterrupted simulation minutes at 10 GW**, independent of quality,
speed, or efficiency optimization. Ordinary industry and orbital compute can
still reward those optimizations. Implement both the time and power contract,
not merely removal of module slots. Quality behavior follows
[the game's quality rules](https://wiki.factorio.com/Quality).

Luke shortened the intended finale from 60 to 20 minutes on 2026-10-06.
The historical engine reproduction above describes the original one-hour recipe.

**Acceptance:** normal through legendary, speed/efficiency beacons, full power,
partial power, total loss, and restored power all satisfy the same final-run
contract. Define the low-power threshold and buffer tolerance explicitly.

**Implemented 2026-10-06:** every quality runs at speed one and 10 GW; module,
beacon, surface, and local effects are disabled. A separate bounded monitor
scraps progress on low/no power or a sampled buffer below 90%, holds retry for
one second, and preserves the committed batch. Exact native zero cancels that
batch, so the reset uses a negligible positive sentinel (displayed as 0%).
Completion callbacks see the final post-draw buffer; prior failure state, not
that buffer, guards completion. The [finale fixture](finale-validation.md)
measures full-duration energy and reloads a failed controller before recovery.

### R06: Physical Purchases Exhaust Untouched Virtual Prospects [P1]

**Evidence:** executed unchanged Lua purchase functions. At
`control.lua:2584`, virtual eligibility subtracts settlement-wide per-model
purchases from virtual population. Physical sales at `10111` increment that
same counter. With one physical Roadster buyer and one untouched virtual
prospect, selling to the physical buyer incorrectly makes virtual capacity zero.

**Work:** distinguish physical and virtual purchase history while conserving
aggregate population, owner counts, reserved buyers, and per-generation
eligibility. Avoid one Lua record per virtual customer.

**Acceptance:** mixed populations can buy each permitted generation exactly
once; replacements change the active vehicle without multiplying owners.
Cover sales cancellation, death, representation churn, and save/reload.

**Implemented 2026-10-06:** `runtime/customer_population.lua` separates physical
and virtual histories and stores virtual customers as bounded cohorts of purchase
history plus current model. Reservations carry a cohort ticket through completion
or cancellation; no per-virtual-customer record is created. Native mixed-population
Roadster/Premium sales and replacements, death, cancellation, and repeat rebuilds
pass. Executable policy fixtures cover every model and concurrent reservations.
See [customer-state validation](customer-state-validation.md) for exact coverage
and archive evidence; this is not the long population/performance qualification.

### R07: Configuration Rebuild Can Lose Virtual-Only Settlements [P1]

**Evidence:** source trace. `rebuild_customer_settlement_population_cache` at
`control.lua:3939` rebuilds records from surviving physical units and copies
prior virtual state only into those records. A living settlement with virtual
owners but no physical representative can lose its state on configuration change.

**Work:** establish every valid settlement/force population record first, then
attach physical representatives and retained virtual state. Fresh-only support
does not excuse corrupting an otherwise valid v1 save during normal mod updates.

**Acceptance:** zero representatives plus virtual owners/prospects/reservations
survive save/load and a benign configuration change without loss or duplication.

**Implemented 2026-10-06:** rebuilds establish every valid settlement/market-force
population before attaching physical representatives, preserve same-force cohorts,
derive ownership/history summaries, and reconcile pending tickets. A real
server-written checkpoint retains a virtual owner, prospect, and pending purchase
with zero representatives through separate-process reload and helper-version
change. Destroyed settlements are pruned without erasing lifetime sales. This
supports normal updates of the new state, not backfilling unsupported private
alpha histories. See [customer-state validation](customer-state-validation.md).

### R08: Rewritten Recipes Keep Old Recycling Outputs [P1]

**Evidence:** inspected final engine prototype dump after the diagnostic shim.
`data-updates.lua:37` rewrites vanilla recipes after Recycler's earlier update
stage has generated their reverse recipes. Final fixes do not reconcile them.
The cheap Big Mining Drill still recycles into Tungsten Carbide; Foundry into
Tungsten Carbide; Battery MK3 into inaccessible Supercapacitors. These materials
are absent from the new forward recipes and leak removed planetary economies.

**Work:** regenerate intended reverse recipes after all rewrites, or explicitly
disable recovery for exceptions. Audit every rewritten vanilla recipe, not just
these three. Preserve 90% cell recovery as a deliberate custom contract.

**Acceptance:** final-dump assertions and native recycler runs agree with
approved ingredients, recovery ratios, quality policy, and planet scope.
The ten-damaged-pack runtime check did select the intended custom recovery;
self-recycling shadowing is **not** established. Still test 1-9 packs,
incremental feeding to ten, and previously selected automatic recipes.

**Implemented 2026-10-06:** every rewritten vanilla recipe is tracked and its
reverse regenerated by the upstream Recycler helper after final fixes, with
exactly one recycling unlock and no reverse productivity. Final-dump checks cover
all **18** approved recipes, not only drills and Foundries. Both damaged-pack
items disable automatic self-recycling; native 1-9/incremental batches survive,
then return exactly 36 cells at ten. Normal/rare recovery and separate-process
partial-batch reload pass on source and the exact ZIP. See
[recycling validation](recycling-validation.md) for the native/probability scope.

### R09: Contested Chargers Can Starve An Equal Neighbor [P2]

**Evidence:** executed `runtime/charger_allocator.lua:214`. One 48-capacity
charger shared by two settlements demanding 48 each allocates **48/0**; the
earlier stall-sized rule allocates **24/24**. The optimization confuses one
candidate charger per settlement with absence of competing demand.

**Work:** bulk-allocate only genuinely uncontested capacity. Retain bounded,
deterministic fair sharing for contested service, including partial power.

**Acceptance:** equal and unequal shared demand, added/removed chargers, and
brownouts conserve total capacity without key-order starvation.

**Related follow-on found 2026-10-06:** `eligible_customer_buyers` adds the
per-model reserved-by-settlement count (which includes virtual tickets) and
`population.virtual_reserved` to its pool load. Same-model virtual reservations
therefore count twice for buyer-pool balancing. Count each pending buyer once
and cover multiple offices/models when qualifying this fairness slice.

**Implemented 2026-10-06:** the bulk shortcut now requires both one reachable
charger and one demanding settlement at that charger. Contested capacity uses
bounded stall-sized heap rounds, including brownouts, while uncontested demand
retains bulk allocation. Pending buyers count once across all EV models.
Ten native-Lua allocator cases and actual charger removal/brownout/restoration
plus multi-office virtual-ticket tests pass on source and the exact ZIP. See
[charging validation](charging-validation.md) for rounding and scaling limits.

### R10: Service Health And Growth Use Divergent Predicates [P2]

**Evidence:** source trace and a bounded timing simulation. Initial service at
`control.lua:5140` recognizes taxi-only coverage; capacity refresh at `5196`
omits it. Cached mood checks can temporarily report a healthy taxi-only
settlement as deficient. The normal 60-second rebuild restores it inside the
three-minute grace period: **healthy-depot hostility was not reproduced**.

Growth at `7265` separately treats fully powered requested charger stalls as
healthy even when a settlement has an allocation deficit. This can contradict
the documented rule that shortages suspend only the affected settlement.

**Work:** use one explicit settlement-health predicate for initial rebuild,
refresh, mood, alerts, and growth. Keep private charging and taxi service as
alternative routes to adequate service, not mutually dependent requirements.

**Acceptance:** taxi-only service remains healthy across multiple cache cycles
and unrelated infrastructure edits. One deficient neighbor neither blocks nor
unfairly accelerates healthy neighbors. Outages recover within the intended
grace/mood policy.

**Implemented 2026-10-06:** one pure settlement-health policy now drives rebuild,
cached power/mood refresh, alerts, inspectors, and growth. Fully served taxi-only
homes stay healthy across six cache cycles and unrelated pole edits. Organic
growth runs once per healthy home, including taxi-only homes; deficient neighbors
do not contribute healthy charger-expansion utilization. A real outage respects
the native grace, eventually triggers stochastic anger, then clears it on
recovery. Separate engine reload preserves restored service and pending buyers.
Source/exact-ZIP tests and prior accounting/customer/recycling/broad regressions
pass. See [charging validation](charging-validation.md); this is not long-soak,
all-tier, multiplayer, or native GUI qualification.

### R11: Commodity Premium EV Wrecks Yield Advanced-Chemistry Materials [P2]

**Evidence:** source trace. The legacy Premium recipe at `data.lua:1878` uses
ordinary batteries, but the vehicle death map at `control.lua:172` always yields
eight damaged High-energy Battery Packs. Five such wrecks can recover 144
High-nickel Cells without the advanced mineral supply chain.

**Work:** choose an honest salvage rule. For a shared vehicle prototype with no
ingredient provenance, conservative generic salvage is preferable to tracking
every crafting ingredient on every car. If chemistry-specific salvage matters,
use an explicit distinction rather than guessing from unlocked research.

**Acceptance:** legacy and cell-based recipes, death, collision, mining, and
fast replacement never mint unearned advanced materials or duplicate wrecks.

**Implemented 2026-10-06:** both actual Premium recipes yield only generic body
salvage because the shared vehicle item has no battery provenance. The anonymous
charger lottery no longer infers advanced packs from lifetime sales. Known
Mass-market/Megatruck/Bitertaxi/Cybertrain recipes retain fixed pack returns;
destroyed player vehicles yield one quality-matched body wreck, and only actual
spilled quantities enter production statistics. Native death/collision, engine
mining, script removal, and genuine construction-bot deconstruction check
conservation; existing customer fixtures cover owner replacement/death without
duplicate sales. Bot deconstruction also exposed hidden drive-charge items
leaking to storage, now removed before player/robot mining. See
[recycling validation](recycling-validation.md). Natural long-duration taxi
attrition and every other mod's scripted lifecycle are not qualified here.

### R12: Guidance And Economy Models Drift From Runtime [P2]

**Evidence:** source and simulator comparison. Progress guidance around
`control.lua:10457` still quotes V2/Capital Scaling/Autonomy/Orbital research as
300/1,000/1,000/2,000 Dollars; implemented costs are 150/600/750/1,500.
Guidance can make optional Foundry or Megatruck work look like required AI
progression. Orbital recipes say 30 seconds, but their normal machine speed is
1.5, making effective cycles **20 seconds** before further effects.

The economy model omits capital spent producing research AI Tokens, including
the 750-token Autonomy requirement. At base terrestrial efficiency this is
38 cycles, 760 Dollars, and 19 minutes of 8 MW operation. It also omits physical
payload transport and controller packaging time/power. Model tests mostly
enforce constants rather than reconcile final prototypes and behavior.

**Follow-on observed 2026-10-06:** the native recycling fixture recovers 39
Dollars from four tier-3 module batches with no customer sales. Progress reports
those 39 as profit because it reads all positive Dollar production. Preserve
legitimate capital recovery, but distinguish returned capital from operating
profit in the economy/interface pass; do not make generic production imply sales.

**Work:** derive costs and effective throughput from current prototypes where
possible. Separate the critical next step from optional upgrades. Keep the
current normal orbital 20-second rate unless balance evidence justifies changing
it; update misleading copy and simulation instead of silently nerfing it.

**Acceptance:** displayed blockers/costs agree with recipes, science, sales,
and power. Compare three economy scenarios using actual budgets and finite
markets, not just an unlimited-sale spreadsheet.

### R13: Soak Evidence Can Overstate Completed Work [P1]

**Evidence:** `scripts/analyze-bitermotors-soak.py:155-180` accepts benchmark
timings, checks only first/last probe errors, and reports requested ticks as
completed duration. It does not require complete benchmark updates, actual
game-time advancement to the requested end, full timing-window coverage, or
complete probe cadence. Intermediate probe failures can go unreported.

Fresh-start and GUI helper folders also end in `0.1.0` while their manifests
declare `0.1.1`; verify discovery and fix this before trusting those validators.

**Work:** make tools fail closed on incomplete runs. Record requested and
observed update counts **and game ticks** separately, verify all snapshots,
require end sentinels/cadence, and validate the separately requested timing
window. Deliberate pause/victory must be accounted for, not called a full soak.
Archive helpers must exercise the same code/configuration they claim to test.

**Acceptance:** truncated logs, early stop, paused game time, missing probes,
intermediate read errors, too few timing samples, and zero-exit Lua failures
all fail with actionable diagnostics. A valid run records archive/save hashes,
engine version, real tick span, workload progress, and trustworthy percentiles.

### R14: Packaging, Versioning, And Media Rights Need Closure [P2]

**Evidence:** `scripts/package-bitermotors.py:47` packages filesystem contents
using a short exclusion list, not an approved tracked-file manifest. A local
ignored credential, log, save, or symlink under the mod directory could ship.
**No actual secret leak was found in this review.** Install/validation scripts
also hard-code the 0.1.1 source directory. CI does not run Factorio; all 121 tests
passing did not catch R01.

MIT code licensing and a separate asset notice already exist. Clarify permitted
installation and redistribution of the unmodified mod package, and record
origins/permissions for shipped audio as well as images. This is a release
documentation/provenance task, not a legal determination.

**Work:** package approved source paths, reject symlinks/forbidden artifacts,
resolve versions from the manifest, and rehearse 1.0.0 metadata consistently.
Use a local engine release gate without pretending CI includes a licensed game.
Pin/document artwork tool versions when reproducibility depends on them.

**Acceptance:** a clean checkout makes a deterministic, self-contained archive;
negative tests reject `.env`, saves, runtime data, and symlinked external files.
The exact upload archive independently installs, loads, saves, and reloads.

### R15: Two Different Orbital Functions Have Identical Placed Art [P2]

**Evidence:** `data.lua:1450` and `1465`, corroborated by the final prototype
dump, retain identical vanilla solar-panel pictures for Radiator and Space
Solar. Dedicated inventory icons exist, but placed entities are indistinguishable.
The art QA generator covers 12 structures and two rail previews, omitting
several final machines, tiers, and the five road vehicles.

**Work:** give radiator and space-solar unmistakably different silhouettes or
surface treatments; repair the current QA inventory. Do not regenerate every
asset or require unique technology art where a consistent mod badge is clear.

**Acceptance:** the full asset matrix below passes native-scale review in the
game, including footprints, shadows, animations, status, and picker visibility.

### R16: AI Cycle Accounting Needs Adversarial Boundary Coverage [P2]

**Evidence:** source risk, not a reproduced incorrect total. The cycle ledger
around `control.lua:1441` samples completed-craft deltas and the current recipe.
Recipe switching between samples, productivity output, pending bonuses, and
machine destruction deserve explicit conservation tests.

**Work:** agree whether a token is counted when computation completes or when
physical output is delivered, then apply that definition once across native
tokens, scripted bonuses, and compressed Datasets. Preserve terrestrial and
orbital tracks and prevent repackaging from minting cumulative progress.

**Acceptance:** output-blocked, recipe-switch, quality, bonus-pending, removal,
save/reload, and two-force/two-platform scenarios keep physical payload and
earned-equivalent ledger consistent with the documented policy.

**Implemented 2026-10-06:** approved compute recipes raise native completion
events. The ledger counts their exact deterministic output equivalents when
the engine materializes output, including native bonus crafts; research bonuses
count only when inserted, retain event product quality, and discard undelivered
liabilities on removal. Packaging and item statistics do not earn progress.
The [source/exact-archive fixture](ai-accounting-validation.md) covers these
accounting boundaries. The [subsequent finale slice](finale-validation.md)
qualifies final training separately. Complete orbital cooling/power and real
cargo delivery remain Phase 3 gates, not implied by accounting coverage.

## Design Freeze Recommendations

### Keep The Existing Campaign

The distinctive loop is coherent: manufacture EVs, earn profit from formerly
hostile customers, manage charging and growth, expand clean power and batteries,
adopt recurring Bitertaxi service, then fund orbital compute and a terrestrial
AGI finale. Space remains a compute location, not a new commercial launch tree.

Keep reservations physical; one buyer does not imply every old paperwork item
is currently useful. Keep finite per-generation purchases and bounded local
growth. Depot recurring income provides a late-game alternative to continually
finding distant new nests. Keep worms hostile and customer diplomacy local.

Make the required route explicit: industrial basics, initial sales, Premium
production, energy/battery scale, Mass-market scale, AI/autonomy, vanilla rocket
and platform logistics, orbital scale tiers, final grid and training. Foundry,
Megatruck, Cybertrain, Self-driving, eSpider, and infinite improvements can be
valuable optional branches without blocking the next unrelated objective.

No extra company simulation, planet, enemy faction, battery chemistry, Diner,
Humanoid Robot, Biterfactory V3, or solar-roof mechanic before v1. Do not make
a wholesale `control.lua` rewrite a release prerequisite. Extract only the
small state/accounting/service functions needed for reliable fixes and tests.

### Recommended Final Payload

Retain the **1B earned AI-token-equivalent goal**, capital requirement, orbital
scaling, terrestrial 10 GW challenge, and physical AGI Model. Change the
transport representation, not the theme or an arbitrary victory multiplier.

Recommended implementation:

1. Keep individual AI Tokens for terrestrial/early-orbital science and discovery.
2. Make an AGI Training Dataset explicitly represent 50,000 computed tokens.
3. At the appropriate orbital scale tier, allow cores to produce Datasets
   directly at the equivalent approved Dollar/time/token rate. For example,
   the current normal hyperscale cycle represents 100,000 tokens, so two
   Datasets preserve its value without emitting 100,000 individual items.
4. Count that earned equivalent once in the orbital cumulative ledger. Converting
   existing Tokens into Datasets must not count a second time.
5. Allow straightforward Dataset/Capital Allocation packaging in ordinary
   industry or a Biterfactory, not a 10 GW endgame-only machine.
6. Keep the final 20,000-Dataset input and test actual delivery from multiple
   platforms. The final controller exists to train, not spend five hours boxing.

This uses an existing item rather than adding another currency. Luke approved
it on 2026-10-06. Dataset stack size/weight and packaging now have native
prototype, AM2/Biterfactory, and accounting coverage. The full cargo delivery
gate remains open.

### Final Run And Recovery

Approved promise: 20 uninterrupted **simulation** minutes, 10 GW while training,
exactly one victory upon successful completion, and continued play afterward. A brief
power-buffer tolerance may avoid meaningless flicker resets, but the documented
low-power threshold must be tested rather than inferred from a status enum.
Quality/beacons must not quietly bypass this challenge.

Clarify that scrapping a training run resets progress while retaining the
recipe's committed input policy; test recovery without forcing the player to
earn another arbitrary full campaign budget. Cooling failure likewise needs a
clear explanation, visible alert, and repeatable recovery. Do not add physical
heat-network simulation for v1: eight radiators per core on the same platform
is sufficient if allocation, removal, and feedback are correct.

### Balance Decisions Before The Fresh Campaign

The current simulator is a sensitivity tool, not an end-to-end campaign proof.
Reconcile it with the final prototype dump and include science consumed to
unlock each stage, AI research operating cost, construction, shipping, payload
preparation, growth, recurrent taxi profit, outages, and power expansion.

Run restricted-market, typical-expansion, and taxi/energy-product-heavy scenarios.
Include roughly 5, 10, and 20 developed settlements rather than unlimited
instant customers. Show active build/expansion time separately from unavoidable
simulation wait. Target useful major progression every approximately 2-3 hours
of active play; this is a proposed tuning criterion, not a completion promise.

Do not reduce everything indiscriminately. First remove accounting bugs and
transport/packaging grind; then tune the actual capital or resource bottleneck.
For the final power build, count all panels, batteries, material chains, and
research effects. The old plan's roughly 4,762 Tandem Solar Arrays and 1,001
Grid Battery Arrays at zero solar improvements needs a build/research comparison,
not another blanket panel-output multiplication.

The Foundry power gate also needs an explicit meaning: the current deployed
panel/battery count is not proof of a connected, functioning power system.
Choose a simple discoverable construction milestone or a real grid-capacity
check and describe it honestly. Do not silently change this mid-playthrough.

## Asset Review And Minimum Finish Pass

The committed art is substantially more complete than a placeholder mod:
63 custom inventory icons, 34 entity PNGs, 29 animation PNGs, eight technology
PNGs, directional vehicle sprites/shadows, and custom rail assets. These are
file counts, not counts of distinct buildings or independent art approvals.

The red/black/white/silver/gold vehicle family is readable and consistent.
Reservations read as paperwork. Clean-process icons have dedicated art rather
than the disliked module overlays. Damaged and healthy Battery Pack icons are
not identical, but their silhouettes remain too similar at small scale.
Biterfactory tiers and Grid Battery tiers also need stronger small-size cues.
Vanilla/tinted eSpider and consistently badged technology art are acceptable
intentional reuse, not automatically release defects.

| Asset family | Minimum pre-freeze review/work |
| --- | --- |
| Sales Office/showroom | Axis-aligned footprint; correct selected vehicle; active/idle/blocked and red/green treatment; no duplicated native recipe label. |
| V1-V4 chargers | Tier order and size; readable utilization; charging animation; no misleading logistics overlay; consistent coverage and grid connection. |
| Biterfactory V1/V2 | Same replaceable footprint; tier differentiation; production-only activity; shadows and recipe icon do not obscure the building. |
| HD/Tandem solar | Footprint edge/alignment; distinct upgrade tier at inventory and placed scale; contiguous fields have no misleading empty border. |
| Grid Battery/Array | Distinct tiers; charging/discharging and idle states; damaged-pack versus healthy-pack silhouette at belt scale. |
| Terrestrial/Orbital compute | Footprint and active state; power/cooling reset indication; orbital core included in QA. |
| Orbital radiator/space solar | Required distinct placed art; correct platform footprint and solar/cooling identity. |
| Controller/Dataset/Model | Training versus packaging/idle state; compact payload and final reward readable; no obsolete launch branch in QA. |
| Five road EVs | All directions, depth/shadows, color, belts and inventory; forward/reverse audio audibility; battery and charging feedback without trailing labels. |
| Cybertrain/charging stop/eSpider | Native alignment/directions, reserve crawl, charging, remote-view readability; intentional native art reuse identified. |
| Prospect/customer/spawner UI | Friendly versus hostile; car class and underserved status; map warnings locate the actual affected settlement. |
| Resources/intermediates | Mineral/chemistry, dirty/clean, healthy/damaged, and recoverable waste clearly distinguishable at 16/32/64 px. |

Static sheets do not establish native entity scale, animation gating, selection
boxes, day/night readability, GUI clipping, or sound. Generate one current QA
index covering every shipping entity/item, then inspect an isolated showcase
save at ordinary zoom, night, remote view, and two UI scales. Fix confusing
functionality first; optional aesthetic polish and a trailer can follow v1.
Marketing should use approved, physically plausible real-game scenes rather
than moving Luke's vehicle/player in a live campaign for photographs.

## Consecutive Implementation Phases

All unchecked work below is outstanding. Complete Phases 1-6 **before** Luke
starts the final campaign. A phase may take more than one focused commit; do
not combine unrelated fixes into a single opaque patch. Record actual artifacts,
verification, and remaining gaps in this document as each phase completes.

### Phase 1: Restore A Truthful Current-Version Baseline

- [x] Fix R01 and choose/document the supported engine build.
- [x] Correct helper folder/manifest versions and version-derived source paths.
- [x] Make validators inspect the whole run and fail on missing sentinels/errors.
- [x] Harden soak completeness checks from R13 with negative fixtures.
- [x] Record a clean source and exact-ZIP engine pass without a shim.

**Deliverables:** compatibility fix, trustworthy validation tools, dated baseline.
**Exit gate:** clean create/save/reload plus existing smoke with no shim; test
suite and deliberate broken/truncated validator cases both behave correctly.

**Completed 2026-10-05:** [dated baseline and exact archive](validation-baseline.md).
Factorio 2.1.20 loads the corrected source and package; 147 Python tests pass.
Native short soaks verify N-1 tick spans, including a terminal periodic boundary.
R01 and the evidence-completeness defects in R13 are addressed. Version-derived
install/validation paths also close part of R14; its packaging/provenance work
is not complete. GUI acceptance still needs a player-bearing fixture. No long
soak, full campaign, or final training qualification is claimed by Phase 1.

### Phase 2: Make Progression And Customer State Authoritative

- [x] Correct production/sales/profit accounting and replace inverted assertions.
- [x] Fix mixed physical/virtual purchase history and virtual-only rebuilds.
- [x] Restore contested capacity fairness and unify service-health predicates.
- [x] Reconcile rewritten reverse recipes and legacy chemistry salvage.
- [x] Add executable mixed-customer lifecycle and persistence fixtures.
- [x] Add executable recycling/salvage and partial-batch persistence fixtures.
- [x] Complete executable charging/service fixtures.

**Accounting slice complete 2026-10-05:** [verification and exact ZIP](accounting-validation.md).
152 Python tests, source/archive broad smoke, and source/archive accounting
fixtures pass. The latter execute the production/sales policy in Factorio, earn
50 customer-backed Roadster sales, reject a canceled Premium sale, and reload
an actual server-written checkpoint in a separate process.

**Customer-state slice complete 2026-10-06:** [verification and exact ZIP](customer-state-validation.md).
158 Python tests and native source/archive customer fixtures pass: 63 policy,
134 native-world, 9 separate reload, and 12 configuration-change assertions.
Source/archive accounting and broad smoke remain passing. That slice closed
R06/R07; R08/R11 were still outstanding at its completion.

**Recycling/salvage slice complete 2026-10-06:** [verification and exact ZIP](recycling-validation.md).
167 Python tests pass. Source/archive final-dump checks cover 18 inverse recipes
and both recovery routes; native fixtures pass 52 policy, 480 world, and 26
separate-reload assertions. Real bot deconstruction does not leak hidden fuel or
duplicate salvage. Source/archive accounting, customer lifecycle, and broad smoke
remain passing. R08/R11 were addressed; R09/R10 were still open at that slice.

**Charging/service slice complete 2026-10-06:** [verification and exact ZIP](charging-validation.md).
178 Python tests pass. Source/archive charging fixtures pass 137 policy, 1,196
world, and 14 separate-reload assertions: contested capacity, actual power,
taxi-only service, local growth, pending-ticket balancing, and native grace/mood
recovery. Prior accounting, customer-state, recycling, and broad smoke pass on
both source and the current archive. **Phase 2 is complete.** R12's capital
recovery/profit label remains a Phase 4 economy/interface follow-on.

**Deliverables:** R02/R06-R11 fixes, conservation and progression regressions.
**Exit gate:** no recipe unlock from unsold cars; exact production/sale milestones;
mixed customer populations and zero-representative settlements survive lifecycle
changes; no removed-planet materials appear through recycling.

### Phase 3: Finish The Physical Endgame

- [x] Approve and implement compressed Datasets/cheap packaging from R03.
- [x] Replace sampled AI cycles with native, token-equivalent completion
      accounting and adversarial persistence/conservation coverage from R16.
- [x] Latch real AGI completion and enforce the intended time/power contract.
- [ ] Cover AI accounting boundaries, cooling allocation, blocked outputs,
      brownout recovery, platform removal, and recipe changes.
- [ ] Build a native endgame fixture with two platforms, real hub/cargo-pod
      delivery, terrestrial research, payload loading, and powered training.
- [x] Run the actual full-length final training with no injected completion or
      accelerated final crafting; remove the Model immediately as a second case.

**Deliverables:** endgame fixes, revised contract, complete native delivery/win tests.
**Exit gate:** 1B earned equivalents reconcile; final inputs arrive through real
logistics; cooling and power failures reset/recover; the complete run wins once
under every supported quality/output-extraction configuration.

**Payload/accounting slice complete 2026-10-06:**
[verification](ai-accounting-validation.md). Grid-scale/hyperscale direct
Datasets preserve time, capital, and computed output rates; cheap packaging
does not earn progress again. Native recipe-switch, productivity, quality,
blocked output/bonus, immediate removal, force isolation, milestone, inserter,
platform deletion, and separate-reload cases pass.

**Finale slice implemented 2026-10-06:** [verification](finale-validation.md).
Native earned computation opens the billion-equivalent gate. Ten actual final
runs exercise all qualities, speed/efficiency beacons, local effects,
extraction/removal, brownout/total outage, failed-state reload, and retained-input
recovery. Separate completed-world reload checks the once-only victory latch.
Remaining Phase 3 work is full real cargo delivery and complete orbital
cooling/power allocation, reset, and recovery qualification.

### Phase 4: Freeze Economy, Guidance, And Functional Art

- [ ] Reconcile simulator with final prototypes and three finite-market scenarios.
- [ ] Set the intended research/construction/AI operating budgets and cadence.
- [ ] Derive Progress costs/blockers and distinguish optional branches.
- [ ] Complete R15 and the minimum asset matrix; repair the QA index.
- [ ] Verify all physical/script-produced items are filterable before unlock,
      technology costs/descriptions match, and UI fits at supported scales.
- [ ] Publish a short campaign contract and known limitations; stop adding features.

**Deliverables:** final balance report, current QA page/screens, spoiler-light guide.
**Exit gate:** no known forced transport/passive-money grind, misleading unlock,
ambiguous critical asset, or unexplained non-actionable blocker.

### Phase 5: Reliability And Scaling Qualification

- [ ] Run a four-hour late-terrestrial soak and one-hour multi-platform orbital
      soak against the exact candidate archive with truthful duration probes.
- [ ] Benchmark increasing settlement count separately from visible-unit count:
      25/100/250/500 settlements and approximately 2,000 visible representatives.
- [ ] Include sales bursts, growth, Grid Battery adoption, open inspectors,
      charger/pole placement/removal, commutes, and power transitions.
- [ ] Profile before optimizing. `sync_grid_battery_installations` around
      `control.lua:8940` can still scale with settlements times selling offices;
      visible-unit caps do not bound that workload. Quantify it first.
- [ ] Verify save/load, harmless configuration change, two-player join/reconnect,
      force isolation, building fast-replacement, and no hidden-entity leaks.

**Deliverables:** hashed soak summaries, scaling curves, targeted fixes if needed.
**Exit gate:** existing budgets (average <= 8 ms, warm p99 <= 16.667 ms, warm
maximum <= 100 ms) plus no runtime errors, recurring second-scale hitches, state
loss, or unbounded backlog. Report machine/version and workload with every result.
20,000 fully physical biters remain a diagnostic negative stress case, not the
supported population architecture or a prerequisite for 60 UPS.

### Phase 6: Release-Candidate Rehearsal

- [ ] Close package/provenance/version issues from R14.
- [ ] Make the candidate from a clean commit; retain archive SHA-256 and manifest.
- [ ] Clean-install that exact archive with only declared dependencies; create,
      save, reload, and join both single-player and multiplayer worlds.
- [ ] Have an outside player complete the initial customer/manufacturing loop
      without developer explanations; fix only demonstrated usability blockers.
- [ ] Capture the campaign configuration, supported version, and checkpoints.

**Deliverables:** installable RC, release manifest, compatibility/recovery notes.
**Exit gate:** no P0/P1 remains, no known P2 breaks the tested path, and the
archive rather than a source symlink is ready for the final playthrough.

### Phase 7: Luke's Final Fresh Playthrough

- [ ] Create a new non-sandbox world with the approved accelerated landing kit.
- [ ] Freeze the engine, mod archive, startup settings, and campaign seed.
- [ ] Record elapsed game/active time, profit, research, peak/grid power,
      resource production, sales, represented population, and AI output at
      each major milestone. Telemetry is read-only and bounded.
- [ ] Keep milestone saves, especially before orbital infrastructure and AGI.
- [ ] Reach the ending with real products, earnings, deliveries, and power:
      no refunded capital, injected token milestones, or inserted AGI Model.
- [ ] Finish the actual training, continue playing, save, and reload afterward.

**Allowed changes:** small numeric balance adjustments only, each logged with
before/after effect and affected tests. A progression/state/performance bug is
a stop-and-fix RC defect, not permission to quietly redesign mid-campaign.
Retest its subsystem and preserve a backup; restart the campaign only when the
change invalidates progression evidence. Do not reset the live game casually.

**Exit gate:** complete and understandable campaign, no critical workaround,
credible pacing, verified orbital transition and native final victory.

### Phase 8: Publish V1

- [ ] Apply only the final approved adjustments; rerun affected gates and exact
      1.0.0-archive installation after the version change.
- [ ] Finalize changelog, license/provenance, supported version, known issues,
      save-compatibility promise, screenshots, and feedback channel.
- [ ] Tag the exact source/archive version and upload the validated artifact.
- [ ] Verify the portal download independently installs and loads.
- [ ] Keep trailer, aesthetic polish, and new feature branches outside the gate.

**Exit gate:** public 1.0.0 download reproduces the validated campaign and its
ending. Public patch-save support begins with the first public archive.

## Required Regression Matrix

| Area | Cases required before final playthrough |
| --- | --- |
| Fresh world | Accelerated start on/off; wreck salvage and captain's cache; two-player gear; at least five seeds with reachable Nickel/Lithium/Calcite; no console-only initial recipe. |
| Tech reachability | Actual ingredients/machines/science for each critical unlock; no hidden-planet prerequisite/material; mining/engine and furnace/refinery dependencies; required versus optional branches. |
| Production and sales | Boundary values above; production without sale; sale without production changes; high-quality variants; statistics reset; transaction cancellation/output blockage. |
| Customers | Mixed physical/virtual; zero representatives; replacement purchases; death; new spawns; referral/growth cap; two forces/surfaces; isolated under-service. |
| Charging/diplomacy | All tiers, shared allocation, partial power, no grid, added/removed poles/chargers, timed commutes/home return, worms, road rage, grace and recovery, taxi-only coverage. |
| Reservations | Only eligible demand; slow retry; finite output/backpressure; output full and prospects exhausted; no exponential paperwork churn. |
| Grid Battery sales | Purchaser stays at showroom; installation/adoption; repeat neighbor demand; no duplicate currency/installation; growth and office-count scaling. |
| Vehicles | Five EVs, eSpider and Cybertrain; low battery, charging, reverse sound, collision/wreck, reserve crawl, blocked Self-driving path and cancel, teleport/removal/save-load. |
| Batteries/recycling | Dirty/clean coproducts, tailings throughput, productivity whitelist, 90% recovery, low-count feed, rewritten vanilla inverses, no chemistry fabrication through wrecks. |
| AI/endgame | Base/efficient tiers, quality/beacons, blocked outputs, pending bonus, low power, cooling shortfall/removal, two platforms, cargo return, datasets, full 20-minute run, immediate Model extraction. |
| Presentation | Native scale/night/remote map; every physical item filterable while locked; overlays and alerts; clipped text; progressive UI; actionability and correct counts. |
| Persistence/package | Native save/load at each milestone; harmless config change; multiplayer join; clean 1.0.0 archive; deterministic hashes; no secrets/runtime artifacts. |

## Next Implementation Slice

Continue **Phase 3 physical endgame**. The 50,000-equivalent Dataset and fixed
20-minute, 10 GW finale contracts are approved; compressed production,
ordinary packaging, native compute accounting, and full native final training
are implemented. Next qualify real multi-platform hub/cargo-pod/landing-pad
delivery into the final controller and complete orbital cooling/power
allocation, removal, reset, and recovery. Use genuinely computed payloads and
real delivery; do not substitute inventory setup for transport. Packaging must
remain outside the earned-compute ledger.
Phase 2 is qualified within the recorded fixture bounds, not as a full campaign
or scale/GUI sign-off. Track recovered capital versus profit with R12.

The original review changed planning/documentation only. Phase 1 and the Phase 2
accounting/customer-state/recycling/charging slices record their implemented fixes above; none
qualifies a release or authorizes restarting Luke's game.
