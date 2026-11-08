# Physical Model Ending: Contract And Validation

Updated **2026-11-08**. Supported test engine: **Factorio 2.1.20, build 87512,
mac-arm64, Space Age**. Mod: **Biter Motors 0.1.1 alpha**.

This is the current ending. Older controller/finale reports are dated evidence
for a removed design, not its acceptance tests. The skippable terminal and
progressive ending interface are implemented; see the
[new terminal qualification](terminal-epilogue-validation.md) for current source
and archive evidence. Practical platform/pacing freeze and release qualification
remain next. The evidence table below preserves the preceding Model slice's
dated baseline, not the current archive hash.

## Player Route

1. Earn **one billion cumulative AI Token equivalents** through native compute.
   Terrestrial and orbital output count; packaging, moved inventory, injected
   items and raw production statistics do not. Research-consumed output still
   counts as earned work, but cannot also supply the physical final payload.
2. Research **Grid-scale Energy**. Hyperscale is an optional efficiency upgrade,
   not permission to win. No white science or additional final research is needed.
3. In an **Orbital Compute Cluster over Nauvis**, select **Assemble AGI Model**:
   **20,000 physical Training Datasets + one Datacenter Rack -> one AGI Model**.
   Its 90 recipe-seconds take **60 actual seconds** at normal cluster speed 1.5.
   The entire payload must fit and be consumed by a genuine native craft.
4. Extract the Model into that platform's hub and request it at a **Nauvis Cargo
   Landing Pad**. The native cargo pod must actually deliver it.
5. Feed the returned Model into an existing **Terrestrial Datacenter** on Nauvis
   and select **Activate AGI Model**. This is **30 recipe-seconds / 30 normal
   seconds at 8 MW**, returns the Model as output and latches victory once.
   Continued freeplay remains available.

Both final recipes reject productivity, quality rerolls and recycling. The
ordinary machine-quality speed benefit remains; there is no quality-independent
countdown, capital package, special controller, 50,000-Dollar fee or 10 GW run.
The Model remains filterable while locked, stacks to one and weighs 1 kg.

## Interruptions And Authority

Orbital low power slows/stops native crafting. Missing local radiator capacity
pauses the cluster without resetting its progress or canceling committed inputs.
Ground activation likewise banks its Model and progress through low power.
Only the ordinary terrestrial AI Token recipe retains the run-scrapping policy.

Native recipe-completion events earn assembly/activation credit, never output
inventory presence or sampled current recipes. Assembly credit is scoped to
**force + platform + product quality**. An actual outgoing hub pod reserves at
most its matching Model cargo. Native delivery into that force's canonical Nauvis
pad grants matching activation credit. Lost pods forfeit reservations. Wrong
force, wrong quality, a non-Nauvis surface, an injected Model or a replayed cargo
event cannot fabricate a qualified chain.

Native activation consumes a return credit and records persistent victory
metadata with source `native-model-activation`. Immediate output extraction,
recipe changes or machine removal cannot erase earned milestones or victory.
There is no per-tick world/inventory scan: the authority consists of small
force/platform/quality counters and tracked in-transit pods, with event cleanup.

**Provenance boundary:** ordinary same-quality Factorio items have no individual
serial identity. Credit conservation proves the genuine chain happened; it
cannot distinguish identical stacks subsequently exchanged by an administrator
or another mod. No claim of tamper resistance to arbitrary script modification
is made. Supplying a Model alone cannot fabricate any stage.

## Read-Only Signals

`remote.call("bitermotors", "endgame_status", "player")` reports earned compute,
separate terrestrial/orbital tracks, banked core/cooling/power state and `agi`:

- `unlocked`, `cumulative_ai_tokens`, `required_ai_tokens`;
- `models_assembled`, `models_returned`, `models_activated`;
- `assembly_credits`, `return_credits`, `models_in_transit`;
- `assembly_progress`, `activation_progress`, active machine counts;
- `grid_scale_researched` and bounded `assembly`/`activation` machine summaries,
  including native state, quality, input counts, committed payload and progress;
- normal assembly/activation seconds and activation demand;
- `completed` and persistent `victory` metadata.

