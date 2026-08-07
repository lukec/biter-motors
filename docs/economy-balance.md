# Biter Motors Economy Simulation

This is a strategic lower-bound model of the approved late-game rebalance and
two sensitivity cases. It models current recipe profits, required Dollars,
cumulative orbital AI bands, final power, and solar storage. It excludes raw ore throughput,
customer-acquisition delay, quality, modules, and factory build time, so real
playtime will be longer.

One in-game Dollar represents `$10,000` USD of profit.

## Sale Economics

| Product | Profit per sale | Nominal sale time | One-office profit rate |
|---|---:|---:|---:|
| Prototype Roadster | 2 | 60 sec | 120 Dollars/hour |
| Premium EV | 1 | 30 sec | 120 Dollars/hour |
| Mass-market EV | 1 | 5 sec | 720 Dollars/hour |
| Megatruck | 2 | 10 sec | 720 Dollars/hour |
| Grid Battery | 20 | 30 sec | 2,400 Dollars/hour |

## Terrestrial Progression

| Milestone | Incremental Dollars | Cumulative | Physical gate | Practical funding lower bound |
|---|---:|---:|---|---|
| Premium EV | 250 | 250 | 50 Roadsters sold | 125 Roadsters fund the research, so capital dominates the 50-sale gate. |
| Advanced Battery Chemistry | 300 | 550 | Premium EV production and the battery branch | 300 Dollars funds the first chemistry upgrade without requiring a Grid Battery economy. |
| Energy Products | 200 | 750 | Advanced Battery Chemistry | 200 Dollars opens the Grid Battery branch before large-scale EV expansion. |
| V2 Charging Network | 150 | 900 | Premium EV program and powered V1 charging | The cheaper V2 path lets the player reach distant colonies without hoarding research capital. |
| Capital Scaling | 600 | 1,500 | 250 Premium EVs sold | 600 Dollars opens the Biterfactory V2 and mass-market production path. |
| Terrestrial AI | 750 | 2,250 | Capital Scaling and Energy Products | 750 Dollars funds terrestrial compute without making the first datacenter a dead end. |
| Autonomous Logistics | 750 | 3,000 | Terrestrial AI and logistics science | 750 Dollars unlocks Bitertaxi service and the V4 charging tier. |
| Orbital Compute | 1,500 | 4,500 | 5,000 cumulative consumer EV sales and rocket prerequisites | 1,500 Dollars funds the orbital transition; the 5,000-sale gate remains unchanged. |
| Cluster Training | 5,000 | 9,500 | 1,000,000 cumulative orbital tokens | Research unlocks 25,000-token orbital batches. |
| Grid-scale Energy | 15,000 | 24,500 | 10,000,000 cumulative orbital tokens | Research unlocks 50,000-token batches and the late power assets. |
| Hyperscale Training | 30,000 | 54,500 | 100,000,000 cumulative orbital tokens | Research unlocks 100,000-token orbital batches. |
| Planetary Grid | 0 | 54,500 | Hyperscale Training, Autonomous Logistics, and nuclear power | Science and AI Tokens only; Planetary Grid no longer consumes Dollars. |
| Grid Controller | 11,050 | 65,550 | Planetary Grid researched | 10,000 Dollars, 100 capital-funded Biterfactory Modules, and the 5-Dollar upgrades for 10 Grid Battery Arrays. |

The physical sales gates remain important, but the early capital curve is now
deliberately forgiving: the first terrestrial research sequence totals 4,500
Dollars through Orbital Compute, excluding optional branches and construction.
Once Energy Products unlocks, 20-Dollar Grid Battery sales can fund later research
much more efficiently than one-Dollar EV sales.

## Customer Network Assumptions

Each living customer can buy one of each consumer vehicle generation over the
campaign: Prototype Roadster, Premium EV, Mass-market EV, Megatruck. A replacement purchase changes the customer's active
vehicle and has about a 5% chance to create a Wrecked EV, so a developed settlement can keep
producing demand without requiring a new biter for every sale. Bitertaxi fleet
service is recurring revenue and is not part of this consumer replacement
count.

- Purchase opportunities per represented customer: 4
- Replacement purchases: one per consumer vehicle generation
- 5,000 consumer-sale Bitertaxi gate: unchanged
- Organic represented-population cap: 3x each settlement's starting representation
- Organic prospect interval: one represented prospect about every 15 minutes while locally served
- Growth suspension: affected settlement only; other settlements continue growing
- V1/V2/V3/V4 charger radii: 64 / 128 / 192 / 256 tiles

