# FactoryX Design Notes

This file tracks the current design for the Factorio mod concept we have been
calling Factory X. The current working mod folder is
`mod/factoryx_0.1.0`, and the in-game name is FactoryX. The internal
mod id is `factoryx`, all custom prototype ids use the `x-` prefix, and this
fresh-save version intentionally carries no compatibility aliases.

The immediate implementation plan for the next clean, non-sandbox balance run
is in [`feature_specs/factoryx_fresh_playtest.md`](feature_specs/factoryx_fresh_playtest.md).
It specifies fresh-map gates, a mutation-free coach profile, timestamped
production snapshots, paired timelapse frames, playtest notes, and post-run
analysis.

## One-Line Pitch

Factory X is a Biter Motors industrial-ambition mod where the player bootstraps
from prototype EV sales into battery minerals, mass-market manufacturing,
charging infrastructure, energy storage, Robotaxis, terrestrial AI compute,
and a circular autonomous economy.

### Biter Motors Terrestrial Refocus

The current product direction is Biter Motors rather than a combined Tesla and
SpaceX simulation. Future implementation should deepen battery minerals,
vehicle manufacturing, charging, energy storage, Robotaxis, recycling,
terrestrial compute, and humanoid automation. The existing SpaceX-style launch,
satellite, and orbital-compute sections below are historical design material
until a dedicated removal slice deletes their prototypes and runtime paths.

### Terrestrial Roadmap Additions

#### Robotaxi Fleet Safety Learning

- Track force-wide cumulative completed Robotaxi passenger rides using aggregate
  Robotaxi Service Center operation, not individual trip or customer objects.
- Robotaxis become continuously safer as cumulative rides increase. Apply
  diminishing returns so every additional order of magnitude of fleet experience
  reduces collision-loss risk, while routine wear leaves a small nonzero vehicle
  retirement floor.
- This improvement is automatic fleet learning, not another item, recipe, or
  manually repeated technology. The Service Center inspector should show
  cumulative rides, current safety improvement, and expected retirement rate.
- Safety learning reduces wrecks and replacement demand. It does not directly
  increase customers per Robotaxi or trip revenue; those remain separate
  business and technology levers.

#### Electric Semi Locomotive

- Add a very fast battery-electric rail freight locomotive styled as a Biter
  Motors Semi. It uses normal rails, train schedules, wagons, and stations so it
  extends Factorio logistics rather than creating a second road-routing system.
- Give it a finite onboard battery. Acceleration drains energy according to
  train mass and speed change; regenerative braking returns a bounded portion
  of that energy to the onboard battery during deceleration.
- Add an electrified freight stop or charging interface that draws substantial
  grid power while the locomotive is stopped. Grid export should happen only
  through a connected station; a moving train has no physical connection to the
  electrical network.
- Make the locomotive materially faster and more responsive than a conventional
  locomotive, balanced by battery capacity, charging time, grid demand, and a
  late terrestrial recipe using Battery Packs, Electric Drivetrains, steel, and
  capital.
- Runtime work must be limited to a lifecycle registry of active electric
  locomotives and a bounded scheduler. Do not scan every train or update every
  locomotive every tick.

#### Terrestrial Victory Redesign

- The Biter Motors ending remains an explicit open design decision. Removing
  SpaceX invalidates orbital requirements in the current AGI victory path.
- The final condition should close the systems the player actually built:
  customer electrification, sustainable generation and storage, circular
  battery recovery, autonomous fleet safety, terrestrial manufacturing, and
  possibly AGI. Do not select thresholds or preserve AGI as the final artifact
  until this terrestrial victory is designed as one coherent physical finale.

## Design Principles

- Keep the economy physical. Products move on belts. Money moves on belts.
  Late-game AI and energy-grid outputs should also be tangible items where
  possible.
- Prefer concrete player-facing nouns over abstract business terms.
- Use Dollars as the main capital token. Launch credit and money are the same
  system for now.
- Avoid bandwidth tokens. They add an extra abstraction without enough gameplay
  payoff yet.
- Avoid "EV Engineering Data" and "Factory Capex" as items. They were too
  abstract. Replace them with visible infrastructure, concrete products, and
  named hardware packages.
- Make the bootstrapping arc mirror a simplified Tesla-like flywheel: expensive
  early products fund scale, scale funds cheaper products, cheaper products
  fund charging, energy storage, autonomy, recycling, and AI.
- Keep the progression terrestrial. Datacenters and hyperscalers should create
  enough power, capital, land-use, and customer conflict to carry the late game.
- Revisit the AGI victory after the SpaceX removal slice. The current orbital
  requirements are superseded and must not constrain the terrestrial design.
- Keep late terrestrial energy goals concrete: named infrastructure, sustained
  grid draw, physical inputs, and visible output rather than civilization-scale
  rankings.

## Playtest Lessons To Carry Forward

The first few playable steps taught us that the mod feels best when each step is
plainly physical and when the UI answers "what next?" without needing external
notes.

Rules for the rest of the design:

- Every new tech should unlock a concrete next action: place this building,
  craft this product, belt it here, or power this machine.
- Dollars should mostly represent proven market demand being reinvested into
  tooling, factories, launch capacity, energy infrastructure, and compute.
- Avoid single-use abstract tokens unless they are clearly physical or visible on
  belts. `EV Reservation` works because it is a buyer demand item feeding sales.
  We should be skeptical of adding more generated coupons.
- The first instance of a new business loop should be slow and dramatic. `Sell
  hopes and dreams` takes 60 seconds so prototype sales happen on the order of
  minutes.
- Sales Offices define customers. Hostile biters become peaceful customers only
  when a Sales Office covers them, and chargers turn those customer settlements
  into measured demand.
- Sales markets are geographic. A Sales Office can assign vehicles only to
  mobile or virtual buyers whose registered home settlement lies inside that
  office's coverage. Never pull a spare buyer from another colony and rewrite
  its home merely to keep a sale moving.
- Opening salvage should invite exploration rather than explain itself. The
  Captain's Chest is visible but unannounced, contains one personal robotics
  kit and one stack of each robot type, and every mineable crash-site fragment
  must yield at least a small physical salvage item.
- Infrastructure should explain itself through power draw, coverage, stalls,
  recipes, and status panels. If the player clicks a machine, the next step
  should be visible in-game.
- The recovered legendary Megapacks can carry the opening grid all the way to
  Energy Products. This is desirable: the crash kit bypasses ordinary
  accumulator construction without making replacement Megapacks reproducible
  before their technology is recovered.
- Runtime milestone unlocks must be idempotent. Configuration changes can reset
  a recipe to its data-stage disabled state while milestone storage and
  production history survive. Recipe repair must always run; only the player
  announcement should be one-time.
- Researched FactoryX technologies are also repaired generically from their
  declared unlock effects. The runtime exposes a progression-integrity report,
  and validation fails if a recipe has no technology/milestone owner or no
  compatible crafting machine.
- Progress metrics use Factorio's lifetime per-surface output counters. The
  Dollars value has a stable GUI identity and progressed-save validation checks
  that the stored statistic, progression snapshot, and rendered caption match.
- Each major arc should follow the same readable pattern:
  1. Prove demand with an expensive niche product.
  2. Convert sales into Dollars.
  3. Spend Dollars plus real factory hardware on production capability.
  4. Use the new capability to make a cheaper or larger-scale product.
  5. Add infrastructure that creates more demand or unlocks the next domain.

## Current Implemented MVP

The MVP already has these major loops:

1. Research Automobilism and Chemical Science, then Sales Office. Sales Office
   requires Automobilism, Electric Engine, and Chemical Science technology, and
   consumes red, green, and blue science. It unlocks the Sales Office, EV
   Charging Station, and the first Sales Office recipe: `Sell hopes and dreams`.
2. Place a powered EV Charging Station near biter customer settlements.
3. The first covered biter customer charging site unlocks Prototype Roadsters.
4. Craft Prototype Roadsters.
5. Active charger stalls print physical EV Reservation paperwork. Belt or bot
   one reservation to the Sales Office with each Prototype Roadster.
6. Run `Sell hopes and dreams`, then belt Dollars out of the Sales Office.
7. Scale charging stations and the completed EV fleet to print more reservations
   for Premium and Mass-market sales.
8. Research EV Production Line, then build the first 100 Premium EVs in
   ordinary advanced assemblers as a pilot run.
9. Producing 100 Premium EVs completes the manufacturing pilot. Finishing
   Energy Products as well unlocks Gigafactory Modules and Gigafactory
   construction, ensuring scalable power arrives before mass production.
10. Combine ten modules with two Substations, then move Premium EV production
    into the Gigafactory. Mass-market EVs remain Gigafactory-only.
11. Build silver Megatrucks after Mass-market EV Production, then sell each
    one with an EV Reservation for 2 Dollars of profit.
12. Research Terrestrial AI and build 8 MW datacenters for early AI Tokens.
12. Feed 20 Dollars into an 8 MW datacenter to produce 20 AI Tokens every 30 seconds.
13. Spend 1,000 AI Tokens and 1,000 Dollars on Autonomous Logistics.
14. Build Robotaxi Fleets in Gigafactory V2 and sell them without reservations.
15. Complete Small Orbital Launch, reusable launch, and satellite infrastructure.
16. Move AI production to space platforms with Orbital Compute Arrays.
17. Drop AI Tokens back to the planet.
18. Build a Planetary Energy Grid Controller and the energy infrastructure
    needed for the final training run.
19. Produce Planetary Grid Segments from AI Tokens, Megapacks, Satellite Buses,
    and Ground Station Networks.
20. Generate one billion cumulative AI Tokens across terrestrial and orbital
    compute. This unlocks the AGI Training Run; Tokens need not remain stored.
21. Deliver 100 million physical AI Tokens, 10 million Dollars, and the required
    Planetary Grid Segments to the controller.
22. Sustain roughly 1 TW for a 60-minute AGI Training Run to trigger victory.
23. Continue after victory with larger compute, energy, and customer systems if
    desired; AGI is the complete FactoryX victory.

Current runtime behavior is intentionally small:

- Every 600 ticks, the mod counts active charging stalls from biter customer
  settlements covered by grid-connected EV Charging Stations.
- A v1 EV Charging Station has 4 stalls. Each covered biter spawner occupies
  one stall, capped at 4 active stalls per station.
- Each active stall draws 50 kW from the electric grid, so a fully used v1
  charger draws 200 kW.
- The first covered biter customer charging site unlocks Prototype Roadsters
  for `Sell hopes and dreams`.
- If the EV charging network technology is researched or the first customer
  charging site has been covered, each active charging stall prints one EV
  Reservation per minute into its charger's output inventory.
- Chargers have a one-slot output inventory. Inserters can always move the
  physical paperwork; logistic bots can also collect it when optional logistic
  coverage is available. Logistic coverage never gates charger operation.
- Prototype, Premium, and Mass-market EV sales consume one reservation per car.
  Megatruck sales also consume one reservation. Robotaxi fleets consume no
  reservations; they require major capital instead.
- All five FactoryX EV products are now drivable. They temporarily reuse the
  vanilla car body with product colors: Roadster red, Premium black,
  Mass-market white, Megatruck silver, and Robotaxi gold.
- Each placed EV receives embedded battery equipment. Powered charger tiers
  reserve spare stalls for nearby player EVs, draw their normal per-stall grid
  power, and refill those batteries. Customer stalls are allocated first and
  only customer stalls generate EV Reservation paperwork.
- The `/factoryx-coverage` command reports total station count,
  grid-connected station count, covered biter settlements, active charging
  stalls, active EV Sales Offices, and EV Reservation rate.

## New Game Start

FactoryX has an optional startup setting, `FactoryX accelerated start`, enabled
by default. It is deliberately a light start rather than a prebuilt base:

- No factory is prebuilt. A red `Captain's Chest` is placed beside the first
  player as a quiet discovery, but the player chooses where to deploy its
  contents.
- The opening skips basic research chores. Steam Power, Automation Science,
  Steel Axe, Electric Mining Drills, Labs, electric furnaces, lamps, basic
  military, Gun Turrets, Radar, and Heavy Armor, Repair Packs, Stone Walls, Landfill, circuit
  networks, fluid handling, and the oil-to-Advanced-Circuit chain all start
  researched. This makes every ordinary component supplied in the wreckage or
  personal kit craftable without replaying the burner-era technology path.
- The crashed ship contains 100 Steel Plates, 100 Electronic Circuits, 100 Iron
  Gears, four Assembling Machine 1s, four Labs, and 50 Lamps.
- The surrounding wreckage contains starter plates, stone, coal, belts,
  inserters, and electric poles. The former steam-power kit is omitted so the
  recovered solar grid is the natural opening path.
- The Captain's Chest contains 54 legendary High-density Solar Panels (40.5 MW
  peak), 24 legendary Megapacks, 40 legendary Substations, 20 legendary
  Roboports, one stack each of legendary Construction and Logistic Robots, one
  stack each of legendary red Passive Provider Chests and yellow Storage Chests,
  and one legendary personal kit: a Modular Armor, Personal Roboport, two
  Battery equipment items, eight Portable Solar Panels, Night-vision equipment,
  10 Electric Furnaces, and 10 Electric Mining Drills.
  Their corresponding technologies start researched, so normal-quality
  replacements are craftable. Normal versions of the recovered
  base-game infrastructure are craftable immediately, while FactoryX energy
  products still require their normal FactoryX progression.
- Every mineable crash-site wreck receives a small physical salvage payout when
  it would otherwise be empty: steel from large hull sections, iron from medium
  sections, and five copper plates directly into the mining output from each
  small fragment.
- The opening message establishes that this is a colony mission whose advance
  landing party never arrived. The crash preserved advanced hardware but
  destroyed much of its technical archive, explaining why recovered equipment
  cannot initially be reproduced. It directs the player toward immediate red
  and green science so Industrial Supply Chain can recover Big Mining Drill,
  electric-furnace, and foundry plans before introducing the broader customer
  economy and long-term energy/computation objective.
- Disabling the setting restores the ordinary Factorio freeplay start.

## Customer Population Scaling

- Customer settlements are the authoritative population unit. Mobile biters
  are visible representatives, not the source of truth for market size.
- FactoryX retains at most 128 visible mobile customers per settlement and
  2,000 across the map. Additional spawned customers are folded into their
  settlement's virtual population instead of remaining as pathfinding units.
- Virtual customers remain real economically: they can reserve and buy EVs,
  their sold vehicles consume charger capacity, and they contribute to
  settlement mood, reservations, sales progression, and Robotaxi demand.
- Robotaxi Service Centers allocate against aggregate settlement population and
  settlement position. They no longer scan every nearby mobile customer.
- Physical charging commutes remain a bounded visual sample. Virtual vehicle
  owners are represented in charging utilization and mood without individual
  pathfinding or rendering work.
- The 2,000-unit ceiling is conservative. The July 2026 synthetic benchmark
  measured about 21 ms/update for 20,000 ordinary moving biters before adding
  meaningful FactoryX work; registered ownership added about 1.4 ms/update.
  The dominant 20,000-unit cost is Factorio's native unit simulation, although
  per-unit mod rendering and scans can compound it and remain prohibited.

## Quality Policy

- Physical assets use native Factorio quality improvements. Machines gain the
  normal speed and durability benefits; solar and storage use native quality
  scaling; EVs gain vehicle durability.
- Every two quality levels add one embedded battery to a placed FactoryX EV.
- Each quality level adds 10% EV capacity per stall to a charger. Stall count,
  footprint, and coverage radius stay fixed so placement remains readable.
- Abstract outputs do not roll quality. Dollar sales, AI Token production, and
  the final AGI Model use `allow_quality = false`.
- Tier 2 Speed, Productivity, Efficiency, and Quality module research is a
  terrestrial capital step: red, green, blue, and Dollars after the Sales
  Office. Tier 3 modules retain their later planetary progression gates.
- Launch vehicles are the deliberate exception: their native item quality
  represents manufacturing reliability. Their recipes allow quality modules
  but not productivity modules, and the launch system preserves the produced
  vehicle's quality through the attempt.

## Vehicle Build And Profit Balance

