# Endgame Validation Contract

The Biter Motors endgame is a physical orbital-compute campaign ending in one
uninterrupted 20-minute, 10 GW AGI training run. This document defines the
runtime signals that must agree before release.

## Current Validation Status

The [2026-10-05 v1 review](v1-readiness-review.md) found current-version load,
statistics-direction, physical-payload, victory-completion, and final-controller
effect defects. This document is an intended contract, **not evidence that the
current implementation satisfies it**. Finish the review's endgame phase before
Luke's final fresh campaign.

## Authoritative AI Token Accounting

Completed Terrestrial Datacenter and Orbital Datacenter Core cycles are the
authoritative cumulative AI Token ledger. The current implementation uses the
greater of the cycle ledger and a native-statistics helper, but that helper
incorrectly reads consumption as production. Do not explain a zero value as
missing native output until this direction is corrected and tested. Item/fluid
statistics use `input` for production and `output` for consumption; see the
[official API](https://lua-api.factorio.com/latest/classes/LuaFlowStatistics.html).

Physical AI Token items currently supply research, cargo, and Dataset packaging.
The v1 review recommends direct compressed Dataset output at the appropriate
orbital tier, counting earned token-equivalents exactly once, and moving cheap
packaging out of the final 10 GW controller. This is a proposal, not shipped
behavior.

The cumulative ledger controls:

- the Biter Motors Progress Compute section;
- terrestrial efficiency and orbital scale milestones;
- the one-billion-token AGI Training Run unlock;
- victory metadata and endgame telemetry.

## Runtime Status

`remote.call("bitermotors", "endgame_status", "player")` reports:

- cumulative, terrestrial, and orbital AI Token totals;
- native item-stat production for discrepancy diagnosis (currently the wrong
  direction; fix and cover it before release);
- orbital core and radiator totals;
- each core's recipe, progress, power fraction, cooling assignment, and reset
  reason;
- AGI unlock, training progress, and victory state.

This interface is read-only. The smoke-only `test_set_ai_token_progress` helper
is unavailable unless the validation mod is loaded.

## Release Evidence Still Required

- Complete the first real orbital batch on a player-built Nauvis platform.
- Confirm an undercooled core resets and resumes after eight radiators exist.
- Confirm a brownout scraps both an orbital batch and the final AGI run.
- Prove real cargo/inserter delivery of the complete intended final payload
  without injected inventory or an impractical billion-item transfer.
- Confirm quality and beacons do not bypass the chosen final time/power contract.
- Confirm genuine completion wins even if its Model is immediately extracted;
  arbitrary insertion of a Model must not win.
- Run a one-hour soak with several operating cores and at least two platforms.
- Complete the uninterrupted 20-minute, 10 GW AGI run in a non-sandbox campaign.
- Save/reload before, during, and after training, then continue after victory.
