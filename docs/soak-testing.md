# Release Soak Testing

`scripts/soak-bitermotors-save.sh` runs a copy of a real campaign through the
exact packaged Biter Motors archive in an isolated Factorio user directory.
It advances simulated game time as quickly as the CPU permits; it does not wait
four wall-clock hours for a four-hour terrestrial soak. The isolated copy is
explicitly unpaused; the original save's paused state is not changed.

The harness produces:

- `benchmark.log`: the complete long-run Factorio log and timing summary;
- `timing-sample.log`: a bounded per-tick timing sample used for p95 and p99;
- `probe.jsonl`: periodic progress, endgame, performance, platform, and core
  snapshots from a temporary read-only probe mod;
- `summary.json`: hashes, simulated and wall-clock duration, thresholds,
  metrics, initial/final state, and the pass/fail verdict.

It fails on known Factorio/Lua runtime-error signatures even when Factorio exits
with status zero. The default performance gates reserve meaningful room inside
the 16.667 ms update budget: long-run average at most 8 ms, warm p99 at most
16.667 ms, and warm maximum at most 100 ms. The first 60 timing ticks are
excluded as load warmup.

## Terrestrial Release Soak

Use a representative late-terrestrial save with an operating customer economy
and terrestrial compute:

```bash
scripts/soak-bitermotors-save.sh \
  --profile terrestrial \
  --save /absolute/path/to/late-terrestrial.zip \
  --hours 4 \
  --output-dir /tmp/bitermotors-terrestrial-soak
```

The profile requires at least one Sales Office, customer settlement, and
Terrestrial Datacenter. A four-hour run advances 864,000 simulation ticks.

## Orbital Release Soak

Use a save with at least two platforms and two powered, cooled, configured
Orbital Datacenter Cores:

```bash
scripts/soak-bitermotors-save.sh \
  --profile orbital \
  --save /absolute/path/to/orbital-scale.zip \
  --hours 1 \
  --output-dir /tmp/bitermotors-orbital-soak
```

The profile also requires cumulative orbital AI Token output to increase during
the run. A one-hour run advances 216,000 simulation ticks.

For harness development only, `--ticks` can replace `--hours` and
`--skip-profile-requirements` can measure an incomplete fixture. Do not use that
flag as release evidence. The original save is never modified.
