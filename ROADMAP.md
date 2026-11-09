# Biter Motors Roadmap

This document is the authoritative product and release roadmap for Biter
Motors. Git history preserves superseded experiments; they are not active
design requirements.

## Release Objective

Ship a stable **v1.0** for a validated Factorio 2.1 Space Age build, supporting
a complete new-world campaign from the crash landing through a physical AGI
victory. First stabilize and freeze the campaign, then complete Luke's final
fresh playthrough with only minor balance adjustments. Do not use that campaign
to discover unfinished endgame logistics or redesign core mechanics.

The first public archive begins the public save-compatibility contract, whether
published as a beta or v1. It requires a finishable campaign, release soak
evidence, and an exact-archive rehearsal. Optional art polish and a trailer must
not delay a proven ending.

### Remaining Plan As Of 2026-11-08

**Two milestones: a frozen, finishable private playtest candidate; then public
v1.0 after Luke completes it.** Do not start that acceptance campaign while the
ending is still being replaced. A separate public beta is optional, not another
required development phase.

Planning baseline: `7660e91`, with 255 Python tests passing and engine
**2.1.20, build 87512**. The subsequent banked-compute slice implements native
orbital pause/slowdown, retained inputs/progress, and the approved scale-tier
costs/yields. See the [new validation](docs/orbital-banked-compute-validation.md)
for current source/ZIP results; October reports remain dated evidence. The
physical Model ending is now implemented, including native orbital assembly,
cargo return and ground activation. See the [current ending contract and native
evidence](docs/endgame-validation.md). Phase 3C now implements the progressive
ending interface and persistent offline terminal; see
[terminal qualification](docs/terminal-epilogue-validation.md). Isolated native
qualification is still not a frozen, playtest-ready campaign. Phase 4 now has
[practical platform layouts](docs/orbital-platform-guide.md) and a
[source-bound logistics budget](docs/orbital-logistics-budget.md). **Next: finish
the remaining pacing, fresh-seed/prerequisite and functional-art freeze.**

The remaining phases preserve the original review's numbering: **3 through 8**.
Complete them consecutively. Each implementation slice updates its actual
artifacts, tests and remaining gaps here; completion means its exit gate passes,
not just that the code exists.

#### Phase 3: Complete The Approved Ending

Build in three consecutive slices:

1. **Banked compute and scale tiers.** Orbital low power or missing cooling
   pauses/slows work without losing committed inputs or progress. Keep ordinary
   terrestrial run-scrapping. Apply the approved research/yield changes: the
   three scale projects cost 2,000/3,000/6,000 Dollars and unlock
   50,000/100,000/200,000 equivalents per normal 20-second batch. Match direct
   Dataset yields to their Token variants and preserve native earned accounting.
   **Implemented:** [banked-compute validation](docs/orbital-banked-compute-validation.md).
2. **Physical Model and ground activation.** Assemble 20,000 physical Datasets
   plus one Rack into a Model in orbit, return it through real cargo logistics,
   and activate it in an existing Nauvis datacenter. Verify the cluster accepts
   the entire input batch. Target approximately one normal minute for assembly
   and 30 seconds for activation, not another long training/power challenge.
   Victory requires earned compute and genuine native assembly/activation;
   injected items/statistics, output extraction or machine removal must not
   fabricate or erase victory. Remove the controller, Capital Allocation fee,
   obsolete required research and old 10 GW/uninterrupted-run contract.
   **Implemented:** [physical Model ending](docs/endgame-validation.md).
3. **Ending feedback and epilogue.** Progressively reveal player-relevant
   stages. Show earned compute separately from physical payload, explain
   pause/blocker states, guide Model return and
   activation, and persist victory and per-player epilogue acknowledgement.
   Implement the approved skippable offline terminal scene from the ending
   spec. Update technology descriptions, inspectors, Progress, locale, metadata,
   fixtures and documentation together; remove obsolete finale directions.
   **Implemented:** [terminal and final presentation](docs/terminal-epilogue-validation.md).
   Native single-player checkpoints qualify thinking, reply, acknowledgement
   and replay persistence. Real graphical join/Escape/reconnect supplements
   those callbacks; simultaneous multi-player scene acceptance remains Phase 5.

**Exit gate:** an isolated native test earns the required computation, consumes
the actual payload, assembles and returns the Model, activates it, wins once,
continues play and survives a separate-process reload. Include outages/cooling
recovery, partial shipments, blocked output, immediate extraction/removal,
quality and force isolation. Do not substitute the old finale fixture.

#### Phase 4: Freeze Pacing And Functional Presentation

**Platform/logistics slice implemented:** native-exported 1/4/8/12-cluster
blueprints, [coordinate previews](docs/orbital-layout-preview.html), native solar,
real rocket uplift, physical output delivery and in-flight-work save/reloads.
The raw-Token baseline confirmed severe extraction backpressure. Entry and
Cluster Training now also offer compact Datasets at identical cost/time/energy
per equivalent, with ordinary unpacking for research and no duplicate compute
credit. See [measurement results](docs/orbital-logistics-measured.md) and the
[operating guide](docs/orbital-platform-guide.md). Ground stock and technology
are supplied in these fixtures; they do not prove a natural campaign. Phase 4
is not complete merely because these isolated layouts work.

