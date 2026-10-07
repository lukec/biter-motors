# Native Endgame Delivery And Cooling Validation

Date: **2026-10-06**. Mod: **Biter Motors 0.1.1**, fresh worlds only.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
This covers **R03's downward-delivery path**, alongside
the [AI accounting](ai-accounting-validation.md) and
[finale](finale-validation.md) fixtures. It is not campaign, economy, long-soak,
multiplayer, GUI, or public-release qualification.

**Qualification correction, 2026-10-07:** this fixture supplied hardware and
operating Dollars directly on the platforms. Runtime prototype capture now
shows a 1,208,326-g core (over the 1,000,000-g rocket limit) and 250,025-g
Dollars (three per rocket). Direct whole-core uplift is blocked; manufacturing
it in orbit is an untested alternative. Actual hardware/currency uplift remains
open, so Phase 3 is reopened. The old downward-delivery and controller results
below remain valid within their bounds; they do not qualify the replacement
[orbital ending](../feature_specs/orbital_agi_ending.md).

## Real Delivery Through Victory

`scripts/fixtures/delivery-control.lua` uses two genuine Nauvis platforms.
Each has 16 legendary hyperscale cores, eight real radiators per core, and
313 supplied operating Dollars per core. Unmodified native recipes produce
**10,016 Datasets per platform**. An additional core produces **10,000 physical
AI Tokens** for research. Native completion earns **1,001,610,000 equivalents**;
no milestone, native progress, or final Model is injected.

The fixture verifies this complete chain:

1. Core output is extracted by bulk inserters onto express belts.
2. Belts and inserters feed the platform hubs; research Tokens use a separate bus.
3. Nauvis landing-pad requests trigger native orbital cargo pods.
4. Both platforms deliver; pods land at the pad without ground-container spills.
5. Logistic bots supply delivered Tokens to real labs. The final technology
   completes through native research, not a scripted researched flag.
6. An AM3 constructs the controller from its actual recipe. Another AM3
   packages 50,000 supplied Dollars into 100 Capital Allocations.
7. The genuinely crafted controller is placed on an unobstructed site. Belts
   and four input inserters supply the entire final recipe; no Dataset inventory
   insertion/removal or scripted cargo-pod creation/destination override is used.
8. The controller completes **72,000 native updates at 10 GW**, producing a
   physical Model and latching victory exactly once.
9. A server-written completed save is loaded in a separate process. Advancing
   updates preserve the ledger, completed product, and first victory metadata.

| Native milestone | Simulation tick |
| --- | ---: |
| All compute complete: 20,032 Datasets and 10,000 Tokens | 150,241 |
| Final technology researched in labs | 197,563 |
| Full payload committed; training starts | 315,488 |
| Native final completion | 387,487 |
| Separate-process reload assertion | 387,491 |

