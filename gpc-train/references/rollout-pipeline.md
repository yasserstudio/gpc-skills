# Release Train: Full Lifecycle

End-to-end reference for the `gpc train` config-driven staged rollout pipeline, matching GPC v1.0.0-rc.2.

## Overview

```
.gpcrc-train.json -> gpc train start -> stage 1 runs now
  -> gpc train advance (scheduled) -> after elapsed? gates pass? -> stage 2
  -> gpc train advance ...                                       -> stage N -> completed
```

Nothing moves on its own: each transition happens only when `gpc train advance` runs and both conditions hold:

1. The next stage's `after` delay has elapsed since the current stage ran.
2. Every configured gate (crash rate, ANR rate) is at or below its `max`.

## Config reference

`.gpcrc-train.json` (or any file passed with `--config`):

```json
{
  "stages": [
    { "track": "internal",   "rollout": 100 },
    { "track": "alpha",      "rollout": 100, "after": "2d" },
    { "track": "production", "rollout": 10,  "after": "7d" },
    { "track": "production", "rollout": 100, "after": "14d" }
  ],
  "gates": {
    "crashes": { "max": 1.5 },
    "anr":     { "max": 0.5 }
  }
}
```

`gates.*.max` are **percentages** (`1.5` = 1.5%). Elsewhere in GPC (`gpc vitals --threshold`, `gpc watch`, `vitals.thresholds.*`) rates are fractions (`0.015`).

### Time format for `after`

| Value | Meaning |
|-------|---------|
| `30m` | 30 minutes |
| `12h` | 12 hours |
| `2d`  | 2 days |
| `14d` | 14 days |

Omitting `after` makes the stage eligible on the next `advance` (gates still apply).

## State file

```
~/.cache/gpc/train-<packageName>.json
```

```json
{
  "packageName": "com.example.app",
  "status": "running",
  "currentStage": 1,
  "startedAt": "2026-10-01T10:00:00.000Z",
  "updatedAt": "2026-10-03T10:05:00.000Z",
  "stages": [
    { "track": "internal", "rollout": 100, "executedAt": "2026-10-01T10:00:00.000Z" },
    { "track": "alpha", "rollout": 100, "after": "2d", "executedAt": "2026-10-03T10:05:00.000Z" },
    { "track": "production", "rollout": 10, "after": "7d" }
  ],
  "gates": { "crashes": { "max": 1.5 }, "anr": { "max": 0.5 } }
}
```

Status values: `running`, `paused`, `completed`. `gpc train status` prints this state (`--json` for the raw object).

## Commands

| Command | Behavior |
|---------|----------|
| `gpc train start [--config <file>] [--force]` | Writes state and runs stage 1 now. With a train already running it changes nothing unless `--force`, which starts over at stage 1. |
| `gpc train advance` | Moves to the next stage when its `after` delay has elapsed and gates pass. Schedule it (CI cron). |
| `gpc train status` | Shows the saved state. |
| `gpc train pause` | Stops `advance` from moving the train. Does not touch rollouts on Google Play. |
| `gpc train abort` | Clears the state. Does **not** halt rollouts; use `gpc releases rollout halt --track <track>`. |

There is no resume command. After a pause or a failed gate, restart with `gpc train start --force` (stage 1 again), adjusting the config first if earlier stages should not re-run.

## Gate checks

Before each transition `advance` reads the most recent day of crash and ANR data and takes the worst value of that day.

| Result | Effect | Exit |
|--------|--------|------|
| All gates pass | Next stage runs | 0 |
| Crash gate over `max` | Train paused, `TRAIN_CRASH_GATE_FAILED` | 6 |
| ANR gate over `max` | Train paused, `TRAIN_ANR_GATE_FAILED` | 6 |
| No data for a gate (rc.2+) | Train stays on its stage, `TRAIN_GATE_NO_DATA` | 6 |

Vitals data lags 2 to 4 days, so set `after` delays long enough for a stage to produce data, and expect `TRAIN_GATE_NO_DATA` on low-traffic apps. Before rc.2 a gate with no data let the train advance.

## Scheduling `advance` in CI

```yaml
on:
  schedule:
    - cron: "0 */6 * * *"
jobs:
  train:
    runs-on: ubuntu-latest
    steps:
      - run: npx @gpc-cli/cli train advance --app com.example.app
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.GPC_SERVICE_ACCOUNT }}
```

Exit 6 fails the job on a breach or missing data; the state file must persist between runs (use a self-hosted runner or cache `~/.cache/gpc`).
