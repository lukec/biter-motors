# Terminal Epilogue And Final Presentation

Updated **2026-11-08**. Engine: **Factorio 2.1.20, build 87512, mac-arm64,
Space Age**. Mod: **Biter Motors 0.1.1 alpha**.

This completes Phase 3C's implementation. Phase 4's practical platform, pacing
and orbital artwork freeze remains next. This is not a natural campaign,
release soak or simultaneous multiplayer acceptance report.

## Player Experience

The final chapter progressively shows earned compute, orbital Model assembly,
native cargo return and ground activation. Earned computation is distinct from
physical inputs. Once native crafting consumes a payload, Progress and the
inspector say **Payload committed**, rather than requesting those inputs again.
Power, cooling and output holds explain what to fix. Completion is derived from
the persistent victory, even after the final machines are removed.

After the normal victory screen's Continue action, the terminal waits until the
player has no other GUI or landing cutscene open. It presents the approved
offline dialogue, a blinking cursor for **180 simulation ticks**, then the reply.
Skip, Continue, X and native Escape close it. The completed Progress panel's
Model button replays it. No network call, credential, paid inference, world
pause or speed change is involved.

Acknowledgement is stored per **player + force + original victory tick**.
Disconnects suspend without acknowledging. Thinking/reply sessions survive
reload; replay preserves the original Continue/Skip history. An unwon force
cannot open the scene. A late joining player is independently eligible.

The runtime visits only queued/open terminal players, and refreshes only open
late Progress panels once per second. It does not add whole-world inventory or
customer scans. Stable presentation signatures avoid rebuilding a completed UI
on every refresh.

## Native Qualification

The single-player fixture starts with an actual native offline player, then
runs the genuine rare-quality ending route: one billion earned equivalents,
20,000 physical Datasets, native orbital assembly, the actual Model pod and
Nauvis delivery, native ground activation, and once-only victory. It does not
inject victory, fake players, raise GUI events, or substitute output presence
for completion.

Separate Factorio processes reload the interrupted assembly, in-flight pod,
returned Model, interrupted activation, won world, mid-thinking scene,
reply-before-acknowledgement, acknowledged scene, and unfinished replay.
The final world advances **2,400 more freeplay ticks** without repeating victory
or reopening an acknowledged terminal. Six native Progress checks prove the
committed assembly/activation states before and after reload, and completion
after machine removal. Native pure-presentation assertions additionally cover
stage precedence and actionable blockers.

The headless GUI checks use real LuaGuiElements and public presentation
callbacks for a real offline player. They are **not simulated mouse events**.
Pure Lua tests exercise independent players, Skip/Continue/X/replay handlers,
force isolation, lifecycle cleanup and cutscene deferral separately.

Graphical review uses a disposable copy of a genuinely won native fixture, a
loopback server and an isolated client profile. It verifies actual late player
creation/join, automatic presentation after the landing cutscene, native Escape
acknowledgement, and legible terminal/Progress layouts at two GUI scales. The
graphical replay is opened through the public callback; mouse-button dispatch
is not claimed by that review.

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
BITERMOTORS_EPILOGUE_SINGLE_PLAYER=1 \
BITERMOTORS_ENDING_PLAYER_SAVE=/absolute/path/to/native-offline-player.zip \
  scripts/validate-bitermotors-epilogue.sh
