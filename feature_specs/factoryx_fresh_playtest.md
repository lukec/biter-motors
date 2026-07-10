# FactoryX Fresh Playtest: Immediate Pre-Run Changes

## Purpose

Prepare one clean, non-sandbox FactoryX run that can be played from arrival
through every currently reachable terrestrial and space milestone. The run must
produce enough evidence to answer balance questions after the fact without the
coach changing the factory being measured.

This is an implementation specification for the next turn. It does not change
the mod or coach yet.

## Decisions For This Run

- Use ordinary Freeplay with Space Age and FactoryX enabled. Do not use Sandbox,
  Editor Extensions, creative chests, console-created resources, or research
  cheats.
- Leave `FactoryX accelerated start` enabled. Its current light start grants
  basic industrial research and wreckage supplies, but places no factory.
- Do not add the previously brainstormed 40 MW legendary solar/accumulator and
  robotics cache before this run. That would bypass the early power and
  logistics constraints we need to measure. Reconsider it after reviewing the
  first playtest timeline.
- Keep the currently implemented Planetary Energy Grid victory for this run.
  AGI victory and the terrestrial Hyperscaler remain roadmap designs until
  token rates from this run give us evidence for their scale.
- The coach must run in a dedicated read-only playtest mode. Ordinary coach
  mutations would contaminate production timings and bottleneck evidence.

## P0: Fresh-Game Gate

These changes must be complete before creating the save. Mod startup settings
and prototype changes cannot be cleanly evaluated if added after map creation.

### 1. Add A Real Freeplay Bootstrap Smoke Test

Create a disposable new Freeplay map with the exact intended mod set and assert:

- Factorio 2.1, Space Age, quality, and FactoryX load successfully.
- `x-accelerated-start` is true.
- The starting force owns exactly the documented bootstrap technologies.
- The crashed ship and wreckage contain the documented item sets and no
  creative/sandbox items.
- The FactoryX introduction text is registered.
- Enemy expansion, evolution, pollution, day/night, and achievements are not
  disabled by scenario or test settings.
- Sales Office is visible as the first FactoryX research goal.
- The Prototype Roadster path is initially locked and becomes reachable through
  the intended Sales Office, charger, customer, and reservation milestones.
- Space Age remains the only space framework; no duplicate vanilla/FactoryX
  launch progression is accidentally exposed early.

The test must create and discard its own save. It must not mutate Luke's future
playtest save.

### 2. Add A Dedicated Robotaxi Service Center Runtime Gate

The general smoke test currently proves that the mod still runs, but it does
not exercise a live Service Center. Add a focused engine scenario that verifies:

- Two overlapping centers never count one customer twice.
- Customers choose the nearest stocked center deterministically.
- An empty center does not claim demand from a stocked center.
- A full Dollar output pauses revenue and attrition without accumulating a
  deferred payout.
- Low power reduces service; zero power stops it.
- Reload/reconciliation leaves exactly one hidden 10 MW helper per center and
  removes orphans.
- Mining and robot-mining a center remove its helper and runtime state.

### 3. Establish A Performance Baseline

Benchmark the RSC and customer loops against a disposable copy of the largest
available customer-heavy save. Record UPS/update time with:

- The current customer population.
- One stocked Service Center.
- Four overlapping stocked Service Centers.
- Full power, low power, and no power.

The acceptance target is no visible UPS loss at the current population and no
new once-per-second operation above 10 ms on Luke's machine. If the
force-wide nearest-center scan exceeds that budget, phase customer allocation
across ticks or cache assignments until centers, inventories, or customers
change.

## P0: Read-Only FactoryX Playtest Coach

Add a single launch profile rather than requiring a fragile list of negative
flags:

```sh
scripts/start-factoryx-playtest-coach.sh --session fresh-01
```

The profile must:

- Connect through the supported RCON/companion path.
- Observe and record while Luke is connected.
- Never place, mine, upgrade, deconstruct, request, insert, remove, research,
  change recipes, alter schedules, pause combat, or rewrite modules.
- Disable advice chat by default so prompts do not affect play decisions.
- Disable host auto-pause and empty-server mutation; simply stop sampling while
  no player is connected.
- Continue bounded state sync and performance logging.
- Refuse to start if any mutation subsystem remains enabled. Print the exact
  enabled subsystem and exit nonzero.