The implementation follows the useful architecture from the MIT-licensed
`electric-vehicles` mod: battery equipment stores energy and a runtime
transformer converts that energy into vehicle propulsion fuel. That mod and
its wireless-charging companion target Factorio 0.14, so FactoryX does not take
an obsolete dependency. It implements the pattern directly against Factorio
2.1, with FactoryX chargers supplying the grid draw.

| Vehicle | Build time | Sale time | Profit | Reservation |
| --- | ---: | ---: | ---: | --- |
| Prototype Roadster | 30s | 120s | 2 Dollars | 1 |
| Premium EV | 20s | 30s | 1 Dollar | 1 |
| Mass-market EV | 8s | 5s | 1 Dollar | 1 |
| Megatruck | 15s | 10s | 2 Dollars | 1 |
| Robotaxi | 20s | 3s per three | 1 Dollar per three | None |

One Dollar represents roughly US$10,000 of investable profit, not gross
revenue. Robotaxi economics remain provisional until the planned Robotaxi
Service Center replaces direct sales with fleet-service income.

## Current Economy

### Capital

`Dollar` is the main capital item. One item represents roughly US$10,000 of
investable capital in current-dollar terms. Dollars are produced by
selling products through Sales Offices, then consumed by technologies and scale
recipes.

Capital currently goes into:

- Research costs.
- Higher-tier EV Charging Stations. The v1 station is built from ordinary
  electrical infrastructure and does not consume Dollars.
- Gigafactory Modules.
- Space and satellite infrastructure.
- Datacenter and planetary grid infrastructure.
- Robotaxi and autonomy scaling.

### Research Progression And Balance

FactoryX research follows Factorio's cumulative-science convention. Major
industrial milestones retain earlier science packs instead of replacing them
with only the newest pack. Military science is generally excluded because the
tree is commercial, industrial, energy, and compute focused. Customer Referral
Program is the deliberate satirical exception.

#### Infinite Continuous Improvement

Four repeatable technologies provide permanent late-game uses for Dollars and
science. Their costs double each level. Customer Referral Program uniquely
requires military science; the joke is intentional and does not imply combat
functionality.

| Technology | Starts after | Effect per level |
| --- | --- | --- |
| Supercharging Power Electronics | EV Charging Network | Player EVs charge 10% faster; an occupied charging stall can draw 10% more power. |
| Long-range Battery | Capital Scaling | Customer capacity rises 5% per stall and drivable EV energy use falls 8%, capped at a 75% reduction. |
| Premium Audio Systems | EV Production Line | Consumer EV sales run 5% faster and Robotaxi trips return 5% more profit. Biters love Nickelback. |
| Customer Referral Program | EV Charging Network | Powered charging-driven settlement growth runs 10% faster; uniquely consumes military science. |

Research levels and their effects are visible in the FactoryX Progress panel.

| Technology | Cycles | Inputs per cycle | Time |
| --- | ---: | --- | ---: |
| Sales Office | 75 | Red, green | 20s |
| EV Production Line | 250 | Red, green, blue, Dollar | 30s |
| EV Charging Network | 300 | Red, green, blue, Dollar | 30s |
| Energy Products | 250 | Red, green, blue, Dollar | 30s |
| Mass-market EV Production | 1,000 | Red through yellow, Dollar | 60s |
| Terrestrial AI | 1,000 | Red through yellow, Dollar | 60s |
| Autonomous Logistics | 1,000 | Red through yellow, AI Token, Dollar | 60s |
| Small Orbital Launch | 1,000 | Red through yellow, Dollar | 60s |
| Reusable Launch | 1,500 | Red through space, Dollar | 60s |
| Satellite Constellation | 2,000 | Red through space, Dollar | 60s |
| Orbital Compute | 2,000 | Red through space, electromagnetic, AI Token, Dollar | 60s |
| Planetary Energy Grid | 2,500 | Red through space, four planetary packs, AI Token, Dollar | 60s |
| AGI Training Run | Automatic unlock | One billion cumulative AI Tokens | N/A |

Mass-market EV Production explicitly requires Energy Products plus production
and utility science. Autonomous Logistics uses Logistic Robotics rather than
Space Age's space-gated Logistic System, preserving the terrestrial-first
roadmap. Orbital Compute adds electromagnetic science for high-end compute
hardware. Planetary Energy Grid consumes every official pre-Promethium science
pack. The AGI unlock is a production milestone rather than another laboratory
research count.

Planetary Grid Segments are not laboratory science. They remain physical
infrastructure assembled in the controller and consumed by the final training
run.
This prevents a large research count from silently multiplying segments and
keeps the visible build-and-train victory mechanic dominant.

### Recipe Design Rule

FactoryX recipes should normally use two to four inputs. Three is a natural
default, not a quota. Every input must represent a distinct subsystem or
gameplay logistics stream.

Higher-level Factorio items carry their own material complexity forward. A
recipe that consumes a Substation should not separately repeat its advanced
circuits, copper cable, or steel. An Accumulator already represents cells and a
metal enclosure. A Car already represents the chassis, engines, iron, and
steel. Processing Units already contain advanced circuits. This keeps recipes
readable without making them cheap: difficulty should come from quantities,
craft time, power, prerequisites, and throughput rather than redundant input
slots.

### Proposed Battery Chemistry Branch

The proposed branch replaces the generic Battery Pack with high-nickel and
LFP chemistry families. Premium EVs use high-energy nickel packs; Mass-Market
EVs, Robotaxis, and Megapacks use cheaper long-life LFP packs; Megatrucks add
high-energy packs to their mass-market donor vehicles. Nickel Ore and Lithium
Brine are the only new natural resources. Coal supplies graphite, stone supplies
phosphate, and early nickel refining produces a small cobalt byproduct.

Battery recycling is 90% efficient for active cell material only: ten damaged
packs return 72 of their original 80 cells, enough to rebuild nine packs after
supplying fresh Accumulators and electronics. Chemistry cannot be transmuted,
customer kills do not drop recoverable packs, and battery refining, cell, pack,
and recycling recipes reject productivity to prevent Gigafactory V2's built-in
productivity from creating an overly rich closed loop.

The complete proposed recipes, balance audit, progression gates, and
implementation slices are in
[`feature_specs/factoryx_battery_chemistry_branch.md`](feature_specs/factoryx_battery_chemistry_branch.md).

Current simplified terrestrial recipes:

- Sales Office: `Assembling Machine 2 + Radar + Concrete`.
- V1 EV Charging Station: `Substation + Accumulators + Concrete`.
- Battery Pack: `Accumulator + Electronic Circuits + Copper Cable`.
- Electric Drivetrain: `Electric Engine Unit + Advanced Circuits + Copper Cable`.
- Prototype Roadster: `Car + Batteries + Advanced Circuits`.
- Premium EV: `Car + Battery Packs + Electric Drivetrains + Advanced Circuits`.
- Mass-Market EV: `Car + Battery Packs + Electric Drivetrain`.
- Megatruck: `2 Mass-Market EVs + 20 Steel Plates + 4 Battery Packs`.
- High-density Solar Panel: `1 Solar Panel + 2 Processing Units + 2 Low Density Structures + 1 Dollar`.
- Megapack: `Battery Packs + Accumulators + Substation`.
- Autonomy Computer: `Processing Units + Speed Modules`.
- Robotaxi Fleet: `Mass-Market EVs + Autonomy Computers + Dollars`.
- Gigafactory Module: `10 Dollars + 5 Assembling Machine 2s + 5 Labs + 50 Refined Concrete`.
- Gigafactory: `10 Gigafactory Modules + 2 Substations`.

The Prototype Roadster deliberately uses primitive batteries and electronics.
It cannot require FactoryX Battery Packs or Electric Drivetrains because its
first sale funds the EV Production Line technology that unlocks those parts.

### Sales Office

The Sales Office is the central economic machine. It converts physical products
into Dollars.

Current sales recipes:

- Prototype Roadster + EV Reservation -> 2 Dollars, displayed as `Sell hopes
  and dreams`: 60 seconds.
- Premium EV + EV Reservation -> 1 Dollar: 30 seconds. One Dollar represents
  roughly US$10,000 of profit.
- Mass-market EV + EV Reservation -> 1 Dollar: 5 seconds.
- Megatruck + EV Reservation -> 2 Dollars: 10 seconds.
- Megapack -> Dollars.
- Small launch service -> Dollars.
- Reusable launch service -> Dollars.

### EV sales milestone gates

Vehicle progression requires both the normal technology and completed,
force-wide customer sales. Premium EVs require 50 Prototype Roadsters sold;
Mass-market EVs require 250 Premium EVs sold; Megatrucks require 2,000
Mass-market EVs sold; and Robotaxis require 5,000 total Roadster, Premium,
Mass-market, and Megatruck sales. Production alone does not count. A completed
Sales Office contract increments the relevant total permanently, so an owner's
later death does not erase market progress. These intentionally large gates
push the player to reach several customer settlements and scale reservations,
charging, vehicle production, and Sales Office throughput together.
- Three Robotaxi Fleet items -> 1 Dollar: 3 seconds. This consumes Robotaxis at
  one per second while representing roughly one Dollar of profit per three.

Dollar outputs represent profit, not vehicle revenue. This keeps the physical
currency useful as reinvestable capital without pretending that the business
retains its gross sales price.

Stack-size audit: individual EVs and Robotaxi Fleets stack to 1; Gigafactories,
Terrestrial Datacenters, Orbital Compute Arrays, and the Planetary Grid
Controller stack to 1; every charger tier stacks to 5; Sales Offices, large
Solar Arrays, and Megapacks stack to 10. Bulk capital, paperwork, science, and
intermediate components retain larger logistics-friendly stacks.

The design intent is that sales are not magic research points. The player
physically manufactures a product, belts it into a market-facing machine, and
belts capital back out.

A sale also requires a real mobile customer. Unsold mobile biters and spitters
show `$`; a Sales Office reserves one eligible buyer per represented vehicle
and pauses when none is available. A completed sale assigns the vehicle to that
customer and replaces `$` with the vehicle's item icon. Buyer selection favors
the least-utilized friendly settlements. Charging capacity is a preference, not
a sales hard cap: if real buyers remain, the Sales Office can sell beyond local
powered capacity. Excess owners become underserved, receive the settlement
alert, and enter the same three-minute grace followed by stochastic anger used
for charger removal and brownouts. Adding powered stalls restores service and
friendliness immediately. Once all mobile buyers own vehicles, scaling sales
still requires reaching additional colonies. If an owner dies, its vehicle
leaves the active fleet immediately; lifetime sales remain in the economic
statistics.

Holding or selecting a Sales Office shows its 128-tile customer conversion
radius. Hostile biter entities inside that radius are converted into customer
entities. The `Sales Office Coverage` shortcut, unlocked with the Sales Office
technology, toggles a per-player chart overlay for every Sales Office owned by
that player's force. The chart-only circles use a dark teal translucent fill and
restrained outline, so they remain readable without washing out Remote View.

Selecting or opening a Sales Office adds a live FactoryX diagnostics panel. It
uses a compact native icon/label/value table for state, settlements, available
buyers, EV owners, powered charging capacity, underserved owners, and reserved
buyers. It also forecasts the nearest local customer threshold as `N EV sales
-> +X kW`, using only settlements inside that office's market. This is the next
possible charging-load step, not a globally pooled sales promise. It deliberately
omits recipe, cycle, input, and output details already visible in Factorio's
machine GUI. Fixed short labels and a right-aligned value column prevent
truncation; one colored status strip gives the current action or blocker.

A full Dollar output inventory stops the selected sale recipe. No EV or EV
Reservation is consumed while blocked; inputs back up at the Sales Office,
then reservation paperwork eventually backs up at chargers. Removing Dollars
resumes the physical sales pipeline. This is normal Factorio backpressure, not
an automatic customer penalty.

### Progress And Diagnostics

- The `FactoryX Progress` shortcut uses the steel-X FactoryX emblem and is
  available throughout the game.
- It opens a movable screen panel that derives the current stage and next
  physical action from live force state rather than a static checklist.
- Once EV sales begin, its compact Grid power section shows FactoryX charging
  demand versus delivered power, powered versus requested stalls, supported
  versus stranded EV owners, and the nearest additional sale count that will
  activate another stall. Forecasts turn yellow inside the final quarter of a
  stall's customer capacity; existing power or capacity failures are red.
- Charging stations use ordinary electric-pole supply coverage like assemblers.
  Their hidden per-stall consumers draw the rated load but are not electric
  poles, cannot attract copper wires, and never become routing nodes between
  substations or other grid infrastructure.
- The panel is progressively disclosed. It shows the immediate objective and
  current milestone first, then only business products, infrastructure,
  improvements, and journey stages the force has actually reached. Robotaxi,
  orbital, and AGI telemetry stays hidden until its enabling research is done.
- The objective uses the relevant item icon and a progress bar when the current
  milestone is numeric. Compact icon/label/value rows replace the old telemetry
  table. Green means healthy or complete, yellow means available or in progress,
  and red identifies a concrete customer, charging, or infrastructure blocker.
- The Journey section contains completed milestones plus the current milestone
  only. Parallel terrestrial-industry unlocks remain in their own section and
  no longer block the main business journey display.
- Its inputs include research, Sales Offices, converted customer settlements,
  grid-connected chargers, sold EVs, active stalls, reservation output,
  first sales, both Gigafactory tiers, Energy Products, datacenters, autonomy,
  orbital compute, planetary-grid research, and victory.
- The panel reports lifetime Dollars produced, active charging throughput,
  physical reservation stock at chargers, and important infrastructure counts.
- `/factoryx-status` opens or refreshes the panel for players and returns the
  same current objective through RCON.
- Selecting either Gigafactory tier shows its state, rated power, selected
  recipe, cycle progress, exact input/output counts, missing ingredient, and
  output blockage. V2 also states its 2x speed and 150% built-in productivity.
- Selecting a biter or spitter spawner opens the Customer Settlement Inspector.
  It reports market coverage, assigned charger, active and free stalls, sold
  fleet size, network capacity, and the concrete reason for hostile status.
- Research completions and first placements provide concise physical next
  actions. First Mass-market EV sales are now tracked alongside the existing
  Prototype and Premium sales milestones.

### EV Charging Network

The EV Charging Station is the first demand-side infrastructure mechanic.

Current implementation:

- The station is an inventory-bearing site using custom charging-station art,
  so clicking it exposes reservation paperwork without opening the Factorio
  power-network UI.
- A station can be placed away from power, but it is inactive until it is within
  18 tiles of a friendly electric grid pole.
- Powered stations create a hidden electric-pole grid tap at the same position,
  so the site can retain a visible copper-wire connection to the grid while the
  station itself remains the clickable object. Unpowered stations remove that
  hidden tap and show Factorio's native flashing no-power alert to connected
  players.
- Logistic-network coverage is optional. The passive-provider capability makes
  bot pickup convenient when coverage exists, but the prototype suppresses the
  irrelevant no-logistic-network icon and runtime demand never checks logistics.
- Holding a charger item shows electric coverage and hides logistics coverage;
  changing the cursor restores the player's prior overlay choices.
- A v1 station has 4 stalls. Each covered biter customer settlement occupies one
  potential stall, capped at 4 per station.
- Each active stall consumes 50 kW from the electric grid.
- EV Charging Network unlocks V2: an 8-stall, 4x4 charging hub with a 96-tile
  customer radius. Each active V2 stall draws 150 kW, for 1.2 MW maximum.
- V2 costs `1 V1 Charger + 2 Substations + 20 Processing Units + 20 Dollars`.
- V2 uses dedicated aligned 4x4 art with eight visible stalls and heavier
  transformers.
- Mass-market EV Production unlocks the 5x5 V3 Supercharger: 12 stalls, a
  128-tile customer radius, and 250 kW per occupied stall for 3 MW maximum.
- V3 costs `1 V2 Charger + 4 Substations + 40 Processing Units + 75 Dollars`.
- Selling the first Robotaxi Fleet unlocks the 6x6 V4 Supercharger: 20 stalls,
  a 160-tile customer radius, and 500 kW per occupied stall for 10 MW maximum.
