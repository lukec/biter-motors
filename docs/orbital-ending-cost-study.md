# Orbital Ending Cost Study

Date: **2026-10-08**. **Orbital-entry prototypes implemented; finale gameplay pending.**

Native input: `economy-prototypes.json`, Factorio 2.1.20, normal quality, no modules or research productivity.
Overrides are isolated in `scripts/model_orbital_ending.py`; the native capture is not relabeled as proposed data.
This is **not a campaign-time prediction**. All existing terrestrial industry and one datacenter are assumed built.
The minute model assumes hardware, colored science inputs, power and transport are available when needed.
Construction/exploration, damaged grids, ore throughput, waste disposal and cargo delays are unmeasured.

## Native Transport Readiness

The captured core weighs **100,000 g** versus a **1,000,000 g** rocket limit.
A native Dollar weighs **10 g**: only 100000 fit per rocket. The AGI Model weighs **1,000 g**.
The former 1,208,326-g core, 250,025-g Dollar and 2,147,483,647-g Model defaults were corrected on 2026-10-08.
The rocket has 20 inventory slots but its native cargo pod has 10; uplift budgets respect both, using the tighter 10-slot limit.
Mass arithmetic alone is not qualification: actual silo-to-platform launches are required, including partial-load minimums.
Earlier delivery fixtures placed cores directly on platforms. They qualify output return, not hardware uplift.
See [orbital-entry qualification](orbital-entry-validation.md) for native launch evidence and supplied-input limits.
Blocked modeled native cargo: none.

## Candidate Research And Compute

| Upgrade | Science sets | Dollars |
| --- | ---: | ---: |
| autonomous-logistics | 750 | 750 |
| orbital-compute | 1,500 | 1,500 |
| orbital-cluster-training | 1,000 | 2,000 |
| grid-scale-energy | 1,500 | 3,000 |
| hyperscale-training | 2,000 | 6,000 |

No white science, planetary-controller research or final capital package is required in the candidate.
Before orbit: **2,260 Dollars**, 56.5 active minutes of one 8 MW datacenter.
Research and Tokens can stream concurrently; two or more datacenters are optional, not a gate.

| Orbital tier | Tokens / 20s batch | Target online cores | Compute-only band |
| --- | ---: | ---: | ---: |
| 1 | 10,000 | 1 | 0.56h |
| 2 | 50,000 | 4 | 0.25h |
| 3 | 100,000 | 8 | 0.62h |
| 4 | 200,000 | 12 | 2.08h |

Ideal direct AI/research cash: **21,191 Dollars**, including **5,681** for successful orbital batches.
Comparable old remaining bill, after Terrestrial AI and initial datacenter/Biterfactory construction: **132,326 Dollars**.
Both omit the existing factory and optional fleet, but the old bill includes its final controller/grid/capital. Old uplift remains unqualified.
This excludes optional fleet/depot capital, fleet wear, prior terrestrial progression and existing factory costs.
These proposed hardware recipes contain no Dollars; the expanded bill must agree, rather than assume that upstream ingredients are free.
Compute-only ramp: **3.51h**. The current yields need **5.21h even with twelve cores online from the start**.
The candidate still consumes one billion physical training equivalents; labs' research Tokens are replaced, not counted twice.

## Hardware And Launches

| Metric | First cluster | 12 clusters, one platform |
| --- | ---: | ---: |
| Compute units | 1 | 12 |
| Space solar panels | 5 | 60 |
| Radiators | 1 | 12 |
| Placed foundation tiles, including starter hub area | 200 | 1300 |
| Additional foundation uplift | 100 | 1200 |
| Batched automatic uplifts | 9 | 35 |
| Rocket fuel, LDS, blue circuits for launches, each | 450 | 1750 |
| Assembly-only lower bound, one unmoduled silo | 22.5min | 87.5min |
| Compute / solar generation | 250 / 300 MW | 3 / 3.6 GW |

Automatic uplift counts sum whole rockets for each item and each platform, respect item weights and inventory slots,
and assume custom minimum requests allow partial loads. They do not assume manually mixed cargo.
They are batched budgets: phased deliveries and ongoing cash top-ups can require extra partial launches.
A single-platform 1/4/8/12 build ramp takes **49** separate-item launches versus **35** fully batched launches.
That adds **700** of each launch ingredient; upgrade/research waits can require further currency top-ups.
Silo construction, starter-pack manufacture, belts and inserters are included in the supply bill.
Each starter pack manufactures 60 foundations but creates 100 placed tiles; those are not the same quantity.
The 100-extra-tiles-per-cluster envelope is a layout assumption, not a tested platform blueprint.

