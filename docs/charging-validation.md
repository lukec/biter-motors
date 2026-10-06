# Charging And Settlement Service Validation

Date: **2026-10-06**. Release-plan **Phase 2 complete**: R09/R10
and virtual-buyer pool balancing addressed. The mod remains alpha; this does
not qualify a full campaign or authorize starting the final playthrough.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
Mod: **Biter Motors 0.1.1**, fresh-world contract.

## Changes

- Count competing settlement demand at each charger before using the bulk
  allocation shortcut. Contested service uses the existing deterministic heap
  and stall-sized rounds. One 48-capacity charger now shares **24/24** between
  two homes demanding 48 each, rather than **48/0**.
- Keep bulk allocation for truly uncontested demand. Work scales with candidate
  homes, charger capacity, and available stalls, not represented EV population.
  Fairness has one-stall granularity; this is not an exact per-EV or general
  network maximum-flow optimizer.
- Extract the pure `runtime/settlement_service.lua` policy. Adequate private
  charging or adequate Bitertaxi service makes a home operational. Cached
  refresh, mood, alerts, inspectors, and growth use the same effective deficit.
  Taxi-covered owners no longer create false private-charging warnings.
- Preserve the existing zero-owned prospect admission rule, overselling,
  three-minute service grace, stochastic anger, and short-memory recovery.
  Prices, research, charger footprints, and recipe durations are unchanged.
- Only healthy home loads contribute charger-expansion utilization. Organic
  growth runs once per healthy home, including taxi-only homes, while keeping
  the existing interval, population cap, and global expansion cooldown.
- Count every pending buyer once across all EV models when balancing Sales
  Offices between homes. Canceled tickets release their original reservation;
  pending buyers are not also added through `population.virtual_reserved`.
- Add a compact on-demand `customer_service_status` remote snapshot. It reports
  effective health, private capacity, mood, growth, and pending transactions;
  it does not add a recurring observer or per-customer rendering loop.

## Verified Evidence

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 178 tests pass | Includes negative report gates and source wiring contracts; native behavior is tested separately below. |
| Source/exact-ZIP charging policy | 137 assertions each | Ten allocator cases and eight service-health cases, executed in Factorio Lua. |
| Equal/unequal demand | Pass | Equal 48/48 demand shares 24/24; 48/96 shares 12/36. Reversed candidate/station order, two chargers, zero power, and partial power conserve capacity. |
| Aggregate scaling policy | Pass | 128 homes demanding one million EVs each consume four available stall-sized chunks, not one operation per EV; uncontested demand uses one chunk. Not a 20k-unit engine stress result. |
| Source/exact-ZIP native service | 1,196 world assertions each | Four isolated scenes exercise removal, real brownouts, restoration, pending transactions, and mood. Many assertions repeat temporal invariants; these are not 1,196 independent scenarios. |
| Native private charging | Pass | Two V1 chargers cover two 48-owner homes; native removal leaves 24/24; partial supply leaves 12/12; replacement restores both homes without waiting for the full cache TTL. |
| Taxi-only service | Pass | Powered, stocked depot serves a home with no Sales Office or private charger across six cache cycles and unrelated pole creation/removal; no false deficit timer starts. |
| Local growth | Pass | In a partly powered shared V2 pool, only the healthy home adds one prospect when its timer is due; the deficient home does not. Taxi-only organic growth also works. Deficient loads do not inflate healthy charger-expansion utilization. |
| Native buyer-pool balancing | Pass | Three supplied, circuit-paused Sales Offices reserve real virtual tickets across Roadster/Premium recipes. Same-model tickets count once; other-model tickets share load; cancellation releases one ticket. No sale completion is injected. |
| Outage and recovery | Pass | Private service loses all powered capacity, respects the native 180-second grace, eventually becomes angry through its normal stochastic checks, and clears anger/deficit timers on restored power. |
| Real persistence | 14 assertions each | Server writes a checkpoint at tick 22,920; a separate process checks at tick 22,950. Restored service and two uncanceled transactions survive; canceled ticket stays released. |
| Accounting regression | Source/exact ZIP pass | 39 policy + 26 world + 3 reload assertions; manufactured 259, sold 50, profit 113. Its accelerated helper recipes are not campaign economics. |
| Customer-state regression | Source/exact ZIP pass | 63 policy + 134 world + 9 reload + 12 configuration-change assertions; mixed histories and virtual-only homes remain intact. |
| Recycling regression | Source/exact ZIP pass | 176 final-prototype checks; 52 policy + 480 world + 26 reload assertions, including partial-batch and salvage conservation. |
| Broad smoke | Source/exact ZIP pass | Prototype/smoke checks, including warning/recovery behavior; not an earned orbital finale. |