- V4 costs `1 V3 Supercharger + 4 High-density Solar Panels + 4 Megapacks +
  200 Dollars`. Its dedicated 6x6 art includes a broad solar canopy; 15 stalls
  are visible and the final row is represented beneath the canopy.
- Selecting a station opens a small FactoryX panel that shows grid
  status, covered biter customer settlements, active stalls, power draw,
  reservation rate, active EV Sales Offices, and the next progression step.
- Chargers remain passive-provider entities internally so logistic bots can
  collect reservation paperwork. Clicking one suppresses Factorio's generic
  logistic-container panel and opens only the movable FactoryX charger
  inspector; logistic coverage and robot counts are implementation details and
  are not shown as charger mechanics.
- Holding or selecting a station shows a 64-tile customer coverage radius using
  Factorio's native radius visualization. The field uses a muted leaf-green
  tint at low opacity so it remains readable without washing out terrain or
  looking like an aggressive warning overlay.
- V1 charger placement messages remain progression-neutral after reporting
  active stalls and covered settlements: the site serves customer EVs and
  prints EV Reservations for Sales Offices. Only the one-time first-site
  milestone announces that Prototype Roadsters have unlocked.
- The Sales Office technology enables the Sales Office, EV Charging Station,
  and `Sell hopes and dreams`.
- The first covered biter customer charging site enables the Prototype Roadster
  craft recipe for that force.
- Existing playtest saves also unlock on config sync if Factorio production
  statistics show a Prototype Roadster was already consumed.
- The three-input recipe is `Substation + Accumulators + Concrete`.
  The Substation already embodies switchgear, power electronics, heavy
  conductors, and a steel enclosure; the Accumulators add local buffering; the
  Concrete represents site work.
- More active charging stalls mean more EV Reservations: one per active stall
  per minute.
- Potential demand and actual utilization are separate. A stall is requested
  only by a settlement containing at least one living mobile vehicle owner.
  Manufactured inventory and historical production do not count.
- Charger consumers measure the electric network's delivered fraction. Powered
  stalls are the requested stalls multiplied by power satisfaction and rounded
  down, so a 50% brownout serves roughly half the requested stalls and prints
  half the paperwork.
- Each charger renders one small status light per physical stall. A dark light
  is unused; cyan pulses move from slow to faster as that stall rises through
  low, medium, and near-full utilization; red means sold vehicles are
  underserved; and a white lightning pulse means a sampled customer is
  physically charging. The visualization uses aggregate market state and is
  capped at the charger tier's fixed stall count, never the customer count.
- Placing or removing a charger immediately invalidates and rebuilds charging
  assignments after the entity registry changes. Buyer eligibility, stall
  lights, open entity inspectors, and FactoryX Progress refresh in the same
  event; periodic service reconciliation is only a fallback for missed events.
- A settlement that loses its stall because of overload, charger removal, or a
  power shortage stays friendly for three minutes. Anger checks then ramp from
  5% to 25% per minute. Restored powered service makes it friendly immediately
  and clears its short memory of the outage.
- Charging disruption and recovery do not print chat messages. Only affected
  settlements receive a persistent flashing map alert while service is
  unavailable. A charger icon means that settlement needs another or better
  nearby charger; an accumulator icon means its assigned stalls are losing
  service to grid power. Underpowered chargers also show their powered/requested
  active stall count. Restoring service removes the alerts. Routine customer
  settlement growth is silent, leaving the map and entity alerts as the
  operational interface.
- A charger with a reachable unsold buyer can print one slow bootstrap
  reservation before the first sale. Once owners exist, reservations scale at
  one per powered occupied stall per minute.
- Prototype, Premium, and Mass-market consumer EV sales consume EV Reservations,
  starting with the first Prototype Roadster. Robotaxis are capital-gated.
- This creates a reason to build charging infrastructure before high-volume
  consumer EV sales really take off.

Current limitation:

- Overlapping chargers can still see the same settlement as potential demand,
  but force-wide EV allocation prevents that overlap from creating more occupied
  stalls than produced vehicles.
- Future versions can make this more realistic by adding a custom coverage
  visualization and measuring powered coverage, unique chunks, city zones, or
  connected electric networks.
- Charger art is now distinct by tier and sized to the exact 2x2, 4x4, 5x5,
  and 6x6 footprints. A later animation pass can add status lighting without
  changing those readable silhouettes.

### Biter Customer Economy Research

The conceptual leap in the current economy is that someone is buying the EVs.
The funnier and more Factorio-native answer is: the biters are the customers.
Instead of treating biters as direct political enemies or abstract mobs,
FactoryX can turn them into non-aggressive biter customers whose settlements
create demand for EVs and charging infrastructure.

Current research notes from Factorio 2.1.9 docs and wiki:

- `LuaForce::set_cease_fire` can put forces on a cease-fire list so they are
  not targeted for attack. `LuaForce::set_friend` goes further and makes forces
  friendly, including preventing turrets from firing at them. Source:
  <https://lua-api.factorio.com/latest/classes/LuaForce.html>
- `LuaSurface` can find enemy units and entities, create entities, create unit
  groups, command units, pollute areas, find non-colliding positions, and call
  `build_enemy_base(position, unit_count, force)` to send a group to build a
  new enemy base. Source:
  <https://lua-api.factorio.com/latest/classes/LuaSurface.html>
- Commands can be given to enemies and unit groups, including go-to-location,
  attack-area, wander, and compound commands. Source:
  <https://lua-api.factorio.com/latest/concepts/Command.html>
- `game.map_settings.enemy_expansion` can be changed at runtime. Enemy
  expansion has an `enabled` flag, chunk scoring coefficients, settler group
  sizes, and cooldowns. Source:
  <https://lua-api.factorio.com/latest/concepts/EnemyExpansionMapSettings.html>
- Vanilla enemy expansion is not enough by itself for this design. The base
  game expands into "unclaimed" territory and penalizes chunks near player
  structures and existing spawners, so chargers would not naturally attract
  growth without scripted behavior. Source:
  <https://wiki.factorio.com/Enemies>
- Market entities exist, with offers and an `on_market_item_purchased` event,
  but they are player-click purchase UIs. They do not solve belt-fed sales to
  biters. Source:
  <https://lua-api.factorio.com/latest/classes/LuaEntity.html> and
  <https://lua-api.factorio.com/latest/concepts/Offer.html>

Practical mechanics available to us:

- Local customer conversion:
  - FactoryX creates a `factoryx-customers` force.
  - Normal `enemy` biters remain hostile to player forces.
  - Enemy spawners inside 128 tiles of a Sales Office become eligible customers;
    they convert only when a reachable powered charging stall can serve them.
    Nearby mobile biters and spitters follow the served settlement's force.
  - Worms remain on the enemy force and hostile to the player, even inside Sales
    Office coverage. Their immobility makes them a fixed hazard around customer
    settlements.
  - Player forces have cease-fire with `factoryx-customers`, while player/enemy
    cease-fire is explicitly disabled.
  - Enemy and customer forces have cease-fire with each other so hostile biters
    do not erase customer settlements.
  - Customer spawners, biters, and spitters get a solid `$` marker so
    playtesting can distinguish them from hostile entities.
- Demand detection:
  - Every bounded interval, convert Sales Office-covered enemy settlements into
    customer settlements.
  - Powered EV Charging Stations count customer spawners such as
    `biter-spawner` and `spitter-spawner`.
  - Convert customer settlement count, charger count, and Sales Office proximity
    into EV Reservations.
  - Keep the reservation item if possible. It becomes a physical "buyer
    reservation" rather than an abstract generated coupon.
- Sales:
  - Keep Sales Offices as the belt-fed conversion point.
  - Add or retheme recipes so mass-market EV and robotaxi sales are implicitly
    selling to covered biter settlements.
  - A Sales Office near biter settlements could receive a demand multiplier or
    accept a special recipe such as `Sell EVs to biters`.
- Charger-driven settlement growth:
  - Scripted growth is the right tool. Vanilla expansion avoids player
    structures, so it will not reliably grow around chargers.
  - If a charger has power, a nearby Sales Office, and recent EV sales, it can
    accumulate "customer adoption" points.
  - At thresholds, the mod can add a new biter settlement near the charger by
    finding a non-colliding position and either calling `build_enemy_base` or
    directly creating a small spawner cluster.
  - Growth must be capped per charger, per chunk, and per surface so it stays
    readable and does not become a UPS problem.

Implemented v1 behavior:

- A settlement is friendly only when it is inside Sales Office coverage and is
  assigned one reachable stall at a powered EV Charging Station. Sales coverage
  by itself no longer creates a cease-fire zone.
- Served spawners and their mobile biters become true friends with the player
  force. Converted mobile units have old enemy attack commands replaced with a
  persistent eight-tile wander command using `distraction = none`, so they move
  around locally without attacking player structures, enemy worms, or anything
  else under a customer `$` marker. Units that leave customer service get a
  short interruptible enemy wander command so vanilla hostility can resume.
- If a customer unit nevertheless damages player infrastructure, its command is
  immediately reset to non-combat wandering. This prevents a friendly unit from
  attacking a turret that correctly refuses to fire back.
- Mobile service is centered on each assigned customer spawner, not on the
  charger. This matters for V2-V4 sites whose served spawners can be well beyond
  48 tiles from the station: units born beside a served `$` spawner remain
  customers instead of immediately reverting to enemy force.
- Completed sales assign cars to living mobile customers; production alone does
  not form the fleet. Successive charger generations serve 12, 20, 32, and 50
  owners per stall. Sales may exceed that capacity while unowned friendly buyers
  remain. Only owners beyond powered capacity count as underserved. Overload,
  charger removal, and brownouts use one local three-minute grace-and-anger
  path; restored service recovers immediately.
- A served settlement with no physical or virtual population seeds one small
  mobile prospective customer. This prevents the first Reservation and sale
  from deadlocking on quiet, unpolluted spawners while preserving the rule that
  every sold EV must be assigned to a distinct owner.
- Existing mobile biters and spitters inside overlapping Sales Office and
  charger coverage convert as prospective customers across the charger's full
  tier-specific service radius. They are assigned to the nearest settlement
  served by that charger; hostile worms are never converted.
- Sales eligibility follows the buyer's home settlement, not the wandering
  unit's momentary position. A Sales Office can reserve an unowned mobile buyer
  when that buyer's operational home settlement is inside office coverage;
  wandering across the circle edge cannot pause an in-progress sale.
- Settlement population records are derived from live spawners, registered
  customers, and home-settlement assignments. Sales synchronization rebuilds
  that cache automatically if a same-version mod restart leaves it empty.
- An unowned mobile buyer may adopt another covered friendly settlement when a
  sale is reserved. Selection favors the lowest owners-per-capacity ratio, so
  spare charging is consumed before any settlement is deliberately oversold.
  This keeps ownership physical while preventing one prolific spawner from
  blocking a larger multi-settlement charging network.
- Registered mobile customers follow the service state of their home
  settlement, not whether wandering has carried them outside a short scan
  circle. Roaming cannot silently turn a served customer back into an enemy.
- Operational inspectors open as relative panels attached to Factorio's native
  entity window. Hovering or placing an entity never occupies the top-left HUD;
  details appear only while the player has explicitly opened that entity.
- Player EVs recharge at 3% of installed battery capacity per second while a
  powered stall serves them. Mining an EV never returns the hidden drive-fuel
  token; only the physical vehicle returns to inventory.
- Customer-colony growth accrues from powered customer stalls and spare local
  settlement capacity. It remains a five active-stall-minute process, while
  hostile worms retain their normal randomized appearance.
- While a player drives a FactoryX EV, powered chargers within 256 tiles show a
  private translucent green circle matching that tier's real player-vehicle
  charge radius. While energy is flowing, the EV shows a pulsing battery icon
  and live `CHARGING N%` label. These renderings are per connected player and
  never attach to customer units.
- Player-driven EVs must park physically at the site: V1 charges within 8 tiles
  and V2 through V4 within 10 tiles. Higher tiers scale charging power and stall
  throughput rather than becoming long-range wireless chargers.
- Entering or exiting a FactoryX EV briefly shows its battery percentage above
  that vehicle for two seconds. The private player-only label is green, amber,
  or red by charge level, remains solid for one second, then fades for one
  second. It uses the same embedded-battery measurement as the live charging
  indicator.
- Every active stall contributes one adoption point per second. Five active
  stall-minutes grow one new customer spawner when that charger still has a
  spare settlement stall and there are no stranded EVs.
- Each new customer spawner rolls for at most one hostile worm: 25% below 0.3
  evolution, 50% from 0.3 to 0.6, and 75% above 0.6. Worm tier still scales with
  evolution. The spawner and mobile customers remain protected by the customer
  cease-fire; any worm remains hostile and can be targeted normally.
- Growth is locally bounded by the charger's stall count. V1 can serve at most
  four nearby settlements and V2 can serve at most eight, so growth cannot run
  away without deliberate charging expansion.
- The charger panel and `factoryx` remote market status expose friendly and
  angry settlements, stranded EVs, spare settlement capacity, grown colonies,
  and progress toward the next colony.
- Visual behavior:
  - Customer spawning remains natural and FactoryX does not cap or cull mobile
    populations. Friendly non-owners use eight baked green prospect prototypes
    with native hover names such as `EV prospect (friendly) - Small biter`;
    hostile units retain their normal appearance.
  - Vehicle owners use 40 explicit baked prototypes: eight vanilla mobile forms
    multiplied by Roadster, Premium EV, Mass-market EV, Megatruck, and Robotaxi
    classes. Roadster is red, Premium is black, Mass-market is white, Megatruck
    is silver, and Robotaxi is gold.
  - Completed sales replace the selected mobile buyer with its class prototype
    while preserving position, health ratio, force, settlement, and ownership.
    Existing owners and unowned prospects migrate at a combined 50 units per
    second. Prospect replacement rewrites the settlement buyer queue to the new
    unit number. No per-owner Lua car-icon render object remains; only settlement
    `$` markers use custom rendering.
  - Friendly mobile customers wander independently near their conversion point.
    Commands are assigned only when a unit is converted, stopped, or carrying a
    non-wander command; the once-per-second service sync does not reset an
    already wandering unit.
  - Keep this strictly cosmetic and local. Broader routes between settlements,
    chargers, and Sales Offices remain deferred because unit pathfinding is
    expensive compared with counting static spawners.

Recommended design direction:

1. Recast EV Reservations as biter-customer demand.
2. Keep the existing Sales Office and EV Charging Station as the main gameplay
   objects.
3. Add biter settlements as a demand amplifier, not a required dependency for
   the first `Sell hopes and dreams` sale.
4. Make Sales Office-covered biter customers the default FactoryX market
   behavior while keeping normal biters hostile.
5. Make settlement growth a scripted reward for serving demand, not a vanilla
   enemy-expansion side effect.

This creates a more coherent fiction:

- Early prototype Roadster sales are "hopes and dreams."
- Once the player wants mass-market sales, they need reachable customers.
- Biters become the customers.
- Charging stations are not just abstract coverage. They become the thing that
  lets biter settlements adopt EVs, which then creates more demand and more
  settlement growth.

The first implementation should avoid adding new art. It can reuse the current
Sales Office, EV Charging Station, EV Reservation, and Dollar items, with a new
runtime demand rule and a command report. A later pass can add a distinct Biter
Dealership, customer settlement marker, or decorative charger activity.

### Gigafactory Module

Gigafactory Module replaces the old abstract Factory Capex idea.

Current recipe inputs:

- Dollars.
- Assembling machine 3s.
- Express transport belts.
- Concrete.

Design meaning:

- This is a tangible package of factory expansion hardware.
- It represents converting capital plus real production equipment into scalable
  industrial capacity.
- Late infrastructure consumes Gigafactory Modules instead of abstract capex.

### AI Tokens, AGI, And Planetary Grid Segments

AI token is a physical science-like output.

Current design:

- Terrestrial datacenters produce AI tokens slowly.
- Orbital Compute Arrays produce AI tokens at scale in space.
- Late technologies consume AI tokens directly. Lifetime AI Token production
  across all surfaces is also tracked toward the one-billion-Token AGI gate.
- Planetary Energy Grid Controllers become 1 TW training machines. They convert
  large AI Token streams, Megapacks, Satellite Buses, and Ground Station
  Networks into Planetary Grid Segments.
