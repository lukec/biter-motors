# Biter Motors Economy Simulation

This is a strategic lower-bound model of the current alpha economy and two
release-candidate rebalances. It models current recipe profits, required Dollars,
AI efficiency, final power, and solar storage. It excludes raw ore throughput,
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
| Orbital Compute | 4,000 | 9,050 | Rocket and orbital prerequisites | 2,000 terrestrial tokens plus 2,000 Dollars of research. |
| Planetary Grid | 2,525 | 11,575 | Orbital Compute and Autonomous Logistics | 2,500 Dollars of research plus about 25 Dollars for 2,500 orbital tokens. |
| Grid Controller | 11,000 | 22,575 | Planetary Grid researched | 10,000 Dollars directly plus 100 Gigafactory Modules worth 1,000 Dollars. |

The physical sales gates remain important, but capital is already the tighter
gate at Premium EV: the 50 required Roadsters produce only 100 of the 250
Dollars needed for research. Once Energy Products unlocks, 20-Dollar Megapack
sales can fund later research much more efficiently than one-Dollar EV sales.

### Practical Mixed-Sales Path

| Milestone funded | Products sold in this step | Profit raised | Spend | Cash after |
|---|---:|---:|---:|---:|
| Premium EV | 125 Roadsters | 250 | 250 | 0 |
| Energy Products | 500 Premium EVs | 500 | 500 | 0 |
| Mass-market + Giga V2 + solar gate | 79 Megapacks | 1,580 | 1,575 | 5 |
| Robotaxi | 4,375 Mass-market EVs | 4,375 | 3,000 | 1,380 |
| Orbital Compute | 131 Megapacks | 2,620 | 4,000 | 0 |
| Planetary Grid + controller | 677 Megapacks | 13,540 | 13,525 | 15 |

This path reaches a built Planetary Grid Controller with **5,000 consumer EVs
sold plus 887 Megapacks sold**. It deliberately uses the required consumer sales
to fund Robotaxi research before leaning on Megapacks again. Building the
controller also retains 100 additional Megapacks rather than selling them. An
EV-only path needs approximately **125 Roadsters, 2,075 Premium EVs, and 20,525
Mass-market EVs**, or 22,725 total consumer-vehicle sales. Neither path includes
the final AI run, final capital package, optional branches, or raw science-pack
costs.

Recommended construction around the mass-market transition adds about 275
Dollars: 100 for Gigafactory V1, 150 more for V2, and 25 for the solar-panel
production gate. A fully stocked Robotaxi Service Center costs about
20,479 Dollars, serves 1,000
customers, and currently earns only 120
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
| Planetary Grid Controller | 11,000 direct / 13,000 effective | 10,000 direct, 100 Gigafactory Modules, and 100 unsold Megapacks |
| AGI recipe Megapacks | 20,000 effective | 1,000 unsold Megapacks, separate from grid storage |

## Endgame Scenarios

| Metric | Current alpha | Balanced release | Demanding release |
|---|---:|---:|---:|
| Final grid | 1 TW | 10 GW | 25 GW |
| Optimal orbital AI efficiency | Level 4 | Level 2 | Level 3 |
| AI operating + efficiency Dollars | 7,254,579 | 84,433 | 164,948 |
| One-core AI time | 595.2 hours | 694.4 hours | 641.0 hours |
| Cores for a 10-hour AI build | 60 | 70 | 65 |
| Orbital compute power for that build | 15 GW | 17.5 GW | 16.25 GW |
| Orbital solar panels for that build | 100 | 117 | 109 |
| Orbital radiators for that build | 480 | 560 | 520 |
| Mandatory path + transition construction | 22,850 | 22,850 | 22,850 |
| Final capital Dollars | 10,000,000 | 100,000 | 250,000 |
| HD solar panels | 4,761,905 | 47,620 | 119,048 |
| Grid Megapacks | 1,000,001 | 10,001 | 25,001 |
| HD-panel recipe Dollars | 3,571,429 | 34,014 | 85,034 |
| Solar productivity research Dollars | 0 | 6,094 | 6,094 |
| HD panels embedded in orbital solar | 300 | 334 | 311 |
| Unsold Megapack opportunity cost | 20,022,020 | 222,020 | 522,020 |
| Direct Dollars required | 20,849,158 | 247,726 | 529,237 |
| Total economic burden | 40,871,178 | 469,746 | 1,051,257 |
| Megapacks sold to fund direct Dollars | 1,042,458 | 12,386 | 26,462 |
| Total Megapacks manufactured | 2,043,559 | 23,487 | 52,563 |
| One-Dollar EV equivalent | 40,871,178 | 469,746 | 1,051,257 |

