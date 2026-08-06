# Biter Motors 0.1.1

Biter Motors is an alpha Factorio 2.1 Space Age campaign for Nauvis and
stationary platforms in Nauvis orbit.

The mod id is `bitermotors`; custom prototypes use the `bitermotors-` prefix.
The retired private-development namespace is not retained as an alias.

## Why Play

- **Drive super fast EVs!** Roadsters, Premium EVs, Mass-market EVs,
  Megatrucks, and Bitertaxis have distinct speed, range, braking, durability,
  charging, and Self-driving behavior. The eSpider adds native remote control,
  Tesla guns, and extreme all-terrain electric mobility.
- **Kill biters... or make them your customers!** Reservations and vehicles go
  into Sales Offices. Dollars and newly motorized biter customers come out.
- **Scale up and rebuild!** Retool small pilot lines into vertically integrated
  Biterfactories, then automate fleet service and Cybertrain freight.
- **New battery chemistries!** Mine strategic materials, choose dirty or clean
  refining, process waste, recycle cells, and stabilize the grid.
- **Build compute for the future!** Turn vehicle profit into terrestrial and
  orbital computation without letting the power fail halfway through a run.

## Campaign Loop

1. Recover the finite solar, storage, robotics, and industrial equipment from
   the crash site.
2. Establish the Industrial Supply Chain and research the Sales Office.
3. Put powered EV Charging Stations near biter settlements.
4. Move physical EV Reservations and vehicles into Sales Offices.
5. Move physical Dollars out and reinvest profit in research and factories.
6. Sell 50 Prototype Roadsters to open the Premium EV program.
7. Build 100 Premium EVs to unlock Biterfactory construction.
8. Establish nickel, lithium, high-nickel, LFP, waste, and recycling loops.
9. Scale High-density Solar Panels, Grid Batteries, advanced chargers, Biterfactories,
   and Mass-market EVs.
10. Add Bitertaxi service, autonomous logistics, Cybertrain freight, and the
    late terrestrial eSpider.
11. Fund Terrestrial Datacenters with continuous power and Dollars.
12. Launch physical orbital AI infrastructure and return AI Tokens to Nauvis.
13. Sustain a 10-gigawatt final training run to produce an AGI Model.

## Customer Contract

- Sales require living mobile prospects.
- Consumer EV sales consume one EV Reservation and assign the vehicle to one
  specific customer.
- Sold vehicles, not manufactured inventory, create charging demand.
- Customer settlements need Sales Office coverage and powered local charging.
- Low service has a grace period, then only affected settlements can become
  hostile. Restored service makes them friendly again.
- Worms remain hostile.
- Customer growth and physical charging commutes are visible but use bounded
  aggregate simulation beyond the visible-customer limit.

## Terrestrial Infrastructure

- V1 charger: 4 stalls, 12 EVs per stall, 50 kW per active stall.
- V2 charger: 8 stalls, 20 EVs per stall, 150 kW per active stall.
- V3 Rapid Charger: 12 stalls, 32 EVs per stall, 250 kW per active stall.
- V4 Solar Charging Hub: 20 stalls, 50 EVs per stall, 500 kW per active stall.
- Biterfactory V1: 9x9, 20 MW, 4x crafting speed, 50% built-in productivity.
- Biterfactory V2: fast-replaceable 9x9 upgrade, 30 MW, 8x speed, 150%
  built-in productivity.
- High-density Solar Panel: upgradeable 3x3 panel producing 300 kW.
- Grid Battery: 100 MJ storage with 5 MW charge and discharge.
- Terrestrial Datacenter: 8 MW plus 20 Dollars per uninterrupted 30-second
  batch, producing 20 physical AI Tokens.

## Vehicles

- Prototype Roadster: very fast, short-ranged, and fragile.
- Premium EV: refined performance and range.
- Mass-market EV: balanced, durable, and scalable.
- Megatruck: fast, long-ranged, heavy, and highly collision-resistant.
- Bitertaxi: efficient long-duty fleet vehicle.
- Cybertrain: extreme-speed battery-electric locomotive with acceleration draw,
  regenerative braking, reserve crawl, and 50 MW station charging.
- eSpider: roughly 160 km/h in its factory configuration, with four Tesla guns,
  four Battery MK3 units, four exoskeletons, 8 MW traction, charger support, and
  a depleted-battery limp-home reserve.

Premium, Mass-market, Megatruck, and Bitertaxi vehicles support Route and
Summon after Autonomous Logistics. The deliberately raw Roadster does not.
eSpider uses Factorio's standard Spidertron remote and logistics controls.

## Physical Orbital Endgame

Vanilla rockets, cargo pods, and platforms remain the logistics layer.

Orbital AI Infrastructure unlocks:

- A 6x6 Orbital Datacenter Core drawing 250 MW.
- Orbital Radiator Panels, with eight required per core.
- 50 MW High-density Space Solar Panels.

A cooled core consumes 1 Dollar and initially produces 10,000 physical AI
Tokens every 30 seconds. Cumulative orbital output unlocks capital-and-science
projects at 1M, 10M, and 100M Tokens, raising batches to 25,000, 50,000, and
100,000 Tokens. Low power or insufficient cooling resets the active batch.
Tokens must return to Nauvis by cargo pod.

The 10M milestone also unlocks direct upgrades from 300 kW HD panels to 3 MW
Tandem Solar Arrays, and from 100 MJ Grid Batteries to 1 GJ Grid Battery Arrays.

Producing 1,000,000,000 cumulative AI Tokens unlocks the final training recipe.
The Planetary Energy Grid Controller consumes:

- 20,000 AGI Training Datasets, each packaging 50,000 AI Tokens
- 100 Capital Allocations, each packaging 500 Dollars
- 100 Grid Battery Arrays
- 10,000 Processing Units

The controller must sustain 10 GW for 60 uninterrupted minutes. Low power resets
the run. Producing one physical AGI Model wins the campaign.

## Interface

- `Biter Motors Progress` shows only milestones relevant to unlocked content.
- Entity inspectors explain Sales Offices, chargers, settlements, factories,
  datacenters, and the final controller.
- Coverage, alerts, status colors, and map tags identify actionable market and
  power failures.
- `/bitermotors-status` opens or reports the current progression objective.
- `/bitermotors-note <text>` records a timestamped playtest note.
- `/bitermotors-coverage` reports charging and customer coverage.

## Development

The repository README, `ROADMAP.md`, and `COMPATIBILITY.md` are the public
sources of truth. This packaged README describes implemented behavior, not
superseded design experiments.