The model treats represented populations as aggregate settlement state. It does
not require one Lua unit per simulated customer, and it does not make distant
colonies mandatory once the player has developed a bounded network of local
settlements.


### Practical Mixed-Sales Path

| Milestone | Requirement | Illustrative capital raised | Spend | Cash after |
|---|---:|---:|---:|---:|
| Premium EV | 50 Roadsters sold | 250 | 250 | 0 |
| Advanced Battery Chemistry | Premium EV production | 300 | 300 | 0 |
| Energy Products | Advanced Battery Chemistry | 200 | 200 | 0 |
| V2 Charging Network | Powered V1 charging | 150 | 150 | 0 |
| Capital Scaling | 250 Premium EVs sold | 600 | 600 | 0 |
| Terrestrial AI | Capital Scaling and Energy Products | 750 | 750 | 0 |
| Autonomous Logistics | Terrestrial AI and logistics science | 750 | 750 | 0 |
| Bitertaxi | 5,000 cumulative consumer sales | 0 | 0 | 0 |
| Orbital Compute | Rocket and orbital prerequisites | 1,500 | 1,500 | 0 |
| Orbital milestone research | 1M / 10M / 100M tokens | 50,000 | 50,000 | 0 |
| Planetary Grid | Hyperscale and science | 0 | 0 | 0 |
| Grid Controller | 10 Grid Battery Arrays and modules | 11,050 | 11,050 | 0 |
| Final capital package | 100 allocations | 50,000 | 50,000 | 0 |

This terrestrial path still uses the required consumer sales to open Bitertaxi
and orbital play, then uses Grid Battery sales as the scalable capital source. The
late path adds three explicit orbital research bills of 5,000, 15,000, and
30,000 Dollars. It excludes raw ore throughput, customer acquisition, quality,
modules, and factory build time, so real playtime will be longer.

Recommended construction around the mass-market transition adds about 275
Dollars: 100 for Biterfactory V1, 150 more for V2, and 25 for the solar-panel
production gate. A fully stocked Bitertaxi Depot costs about
4,200 Dollars, serves 1,000
customers, earns 6,000 Dollars/hour at
the target rate, and pays back its full center-and-fleet capex in about
0.7 hours before other operating costs.

Optional finite branches add 1,250 Dollars: 250 for Megatruck Engineering, 250
for Battery Material Recovery, and 750 for Cybertrain Logistics. Infinite
improvement research is intentionally excluded.

## Capital Construction

| Construction sink | Dollar burden | What the model counts |
|---|---:|---|
| Biterfactory V1 | 100 | 10 Biterfactory Modules |
| Biterfactory V2 upgrade | 150 | Structural Casting plus the V2 recipe |
| V3 Rapid Charger upgrade | 0 | Physical electrical infrastructure only |
| V4 Solar Charging Hub upgrade | 0 direct / 80 effective | 4 HD panels and 4 unsold Grid Batteries |
| Full Bitertaxi Depot | 4,200 direct / 4,280 effective | 200 fleets, charger chain, center, and four unsold Grid Batteries |
| Planetary Grid Controller | 11,050 direct / 11,250 effective | 10,000 direct, 100 capital-funded Biterfactory Modules, and 10 Grid Battery Array upgrades |
| AGI final-run storage | 500 direct / 2,500 effective | 100 Grid Battery Arrays, separate from the 1,001-grid-asset target |

## Endgame Scenarios

