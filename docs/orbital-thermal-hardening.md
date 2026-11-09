# Physical Orbital Cooling

Qualified 2026-11-09 on **Factorio 2.1.24, build 87808, mac-arm64, Space Age**.
The [compact evidence record](orbital-thermal-hardening.json) identifies source,
archive, fixture and runner hashes without committing raw saves or runtime logs.

The main mod now replaces platform-wide radiator quotas with native heat
networks. The original [isolated prototype](orbital-thermal-prototype.md) is
historical; its 500 MJ buffer and 69-second failure window are not current balance.

## Player Contract

Connect a Compute Cluster's center-edge port to an Orbital Radiator with
Orbital Heat Pipes. All four sides have ports. Multiple clusters and radiators
can share a network; a disconnected radiator provides no cooling. Heat transport
and storage use Factorio's native heat system, not Lua searches for nearby sinks.

| Property | Normal value |
| --- | ---: |
| Active compute | 250 MW plus native idle drain |
| Idle drain | Approximately 8.33 MW |
| Target operating temperature, short correctly sized loop | Approximately 97 C |
| Warning, yellow | 105 C |
| Critical, red | 120 C |
| Destructive burnout | 130 C |
| Core heat capacity | 1.2 GJ per C |
| Radiator heat capacity | 100 MJ per C |
| Orbital Heat Pipe capacity | 20 MJ per C |
| Maximum rejection per radiator | 300 MW |

From normal full-load operation, disconnection gives roughly **2-3 minutes**
to repair the heat path or stop the power. The native single-core measurement
was **154.75 seconds**, ending in one actual entity death at about **130.05 C**.
A correct network operates indefinitely without random failures or maintenance.
Extra radiators and isolation are legitimate engineering choices.

Warning and critical states create native custom alerts targeted at the affected
core with `show_on_map=true`, a visible warning sprite and a temperature-bearing
native machine status. Recovery removes the alerts and sprite. There is no
recurring console spam. The entity inspector shows temperature and heat load;
ordinary and final-stage Progress show the hottest core and thermal health.

Low power proportionally slows native work and reduces heat; a complete outage
stops active heat. Full output or idle machines produce only their powered idle
load. Power failures bank native progress and committed ingredients. Cooling
failures **never automatically pause computation**: burnout destroys the core
and its committed batch, including an unfinished Model. Previously completed
compute remains earned. Ordinary terrestrial AI retains its separate scrap rule.

## Runtime And Lifecycle

- One hidden native heat buffer per core. It is noncolliding and excluded from
  blueprints; real ports are at the center of each edge of the 3x3 footprint.
- Native recipe-completion events plus sampled progress account for real work.
  Bonus outputs are not extra electrical work. Actual crafting speed and native
  consumption bonuses are used; speed/recipe edits can straddle one sample.
- Idle draw under brownout is approximated from the electrical buffer. This is
  a gameplay heat model, not per-tick electricity calorimetry or flight hardware.
- Every 15 ticks, visit at most 64 cores and 64 radiators through persistent
  queues. At 128 of each, a full sweep is half a second. No recurring surface,
  settlement, customer or heat-network graph scans are added.
- Heat, work counters and queues persist through save/reload. Configuration
  reconciliation retains existing valid buffers instead of resetting their heat.
- Clones inherit source temperature but have separate components/counters.
  Relocation retains temperature; force changes update buffer and warning ownership.
- Mining, death, script destruction and surface deletion remove components.
  Mining has ordinary Factorio consequences: committed work is lost; temperature
  is not preserved in an ordinary building item. Missing hidden components cannot
  silently respawn cold and rescue an overheating core.

Radiation uses a capped absolute-Kelvin fourth-power curve, calibrated for a
short normal loop. The 15 C simulation floor and 130 C burnout are game tuning,
not claims about vacuum temperature, real chip limits or SpaceX specifications.
Longer pipes and overclocking can require more cooling. Five ordinary Solar
Wings still supply 300 MW in Nauvis orbit; no coolant mining, fluids, new money
fee or additional required research has been introduced.

## Reproduce

```bash
python3 -m unittest tests.test_orbital_thermals tests.test_orbital_thermal_data
scripts/validate-bitermotors-thermal-hardening.sh
```

The runner creates disposable local profiles, supplied-stock platforms and
real server checkpoints, reloads them in separate processes, checks native fatal
logs even on zero exit status, and benchmarks stable 12- and 128-core arrays.
The single-core case uses five real orbital Solar Wings. Larger shared arrays
use explicitly supplied electrical interfaces, not proof of real solar or rocket
logistics. Every benchmark core must produce new physical output during advancing
game time; a completed benchmark update count alone is insufficient.

Set `BITERMOTORS_THERMAL_PLAYER_SAVE` to a disposable native player seed to
exercise actual per-player alert creation and clearing without controlling a
desktop client. Never use a valuable campaign save as a destructive fixture.
`BITERMOTORS_MOD_ARCHIVE=/absolute/path/to/bitermotors_0.1.1.zip` tests the exact
archive after checking it matches source. `--check-report ARTIFACT_ROOT` validates
completed evidence without launching Factorio.

The banked-work/terrestrial-scrap and physical ending regressions remain useful:

```bash
scripts/validate-bitermotors-cooling.sh
scripts/validate-bitermotors-ai.sh
scripts/validate-bitermotors-finale.sh
```

## Acceptance Boundary

The final archive passed a fresh, non-resumed **20-phase** thermal run with one
real offline player, plus full-mod smoke and the native single-player physical
ending/epilogue checks. Hot and burned checkpoints were reloaded in separate
processes. All **448 Python tests pass, zero skipped** with Lua execution available.
The updated 1/4/8/12 native blueprints passed real rockets, native solar,
construction, extraction, return and reload using a Lua-identical package before
the final documentation-only archive refresh; all 31 Lua members were compared.

| Native benchmark | Runs, each 3,600 updates | Mean engine ms/tick |
| --- | --- | ---: |
| 12 connected cores | 377.605 / 387.248 / 397.501 ms | 0.108 |
| 128 connected cores | 579.059 / 596.958 / 590.414 ms | 0.164 |

Each individual core produced new physical output in every benchmark run.
The 128-core network stayed near 96.5 C at its checkpoint; thermal processing
visited no more than 64 cores and 64 radiators per callback. Shared-radiator loss
heated all four connected cores and replacing it restored safe operation.
Native cloning, force change, mining, rebuilding, script removal and platform
surface deletion passed cleanup checks. Configuration reconciliation and effect
math have unit coverage; a native configuration-change and quality/beacon matrix
are not claimed by this slice.

Native physics and native alert/render objects do not establish graphical
readability, real mouse dispatch, simultaneous multiplayer, natural campaign
pacing, or performance in a large populated player save. Native engine timings
include the test world and fixture, not an isolated measurement of thermal Lua.
The final playthrough still needs remote-view/readability checks and practical
observation of cooling repairs and expansion.

No live player save, server or desktop client is restarted by these validators.
Existing orbital layouts must be replumbed before resuming work; an old radiator
count is no longer protection from overheating. The supported release path is
a newly created world, not a promise of an old-save type migration.