Both platforms deliver all **20,032 Datasets**, of which 20,000 are required.
The fixture launches **84 automatic pods**, including research Tokens and partial
shipments. Twenty fully packed standard rocket payloads is **weight arithmetic**,
not an exact count of native downward pods. Automatic deliveries need not wait
for a full stack. See the official [Cargo landing pad](https://wiki.factorio.com/Cargo_landing_pad)
and [Space platform hub](https://wiki.factorio.com/Space_platform_hub) descriptions.

The entire supplied fixture takes about **108 simulation minutes**. That is
not a campaign-time estimate: industry, capital, terrain, prerequisites, six
science-pack types, legendary cores/labs, inserter-capacity research, and ideal
power are supplied. Orbital hardware is placed rather than lifted by player-built
rockets. Controller placement is scripted after genuine construction, not a
construction-bot placement test. `game.speed = 100` speeds wall time only.

Reports contain **720 setup, 3 compute, 355 payload, 360 final, and 4 reload
assertions**. Counts accumulate within each process and restart on load; do not
sum them as independent checks. The loader/constructor ordering matters:
feeding a future machine position spills ingredients onto the ground, and
shared named request groups overwrite other entities' filters. The final
fixture gates inserters until placement and uses ungrouped requests.

## Cooling And Failure Recovery

`scripts/fixtures/cooling-control.lua` checks two same-force platforms plus a
second-force core on the first platform:

- Seven versus eight radiators; no borrowing across platforms or forces.
- Sixteen versus fifteen radiators; oldest unit-number cores receive capacity.
- Added/removed cores, promotion after removing a cooled core, and radiator recovery.
- Removing cooling during genuine native progress resets/disables the batch.
- Full output prevents completion and earned computation; freeing output
  permits one real completion.
- One active 250 MW core with one **125 MW** source: partial power resets its
  active run instead of completing slowly. The other core is explicitly idle.
- Complete source removal, a held-failure checkpoint, and separate-process
  reload. Restoration produces exactly one **new** batch: **10,000 new physical
  Tokens and 10,000 new ledger equivalents**, not an old output item.
- Platform deletion removes its cooling infrastructure without erasing earned work.

The original native reproduction completed at half-power with a buffer around
**39%** full. The monitor previously required both `low_power` and a buffer
below 10%. It now scraps ordinary compute on **any native low-power status**;
the final controller retains its stricter existing 90% contract. Monitoring
remains bounded to 32 ordinary compute machines per tick; this small fixture
does not qualify arbitrarily large registries or every sub-update flicker.

Ordinary compute resets still cancel the committed batch and its operating
Dollars; reserve capital is supplied for retries. Only final AGI training
promises retained inputs. Repeated brownout capital losses need explicit
economy/UX treatment in Phase 4, not an assumption that retries are free.

Cooling reports contain **14 policy, 42 checkpoint, and 15 reload/removal
assertions**. The failure is saved at tick **2,042** and recovery/removal finishes
at **3,300**. The aggregate ledger advances from **10,000 to 20,000**, and the
other force remains at zero. Source and exact-archive reports agree.

## Reproduce And Candidate

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-delivery.sh
scripts/validate-bitermotors-cooling.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-phase3-delivery-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase3-delivery-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-delivery.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase3-delivery-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-cooling.sh
```

Candidate SHA-256:

```text
ad9574ff8e5b86c719348a5bd5847c418c562fa6b2d816b8c1f7c8c61e085e0c
```

**203 Python tests pass.** Source delivery, cooling, AI accounting, finale, and
broad smoke pass. **All nine native validators pass on this same byte-matched
candidate.** Its contents match the current source and package/legal manifest.

| Exact-ZIP validator | Artifacts |
| --- | --- |
| Delivery/research/construction/training/reload | `/tmp/bitermotors-delivery.FyjXiF/` |
| Cooling/power/recovery/removal | `/tmp/bitermotors-cooling.OipqTI/` |
| Finale qualities/effects/extraction/retained retry | `/tmp/bitermotors-finale.LYh06v/` |
| AI accounting | `/tmp/bitermotors-ai.HkT7FL/` |
| Production/sales accounting | `/tmp/bitermotors-accounting.1PeDan/` |
| Customer state | `/tmp/bitermotors-customers.0f40IO/` |
| Recycling/salvage | `/tmp/bitermotors-recycling.PmyXQk/` |
| Charging/service | `/tmp/bitermotors-charging.efLm3F/` |
| Broad smoke | `/tmp/bitermotors-validate.LlPRFi/` |

Runtime artifacts stay outside Git and may expire. Source delivery:
`/tmp/bitermotors-delivery.LGrET7/`; source cooling:
`/tmp/bitermotors-cooling.t0GTE2/`. One preliminary concurrent AI validation
process received external signal 9; its missing completion marker was correctly
rejected. The final sequential archive regression run above passes. The cause
of that external termination is not established. Temporary servers bind loopback, reject
zero-exit engine errors, require ordered advancing reports and real saved files,
and clean up only their own processes.

**No live game, player save, server, desktop client, or installed mod link was
changed.** Next: Phase 4 economy/guidance/functional art freeze, then candidate
soaks/multiplayer/clean-install rehearsal before the final fresh campaign.