**Next pacing decision:** the measured layout samples support a roughly
3.7-5.2-hour compute-only sensitivity with Hyperscale, or 5.8-8.6 hours without
it. These are extrapolations, not player-time bounds. The zero-opening-stock
example at 1,000 copper plates/minute takes about 8.7 modeled hours to supply
the recurring-business route's joint material bill. Check realistic existing
stock/production and the cash/material schedule before freezing the 4-6 active
hour target; do not solve a hypothetical low production rate by blindly boosting
compute. The large physical Dataset input transfer into Model assembly also
needs a practical native rehearsal beyond the existing mechanical-ending test.

- Build a practical first-cluster layout and representative 1/4/8/12-cluster
  ramps with appropriate inserters, belts and hub settings. Twelve is a sizing
  reference, not a victory gate. The basic uplift fixture's roughly 73-minute
  raw-Token extraction/return is not acceptable evidence of practical I/O.
- Recompute real research, construction, cash, power, battery-material, rocket
  and science demands from the final prototypes. Include manufacturing and
  cargo delays, and do not allocate the same blue-circuit production twice.
  Check a modest market of roughly ten settlements and an alternative to
  mandatory Bitertaxi expansion; avoid requiring limitless new nests or AFK cash.
- Aim for a major upgrade every 2-3 active hours and roughly 4-6 active hours
  for the orbital chapter. These are targets to qualify, not observed campaign
  times. The earlier 5.7-hour ideal-input model already excludes construction
  and delivery, so it cannot establish the target. Tune before the campaign.
- Audit fresh starts on at least five seeds, resource access, and every critical
  technology's ingredients, manufacturing machine and science prerequisites.
  No removed-planet material, hidden unlock or optional vehicle/quality branch
  may block the ending.
- Give the cluster, radiator and solar wing clear platform-appropriate art with
  distinct silhouettes and correct footprints. Check existing critical assets,
  locked-item filters, tier/readability cues and native UI at two scales,
  day/night and remote view. Fix functional confusion, not every aesthetic flaw.
- Freeze the spoiler-light campaign contract, default start, supported engine,
  prototype identifiers and core recipes. Move unrelated ideas to post-v1.

**Exit gate:** the new route is buildable and understandable without console
help, known mandatory money/transport stalls are resolved, and only small
numerical balance changes should be necessary during Luke's campaign.

#### Phase 5: Qualify Reliability And Scale On The Exact Archive

- Close R14's packaging gap first: use approved tracked inputs, reject secrets,
  saves/runtime files and external symlinks, derive versions/paths from the
  manifest, and finish shipped image/audio provenance and redistribution notes.
- Build a deterministic candidate ZIP and record its hash. Run broad smoke and
  relevant native regressions against source and that exact archive, including
  the new ending, new-world start, persistence and two-force behavior.
- Run the existing **four simulated-hour terrestrial** and **one simulated-hour
  multi-platform orbital** soaks. Requested benchmark updates alone do not prove
  time advanced or that the economy was working; inspect state progress too.
- Benchmark 25/100/250/500 settlements at the bounded visible-unit cap, with
  sales, growth, battery adoption, charging commutes, inspectors and grid changes.
  Profile Grid Battery installation work and charger placement/removal before
  deciding which optimizations are needed. Do not target 20,000 physical movers.
- Test real two-player join/reconnect, ownership/force boundaries, save/load,
  harmless configuration changes, fast replacements and hidden-entity cleanup.

**Exit gate:** no runtime errors, lost progress, duplicated rewards, unbounded
backlogs or recurring second-scale hitches. Meet existing measured budgets:
average <=8 ms, warm p99 <=16.667 ms and warm maximum <=100 ms on the recorded
test machine/workload. A failing gate produces a focused fix and rerun, not a
blanket rewrite or another feature branch.

#### Phase 6: Rehearse Installation And Declare Playtest Ready

- Install the exact candidate into clean user directories with only declared
  dependencies; create, save, reload and join single/multiplayer worlds.
- Have one outside player complete the early customer/manufacturing loop
  without developer coaching. Fix demonstrated discovery blockers.
- Publish the candidate manifest, supported configuration, short player guide,
  known limitations and save/backup procedure. Freeze its version, ZIP hash,
  settings and campaign seed; no source-symlink-only acceptance run.

**Milestone A: ready for Luke's final playtest.** Phases 3-6 pass, no P0/P1 or
known path-blocking P2 remains, and a native rehearsal reaches the actual new
victory. Launching your fresh campaign is an explicit handoff, not an automatic
server/client restart or a replacement of your current save.

#### Phase 7: Finish One Real Fresh Campaign

- Play non-sandbox from the approved landing kit through Model activation and
  victory, without refunded cash, injected compute or developer-only unlocks.
- Keep milestone saves and bounded read-only records of time, earnings,
  research, power, population, production and AI output. No external coach or
  telemetry system may be required for the mod to function.
