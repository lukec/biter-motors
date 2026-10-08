# Biter Motors Economy Freeze Model

Captured engine: **2.1.20**; mod **0.1.1**.
Final prototypes and runtime policy: `docs/economy-prototypes.json`. Source freshness is
checked by content hash, not string fragments. Budgets use normal quality, no modules,
and zero research productivity. No infinite improvement is required.

**Not a total campaign-time forecast.** Ore/chemistry throughput, building, science manufacture/
research speed, combat, exploration, rocket uplifts, walking, and cargo congestion are not
simulated. Native spawns/new nests are excluded from closed-market cases. Active building/
exploration time is **unmeasured**, not zero. Intrinsic Biterfactory productivity can lower
construction cash/material use; the unbonused budget is conservative, not an optimum.
Recovered-capital credit is zero in these budgets: do not treat recycling as new business profit
or fund purchases twice from the same returned capital.

**Transport scope (2026-10-08):** critical cargo now has explicit portable weights.
This model still excludes hardware uplift and cannot establish
a finishable campaign. See [the orbital ending cost study](orbital-ending-cost-study.md).

## Research And Gates

| Required research | Science cycles | Dollars | AI Tokens |
| --- | ---: | ---: | ---: |
| premium-ev-program | 250 | 250 | 0 |
| advanced-battery-chemistry | 300 | 300 | 0 |
| energy-products | 200 | 200 | 0 |
| ev-charging-network | 150 | 150 | 0 |
| capital-scaling | 600 | 600 | 0 |
| terrestrial-ai | 750 | 750 | 0 |
| autonomous-logistics | 750 | 750 | 750 |
| orbital-compute | 1,500 | 1,500 | 1,500 |
| orbital-cluster-training | 1,000 | 5,000 | 1,000 |
| grid-scale-energy | 1,500 | 15,000 | 1,500 |
| hyperscale-training | 3,000 | 30,000 | 3,000 |
| planetary-energy-grid | 2,500 | 0 | 2,500 |

Optional Foundry, Megatruck, Cybertrain, eSpider, and infinite improvements are excluded.
The 50-Roadster and 250-Premium sales gates still apply. The 2,000 Mass-market and 5,000
consumer-sale gates unlock optional Megatruck and Bitertaxi production; neither gates orbital
research. Each living customer may purchase each generation once, not unlimited repeat EVs.

## Corrected AI Budget

Before orbit, 2,250 research Tokens need **113 terrestrial batches, 2,260 Dollars, and 56.5 active minutes at 8 MW**.
Base terrestrial efficiency is used; optional efficiency research reduces later operation.

| Orbital band | Normal cycle | Batches | Operating Dollars | One-core hours |
| --- | ---: | ---: | ---: | ---: |
| orbital-ai-token | 20s | 100 | 100 | 0.56 |
| orbital-ai-token-cluster | 20s | 360 | 360 | 2.00 |
| orbital-ai-dataset-grid-scale | 20s | 1,800 | 1,800 | 10.00 |
| orbital-ai-dataset-hyperscale | 20s | 9,001 | 9,001 | 50.01 |

The 30-second recipe runs every **20 seconds** in a normal 1.5-speed core.
Total: **11,261 operating Dollars, 62.56 core-hours**. Research costs are counted once separately.
Later labs use 8,000 Tokens. Package 199 Datasets from early stock (one AM3: 2.65 minutes); use direct Dataset recipes after Grid-scale Energy.
The last batch replaces spent research payload; earned computation is not the same as physical inventory.
One AM3 packages capital in 80s. The finale remains **20 uninterrupted minutes at 10 GW** (12 TJ).

## Cash And Power

| Cash sink | Dollars |
| --- | ---: |
| Required research | 54,500 |
| Terrestrial research compute | 2,260 |
| Orbital compute and replacement payload | 11,261 |
| Transition, controller, normal grid, and 8-core hardware | 16,815 |
| Final Capital Allocations | 50,000 |
| **Direct cash requirement** | **134,836** |

Solar-only finale supply: **4,762 Tandem Arrays and 1,001 deployed Grid Battery Arrays**. Controller/final recipes consume 110 more arrays, which cannot double as grid storage.
HD and Tandem panels consume **no Dollars**; the previous report's panel cash charges were stale.
Forgone battery sales: up to 22,220 Dollars, **not another cash bill**, and only realizable with eligible buyers.