- Write its PID/session metadata so it can be stopped and resumed into the same
  playtest directory.

Implement the safety boundary as an explicit `--playtest-record` mode checked
centrally by the scheduler. Do not rely only on wrapper-script flags. Add tests
that enumerate all registered mutators and prove that the profile disables each
one.

## P0: Timestamped Playtest Recorder

### Output Layout

All generated evidence is local runtime output and must remain gitignored:

```text
playtests/fresh-01/
  session.json
  timeline.jsonl
  snapshots/
    20260710-193000-tick-001234500-periodic.json
    20260710-193412-tick-001248900-milestone.json
  frames/
    20260710-193000-tick-001234500-periodic.png
    20260710-193000-tick-001234500-periodic.json
  notes.jsonl
  coach-perf.jsonl
  postplay-report.md
```

Use UTC ISO-8601 inside JSON and a filesystem-safe UTC timestamp in filenames.
Include game tick in every filename so ordering survives clock corrections.
Write snapshots atomically through a temporary file and rename.

### Capture Cadence

- Normalized JSON snapshot every five connected gameplay minutes.
- Timelapse frame every fifteen connected gameplay minutes.
- Immediate snapshot and frame on important FactoryX milestones.
- Final snapshot when the player disconnects or the coach stops cleanly.
- Do not count paused or disconnected wall time as gameplay time.
- If a capture is slow or fails, record an error row and continue playing. The
  recorder must never pause the game to catch up.

### Milestone Captures

Capture on transitions, not on every poll:

- Technology researched.
- First placement of each FactoryX entity tier.
- First completion of each product and sale recipe.
- First Dollar, EV Reservation, AI Token, and Robotaxi service Dollar.
- New customer settlement, first angry settlement, and first restored
  settlement after a service disruption.
- Charger, Gigafactory, datacenter, or RSC power starvation lasting at least 60
  seconds.
- New terrestrial AI efficiency level.
- Launch and victory milestones.

Deduplicate with stable keys persisted in the playtest session state.

### Snapshot Schema

Each snapshot should contain only serializable observed state:

- `schema_version`, `session_id`, UTC timestamp, game tick, connected gameplay
  seconds, save identity, Factorio version, and enabled mod versions.
- Startup/map settings relevant to balance: accelerated start, pollution,
  evolution, expansion, research queue, recipe/technology difficulty, and
  peaceful mode.
- Player surface, position, health, inventory summary, and current research.
- FactoryX `progress_status`, customer-market status, continuous-improvement
  levels, AI efficiency status, vehicle ownership, and RSC status through the
  existing read-only remote interface.
- Lifetime item production and consumption for all FactoryX items, science
  packs, primary ores/plates, circuits, batteries, power products, and rocket
  components.
- Delta rates calculated from the previous snapshot using elapsed game ticks:
  items/minute, Dollars/minute, reservations/minute, EVs/minute, AI Tokens/minute,
  and science/minute. Preserve both raw cumulative counters and derived rates.
- Entity counts by name and quality for FactoryX entities, labs, assemblers,
  furnaces, miners, power generation/storage, roboports, and logistics.
- Electric-network summary by surface: generation capacity and mix, current
  production, demand, satisfaction, accumulator charge, and the largest
  FactoryX consumers where available.
- Current research ingredients, progress, estimated consumption rate, and time
  since the previous completed technology.
- Logistic stock totals for Dollars, Reservations, each EV, AI Tokens,
  Gigafactory components, energy products, and launch components. Clearly mark
  totals as network-only rather than global when that is the observation scope.
- Customer counts, friendly/angry/operational settlements, sold fleet by class,
  stalls by tier, powered stalls, reservation stock/rate, stranded EVs, colony
  growth, and RSC served/covered customers.
- Capture health: observation durations, limits hit, stale shards, missing
  domains, and errors.

Never infer a zero when a domain was not observed. Use `null` plus a structured
`missing` or `stale` reason.

### Timeline Index

Append one compact row to `timeline.jsonl` for every snapshot. It should contain
the timestamp, tick, reason, snapshot path, frame path when present, milestone
keys, current progression stage, and headline rates. The complete payload stays
in the individual snapshot file so the timeline remains easy to stream.

