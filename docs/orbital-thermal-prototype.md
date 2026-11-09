# Isolated Orbital Thermal Prototype

## Scope

Opt-in addon: `experiments/bitermotors_thermal_prototype_0.1.0`.
Physical core buffers, conduits and radiators are experimental entities;
the main mod's source and ordinary gameplay remain untouched. This is not a
replacement for the production orbital-cooling system.

The custom GUI frame has been removed. Display scope is native entity
`custom_status` for core temperature and radiator power. Graphical/UI
qualification, including unpowered status display and future GUI work, is
**not done**; native physics validation does not establish it.

The approved normal operating target is **97 C**, not a destruction threshold.
Warning begins at 105 C, critical at 120 C, and destructive burnout at 130 C.
No automatic thermal shutdown is proposed: inadequate cooling must be able to
destroy a running core rather than silently protecting it.

## Model

- Approximately 250 MW aggregate heat per fully working core, calculated in Lua
  from measured native work rather than assumed continuous operation.
  The prototype deliberately isolates active heat: 250 MW active / 0 W idle,
  with `energy_source.drain = "0W"` on the experimental core only. Production
  core idle drain remains unchanged.
- Finite heat capacities: core 500 MJ/C, radiator 100 MJ/C, conduit 20 MJ/C.
  Native heat buffers/connections conduct heat, with 5 GW maximum transfer.
- Radiator rejection is `min(300 MW, 250 MW * ((T + 273.15) / 367.8)^4)`.
  The radiation reference is calibrated to 94.65 C (367.8 K), targeting
  97 C +/- 1 C in the nominal three-conduit layout. Different layouts need
  not equilibrate at the same core temperature.
- Cooling removes no more than the radiator's available stored heat above
  15 C. This thermal floor is a gameplay bound, **not real orbital ambient**.
  Heat interfaces use neutral `at-least` mode at 15 C and explicitly spawn at
  15 C. Do not use `add` mode: the first native run found that `add 0` was
  clamped to 15 and added 15 C per tick.
- Work credit is clamped between zero and elapsed time. A decreasing/reset
  work counter, including a recipe-change reset, cannot earn negative heat
  or fictitious work credit. Native recipe-change integration still needs testing.

This is a lumped thermal approximation, not a full orbital radiation model:
it does not qualify radiator area, orientation, sunlight or spacecraft geometry.

