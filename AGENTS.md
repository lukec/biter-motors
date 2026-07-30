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