- Planetary Grid Segments are physical inputs to the final AGI Training Run,
  not laboratory science.
- The final AGI Training Run consumes four large streams: grid segments,
  100 million physical AI Tokens, supporting energy hardware, and 10 million
  Dollars, plus a sustained one-terawatt controller cycle. Satellite and ground
  infrastructure are embodied in the grid segments.

The important balance goal is that land-based compute should not be enough for
the final game. The player should need many space platforms running orbital
compute and returning AI tokens to the planet. Those tokens are not power beamed
from space; they are trained-model data and knowledge used by the planetary
training system. Terrestrial production can contribute forever, but reaching
one billion without orbital compute should be economically absurd.

## Concrete Tech Tree Arc

This is the target shape for the full design. Some names already exist in code;
some are recommended renames or future mechanics.

### Terrestrial Industrial Supply Chain

Before the Sales Office, FactoryX should offer a red-and-green-science
`Industrial Supply Chain` branch. It does not produce or consume Dollars. Its
purpose is to make the terrestrial opening materially different from ordinary
Nauvis by moving a carefully selected set of Space Age industrial machines
into an earlier, self-contained progression. The Sales Office remains the first
business and the first source of capital; do not add an early normal-Car sales
loop.

The branch should be implemented and balanced in this order:

1. **Industrial Supply Chain** (`automation-science-pack` and
   `logistic-science-pack`) establishes the branch and unlocks the adapted Big
   Mining Drill research. It should require Electric Mining Drills but no oil,
   plastics, blue science, or Dollars.
2. **Heavy Mining Equipment** unlocks the Big Mining Drill with the terrestrial
   recipe `4 Electric Mining Drills + 20 Engines + 20 Electronic Circuits`.
   Remove its vanilla molten-iron, tungsten-carbide, Foundry-only, and Vulcanus
   dependencies. This is intentionally an early and powerful accelerator; its
   electricity draw, footprint, and reduced resource drain remain the costs.
3. **Electric Metallurgy** makes Electric Furnaces available before plastics.
   Because the vanilla furnace recipe uses Advanced Circuits, FactoryX must
   deliberately replace those with Electronic Circuits; otherwise the intended
   pre-plastics Foundry gate is impossible. Keep the rest of the furnace recipe
   recognizable and cover this global recipe change with a prototype test.
4. **Terrestrial Foundry** unlocks sparse Nauvis calcite deposits, ore melting,
   metal casting, and the Foundry recipe `25 Electric Furnaces + 50 Electronic
   Circuits + 200 Refined Concrete`. Remove the magnetic/pressure, Vulcanus,
   tungsten, and molten-metal construction restrictions that prevent terrestrial
   crafting. This is deliberately available before plastics as a playtest
   experiment. Foundry's built-in productivity may radically reduce early ore
   pressure, so telemetry should compare ore mined, plates produced, power, and
   time-to-Sales-Office against the previous run before this becomes permanent.
5. **Vehicle Recycling** research is revealed when the first Wrecked EV is
   produced. The player must then complete its red-and-green-science research
   before the Recycler and explicit FactoryX Wrecked EV recipe unlock. This
   relocates the Recycler without importing Fulgoran scrap or holmium, with
   probabilistic recovery of recognizable EV ingredients. Explicit
   recipes are preferred over automatic recipe reversal so returns can be
   balanced and cannot create ingredient loops.
6. **Tesla Weapons** relocates the Tesla Gun/Turret branch without holmium,
   electrolyte, superconductors, or electromagnetic science. Recipes should use
   existing terrestrial and FactoryX intermediates such as Battery Packs,
   Processing Units, steel, accumulators, and Dollars. This is a later
   terrestrial branch, not part of the red-and-green bootstrap; exact recipes
   and placement relative to Robotaxis remain a balance decision.
7. **Mech Armor** remains future content. It must be built from an Optimus
   Humanoid Robot when that product exists, making the armor the wearable result
   of FactoryX robotics rather than a transplanted Fulgora recipe. Its other
   ingredients should use terrestrial FactoryX power electronics and advanced
   materials, not holmium.

Charging infrastructure participates in the circular economy. Each active
stall's completed reservation-generation cycle has a 1% chance to produce one
`Wrecked EV` in addition to its normal demand paperwork. This ties wreck volume
to sold-EV charging demand, not merely to placed chargers. Robotaxi Service
Centers should remain the larger, predictable source of wrecks because fleet
vehicles are operated continuously and slowly wear out.

Explicit exclusions:

- Do not relocate the Electromagnetic Plant or create a Nauvis holmium chain.
- Do not import Gleba materials, biological recipes, or technologies.
- Do not require Dollars anywhere in the Industrial Supply Chain bootstrap.
  Capital first enters progression through the existing Sales Office economy.
- Do not automatically relocate every planetary technology. Recycler, Big
  Mining Drill, Foundry, Tesla weapons, and future Optimus-derived Mech Armor
  are the intentional exceptions.

### 1. Sales Office: Customer Discovery

Player proof:

- Place a Sales Office near a biter settlement.
- The covered settlement converts to the `factoryx-customers` force and gets a
  simple customer marker.
- Place a powered EV Charging Station so one customer spawner occupies one
  charger stall.
- Craft one Prototype Roadster.
- Run the deliberately slow `Sell hopes and dreams` contract and belt out the
  first Dollars. Target sale time: 60 seconds.

Why it works:

- The player sees the customer.
- The player sees the charger coverage and stall count.
- The first sale is slow enough to feel like a milestone.

Next concrete unlock:

- EV Production Line.

### 2. EV Production Line: From Prototype To Premium Product

Tesla-like meaning:

- The first capital goes into tooling: battery packs, drivetrains, jigs,
  assemblers, power electronics, and better shop-floor logistics.

Implemented design:

- Player-facing technology name is `EV Production Line`; its prototype id is
  `x-premium-ev-program`.
- Research costs 250 cycles of Dollars plus red/green/blue science. This makes
  the first production program a meaningful bootstrap investment while leaving
  the truly large science jump for mass-market scale.
- The first completed `Sell hopes and dreams` sale prints a next-step message
  telling the player to research EV Production Line.
- EV Production Line unlocks `Battery Pack`, `Electric Drivetrain`, `Premium
  EV`, and `Sell premium product` after the existing 50-Roadster market gate.
- Premium EVs can initially be built in ordinary advanced assemblers. Producing
  100 completes the pilot run; the pilot plus Energy Products unlock both
  `Gigafactory Module` and the Gigafactory construction recipe.
- Energy Products remains a parallel power branch for High-density Solar
  Arrays and Megapacks, and is required before Gigafactory construction or
  mass-market scaling.
- Every Sales Office recipe uses the sold product as its dominant icon with a
  small gold coin badge. EV, Megapack, launch-service, and Robotaxi sales are
  visually distinct in the recipe chooser.
- The Gigafactory is the tangible production gate; do not add a separate EV
  Production Line Kit item.

Gigafactory design:

- Internal prototype target: `x-gigafactory-building`.
- A dedicated 9x9 production building, approximately the footprint of a rocket
  silo.
- Producing 100 Premium EVs and researching Energy Products reveals Factorio's
  Logistic System technology alongside Gigafactory construction. It costs 500
  cycles of red, green, blue, and Dollars, granting requester, buffer, and
  active-provider chests without Space Age's space-science gate. The player
  chooses when to fund logistics automation; placing a Gigafactory no longer
  silently completes the research.
- FactoryX `Autonomous Logistics` remains the later AI/Robotaxi technology; it
  is not the requester-chest unlock.
- A Gigafactory Module is one repeatable production cell: capital, machines,
  line logistics, and factory floor. The Gigafactory is assembled from several
  of these modules.
- Gigafactory Module recipe:
  `10 Dollars + 5 Assembling Machine 2s + 5 Labs + 50 Refined Concrete`.
- Gigafactory construction recipe:
  `10 Gigafactory Modules + 2 Substations`.
- Total large-factory bill of materials:
  `100 Dollars + 50 Assembling Machine 2s + 50 Labs + 500 Refined Concrete + 2 Substations`.
- Labs replace direct belts because each Lab already embodies belts, gears, and
  electronic circuits. Five hundred Refined Concrete embodies 1,000 ordinary
  Concrete plus reinforcing materials, giving the building a foundation cost
  comparable to a rocket silo.
- Dollars, machinery, line logistics, and concrete are embodied in the modules,
  so the Gigafactory recipe does not bill those inputs a second time.
- Premium EVs use both advanced crafting and the FactoryX vehicle-assembly
  category, allowing the first ten to be built slowly in AM2/AM3 machines and
  later scaled in a Gigafactory. Mass-market EVs remain Gigafactory-only.
- Prototype Roadsters remain craftable in ordinary advanced assemblers because
  they precede the production-line investment.
- Active power draw is 20 MW, with a native unpowered/low-power
  state. This is the first meaningful factory power step before chargers and
  datacenters create much larger demand.
- V1 runs at crafting speed 4 with 50% built-in productivity. Every two
  Premium EV input sets therefore produce three vehicles before quality or
  speed specialization. This material advantage is the primary payback for
  its 100-Dollar, 50-assembler, 50-lab construction bill.
- Both Gigafactory tiers accept up to eight modules. Speed, efficiency,
  pollution, and quality effects work on their recipes. Productivity modules
  follow the base-game rule and work only on intermediate-product recipes;
  V1's 50% and V2's 150% built-in productivity remain part of the machines
  themselves.
- A curated `Gigafactory vertical integration` category makes the factory a
  super-assembler without exposing every ordinary assembler recipe. It includes
  Copper Cable, Electronic Circuits, Advanced Circuits, Low Density Structures,
  Gigafactory Modules, Gigacasts, Battery Packs, Electric Drivetrains, Autonomy
  Computers, Datacenter Racks, Reusable Boosters, Satellite Buses, and Ground
  Station Networks.
- Premium EVs, Mass-market EVs, Robotaxi Fleets, High-density Solar Panels, and
  Megapacks are final products and explicitly reject productivity modules.
- The Gigafactory uses a centered, axis-aligned 9x9 static sprite whose visible
  base fills the collision footprint. A later animation pass should preserve
  that footprint-readable silhouette.
- The 100-Premium-EV pilot milestone unlocks the Gigafactory Module and
  Gigafactory recipes together. Gigafactory Modules remain useful as repeatable
  capital inputs for later datacenters and more Gigafactories.
- Both Gigafactory tiers manufacture energy hardware through the dedicated
  `x-energy-products` recipe category. Energy Products research can proceed in
  parallel; its hardware recipes become available in an unlocked Gigafactory.

Gameplay loop:

- Manufacture battery packs and drivetrains.
- Build ten pilot Premium EVs in ordinary assemblers.
- Use the newly unlocked modules to build a Gigafactory and scale production.
- Sell Premium EVs through Sales Offices for more Dollars.
- Premium sales are faster than `Sell hopes and dreams`, because the business
  has moved from hand-built prototype to limited production: 30 seconds per EV
  for 1 Dollar of profit.
- EV Production Line research completion prints a concrete production-chain
  prompt.
- The first `Sell premium product` completion prints the next scale prompt:
  build EV Charging Network and prepare for mass-market EVs.

Next concrete unlock:

- EV Charging Network as an expansion system, not just a recipe.

### 3. EV Charging Network: Demand Infrastructure

Tesla-like meaning:

- Premium products prove the market, but mass adoption needs visible charging
  infrastructure.

Current implemented rule:

- V1 chargers have 4 stalls.
- V2 chargers have 8 stalls, a 4x4 footprint, and a 96-tile customer radius.
- V3 Superchargers have 12 stalls, a 5x5 footprint, and a 128-tile customer
  radius.
- V4 Superchargers have 20 stalls, a 6x6 footprint, a solar canopy, and a
  160-tile customer radius.
- Service capacity rises with charging generation: V1 serves 12 EVs per stall,
  V2 serves 20, V3 serves 32, and V4 serves 50. Total site capacities are 48,
  160, 384, and 1,000 EVs respectively.
- Each active stall requires one Sales Office-converted customer spawner.
- Total active stalls are capped by cumulative EV sales across the force.
- Active stall draw rises by tier: V1 50 kW, V2 150 kW, V3 250 kW, and V4
  500 kW. Peak site demand is therefore 200 kW, 1.2 MW, 3 MW, and 10 MW.
- Every active stall creates one EV Reservation per minute in its charger.
- Sales Office customer conversion range is larger than charger range: 2x the
  V1 charger radius, currently 128 tiles.

Current presentation work remaining:

- Keep V1 chargers simple.
- Replace V2/V3/V4 temporary scaled and tinted art with footprint-specific
  sites. V4's final art should retain the solar canopy.
- Sales Office panels and `/factoryx-coverage` should keep reporting:
  customer settlements, powered chargers, active stalls, power draw, active Sales
  Offices, and reservation rate.

Next concrete unlock:

- Mass-market EV Production: mass-market EVs become possible only after the
  player has Dollars, charger-created demand, and a Gigacast-equipped factory.

### 4. Mass-Market EV Production

Tesla-like meaning:

- Use premium-product profits and charging coverage to make cheaper cars at
  higher volume.

Current code:

- `x-capital-scaling` is displayed as `Mass-market EV Production`.
- Research requires 1,000 cycles of red-through-yellow science plus 1,000
  Dollars, and explicitly requires Energy Products.
- It unlocks `Gigacast`, `Gigafactory V2`, `Mass-market EV`, and
  `Sell mass-market EV`.
- Gigafactory V1 can build Premium EVs. Mass-market EVs use a dedicated recipe
  category available only in Gigafactory V2.
- Gigafactory V2 runs at crafting speed 8, exactly twice V1's raw throughput,
  with 150% built-in productivity and a 30 MW draw. It uses 25% less energy per
  unit of crafting speed than V1 while retaining a substantial absolute grid
  load.
- Gigafactory V2 is crafted in an Assembling Machine or either Gigafactory tier
  from one Gigafactory item, one Gigacast, and 100 Dollars. V1 and V2 share a
  fast-replace group, so a V2 item can be placed directly over a V1 building.
  The replaced V1 is returned just like an Assembling Machine tier upgrade.
  The recipe does not repeat the concrete already embodied in Gigafactory V1.
- Gigacast consumes 20 Electric Furnaces, 500 Steel Plates, 50 Electric Engine
  Units, and 50 Dollars.
- The sales recipe consumes EV Reservations, so charger demand matters.

Target feel:

- The player should not be able to spam mass-market sales from one early charger.
- Mass-market EVs should be cheaper per vehicle than Premium EVs, but the sales
  contract should stay literal and readable:
  `1 Mass-Market EV + 1 EV Reservation -> 1 Dollar`.
- Sale time is 5 seconds. This preserves the high-throughput
  mass-market feel while allowing charger reservation output to bottleneck
  sustained sales. Tune the time after playtesting rather than batching cars in
  groups of five.
- This is the first loop where charger stall count should obviously bottleneck
  revenue.

Roadmap after V2:

- Gigafactory V3 should require a new physical `Humanoid Robot` item, turning
  humanoid factory labor into the next concrete automation leap.
- V3 should be a later terrestrial successor, likely tied to AI Tokens and
  Autonomous Logistics. Its exact productivity, speed, recipe, power draw, and
  vehicle access remain intentionally undecided until V2 is playtested.
- Humanoid Robots and Gigafactory V3 will both require distinct artwork.

Next concrete unlock:

- Energy Products and broader Gigafactory scaling.

### 5. Gigafactory Modules: Production Cells And Factory Expansion

Tesla-like meaning:

- Capital is now spent on factories, production cells, line automation, concrete,
  logistics, and power distribution.

Current code:

- `Gigafactory Module` already replaces the abstract `Factory Capex` idea.
- EV Production Line unlocks its production-cell recipe using Dollars,
  Assembling Machine 2s, Labs, and Refined Concrete.

Target feel:

- This should become the main midgame capital sink.
- Ten modules plus Substations construct one 9x9 Gigafactory.
- It should be required by big infrastructure recipes so Dollars are not just a
  research ingredient.
