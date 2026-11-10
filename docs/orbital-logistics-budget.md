# Orbital Logistics Budget

unqualified for campaign pacing; not actual player time

Native observations: unqualified: native measurements missing

Measured = finite native fixture windows, not a steady plateau. Midpoint and full/drain extrapolations below are sensitivities, not bounds or actual campaign time.

Campaign rockets/materials are modeled with conservative separate-item loads, not native mixed-load counts.

| Scenario | Projected Rockets | Joint blue circuits | Cash before wear | Finite funding gap |
| --- | ---: | ---: | ---: | ---: |
| Modest recurring; ten settlements | unqualified | 3772 | 12741 | 741 |
| Finite non-taxi; skip Hyperscale | unqualified | 1334 | 13441 | 0 |

Layouts missing: material/cash columns are partial, not full chapter totals.

## Modest recurring; ten settlements

Finite sales revenue ceiling (Dollars): 10,000.00
Steady service funding-only lower bound (hours): 0.21
Frontier known lower bound (minutes): unqualified; unrated items: 14
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 11.11 | unqualified | unqualified |
| orbital-ai-dataset-cluster | 4 | 5.00 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 8 | 12.50 | unqualified | unqualified |
| orbital-ai-dataset-hyperscale | 12 | 41.68 | unqualified | unqualified |

Compute-only extrapolations: startup-midpoint unqualified hours; finite-drain unqualified hours. Not player time.

## Finite non-taxi; skip Hyperscale

Finite sales revenue ceiling (Dollars): 20,000.00
Steady service funding-only lower bound (hours): unqualified
Frontier known lower bound (minutes): unqualified; unrated items: 14
Transit: unqualified: Model-return transit missing; any native uplift samples remain separate

| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-dataset | 1 | 11.11 | unqualified | unqualified |
| orbital-ai-dataset-cluster | 4 | 5.00 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 8 | 12.50 | unqualified | unqualified |
| orbital-ai-dataset-grid-scale | 12 | 83.34 | unqualified | unqualified |

Compute-only extrapolations: startup-midpoint unqualified hours; finite-drain unqualified hours. Not player time.

## Explicit Manufacturing Assumption

Synthetic simultaneously sustainable units/minute; zero opening material stock. Not native campaign production. Each joint frontier item is shown; blue circuits are one shared allocation, and advanced circuits are already expanded, not another frontier bottleneck.

| Frontier | Assumed units/min | Recurring demand | Finite demand |
| --- | ---: | ---: | ---: |
| bitermotors-lithium-brine | unqualified | 212,500.00 | 320,000.00 |
| calcite | unqualified | 8,500.00 | 12,800.00 |
| coal | unqualified | 23,733.00 | 16,338.00 |
| copper-plate | unqualified | 215,127.00 | 180,055.00 |
| electric-engine-unit | unqualified | 1,347.00 | 667.00 |
| iron-ore | unqualified | 4.00 | 2.00 |
| iron-plate | unqualified | 169,713.00 | 148,073.00 |
| petroleum-gas | unqualified | 494,160.00 | 341,760.00 |
| processing-unit | unqualified | 3,772.00 | 1,334.00 |
| steel-plate | unqualified | 73,784.00 | 81,346.00 |
| stone | unqualified | 34,255.00 | 42,005.00 |
| stone-brick | unqualified | 8,690.00 | 6,680.00 |
| sulfuric-acid | unqualified | 321,480.00 | 554,680.00 |
| water | unqualified | 19,900.00 | 15,200.00 |

| Scenario / Rate multiplier | Shared material lower bound min (hours) | Top bottlenecks: demand / rate |
| --- | ---: | --- |

## Verdict

The 4-6 active-hour goal is not qualified. The finite-window compute sensitivities exclude construction, manufacturing and cash/cargo scheduling; the synthetic 1x material profile can exceed six simulated hours on its own. Startup-to-midpoint is less pessimistic but not a sustained measurement. Do not add max-parallel material bounds to cash or compute clocks as proven wall time; there is no free-grind or actual-player-time claim.

Remaining bottleneck: shared manufacturing and financing/construction logistics, with finite Dollar distribution/tail uncertainty. These measurements do not establish an intrinsically slow native core cycle or prove cargo is the sole overhead.

Modest business: ten settlements, 2,000 population, 500 finite battery buyers, one office/depot and 120 fleet; taxi sales gate assumed met. Finite alternative: 1,000 battery buyers, no taxi, no Hyperscale. Opening wallet 2,000 Dollars each; all remaining sales stock is charged. Finite revenue is a ceiling, not immediate cash. No funding gap does not prove finishability. The finite route uses Grid-scale/8 from 10M to 100M, then Grid-scale/12 through the gate, with no extra research or compute Dollars. The unchanged raw-equivalent minute business simulation remains at 8 cores in that case and is not used for these compute projections or compact batch/ship scheduling.

Native spare prebuilt rocket parts are reported in JSON and not charged as minimum launch ingredients. Independent fresh-platform mixed flights do not replace the modeled staged single-item campaign count.

No concrete hardware cost until --layouts is supplied.
Scope: Autonomous Logistics through activation; earlier research/factory assumed built.
Silo, landing pad and business capacity are charged as new; no opening stock credit.
Business uses finite buyers, native adoption/referral and shared-customer fleet caps.
Recurring scenario assumes the 5,000 consumer-sales taxi gate already met.
All frontier demand shares one production allocation; blue circuits counted once.
Campaign rockets use modeled single-item packing; native mixed-load fixture flights do not replace them.
No lab capacity, build schedule, wear-material replacement, power infrastructure or movement time modeled.
Independent lower bounds are not additive and are not a finish-time forecast.

Native catalog source SHA-256: `1fee85102ae3ceab0208c8849e2e0b24bff0d5beeebddcfc3bda0db6f72e2efb`.