- Allow logged small numeric balance adjustments. Treat a crash, softlock,
  state loss or major pacing redesign as an RC defect: preserve a backup, fix
  and retest the affected gate, then explicitly decide whether earlier campaign
  evidence remains valid. Never silently reset the game.
- Save/reload after victory and verify continued freeplay. Capture a few
  spoiler-light, physically plausible gameplay scenes with Luke's approval;
  never reposition the live player/vehicle merely to obtain a screenshot.

**Exit gate:** one complete, understandable and enjoyable campaign with no
critical workaround and credible pacing. The isolated fixture proves mechanics;
this playthrough proves the game hangs together.

#### Phase 8: Publish And Support V1

- Apply only approved final fixes. Rehearse the numeric 1.0.0 metadata/package
  version; if bytes change, rebuild and rerun affected gates and exact-archive
  installation, including loading campaign checkpoints and the won save.
- Finalize changelog, requirements, supported version, known issues, licenses,
  asset provenance, feedback channel and a small set of real gameplay images.
- Tag the exact release source, upload its validated ZIP to the mod portal,
  download it independently and verify install/load before announcing it.
- Start the public save-compatibility contract at that first public archive.
  Triage crashes, broken saves and progression blockers before adding features.

**Milestone B: shipped.** The public download installs and reproduces the
campaign we tested. A YouTube trailer, more marketing art, comprehensive art
replacement, new vehicles/chemistries, Diners, Humanoid Robots, hyperscalers and
other new mechanics are not release blockers.

**Immediate next implementation:** Phase 3C's ending feedback and skippable
terminal epilogue, followed by the Phase 4 practical platform/pacing freeze.
Orbital Model assembly, native return and Nauvis activation have replaced the
controller/capital finale. No player save or live process was changed by this
implementation; the development mod symlink will load this source on a later
restart, not hot-reload it into the running world.

### Current Review And Consecutive Plan

The [2026-10-05 v1 readiness review](docs/v1-readiness-review.md) supplies the
findings and dated evidence; the remaining plan above governs current work.
Reviewed commit: `54c12ac`; baseline engine: **2.1.20**.
The reviewed source could not load on that build. **Phase 1 is now complete:**
the compatibility defect is fixed, isolated source and exact-archive smoke
tests pass without a shim, and validators/soaks reject incomplete evidence.
The [dated baseline](docs/validation-baseline.md) records the tests and limits.
Passing Python tests, short harness checks, and historical 2.1.14 results are
not current release qualification.

Complete these phases in order; the review defines their findings, artifacts,
and acceptance tests:

1. **Current-version baseline:** compatibility and trustworthy validators/soaks.
2. **Authoritative progression:** production/sales accounting, customer state,
   capacity sharing, service health, and recycling correctness.
3. **Physical endgame:** reachable orbital uplift, banked physical compute,
   orbital Model construction, ground activation, and reliable victory.
4. **Design freeze:** prototype-backed economy/guidance and functional art QA.
5. **Qualification:** terrestrial/orbital soaks, settlement scaling, persistence,
   and multiplayer tests against the exact candidate archive.
6. **RC rehearsal:** clean install, package/provenance, and outside-player check.
7. **Final fresh playthrough:** real earnings, orbital output, physical Model
   return and ground activation with a frozen engine/mod configuration.
8. **V1 publication:** validated 1.0.0 archive, tag, portal download verification.

**Phase 2 is complete:** production, confirmed sales, and profit accounting
have been separated and validated in isolated native worlds and the exact ZIP.
The [accounting evidence](docs/accounting-validation.md) includes genuine
manufacturing, customer-backed sales, canceled transactions, quality, and a
separate save/reload. **R06/R07 are now fixed:** bounded purchase-history cohorts
keep physical and virtual customers independent, conserve replacement owners,
and retain virtual-only settlements through rebuilds and normal mod updates.
The [customer-state evidence](docs/customer-state-validation.md) records real
sales, cancellation, death, save/reload, and configuration-change tests.
**R08/R11 are now fixed:** rewritten reverse recipes match terrestrial builds,
damaged packs wait intact for 90% recovery, and ambiguous vehicle/charger scrap
cannot invent advanced chemistry. The [recycling evidence](docs/recycling-validation.md)
includes native crafting, quality, vehicle destruction, robot mining, and a
separate partial-batch save/reload. **R09/R10 are now fixed:** contested chargers
share stall-sized capacity; taxi/private service health, mood, alerts, and local
growth agree; pending buyers count once across models. The
[charging evidence](docs/charging-validation.md) records native removal,
brownouts, grace/anger/recovery, multi-office transactions, and separate reload.
All four focused regressions and broad smoke pass on source and the exact ZIP.
**Phase 3 is reopened as of 2026-10-07.** The earlier fixtures passed within
their recorded bounds, but supplied hardware directly on platforms instead of
qualifying rocket uplift. The orbital entry slice has compact hardware, portable
weights, one-radiator cooling and research without white science; see the
[orbital-entry evidence](docs/orbital-entry-validation.md). Compressed Dataset
output, ordinary packaging, and native-event
AI accounting are implemented. The
[AI payload/accounting evidence](docs/ai-accounting-validation.md) records real
compute output, quality, native bonus events, blocked output, immediate recipe
changes/removal, force isolation, physical inserter extraction, and separate
reload. Earned Token equivalents exclude inventory transfers, packaging, and
item-statistics injection. The old controller's R04/R05 regressions are dated
evidence, not the present design. Native Model assembly, real downward cargo,
ground activation, completion latching and persistence now replace that path;
see the [current ending contract](docs/endgame-validation.md). Orbital work
banks committed inputs and progress; ordinary terrestrial AI still scraps
failed batches. **Phase 4's first slice is implemented:**
the [economy/guidance evidence](docs/economy-guidance-validation.md) records
native research costs/throughput, optional-route guidance, genuine business
profit versus recovered capital, and three source-hashed finite-market models.
The artwork index is repaired with current assets and explicit reuse gaps.
The subsequent practical-platform slice adds early compact Dataset output and
lossless unpacking without changing per-equivalent cash, compute time or power.
Its [measured logistics budget](docs/orbital-logistics-measured.md) includes
concrete hardware, shared manufacturing demand and explicit scope limits.
**Phase 4 remains open; Phases 5-8 are outstanding**.
The final playthrough begins only after Phases 1-6. Luke approved the
50,000-equivalent Dataset on 2026-10-06 and shortened the implemented terrestrial
finale to 20 minutes the same day. The 2026-10-07 design below supersedes that
finale, not its historical validation results. No new company, planet, battery
chemistry, or future feature branch belongs in this release sequence.