- Building additional Gigafactories repeats module demand instead of introducing
  another abstract factory token.

Next concrete unlock:

- Gigafactory / Energy Products.

### 6. Energy Products

Tesla-like meaning:

- Once factories scale, the business expands from cars into solar generation and
  energy infrastructure.

Current code:

- `x-energy-products` branches directly from EV Production Line, solar energy,
  and electric energy accumulators; it does not require production science or
  Mass-market EV Production. The physical recipes remain the scaling gate.
- It unlocks the placeable 300 kW High-density Solar Panel, the placeable 100 MJ
  Megapack, and `Sell Megapack`.
- Megapack charges and discharges at up to 5 MW.
- The High-density Solar Panel is a 3x3, five-times-output direct upgrade from a
  conventional Solar Panel. A filtered upgrade planner lets construction robots
  modernize an existing field in place while returning the old panels to
  logistics for reuse.
- Ordinary assemblers upgrade one Solar Panel with 2 Processing Units, 2 Low
  Density Structures, and 1 Dollar. The item stacks to 10 rather than the
  conventional panel's 50.
- After the Gigafactory production gate, either Gigafactory tier unlocks a
  mass-production recipe: 4 Solar Panels, 6 Processing Units, 6 Low Density
  Structures, and 3 Dollars produce 4 High-density Solar Panels. This is an
  explicit 25% advanced-component and capital discount without allowing
  productivity modules on a finished product.
- Both Gigafactory tiers can manufacture Megapacks and mass-produce panels.
- Megapack costs 12 Battery Packs, 4 Accumulators, and 1 Substation.

Target additions:

- Reserve the player-facing name `Megafactory` for a later dedicated Megapack or
  grid-storage factory, matching Tesla's distinction between vehicle
  Gigafactories and the Lathrop Megafactory.
- Recipes should lean on meaningful composite infrastructure. Grid-storage
  products use Battery Packs, Accumulators, and a Substation; they do
  not separately repeat the Substation's circuits or steel.
- This stage should teach the player that the final victory will be an energy
  infrastructure problem, not just a research problem.

Next concrete unlock:

- Small Orbital Launch.

### 7. Small Orbital Launch: Capital Enters Space

SpaceX-like meaning:

- Early launch services are expensive, small, and not yet reusable.
- The shared Dollar economy lets EV profits fund launch capacity.

Current code:

- `Small Orbital Launch` unlocks `Small Launch Service` and its Sales Office
  recipe.

Target feel:

- A Small Launch Service should be a physical product made from rocket fuel,
  low-density structures, processing units, and maybe Dollars.
- Selling it through the Sales Office represents commercial launch contracts.
- It should produce a lot of Dollars, but the recipe should be slow and
  material-heavy.

Planned early-launch reliability mechanic:

- Replace the abstract service-only step with a dedicated Rocket Factory that
  manufactures a physical early launch vehicle. The intended progression path
  requires installing quality modules in this factory and supplying enough
  ingredients to tolerate failed quality rolls.
- The early vehicle mirrors the Falcon 1 bootstrap period: normal and uncommon
  vehicles may be launched, but always fail. A rare-or-better vehicle succeeds.
- Every attempt consumes its vehicle and payload. Failure creates a visible
  launch explosion and perhaps a small amount of ordinary wreckage or scrap;
  it produces no Dollars, satellite deployment, or progression credit.
- The first successful rare launch is the milestone that proves orbital access
  and unlocks the next launch generation. Merely manufacturing or attempting a
  launch is insufficient.
- Do not add abstract Engineering Data or Launch Credit. Failed attempts are
  their own lesson; the player's concrete response is better modules, more
  production, and another vehicle.
- The Launch Pad inspector must state the reliability rule before commitment:
  `Early launch vehicle: rare quality required for success.` It should also
  report attempts, failures, and successful launches by force.

Proposed reliability progression:

| Launch generation | Normal | Uncommon | Rare or better | Design purpose |
| --- | ---: | ---: | ---: | --- |
| Early expendable | 0% | 0% | 100% | Quality modules bootstrap the program. |
| First reusable | 75% | 95% | 100% | Reliability is much better, but early production still carries risk. |
| Mature reusable | 100% | 100% | 100% | Quality improves recovery and economics rather than basic mission success. |

- For mature reusable vehicles, higher quality should increase booster recovery
  chance or recovered-booster quality instead of gating access to orbit. This
  keeps quality valuable without making the late launch economy arbitrarily
  unreliable.
- Before implementation, spike both supported approaches against Factorio 2.1:
  preserving quality through a real rocket-silo launch event, or using a
  dedicated scripted Launch Pad. Prefer the native rocket animation and launch
  event if it can inspect the physical launch vehicle's quality without also
  forcing the player through a duplicate vanilla rocket-production path.

Planned launch-water mechanic:

- The Rocket Factory manufactures the vehicle, but a separate Launch Pad must
  receive a large, sustained water supply for flame suppression, acoustic
  suppression, and pad cooling. Water is physical infrastructure, not another
  launch token or packaged intermediate.
- Initial tuning target: drain `4,800 water/second` during a 60-second launch
  sequence, equivalent to four normal offshore pumps running at their full
  `1,200 water/second` output and `288,000 water` per attempt. Failed early
  launches consume the full deluge just like successful launches.
- Give the pad only a modest working buffer so one pump cannot slowly fill an
  enormous internal tank and bypass the intended flow challenge. Sustained
  under-delivery should pause and slowly rewind launch preparation without
  destroying the vehicle; the inspector and map warning should say
  `Insufficient launch-water flow`.
- Show current water flow, required flow, buffered water, and launch readiness
  in the Launch Pad inspector. Avoid chat messages for ordinary shortages.
- This should create a meaningful siting decision: build near a large body of
  water, construct several long pipelines, or deliver water to a dedicated
  launch complex. Storage tanks can smooth brief interruptions but should not
  replace the multi-pump supply system.
- Treat `4,800 water/second` as the first playtest target. Benchmark the fluid
  network and tune the requirement before adding larger launch generations;
  reusable or heavy launch vehicles may demand still more flow.

Next concrete unlock:

- Reusable Launch.

### 8. Reusable Launch: Cheaper Access To Orbit

SpaceX-like meaning:

- Reusability should feel like a step-change in launch economics.

Current code:

- `Reusable Launch` unlocks Reusable Boosters, Reusable Launch Services, and a
  higher-value sales recipe.

Target additions:

- Keep V1 simple: craft boosters, craft reusable launch service, sell it.
- Later add recovery infrastructure or a probabilistic recovered-booster output.
- Avoid an abstract `launch credit` item; Dollars are enough.

Next concrete unlock:

- Satellite Constellation.

### 9. Satellite Constellation: Space Infrastructure Becomes A Network

SpaceX-like meaning:

- Launch capability turns into satellite deployment and ground network
  operations.

Current code:

- Unlocks `Satellite Bus` and `Ground Station Network`.

Target feel:

- Satellite Bus should be a physical payload item.
- Ground Station Network should be a physical infrastructure item or later a
  placeable entity.
- These should be used by orbital compute and planetary grid recipes so the
  player understands that data and coordination depend on deployed space
  infrastructure.

Next concrete unlock:

- Terrestrial AI.

### 10. Terrestrial AI: Useful But Not Enough

Tesla-like meaning:

- Autonomy and AI start on the ground: computers, racks, datacenters, power, and
  products like robotaxi fleets.

Implemented design:

- Unlocks Autonomy Computer, Datacenter Rack, Terrestrial Datacenter, and
  terrestrial AI token production.
- The 6x6 Terrestrial Datacenter runs the physical recipe
  `20 Dollars -> 20 AI Tokens` over 30 seconds while drawing 8 MW. At full
  speed that is 40 Dollars and 40 base AI Tokens per minute.
- Its inspector reports capital burn, effective output, tracked terrestrial
  production, current efficiency level, and the next output milestone.
- Terrestrial AI Efficiency unlocks at 1,000, 10,000, 100,000, 1 million,
  10 million, and 100 million tracked terrestrial AI Tokens. Each researched
  level adds 10% output without increasing capital or power per cycle. The
  runtime accumulates fractional improvement and emits whole 20-token bonus
  batches, matching Factorio's familiar productivity-bar behavior.
- The terrestrial track deliberately tops out at level 6: 32 AI Tokens per
  cycle, or 64/minute at full power. Scaling materially beyond that ceiling
  requires the separate Orbital AI track.
- Requires Mass-market EV Production, Energy Products, and Processing Units,
  with no launch, satellite, or space-science prerequisite.
- Research costs 1,000 cycles of cumulative red-through-yellow science and
  Dollars.
- A Terrestrial Datacenter costs a Gigafactory Module, four Datacenter Racks,
  four Substations, and 100 Refined Concrete.
- The placed datacenter is a large 6x6 server hall. Each 30-second cycle consumes
  20 Dollars, draws 8 MW continuously, and produces 20 AI Tokens.
- One datacenter needs 25 minutes to produce the 1,000 AI Tokens required for
  Autonomous Logistics, but more than two hours for the final 5,000-token
  workload. This makes terrestrial compute useful without replacing orbit.
- AI Tokens are acceptable as a science-like physical output because the player
  can belt them, launch them, or ship them.
- AI Tokens stack to 1,000,000, reflecting that trained models and inference
  data are much denser cargo than physical products.
- Terrestrial and orbital AI have independent efficiency tracks. Producing
  1,000, 10,000, 100,000, 1 million, 10 million, and 100 million Tokens in a
  track enables its next research level. Each level costs Dollars plus the
  appropriate science packs and adds 10% recipe productivity without increasing
  capital or power per cycle. Research cycles equal 10% of the threshold.

Next concrete unlocks:

- Autonomous Logistics.
- Orbital Compute.

### 11. Autonomous Logistics: Robotaxi Demand Loop

Tesla-like meaning:

- Robotaxis are not just better cars; they combine mass-market EVs, autonomy
  computers, charging coverage, and customer demand.

Implemented design:

- Unlocks `Robotaxi Fleet` and `Sell robotaxi fleet`.
- Autonomous Logistics research itself consumes 1,000 Dollars, and each Robotaxi
  Fleet consumes another 100 Dollars alongside four Mass-market EVs and four
  Autonomy Computers.
- Research also consumes 1,000 AI Tokens and cumulative red-through-yellow
  science. It requires Logistic Robotics, not Space Age's space-gated Logistic
  System technology, so Robotaxis remain the final terrestrial loop.
- Robotaxi Fleets can only be assembled in Gigafactory V2.
- Selling three completed Robotaxi Fleet items takes 3 seconds, returns 1
  Dollar, and does not consume an EV Reservation. Sustained input is one
  Robotaxi item per second.
- The first completed sale is an explicit progression milestone and points the
  player to Small Orbital Launch.
- Small Orbital Launch requires Autonomous Logistics and remains disabled until
  the first Robotaxi Fleet sale, making this the final terrestrial business
  loop before the space branch.

Next concrete unlock:

- Small Orbital Launch.

### 12. Orbital Compute: AI Moves Off-Planet

SpaceX/Tesla-like meaning:

- Space infrastructure is not beaming power back. It is running compute in orbit
  and returning AI Token data to the planet.

Current code:

- Orbital Compute Arrays can only run in low gravity.
- Orbital AI Token production is much stronger than terrestrial production.
- Research requires 2,000 cycles of red-through-space science,
  electromagnetic science, AI Tokens, and Dollars.

Target feel:

- The player should need many space platforms with Orbital Compute Arrays.
- Orbital compute should consume Satellite Buses, Ground Station Networks,
  Datacenter Racks, or maintenance-like inputs so it has a logistics footprint.
- The planet should receive large streams of AI Tokens and use them to coordinate
  final energy-grid construction.

Next concrete unlock:

- Planetary Energy Grid.

### 13. Planetary Energy Grid: Power The Final Training System

AGI meaning:

- The knowledge comes from terrestrial and orbital compute, but knowledge alone
  does not win. The planet needs a physical grid capable of powering one final,
  sustained training run.

Current code:

- Planetary Energy Grid Controller is a 1 GW machine.
- Research requires 2,500 cycles of every official pre-Promethium science pack,
  AI Tokens, and Dollars.
- Planetary Grid Segments consume AI Tokens, Megapacks, Satellite Buses, and
  Ground Station Networks. Those four composite inputs carry the space and
  energy infrastructure into the final stage.

Target feel:

- The player should first build the Planetary Energy Grid Controller.
- Then they should feed it Planetary Grid Segments and supporting items while
  scaling toward one terawatt of local generation and storage.
- The controller should make AGI training progress only while its full power
  requirement is satisfied. Brownouts pause or proportionally slow training;
  they do not erase completed progress.
- This mirrors the rocket silo pattern: build the silo, then launch the rocket.
  Here: build the controller and grid, then run the AGI training job.

Next concrete unlock:

- AGI Training Run, after one billion cumulative AI Tokens.

### 14. Achieving AGI: Final Training Run

Victory meaning:

- The player wins by completing a sustained, high-power AGI training run after
  proving that the whole economy can generate one billion cumulative AI Tokens.

Current implementation:

- Lifetime production statistics track cumulative AI Tokens across surfaces.
- One billion cumulative Tokens unlocks the controller-only AGI Training Run.
- Packing recipes turn 10,000 AI Tokens into one AGI Training Dataset and
  10,000 Dollars into one Capital Allocation, working around Factorio's 65,535
  per-ingredient limit without changing the economics.
- The run consumes 10,000 datasets, 1,000 allocations, 10,000 Planetary Grid
  Segments, and 1,000 Megapacks over 60 minutes at a 1 TW machine load. These
  embody 100 million AI Tokens and 10 million Dollars.
- Producing the concrete AGI Model triggers victory and allows continued play.

Target feel:

- Track lifetime AI Token production by force across every surface. Consuming,
  moving, or losing Tokens must not reduce the one-billion progress counter.
- At one billion cumulative Tokens, unlock `AGI Training Run`. The threshold is
  intentionally several orders of magnitude beyond practical terrestrial
  production and therefore forces orbital-compute scale.
- The first balance target for the final job is 100 million physical AI Tokens,
  10 million Dollars, Planetary Grid Segments, and supporting Megapacks.
  Physical Tokens and Dollars must arrive through normal logistics.
- The controller draws roughly 1 TW continuously for 60 connected gameplay
  minutes. Exact power and duration may be tuned from recorded playtest rates,
  but the run must remain a sustained grid test rather than an instant craft.
- Terrestrial AI, orbital AI, and the final AGI Training Run require full power.
  A low-power or no-power machine immediately loses all progress in its current
  compute cycle; restoring power begins that cycle again from zero.
- Completion produces one concrete `AGI Model` result and triggers Factorio's
  victory state while allowing the player to continue.
- It should be clear in the UI that the remaining blocker is either input
  logistics, cumulative Token progress, or power supply.

Legacy ending removed by this redesign:

- The legacy final-victory technology and all locale, icon, progression, and
  runtime references were deleted.
- The obsolete final charge item and recipe were deleted. The AGI Training Run
  replaces them as the controller's final operation.
- The old victory trigger and wording were replaced by the AGI Model completion
  event.
- No compatibility aliases are required because FactoryX is still in
  fresh-save playtesting.

## New Prototypes And Artwork Needs

The current MVP uses layered or tinted vanilla icons and copied vanilla machine
graphics. That is good enough for prototype validation, but not for a polished
release. This table tracks what should eventually get custom artwork.

Current concept review page:

- `art/factoryx-review/index.html`
- Scope: implemented prototypes marked as needing new artwork.
- Format: one 2x2 concept sheet per prototype, with four prototype directions
  per sheet.
- Future candidate entities are intentionally excluded from this review page.

Current selected-art review:

- `art/factoryx-review/selected/index.html`
- Cropped selected images: `art/factoryx-review/selected/assets/`
- Structured picks: `art/factoryx-review/selected-picks.json`
- Quadrant legend: option 1 = top-left, option 2 = top-right, option 3 =
  bottom-left, option 4 = bottom-right.

Current production-art QA:

- `art/factoryx-qa/index.html`
- Shows every custom entity against its tile footprint, every icon at inventory
  and belt scale, live previews of the lightweight animation overlays, and the
  locally composed technology illustrations.
