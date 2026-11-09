# Orbital Logistics Budget

Historical quota-era measurements. Physical cooling now has updated native
blueprints and separate [hardening evidence](orbital-thermal-hardening.md).
The source/archive hashes below identify this earlier run, not the current mod;
do not reuse these timings as a fresh post-thermal campaign pacing qualification.

## Final Evidence

- Engine: Factorio 2.1.20, build 87512, macOS arm64.
- Native source SHA-256: `29679894ed82a30bf57272d08dd3d934aad5fc4ad0a4d5fb5c1bcf9d03d0a4d1`.
- Exact ZIP SHA-256: `2668796059e25b4fd4e5176d329b39f49cd28070abf7d44d1c0341aeb53cf0d9` (archive hash checked locally).
- Six final ZIP native platform cases reached `reload_passed`; cargo masses and stack slots were recomputed against the matching native catalog. Source and exact-ZIP full-mod smoke passed; source capture `U51vY0`, ZIP smoke `gS3otg`.
- All 390 Python tests passed with Lua 5.2 execution available. Final-ZIP AI accounting, unpacking, cooling/recovery and mechanical Model assembly/return/activation tests also passed, including separate-process reloads. This turn did not repeat graphical terminal or multiplayer qualification.
- Cases: compact-1 `0D6Vh7`, Cluster-4 `jOpaSs`, Grid-scale-8 `i9aAOx`, Hyperscale-12 `WwpXy7`, raw baseline `xI8aLk`, optional Grid-scale-12 `B0GQxr`. Canonical geometry/source identities and small native counters: `orbital-platform-measurements.json`. Costs and assumptions: `orbital-logistics-measured.json`.
- This is supplied-stock finite platform evidence, not a natural campaign, actual player time or separate Model-finale qualification. No full runtime reports, logs or saves are included.

### Reproduce

Run `scripts/validate-bitermotors-mod.sh` first to capture current prototypes,
then regenerate `docs/economy-prototypes.json` using the capture paths it prints.
The platform runner is isolated from installed mods and live saves:

```sh
BITERMOTORS_MOD_ARCHIVE=/absolute/path/to/bitermotors_0.1.1.zip \
BITERMOTORS_PLATFORM_CORES=1 \
BITERMOTORS_PLATFORM_RECIPE=bitermotors-orbital-ai-dataset \
scripts/validate-bitermotors-platform.sh
```

