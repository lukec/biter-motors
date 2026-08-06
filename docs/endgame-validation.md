# Endgame Validation Contract

The Biter Motors endgame is a physical orbital-compute campaign ending in one
uninterrupted 10 GW AGI training run. This document defines the runtime signals
that must agree before the public alpha.

## Authoritative AI Token Accounting

Completed Terrestrial Datacenter and Orbital Datacenter Core cycles are the
authoritative cumulative AI Token ledger. Factorio item-production statistics
may omit this recipe output, so progression uses the greater of the internal
cycle ledger and native item statistics. Physical AI Token items are still
required for research, cargo, dataset packaging, and the final recipe.

The cumulative ledger controls:

- the Biter Motors Progress Compute section;
- terrestrial efficiency and orbital scale milestones;
- the one-billion-token AGI Training Run unlock;
- victory metadata and endgame telemetry.

## Runtime Status

`remote.call("bitermotors", "endgame_status", "player")` reports:

- cumulative, terrestrial, and orbital AI Token totals;
- native item-stat output for discrepancy diagnosis;
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
- Run a one-hour soak with several operating cores and at least two platforms.
- Complete the one-hour 10 GW AGI run in a non-sandbox campaign.
