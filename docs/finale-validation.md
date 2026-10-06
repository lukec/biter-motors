# Native Finale Validation

Date: **2026-10-06**. This Phase 3 slice implements R04/R05 and qualifies the
final controller's native timing, power, retry, and completion contract.
**Phase 3 remains open:** real hub/cargo-pod delivery and complete orbital
cooling qualification are next. Mod: **Biter Motors 0.1.1**, fresh worlds only.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.

## Implemented Contract

- Earn **1,000,000,000 cumulative AI Token equivalents** through actual compute.
- Supply the unchanged final recipe: 20,000 Training Datasets, 100 Capital
  Allocations, 100 Grid Battery Arrays, and 10,000 Processing Units.
- Run **1,200 native recipe-seconds at 10 GW**: approximately **12 TJ** per run.
  Every controller quality has speed one. Module, beacon, surface, and local
  effects cannot reduce the time or power requirement. Idle drain is zero.
- Low/no power or a sampled buffer below **90%** scraps the active run. The
  retained batch retries after a **one-second hold** and power recovery.
- Native recipe completion latches victory once per force. Inserting a Model
  cannot win. Immediate extraction, a recipe change, machine removal, Continue,
  and save/reload cannot cancel or replay a genuine completion.

Controllers have a separate power queue, checked independently of the ordinary
compute registry: at most **32 controllers per tick**. Up to 32 are checked
each tick; larger registries rotate. This is a bounded architecture, not a
many-controller performance qualification or an unlimited per-tick guarantee.

The native buffer is only about one update of power, not a seconds-long grace
period. Recovery releases the same committed native batch. Exact native zero
progress cancels that batch; a negligible **`1e-12`** progress sentinel preserves
it internally while the public held status reports 0%. Tests supply no second
payload. Other compute machines retain their existing reset behavior.

Native completion callbacks run after the final energy draw. Their depleted
buffer is not evidence of a brownout. The prior monitor failure state and
earned-compute gate guard completion instead.

## Native Fixture Evidence

`scripts/fixtures/finale-control.lua` creates two genuine platforms, each with
32 legendary hyperscale cores and 256 real radiators. Unmodified native recipes
earn **1,004,800,000 equivalents** and **20,096 physical Datasets** by tick 75,420.
The first final run uses 20,000 Datasets withdrawn from those actual outputs.
The rest of the final payload and replicas for the other boundary cases are
explicit fixture supplies.

Ten real final runs test:

| Case | Verified behavior |
| --- | --- |
| Normal | Same-event immediate Model extraction cannot prevent victory. |
| Uncommon | Clearing the completed recipe cannot cancel victory. |
| Rare | Destroying the completed controller cannot cancel victory. |
| Epic | A real fast inserter moves the Model into a steel chest. |
| Legendary | Quality cannot accelerate training or reduce power. |
| Speed beacon | An operative beacon boosts an AM3 witness, not the controller. |
| Efficiency beacon | An operative beacon reduces witness consumption, not the controller. |
| Brownout recovery | Half power then total outage scraps progress; retained inputs finish a full retry. |
| Local effects | Local speed/consumption effects do not change final training. |
| Failed-state reload | Interrupt a run after over 90%; save held state, reload, restore power, finish with retained inputs. |

Successful run measurements are **72,000 observed updates**, or **71,999** for
the retry cases: one-update sampling tolerance around 20 minutes. Consumption
over a measured 60-update window is **10,000,000,320 W**, the native floating
statistics representation of 10 GW. Full-run integrated consumption is within
**two energy-update quanta** of 12 TJ; the runner checks both duration and energy.
No recipe duration, final crafting progress, productivity progress, or cumulative
ledger is injected to complete these runs. The production reset sentinel is the
only deliberate final-progress reset. `game.speed = 100` accelerates wall-clock
testing, not the simulated recipe duration.

The near-completion checkpoint is requested at tick **144,420**, with normal
training at **95.8333%**, zero completed runs, and one failed controller held for
retry. Server saves are asynchronous; reload checks the actual native ticks
between the sample and snapshot, not falsely identical progress. A separate
process completes the runs, saves again, and a third process advances 61 updates
from the completed save. Earned computation and the first victory metadata
survive without replay.

An arbitrary Model is inserted before the gate and retained until genuine compute
opens it: neither insertion nor the gate unlock wins. Broad smoke also rejects
an inserted Model after unlock. The helper rehearses the player's Continue
action so parallel completions can finish without triggering victory again.

Source finale reports: **24 policy, 138 checkpoint, 126 training, and 6 reload
assertions**. **195 Python tests pass**. The runner requires ordered reports,
advancing native ticks, actual saved files, and clean engine logs even when the
process exits zero. Temporary servers bind loopback and cleanup targets only
their own PID. **No live game, save, server, desktop client, or installed mod
link was changed.**

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-finale.sh
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-phase3-finale-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase3-finale-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-finale.sh
```

## Exact Tested Archive

Source and the exact `bitermotors_0.1.1.zip` pass the finale fixture with identical
**24 policy, 138 checkpoint, 126 training, and 6 reload assertions**, identical
earned computation, timing/energy results, and first victory metadata. The
archive matches the source/package manifest byte-for-byte. SHA-256:

```text
2b1c378ddd9a4de99895d3a20ef8b133284f4e3bd0e559fe2bf1adaa72766910
```

All seven native validators pass against this same archive:

| Validator | Native assertions / result | Exact-ZIP artifacts |
| --- | --- | --- |
| Finale | 24 policy, 138 checkpoint, 126 training, 6 reload | `/tmp/bitermotors-finale.p73bT0/` |
| AI accounting | 43 policy, 26 world, 9 reload | `/tmp/bitermotors-ai.qFNYLY/` |
| Production/sales | 39 policy, 26 world, 3 reload | `/tmp/bitermotors-accounting.miK4cS/` |
| Customers | 63 policy, 134 world, 9 reload, 12 configuration | `/tmp/bitermotors-customers.UYoabI/` |
| Recycling | 176 prototype, 52 policy, 480 world, 26 reload | `/tmp/bitermotors-recycling.xw2Kk0/` |
| Charging/service | 137 policy, 1,196 world, 14 reload | `/tmp/bitermotors-charging.1OuSDs/` |
| Broad smoke | Prototype and runtime checks; inserted Model rejected | `/tmp/bitermotors-validate.QyWxfQ/` |

Source finale artifacts: `/tmp/bitermotors-finale.Lr5FWO/`; source broad smoke:
`/tmp/bitermotors-validate.C5dcSu/`. Package:
`/tmp/bitermotors-phase3-finale-release/bitermotors_0.1.1.zip`.
Runtime evidence stays outside Git and may expire. These are isolated fixtures,
not a long soak, native GUI acceptance, multiplayer test, or natural campaign.

## Remaining Gates

- Real computed Dataset delivery through platform hubs, cargo pods, landing pad,
  and controller inputs; current withdrawal/supply is not a transport test.
- Complete orbital cooling allocation, power interruption, radiator/core
  removal, and recovery qualification. This fixture supplies adequate cooling.
- Final controller outage/configuration-change and multiplayer-join qualification
  against the candidate, plus endgame scaling and sustained orbital soaks.
- A natural economy and uninterrupted final run in Luke's complete fresh campaign.
  Supplied operating capital, research, terrain, and ideal power are fixture
  setup, not proof of progression or balance.