### Orbital Ending Direction And Cost Study

The [orbital AGI ending spec](feature_specs/orbital_agi_ending.md) and
[cost study](docs/orbital-ending-cost-study.md) define the next implementation
slices. **Orbital entry, banked compute, scale tiers and the physical Model
finale are implemented.** The terminal scene and campaign freeze remain next.

- Reuse ordinary rockets and the existing terrestrial supply chains. Approximately
  twelve compact compute clusters are a balancing reference, not a count gate.
- Assemble one billion physical training equivalents into an orbital AGI Model,
  return it to Nauvis, and activate it in an existing datacenter. Remove the
  special terrestrial controller, final capital package and required white science.
- Orbital power/cooling shortages pause work rather than erase it. Ordinary
  terrestrial training still scraps a failed run. Victory remains persistent;
  the spec contains a short offline post-victory terminal scene.
- The proposed ideal AI/research bill is about 21,200 Dollars. Modest recurring
  income reaches the model's completion in about 5.7 hours, excluding manufacture,
  exploration, building and cargo delays. A 4-6 active-hour chapter is unproven.
- The 2026-10-07 capture exposed an unlaunchable 1.2-tonne core and 250-kg
  Dollars. The 2026-10-08 entry slice replaces these with explicit 100-kg
  clusters and 10-g Dollars, plus 25-kg wings, 100-kg radiators and a 1-kg Model.
  The native entry fixture now manufactures, launches, builds, computes,
  returns 10,000 Tokens and survives reload on source and the exact ZIP.
  It also captures the tighter ten-slot cargo-pod inventory. Basic Token
  extraction is slow; upgraded I/O belongs in final blueprint/pacing qualification.
- A staged 1/4/8/12-cluster build needs 49 modeled separate-item launches before
  extra cash top-ups, about 4,500 blue circuits for hardware/launches and another
  4,500 for remaining research. It must use spare production, not double-count stock.

First-cluster rocket uplift and banked compute/scale tiers are implemented and
tested. Proceed with Model assembly, return and activation; finish native UI/epilogue and functional
satellite art; requalify source/exact ZIP, soaks and RC installation. The
current private save and live processes remain unchanged by this cost study.

Every development day should close at least one public-release gap:

1. Choose a release gate, not an unrelated feature.
2. Implement the smallest complete slice.
3. Add focused behavioral regressions; static coverage alone is insufficient.
4. Validate non-trivial mod changes in an isolated real Factorio process.
5. Back up any player save before live operations; use isolated copies for
   validation. A fresh final campaign does not require migrating private alphas.
6. Commit and push the completed slice.

## Product Identity

- Player-facing name: **Biter Motors**
- Factorio mod id: `bitermotors`
- Prototype prefix: `bitermotors-`
- Package source: `mod/bitermotors_0.1.1`
- Supported world: Nauvis and stationary platforms in Nauvis orbit
- Required expansion: Space Age
- Current status: alpha

`FactoryX`, `factoryx`, and the `x-` prototype prefix are retired. They are not
aliases, product names, or public compatibility contracts.

Player-facing terminology and internal identifiers use the same Biter Motors
vocabulary: **Biterfactory**, **Bitertaxi**, **Grid Battery**, **Structural
Casting**, and **Self-driving**. The private alpha save is rewritten during the
0.1.1 namespace migration; release builds do not retain legacy prototype or
runtime identifiers.

## Campaign Vision