Repeat for Cluster/4, Grid-scale/8, Hyperscale/12 and Grid-scale/12 using the
exact recipe IDs in the tables below. For the one-core raw baseline, use
`bitermotors-orbital-ai-token` and set `BITERMOTORS_PLATFORM_RAW=true`.
Omit `BITERMOTORS_MOD_ARCHIVE` to test linked source instead. Each successful
run prints its retained artifact directory and reconciled counters; pass those
six JSONL paths to the [budget CLI](orbital-logistics-budget.md#commands) with
the four canonical `docs/orbital-layout-*.json` files and
`docs/orbital-frontier-example.json` as the explicit assumed production profile.

unqualified for campaign pacing; not actual player time

Native observations: native observations supplied; coverage reported per recipe/layout

Measured = finite native fixture windows, not a steady plateau. Midpoint and full/drain extrapolations below are sensitivities, not bounds or actual campaign time.

Campaign rockets/materials are modeled with conservative separate-item loads, not native mixed-load counts.

| Scenario | Projected Rockets | Joint blue circuits | Cash before wear | Finite funding gap |
| --- | ---: | ---: | ---: | ---: |
| Modest recurring; ten settlements | 53 | 11228 | 23791 | 11791 |
| Finite non-taxi; skip Hyperscale | 53 | 7858 | 19691 | 0 |

Independent fixture flights (not a measured campaign ramp):

| Cores / Recipe | Native flights | Same-manifest single-item projection |
| --- | ---: | ---: |
| 1 / orbital-ai-dataset | 5 | 11 |
| 4 / orbital-ai-dataset-cluster | 11 | 16 |
| 8 / orbital-ai-dataset-grid-scale | 20 | 23 |
| 12 / orbital-ai-dataset-hyperscale | 28 | 32 |
| 1 / orbital-ai-token | 5 | 11 |
| 12 / orbital-ai-dataset-grid-scale | 28 | 32 |

## Native Finite Windows

| Cores / Recipe | Produced / Pad | Full window min | Midpoint min | Batches/core range | Last completion min | Drain after last sec |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 / orbital-ai-dataset | 12 / 12 | 20.50 | 10.10 | 12-12 | 20.09 | 24.83 |
| 4 / orbital-ai-dataset-cluster | 240 / 240 | 26.42 | 10.23 | 48-77 | 25.89 | 31.42 |
| 8 / orbital-ai-dataset-grid-scale | 960 / 960 | 30.43 | 10.40 | 47-87 | 29.45 | 59.08 |
| 12 / orbital-ai-dataset-hyperscale | 2880 / 2880 | 32.45 | 10.52 | 46-93 | 31.67 | 46.75 |
| 1 / orbital-ai-token | 50000 / 7812 | 10.00 | 5.00 | 5-5 | 1.73 | 496.42 |
| 12 / orbital-ai-dataset-grid-scale | 1440 / 1440 | 32.45 | 10.52 | 46-93 | 31.67 | 46.75 |

Uses measured_passed, not reload+60. The JSON preserves first/last ticks and the busiest core's cycle floor. Uneven finite Dollar allocation can account for a substantial tail; this is not a proof of a sole cause or slow steady core cycles. A larger output hand was not established as the primary fix. Raw-Token backlog is only a restricted baseline.

## Modest recurring; ten settlements

Finite sales revenue ceiling (Dollars): 10,000.00
Steady service funding-only lower bound (hours): 3.31
Frontier known lower bound (minutes): 524.58; unrated items: 0
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 33.33 | 33.67 | 34.17 |
| orbital-ai-dataset-cluster | 4 | 15.00 | 15.35 | 19.81 |
| orbital-ai-dataset-grid-scale | 8 | 37.50 | 39.00 | 57.06 |
| orbital-ai-dataset-hyperscale | 12 | 125.03 | 131.49 | 202.86 |

Compute-only extrapolations: startup-midpoint 3.66 hours; finite-drain 5.23 hours. Not player time.

## Finite non-taxi; skip Hyperscale

Finite sales revenue ceiling (Dollars): 20,000.00
Steady service funding-only lower bound (hours): unqualified
Frontier known lower bound (minutes): 422.39; unrated items: 0
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 33.33 | 33.67 | 34.17 |
| orbital-ai-dataset-cluster | 4 | 15.00 | 15.35 | 19.81 |
| orbital-ai-dataset-grid-scale | 8 | 37.50 | 39.00 | 57.06 |
| orbital-ai-dataset-grid-scale | 12 | 250.03 | 262.95 | 405.67 |

Compute-only extrapolations: startup-midpoint 5.85 hours; finite-drain 8.61 hours. Not player time.

## Explicit Manufacturing Assumption

Synthetic simultaneously sustainable units/minute; zero opening material stock. Not native campaign production. Each joint frontier item is shown; blue circuits are one shared allocation, and advanced circuits are already expanded, not another frontier bottleneck.

| Frontier | Assumed units/min | Recurring demand | Finite demand |
| --- | ---: | ---: | ---: |
| bitermotors-lithium-brine | 10,000.00 | 218,000.00 | 325,500.00 |
| bitermotors-nickel-ore | 1,000.00 | 640.00 | 640.00 |
| calcite | 1,000.00 | 8,720.00 | 13,020.00 |
| coal | 1,000.00 | 58,599.00 | 43,279.00 |
| copper-plate | 1,000.00 | 524,583.00 | 422,387.00 |
| electric-engine-unit | 100.00 | 3,050.00 | 1,904.00 |
| iron-ore | 1,000.00 | 124.00 | 122.00 |
| iron-plate | 1,000.00 | 290,299.00 | 230,884.00 |
| lubricant | 1,000.00 | 1,300.00 | 1,300.00 |
| petroleum-gas | 20,000.00 | 1,214,620.00 | 893,220.00 |
| processing-unit | 30.00 | 11,228.00 | 7,858.00 |
| rocket-fuel | 60.00 | 2,650.00 | 2,650.00 |
| steel-plate | 1,000.00 | 158,021.00 | 149,271.00 |
| stone | 1,000.00 | 55,390.00 | 56,150.00 |
| stone-brick | 1,000.00 | 23,120.00 | 16,450.00 |
| sulfuric-acid | 10,000.00 | 421,960.00 | 636,520.00 |
| water | 20,000.00 | 63,040.00 | 47,840.00 |

| Scenario / Rate multiplier | Shared material lower bound min (hours) | Top bottlenecks: demand / rate |
| --- | ---: | --- |
| Modest recurring; ten settlements / 0.5x | 1,049.17 (17.49) | copper-plate: 524583 / 500; processing-unit: 11228 / 15; iron-plate: 290299 / 500 |
| Modest recurring; ten settlements / 1x | 524.58 (8.74) | copper-plate: 524583 / 1000; processing-unit: 11228 / 30; iron-plate: 290299 / 1000 |
| Modest recurring; ten settlements / 2x | 262.29 (4.37) | copper-plate: 524583 / 2000; processing-unit: 11228 / 60; iron-plate: 290299 / 2000 |
| Finite non-taxi; skip Hyperscale / 0.5x | 844.77 (14.08) | copper-plate: 422387 / 500; processing-unit: 7858 / 15; iron-plate: 230884 / 500 |
| Finite non-taxi; skip Hyperscale / 1x | 422.39 (7.04) | copper-plate: 422387 / 1000; processing-unit: 7858 / 30; iron-plate: 230884 / 1000 |
| Finite non-taxi; skip Hyperscale / 2x | 211.19 (3.52) | copper-plate: 422387 / 2000; processing-unit: 7858 / 60; iron-plate: 230884 / 2000 |

## Verdict

The 4-6 active-hour goal is not qualified. The finite-window compute sensitivities exclude construction, manufacturing and cash/cargo scheduling; the synthetic 1x material profile can exceed six simulated hours on its own. Startup-to-midpoint is less pessimistic but not a sustained measurement. Do not add max-parallel material bounds to cash or compute clocks as proven wall time; there is no free-grind or actual-player-time claim.

Remaining bottleneck: shared manufacturing and financing/construction logistics, with finite Dollar distribution/tail uncertainty. These measurements do not establish an intrinsically slow native core cycle or prove cargo is the sole overhead.

Modest business: ten settlements, 2,000 population, 500 finite battery buyers, one office/depot and 120 fleet; taxi sales gate assumed met. Finite alternative: 1,000 battery buyers, no taxi, no Hyperscale. Opening wallet 2,000 Dollars each; all remaining sales stock is charged. Finite revenue is a ceiling, not immediate cash. No funding gap does not prove finishability. The finite route uses Grid-scale/8 from 10M to 100M, then Grid-scale/12 through the gate, with no extra research or compute Dollars. The unchanged raw-equivalent minute business simulation remains at 8 cores in that case and is not used for these compute projections or compact batch/ship scheduling.

Native spare prebuilt rocket parts are reported in JSON and not charged as minimum launch ingredients. Independent fresh-platform mixed flights do not replace the modeled staged single-item campaign count.

Scope: Autonomous Logistics through activation; earlier research/factory assumed built.
Silo, landing pad and business capacity are charged as new; no opening stock credit.
Business uses finite buyers, native adoption/referral and shared-customer fleet caps.
Recurring scenario assumes the 5,000 consumer-sales taxi gate already met.
All frontier demand shares one production allocation; blue circuits counted once.
Campaign rockets use modeled single-item packing; native mixed-load fixture flights do not replace them.
No lab capacity, build schedule, wear-material replacement, power infrastructure or movement time modeled.
Independent lower bounds are not additive and are not a finish-time forecast.

Native catalog source SHA-256: `29679894ed82a30bf57272d08dd3d934aad5fc4ad0a4d5fb5c1bcf9d03d0a4d1`.
