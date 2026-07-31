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
| Megapack | 20 | 30 sec | 2,400 Dollars/hour |

## Terrestrial Progression

| Milestone | Incremental Dollars | Cumulative | Physical gate | Practical funding lower bound |
|---|---:|---:|---|---|
| Premium EV | 250 | 250 | 50 Roadsters sold | 125 Roadsters fund the research, so capital dominates the 50-sale gate. |
| Energy Products | 500 | 750 | 250 Premium EVs produced before battery research appears | 500 Premium EV sales fund Advanced Battery Chemistry and Energy Products. |
| Mass-market EV | 1,300 | 2,050 | 250 Premium EVs sold | 1,300 Premium EVs, or 65 Megapack sales after Energy Products unlocks. |
| Robotaxi | 3,000 | 5,050 | 5,000 cumulative consumer EVs sold | Terrestrial AI research, 1,000 terrestrial tokens, and Autonomous Logistics. |
| Orbital Compute | 4,000 | 9,050 | Rocket and orbital prerequisites | 2,000 terrestrial tokens plus the orbital science path. |
| Cluster Training | 5,000 | 14,050 | 1,000,000 cumulative orbital tokens | Research unlocks 25,000-token orbital batches. |
| Grid-scale Energy | 15,000 | 29,050 | 10,000,000 cumulative orbital tokens | Research unlocks 50,000-token batches and the late power assets. |
| Hyperscale Training | 30,000 | 59,050 | 100,000,000 cumulative orbital tokens | Research unlocks 100,000-token orbital batches. |
| Planetary Grid | 0 | 59,050 | Hyperscale Training, Autonomous Logistics, and nuclear power | Science and AI Tokens only; Planetary Grid no longer consumes Dollars. |
| Grid Controller | 11,050 | 70,100 | Planetary Grid researched | 10,000 Dollars, 100 capital-funded Gigafactory Modules, and the 5-Dollar upgrades for 10 Grid Megapacks. |

The physical sales gates remain important, but capital is already the tighter
gate at Premium EV: the 50 required Roadsters produce only 100 of the 250
Dollars needed for research. Once Energy Products unlocks, 20-Dollar Megapack
sales can fund later research much more efficiently than one-Dollar EV sales.

### Practical Mixed-Sales Path

| Milestone | Requirement | Illustrative capital raised | Spend | Cash after |
|---|---:|---:|---:|---:|
| Premium EV | 50 Roadsters sold | 250 | 250 | 0 |
| Energy Products | 250 Premium EVs produced | 500 | 500 | 0 |
| Mass-market EV | 250 Premium EVs sold | 1,300 | 1,300 | 0 |
| Robotaxi | 5,000 cumulative consumer sales | 3,000 | 3,000 | 0 |
| Orbital Compute | Orbital prerequisites | 4,000 | 4,000 | 0 |
| Orbital milestone research | 1M / 10M / 100M tokens | 50,000 | 50,000 | 0 |
| Planetary Grid | Hyperscale and science | 0 | 0 | 0 |
| Grid Controller | 10 Grid Megapacks and modules | 11,050 | 11,050 | 0 |
| Final capital package | 100 allocations | 50,000 | 50,000 | 0 |

This terrestrial path still uses the required consumer sales to open Robotaxi
and orbital play, then uses Megapack sales as the scalable capital source. The
late path adds three explicit orbital research bills of 5,000, 15,000, and
30,000 Dollars. It excludes raw ore throughput, customer acquisition, quality,
modules, and factory build time, so real playtime will be longer.

Recommended construction around the mass-market transition adds about 275
Dollars: 100 for Gigafactory V1, 150 more for V2, and 25 for the solar-panel
production gate. A fully stocked Robotaxi Service Center costs about
20,479 Dollars, serves 1,000
customers, and currently earns only 2,400
Dollars/hour.

Optional finite branches add 1,250 Dollars: 250 for Megatruck Engineering, 250
for Battery Material Recovery, and 750 for Cybertrain Logistics. Infinite
improvement research is intentionally excluded.

## Capital Construction