The boss sent the player to complete an industrial colony on Nauvis. The
advance party never arrived. The player recovers a finite cache from the
wreckage, rebuilds terrestrial industry, converts hostile settlements into an
uneasy customer base, and discovers that every successful product creates a
larger power and logistics problem.

The campaign grows through:

1. Industrial supply-chain acceleration.
2. Prototype EV sales and physical reservations.
3. Premium and mass-market manufacturing.
4. Charging networks, customer growth, and grid pressure.
5. Battery minerals, waste, recycling, solar, and Grid Batteries.
6. Biterfactories, Bitertaxis, autonomous logistics, and Cybertrains.
7. Terrestrial AI funded by ongoing profit.
8. Physical orbital AI infrastructure.
9. Physical orbital AGI Model return and ground activation (implementation pending).

The commercial launch-service, booster-sales, satellite-bus, ground-station,
and Planetary Grid Segment branches are removed. Space is a compute location,
not a second simulated company.

## Implemented Core

### Fresh Start

- Narrative crash landing with a finite, solar-first recovery cache.
- Accelerated basic research and recovered robotics equipment.
- No prebuilt factory; the player must establish real production.
- Other Space Age planets and their unsupported progression are hidden.

### Customer Economy

- Sales Offices sell physical products for physical Dollars.
- One Dollar represents roughly US$10,000 of investable profit.
- EV Reservations are physical paperwork moved by belts or bots.
- Sales require living prospects and assign sold vehicles to specific mobile
  customers.
- Private EV markets need Sales Office coverage and local powered charging.
- A powered, stocked Bitertaxi Depot independently discovers and serves
  settlements within 256 tiles; one Bitertaxi supports five customers, up to
  1,000 customers per depot, without requiring a Sales Office.
- Insufficient service strands affected owners and can make only those
  settlements hostile after a grace period.
- Customer growth, charging commutes, road rage, and bounded representative
  populations remain visible without requiring one Lua object per simulated
  customer.
- Healthy chargers accrue settlement growth at a utilization-weighted station
  rate, bank at most one expansion, and share a five-minute global expansion
  cooldown. A new customer settlement may still bring one hostile worm, so
  growth remains useful and dangerous without scaling linearly with every stall.

### Current Easier-Balance Baseline

The intended balance keeps the same products, profits, `5,000` consumer-sale
Bitertaxi gate, `1B` cumulative AI Token objective, and final AGI endgame. It
reduces the capital squeeze and lets developed settlements support continued
sales:

- Research Dollar costs target: V2 Charging Network `150`, Capital Scaling
  `600`, Terrestrial AI `750`, Autonomous Logistics `750`, and Orbital Compute
  `1,500`.
- Sale profits remain unchanged: Roadster `2`, Premium EV `1`, Mass-market EV
  `1`, Megatruck `2`, and Grid Battery `20` Dollars.
- Customers may make one replacement purchase for each consumer generation:
  Roadster, Premium EV, Mass-market EV, and Megatruck. The active vehicle is
  replaced rather than creating an unbounded sale loop.
- Organic represented prospects grow locally at a bounded rate, with a cap of
  three times each settlement's starting representation. A shortage suspends
  only the affected settlement; healthy settlements continue growing.
- Charger radii target `64 / 128 / 192 / 256` tiles for V1 through V4.
- Bitertaxi Depots target `1 Dollar per 2 allocated vehicle-minutes`. Following
  playtest feedback, each fleet now costs 20 Dollars; a full center therefore
  targets approximately a 42-minute direct-capital payback at saturation.

The simulator and economy report record these assumptions. The v1 review found
accounting defects and missing model costs; reconcile both with final prototypes
and behavioral tests before treating them as reliable campaign evidence.
Historical fixture smoke tests are not proof of correct fresh-world sale gates.

### Vehicles And Manufacturing

- Prototype Roadster, Premium EV, Mass-market EV, Megatruck, and Bitertaxi.
- Drivable battery simulation, nearby charging, range, braking, collision
  behavior, Self-driving, and Summon.
- Terrestrial Stack Inserters followed by reachable space-era belt-capacity
  research for three- and four-high belt stacks.
- Biterfactory V1 and the fast-replaceable V2 upgrade.
- Bitertaxi Depots turn fleet utilization into recurring profit, independently
  pacify covered settlements, and expose service coverage in remote view.
- Cybertrain provides extreme-speed battery-electric rail freight with
  acceleration draw, regenerative braking, reserve crawl, and station charging.

### Energy And Batteries

- Upgradeable 300 kW High-density Solar Panels.
- 100 MJ, 5 MW Grid Batteries.
- Nickel, lithium, high-nickel, and LFP supply chains.
- Dirty early refining, cleaner later recipes, and 90% battery-cell recovery.
- Battery MK3 equipment built from Battery MK2 equipment and Biter Motors
  high-energy packs instead of inaccessible Fulgora supercapacitors.
- Infinite improvements for charging, range, audio, referrals, solar output,
  and Grid Battery output.

### Terrestrial AI

- Terrestrial Datacenters consume 20 Dollars and 8 MW continuously.
- Each uninterrupted 30-second run produces 20 physical AI Tokens.
- Low power scraps the active run.
- Cumulative token milestones unlock increasingly efficient research.

