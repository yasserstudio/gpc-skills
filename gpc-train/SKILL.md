---
name: gpc-train
description: "Use when setting up or managing automated staged rollout pipelines with GPC. Trigger when the user mentions gpc train, release train, staged rollout automation, rollout pipeline, release gates, automatic rollout progression, auto-halt on regression, rollout stages — even if they don't explicitly say 'train.' Also trigger when someone wants to automatically progress a release from internal → alpha → production with time gates, or set up crash/ANR gates that pause a rollout."
compatibility: "GPC v0.9.35+. Requires authenticated GPC setup (see gpc-setup skill). Release train config goes in .gpcrc-train.json (or --config <file>)."
metadata:
  version: 0.11.0
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
- Gate thresholds: max crash rate and max ANR rate, as percentages
- Whether to pause, restart, or abort the train

## Procedure

### 1) Configure the release train

Create `.gpcrc-train.json` in the project root (or pass another file with `--config`). Stages and gates are top-level keys:

```json
{
  "stages": [
    { "track": "internal",   "rollout": 100 },
    { "track": "alpha",      "rollout": 100, "after": "2d" },
    { "track": "production", "rollout": 10,  "after": "7d" },
    { "track": "production", "rollout": 100, "after": "14d" }
  ],
  "gates": { "crashes": { "max": 1.5 }, "anr": { "max": 0.5 } }
}
```

Config keys:

| Key | Type | Description |
|-----|------|-------------|
| `stages[].track` | string | Target track: `internal`, `alpha`, `beta`, `production` |
| `stages[].rollout` | number | Rollout percentage for this stage (1-100) |
| `stages[].after` | string | Minimum time since the previous stage ran (e.g. `2d`, `12h`, `30m`). Omit for no wait. |
| `gates.crashes.max` | number | Maximum crash rate, as a **percentage** (`1.5` = 1.5%), before the train pauses |
| `gates.anr.max` | number | Maximum ANR rate, as a **percentage** (`0.5` = 0.5%), before the train pauses |

Train gates are the one place GPC takes percentages. `gpc vitals --threshold`, `gpc watch` and `vitals.thresholds.*` take fractions (`0.02` = 2%).

Read:
- `references/rollout-pipeline.md`

### 2) Start the train

```bash
gpc train start                      # reads .gpcrc-train.json
gpc train start --config release.json
```

This writes a state file at `~/.cache/gpc/train-<packageName>.json` and runs stage 1 immediately (it sets that track's rollout on Google Play). If a train is already running, `start` changes nothing and prints its state; `--force` starts over and runs stage 1 again.

### 3) Advance the train

Nothing advances on its own. Run `gpc train advance` on a schedule (a CI cron job, for example). Each run moves to the next stage only when:

- the next stage's `after` time has elapsed since the current stage ran, and
- every configured gate passes.

```bash
gpc train advance
```

Gates read the most recent day of crash and ANR data (the worst value of that day).

- **Gate breached:** the train is paused and the command exits 6 (`TRAIN_CRASH_GATE_FAILED` / `TRAIN_ANR_GATE_FAILED`).
- **No data for a gate** (v1.0.0-rc.2+): the train stays on its current stage and the command exits 6 with `TRAIN_GATE_NO_DATA`. Vitals lag 2-4 days, so run it again later. Before rc.2 a gate with no data let the train advance.

### 4) Check train status

```bash
gpc train status
gpc train status --json
```

Prints the saved state: status (`running`, `paused`, `completed`), the current stage index, each stage with its `executedAt` / `scheduledAt` time, and the gates.

### 5) Pause a running train

```bash
gpc train pause
```

Stops `advance` from moving the train. It does **not** halt or change any rollout on Google Play. There is no resume command: to continue after a pause, start again with `gpc train start --force`, which begins at stage 1. Adjust the config first if earlier stages should not run again.

### 6) Abort the train

```bash
gpc train abort
```

Clears the train state. It does **not** halt rollouts on Google Play. To stop a release, halt it explicitly:

```bash
gpc releases rollout halt --track production
```

## Verification

- `gpc train status` shows the correct current stage and gate health values
- `gpc status` confirms rollout percentages on each track match the active stage in the train config
- Gate values (crashes, ANR) are below configured `max` thresholds
- State file at `~/.cache/gpc/train-<packageName>.json` reflects the current stage index and last progression timestamp

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Exit 6, `TRAIN_CRASH_GATE_FAILED` / `TRAIN_ANR_GATE_FAILED`, train paused | Crash/ANR rate above the gate's `max` percentage | Fix the regression in a new release, halt the rollout if needed, then `gpc train start --force` |
| Exit 6, `TRAIN_GATE_NO_DATA` | No vitals for the most recent day yet (2-4 day lag, or low traffic) | Run `gpc train advance` again later; the train stayed on its stage |
| `advance` does nothing | `after` time has not elapsed, or the train is paused | `gpc train status` shows `scheduledAt` and the status |
| `start` prints an old state and does nothing | A train is already running | `gpc train status` to check; `gpc train abort` or `start --force` |
| `INVALID_CONFIG` on start | `.gpcrc-train.json` missing or not valid JSON | Create it, or pass `--config <file>` |
| State file missing | Cache directory cleared or different machine | `gpc train start` again; it begins at stage 1 |

## Related skills

- **gpc-release-flow**: Upload, promote, and manual rollout management
- **gpc-vitals-monitoring**: Crash and ANR monitoring used by gate checks
- **gpc-ci-integration**: Running `gpc train` in CI/CD pipelines