The current alpha's 1 TW solar-only grid is approximately
46,857,149 occupied tiles
before substations, access, and factory logistics. Its installed Megapacks also
represent 20,000,020 Dollars of products
that cannot be sold. This makes the effective ending closer to
40,871,178 Dollars than the visible 10-million-Dollar
capital package suggests.

Both release scenarios keep the 1-billion-token objective while changing four
pressure points:

- orbital compute consumes 1-2 Dollars rather than 100 per 10,000-token cycle;
- final packaged capital falls from 10,000,000 to 100,000-250,000 Dollars;
- the final sustained grid falls from 1 TW to 10-25 GW;
- Robotaxi service pays 1 Dollar per 5-10 vehicle-minutes rather than per 100.

At 10 GW the ending still asks for about 47,620 HD panels
and 10,001 Megapacks. That is roughly 200 times the
47 MW peak grid observed in the prior late-terrestrial playtest, so it remains
a major factory-scale objective.

## Nominal Funding Time

| Funding system | Current alpha | Balanced release | Demanding release |
|---|---:|---:|---:|
| 10 saturated Megapack Sales Offices | 868.7 h | 10.3 h | 22.1 h |
| 25 saturated Megapack Sales Offices | 347.5 h | 4.1 h | 8.8 h |
| 100 saturated Megapack Sales Offices | 86.9 h | 1.0 h | 2.2 h |
| 10 full Robotaxi Service Centers, net of fleet capex | 17,545.0 h | 18.9 h | 61.2 h |
| 50 full Robotaxi Service Centers, net of fleet capex | 3,645.5 h | 10.6 h | 25.9 h |
| 100 full Robotaxi Service Centers, net of fleet capex | 1,908.1 h | 9.6 h | 21.5 h |

These times assume every office or service center is continuously saturated.
Customer growth, reservations, production, transport, and power shortages all
increase elapsed playtime.

## Recommendation

The terrestrial sequence is in the right order of magnitude: hundreds of early
sales, thousands of mass-market sales, then a 5,000-customer Robotaxi gate. The
release blocker is the endgame multiplier. The current ending turns that
thousand-sale economy into a 20-to-40-million-Dollar economy and requires
millions of placed power entities.

The two release simulations bound the effective ending at roughly
469,746-1,051,257
Dollars. Start with the balanced case because every omitted system makes real
play slower. That target is about 20,000-25,000 Megapack-equivalent products, or
400,000-500,000 one-Dollar EV sales before mixing in Robotaxi income. Ten
well-utilized, rebalanced Robotaxi Service Centers could repay their fleet and
contribute the direct endgame capital in about 20 hours, making
customer-network scale useful without making it mandatory.

## Release Issues Found

The progress interface currently says to package 1 billion AI Tokens into
100,000 datasets. The recipe actually consumes 50,000 tokens per dataset and
20,000 datasets, which correctly equals 1 billion. The interface text is stale
and should say 20,000.

## Model Sources

- Biter Motors recipes and technologies:
  `mod/bitermotors_0.1.0/data.lua`
- Runtime sales gates and Robotaxi constants:
  `mod/bitermotors_0.1.0/control.lua`
- Nauvis orbit solar multiplier:
  <https://wiki.factorio.com/Nauvis>
- Base solar average and accumulator ratio:
  <https://wiki.factorio.com/Power_production>