## Implemented Endgame

This section records the **current Lua**. The
[orbital AGI ending spec](feature_specs/orbital_agi_ending.md) defines the current
contract; [native ending evidence](docs/endgame-validation.md) distinguishes
mechanics qualification from the still-required final campaign.

The endgame is physical and uses vanilla rockets, cargo pods, and space
platforms.

### Orbital AI Infrastructure

`Orbital AI Infrastructure` unlocks:

- **Orbital Compute Cluster**
  - Space-only 3x3 compute machine.
  - Draws 250 MW while operating.
  - Consumes 1 Dollar per recipe batch: 30 recipe-seconds, or 20 seconds in a
    normal-quality core at its current 1.5 crafting speed before other effects.
  - Produces 10,000 physical AI Tokens per batch.
- **Orbital Radiator**
  - Space-only cooling infrastructure.
  - One radiator cools one cluster on the same platform and force.
- **Space Solar Wing**
  - Space-only 20 MW nominal solar panel; 60 MW continuously in Nauvis orbit.
  - Five wings generate 300 MW for one 250 MW cluster.
  - Competes with compute, cooling, cargo, and defenses for platform area.
- **Advanced Asteroid Processing**
  - Follows Orbital AI Infrastructure.
  - Provides renewable copper, sulfur, and calcite through advanced crushing.
  - Infinite Asteroid Productivity uses AI Tokens instead of removed
    agricultural science.

Entry research and the three compute scale tiers no longer require white
science. Player hub requests must use custom minimum payloads for small
hardware/cash shipments rather than waiting for full rockets.

Orbital low power slows/stops native crafting without canceling inputs or
progress. Missing cooling pauses the cluster with a yellow status and resumes
the same committed batch when restored. Ordinary terrestrial compute still
scraps failed runs.
Tokens for science physically return to Nauvis by cargo pod. Retain the compact
Dataset payload in orbit, assemble the Model there, and return that Model.
Space does not beam energy to the planet.

Cumulative orbital output opens three explicit scale projects:

- **1M Tokens: Cluster Training**
  - Costs 2,000 Dollars plus science.
  - Unlocks 50,000-token orbital batches or one direct Training Dataset per
    Dollar in 20 normal seconds.
- **10M Tokens: Grid-scale Energy**
  - Costs 3,000 Dollars plus science.
  - Unlocks 100,000-token batches or two directly computed Training Datasets per
    batch, ordinary Dataset packaging, 3 MW Tandem Solar Arrays, and 1 GJ Grid
    Batteries as upgrades for the terrestrial energy products.
- **100M Tokens: Hyperscale Training**
  - Costs 6,000 Dollars plus science.
  - Unlocks 200,000-token batches or four directly computed Training Datasets
    per batch. This is an efficiency option, not permission to win.

Both payload forms use the same Dollars, recipe time, power, and cooling as
their tier. Starting Orbital Compute can already group five raw batches into
one direct Dataset for 5 Dollars in 100 normal seconds. Return a few Datasets
and unpack them in ordinary assemblers for research; keep the final archive in
orbit. Each Dataset represents 50,000 Token equivalents; 20,000 Datasets
embody the billion-equivalent final payload. Datasets stack to 1,000 and weigh
1 kg each. No downward Dataset shipments are required for the final craft;
only the resulting 1 kg Model must return to Nauvis.
Separate native completion ledgers track terrestrial and orbital computation.
Packaging/unpacking existing payload, recycling, and transfers cannot earn progress again.

### AGI Victory

The implemented final progression contract is below. Native computation,
compressed payload, orbital assembly, native cargo return, ground activation
and completion latching have focused engine coverage.
Economy/design freeze, candidate scaling/soaks/multiplayer, clean-install
rehearsal, and the natural final campaign remain required before release.

The current recipe sequence is:

1. Compute 1,000,000,000 cumulative AI Token equivalents.
2. Produce compact Training Datasets directly in grid-scale/hyperscale orbital
   cores, or package existing Tokens in ordinary assemblers or Biterfactories.
3. With Grid-scale Energy researched, assemble 20,000 AGI Training Datasets and
   one Datacenter Rack in an Orbital Compute Cluster: one normal minute.
4. Extract the Model into that platform's hub and request it at a Nauvis Cargo
   Landing Pad. Native delivery unlocks activation.
5. Feed it into an existing Terrestrial Datacenter and select Activate AGI
   Model: 30 normal seconds at the ordinary 8 MW; the Model returns as output.
6. Native activation consumes the same force/quality's returned-Model credit
   and latches victory once. Continued freeplay remains available.

Orbital assembly and ground activation preserve progress and committed inputs
through interruptions. Ordinary terrestrial AI still scraps failed runs. Earned
compute and native assembly/return/activation are required; injected inventory
or statistics do not win. Extraction, recipe changes, removal and reload do not
erase completed milestones. Hyperscale is optional, with no separate capital
package, final-controller building, white science or long power countdown.

## Public Beta Gates