- Approve/revise decisions persist in browser local storage and `Copy review`
  creates a pasteable result list.
- Rebuild with `scripts/build-factoryx-art.py` followed by
  `scripts/build-factoryx-art-qa.py`.

Selected directions:

| Prototype | Player Name | Selected Option |
| --- | --- | --- |
| `x-sales-office` | Sales Office | 4, bottom-right |
| `x-ev-charging-station` | EV Charging Station | 4, bottom-right |
| `x-terrestrial-datacenter` | Terrestrial Datacenter | 1, top-left |
| `x-orbital-compute-array` | Orbital Compute Array | 3, bottom-left |
| `x-knowledge-synthesizer` | Knowledge Synthesizer | 2, top-right, retired from playable mod |
| `x-ev-reservation` | EV Reservation | 3, bottom-left |
| `x-gigafactory-module` | Gigafactory Module | 3, bottom-left |
| `x-ai-token` | AI token | 4, bottom-right |
| `x-k1-knowledge` | K1 knowledge | 4, bottom-right, retired from playable mod |
| `x-prototype-roadster` | Prototype roadster | 1, top-left |
| `x-premium-ev` | Premium EV | 1, top-left |
| `x-mass-market-ev` | Mass-market EV | 2, top-right |
| `x-robotaxi-fleet` | Robotaxi fleet | 3, bottom-left |
| `x-small-launch-service` | Small launch service | 1, top-left |
| `x-reusable-booster` | Reusable booster | 1, top-left |
| `x-reusable-launch-service` | Reusable launch service | 2, top-right |
| `x-satellite-bus` | Satellite bus | 3, bottom-left |
| `x-ground-station-network` | Ground station network | 1, top-left |
| `x-datacenter-rack` | Datacenter rack | 1, top-left |

The retired final-charge prototype no longer needs artwork; the AGI Model uses
the generated endgame icon.

Post-review playtest replacements:

- `x-ev-reservation` now uses a deliberately minimal two-sheet paperwork icon:
  one folded corner, one binder clip, and one large red approval check. The car,
  circuitry, straps, and deep document stack were removed because they became
  visual noise at belt and inventory scale.
- The custom steel `X` inside a gear ring with one orange furnace center is the
  FactoryX Progress shortcut icon and compact module identity. FactoryX no
  longer creates a separate crafting-menu tab.

### Entity Artwork Alignment Rule

- Placeable entity art must make its collision footprint readable at normal
  gameplay zoom.
- Ground pads, slabs, roofs, and perimeter walls stay centered and aligned to
  the Factorio tile axes. Do not rotate a square or rectangular building into a
  diagonal concept-art composition.
- The visible base should fill roughly 85-100% of the sprite canvas after
  transparent padding. Keep only enough margin for antialiasing and legitimate
  vertical equipment overhang.
- All footprint corners should be visually inferable. Tall machinery may rise
  above the rear edge, but it must not obscure or falsely extend the ground
  boundary.
- Multi-tile arrays must tile to their selection box. Internal module borders
  must not create an apparent empty perimeter where adjacent entities actually
  touch.
- Icons may be derived from the aligned entity art so the inventory silhouette
  matches what the player places.

### Crafting Menu Integration

FactoryX products live beside the vanilla systems they extend:

- Prototype, Premium, and Mass-market EVs plus Robotaxi Fleets use the vanilla
  Logistics `transport` row.
- High-density Solar Panels and Megapacks use the vanilla Production `energy`
  row.
- Launch services, boosters, satellites, and ground stations use the vanilla
  Production `space-related` row.
- AI Tokens and planetary-grid outputs use the vanilla `science-pack` row.
- FactoryX infrastructure has a dedicated row in the vanilla Production tab.
- FactoryX components and capital/contracts have dedicated rows in the vanilla
  Intermediate Products tab.
- EV Reservations use the vanilla `raw-material` subgroup inside Intermediate
  Products so they are visible and searchable in item-filter selectors even
  though chargers create them through runtime demand rather than a craft recipe.

### Placeable Entities

| Prototype | Player Name | Current Base | Needs New Artwork? | Notes |
| --- | --- | --- | --- | --- |
| `x-sales-office` | Sales Office | Final footprint-aligned generated master | No | The square 3x3 showroom is empty while idle. During an active sale, a runtime overlay derived from the corresponding drivable vehicle sheet displays the Roadster, Premium EV, Mass-market EV, or Megatruck on the showroom pad. |
| `x-ev-charging-station` | EV Charging Station | Dedicated aligned 2x2, four-stall sprite | No | Square footprint-filling art and matching icon are wired. |
| `x-ev-charging-station-v2` | EV Charging Station V2 | Dedicated aligned 4x4, eight-stall sprite | No | Larger transformers and cyan high-power treatment distinguish V2. |
| `x-ev-charging-station-v3` | V3 Supercharger | Dedicated aligned 5x5, 12-stall sprite | No | Twelve visible charger pedestals and liquid-cooled edge equipment distinguish V3. |
| `x-ev-charging-station-v4` | V4 Supercharger | Dedicated aligned 6x6 solar-canopy sprite | No | Fifteen stalls are visible and five are represented beneath the canopy, matching the 20-stall logical capacity. |
| `x-gigafactory-building` | Gigafactory | Dedicated aligned 9x9 sprite and icon | No | V1 has footprint-aligned production gantries, cooling fans, moving body shells, and loading-bay chase lights while crafting. V2 uses a faster twin-gigacasting animation with stronger cyan process lighting. |
| `x-gigafactory-v2` | Gigafactory V2 | Dedicated aligned Gigacast-focused 9x9 sprite | No | Distinct dual-cell art now has faster gigacasting arms, process-core rings, cooling fans, shuttle motion, and loading-bay lights while crafting. |
| `x-terrestrial-datacenter` | Terrestrial Datacenter | Final footprint-aligned generated master | No | The 6x6 server block now fills its foundation and adds active rooftop cooling-fan animation. |
| `x-robotaxi-service-center` | Robotaxi Service Center | Dedicated aligned 8x8 fleet-depot sprite and icon | No | Solar canopy, fleet rows, transformers, and gold vehicle accents fill the footprint. |
| `x-orbital-compute-array` | Orbital Compute Array | Temporary transparent selected concept art | Partial | Distinct playtest art is wired into the mod; still needs final space-platform-compatible compute array art. |
| `x-planetary-grid-controller` | Planetary Energy Grid Controller | Dedicated aligned control-core sprite and icon | No | High-voltage buswork, transformers, and a contained energy core distinguish the final training structure. |

### Future Candidate Placeable Entities

These are not implemented yet, but they are likely candidates if the mod moves
beyond the MVP tech-and-recipe loop.

| Candidate | Purpose | Needs New Artwork? | Notes |
| --- | --- | --- | --- |
| Launch Site | Makes commercial launch services feel more physical than an item-only recipe. | Yes | Could be a rocket-silo-adjacent entity or a dedicated assembler category. |
| Booster Landing Pad | Supports reusable booster recovery or reuse mechanics. | Yes | Would make the reusable-launch flywheel more visual. |
| Ground Station | Converts the current Ground Station Network item into visible satellite infrastructure. | Yes | Could increase orbital compute output or satellite constellation capacity. |
| Satellite Constellation Controller | Tracks constellation scale and links launch products to compute bonuses. | Yes | Might be a radar/combinator-like entity rather than a normal assembler. |
| Market Exchange | Alternative or upgrade to Sales Office for late product sales. | Yes | Only worth adding if Sales Office recipes become too crowded. |
| Biter Diner | Mass-market hospitality side path and 80-stall V5-class charging destination. | Yes | Large diner-and-charging-campus art should make the restaurant, parking, and chargers readable within a square footprint. |
| Fictional Disruption Spawner | Optional event/enemy source if we add competition or disruption. | Yes | Not MVP. Avoid direct real-world political labels. |

### Items And Products

| Prototype | Player Name | Needs New Artwork? | Notes |
| --- | --- | --- | --- |
| `x-dollar` | Dollar | Maybe | Current coin icon works for MVP. Could use a branded capital token later. |
| `x-ev-reservation` | EV Reservation | No | Custom simplified approved-paperwork icon is wired and verified at 64 px. |
| `x-gigafactory-module` | Gigafactory Module | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-gigacast` | Gigacast | No | Dedicated one-piece vehicle casting and press-die icon is wired. |
| `x-ai-token` | AI token | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-planetary-grid-segment` | Planetary grid segment | No | Dedicated physical high-voltage grid-module icon is wired. |
| `x-agi-model` | AGI Model | Yes | Concrete output of the final training run and the victory trigger. |
| `x-battery-pack` | Battery pack | Maybe | Vanilla battery/accumulator layering is acceptable but could be custom. |
| `x-electric-drivetrain` | Electric drivetrain | Maybe | Vanilla electric engine layering is acceptable for MVP. |
| `x-prototype-roadster` | Prototype roadster | No | Red Blender model, derived icon, and packed 64-direction driving sheet are wired. |
| `x-premium-ev` | Premium EV | No | Black grand-tourer model, derived icon, and packed 64-direction driving sheet are wired. |
| `x-mass-market-ev` | Mass-market EV | No | White liftback model, derived icon, and packed 64-direction driving sheet are wired. |
| `x-cybertruck` | Megatruck | No | Silver faceted pickup model, derived icon, and packed 64-direction driving sheet are wired. |
| `x-high-density-solar-array` | High-density Solar Panel | Partial | Native 3x3 upgrade-compatible solar entity tiles four miniaturized vanilla panels edge-to-edge across the same footprint as one conventional panel. It retains the native 300 kW day/night curve without rotation or hidden support entities. Final premium artwork remains optional. |
| `x-megapack` | Megapack | No | Dedicated aligned 2x2 four-cabinet utility battery sprite and matching icon are wired. |
| `x-autonomy-computer` | Autonomy computer | Maybe | Current processor/module concept is readable. |
| `x-robotaxi-fleet` | Robotaxi fleet | No | Gold Robotaxi model, derived icon, and packed 64-direction driving sheet are wired. |
| `x-small-launch-service` | Small launch service | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-reusable-booster` | Reusable booster | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-reusable-launch-service` | Reusable launch service | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-satellite-bus` | Satellite bus | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-ground-station-network` | Ground station network | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |
| `x-datacenter-rack` | Datacenter rack | Partial | Temporary transparent selected playtest icon is wired; needs final UI-scale icon pass. |

### Recipes And Technologies

Recipes and technologies do not require separate artwork if their icons reuse
the output item, but major technologies may benefit from custom tech icons later:

- EV Production Line.
- EV Charging Network.
- Mass-market EV Production.
- Gigafactory Module.
- Gigafactory.
- Small Orbital Launch.
- Reusable Launch.
- Satellite Constellation.
- Terrestrial AI.
- Orbital Compute.
- Autonomous Logistics.
- Planetary Energy Grid.
- Achieving AGI.

Highest-priority custom tech icons:

1. Achieving AGI.
2. Planetary Energy Grid.
3. Orbital Compute.
4. EV Charging Network.
5. Gigafactory.

### Artwork Remaining For A Final-Quality Mod

The playable terrestrial set no longer has missing or confusing placeholder
art. The 2026-07-10 production pass added final Sales Office and Terrestrial
Datacenter masters, normalized custom icons, seven locally composed technology
icons, and bounded working animations. Remaining work is narrower:

- Technology-tree identity now uses clean subject-specific art plus one small
  lower-right steel `FX` maker's badge in gold and electric cyan. The older
  concentric-circle compositions are retired from the live prototypes. Avoid a
  red `X` or crossed-tool mark because it reads as unavailable or invalid in a
  technology tree.

- `BiterMotors.png` now supplies the square FactoryX brand artwork: a 256x256
  in-game Progress shortcut icon and a 144x144 packaged-mod thumbnail. The
  source artwork remains in Downloads and is not duplicated at full resolution
  inside the mod.

1. Playtest the five wired Blender vehicles for scale, collision alignment, and
   steering feel; make model-specific sprite-scale adjustments from screenshots.
2. Review normalized icons at actual 64 px and belt scale in the QA index; only
   regenerate individual icons that still fail after deterministic normalization.
3. Add Factorio-style shadows, ambient occlusion, damage states, remnants, and
   optional high-resolution variants to the major custom structures.
4. Finish the later space-art pass separately: launch products, launch site,
   orbital compute, satellites, and ground infrastructure should share one
   visual language distinct from the terrestrial Tesla-like industry.

## Future Plans

### Phase 0: Stabilize MVP

- Keep the current prototype set loading cleanly under Factorio 2.1 + Space Age.
- Keep the runtime loop bounded and easy to reason about.
- Add tests for any new runtime mechanics.
- Keep the install script and validation workflow documented.

### Phase 0.5: Playtest-Driven Progression Pass

- Rename or reframe `Premium EV Program` as `EV Production Line` so the next
  step after first Dollars is obvious. Implemented for the player-facing locale;
  its prototype id is `x-premium-ev-program`.
- Add an explicit post-first-sale hint: spend Dollars on EV production tooling.
  Implemented as a first-Dollar force message.
- Make the first post-dollar tech consume Dollars, not only conventional science.
  Implemented on EV Production Line research.
- Add the 9x9 Gigafactory as the physical scale-up after a 100-Premium-EV pilot
  run in ordinary assemblers. It consumes ten Gigafactory Modules plus
  Substations and then scales Premium EV assembly. Implemented.
- Add Gigacast and Gigafactory V2 as the mass-market production gate. V2
  consumes V1, draws 30 MW, runs at 2x speed, has 150% built-in productivity,
  and fast-replaces V1. Implemented.
- Unlock Gigafactory Modules after both the 100-Premium-EV pilot milestone and
  Energy Products, using the production-cell recipe `Dollars + Assembling
  Machine 2s + Labs + Refined Concrete`. Implemented.
- Change mass-market sales from a five-car batch to the literal contract
  `1 Mass-Market EV + 1 EV Reservation -> 1 Dollar`. Implemented.
- Ensure every Sales Office recipe has a sensible sale time:
  - `Sell hopes and dreams`: 60 seconds.
  - `Sell premium product`: 30 seconds for 1 Dollar.
  - `Sell mass-market EV`: 5 seconds and gated by EV Reservations.
  - `Sell robotaxis`: three Robotaxi items in 3 seconds for 1 Dollar.
  - Launch and grid sales: slow, high-value contracts.
- Add status panels or command output for each new infrastructure loop before
  adding more invisible mechanics. Implemented for global progression, Sales
  Offices, EV Charging Stations, and both Gigafactory tiers; future placeable
  infrastructure should extend the same model.
- Roadmap: make the Prototype Roadster conversion explicitly electric. By the
  FactoryX entry point, lubricant and Electric Engine Units are normally
  available, so use `Car + Electric Engine Units + Batteries + Advanced
  Circuits`. The Car remains the physical chassis donor; later purpose-built
  EVs continue consuming the higher-level Electric Drivetrain intermediate.
  Audit prerequisite ordering so Electric Engine Units are always craftable
  before the Roadster recipe becomes available.

### Phase 1: Art Pass

- Replace copied machine graphics for the existing placeable entities and the
  new Gigafactory.
- Replace the most important product icons: EVs, launch services, AI token,
  Planetary Grid Segment, Gigafactory Module, EV Reservation.
- Keep silhouettes readable in Factorio's UI and on belts.
- Avoid real company marks or real-world logos. The mod should be inspired by
  the industrial arc, not use protected branding.

### Phase 2: Better Charging Coverage

- Move beyond simple active-stall count.
- Implemented: multiple grid-connected chargers can contribute separate stalls
  to the same settlement. Each additional V1 stall supports 12 more EV owners,
  so a pre-V2 player can resolve an underserved market by building more V1
  infrastructure. The Sales Office does not hard-stop at this capacity: it can
  oversell to remaining mobile buyers, visibly creating customer-service risk.
  Assignment favors settlements with the least existing capacity. Extra stalls
  begin drawing power only as sold EV ownership grows beyond earlier stalls.
