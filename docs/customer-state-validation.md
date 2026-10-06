# Customer State Validation

Date: **2026-10-06**. Release plan **Phase 2 customer-state slice complete**:
R06/R07 addressed; Phase 2 as a whole and the final playthrough gate remain open.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
Mod: **Biter Motors 0.1.1**, fresh-world alpha contract.

## Changes

- `runtime/customer_population.lua` separates physical purchases from virtual
  histories. A physical sale cannot exhaust an untouched virtual prospect.
- Virtual customers share cohort counters keyed by purchase-history mask and
  current vehicle. They remember every purchased generation after replacing
  their vehicle. The five persisted model bits are append-only, not reorderable.
  Valid state needs at most 81 population counters per settlement regardless of
  represented population size; there is no per-virtual-customer object.
- Pending transactions carry cohort tickets. Reservation, completion, release,
  and replay conserve capacity, including concurrent offices selling different
  models. Repeat completion/cancellation cannot consume another ticket's slot.
- Rebuilds create every valid settlement/market-force record before attaching
  physical representatives. Same-force virtual cohorts and pending tickets
  survive even when the physical population is zero. Dead settlements are
  removed; their historical sales remain in the force's lifetime sales ledger.
- Sales Offices hold a new cycle until a buyer can be reserved, and completion
  puts the office on hold before the next cycle. Missing inputs are identified
  separately from exhausted buyers. Paperwork printing uses nominal selected
  sale-recipe capacity, not the office's script-held/input-waiting state, avoiding
  a startup deadlock. Circuit-disabled/deconstructing offices are excluded;
  chargers still need their existing powered, eligible customer market.
- Added a read-only `customer_population_status(force_name)` diagnostic.
  Tests exercise the real pure module and real runtime without a new customer
  state-injection interface. No older private-alpha history backfill is attempted.

## Verified Evidence

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 158 tests pass | Static contracts, existing policy/simulator/package tests, and negative customer-report gates; not a campaign. |
| Source and exact-ZIP customer fixture | Pass | 63 executable Lua policy assertions, 134 native-world assertions, 9 reload assertions, and 12 configuration-change assertions. |
| Mixed native population | Pass | Native overflow creates 128 physical + 1 virtual customer; after physical purchases/deaths, the untouched virtual prospect buys Roadster number 51. |
| Native replacements/cancellation | Pass | A physical owner and a virtual owner each buy Premium; active ownership remains two. Canceling an in-progress virtual sale releases its reservation and records no sale. |
| Zero representatives | Pass | Repeated rebuilds retain one virtual Premium owner, one unowned virtual prospect, and one pending Roadster purchase with no physical customers. |
| Real persistence | Pass | Server saves at tick 3,196; separate-process reload and helper-version-change assertions run at tick 3,201. Both retain owner, prospect, histories, and ticket. |
| Destroyed settlement | Pass | After the configuration change, destroying the home and rebuilding removes its virtual owner/population while keeping 51 lifetime Roadster sales. |
| Every generation/concurrency | Pass | Pure Lua fixtures cover all five modeled generations, mixed histories, serialization, concurrent model reservations, cancellation, and repeat completion/release. Not hundreds of native sales of every generation. |
| Million-customer aggregate | Pass | Six cohort counters conserve one million virtual customers after five purchases. This tests state-size/conservation, not one million entities, UPS, or a soak. |
| Source and exact-ZIP accounting regression | Pass | 39 policy + 26 native + 3 reload assertions; manufacturing 259, genuine customer sales 50, profit 113, preserved after reload. See the earlier [accounting evidence](accounting-validation.md) for fixture scope. |
| Source and exact-ZIP broad smoke | Pass | Existing prototype/runtime scenario, including prospect paperwork retries. It uses injected milestones/inputs and is not endgame qualification. |

The customer helper uses seed **1062027**, a finite cleared test area, raised
build events, native customer overflow/deaths, and genuine Sales Office crafting.
Only the four consumer sale durations are shortened to **0.5 seconds**; native
spawner cooldown is lengthened to suppress uncontrolled random spawns. Initial
research, power, input vehicles, and paperwork are fixture setup, not naturally
earned campaign resources. Inputs, profits, and ownership rules are unchanged.

Pending progress is paused with the native circuit enable/disable control before
the real checkpoint. The helper changes from 0.1.1 to 0.1.2 to trigger the normal
configuration-change lifecycle. Neither test relies on writing read-only entity
`active` or `spawning_cooldown` runtime properties. See the official
[LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html) and
[assembler control behavior](https://lua-api.factorio.com/latest/classes/LuaAssemblingMachineControlBehavior.html)
contracts.

The runner checks all engine logs, ordered completion sentinels, minimum
assertion counts, an actual checkpoint, and advancing reload/configuration ticks.
It binds a temporary loopback server and stops only its own PID. All game
artifacts are temporary; **no live server, desktop client, or player save was
changed or restarted**. Existing development symlinks naturally load the changed
source on their next normal game load; none was rewritten.

This does not qualify contested service, every buyer death/recipe race, long
commute/diplomacy behavior, large-settlement UPS, multiplayer players, or the
orbital/final campaign. Those remain explicit later release gates.

## Exact Tested Archive

Archive: `bitermotors_0.1.1.zip`. SHA-256:

```text
0ae86a802b135b0db09cca1f3e26dfaeebed7318fa4cf1822917be403904b44d
```

Local evidence is excluded from Git and subject to temporary-file expiry:

- Package: `/tmp/bitermotors-phase2-customers-release/bitermotors_0.1.1.zip`
- Source customer fixture: `/tmp/bitermotors-customers.ftlZD0/`
- Source accounting: `/tmp/bitermotors-accounting.rsdygE/`
- Source broad smoke: `/tmp/bitermotors-validate.V3aaTL/`
- Exact-ZIP customer fixture: `/tmp/bitermotors-customers.d9YlPU/`
- Exact-ZIP accounting: `/tmp/bitermotors-accounting.Q0Kwzn/`
- Exact-ZIP broad smoke: `/tmp/bitermotors-validate.xmg34P/`

Rebuild after any packaged source/changelog change; the version number alone
does not identify tested bytes. Roadmap/evidence files are not packaged.

## Reproduce

From the repository root, with a licensed Factorio 2.1.20 installation:

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-customers.sh
scripts/validate-bitermotors-accounting.sh
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-customers-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-customers-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-customers.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-customers-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-accounting.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-customers-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-mod.sh
```

`FACTORIO_BINARY` and `FACTORIO_READ_DATA` override the default macOS Steam
paths. The archive runners reject a ZIP that does not exactly match current
package source. Test-only manifests, logs, JSONL, and saves stay in `/tmp`.

## Next Slice

Continue Phase 2 with **R08/R11**: rewritten vanilla reverse recipes, conservative
EV chemistry salvage, and real Recycler/recovery assertions. Then **R09/R10**:
contested charging fairness and a shared settlement service-health predicate.
Include the buyer-pool virtual-reservation double weighting identified in the
readiness review; the current single-office native fixture does not qualify it.
Phase 3 still owns practical orbital delivery and reliable final training.