```

Create the disposable seed through a real client joining an isolated local
server, disconnect, then save it from that server. Use a fresh world, not a
playthrough save. Factorio has no `game.create_player` API; GUI and join events
cannot be raised with `script.raise_event`. Lua/Lupa is required to execute
the optional pure-Lua Python cases; the native validator is separate.

The stricter default epilogue mode requires three actual offline players and a
genuine later connection named `Epilogue-late`. It fails before engine startup
if its seed is missing, and has a bounded late-join wait. Single-player reports
explicitly set `single_player=true`. All fixture modes retain
`multiplayer_qualified=false`; the stricter fixture can only qualify the narrower
`native_player_isolation_qualified` scope. Ordinary mechanical validators
explicitly report the epilogue as unqualified. None silently substitutes a
weaker green result for simultaneous multiplayer evidence.

To test the exact package, add
`BITERMOTORS_MOD_ARCHIVE=/absolute/path/to/bitermotors_0.1.1.zip`.
The runner rejects an archive that differs from the current package contents.

## Evidence And Limits

- **323 Python tests pass**, including executable Lua state/presentation cases.
- Source single-player native ending: **20 phases**, nine checkpoint reloads,
  six native ending Progress checks, and 2,400 freeplay ticks. A separate native
  force roundtrip primes an early-view cache, replaces it with the won view,
  then proves that returning to the early force hides the ending and replay.
- Current native prototype capture confirms **no recipe, research, power or
  economy changes** in this presentation slice; generated budget differences
  are source-provenance hashes only.
- Smoke now fixes the world seed and prepares the datacenter power-probe area:
  random trees/terrain previously displaced its pole independently of the
  datacenter, producing an unrelated false power failure.
- Graphical testing caught and fixed cutscene focus theft; native Progress
  testing caught and fixed the progress-bar style API before packaging.

Runtime/prototype source SHA-256:
`41aa2e052f7c4e65225716b391f661ca915bde261af0ae2320b8a078b5fb953f`.

Exact development archive SHA-256:
`230715554394ee40da77db841ffd39f1337be8fd3294e863279b99783699ad42`.

Fresh source capture: `/tmp/bitermotors-validate.R2s9Dh`.
Archive: `/tmp/bitermotors-terminal-qualified-package`.
Temporary saves/logs are deliberately not committed.

| Final Check | Source | Exact ZIP |
| --- | --- | --- |
| Broad smoke and native prototype/runtime capture | Pass | Pass |
| Rare Model route, terminal and nine checkpoint reloads | 20 phases pass | 20 phases pass |
| Repeated open, six ending GUI checks, 91 presentation assertions | Pass | Pass |
| Same-frame early/won/early/won Progress cache and spoiler isolation | Pass | Pass |
| Normal-quality Model delivery route | Prior Model baseline | 12 phases pass, no GUI claim |
| AI accounting and pending-bonus/in-progress reload | Prior Model baseline | Pass |
| Cooling/power banking and terrestrial scrapping | Prior Model baseline | Pass |

Each final ending run advances 2,400 further freeplay ticks. Current native
ending artifacts are `/tmp/bitermotors-finale.Mvo4HU` (source),
`/tmp/bitermotors-finale.UVThmH` (ZIP) and
`/tmp/bitermotors-delivery.5iEVvG` (normal ZIP). ZIP smoke is
`/tmp/bitermotors-validate.qTmZQN`; ZIP AI and cooling are
`/tmp/bitermotors-ai.IZp8Eu` and `/tmp/bitermotors-cooling.9L9Dmr`.
Both multiplayer qualification flags are false in the single-player reports.

The graphical run used `/tmp/bitermotors-epilogue-visual`, an isolated client
profile and loopback port 36584. At GUI scales 0.75 and 1.25, dialogue, status,
buttons and completion rows remained legible and contained. After native Escape,
the saved acknowledgement was true. A separate server process loaded that
actual save; the real client reconnected with the same original victory tick,
`phase=acknowledged`, `acknowledged=true`, `open=false`. The scene did not reopen.
Both test processes were then saved/stopped; the normal game profile was not
used for a playthrough or world mutation. This supplements rather than replaces
the native checkpoint fixture and its explicit multiplayer limitation.

**Still required before release:** simultaneous independent-player native GUI
acceptance, practical orbital layout/pacing, remaining orbital art, scale/long
soaks on the frozen archive, clean installation and Luke's full fresh campaign.
Only purpose-created temporary test processes/worlds are operated in this
slice; no live playthrough save is edited or normal game server restarted.
