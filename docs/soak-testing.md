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
- `timing-probe.jsonl`: initial/final sentinels for the separate timing run;
- `summary.json`: hashes, simulated and wall-clock duration, thresholds,
  metrics, initial/final state, and the pass/fail verdict.

It fails on Factorio/Lua runtime-error signatures even when Factorio exits
with status zero. Both logs must report exactly the requested update counts
and a normal completion marker. All probes must have readable status/error
fields, the expected absolute-tick cadence, and unique initial/final sentinels.
Missing, malformed, truncated, out-of-order, or intermediate failed evidence
produces a failure summary; `--skip-profile-requirements` never relaxes these
completeness checks.

Requested updates and observed game-time span are recorded separately. On the
validated 2.1.20 engine, probes captured on the first and last of **N** updates
span **N-1** game ticks. Tick zero is not a periodic or terminal probe. A paused
or won world may report N benchmark updates without advancing game time; such
a run must fail rather than count as a completed soak. This convention is
native-engine-tested, not inferred from a requested CLI duration.

The default performance gates reserve meaningful room inside
the 16.667 ms update budget: long-run average at most 8 ms, warm p99 at most
16.667 ms, and warm maximum at most 100 ms. The first 60 timing ticks are
excluded as load warmup.

The temporary probe records periodic state during the long run. The harness
disables that periodic callback before the bounded timing sample so the
serialization cost of `progress_status`, `endgame_status`, and
`performance_status` is not mistaken for gameplay cost. The timing sample
still loads the same packaged mod and copied save.
Initial/terminal probe serialization still runs; the initial sample is inside
warmup, while the terminal sample remains in the measured window. Every
requested verbose timing row must be present, sequential, and numeric before
warmup exclusions or percentiles are calculated.

## Late-terrestrial Performance Reference

The September 2026 investigation used Luke's protected late-terrestrial save
with 221 settlements, 9,229 represented vehicle owners, 156 chargers, 20 Sales
Offices, and about 2,000 visible customer units. The original warm sample was
2.17 ms average, 12.16 ms p95, 24.53 ms p99, and 287.22 ms maximum.

The recurring hitch came from rebuilding the complete settlement-to-charger
market graph after every vehicle sale and population event. Biter Motors now
coalesces demand-only invalidations into one ten-second batch; infrastructure
changes still invalidate immediately. Charger power maintenance also caches
unchanged hidden sink configurations rather than rewriting every stall every
second. The same 3,600-tick sample after those changes measured 1.36 ms average,
6.54 ms p95, 15.05 ms p99, and 55.42 ms maximum on Factorio 2.1.14.

The tradeoff is bounded: ownership is assigned immediately, while aggregate
charger utilization and settlement mood may trail sales or population churn by
at most ten seconds. Building or removing chargers, poles, Sales Offices, or
settlements remains immediately actionable.

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
Terrestrial Datacenter. A four-hour request runs 864,000 updates, with an
expected 863,999-tick span between the initial/final probes. Presence alone is
not proof of an operating economy; use a representative campaign and inspect
its workload progress.

## Orbital Release Soak

Use a save with at least two platforms and two powered, cooled, configured
Orbital Datacenter Cores. All four orbital AI recipe tiers qualify; cores
disabled by script or carrying a power/cooling reset do not:

```bash
scripts/soak-bitermotors-save.sh \
  --profile orbital \
  --save /absolute/path/to/orbital-scale.zip \
  --hours 1 \
  --output-dir /tmp/bitermotors-orbital-soak
```

The profile also requires cumulative orbital AI Token output to increase during
the run. A one-hour request runs 216,000 updates, with an expected 215,999-tick
span between probes.

For harness development only, `--ticks` can replace `--hours` and
`--skip-profile-requirements` can measure an incomplete fixture. Do not use that
flag as release evidence. The original save is never modified.

The [2026-10-05 baseline](validation-baseline.md) includes a short native
harness check only. The four-hour terrestrial and one-hour orbital release
soaks remain outstanding.