Fixture seed: **1062029**. Cleared terrain, power supplies, research, items, and
aggregate ownership are setup. The ownership helper updates both bounded
purchase-history cohorts and the matching vehicle aggregate; it does not fake
production/sales statistics. A second guarded helper makes organic timers due
so the native growth decision can be tested without waiting 15 minutes. This
does not qualify natural long-duration growth cadence. Both mutation helpers
reject use unless the isolated `bitermotors_charging` helper mod is active.

Actual charger prototypes, recipes, power sampling, grace, and random mood
checks are unchanged. `game.speed = 100` accelerates wall-clock simulation, not
recipes. Power fixtures respect the engine's per-tick
[electric-interface output limit](https://lua-api.factorio.com/latest/classes/LuaEntity.html#output_flow_limit)
and clear stored energy when cutting supply. The fixture's zero consumer-sale
ledger remains zero after seeded ownership and paused transactions.

The broad smoke previously cut only private-charger power while a separately
powered depot covered the same homes. Its old expectation of stranded owners
was incompatible with the alternative-service contract. The fixture now cuts
both sources and retains its shortage, map-warning, grace, and recovery checks.

The charging runner rejects missing, duplicate, reordered, low-assertion,
incomplete-case, stale-cache, and non-advancing reload reports. All engine logs
are checked even after a zero exit code; success requires a real server-written
save. Temporary servers bind loopback and cleanup stops only their own PID.
**No live server, desktop client, installed link, or player save was changed.**

## Exact Tested Archive

Archive: `bitermotors_0.1.1.zip`. SHA-256:

```text
44e5f5af4c008f2396a03338095291cb2beeb190bd69231d44a399abb425a21f
```

Local evidence is excluded from Git and may expire:

- Package: `/tmp/bitermotors-phase2-charging-release/bitermotors_0.1.1.zip`
- Source charging: `/tmp/bitermotors-charging.EtMtUD/`
- Exact-ZIP charging: `/tmp/bitermotors-charging.Tj62s0/`
- Source accounting: `/tmp/bitermotors-accounting.3UWKNj/`
- Exact-ZIP accounting: `/tmp/bitermotors-accounting.YNlPUW/`
- Source customers: `/tmp/bitermotors-customers.EuLowS/`
- Exact-ZIP customers: `/tmp/bitermotors-customers.rIB43t/`
- Source recycling: `/tmp/bitermotors-recycling.WgW8op/`
- Exact-ZIP recycling: `/tmp/bitermotors-recycling.QqixtB/`
- Source broad smoke: `/tmp/bitermotors-validate.tcFDOe/`
- Exact-ZIP broad smoke: `/tmp/bitermotors-validate.YRba3q/`

The archive matches current packaged source, including the changelog, byte for
byte. Rebuild and retest after packaged changes; version 0.1.1 alone does not
identify tested bytes. Roadmap and validation-report edits are not packaged.

## Reproduce

From the repository root with a licensed Factorio 2.1.20 installation:

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-charging.sh
scripts/validate-bitermotors-accounting.sh
scripts/validate-bitermotors-customers.sh
scripts/validate-bitermotors-recycling.sh
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-charging-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-charging-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-charging.sh
```

Repeat the other focused validators and broad smoke with that same archive
environment variable. `FACTORIO_BINARY` and `FACTORIO_READ_DATA` override the
default macOS Steam paths.

## Remaining Gates

Phase 3 must resolve Dataset transport, earned AI accounting, cooling/power
recovery, fixed final training, and reliable victory. The proposed compression
and final time/power contract require a design decision before implementation.

Later qualification still needs all charger tiers in larger worlds, natural
taxi attrition/growth, physical commutes, representative caps, two forces,
multiplayer, player/robot lifecycle, and native visual UI inspection. These
small scenes are not a long soak, a throughput comparison, or a final campaign.
Keep recovered capital versus operating profit as the explicit R12 interface
and economy follow-on; recycling remains profitable recovery, not a sale.