| Construction sink | Dollar burden | What the model counts |
|---|---:|---|
| Gigafactory V1 | 100 | 10 Gigafactory Modules |
| Gigafactory V2 upgrade | 150 | Gigacast plus the V2 recipe |
| V3 Supercharger upgrade | 75 | Direct recipe capital |
| V4 Supercharger upgrade | 204 direct / 284 effective | 200 Dollars, 4 HD panels, and 4 unsold Megapacks |
| Full Robotaxi Service Center | 20,479 direct / 20,559 effective | 200 fleets, charger chain, center, and four unsold Megapacks |
| Planetary Grid Controller | 11,050 direct / 11,250 effective | 10,000 direct, 100 capital-funded Gigafactory Modules, and 10 Grid Megapack upgrades |
| AGI final-run storage | 500 direct / 2,500 effective | 100 Grid Megapacks, separate from the 1,001-grid-asset target |

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
| Mandatory path + transition construction | 70,375 | 70,375 | 70,375 |
| Final capital Dollars | 50,000 | 50,000 | 60,000 |
| Tandem Solar Arrays | 4,762 | 5,715 | 5,715 |
| Grid Megapacks | 1,001 | 1,201 | 1,201 |
| Tandem recipe Dollars | 4,762 | 5,715 | 5,715 |
| Grid Megapack recipe Dollars | 5,005 | 6,005 | 6,005 |
| Solar productivity research Dollars | 0 | 6,094 | 6,094 |
| Orbital solar recipe Dollars | 51 | 49 | 49 |
| Unsold Megapack opportunity cost | 22,220 | 26,220 | 26,220 |
| Direct Dollars required | 141,953 | 149,997 | 159,997 |
| Total economic burden | 164,173 | 176,217 | 186,217 |
| Megapacks sold to fund direct Dollars | 7,098 | 7,500 | 8,000 |
| Total Megapacks manufactured | 8,209 | 8,811 | 9,311 |
| One-Dollar EV equivalent | 164,173 | 176,217 | 186,217 |

The approved 10 GW grid is approximately
46,862 occupied tiles
before substations, access, and factory logistics: 4,762
Tandem Solar Arrays and 1,001 Grid Megapacks. The
Grid Megapacks also represent 20,020
Dollars of normal Megapacks that were upgraded rather than sold.

The approved design keeps the 1-billion-token objective while changing four
pressure points:

- orbital compute costs 1 Dollar per 30-second batch at every band;
- output rises from 10,000 to 25,000, 50,000, and 100,000 tokens at 1M, 10M,
  100M, and 1B cumulative tokens;
- final packaged capital is 100 allocations at 500 Dollars each, or 50,000 Dollars;
- the final sustained grid is 10 GW, with 3 MW Tandem Arrays and 1 GJ Grid Megapacks.

At 10 GW the ending asks for about 4,762 Tandem
Arrays and 1,001 Grid Megapacks. That is still a
major factory-scale objective, but it is thousands of late assets rather than
millions of HD panels.

## Nominal Funding Time

| Funding system | Approved rebalance | Higher-power sensitivity | Higher-power and capital sensitivity |
|---|---:|---:|---:|
| 10 saturated Megapack Sales Offices | 5.9 h | 6.2 h | 6.7 h |
| 25 saturated Megapack Sales Offices | 2.4 h | 2.5 h | 2.7 h |
| 100 saturated Megapack Sales Offices | 0.6 h | 0.6 h | 0.7 h |
| 10 full Robotaxi Service Centers, net of fleet capex | 14.4 h | 14.8 h | 30.4 h |
| 50 full Robotaxi Service Centers, net of fleet capex | 9.7 h | 9.8 h | 19.7 h |
| 100 full Robotaxi Service Centers, net of fleet capex | 9.1 h | 9.2 h | 18.4 h |

These times assume every office or service center is continuously saturated.
Customer growth, reservations, production, transport, and power shortages all
increase elapsed playtime.

## Recommendation

The terrestrial sequence is in the right order of magnitude: hundreds of early
sales, thousands of mass-market sales, then a 5,000-customer Robotaxi gate. The
approved late game turns the 1-billion-token objective into a staged capital
and power campaign without requiring millions of placed power entities.

The approved case and sensitivities bound the effective ending at roughly
176,217-186,217
Dollars. The approved case is about 164,173
Dollars, or roughly 7,098 Megapack
sales before Robotaxi income. Ten well-utilized Robotaxi Service Centers can
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
  `mod/bitermotors_0.1.0/data.lua`
- Runtime sales gates and Robotaxi constants:
  `mod/bitermotors_0.1.0/control.lua`
- Nauvis orbit solar multiplier:
  <https://wiki.factorio.com/Nauvis>
- Base solar average and accumulator ratio:
  <https://wiki.factorio.com/Power_production>