The following gates preserve prior implementation work and **dated** evidence.
They are not a current pass certificate. The consecutive v1 plan above now
governs remaining work; do not re-open completed naming work or add features
merely to fill the old beta sequence.

### Gate 1: Product Coherence

Status: **complete**

- [x] Standardize all public and internal naming on Biter Motors.
- [x] Rename the mod id, package, prototypes, commands, remote interface, art
      paths, validators, and tests.
- [x] Rename Cybertruck to Megatruck and Electric Semi to Cybertrain.
- [x] Remove the contradictory custom launch-business endgame.
- [x] Implement physical orbital compute, cooling, power, token return, and AGI.
- [x] Convert Luke's active private playtest save without resetting progress.

### Gate 2: Legal And Release Artifacts

Status: **complete**

- [x] Add the chosen source-code license.
- [x] Add an explicit asset license and exclusions for third-party Factorio
      assets.
- [x] Add `ATTRIBUTION.md`, including MIT-licensed electric-vehicle inspiration
      and any third-party tools or source material actually incorporated.
- [x] Add `CHANGELOG.md`.
- [x] Add a reproducible packaging script that produces
      `bitermotors_<version>.zip` with the correct root directory.
- [x] Add CI for static tests, archive layout, forbidden namespace scans, and
      release metadata.
- [x] Clearly mark the generated art QA index as historical development
      material; it is not part of release archives.

### Gate 3: Campaign Completion

Status: **playtest required**

- [x] Implement the physical orbital Model and ground-activation ending in
      `feature_specs/orbital_agi_ending.md`; retire the controller/capital finale.
- [x] Make completed AI production cycles the authoritative cumulative counter
      for progression, the Compute panel, the AGI gate, and victory metadata.
- [x] Add a read-only endgame status contract for token tracks, orbital cooling,
      core reset state, and AGI readiness.
- [ ] Complete one non-sandbox campaign from a fresh crash landing to the AGI
      Model.
- [ ] Record milestone time, profit, power, production, customer, and token
      telemetry.
- [ ] Verify every progression gate is discoverable without console commands.
- [ ] Tune research and recipes from observed bottlenecks, not isolated item
      costs.
- [ ] Confirm the terrestrial-to-orbital transition creates a real order-of-
      magnitude scaling requirement.
- [ ] Qualify genuine rocket uplift, banked orbital compute, physical Model return
      and ground activation under the replacement ending spec.

### Gate 4: Reliability And Performance

Status: **partially complete**

- [x] Bounded customer representations above the visible-unit cap.
- [x] Timing wheels and lifecycle registries for recurring customer work.
- [x] No per-customer rendered vehicle icon objects.
- [x] Existing 20,000-unit stress and commute benchmarks.
- [x] Re-run the stress suite against the renamed release candidate.
- [x] Add an exact-archive soak harness with terrestrial and orbital fixture
      requirements, runtime-error detection, periodic state probes, and
      explicit average/p99/spike thresholds.
- [x] Coalesce sale and population demand invalidations instead of rebuilding
      the full customer market graph for every event.
- [x] Cache unchanged per-stall charger power-sink configurations.
- [ ] Run a four-hour headless soak on a late terrestrial save.
- [ ] Run a one-hour soak with multiple orbital cores and platforms.
- [ ] Verify no recurring invalid-entity crashes, log spam, or second-scale
      update spikes.
- [ ] Validate save/load, reconnect, multiplayer join, and configuration-change
      behavior.

Historical release-candidate baseline (Factorio 2.1.14; not requalified on 2.1.20):

- Luke's protected late-terrestrial save, containing 221 settlements, 9,229
  represented owners, 156 chargers, 20 Sales Offices, and about 2,000 visible
  customer units, improved from 2.17 ms warm average, 12.16 ms p95, 24.53 ms
  p99, and 287.22 ms maximum to 1.36 ms, 6.54 ms, 15.05 ms, and 55.42 ms in the
  exact 3,600-tick verbose comparison.
- A 36,000-tick soak of the same save completed without a script error at
  1.75 ms average and 83.54 ms maximum; the earlier soak was 3.93 ms average
  and 1,129 ms maximum.
- 2,000 represented owners cost 1.13 ms while stationary, 1.93 ms with up to
  128 commanded movers, and 2.40 ms with up to 512 commanded movers.
- 20,000 physical biters cost 25.76 ms while stationary before ownership
  bookkeeping. This confirms that Factorio's native unit simulation, not one
  remaining Lua scan, makes fully physical 20,000-customer populations
  incompatible with 60 UPS. Production therefore keeps the bounded visible
  representative model.

### Gate 5: Interface And Art

Status: **functional, not final**

- [x] Progressive Biter Motors Progress panel.
- [x] Native-style entity inspectors, alerts, coverage, and map guidance.
- [x] Distinct vehicle sprites and major terrestrial building artwork.
- [ ] Final orbital core, radiator, and space-solar art pass.
- [ ] Final icon/readability audit at 16, 32, and 64 pixels.
  - [x] Replace clean battery recipe module badges with dedicated process art.
  - [x] Replace composed placeholder icons for Biterfactory V2, Tandem Solar
        Array, Grid Battery Array, Wrecked EV, eSpider, Electric Drivetrain,
        Autonomy Computer, Orbital Radiator, and Space Solar.
  - [ ] Decide which unique Biter Motors technology families need dedicated
        art instead of a vanilla technology image plus the common mod badge.