| Metric | Approved rebalance | Higher-power sensitivity | Higher-power and capital sensitivity |
|---|---:|---:|---:|
| Final grid | 10 GW | 12 GW | 12 GW |
| Orbital AI milestone band | Band 4 of 4 | Band 4 of 4 | Band 4 of 4 |
| AI operating + milestone research Dollars | 61,260 | 61,260 | 61,260 |
| One-core AI time | 93.8 hours | 93.8 hours | 93.8 hours |
| Cores for a 10-hour AI build | 10 | 10 | 10 |
| Orbital compute power for that build | 2.5 GW | 2.5 GW | 2.5 GW |
| Orbital solar panels for that build | 17 | 17 | 17 |
| Orbital radiators for that build | 80 | 80 | 80 |
| Mandatory path + transition construction | 65,825 | 65,825 | 65,825 |
| Final capital Dollars | 50,000 | 50,000 | 60,000 |
| Tandem Solar Arrays | 4,762 | 5,715 | 5,715 |
| Grid Battery Arrays | 1,001 | 1,201 | 1,201 |
| Tandem recipe Dollars | 4,762 | 5,715 | 5,715 |
| Grid Battery Array recipe Dollars | 5,005 | 6,005 | 6,005 |
| Solar productivity research Dollars | 0 | 6,094 | 6,094 |
| Orbital solar recipe Dollars | 51 | 49 | 49 |
| Unsold Grid Battery opportunity cost | 22,220 | 26,220 | 26,220 |
| Direct Dollars required | 137,403 | 145,447 | 155,447 |
| Total economic burden | 159,623 | 171,667 | 181,667 |
| Grid Batteries sold to fund direct Dollars | 6,870 | 7,272 | 7,772 |
| Total Grid Batteries manufactured | 7,981 | 8,583 | 9,083 |
| One-Dollar EV equivalent | 159,623 | 171,667 | 181,667 |

The approved 10 GW grid is approximately
46,862 occupied tiles
before substations, access, and factory logistics: 4,762
Tandem Solar Arrays and 1,001 Grid Battery Arrays. The
Grid Battery Arrays also represent 20,020
Dollars of normal Grid Batteries that were upgraded rather than sold.

The approved design keeps the 1-billion-token objective while changing four
pressure points:

- orbital compute costs 1 Dollar per 30-second batch at every band;
- output rises from 10,000 to 25,000, 50,000, and 100,000 tokens at 1M, 10M,
  100M, and 1B cumulative tokens;
- final packaged capital is 100 allocations at 500 Dollars each, or 50,000 Dollars;
- the final sustained grid is 10 GW, with 3 MW Tandem Arrays and 1 GJ Grid Battery Arrays;
- Bitertaxi service earns 1 Dollar per 2 allocated vehicle-minutes, targeting a
  roughly 3-4 hour full-center capex payback.

At 10 GW the ending asks for about 4,762 Tandem
Arrays and 1,001 Grid Battery Arrays. That is still a
major factory-scale objective, but it is thousands of late assets rather than
millions of HD panels.

## Nominal Funding Time

| Funding system | Approved rebalance | Higher-power sensitivity | Higher-power and capital sensitivity |
|---|---:|---:|---:|
| 10 saturated Grid Battery Sales Offices | 5.7 h | 6.1 h | 6.5 h |
| 25 saturated Grid Battery Sales Offices | 2.3 h | 2.4 h | 2.6 h |
| 100 saturated Grid Battery Sales Offices | 0.6 h | 0.6 h | 0.6 h |
| 10 full Bitertaxi Depots, net of fleet capex | 3.0 h | 3.1 h | 6.6 h |
| 50 full Bitertaxi Depots, net of fleet capex | 1.2 h | 1.2 h | 2.4 h |
| 100 full Bitertaxi Depots, net of fleet capex | 0.9 h | 0.9 h | 1.9 h |

These times assume every office or service center is continuously saturated.
Customer growth, reservations, production, transport, and power shortages all
increase elapsed playtime. The simulator and live mod share the approved
Bitertaxi target rate.

## Recommendation

The terrestrial sequence is in the right order of magnitude: hundreds of early
sales, thousands of mass-market sales, then a 5,000-customer Bitertaxi gate. The
approved late game turns the 1-billion-token objective into a staged capital
and power campaign without requiring millions of placed power entities.

The approved case and sensitivities bound the effective ending at roughly
171,667-181,667
Dollars. The approved case is about 159,623
Dollars, or roughly 6,870 Grid Battery
sales before Bitertaxi income. Ten well-utilized Bitertaxi Depots can
meaningfully offset this capital burden, making
customer-network scale useful without making it mandatory.

## Physical Token Caveat

The one-billion milestone is cumulative production, while the final recipe
physically consumes 20,000 datasets of 50,000 Tokens each. Tokens spent on
research must therefore be replaced before the final run can be loaded. The
additional requirement is small relative to one billion, but the logistics are
deliberately physical.

## Model Sources

- Biter Motors recipes and technologies:
  `mod/bitermotors_0.1.1/data.lua`
- Runtime sales gates and Bitertaxi constants:
  `mod/bitermotors_0.1.1/control.lua`
- Nauvis orbit solar multiplier:
  <https://wiki.factorio.com/Nauvis>
- Base solar average and accumulator ratio:
  <https://wiki.factorio.com/Power_production>