The supplied inspiration is [Elon Musk's X post](https://x.com/elonmusk/status/2013676764099199156),
associated with a 370 K target (96.85 C by conversion). Direct retrieval was
blocked; its wording has not been independently verified and is not quoted here.
The user approved 97 C regardless of that attribution.

## Verification

Pure Lua policy and source-scope checks:

```sh
python3 -m unittest tests.test_orbital_thermal_prototype -v
```

Run the isolated native validator from source or with an exact-source addon ZIP:

```sh
scripts/validate-bitermotors-thermal.sh
BITERMOTORS_THERMAL_ARCHIVE=/path/to/bitermotors_thermal_prototype_0.1.0.zip \
  scripts/validate-bitermotors-thermal.sh
```

Both modes stage mods and engine write data under a fresh temporary directory;
the archive mode verifies file membership and bytes against current addon source
before staging. Neither mode installs the prototype into the normal mod folder.

These cover Kelvin fourth-power rejection, the 300 MW cap, temperature states,
finite-energy cooldown/floor, bounded work credit, absence of a proposed
shutdown, neutral heat registration/spawn initialization, experimental-only zero
idle drain, and separation from main-mod Lua. Runtime registration uses Lua
mocks; these checks do not prove native conduction, runtime destruction, power
consumption or persistence. Source guards also check temporary runner paths,
phase log/report checks, and fixture markers without temperature/progress writes.
These are harness contracts, not an execution-based source-integrity proof.
No pytest dependency is required.

Native run baseline: **Factorio 2.1.24, build 87808, arm64**.
Earlier 2.1.20 validation is historical and does not qualify this prototype.

Final source-native validation **passed all 12 ordered report states**;
its JSONL results were inspected. The **30-minute initial warmup (108000 ticks)**
reached 97.00457 C at 250 MW. Burnout occurred at 130.07493 C, 41.75 seconds
after the hot checkpoint near 110 C: exactly one native death, radiators
unharmed, and the hidden thermal component removed. Hot and burned reloads
passed in separate processes. Post-repair settling runs for 20 minutes
(72000 ticks); conduit cuts and repairs are native.
The final conduit cut from the repaired normal operating point provided
**68.75 seconds to burnout**, measured from the `repair_passed` tick to the
native death tick; the 41.75-second hot-checkpoint interval is only its final
portion, not the full normal-temperature repair window.

The exact-source addon ZIP also **passed all 12 states**, including separate
hot and burned reloads; its phase logs passed the native log checker.
This independently qualifies the packaged artifact within the same fixture
scope. Final run records:

- Source: `/tmp/bitermotors-thermal.swPjz4`.
- Exact addon ZIP: `/tmp/bitermotors-thermal.xl48qC`.
- ZIP SHA-256: `66ceebdb5af44d2952aeba5c0a236bdad7b1f501a378c698f92f28bee8880a99`.
- Both runs: steady 97.0045716108 C; burnout 130.074926625 C;
  68.75 seconds from nominal cut, 41.75 seconds from the hot checkpoint.
- Repaired equilibrium: 97.03338 C. At 120 MW solar supply, measured work
  fraction was 0.4800748 versus full 250 MW normal operation.

The [review page](orbital-thermal-prototype.html), accompanying PNG diagrams and
[compact results JSON](orbital-thermal-prototype.json) are generated review
artifacts, **not screenshots** or graphical qualification.

Regenerate the charts from a completed validator run:

```sh
python3 scripts/render_thermal_prototype.py \
  --samples /tmp/<run>/script-output/bitermotors-thermal-samples.jsonl \
  --report /tmp/<run>/script-output/bitermotors-thermal.jsonl \
  --output docs/orbital-thermal-prototype.html
```

| Planned Case | Required Evidence | Status |
| --- | --- | --- |
| Stable connected cooling | Nominal three-conduit core at 97 C +/- 1 C, native solar and actual work | Passed: 97.00457 C at 30 min |
| Energy conservation | Generated heat reconciles with radiated energy and stored-energy change across native buffers/conduits | Passed within 0.1% tolerance |
| Conduit cut | Loss of conduction and rising core heat under measured work | Passed |
| Reconnect | Restored conduction and cooling after 1200 seconds of repair settling, without fabricated work/progress | Passed: 97.03338 C |
| Brownout / outage | Heat tracks reduced actual work; unpowered core stops active heat | Passed: 120 MW supply, work fraction 0.48007; outage heat stops |
| Output full | Block output after steady state; no continued compute heat credited while native work is stalled | Passed: zero active heat |
| Native burnout | Destruction at/above 130 C without protective shutdown; local cleanup | Passed: 130.07493 C, one native death |
| Save/reload | Hot buffer persists; burned core stays destroyed without duplicate death or output | Passed: separate-process hot and burned checkpoints |
| Exact ZIP | Byte-matched packaged addon completes native fixture | Passed: all 12 states and phase log checks |
| Graphical/UI | Native status display, including unpowered status, inspected in a client | Not qualified |

Qualification is limited to the isolated thermal fixture: supplied foundation,
hardware, research and physical Dollars, with native orbital solar, crafting,
conduction and destruction. It does **not** qualify real rocket launches,
campaign progression, graphical behavior or the main mod's production cooling.
The main mod source remains unchanged; all thermal behavior is confined to
the opt-in experimental addon. Tests include the passive native API setting
guard (`at-least` 15 C), not just the pure cooling equation.
