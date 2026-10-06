# Endgame Validation Contract

The Biter Motors endgame is a physical orbital-compute campaign ending in one
uninterrupted 20-minute, 10 GW AGI training run. This document defines the
runtime signals that must agree before release.

## Current Validation Status

The [2026-10-05 v1 review](v1-readiness-review.md) found current-version load,
statistics-direction, physical-payload, victory-completion, and final-controller
effect defects. Native compute accounting and fixed final training/completion
are now implemented; see [accounting evidence](ai-accounting-validation.md) and
[finale evidence](finale-validation.md). Cargo delivery, complete cooling
qualification, and the final campaign remain open. This contract is not a full
release certificate; finish Phase 3 before Luke's final fresh campaign.

## Authoritative AI Token Accounting

Completed native Terrestrial Datacenter and Orbital Datacenter Core recipes
are the authoritative cumulative AI Token-equivalent ledger. Scripted research
bonuses count only when physically inserted. Statistics, transfers, packaging,
and arbitrary inventory insertion cannot establish earned computation.
Item/fluid statistics use `input` for production and `output` for consumption;
electric-network statistics instead use `input` for consumption; see the
[official API](https://lua-api.factorio.com/latest/classes/LuaFlowStatistics.html).

Physical AI Tokens supply research and ordinary Dataset packaging. Grid-scale
and hyperscale cores can output compact Datasets directly, worth 50,000 computed
equivalents each. Packaging existing Tokens earns no additional progress and
does not require a 10 GW controller.

The cumulative ledger controls:

- the Biter Motors Progress Compute section;
- terrestrial efficiency and orbital scale milestones;
- the one-billion-token AGI Training Run unlock;
- victory metadata and endgame telemetry.

## Runtime Status

`remote.call("bitermotors", "endgame_status", "player")` reports:

- cumulative, terrestrial, and orbital AI Token totals;
- native item-stat production for discrepancy diagnosis, not progression;
- orbital core and radiator totals;
- each core's recipe, progress, power fraction, cooling assignment, and reset
  reason;
- AGI unlock, training progress, the 1,200-second/10 GW contract, the 90%
  power-buffer threshold, and persistent native-completion victory metadata.

This interface is read-only. The smoke-only `test_set_ai_token_progress` helper
is unavailable unless the validation mod is loaded.

## Final Training Contract

Every controller quality runs at native speed one. Final training ignores
module, beacon, surface, and local effects. The base recipe lasts 1,200 seconds,
has no productivity or quality multiplication, and draws 10 GW while working.
The native completion event is authoritative; an inserted Model cannot win.

Controllers have a separate bounded power queue: at most 32 controllers are
checked per tick, independently of other AI machines. Up to 32 are all checked
every tick; larger registries rotate. A low/no-power status or a sampled buffer
below 90% scraps active progress. The internal buffer provides only a tiny
flicker tolerance, not a grace period measured in seconds. Inputs stay committed.
After a one-second retry hold and buffer recovery, training starts again from
zero without another full set of inputs. Native exact-zero progress cancels the
committed batch, so a negligible `1e-12` sentinel preserves it internally; the
public status reports 0% while held. Native red status explains the hold.

The completion callback follows the final energy draw, so its now-depleted
buffer must not veto a completed native run. Persistent failure state and the
earned billion-equivalent gate still guard completion. Victory latches once per
force and survives output removal and reload. The finale fixture exercises ten
full runs, not merely an injected win or an accelerated final recipe.

## Release Evidence Still Required

- Complete the first real orbital batch on a player-built Nauvis platform.
- Confirm an undercooled core resets and resumes after eight radiators exist.
- Finish orbital brownout and cooling-allocation/removal/recovery qualification.
- Prove real cargo/inserter delivery of the complete intended final payload
  without injected inventory or an impractical billion-item transfer.
- Run a one-hour soak with several operating cores and at least two platforms.
- Complete the uninterrupted 20-minute, 10 GW AGI run in a non-sandbox campaign.
- Qualify multiplayer joins and harmless configuration changes during outages
  and training against the final candidate archive.