- Possible mechanics:
  - Count unique chunks covered by charging stations.
  - Require stations to be powered.
  - Scale reservations by connected electric network capacity.
  - Reduce value from overlapping stations.
  - Assign nearby peaceful biter settlements to charger stalls as real customer
    demand.
  - Require Sales Offices to be within a market radius of biter settlements for
    mass-market sale bonuses.
  - Add a dashboard or command report that shows coverage, demand, and sales
    bottlenecks.

### Phase 2.4: Biter Diner Side Path

Add a deliberately playful terrestrial expansion during the Mass-market EV
stage. It is powerful, but optional and expensive enough that ordinary V2-V4
charging remains the straightforward path.

- `Biter Hospitality` becomes researchable after Mass-market EV Production. A
  provisional cost is 1,000 cycles using red, green, blue, purple, and yellow
  science. It unlocks both the `Biter Diner` and a FactoryX-retuned version of
  the existing Space Age `fish-breeding` recipe.
- The Biter Diner is a 12x12, stack-size-1 specialty V5-class charger with 80
  public stalls and a 224-tile customer radius. Each stall supports 50 EV
  owners, matching V4 throughput, for 4,000 supported owners at one campus.
- Each occupied stall draws 500 kW, for 40 MW peak site demand. Empty stalls do
  not draw their full charging load. Quality and the existing Long-range
  Battery and Supercharging research apply through the normal charger rules.
- Diner stalls produce EV Reservations at the normal one-per-active-stall rate.
  The economic bonus is separate: a consumer EV sold to a buyer whose home
  settlement is assigned to a Diner yields three times that sale recipe's base
  Dollar profit. This applies once, even with overlapping Diners. It does not
  multiply Robotaxi Service Center trip income.
- Bonus Dollars still emerge physically from the Sales Office. Implementation
  must reserve enough output space for the full 3x payout before starting the
  sale, so the bonus cannot disappear when output is nearly full.
- Proposed four-ingredient recipe: `1 V3 Supercharger + 100 Raw fish + 500
  Refined concrete + 1,000 Dollars -> 1 Biter Diner`. The inherited V3 contains
  the electrical equipment; fish creates the exploration/automation sidequest;
  concrete and capital reflect the large destination campus.
- Retune `fish-breeding` for the established no-Gleba terrestrial game:
  `2 Raw fish + 20 Wood + 100 Water -> 3 Raw fish` in a Chemical Plant, 30
  seconds, Nauvis only, with no productivity or quality. This preserves the
  vanilla recipe and chemical-plant affordance while removing nutrients and
  agricultural science. A player can catch the initial fish manually, then
  scale hatcheries to supply one or more Diners.
- Do not use Spoilage as the initial breeding gate. Raw fish take a little over
  two hours to spoil in Space Age, so requiring the player to wait for the first
  Spoilage would be obscure and inert. Spoilage can remain a future optional
  efficiency recipe if playtesting shows that the fish loop needs another sink.
- Assignment should prefer normal spare charging before overloading a Diner or
  vice versa according to the existing owners-per-capacity balancing. The
  settlement inspector must identify `Biter Diner`, show its 3x hospitality
  bonus, and report local capacity and underserved owners normally.
- Required art: a footprint-aligned square diner campus with a clearly visible
  restaurant core, parking/drive-through circulation, and charger banks. Avoid
  angled presentation art; all 12x12 boundaries should read at game zoom.

Balance questions for playtesting, not blockers for first implementation:

- Whether 1,000 Dollars sufficiently offsets the jump to 4,000-owner capacity.
- Whether the Diner should use 40 MW or add a small always-on restaurant load.
- Whether 100 fish creates a satisfying ten-to-twenty-minute hatchery sidequest
  once several Chemical Plants are running.

### Phase 2.5: Biter Customers

- Create a `factoryx-customers` force on init and configuration change.
- Keep normal player/enemy hostility enabled.
- Convert Sales Office-covered spawners, biters, and spitters with reachable
  powered charging service into peaceful customer entities while leaving worms
  hostile.
- Count customer spawners near powered EV Charging Stations as covered biter
  settlements.
- Generate EV Reservations from active charger stalls rather than from raw
  charger count alone.
- Add `/factoryx-market` or extend `/factoryx-coverage` to report:
  - Powered chargers.
  - Covered biter settlements.
  - Active charging stalls.
  - Active Sales Offices.
  - Reservations generated per interval.
- V1 scripted growth is implemented: served stalls accumulate adoption and add
  bounded customer spawners plus hostile worms when spare capacity exists.
- Test against saves with biters disabled, peaceful mode, normal enemies, and
  sandbox-created enemy spawners.

### Phase 2.6: Physical Customer Charging Commutes

Implemented V1:

- Only customers who own sold EVs need to charge. Unsold `$` buyers continue
  wandering near their home settlement.
- A customer is not permanently bound to its settlement's current charger.
  When charging is due, choose the nearest charger on the same surface with an
  available powered customer stall. This allows customers to float between
  charger sites as the player expands or power conditions change.
- Customers physically walk to a non-colliding staging position around the
  selected charger and wait there for a charging interval. After charging,
  each customer walks back to a dispersed non-colliding point 8-20 tiles from
  its registered home settlement, then resumes local wandering there. Return
  trips do not consume the capped moving-or-charging commute slots.
- Charging duration scales inversely with available power. A fully powered
  stall charges at its tier rate; a brownout lengthens the wait approximately
  by `1 / power_fraction`. Zero useful power pauses charging without instantly
  making the customer hostile.
- Long-range Battery research increases time between charging visits.
  Supercharging Power Electronics reduces the powered charging duration while
  increasing the stall's grid draw.
- Uses event-driven `go_to_location` and `on_ai_command_completed` transitions.
  The one-second scheduler starts at most eight new trips and never permits more
  than 512 moving or charging owners at once; it does not pre-request paths.
- Blocked routes return the owner to local wandering and retry with exponential
  delays from 30 seconds through five minutes.
- Settlement-level powered capacity remains authoritative in V1. Physical
  commuters visualize service and can raise a local route-blocked alert, but a
  pathfinding failure alone does not invalidate an otherwise healthy market.
- Fully powered charging takes about 30 seconds. The sampled station power
  fraction advances that clock, so low power extends the visit and zero power
  pauses it. Supercharging research accelerates the visit; Long-range Battery
  research adds 25% per level to the interval between visits.
- Initial class intervals are deliberately exaggerated and readable: Roadster
  3 minutes, Mass-market EV 5, Premium EV 6, Robotaxi 7, and Megatruck 8.
- The charger inspector reports approaching and charging owners. FactoryX
  Progress reports network-wide commute activity and completed visits.
- Still benchmark 128, 256, and 512 simultaneous commuters against the roughly
  12,000 customer units in the large save before increasing the production cap.

### Phase 2.7: Customer Road Rage

Roadmap idea for player-driven EV collisions:

- Hitting a friendly mobile biter or spitter with a player-driven FactoryX EV
  immediately makes that individual customer angry at the driver.
- A small number of customers within roughly 10-15 tiles may join the response,
  but one accidental collision must never turn an entire settlement or the
  global customer force hostile.
- Anger lasts roughly 30-60 seconds and clears when the player escapes without
  causing more damage. Restored customers have a deliberately short memory.
- Killing a customer removes that customer's vehicle ownership and associated
  charging demand, consistent with the existing ownership lifecycle.
- Vehicle character should affect consequences: the fragile Roadster takes
  meaningful collision damage, while the Megatruck can absorb impacts but
  provokes a larger nearby response.
- Abstract Robotaxi operations do not trigger road rage; only a vehicle under a
  player's direct control can cause it.
- Implement with a bounded angry-customer registry and expiration scheduler,
  not force-wide diplomacy changes or recurring scans of all mobile customers.

Implemented performance architecture:

- Stations, Sales Offices, and Robotaxi Service Centers are maintained in
  lifecycle registries. Recurring handlers no longer search every surface for
  these entities; configuration changes rebuild the registries once.
- Each force shares one immutable customer-service snapshot per simulation
  tick. Growth, stall utilization, reservation generation, commute dispatch,
  alerts, and inspectors reuse it instead of reconstructing the market several
  times during the same update.
- New mobile customers enter a settlement-specific available-buyer queue from
  `on_entity_spawned`. Sales Offices pop and lazily validate buyers instead of
  scanning every mobile customer for every contract.
- Commute dispatch uses a bounded 256-owner round-robin due queue and a separate
  active set capped at 512. Active station counts inspect only active commutes;
  the scheduler no longer walks every vehicle owner each second.
- Robotaxi customer allocation uses per-center spatial queries, chooses the
  nearest eligible center for overlaps, and caches the network result for five
  seconds. Inspectors and the remote status API consume the same allocation.
- Entity inspectors and FactoryX Progress refresh expensive telemetry every
  five seconds while selection/open events still render immediately.
- Datacenter brownout checks use a rotating queue of at most 32 compute machines
  per tick, preserving sub-second response while bounding late-game work.
- The engine smoke exposes performance counters and enforces call-count budgets
  for market snapshots and Robotaxi allocation. It also fails explicitly when
  Factorio logs a non-recoverable mod error, even if the binary exits with zero.

#### July 2026 customer scale benchmark

`scripts/benchmark-factoryx-scale.sh` creates disposable saves with registered
customer owners and compares 0, 128, 256, and 512 continuously commanded units.
It never touches the active playtest save.

Measured 20,000-unit results over 3,600 ticks:

| Registered owners | Commanded movers | Average update | Maximum update |
| --- | ---: | ---: | ---: |
| No | 0 | 21.141 ms | 64.257 ms |
| Yes | 0 | 22.507 ms | 98.743 ms |
| Yes | 128 | 23.049 ms | 108.628 ms |
| Yes | 256 | 22.333 ms | 60.943 ms |
| Yes | 512 | 23.497 ms | 68.265 ms |

The single-run movement values contain substantial simulation jitter, so they
should not be interpreted as a monotonic curve. A separate 5,000-unit run
verified that the commands were real: 512 requested movers produced 493 valid
movers, 476 units that changed position, and 11,615 completed movement commands.
Its average update times remained in the 3.34-4.20 ms range across all movement
caps. The actionable conclusion is that up to 512 visible commutes are not the
primary problem; 20,000 independently simulated unit entities already exceed
the 16.67 ms budget for 60 UPS before scripted commuting.

Recommended population virtualization:

- Target at most roughly 5,000 physical mobile customers map-wide. Keep the
  exact cap configurable until real playtest data confirms the comfortable
  margin alongside the player's factory.
- Store additional settlement population as integer counts by settlement and
  vehicle class. Sales, charging demand, reservations, Robotaxi coverage, and
  customer mood should operate on those aggregate counts.
- Retain a bounded pool of visible representatives per settlement. A sale may
  recolor/reclassify one representative, while the authoritative ownership
  count remains aggregate.
- Physical commutes become representative animation: schedule a sample of
  visible owners, capped at 128 by default and 512 maximum, without requiring
  every abstract owner to pathfind.
- Once a settlement reaches its visible-unit allowance, stop its physical
  spawner and advance virtual population through the existing growth clock.
  This avoids paying to spawn and immediately destroy excess units.
- Robotaxi Service Centers should consume aggregate nearby population from a
  settlement index rather than querying mobile units. This is both faster and
  a better model of fleet service coverage.

### Phase 2.7: Robotaxi Service Center

Implemented V1 replaces direct Robotaxi sales with recurring fleet-service
income:

- Add a large `Robotaxi Service Center` with a broad service coverage area.
- A Robotaxi Fleet item has a stack size of 5. The Service Center has 40
  dedicated fleet-inventory slots, so one fully stocked center holds 200
  Robotaxis.
- Each allocated Robotaxi can serve five nearby biter customers. A fully stocked
  and fully utilized center therefore serves at most 1,000 customers:
  `40 slots * 5 Robotaxis * 5 customers`.
- Inventory alone does not produce revenue. Runtime allocation assigns stored
  Robotaxis to eligible biter customers inside the Service Center coverage area.
  Revenue is based on the allocated fleet, capped by both available Robotaxis
  and covered customers.
- The center runs an explicit `Operate Robotaxis` recipe. It produces recurring
  Dollars while very slowly consuming Robotaxi items as fleet attrition and
  replacement demand. The recipe must not burn one Robotaxi every cycle; use a
  long-lived runtime reserve or fractional attrition counter so service income
  can tick frequently while vehicle replacement remains slow.
- Premium Audio Systems increases Robotaxi revenue because customers take longer
  rides. It does not increase the number of customers one Robotaxi can cover.
- The center includes V4 Supercharger-class fleet charging. Its charging power
  and available grid power constrain the proportion of the allocated fleet that
  can operate. Brownouts reduce utilization and revenue proportionally instead
  of immediately making customers hostile.
- The built-in charger is fleet infrastructure, not an additional public
  customer charger. It does not print EV Reservations or add public charging
  stalls to nearby settlements.
- The entity inspector must show stored Robotaxis, allocated Robotaxis, covered
  customers, current utilization, charging power satisfaction, Dollar rate, and
  estimated vehicle attrition rate.
- Retire or disable the current `Sell robotaxi fleet` Sales Office recipe once
  the Service Center is implemented. Implemented: the legacy recipe remains an
  internal compatibility prototype but is disabled in gameplay.
- V1 balance is one Dollar per 100 allocated Robotaxi-minutes at full power and
  one retired vehicle per 60 operating Robotaxi-hours. Premium Audio adds 5%
  revenue per research level.
- V1 uses a 41-slot logistics container: slots 1-40 are filtered to Robotaxis
  and slot 41 to Dollars. A colocated invisible operating machine runs the
  `Operate Robotaxis` recipe and provides the real 10 MW grid load.

Robotaxi Service Center hardening:

- Mobile customers inside overlapping service radii are assigned to exactly one
  nearest stocked center. They cannot generate duplicate revenue at multiple
  centers, while excess demand remains visible as `served / covered` in each
  inspector.
- A full Dollar output pauses trip revenue and vehicle attrition together.
  Clearing the output resumes service; hidden fractional revenue cannot grow
  into a large deferred payout while the center is blocked.
- The hidden 10 MW operating machine is adopted by position after reload or
  state repair. Duplicate colocated helpers are removed instead of stacking
  invisible power demand.
- A center with no fleet does not claim customers from another stocked center.
  Allocation is deterministic by distance and then entity unit number.
- Runtime processing remains once per second. Customer units are scanned once
  per surface for the whole RSC network rather than once per center.

### Phase 2.8: Terrestrial AI Hyperscaler And AI Haters

Future terrestrial escalation before the launch/orbital-compute buildout:

- Add a very large `Terrestrial AI Hyperscaler`, at least a 12x12 footprint,
  drawing **100 GW continuously**. This is intentionally a speculative
  cutting-edge-scale AI campus, not an average present-day hyperscale building.
- Correct capital conversion: a mature roughly **US$100 billion** campus costs
  **10 million in-game Dollar items**, because one in-game Dollar represents
  about US$10,000. The first three campuses are deliberately cheaper prototypes;
  the fourth campus reaches the full 10-million-Dollar cost. The phrase
  "$10 million game dollars" means 10 million physical Dollar items, not US$10
  million represented by 1,000 items.
- A direct assembler recipe cannot practically hold 10 million Dollars in one
  ingredient slot at the current 100,000 stack size. Build it through a large
  `Hyperscaler Construction Site` with a deep filtered capital inventory and a
  visible construction contract. Dollars must arrive physically by train,
  belt, or bots; do not collapse this cost into an abstract research counter.
- The construction contract also consumes one Terrestrial Datacenter,
  Datacenter Racks, and Substations. Exact hardware quantities can increase by
  tier, but capital is the primary scaling pressure.
- Give the Hyperscaler a dedicated operating recipe rather than silently
  speeding up the ordinary Datacenter. Its token throughput should be enormous,
  but its operating Dollar burn and 100 GW load should make repeated terrestrial
  scaling progressively unattractive compared with orbital compute.
- Gate it behind all six Terrestrial AI Efficiency levels or a dedicated
  `Hyperscale Terrestrial AI` technology after Autonomous Logistics. It should
  be optional brute-force terrestrial scaling, not required for space.

Progressively worsening construction economics:

