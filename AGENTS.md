# Agent Instructions

This repository contains the Biter Motors Factorio mod, its design notes,
artwork sources, validation scripts, and tests. Treat it as a fresh-save game
overhaul with no backwards-compatibility obligation unless Luke explicitly
changes that policy.

## Working Method

- Inspect `ROADMAP.md`, the relevant Lua, and existing tests before changing
  gameplay.
- Prefer concrete Factorio mechanics and discoverable progression over abstract
  currencies or invisible state.
- Use the Official Factorio Wiki and local prototype data when mechanics or
  recipes are uncertain.
- Keep recurring runtime work bounded. Customer populations may become very
  large, so use registries, aggregate settlement state, timing wheels, and hard
  caps instead of recurring whole-surface scans or per-customer rendering.
- Register naturally spawned customers through lifecycle events and use bounded
  reconciliation for missed third-party events.
- Factorio can log a non-recoverable mod error while exiting with status zero.
  Engine validators must inspect logs for runtime errors.
- `on_nth_tick` can fire at tick zero. Completion probes must reject premature
  callbacks; benchmark update counts alone do not prove advancing game time.
  A paused or won world can still report all requested benchmark updates.
- Register one handler per event/cadence per mod; a second `on_nth_tick` handler
  for the same interval replaces the first rather than adding work.
- Fixture request sections must be ungrouped unless sharing is intentional;
  named logistic groups share filters across entities. Reserve future machine
  footprints and hold input inserters until placement, or inputs spill to ground.
- Recovery assertions must compare new products, output, and ledger deltas to
  the checkpoint, not accept an old output item as a recovered completion.
- Player-facing currencies and script-produced inventory items must use the
  `always-show` item flag and have prototype-dump coverage so they remain
  selectable in logistic requests and filter pickers while recipes are locked.
- Regenerate reverse recipes after rewriting vanilla ingredients, using the
  upstream Recycler generator. Test custom batch recovery with 1-9 items before
  ten; automatic self-recycling fallbacks can silently consume the partial batch.
- Shared product items do not retain ingredient provenance. Use conservative
  salvage, not research state or lifetime sales, to infer their battery chemistry.
- One reachable charger does not imply uncontested capacity. Preserve bounded,
  stall-sized sharing, and use the same settlement-health policy for mood,
  growth, alerts, and inspectors; adequate Bitertaxi service is an alternative.
- Count compute through native recipe-completion events with the event's recipe
  and product quality, not sampled current recipes or raw item statistics.
  Packaging is not new compute; undelivered scripted bonuses are not earned.
- Completion callbacks follow the final energy draw. A depleted callback-time
  buffer is not proof of an interrupted run; use the prior power-failure state.
- Setting native crafting progress to exact zero cancels its committed batch.
  Retained-input resets need a negligible positive sentinel and a native restart
  test with no replacement ingredients, including an outage checkpoint/reload.
- Electric-network statistics use input for consumption and output for generation.
  Do not reuse the item-production direction rule; preserve quality in probes.
- Prove space hardware/currency uplift through real rockets. Supplied platform
  entities prove neither launchability nor logistics cost. `data.raw` can omit
  auto-calculated item weights; capture `LuaItemPrototype.weight` and check mass,
  inventory slots and practical request minimums for every critical cargo item.
- Derive fixture inserter/loader placement from native machine bounds when
  footprints change; a completion ledger does not prove physical extraction.
- Native starter ascension and delivery can share a simulation tick. Validate
  cargo origin, destination, event order and conservation, not a fabricated delay.
- Cargo delivery clears `cargo_pod_destination` before its callback on 2.1.20.
  Capture the actual station in `on_cargo_pod_finished_descending`, then credit
  only `on_cargo_pod_delivered_cargo`. Arrival alone is not cargo delivery.
- Script-forced `set_recipe` can bypass native surface selection restrictions.
  Keep explicit canonical-surface/force guards on victory events; test those
  guards rather than assuming a fixture's incompatible machine cannot craft.
- Model both rocket and cargo-pod inventory limits. The validated 2.1.20 rocket
  has 20 slots but its ascent pod has 10; weights alone do not define capacity.
- Platform foundation must be connected and hole-free. Include the native hub
  in topology/export checks; a sparse footprint union can leave one tile unbuilt.
- Keep compute input belts Dollar-only and end them at the last pickup. Test
  finite-stock exhaustion: looping Datasets or dead-end belt stock can conceal
  a real logistics stall behind a healthy recipe-completion counter.
- Report full finite-drain and startup/midpoint rates separately. A long belt's
  cash buffer and uneven end-of-batch drain are not sustained compute throughput.
- Rehearse large final inputs with real belts and full-hand inserters, not Lua
  inventory transfers. Account for items that pass the selected pickup and for
  finite research/chest buffers; a lifetime output counter is not a loaded batch.
- Sample campaign stock and production from a disposable copy before balancing.
  Gross output is not spare capacity, and wallet growth is not gross profit.
  Do not count the same stocked intermediate and its ingredients twice.
- Machine-driven rehearsals are lower bounds, not human playtime forecasts.
  Budget explicit time for construction and troubleshooting; Luke's campaigns
  have taken longer than optimistic overlap-based predictions.
- Do not assume data-stage helpers exist at runtime. In particular, runtime
  code must not depend on an incidental `table.deepcopy` global; execute quality
  and researched-upgrade branches in regression tests, not only normal defaults.
- Orbital work banks native progress and committed inputs; never reset/reinsert
  them to emulate a resume. Terrestrial ordinary compute still scraps failures.
- Solar-panel prototypes require strictly positive production on 2.1.20. A test
  may disable platform solar to isolate supplied EEI power, but must disclose
  that limitation and never call it real orbital-generation qualification.
- Passive thermal interfaces use `at-least` at their floor, not `add 0`:
  native clamping can turn the latter into continuous free heat. Prove idle
  behavior, energy conservation, real burnout and hot-buffer reloads.
- Orbital cooling is a physical heat network, never a platform-wide radiator
  quota or automatic script pause. Keep thermal work bounded and preserve heat
  through reconciliation. A destroyed platform object can become invalid before
  the next callback; cache its surface index and do not dereference it afterward.
- GUI/join events cannot be raised synthetically, and LuaGameScript has no
  create_player API. Use purpose-created native players for GUI persistence
  tests; distinguish public-callback tests from real clicks, joins and reconnects.
  A one-player fixture does not qualify simultaneous multiplayer presentation.
- Native label wrapping requires `label.style.single_line = false`; setting a
  creation field alone can silently leave ellipses. Recenter a newly populated
  screen frame with `force_auto_center()`. GUI screenshots must use the player's
  actual display resolution or off-screen captures can create false clipping.

## Verification

- Run focused unit tests for each change.
- Run `python3 -m unittest tests.test_bitermotors_mod` for mod changes.
- Run `scripts/validate-bitermotors-mod.sh` after non-trivial prototype or runtime
  changes when Factorio is available.
- Use `git diff --check` before committing.

## Repository Policy

- Keep this repository independent. Do not import, invoke, or assume external
  game-automation projects.
- Do not commit saves, server data, logs, playtest output, credentials, or
  machine-specific runtime files.
- After each major implementation turn, commit the completed logical slice.
- Never revert unrelated user changes.
