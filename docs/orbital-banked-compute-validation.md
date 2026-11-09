# Banked Orbital Compute And Scale Tiers

Historical qualification of the pre-thermal cooling quota. The current mod
replaces automatic cooling pauses with [physical heat networks and burnout](orbital-thermal-hardening.md).
The retained native power-work and terrestrial scrap policies still apply.
The cooling runner now tests those policies without an invisible radiator quota.

Date: **2026-11-08**. Mod: **Biter Motors 0.1.1**.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
This is the completed banked-work/tier sub-slice of Phase 3, not the replacement
Model ending or permission to begin the final acceptance campaign.

## Implemented Contract

Orbital clusters keep native crafting progress and their committed ingredients.
Low power uses [native proportional slowdown](https://wiki.factorio.com/Electric_system#Consumption)
and stops work when the supply is exhausted. Missing cooling uses a script
pause, including before the first craft, with a yellow native status. Restoring
cooling resumes the same batch; no replacement Dollar or scripted progress
restoration is needed. Removing a machine or changing its recipe retains normal
Factorio consequences.

Ordinary terrestrial AI remains different: low power cancels the batch and its
20 operating Dollars. It cannot finish the scrapped batch merely by restoring
power. The old controller still uses its separate retained-input reset contract
until the next slice replaces it.

| Orbital milestone | Research cycles | Dollars per cycle | Total normal Dollars | Tokens per batch | Direct Datasets per batch |
| --- | ---: | ---: | ---: | ---: | ---: |
| Entry | 1,500 | 1 | 1,500 | 10,000 | Not unlocked |
| 1M earned orbital equivalents | 1,000 | 2 | 2,000 | 50,000 | Not unlocked |
| 10M earned orbital equivalents | 1,500 | 2 | 3,000 | 100,000 | 2 |
| 100M earned orbital equivalents | 2,000 | 3 | 6,000 | 200,000 | 4 |

Every compute batch still uses **one Dollar and 30 recipe-seconds**, or 20
seconds in a normal 1.5-speed cluster, with the same 250 MW nominal power and
one-radiator requirement. Each Dataset represents 50,000 equivalents. Token
and Dataset variants earn the same amount once through native completion events;
ordinary packaging does not earn it again. No white science was reintroduced.
Normal-quality values exclude quality, research productivity and other effects.

Entity descriptions, research announcements, Progress and machine inspectors
now explain retained work and the actual costs/yields. The read-only core
contract replaces obsolete reset flags with `power_limited`,
`paused_for_cooling` and `work_policy = "banked"`. The soak probe requires this
policy and will not count power-limited/paused cores as healthy activity.

## Native Pause And Reload

The rewritten `scripts/fixtures/cooling-control.lua` uses two platforms and two
forces. It supplies power/ingredients but never sets crafting progress, injects
earned milestones or replaces an interrupted orbital Dollar.

- Zero/one radiator capacity, oldest-core allocation and force/platform isolation.
- No-cooling hold before the first craft leaves its Dollar uncommitted.
- A genuinely started batch keeps identical positive progress during a cooling
  hold and resumes on restoration. Full output prevents native completion and
  earned computation; clearing the output permits one actual completion.
- A second batch uses **one rare Dollar**, never topped up. At a 125 MW supplied
  load it advances more slowly without cancellation; removing the source holds
  positive progress at **0.2834764957264967**.
- A native server-written checkpoint is loaded in a separate process. The
  exact progress survives, full power resumes work and the original batch
  completes once: **10,000 new rare Tokens and 10,000 new earned equivalents**.
  No replacement Dollar is supplied, and waiting cannot create another batch.
- A ground datacenter separately loses its original 20 Dollars on native low
  power, earns zero, cannot complete after restoration without fresh inputs,
  then produces exactly 20 Tokens/equivalents from a fresh 20-Dollar retry.
- Platform removal cleans cooling demand without erasing earned work.

Source and exact ZIP pass the five ordered milestones. Native checkpoint tick
is **3,840**; recovered rare output is observed at **7,110**; terrestrial retry
and final cleanup finish at **11,730**. Assertion counters finish at **204**;
they include repeated state checks, not 204 independent test cases.

The fixture disables platform solar to isolate its supplied electric-energy
interfaces. The inherited radiator prototype has a negligible 1 kW solar
production, and the engine rejects a zero-production solar prototype. Disabling
solar here makes the complete outage genuine; it is **not orbital-generation
qualification**. Real wings, native sunlight and rocket uplift use the separate
uplift regression.

## Accounting And Legacy Regressions

The AI fixture covers all native Token/Dataset recipes, quality-preserving
bonuses, native productivity events, blocked output, recipe switching, immediate
removal, two forces and separate-process reload. New expected accounting is
**2,280,126** earned equivalents, including **2,280,120** native equivalents,
with **36 physical Datasets** extracted by an inserter. The second force earns
its own **200,000** equivalents. Packaging remains outside earned computation.
That second force's genuine hyperscale Dataset batch also survives a full
power interruption at positive progress, resumes without replacement currency
and completes its original four-Dataset batch once. The fixture isolates its
supplied power by disabling platform solar; it does not qualify generation.

The existing delivery fixture now computes **20,096 Datasets plus 10,000 Tokens**
using the new four-Dataset output and 157 supplied Dollars per core. Its ledger
must reconcile to **1,004,810,000** equivalents before and after native cargo
delivery, lab research, the old controller run and reload. The finale fixture
also reconciles its genuine Dataset stock against earned equivalents.

Both controller fixtures explicitly emit
`validation_scope = "legacy-controller-regression"`. Passing them protects the
currently implemented alpha from regression; it does not prove orbital Model
assembly, return or ground activation. Those mechanics remain unimplemented.

## Source And Archive Checks

All test processes use private temporary user directories and loopback sockets.
No live server/client restart or player-save operation was performed. The local
client mod is symlinked to this source tree, so it sees the edited files on its
next load; a running Factorio process does not hot-reload them.

| Check | Source | Exact candidate ZIP |
| --- | --- | --- |
| Broad smoke/prototypes/recipe and research amounts | Pass | Pass |
| Banked cooling/power, rare reload and terrestrial scrap/retry | Pass | Pass |
| Updated AI accounting and Dataset pause | Pass | Pass |
| Legacy controller and physical delivery regressions | Pass | Pass |
| Genuine nine-rocket hardware/currency uplift | October baseline | Pass on current ZIP |

All **265 Python tests** pass. The current delivery regression uses **85 native
pods**, genuinely delivered Datasets and native research; the controller then
completes its full 72,000-update legacy run. The separate finale regression
passes ten quality/effect/recovery cases and its checkpoints/reloads. None of
these assertions counts an injected Model or output-only inventory poll as victory.

Candidate SHA-256:

```text
6daf71ca3724ccaaf667f0c75ac9ccc630ca61a885b8d13a8ad0677cd1e8f364
```

Current retained artifacts include source smoke `/tmp/bitermotors-validate.MrDwsk`,
ZIP smoke `/tmp/bitermotors-validate.52d8Ny`, source pause/reload
`/tmp/bitermotors-cooling.vlwao5` and ZIP pause/reload
`/tmp/bitermotors-cooling.H9d4Af`. These local paths are evidence locations,
not shipped files or prerequisites for another checkout.

Source/ZIP AI artifacts are `/tmp/bitermotors-ai.Rnx8SZ` and
`/tmp/bitermotors-ai.OWZy4n`; source/ZIP legacy delivery artifacts are
`/tmp/bitermotors-delivery.4nxWgS` and `/tmp/bitermotors-delivery.qCFEeE`;
source/ZIP legacy finale artifacts are `/tmp/bitermotors-finale.CTBiLZ` and
`/tmp/bitermotors-finale.XtFUZt`. Current ZIP uplift is
`/tmp/bitermotors-uplift.rFo7aI` and confirms 450 native rocket parts,
10,000 physical returned Tokens, 99 remaining Dollars and separate reload.

## Model And Remaining Scope

The native catalog was refreshed from the new engine capture and includes the
explicit terrestrial-scrap/orbital-banked policy. The simulator rejects an
unexpected policy instead of silently treating all interruptions as paid retries.
Its 10% failure sensitivity now charges **260 terrestrial retry Dollars and
zero orbital retry Dollars**. Delayed work is not assumed to complete instantly.
Both reproducible reports use the new source hash, tier values and exact
physical-payload accounting.

`economy-balance.md` still includes the **legacy controller** capital/grid bill;
`orbital-ending-cost-study.md` models its proposed replacement. Neither is a
measured campaign duration. Source/ZIP fixtures do not qualify large-world
performance, multiplayer, GUI appearance, a practical twelve-cluster blueprint
or natural campaign pacing.

Next: native orbital Model assembly, real Model return, Nauvis activation and
removal of the obsolete controller/capital/uninterrupted-run branch. The
epilogue, functional satellite art, release soaks and final campaign remain open.

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
scripts/validate-bitermotors-cooling.sh
scripts/validate-bitermotors-ai.sh
scripts/validate-bitermotors-delivery.sh
scripts/validate-bitermotors-finale.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-banked
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-banked/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-cooling.sh
```

The same archive variable works for the other isolated validators, including
`scripts/validate-bitermotors-uplift.sh`. The cooling validator also supports
`--check-report REPORT SEED_SAVE CHECKPOINT_SAVE` without starting the engine;
its tests reject missing/corrupt fields, old reset evidence, fake replacement
Dollars, duplicate completions, missing saves and nonadvancing reloads.