- Track **lifetime completed Hyperscalers** per force. Do not use currently
  placed count, because mining buildings must not lower future costs.
- Author a sequence of construction-contract recipes that all produce the same
  Hyperscaler entity. Runtime enables the next contract and disables the old
  one as soon as lifetime production reaches `1, 2, 3, 4, 8, 16, 32...`.
- The active recipe must change on completed production, not placement, which
  prevents players from stockpiling many cheap buildings before crossing a
  threshold.
- Initial capital curve for playtesting:

  | Lifetime campuses before craft | Active contract | Dollars for next campus | Approximate real capital |
  | ---: | --- | ---: | ---: |
  | 0 | Hyperscaler Prototype I | 1,000,000 | US$10B |
  | 1 | Hyperscaler Prototype II | 2,500,000 | US$25B |
  | 2 | Hyperscaler Prototype III | 5,000,000 | US$50B |
  | 3 | Hyperscaler I | 10,000,000 | US$100B |
  | 4-7 | Hyperscaler II | 20,000,000 | US$200B |
  | 8-15 | Hyperscaler III | 40,000,000 | US$400B |
  | 16-31 | Hyperscaler IV | 80,000,000 | US$800B |
  | 32+ | Continue geometric tiers | 2x per tier | intentionally prohibitive |

- Show lifetime count, current contract, next doubling threshold, and next
  capital cost in the construction-site inspector and FactoryX Progress panel.
- This rising terrestrial marginal cost is the explicit economic pressure to
  move AI-token growth into space. Orbital compute should have difficult launch
  logistics but a flatter marginal-cost curve.
- The 100 GW Hyperscaler concept now sits below the implemented 1 TW final
  Controller load, preserving the intended late-game escalation.

AI-datacenter opposition dynamic:

- Individual mobile biter customers can become `AI Data Center Haters` when
  they wander into an opposition radius around either a Terrestrial Datacenter
  or Hyperscaler. The Hyperscaler has a much larger radius and higher conversion
  chance.
- Do not change an entire settlement or the global customer force. Convert only
  the selected unit to a dedicated hostile `factoryx-ai-haters` force, replace
  its customer/vehicle marker with a small red datacenter-protest marker, and
  command it to attack the specific Datacenter that triggered it. Player
  defenses can then target it normally.
- Hatred is permanent for that unit. It is distinct from temporary charging
  dissatisfaction, which still has a short memory and can recover when charging
  service returns.
- Give newly placed centers a five-minute commissioning grace period. After
  that, perform a bounded check every 10 seconds, sample at most 32 eligible
  nearby mobile customers per center, and make one probability roll per sampled
  unit. Never scan or command every nearby biter every tick.
- Starting tuning target per sampled visit: 0.25% around an ordinary 8 MW
  Datacenter and 1% around a 100 GW Hyperscaler. Add a per-unit cooldown of five
  minutes so a biter cannot roll repeatedly while lingering at the boundary.
- Pollution and insufficient charging could later increase the chance, but V1
  should use a simple fixed probability so players can understand and balance
  the risk.
- Haters should path to and attack only the triggering Datacenter. If the target
  is destroyed, invalid, or unreachable after bounded retries, let them attack
  nearby player infrastructure using ordinary enemy behavior rather than
  running expensive repeated path requests.
- The design creates a meaningful siting decision: Datacenters near dense
  customer markets are easy to supply but generate opposition; remote power and
  compute campuses require long transmission and logistics but encounter fewer
  potential attackers.
- Before implementation, benchmark 1, 4, and 10 centers against the 12,000-unit
  customer save, measuring update time, path requests, active hater count, and
  turret combat behavior. Cap simultaneous scripted attackers if needed.

### Phase 3: SpaceX-Style Launch Flywheel

- Add a clearer small launch -> reusable booster -> reusable launch progression.
- Make every physical launch depend on a sustained, multi-pump water-deluge
  system. Start playtesting at four offshore pumps of flow for 60 seconds per
  attempt, consume water on failures, and expose flow/readiness in the Launch
  Pad UI.
- Make launch-vehicle quality represent reliability. The early expendable
  vehicle requires rare quality to succeed; normal and uncommon attempts launch
  and fail. Later generations progressively reduce failure risk, while mature
  reusable quality primarily improves booster recovery and economics.
- Add a Rocket Factory that accepts quality modules and launch recipes that
  allow quality but explicitly disallow productivity.
- Record force-wide attempts, failures, and successful launches. Only successful
  launches unlock the next generation and orbital infrastructure.
- Consider launch-site or landing-pad entities if the vanilla rocket silo loop
  is not expressive enough.
- Add a "reuse" mechanic that makes reusable launch services much more
  profitable but requires booster production and/or recovery infrastructure.
- Consider launch cadence as a market mechanic: more launches unlock stronger
  satellite and orbital compute throughput.

### Phase 4: Satellite And Ground Network

- Make satellite buses and ground station networks do more than act as recipe
  ingredients.
- Possible mechanics:
  - Ground stations increase orbital compute efficiency.
  - Satellite constellations unlock higher orbital AI token recipes.
  - Space-platform compute needs satellite buses as ongoing maintenance or
    scaling input.

### Phase 5: Orbital AI Economy

- Make land AI useful but insufficient.
- Make space AI dramatically more scalable but logistically demanding.
- Require large return flows of AI tokens from platforms to Nauvis or another
  core planet.
- Tune Planetary Grid Segments so they feel like a late-game megabase
  throughput challenge.

### Phase 6: Achieving AGI Victory

- Add a force-wide, all-surface cumulative AI Token production counter.
- Show `current / 1,000,000,000` prominently in FactoryX Progress, with
  terrestrial and orbital contributions broken out beneath it.
- Unlock the AGI Training Run automatically at one billion cumulative Tokens.
  The unlock must not require one billion Tokens to remain in storage.
- Keep the Planetary Energy Grid Controller as the explicit final structure,
  with AGI training as its final operation.
- Initial final-run balance target:
  - 100 million physical AI Tokens.
  - 10 million Dollars.
  - Planetary Grid Segments and Megapacks representing space communications,
    storage, and grid hardware.
  - Roughly 1 TW sustained for 60 connected gameplay minutes.
- Brownouts pause or proportionally slow the run. Mining the controller must
  preserve neither ingredients nor progress unless normal Factorio mechanics
  explicitly return them.
- Completion creates an `AGI Model`, triggers Factorio's victory state, records
  completion time and lifetime Token totals, and permits continued play.
- Rebalance orbital compute by orders of magnitude so a well-developed platform
  fleet can reach one billion in a long but credible endgame. Terrestrial AI
  remains useful for early unlocks but is intentionally impractical as the sole
  AGI source.

### Phase 7: Events, Competition, Or Enemies

- Custom hostile enemies are not in the MVP.
- The preferred direction is now biter customers, not real-world political
  enemies.
- FactoryX changes local enemy behavior around Sales Offices: covered biters are
  converted into the peaceful `factoryx-customers` force, while normal biters
  remain hostile elsewhere.
- Possible future mechanics:
  - Sales Office-covered peaceful biter customer settlements create EV demand.
  - EV Charging Stations near settlements increase adoption.
  - Recent EV sales plus charging coverage allow scripted settlement growth.
  - Later, some fictional competitor or market event could create timed
    pressure, but the core joke should stay "sell EVs to biters."

### Roadmap Idea: Quality Dollar Denominations

- Explore using item quality as deterministic currency denominations:
  Normal = 1 Dollar, Uncommon = 10, Rare = 100, Epic = 1,000, and Legendary =
  10,000. Since one game Dollar represents roughly US$10,000 of profit, one
  Legendary Dollar would represent roughly US$100 million.
- Sales should continue producing Normal Dollars. Quality modules must not
  randomly create more valuable money.
- Add a physical Treasury or Capital Consolidator that converts ten Dollars of
  one denomination into one Dollar of the next quality. Support the reverse
  recipe so players can make change for smaller capital inputs.
- Disable quality effects on sales and currency-conversion recipes. The value
  increase comes only from explicit consolidation, not probabilistic crafting.
- Use denominations to make Hyperscalers, launch infrastructure, and other
  multi-million-Dollar projects logistically practical without abandoning the
  physical capital economy.
- Evaluate belt clogging, quality-aware filters, logistics requests, circuit
  signals, recipe ingredient quality, and player discoverability before
  implementation. Mixed-quality currency should create useful denomination
  logistics, not accidental deadlocks.

## Open Design Questions
- Should Dollars be allowed as lab science forever, or should late capital be
  spent mostly through recipes and structures?
- Should the Sales Office have recipe-specific sale rates that are dynamically
  affected by charging coverage, instead of consuming EV Reservations?
- Should orbital AI tokens be physically dropped by cargo pods, or is platform
  logistics enough?
- Should Planetary Grid Segments require real electric-network measurements,
  or is the recipe-based controller enough for MVP?
- Should the AGI Training Run use a recipe-driven 1 TW sink, or should it
  measure actual electric-network generation and require sustained planetary
  supply more directly?
- Should biter settlement demand use existing EV Reservations, or should a
  later version add a more explicit biter-market item?
- Should charger-driven biter growth directly create spawners, or use
  `build_enemy_base` so actual biter settlers walk to the new location?

## Current Validation Expectations

## Infinite Solar Scaling

- `High-density Solar Productivity` is available after Energy Products. Every
  level adds 10% native recipe productivity to FactoryX High-density Solar
  Arrays without affecting vanilla Solar Panels or increasing the array's 300
  kW peak output.
- `Megapack Productivity` is a parallel choice after Energy Products. Every
  level adds 10% native recipe productivity to FactoryX Megapacks.
- Both consume red, green, blue, purple, and yellow science plus Dollars. Costs
  rise by 1.5x per level, starting at 750 cycles for either track.
- Factorio caps recipe productivity at 300%. These upgrades make multi-gigawatt
  terrestrial fields cheaper to mass-produce but do not make one small field
  power a 100 GW Hyperscaler.
- Future generation-density work should use finite higher-output solar hardware
  tiers. Do not attach scripted hidden generators to every panel; that scales
  runtime work with entity count and would make large solar fields expensive to
  simulate.

## Terrestrial Interface Cleanup

- FactoryX Progress includes a spoiler-aware `Terrestrial industry` section.
  It reports Industrial Supply Chain research, built Big Mining Drills, built
  Foundries, and lifetime calcite mined. Wrecked EV and Vehicle Recycling rows
  remain absent until the first wreck reveals that branch.
- The progress body is scrollable with a bounded height so the industrial
  section does not push later market, infrastructure, and improvement metrics
  off-screen.
- The FactoryX Progress panel uses explicit terrestrial labels rather than
  mixing the terrestrial economy into generic infrastructure counters.
- AI output distinguishes Factorio's item production statistic from the
  FactoryX milestone tracker. The latter displays current progress toward the
  next Terrestrial AI Efficiency unlock instead of a second unexplained total.
- High-density Solar Productivity and Megapack Productivity levels are visible
  beside the EV continuous-improvement tracks.
- Robotaxi Service Centers are shown with the rest of terrestrial
  infrastructure as well as in throughput, making an absent center easy to
  distinguish from an idle or understocked one.
- Existing contextual inspectors remain the primary troubleshooting surface:
  Sales Offices, both Gigafactories, Terrestrial Datacenters, charging stations,
  customer settlements, and Robotaxi Service Centers report their immediate
  blocked or running state and the next concrete action.

## Drivable EV Roles

The five EVs deliberately exaggerate different real-world product roles. Motor
power, mass, tire friction, steering, braking, durability, cargo, and physical
battery equipment all differ; these are gameplay vehicles, not cosmetic car
items.

| Vehicle | Driving role | Batteries | Health | Cargo | Character |
| --- | --- | ---: | ---: | ---: | --- |
| Prototype Roadster | Sprint car | 1 | 240 | 20 | Fastest response and sharpest steering; shortest EV range and severe impact vulnerability |
| Premium EV | Grand tourer | 2 | 550 | 40 | Fast, composed, strong braking, and moderate range |
| Mass-market EV | All-rounder | 1 | 500 | 50 | Predictable handling with limited but practical range |
| Megatruck | Electric tank | 4 | 1,400 | 100 | Very fast once moving, longest range, heavy steering, and extreme impact resistance |
| Robotaxi | Long-duty fleet car | 2 | 650 | 30 | Efficient, stable, excellent braking, and tuned for sustained duty |

Quality adds one battery every two quality levels. The Megatruck uses a large
equipment grid so its four-battery base capacity and quality bonuses are not
silently truncated. Long-range Battery research still improves the energy used
per drive-charge unit across every model.

For meaningful mod changes, run:

```sh
python3 -m unittest tests.test_factoryx_mod
scripts/validate-factoryx-mod.sh
```

Validate prototypes with the local Factorio binary in an isolated temp config
and mod directory. The current validated binary is Factorio 2.1.9 with Space
Age enabled:

```sh
"/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio" \
  --config "$tmp/config.ini" \
  --mod-directory "$tmp/mods" \
  --dump-data
```

The isolated `mod-list.json` should enable only `base`, `space-age`, and
`factoryx` unless a temporary smoke-test helper mod is being used.

Current validation state, 2026-07-10:

- `python3 -m unittest tests.test_factoryx_mod` passes: 48 tests.
- `scripts/validate-factoryx-mod.sh` passes.
- `scripts/validate-factoryx-gui.sh <save.zip>` passes against a disposable copy
  of `FactoryX-Start5.zip`, creating the progress, Sales Office, and Gigafactory
  panels and verifying that every researched recipe plus the runtime-unlocked
  Prototype Roadster recipe is available without modifying the source save.
- The same GUI check passes against the latest playtest autosave and verifies
  that 40 lifetime Dollars in Factorio's production statistics render as `40`
  in the FactoryX Progress panel.
- The engine smoke test verifies a mixed V1/V2 network: 12 total stalls, one
  sold EV demand, active 150 kW V2 sinks, no duplicated V1 allocation, and fleet-capped
  reservation generation. After one minute, the active charger contains one
  physical EV Reservation. Its pre-production snapshot verifies zero active
  stalls and zero reservations.
- Isolated `--dump-data` with Factorio 2.1.9 + Space Age loads
  `factoryx 0.1.0` successfully.
- The engine prototype check verifies that Prototype Roadster remains an
  `advanced-crafting` recipe and that Assembling Machine 2 supports that
  category.
- The engine prototype check verifies vanilla crafting-tab placement, confirms
  every authored FactoryX recipe has a technology or milestone owner, and
  confirms every recipe category has at least one compatible machine.
- The engine smoke test completes a real three-Robotaxi, 3-second sale with no
  EV Reservation, verifies 1 Dollar in the Sales Office output, and verifies
  that the sale enables Small Orbital Launch.
- The engine smoke test places a drivable Prototype Roadster beside a powered
  V2 charger, verifies one embedded battery equipment item, measures stored
  energy during the test window, and verifies battery energy is transformed
  into the hidden electric-drive fuel used by the car prototype.
- Unpowered charger alerts use `LuaPlayer.add_custom_alert`; Factorio 2.1 has no
  `defines.alert_type.no_power`. The copied-save GUI gate verifies the supported
  custom-alert signature and the shared charger-build handler.
- A disposable benchmark smoke save with a temporary helper mod ran 3780 updates
  and verified:
  - The Sales Office technology enabled EV Charging Stations and `Sell hopes
    and dreams`.
  - A nearby biter settlement was converted to the `factoryx-customers` force,
    while a far biter settlement remained `enemy`.
  - A covered biter customer charging site enabled Prototype Roadsters.
  - One active charging stall generated one EV Reservation in the charger's
    passive-provider output after one minute.
  - A tracked Planetary Energy Grid Controller exposed the AGI Training Run
    after one billion cumulative AI Tokens.
  - `game.finished` was true after an AGI Model appeared in its output.

For runtime script changes, benchmark a disposable save long enough for the
one-minute EV Reservation printer cycle:

```sh
"/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio" \
  --config "$tmp/config.ini" \
  --mod-directory "$tmp/mods" \
  --benchmark "$tmp/saves/x-smoke.zip" \
  --benchmark-ticks 3780 \
  --benchmark-runs 1
```
