# Authoritative Accounting Validation

Date: **2026-10-05**. Release plan **Phase 2 accounting slice complete**;
Phase 2 as a whole and the final playthrough gate remain open.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Space Age**.
Mod: **Biter Motors 0.1.1**, fresh-world alpha contract.

This is dated accounting-slice evidence, not the hash of the current source.
The subsequent [customer-state slice](customer-state-validation.md) records its
new archive and reruns of the accounting regression.

## Changes

- Production uses native `input` statistics; consumption uses `output`.
  Item reads sum all qualities, rather than silently counting only normal.
- Observed production is persisted per force, item, and surface. An observed
  counter drop starts a new epoch, preserving old production and adding new
  production since the reset. Deleted-surface histories remain recorded.
- Removed Premium EV inventory/ground/belt scans and stock/consumption-based
  reconstruction. Stockpiling, driving, and recycling cannot invent sales.
- `runtime/customer_sales.lua` owns the pure, persisted sales ledger. It starts
  empty, records successful vehicle assignments, and separates consumer sales
  from legacy fleet transactions. Neither manufacture nor generic consumption
  initializes or promotes this ledger.
- Sales completion is observed before refreshing buyer reservations. Actual
  assigned vehicles, not inferred craft batches, determine sales milestones.
  Generic output coins do not establish a first sale.
- Scripted Dollars, AI bonuses, and wrecks use positive `on_flow`, maintaining
  native production graphs instead of writing the consumption counter.

The statistics direction follows the official
[LuaFlowStatistics contract](https://lua-api.factorio.com/latest/classes/LuaFlowStatistics.html).
No new customer-mutation testing backdoor was added to the mod.

## Verified Evidence

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 152 tests pass | Static contracts plus economy, packaging, and validator tests; not a campaign. |
| Source and exact-ZIP broad smoke | Pass | Existing engine/prototype checks, no compatibility shim. Unsold cars do not enter its sales ledger; three actual legacy fleet assignments do. |
| Source and exact-ZIP accounting fixture | Pass | 39 executable Lua policy assertions, 26 native-world assertions, and 3 separate-process reload assertions. |
| Native manufacturing | 99/100 and 249/250 boundaries pass | Genuine assembler production using a cheap accelerated helper-only recipe; not full recipe economics. Biterfactory availability and advanced-chemistry research gates agree. |
| Native Roadster sales | 49 remains locked; 50 unlocks Premium | Real mobile prospects, powered charger, Sales Office, Roadsters, paperwork, and completed ownership assignments. Only sale time is accelerated in the helper. |
| Canceled native sale | No Premium sale or profit recorded | Start a Premium sale, change its recipe before completion, then check the ledger and money. Not every death/recipe race is qualified. |
| Other sale thresholds | 249/250, 1,999/2,000, 4,999/5,000 policy cases pass | Executable ledger/gate-progress fixtures, not thousands of native-world sales. Includes force isolation, serialized state, partial assignment counts, and exclusion of fleet transactions from consumer gates. |
| Profit | 50 native Roadster sales produce 100 Dollars | Progress agrees. The latest source/archive broad smokes separately reconcile 20 native Grid Battery Dollars + 1 legacy fleet Dollar + 1 genuinely scripted depot Dollar = 22. The validator derives the expected total from actual earnings, not a fixed population-dependent count. |
| Statistics isolation/reset | Production 259, raw 9, consumption 10 | 250 manufactured, then clear the original surface's statistics and generate 2 normal + 3 rare + 4 legendary on another surface. A second force's 500 stay separate. |
| Stored materials | Nickel and Lithium production 7, not consumption 3 | Positive/negative native statistics samples remain distinct without selling/consuming the stored output. Not a full refinery-chain throughput test. |
| Real persistence | Checkpoint at tick 9,210; reload assertion at 9,240 | Headless server writes a new ZIP; a separate engine process loads it and retains production 259, sales 50, and profit 113, including 13 explicit scripted-flow Dollars. |

The accounting fixture fixes map seed **1062026**. Its two accelerated recipes
and game speed are test-only. It is not a duration, economy, large-population,
multiplayer-player, or endgame qualification. Production-history resets can only
be detected when a sampled counter becomes lower; a manual reset hidden by
enough intervening production is not reconstructed from inventory guesses.

All game artifacts use isolated temporary directories. No player world was
edited and no live server or desktop client was restarted. Existing development
symlinks were not rewritten, but naturally load changed source next time.
There is no backfill of corrupted private-alpha sales ledgers from older saves.

## Exact Tested Archive

Archive: `bitermotors_0.1.1.zip`

SHA-256:

```text
b72887186cabd0010c7d7108608a6f754673f62b62204a462edbcce9c1050948
```

Local evidence, excluded from Git and subject to temporary-file expiry:

- Package: `/tmp/bitermotors-phase2-accounting-release/bitermotors_0.1.1.zip`
- Source accounting: `/tmp/bitermotors-accounting.FWRdNr/`
- Source broad smoke: `/tmp/bitermotors-validate.151an0/`
- Exact-ZIP accounting: `/tmp/bitermotors-accounting.Si4UbO/`
- Exact-ZIP broad smoke: `/tmp/bitermotors-validate.Z9JWtc/`

Rebuild after package changes; a version number does not identify tested bytes.

## Reproduce

From the repository root:

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-accounting.sh
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-accounting-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-accounting-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-accounting.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-accounting-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-mod.sh
```

The accounting validator binds a temporary headless server to loopback on a
selected unused UDP port. It stops only its own process after the checkpoint,
then uses a separate bounded benchmark load. It fails on logged engine errors,
missing/duplicate/early report sentinels, missing save, or failed assertions.

## Next Slice

R06/R07 were subsequently fixed and qualified in the
[customer-state slice](customer-state-validation.md). Continue Phase 2 with
rewritten recycling/chemistry salvage, then contested charging/service health.
Physical orbital delivery and the final training contract remain Phase 3;
the final acceptance campaign still waits for Phases 1-6.