| Platforms for 12 clusters | Batched uplifts | Placed tiles |
| --- | ---: | ---: |
| 1 | 35 | 1300 |
| 2 | 38 | 1400 |
| 3 | 45 | 1500 |

## Factory Supply Bill

The following bill uses the **49-launch staged ramp**, not the cheaper fully batched shipment plan.
Recipes are expanded through all intermediate components to a named supply frontier, not raw ore or a free-input assumption.
Use clean/dry battery routes already unlocked by Capital Scaling. Native multi-output recipes run jointly: their co-products are credited once.
No module/intrinsic machine productivity is applied; this is conservative on manufacture, not on missing build time.

| Supply | Hardware + launches | Hardware + launches + remaining research |
| --- | ---: | ---: |
| lithium-brine | 5,500 | 5,500 |
| nickel-ore | 640 | 640 |
| calcite | 220 | 220 |
| coal | 10,828 | 49,078 |
| copper-plate | 107,044 | 431,044 |
| electric-engine-unit | 320 | 2,570 |
| iron-ore | 120 | 120 |
| iron-plate | 5,400 | 187,650 |
| petroleum-gas | 208,560 | 1,024,200 |
| processing-unit | 4,490 | 8,990 |
| rocket-fuel | 2,450 | 2,450 |
| steel-plate | 38,451 | 117,201 |
| stone | 390 | 34,140 |
| stone-brick | 600 | 23,100 |
| sulfuric-acid | 45,160 | 135,160 |
| water | 12,000 | 62,640 |

Science totals assume no existing science stock. Blue circuits, electric engines, fuel, plates and fluids are frontier supplies,
not their raw ore/oil totals. Manufacturing energy and neutralization of acidic tailings must still be provided.
Hardware-route tailings: **5,550** fluid units.

## Cash Flow Sensitivities

All cases start with 2,000 Dollars and the first datacenter already built, at 60 effective science sets/minute.
Only remaining Grid Battery adopters generate finite sales; no old EV profit or already-sold batteries are earned again.
Taxi cases assume the 5,000-sale gate was earned earlier, but finance their fleet/depot incrementally only after Autonomy research completes.
Taxi income is capped by unique living customers, native fleet limits and conservative initial wear. No mature fleet is free.
During research/funding waits, existing orbital cores keep working if funded. The cumulative output is banked, not discarded at upgrades.
The finite-market route deliberately skips Hyperscale: efficiency upgrades are optional, not permissions to win.

| Case | Remaining battery buyers | Financed taxi vehicles | First orbital output | Model completion |
| --- | ---: | ---: | ---: | ---: |
| Finite sales; skip Hyperscale | 1000 | 0 | 64min | 10.26h |
| Modest recurring business | 500 | 120 | 73min | 5.69h |
| Stronger recurring business | 500 | 300 | 72min | 5.67h |
| No remaining income | 0 | 0 | not reached | not finished in 24h |

These are ideal-input economic/compute clocks, not observed active playtime. A 4-6-hour chapter remains a design target.
Compare it against science manufacture, materials, actual blueprints, native uplifts and player build time before freezing recipes.

## Manufacture Sensitivity

| Available incremental blue-circuit output | Hardware bill production floor |
| --- | ---: |
| 20/min | 3.74h |
| 60/min | 1.25h |
| 120/min | 0.62h |

Those rates must be spare after other factory demand. The science bill also consumes blue circuits; no double allocation is permitted.
Other commodities can bottleneck first. A factory that makes only 20 spare blue circuits/minute may need a supply upgrade, not more idle waiting.

## Reproduce

```bash
python3 scripts/model_orbital_ending.py --output docs/orbital-ending-cost-study.md
python3 scripts/model_orbital_ending.py --json
python3 -m unittest tests.test_orbital_ending_model
```

Native source SHA-256: `880f6aad5e508f969fcffc5775e71c321e52b8f9ef5fdaa030d4bd2c1e90c574`.
The model rejects stale native input and records a separate hash of all three model scripts in JSON. Running the model does not change gameplay.
Launch rules: [Factorio Wiki](https://wiki.factorio.com/Rocket_silo).
Platform construction/transport: [Factorio Wiki](https://wiki.factorio.com/Space_platform).