## P1: Screenshot And Timelapse Integration

The current coach already creates top-down PNG timelapse frames from bounded
RCON observations. They are reconstructed map images, not literal captures of
Luke's graphical client. Extend this system rather than starting a second frame
recorder:

- Point timelapse output into the active playtest session's `frames/` directory.
- Pair frame and production snapshot by the same timestamp, tick, and reason.
- Put `snapshot_path` in the frame sidecar and `frame_path` in the snapshot.
- Keep automatic bounds, but persist bounds in the session so adjacent frames
  do not zoom wildly after one remote outpost is built. Expand bounds when
  needed; do not shrink them during a session.
- Add FactoryX-specific colors for Sales Offices, each charger tier,
  Gigafactories, solar arrays, Megapacks, datacenters, and RSCs.
- Add an optional manual capture command for moments Luke wants preserved.

Explore native Factorio screenshots separately. The coach normally observes a
headless server and cannot assume access to the graphical client's camera. A
native screenshot is a bonus only if the active runtime supports it; the
deterministic top-down frame remains the required artifact.

## P1: Playtest Notes

Add a lightweight command that records human observations without changing the
game, for example:

```text
/factoryx-note Waiting on red circuits for charger V2
```

The note should append to `notes.jsonl` with timestamp, tick, player, position,
progression stage, and the text. It should also trigger an immediate paired
snapshot/frame. Notes are evidence, not chat advice, and should never invoke a
model during play.

## P1: Post-Play Balance Report

Add a deterministic report generator that consumes one session directory and
produces `postplay-report.md`. It should report:

- Real connected playtime to each technology, first build, first sale, and
  progression stage.
- Time spent with research idle and time each science pack was the limiting
  input.
- Dollar income and spending proxies by stage.
- Production-rate history for EVs, Reservations, Dollars, AI Tokens, solar,
  Megapacks, and major intermediates.
- Power headroom, brownout intervals, accumulator depletion, and which new
  FactoryX unlock first caused each material increase in demand.
- Charger utilization, unsupported customers, settlement anger/restoration,
  and whether demand paperwork or vehicle production constrained sales.
- Gigafactory and datacenter utilization, blocked-output time, missing-input
  time, and low-power time where observable.
- The first sustained bottleneck in each progression stage.
- Missing or stale telemetry so conclusions are not presented as facts when
  evidence was unavailable.

The first implementation should produce tables and concise findings. Charts can
follow after one real session proves which series are useful.

## P1: Launch Preflight

Before Luke creates `FactoryX-Fresh-01`:

1. Run unit tests, full FactoryX engine validation, fresh Freeplay bootstrap
   smoke, dedicated RSC smoke, and the customer-heavy performance benchmark.
2. Install the exact validated FactoryX directory.
3. Verify Space Age, quality, elevated rails, recycler, and FactoryX are enabled;
   disable unrelated gameplay mods for this run.
4. Record mod checksums and startup settings in a preflight manifest.
5. Confirm no Factorio/headless process is holding an older mod version.
6. Create the new save only after startup settings are verified.
7. Join the world, dismiss the intro, and confirm achievements remain available.
8. Start the read-only playtest coach and verify one initial snapshot and frame.
9. Confirm the coach's startup log says `mutation mode: disabled (playtest)`.
10. Begin play only after the session manifest and initial artifacts exist.

## Acceptance Criteria

The pre-play slice is complete when:

- A fresh real Freeplay save passes the bootstrap gate.
- The exact installed mod build is recorded.
- The coach cannot mutate the save in playtest mode.
- Initial, periodic, milestone, manual-note, disconnect, and shutdown captures
  are tested.
- Every frame can be joined to one production snapshot by tick.
- Snapshot deltas use active game ticks and survive coach restarts.
- A fixture session produces a deterministic post-play report.
- Generated playtest evidence is gitignored.
- The full coach test suite and FactoryX engine gates pass.

## Explicitly Deferred

- AGI victory implementation and its final token target.
- Terrestrial Hyperscaler implementation.
- The rich 40 MW/robotics starting cache.
- Final vehicle sprites and remaining art polish.
- Automatic balance changes during a playtest.
- Model-generated advice or analysis while Luke is actively playing.

These should be decided from the recorded run, not inserted immediately before
the baseline is measured.
