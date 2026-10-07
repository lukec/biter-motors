# AI Payload And Accounting Validation

Date: **2026-10-06**. Phase 3's payload/accounting slice addresses R16 and
implements the compressed production/packaging portion of R03. The subsequent
[finale slice](finale-validation.md) implements fixed full-duration training and
native victory; [delivery/cooling](endgame-delivery-validation.md) closes Phase 3's
isolated native gate. Mod: **Biter Motors 0.1.1**, fresh worlds only.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.

## Approved Contract

Luke approved the following contracts on 2026-10-06:

- One Training Dataset represents **50,000 computed AI Token equivalents**.
- The final run requires **20 uninterrupted simulation minutes at 10 GW**,
  independent of quality/beacons. That finale is implemented and tested in the
  separate [full-duration fixture](finale-validation.md).

The final duration was revised from 60 to 20 minutes later the same day; this
does not change the accounting evidence or retroactively validate the finale.

## Payload And Progress

| Orbital tier | Dollar cost | Recipe time | Token recipe | Direct Dataset recipe |
| --- | --- | --- | --- | --- |
| Grid-scale | 1 | 30 recipe-seconds | 50,000 Tokens | 1 Dataset |
| Hyperscale | 1 | 30 recipe-seconds | 100,000 Tokens | 2 Datasets |

The alternatives preserve compute rates, operating capital, power, and cooling.
A normal core has crafting speed 1.5, so either form takes **20 simulation
seconds** per batch before other effects. Existing Tokens remain available for
science. The final payload is 20,000 Datasets, not a billion belt items.

Datasets stack to 1,000 and weigh 1 kg each: standard 1,000 kg payload arithmetic
allows 1,000 Datasets per payload, or 20 for the final Dataset requirement.
This is checked prototype arithmetic, **not a completed cargo-pod delivery test**.

Ordinary assemblers/Biterfactories package 50,000 existing Tokens into one
Dataset in one recipe-second. Capital Allocation packaging similarly consumes
500 Dollars. Neither operation needs a 10 GW controller, gains productivity,
creates new cumulative compute, or generates a reverse-recycling recipe.
Datasets, Allocations, and the Model remain filterable before recipe unlock.

`runtime/ai_accounting.lua` defines the seven deterministic compute recipes.
Their native recipe-completion events count physical output equivalents,
including native bonus crafts, without sampling the machine's current recipe
or `products_finished`. Terrestrial/orbital ledgers remain independent and
force-local. Spending or losing previously computed output does not erase
cumulative progress. Item-statistics injection/reset, transfers, and packaging
cannot manufacture another earned completion.

Terrestrial research adds 10% per level to base crafts, not to native
productivity bonus crafts. Scripted bonus output retains the completion's
product quality and counts only when physically inserted. Full output keeps a
pending liability; removal cancels undelivered bonuses, not previously earned
work. A force transfer also discards an old-force liability before recording
a new-force completion. That guard has source coverage; native force-transfer
and force-merge qualification remain Phase 5 cases.

Only pending bonus machines are polled, capped at **32 per 30 ticks** in a
persistent queue. Orbital progress no longer polls every core or scans surfaces.
This architectural bound is not a high-scale UPS benchmark.

## Verified Cases

| Check | Result | Boundary |
| --- | --- | --- |
| Python suite | 186 tests pass | Wiring, report guards, package, and existing policies; native behavior is tested separately. |
| Native policy | 43 assertions | Seven equivalent mappings checked against native outputs; no reverse-recycling routes; packaging rejection; quality liabilities; partial delivery; serialization; cancellation; native bonus semantics. |
| Native world | 26 assertions | Two genuine platforms, two computing forces, actual recipe durations/output, real inserter extraction, and first earned orbital milestone. |
| Cumulative compute | 1,155,126 equivalents | 1,155,120 native equivalents plus six physically delivered research bonus Tokens; two additional bonus Tokens are still blocked at the checkpoint. |
| Second force | 100,000 equivalents | Two directly computed Datasets, separate ledger; subsequent platform deletion retains earned computation. |
| Recipe switch/removal | Pass | Immediately change a Dataset recipe to Token output after completion; destroy an orbital core without a lifecycle notification; remove a terrestrial machine before its pending bonus delivers. No sampled-recipe race. |
| Blocked output | Pass | A full-output core earns no completion until cleared; its actual subsequent craft counts once. Filled fixture inventories do not count as compute. |
| Quality/native bonus | Pass | Rare terrestrial craft produces 22 rare Tokens, no normal ones. One base craft plus an explicit native bonus craft yields 42 Tokens, not compounded research-on-bonus output. |
| Packaging | Pass | An earned 50,000-Token batch becomes one physical Dataset in AM2; Biterfactory packages 500 Dollars into one Allocation despite its built-in productivity. Neither earns compute progress. |
| Inserter/milestone | Pass | Native inserter extracts 18 directly computed Datasets; genuine cumulative orbital output enables Cluster Training, without a seeded-progress helper. |
| Native persistence | 9 assertions | Checkpoint contains a blocked two-Token bonus and a genuinely in-progress second craft. Separate process advances 121 updates; new native craft and bonuses reconcile to 1,155,150 at tick 14,041, from saved tick 13,950. No event replay. |
| Statistics | Pass | One billion injected item-statistics Tokens earn zero progress and cannot unlock AGI; resetting statistics does not erase genuine computation. |