Partial material bill, before HD/base-battery recipes, other industry, poles, and transport:

- `tandem_arrays`: 4,762
- `grid_battery_arrays_including_consumed`: 1,111
- `hd_panels_for_tandem`: 4,762
- `lfp_packs_for_array_upgrades`: 26,664
- `processing_units_before_hd_panel_and_grid_battery_base_recipes`: 79,840
- `low_density_structures_for_tandem`: 47,620

Solar/Array productivity makes **more items per craft**, not more watts/joules per placed
entity. It saves materials, not placed counts. Quality and nuclear are optional alternatives.
This report does not prove raw-material production can sustain a specific campaign cadence.

## Finite-Market Scenarios

Assume 200 living customers per developed settlement, all three required EV generations sold
already, finite battery adoption (5% initially, then 5% of remaining eligibility every five
minutes), and unique allocated taxi customers. No unlimited repeat battery sales or duplicate
revenue from overlapping depots. Fleet replacement uses conservative initial wear, not mature safety.

| Metric | Restricted market | Typical expansion | Taxi / energy heavy |
| --- | ---: | ---: | ---: |
| Settlements | 5 | 10 | 20 |
| Living customers | 1,000 | 2,000 | 4,000 |
| Consumer purchase capacity | 3,000 | 6,000 | 12,000 |
| Finite EV + Grid Battery profit ceiling | 24,000 | 48,000 | 96,000 |
| Taxi gate from those sales | needs expansion | ready | ready |
| Organic-only wait to fill taxi gate; no new nests | 33.4h | 0.0h | 0.0h |
| Allocated taxi fleet | 0 | 400 | 800 |
| Fleet/depot capital | 0 | 8,400 | 16,800 |
| Net recurring Dollars/hour | 0 | 11,867 | 23,733 |
| Full fleet cash payback | not unlocked | 0.71h | 0.71h |
| Post-network funding window | >48h; finite ceiling | 8.03h | 2.85h |
| Ideal EV selling time, before funding window | 5.28h | 5.28h | 5.28h |
| Normal orbital cores | 4 | 8 | 16 |
| Core work / selected cores | 15.64h | 7.82h | 3.91h |
| Failed-batch cash sensitivity | 0 | 0 | 1,512 |

Funding and compute can overlap; adding these numbers is **not** a campaign-time estimate.
Funding starts with EV cash already earned and assumes mature service can be financed. It
counts fleet capex and finite battery adoption, but does not qualify natural bootstrapping.
Core work excludes research waiting and idle cores at tier boundaries. Heavy sensitivity
loses 10% of ordinary compute batches; retry time is not guessed. Extra manufacturing,
charging, depot load, and existing industry require power above the 10 GW final load.

## Remaining Balance Decisions

- A closed five-settlement market cannot fund the ending from one-time purchases alone. Expand, allow natural customer/nest growth, or unlock recurring service. Organic virtual growth is not instant new demand.
- With two full depots, the 50,000-Dollar finale bill alone needs about 4.2 service hours. Evaluate a targeted capital adjustment against the 2-3-hour major-step target, not blanket cheaper research.
- Measure actual panel/battery materials and transport throughput. Native delivery proves physical completion, not comfortable pacing.
- Eight normal cores need about 6.25 active hours in the final compute band; sixteen need about 3.13. Compare practical core expansion and power/logistics throughput before changing Token yields.
- Ordinary AI brownouts lose committed Dollars. Final AGI failure retains inputs: retry time/power, not another full capital package. Recycled capital and other inflows are not business profit.

No balance values are changed by this simulator. Phase 4 remains open for targeted decisions,
functional art, and native UI qualification.

## Reproduce

```bash
scripts/validate-bitermotors-mod.sh  # prints an isolated artifact directory
python3 scripts/bitermotors_economy_catalog.py --dump <artifacts>/script-output/data-raw-dump.json --runtime-contract <artifacts>/script-output/bitermotors-economy-contract.json
python3 scripts/simulate_bitermotors_economy.py --check-source --output docs/economy-balance.md
```

Solar/storage equations: [Official Factorio Wiki](https://wiki.factorio.com/Power_production).
The exporter verifies the validator's capture manifest, raw-dump/runtime hashes, and unchanged
source before recording a catalog. It cannot legitimize a stale dump by hashing today's source.

Standard orbital rocket payload arithmetic does not predict the number of downward cargo pods.
