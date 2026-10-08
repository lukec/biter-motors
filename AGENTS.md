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
- Model both rocket and cargo-pod inventory limits. The validated 2.1.20 rocket
  has 20 slots but its ascent pod has 10; weights alone do not define capacity.

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