Fixture seed: **1062026**. Cleared terrain, supplied Dollars/infrastructure,
research/recipe access, ideal power, and the injected full-output inventory are
explicit fixture setup, not an earned campaign. One test sets native
`bonus_progress = 1` to exercise the engine's bonus-craft event; it does not
shorten recipes, set final crafting progress, or inject cumulative compute.
`game.speed = 100` accelerates wall-clock testing only. This does not demonstrate
the natural campaign economy or a full billion-equivalent endgame.

The runner checks logs even after zero exit status, requires exact ordered
reports with expected totals and minimum assertions, and requires a genuine
server-written checkpoint followed by advancing separate-process reload.
Temporary servers bind loopback; cleanup affects only their own PID.
**No live save, server, desktop client, or installed mod link was changed.**

The broad smoke's profit snapshot now runs one tick after its regular income
mutation boundary. Native flow statistics can settle after same-tick script
callbacks; comparing them earlier created a seed-dependent one-Dollar mismatch.
The exact income equality is preserved. No profit policy was weakened or changed.

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-ai.sh
scripts/validate-bitermotors-mod.sh
```

For the exact packaged candidate:

```bash
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-phase3-ai-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase3-ai-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-ai.sh
```

The runner rejects stale same-version archives.

## Exact Tested Archive

This section records the earlier payload/accounting slice's archive, not the
subsequent finale candidate. See [finale evidence](finale-validation.md) for
the newer exact source/package validation.

Source and the exact `bitermotors_0.1.1.zip` passed the AI fixture with identical
**43 policy, 26 world, and 9 reload assertions** and the same ledger totals.
That package matched its source/packaging manifest byte-for-byte.
SHA-256:

```text
298006fc4aeb6c16a6dd4f43eaeedaf589439729afe1d8058751aa8905dd5eb9
```

All earlier focused regressions and broad smoke pass on both source and this ZIP:

| Regression | Native assertions |
| --- | --- |
| Production/sales | 39 policy, 26 world, 3 reload |
| Customer lifecycle | 63 policy, 134 world, 9 reload, 12 configuration-change |
| Recycling/salvage | 176 final-prototype; 52 policy, 480 world, 26 reload |
| Charging/service | 137 policy, 1,196 world, 14 reload |
| Broad smoke | All prototype, progression, power/mood/recovery checks pass |

Local evidence is excluded from Git and may expire:

| Validator | Source artifacts | Exact-ZIP artifacts |
| --- | --- | --- |
| AI | `/tmp/bitermotors-ai.Zf5HVM/` | `/tmp/bitermotors-ai.WUkqy3/` |
| Broad smoke | `/tmp/bitermotors-validate.Jll9IF/` | `/tmp/bitermotors-validate.7TWwdN/` |
| Accounting | `/tmp/bitermotors-accounting.8xTh4L/` | `/tmp/bitermotors-accounting.hSCKDF/` |
| Customers | `/tmp/bitermotors-customers.ZBHbxZ/` | `/tmp/bitermotors-customers.Y0avju/` |
| Recycling | `/tmp/bitermotors-recycling.nTqQU6/` | `/tmp/bitermotors-recycling.RI339j/` |
| Charging | `/tmp/bitermotors-charging.sGFo5u/` | `/tmp/bitermotors-charging.LmElUT/` |

Package: `/tmp/bitermotors-phase3-ai-release/bitermotors_0.1.1.zip`.

## Remaining Gates

- Phase 4 economy/guidance/functional art freeze and Phases 5-6 qualification.

Real final cargo delivery and complete cooling/reset/recovery now pass in the
subsequent [native delivery/cooling fixture](endgame-delivery-validation.md).
