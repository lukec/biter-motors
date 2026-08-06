# Biter Motors Roadmap

This document is the authoritative product and release roadmap for Biter
Motors. Git history preserves superseded experiments; they are not active
design requirements.

## Release Objective

Ship a stable public alpha for Factorio 2.1 Space Age that supports a complete
new-world campaign from the crash landing through a physical AGI victory.

Every development day should close at least one public-release gap:

1. Choose a release gate, not an unrelated feature.
2. Implement the smallest complete slice.
3. Add focused static coverage.
4. Validate non-trivial mod changes in an isolated real Factorio process.
5. Preserve Luke's active playtest save when the change affects it.
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
9. A 10-gigawatt terrestrial AGI training run.

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
- Customer settlements need Sales Office coverage and local powered charging.
- Insufficient service strands affected owners and can make only those
  settlements hostile after a grace period.
- Customer growth, charging commutes, road rage, and bounded representative
  populations remain visible without requiring one Lua object per simulated
  customer.
- Healthy chargers accrue settlement growth at a utilization-weighted station
  rate, bank at most one expansion, and share a five-minute global expansion
  cooldown. A new customer settlement may still bring one hostile worm, so
  growth remains useful and dangerous without scaling linearly with every stall.

### Approved Easier-Balance Target

The next balance slice keeps the same products, profits, `5,000` consumer-sale
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
- Bitertaxi Depots target `1 Dollar per 2 allocated vehicle-minutes`,
  giving a full center approximately a `3-4` hour capex payback at saturation.

The simulator and economy report are the source of truth for these balance
assumptions. The corresponding runtime values and replacement invariants pass
isolated Factorio smoke tests; fresh-campaign playtesting remains the tuning
gate.

### Vehicles And Manufacturing

- Prototype Roadster, Premium EV, Mass-market EV, Megatruck, and Bitertaxi.
- Drivable battery simulation, nearby charging, range, braking, collision
  behavior, Self-driving, and Summon.
- Biterfactory V1 and the fast-replaceable V2 upgrade.
- Bitertaxi Depots turn fleet utilization into recurring profit.
- Cybertrain provides extreme-speed battery-electric rail freight with
  acceleration draw, regenerative braking, reserve crawl, and station charging.

### Energy And Batteries

- Upgradeable 300 kW High-density Solar Panels.
- 100 MJ, 5 MW Grid Batteries.
- Nickel, lithium, high-nickel, and LFP supply chains.
- Dirty early refining, cleaner later recipes, and 90% battery-cell recovery.
- Infinite improvements for charging, range, audio, referrals, solar output,
  and Grid Battery output.

### Terrestrial AI

- Terrestrial Datacenters consume 20 Dollars and 8 MW continuously.
- Each uninterrupted 30-second run produces 20 physical AI Tokens.
- Low power scraps the active run.
- Cumulative token milestones unlock increasingly efficient research.

## Authoritative Endgame

The endgame is physical and uses vanilla rockets, cargo pods, and space
platforms.

### Orbital AI Infrastructure

`Orbital AI Infrastructure` unlocks:

- **Orbital Datacenter Core**
  - Space-only 6x6 compute machine.
  - Draws 250 MW while operating.
  - Consumes 1 Dollar per 30-second batch.
  - Produces 10,000 physical AI Tokens per batch.
- **Orbital Radiator Panel**
  - Space-only cooling infrastructure.
  - Eight panels provide cooling capacity for one core on the same platform.
- **High-density Space Solar Panel**
  - Space-only 50 MW solar panel.
  - Competes with compute, cooling, cargo, and defenses for platform area.

Every orbital training batch resets to zero on low power or inadequate cooling.
AI Tokens must physically return to Nauvis by cargo pod. Space does not beam
energy to the planet.

Cumulative orbital output opens three explicit scale projects:

- **1M Tokens: Cluster Training**
  - Costs 5,000 Dollars plus science.
  - Unlocks 25,000-token orbital batches.
- **10M Tokens: Grid-scale Energy**
  - Costs 15,000 Dollars plus science.
  - Unlocks 50,000-token batches, 3 MW Tandem Solar Arrays, and 1 GJ Grid
    Grid Batteries as upgrades for the terrestrial energy products.
- **100M Tokens: Hyperscale Training**
  - Costs 30,000 Dollars plus science.
  - Unlocks 100,000-token batches and the final Planetary Energy Grid research.

### AGI Victory

The final progression contract is:

1. Produce 1,000,000,000 cumulative AI Tokens.
2. Package Tokens in 50,000-token AGI Training Datasets.
3. Package Dollars in 500-Dollar Capital Allocations.
4. Build a Planetary Energy Grid Controller.
5. Supply:
   - 20,000 AGI Training Datasets
   - 100 Capital Allocations
   - 100 Grid Battery Arrays
   - 10,000 Processing Units
6. Sustain the controller's 10 GW draw for 60 minutes.
7. Any low-power condition scraps the current run.
8. Producing one physical AGI Model triggers victory and continued play remains
   available.

The cumulative gate makes orbital scaling practically necessary. The physical
recipe and uninterrupted 10-gigawatt run ensure that the terrestrial factory,
capital loop, and power grid remain part of the finale.

## Public Alpha Gates

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

- [x] Choose and implement the modeled 10 GW balanced ending documented in
      `docs/economy-balance.md`; the 25 GW sensitivity is no longer a release
      candidate.
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
- [ ] Confirm the final one-hour run is demanding but recoverable after failure.

### Gate 4: Reliability And Performance

Status: **partially complete**

- [x] Bounded customer representations above the visible-unit cap.
- [x] Timing wheels and lifecycle registries for recurring customer work.
- [x] No per-customer rendered vehicle icon objects.
- [x] Existing 20,000-unit stress and commute benchmarks.
- [x] Re-run the stress suite against the renamed release candidate.
- [ ] Run a four-hour headless soak on a late terrestrial save.
- [ ] Run a one-hour soak with multiple orbital cores and platforms.
- [ ] Verify no recurring invalid-entity crashes, log spam, or second-scale
      update spikes.
- [ ] Validate save/load, reconnect, multiplayer join, and configuration-change
      behavior.

Current release-candidate baseline (Factorio 2.1.13, fixed seed `424242`):

- Luke's protected late-terrestrial save improved from a 3.00 ms warm average,
  39.68 ms p99, and 248.29 ms maximum to 1.31 ms, 16.48 ms, and 79.42 ms
  respectively in the 3,600-tick verbose comparison.
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

Status: **archive validated**

The checked items below were validated locally with the Factorio 2.1.13 engine
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

- [ ] Create the mods.factorio.com listing as an alpha.
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

## Explicit Non-Goals For Public Alpha

- No custom launch-service products or commercial SpaceX simulation.
- No Vulcanus, Fulgora, Gleba, or Aquilo campaign support.
- No military-science requirement except the intentionally humorous Customer
  Referral Program research.
- No invisible engineering-data, bandwidth-token, launch-credit, or capex
  currencies.
- No automatic compatibility guarantee for world-overhaul or enemy-overhaul
  mods.
- No new feature is allowed to delay a complete, stable AGI campaign unless it
  fixes a release-blocking problem.