The existing `agi_training_status` remote method exposes the same new Model
status. No legacy controller aliases or save migrations were added. Progress
reveals earned compute and physical Model stages only when relevant; inspectors
explain Dataset retention in orbit and the two different terrestrial policies.
The smoke-only milestone setter remains unavailable in ordinary games.

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
scripts/validate-bitermotors-ai.sh
scripts/validate-bitermotors-cooling.sh
scripts/validate-bitermotors-delivery.sh
scripts/validate-bitermotors-finale.sh
```

The delivery case uses normal payload quality; finale repeats the complete path
with rare payload and adversarial checks. The ending fixture earns the billion
through **5,000 genuine hyperscale Dataset completions** using 5,000 supplied
physical Dollars. It removes Hyperscale research before assembly, proving it is
not a final permission gate. It never writes crafting progress or seeds earned
compute storage.

Checkpoints restart separate Factorio processes during interrupted assembly,
with the original Model pod in flight, after native return, during interrupted
activation and after victory. Recovery must produce
a **new native event and new physical output**, not merely retain an old item.
No artificial flight delay is introduced. Both Model cases prove the exact
native pod's identity, cargo and reserved credit survive an actual in-flight
checkpoint, then earn a new delivery after reload. This is distinct from the
earlier starter-pack ascension/delivery that could share a tick. Pure ledger
fixtures also exercise replay, loss, serialization and cross-boundary credits.

Fixtures supply construction, foundation, research, physical operating Dollars,
the final Rack and electric-energy-interface power; platform solar is disabled
to isolate outages from the radiator's small native solar scaffold. Conserving
inventory transfers stage earned outputs, while native inserters prove Model
extraction and the hub/pod/pad performs actual cargo return. This is mechanical
ending qualification, **not** a natural campaign, real solar-layout proof,
manufacturing throughput, a long soak or multiplayer join acceptance. Native
rocket uplift is separately qualified by `validate-bitermotors-uplift.sh`.

## This Slice's Evidence

All runs used isolated temporary user/mod directories on the engine above.
No live server/client was restarted and no player save was edited. The existing
development-mod symlink will see these source changes on its next load; running
Factorio processes do not hot-reload them.

| Check | Final Source | Exact ZIP |
| --- | --- | --- |
| Broad prototype/runtime smoke and native catalog capture | Pass | Pass |
| AI accounting, Dataset payload and native reload | Pass | Pass |
| Banked orbital work, cooling/power recovery, terrestrial scrapping | Pass | Pass |
| Native nine-launch first-cluster uplift and Token return | Pass | Pass |
| Normal Model assembly -> pod return -> activation -> victory/freeplay | Pass | Pass |
| Rare Model route with injected/statistics/force/quality/replay negatives | Pass | Pass |

**284 Python tests pass**, plus package/source matching, namespace/artifact
checks and `git diff --check`. Each complete ending case earns a genuine billion,
accepts and commits the entire 20,000-Dataset batch, waits beyond a full craft
with blocked output, banks interrupted assembly and activation, extracts the
Model with a native inserter, removes the assembly machine, returns the actual
pod and consumes exactly one activation credit. Five checkpoint/reload
boundaries survive; the won save advances **2,400 further freeplay ticks**
without replaying victory. A supplied Model can run a native activation recipe
but cannot win without the earned native chain. Runtime surface checks also
reject script-forced orbital activation; fixture `set_recipe` can bypass native
selection restrictions and is not proof of what a normal GUI permits.

The native activation probe measures **8,266,666.875 J over 60 ticks**, about
**8.267 MW** including ordinary idle drain. The recipe's **rated working demand
is 8 MW**, unchanged from terrestrial compute; it is not a new grid challenge.

Final runtime/prototype source SHA-256:
`4ee8ee9c393ca2066fb21e0c9087d78da26ebe8a2508558fe1e360a1ffcaebe0`.

Tested deterministic archive: `bitermotors_0.1.1.zip`, SHA-256:
`7b2dc733948a0ac1b5a2b6f8b00bdb583ed9aa5c136176b5502b454d1dad645c`.
It remains an alpha development package, not a release candidate or publication.

Retained local evidence:

| Case | Source Artifacts | ZIP Artifacts |
| --- | --- | --- |
| Smoke/capture | `/tmp/bitermotors-validate.Nka9x5` | `/tmp/bitermotors-validate.4jjudO` |
| AI | `/tmp/bitermotors-ai.Nx82kg` | `/tmp/bitermotors-ai.U7VpBh` |
| Cooling | `/tmp/bitermotors-cooling.tMWDq2` | `/tmp/bitermotors-cooling.Mqy9Fl` |
| Uplift | `/tmp/bitermotors-uplift.ODziA7` | `/tmp/bitermotors-uplift.DATS87` |
| Normal ending | `/tmp/bitermotors-delivery.JCNABZ` | `/tmp/bitermotors-delivery.0DfPwc` |
| Rare/adversarial ending | `/tmp/bitermotors-finale.UJcsUv` | `/tmp/bitermotors-finale.Gl5O3j` |

The archive is retained locally under `/tmp/bitermotors-model-ending-package`.
Temporary saves/logs are intentionally not committed. Reproduce ZIP validation
by setting `BITERMOTORS_MOD_ARCHIVE` to the current matching archive's absolute
path; the runner rejects stale bytes before starting the engine.

## Remaining Release Gates

- Complete the remaining multi-player terminal acceptance in Phase 5; the
  implemented scene and single-player persistence are qualified separately.
- Prove the practical 1/4/8/12-cluster platform ramp and freeze pacing/art.
- Run long terrestrial/orbital soaks, scale and multiplayer/configuration tests
  against the exact frozen archive, then rehearse clean installation.
- Finish Luke's non-sandbox fresh campaign through Model activation and reload.
