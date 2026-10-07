# Changelog

## 0.1.1 - Alpha

This is the first Biter Motors alpha release candidate line after the private
development namespace migration.

- Restored Factorio 2.1.20 compatibility for EV, Cybertrain, and eSpider
  drive-charge fuel items; both engine dependencies now require 2.1.20.
- Hardened isolated validators and soak evidence against zero-exit Lua errors,
  stale archives, incomplete probes, paused game time, and truncated timings.
  This establishes a current engine baseline, not full campaign qualification.
- Separated physical and virtual purchase histories using bounded cohorts.
  Replacements preserve owner counts, cancellations release reservations, and
  virtual-only settlements survive population rebuilds and normal mod updates.
- Prevented Sales Offices from starting a new vehicle transaction before a
  buyer is reserved, without blocking the paperwork needed to start selling.
- Regenerated all 18 rewritten vanilla recycling recipes from their final
  terrestrial ingredients, eliminating removed-planet material returns.
- Preserved small damaged-pack batches for ten-pack, 90% cell recovery instead
  of allowing the automatic one-pack self-recycling fallback to consume them.
- Made Premium EV salvage conservative across its two battery recipes; only
  vehicles with fixed chemistry return advanced packs. Anonymous charger
  incidents no longer fabricate advanced battery materials.
- Added one body wreck on player-vehicle destruction, preserved salvage quality,
  reconciled physical salvage statistics, and stopped construction bots from
  carrying hidden EV drive-charge items into storage when mining a vehicle.
- Added an isolated native Recycler/salvage fixture with a real server-written
  checkpoint and separate-process reload; no live save changes are required.
- Restored stall-sized fair sharing for contested chargers while retaining bulk
  allocation for genuinely uncontested demand, including proportional brownouts.
- Unified settlement service health across rebuilds, refreshes, mood, alerts,
  inspectors, and growth. Adequate Bitertaxi coverage remains an independent
  route; deficient neighbors do not contribute healthy expansion utilization.
- Made organic growth run once per healthy settlement, including taxi-only
  homes, and count each pending buyer only once across EV models and offices.
- Added isolated charging regressions for removal, brownouts, grace-period
  hostility, recovery, virtual-buyer balancing, and separate-process reload.
- Added direct compact Training Dataset output at grid-scale and hyperscale
  orbital tiers, preserving compute rates and Dollar costs. Each Dataset
  represents 50,000 computed Token equivalents and stacks to 1,000.
- Moved Dataset and Capital Allocation packaging into ordinary assemblers and
  Biterfactories; packaging cannot gain productivity or earn compute progress.
- Replaced AI cycle sampling with native recipe-completion accounting. Research
  bonuses preserve product quality, blocked bonuses count only on delivery,
  and machine removal cancels undelivered liabilities without losing earned work.
- Added isolated two-platform AI accounting, native milestone and inserter
  extraction tests with pending-bonus/in-progress-craft save/reload coverage.
- Shortened the AGI Training Run's base recipe and progress target from 60 to
  20 minutes, retaining 10 GW and all final inputs.
- Fixed final-controller speed at every quality and disabled module, beacon,
  surface, and local effects; training draws 10 GW with no idle drain.
- Replaced output-presence victory polling with earned native training
  completion. Inserting a Model cannot win; extraction, recipe changes, and
  removal after completion cannot erase victory. Continued play is supported.
- Separated final-controller power monitoring from orbital workloads. A
  brownout scraps progress, retains committed inputs, and retries after power
  recovery; a native red status explains the hold.
- Added an isolated full-duration finale fixture with real billion-equivalent
  computation, quality/beacon checks, integrated energy measurements, partial
  and total outages, native Model extraction, and midrun/failed-state/won reloads.
  Campaign qualification remains a release gate.
- Fixed sustained brownouts allowing ordinary AI batches to finish slowly.
  Any native low-power status now scraps active terrestrial/orbital training.
- Added native orbital cooling and power regressions: platform/force isolation,
  deterministic capacity allocation, core/radiator removal, blocked output,
  half-power reset, total outage, checkpoint/reload, and exact recovered output
  and earned-compute conservation.
- Qualified the final physical supply chain with two genuine platforms, native
  belts/inserters and cargo pods, landing-pad requests, logistic bots, real lab
  research, native controller construction and capital packaging, a full
  20-minute run, and persistent once-only victory after save/reload.
- Derived Progress research costs from native technology ingredients and normal
  orbital cycle time from the machine's actual crafting speed. Optional Foundry,
  Megatruck, charger placement, and Bitertaxi work no longer block orbital guidance.
- Described the Foundry unlock honestly as a deployment milestone, not proof of
  a connected, functioning industrial grid.
- Counted business profit from native Sales Office completions and actually
  delivered depot income. Recycled capital and other Dollar production stay
  separate, including through statistics clears and save/reload.
- Replaced stale economy constants with a hashed final-prototype/runtime capture,
  research Token costs, physical payload conservation, and three finite-market
  sensitivities. This does not change prices or claim a measured campaign duration.
- Repaired the development artwork index with stable review IDs, real PNG/frame
  dimensions, all five EVs, both compute/power tiers, and explicit inherited-art
  gaps. Static review is not native visual approval.
- Rebranded the player-facing campaign as Biter Motors.
- Added the terrestrial customer economy: Sales Offices, physical
  reservations, charging coverage, customer ownership, and Dollar profit.
- Added drivable Roadster, Premium EV, Mass-market EV, Megatruck, Bitertaxi,
  and Cybertrain vehicles with charging and bounded customer simulation.
- Added the eSpider: a native remote-controlled electric SpiderVehicle with
  four Tesla guns, factory-installed Battery MK3s and exoskeletons, charger
  support, 8 MW traction, and a low-speed limp-home reserve.
- Replaced module-badged clean battery recipe icons with dedicated refining,
  extraction, and dry-electrode process artwork.
- Grouped all four EV Charging Station tiers into one dedicated crafting-picker
  row in tier order.
- Replaced nine composed placeholder icons with dedicated Biter Motors artwork
  for advanced factories, energy products, components, vehicles, and orbital
  infrastructure.
- Added Biterfactory production, battery chemistry, recycling, High-density
  Solar Panels, Grid Batteries, and terrestrial AI compute.
- Added orbital AI infrastructure, physical AI Token return, and the AGI
  training-run victory path.
- Added bounded customer populations, timing-wheel scheduling, and scale
  benchmarks for large customer populations.
- Reworked charger allocation around event-invalidated power caches and a
  spatial station index, substantially reducing recurring late-save stutter.
- Made the Bitertaxi Depot's hidden 10 MW load connect anywhere a real power
  pole overlaps its 8x8 footprint, matching EV Charging Station behavior.
- Added a remote-view Bitertaxi service-coverage toggle and made powered,
  stocked depots independently convert and serve nearby settlements without a
  Sales Office.
- Added the fresh-start crash-landing narrative and recovered industrial kit.
- Restored Transport Belt Capacity, Battery MK3, Advanced Asteroid Processing,
  and Asteroid Productivity through reachable Biter Motors progression paths.
- Replaced the removed electromagnetic-science requirement in late Tesla
  weapon damage research with AI Tokens.

This release is alpha software. Balance, artwork, progression, performance,
and late-game details remain subject to change.
