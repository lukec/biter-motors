# Orbital Logistics Budget

unqualified for campaign pacing; not actual player time

Native observations: unqualified: native measurements missing

Measured = finite native fixture windows, not a steady plateau. Midpoint and full/drain extrapolations below are sensitivities, not bounds or actual campaign time.

Campaign rockets/materials are modeled with conservative separate-item loads, not native mixed-load counts.

| Scenario | Projected Rockets | Joint blue circuits | Cash before wear | Finite funding gap |
| --- | ---: | ---: | ---: | ---: |
| Modest recurring; ten settlements | 58 | 9946 | 15691 | 3691 |
| Finite non-taxi; skip Hyperscale | 58 | 7108 | 15191 | 0 |

## Modest recurring; ten settlements

Finite sales revenue ceiling (Dollars): 10,000.00
Steady service funding-only lower bound (hours): 1.04
Frontier known lower bound (minutes): 422.62; unrated items: 0
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
Frontier known lower bound (minutes): 358.75; unrated items: 0
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
| coal | 1,000.00 | 46,199.00 | 35,404.00 |
| copper-plate | 1,000.00 | 422,619.00 | 358,747.00 |
| electric-engine-unit | 100.00 | 2,284.00 | 1,404.00 |
| iron-ore | 1,000.00 | 124.00 | 122.00 |
| iron-plate | 1,000.00 | 233,249.00 | 195,409.00 |
| lubricant | 1,000.00 | 4,540.00 | 4,540.00 |
| petroleum-gas | 20,000.00 | 949,370.00 | 724,470.00 |
| processing-unit | 30.00 | 9,946.00 | 7,108.00 |
| rocket-fuel | 60.00 | 2,900.00 | 2,900.00 |
| steel-plate | 1,000.00 | 137,709.00 | 138,271.00 |
| stone | 1,000.00 | 43,900.00 | 48,650.00 |
| stone-brick | 1,000.00 | 15,460.00 | 11,450.00 |
| sulfuric-acid | 10,000.00 | 391,320.00 | 616,520.00 |
| water | 20,000.00 | 45,790.00 | 36,590.00 |

| Scenario / Rate multiplier | Shared material lower bound min (hours) | Top bottlenecks: demand / rate |
| --- | ---: | --- |
| Modest recurring; ten settlements / 0.5x | 845.24 (14.09) | copper-plate: 422619 / 500; processing-unit: 9946 / 15; iron-plate: 233249 / 500 |
| Modest recurring; ten settlements / 1x | 422.62 (7.04) | copper-plate: 422619 / 1000; processing-unit: 9946 / 30; iron-plate: 233249 / 1000 |
| Modest recurring; ten settlements / 2x | 211.31 (3.52) | copper-plate: 422619 / 2000; processing-unit: 9946 / 60; iron-plate: 233249 / 2000 |
| Finite non-taxi; skip Hyperscale / 0.5x | 717.49 (11.96) | copper-plate: 358747 / 500; processing-unit: 7108 / 15; iron-plate: 195409 / 500 |
| Finite non-taxi; skip Hyperscale / 1x | 358.75 (5.98) | copper-plate: 358747 / 1000; processing-unit: 7108 / 30; iron-plate: 195409 / 1000 |
| Finite non-taxi; skip Hyperscale / 2x | 179.37 (2.99) | copper-plate: 358747 / 2000; processing-unit: 7108 / 60; iron-plate: 195409 / 2000 |

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

Native catalog source SHA-256: `00a8fe673da903fb88d2a531ea7ac9eda2fe833372cd9abfd437c2f876d13a85`.
