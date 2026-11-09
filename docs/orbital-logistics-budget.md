# Orbital Logistics Budget

unqualified for campaign pacing; not actual player time

Native observations: unqualified: native measurements missing

Measured = finite native fixture windows, not a steady plateau. Midpoint and full/drain extrapolations below are sensitivities, not bounds or actual campaign time.

Campaign rockets/materials are modeled with conservative separate-item loads, not native mixed-load counts.

| Scenario | Projected Rockets | Joint blue circuits | Cash before wear | Finite funding gap |
| --- | ---: | ---: | ---: | ---: |
| Modest recurring; ten settlements | 62 | 11678 | 23791 | 11791 |
| Finite non-taxi; skip Hyperscale | 62 | 8308 | 19691 | 0 |

## Modest recurring; ten settlements

Finite sales revenue ceiling (Dollars): 10,000.00
Steady service funding-only lower bound (hours): 3.31
Frontier known lower bound (minutes): 536.94; unrated items: 0
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 33.33 | unqualified | unqualified |
| orbital-ai-dataset-cluster | 4 | 15.00 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 8 | 37.50 | unqualified | unqualified |
| orbital-ai-dataset-hyperscale | 12 | 125.03 | unqualified | unqualified |

Compute-only extrapolations: startup-midpoint unqualified hours; finite-drain unqualified hours. Not player time.

## Finite non-taxi; skip Hyperscale

Finite sales revenue ceiling (Dollars): 20,000.00
Steady service funding-only lower bound (hours): unqualified
Frontier known lower bound (minutes): 434.75; unrated items: 0
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 33.33 | unqualified | unqualified |
| orbital-ai-dataset-cluster | 4 | 15.00 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 8 | 37.50 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 12 | 250.03 | unqualified | unqualified |

Compute-only extrapolations: startup-midpoint unqualified hours; finite-drain unqualified hours. Not player time.

## Explicit Manufacturing Assumption

Synthetic simultaneously sustainable units/minute; zero opening material stock. Not native campaign production. Each joint frontier item is shown; blue circuits are one shared allocation, and advanced circuits are already expanded, not another frontier bottleneck.

| Frontier | Assumed units/min | Recurring demand | Finite demand |
| --- | ---: | ---: | ---: |
| bitermotors-lithium-brine | 10,000.00 | 218,000.00 | 325,500.00 |
| bitermotors-nickel-ore | 1,000.00 | 640.00 | 640.00 |
| calcite | 1,000.00 | 8,720.00 | 13,020.00 |
| coal | 1,000.00 | 59,724.00 | 44,404.00 |
| copper-plate | 1,000.00 | 536,943.00 | 434,747.00 |
| electric-engine-unit | 100.00 | 3,050.00 | 1,904.00 |
| iron-ore | 1,000.00 | 124.00 | 122.00 |
| iron-plate | 1,000.00 | 292,114.00 | 232,699.00 |
| lubricant | 1,000.00 | 2,400.00 | 2,400.00 |
| petroleum-gas | 20,000.00 | 1,237,120.00 | 915,720.00 |
| processing-unit | 30.00 | 11,678.00 | 8,308.00 |
| rocket-fuel | 60.00 | 3,100.00 | 3,100.00 |
| steel-plate | 1,000.00 | 164,921.00 | 156,171.00 |
| stone | 1,000.00 | 55,390.00 | 56,150.00 |
| stone-brick | 1,000.00 | 23,120.00 | 16,450.00 |
| sulfuric-acid | 10,000.00 | 421,960.00 | 636,520.00 |
| water | 20,000.00 | 63,040.00 | 47,840.00 |

| Scenario / Rate multiplier | Shared material lower bound min (hours) | Top bottlenecks: demand / rate |
| --- | ---: | --- |
| Modest recurring; ten settlements / 0.5x | 1,073.89 (17.90) | copper-plate: 536943 / 500; processing-unit: 11678 / 15; iron-plate: 292114 / 500 |
| Modest recurring; ten settlements / 1x | 536.94 (8.95) | copper-plate: 536943 / 1000; processing-unit: 11678 / 30; iron-plate: 292114 / 1000 |
| Modest recurring; ten settlements / 2x | 268.47 (4.47) | copper-plate: 536943 / 2000; processing-unit: 11678 / 60; iron-plate: 292114 / 2000 |
| Finite non-taxi; skip Hyperscale / 0.5x | 869.49 (14.49) | copper-plate: 434747 / 500; processing-unit: 8308 / 15; iron-plate: 232699 / 500 |
| Finite non-taxi; skip Hyperscale / 1x | 434.75 (7.25) | copper-plate: 434747 / 1000; processing-unit: 8308 / 30; iron-plate: 232699 / 1000 |
| Finite non-taxi; skip Hyperscale / 2x | 217.37 (3.62) | copper-plate: 434747 / 2000; processing-unit: 8308 / 60; iron-plate: 232699 / 2000 |

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

Native catalog source SHA-256: `4c1a3bf4fc8fe9161bf03b147fd804643793c2c9be72dce48455043986d57ceb`.
