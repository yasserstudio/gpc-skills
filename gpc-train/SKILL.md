---
name: gpc-train
description: "Use when setting up or managing automated staged rollout pipelines with GPC. Trigger when the user mentions gpc train, release train, staged rollout automation, rollout pipeline, release gates, automatic rollout progression, auto-halt on regression, rollout stages — even if they don't explicitly say 'train.' Also trigger when someone wants to automatically progress a release from internal → alpha → production with time gates, or set up crash/ANR gates that pause a rollout."
compatibility: "GPC v0.9.35+. Requires authenticated GPC setup (see gpc-setup skill). Release train config goes in .gpcrc.json."
metadata:
  version: 0.10.0
---

# GPC Release Train

## When to use

Use this skill when the task involves:

- Setting up a config-driven staged rollout pipeline
- Automatically progressing a release through tracks (internal → alpha → production) with time gates
- Gating progression on crash rate and ANR rate thresholds
- Pausing, resuming, or aborting an in-flight release train
- Checking the current stage and gate health of a running train

## Inputs required

- Package name (or configured default in `.gpcrc.json`)
- Release train config: stages with tracks, rollout percentages, and time delays
- Gate thresholds: max crash rate and max ANR rate
- Whether to pause, resume, or abort the train

## Procedure

### 1) Configure the release train

Add a `release-train` block to `.gpcrc.json` in the project root:

```json
{
  "release-train": {
    "stages": [
      { "track": "internal",   "rollout": 100 },
      { "track": "alpha",      "rollout": 100, "after": "2d" },
      { "track": "production", "rollout": 10,  "after": "7d" },
      { "track": "production", "rollout": 100, "after": "14d" }
    ],
    "gates": { "crashes": { "max": 1.5 }, "anr": { "max": 0.5 } }
  }
}
```

Config keys:

| Key | Type | Description |
|-----|------|-------------|
| `stages[].track` | string | Target track: `internal`, `alpha`, `beta`, `production` |
| `stages[].rollout` | number | Rollout percentage for this stage (1–100) |
| `stages[].after` | string | Minimum time to wait before this stage (e.g., `2d`, `12h`, `30m`). Omit for immediate. |
| `gates.crashes.max` | number | Maximum crash rate percentage before pausing progression |
| `gates.anr.max` | number | Maximum ANR rate percentage before pausing progression |

Read:
- `references/rollout-pipeline.md`

### 2) Start the train

```bash
gpc train start
```

This reads `.gpcrc.json`, creates a state file at `~/.cache/gpc/train-<packageName>.json`, and begins executing the first stage immediately. Subsequent stages are executed when the `after` time has elapsed and gates pass.

```bash
# Resume a paused train
gpc train start --resume
```

### 3) Check train status

```bash
gpc train status
```

Output:

```
Release Train · com.example.app
  Stage 2 / 4   alpha @ 100%   in progress
  Last progressed: 2026-03-17 11:00 (2 days ago)
  Next stage: production @ 10%   eligible in 5 days

  Gates (last check: 10 minutes ago)
    crashes   0.82%   ✓  (max 1.5%)
    anr       0.19%   ✓  (max 0.5%)
```

```bash
# Resume if paused due to a gate failure
gpc train status --resume
```

### 4) Monitor gate health

Before each stage transition, `gpc train` automatically checks the configured `gates`:

- If **all gates pass**, the stage progresses (subject to the `after` time having elapsed).
- If **any gate fails**, progression is paused and a warning is shown.
- The user must fix the regression and re-run `gpc train start --resume` or `gpc train status --resume`.

Gate checks call the same vitals API as `gpc vitals crashes` and `gpc vitals anr`. Data lag of 6–48 hours applies to new releases — avoid configuring gates on the very first stage.

### 5) Pause a running train

```bash
gpc train pause
```

Pauses automatic progression. Does **not** halt or change the active rollout on any track. Run `gpc train start --resume` to continue.

### 6) Abort the train

```bash
gpc train abort
```

Aborts the train and **halts all active rollouts** on tracks managed by this train. State file is cleared. Use when a critical regression is found and the release must be stopped immediately.

## Verification

- `gpc train status` shows the correct current stage and gate health values
- `gpc status` confirms rollout percentages on each track match the active stage in the train config
- Gate values (crashes, ANR) are below configured `max` thresholds
- State file at `~/.cache/gpc/train-<packageName>.json` reflects the current stage index and last progression timestamp

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Gate check fails | Crash/ANR rate above configured `max` | Fix the regression in a new release, then `gpc train start --resume` |
| `Train already running` | Previous train was not completed or aborted | `gpc train status` to check state; `gpc train abort` if needed |
| Stage progression skipped | `after` time has not elapsed | `gpc train status` shows time remaining until next eligible stage |
| Train aborted unexpectedly | Gate threshold breached automatically | Check `gpc vitals crashes` and `gpc vitals anr`, fix regression, then restart |
| State file missing | Cache directory cleared or different machine | Re-run `gpc train start` — it will re-read `.gpcrc.json` and restart from stage 1 |

Read:
- `references/rollout-pipeline.md` — full lifecycle: config → start → gate check → progress → complete

## Related skills

- **gpc-release-flow**: Upload, promote, and manual rollout management
- **gpc-vitals-monitoring**: Crash and ANR monitoring used by gate checks
- **gpc-ci-integration**: Running `gpc train` in CI/CD pipelines