- [ ] Animation and footprint audit for every placeable Biter Motors entity.
- [ ] Remove obsolete launch-business art from generated QA pages.
- [x] Add benefit-led marketing copy while preserving the illustrated campaign
      narrative.
- [x] Add an unretouched live-save factory-floor capture to the repository
      README.
- [ ] Build a separate, physically plausible showcase save for repeatable media
      capture. Review each staged scene with Luke before recording.
- [ ] Capture spoiler-light native gameplay screenshots and short loops for EV
      driving and charging, the biter customer economy, and Biterfactory scale.
- [ ] Verify final media readability at GitHub desktop and mobile widths.

### Gate 6: Compatibility Contract

Status: **source/ZIP load qualified on 2.1.20; broader release qualification open**

The checked items below were validated locally with the Factorio 2.1.14 engine
using an isolated user directory and the exact packaged archive. CI reproduces
the static, unit, metadata, and deterministic-package checks; it does not bundle
or execute Factorio.

- [x] Publish `COMPATIBILITY.md`.
- [x] Define the first portal release as the beginning of the public save
      compatibility contract.
- [x] State Nauvis-and-orbit overhaul boundaries and expected mod conflicts.
- [x] Test a release archive on a clean Factorio user directory.
- [x] Test new single-player and multiplayer worlds with only declared
      dependencies.

The repeatable terrestrial and orbital soak procedure, profile requirements,
performance gates, and result artifacts are documented in
`docs/soak-testing.md`.

### Gate 7: Release Candidate

Status: **not started**

- [ ] Freeze features.
- [ ] Resolve every P0/P1 issue from the release audit.
- [ ] Package an RC archive from a clean commit.
- [ ] Install that exact archive, create a new world, save, reload, and join it.
- [ ] Have at least one outside player complete the terrestrial loop.
- [ ] Tag the RC commit only after the archive and portal metadata agree.

### Gate 8: Portal Publication

Status: **not started**

- [ ] Create the mods.factorio.com listing as a beta.
- [ ] Use the marketing README and spoiler-light screenshots.
- [ ] Upload and verify the selected gameplay images in the mod portal gallery.
- [x] Write a spoiler-light gameplay trailer storyboard and capture contract.
- [ ] Record, edit, caption, and publish the gameplay trailer on YouTube; link it
      from the repository README and mod portal.
- [ ] Publish requirements, compatibility, known issues, and feedback channel.
- [ ] Upload the exact validated archive.
- [ ] Verify the portal download installs and loads independently.
- [ ] Triage launch feedback before adding new feature branches.

## Compatibility Policy

The detailed contract is in `COMPATIBILITY.md`.

The one-time conversion from Luke's private `factoryx` development save is not
a public migration promise. Public save compatibility begins with the first
mods.factorio.com build using the `bitermotors` id.

## Post-Alpha Candidates

These are candidates only after the release gates above:

- Biter Diner with fish breeding and high-capacity destination charging.
- Megatruck customer art and additional vehicle polish.
- Humanoid Robot manufacturing and a Biterfactory V3.
- Hyperscale terrestrial datacenters with escalating capital costs and
  settlement opposition.
- Solar-roof modules for compatible factories.
- Orbital heat-network simulation if it is clearer and more robust than the
  current explicit radiator-capacity contract.
- Alternative post-victory scorecards for autonomous abundance or sustained
  compute civilization.
- [x] **Fast electric eSpider:** clones the native SpiderVehicle and all eight
  leg prototypes, with faster native stepping instead of Lua-forced movement.
  Its factory configuration installs four Battery MK3 units, four exoskeletons,
  and four Tesla guns; draws 8 MW before equipment load; works with every Biter
  Motors charger; and uses the standard Spidertron remote and logistics UI. A
  hidden low-speed reserve lets a depleted unit limp home. The isolated engine
  benchmark measured 443.8 tiles in ten seconds versus vanilla Spidertron's
  130.0, or about 3.41x the travel and roughly 160 km/h. Battery endurance is
  approximately two minutes at sustained full stride.

## Explicit Non-Goals For Public Beta

- No custom launch-service products or commercial SpaceX simulation.
- No Vulcanus, Fulgora, Gleba, or Aquilo campaign support.
- No military-science requirement except the intentionally humorous Customer
  Referral Program research on the commercial critical path. The optional
  Megatruck's Tank prerequisite is an existing exception to confirm in the
  pre-freeze design pass; military research must not gate the AI ending.
- No invisible engineering-data, bandwidth-token, launch-credit, or capex
  currencies.
- No automatic compatibility guarantee for world-overhaul or enemy-overhaul
  mods.
- No new feature is allowed to delay a complete, stable AGI campaign unless it
  fixes a release-blocking problem.
