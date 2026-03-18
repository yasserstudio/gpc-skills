# Release Train — Full Lifecycle

End-to-end reference for the `gpc train` config-driven staged rollout pipeline.

## Overview

```
configure .gpcrc.json → gpc train start → stage 1 (immediate)
  → [wait: after time] → gate check → stage 2
  → [wait: after time] → gate check → stage 3
  → [wait: after time] → gate check → stage 4 → complete
```

Each stage transition requires two conditions to be met:
1. The `after` time delay has elapsed since the previous stage.
2. All configured gates (crash rate, ANR rate) are below their `max` thresholds.

If either condition fails, progression is paused until the issue is resolved and the user resumes.

## State file

The train stores its progress in:

```
~/.cache/gpc/train-<packageName>.json
```

Example state:

```json
{
  "packageName": "com.example.app",
  "startedAt": "2026-03-15T10:00:00Z",
  "currentStageIndex": 2,
  "lastProgressedAt": "2026-03-17T10:05:00Z",
  "status": "running",
  "gateFailures": []
}
```

Status values: `running`, `paused`, `aborted`, `complete`.

## Config reference

```json
{
  "release-train": {
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
}
```

### Time format for `after`

| Value | Meaning |
|-------|---------|
| `30m` | 30 minutes |
| `12h` | 12 hours |
| `2d`  | 2 days (48 hours) |
| `7d`  | 7 days |
| `14d` | 14 days |

Omitting `after` means the stage is eligible immediately (subject to gate checks still passing).

## Phase-by-phase lifecycle

### Phase 1 — Config

Create or update `.gpcrc.json` with the `release-train` block. This is the single source of truth for stage definitions and gate thresholds. Commit this file to source control so all team members and CI share the same pipeline definition.

### Phase 2 — Start

```bash
gpc train start
```

- Reads `.gpcrc.json`.
- Creates the state file at `~/.cache/gpc/train-<packageName>.json`.
- Executes stage 0 immediately (no `after` delay, no gate check on the first stage).
- Transitions: promotes the release to the configured track at the configured rollout percentage.
- Logs the start timestamp to the state file.

### Phase 3 — Gate check

Before each stage transition (stages 1+), `gpc train` evaluates the configured gates:

```
crash rate  ≤  gates.crashes.max  →  pass
ANR rate    ≤  gates.anr.max      →  pass
```

If both pass and the `after` time has elapsed, progression continues. If either fails, the state is set to `paused` and a warning is printed:

```
Gate failed: crash rate 2.1% exceeds max 1.5%
Progression paused. Fix the regression and run: gpc train start --resume
```

The gate check uses the same vitals API as `gpc vitals crashes` and `gpc vitals anr`. Note that vitals data for a newly released version takes 6–48 hours to populate — configure your `after` delays accordingly.

### Phase 4 — Progression

When both conditions are met (time elapsed + gates pass), the train:

1. Calls the appropriate GPC release command for the next stage (promote, rollout increase, or rollout complete).
2. Updates `currentStageIndex` and `lastProgressedAt` in the state file.
3. Prints a progress line showing the new stage.

### Phase 5 — Complete

When the final stage is executed successfully, the state file status is set to `complete` and the train exits cleanly:

```
Release train complete. All stages executed.
  internal → alpha → production@10% → production@100%
```

## Commands at a glance

| Command | What it does |
|---------|-------------|
| `gpc train start` | Start the train from stage 0, or restart a completed/aborted train |
| `gpc train start --resume` | Resume a paused train from the current stage |
| `gpc train status` | Show current stage, last progression time, time until next stage, gate health |
| `gpc train status --resume` | Show status and attempt to resume if paused and gates now pass |
| `gpc train pause` | Pause automatic progression (does not halt active rollout) |
| `gpc train abort` | Abort the train and halt all active rollouts on managed tracks |

## Pause vs abort

| | Pause | Abort |
|-|-------|-------|
| Stops stage progression | Yes | Yes |
| Halts active rollout | No | Yes |
| Clears state file | No | Yes |
| How to recover | `gpc train start --resume` | `gpc train start` (from stage 0) |

Use **pause** when you want to temporarily hold the pipeline (e.g., over a holiday weekend) without touching the active rollout.

Use **abort** when a critical regression requires immediately stopping distribution and starting over.

## Gate failure recovery flow

```
1. gpc train status         → confirm gate failure and which metric
2. gpc vitals crashes       → inspect crash rate and top clusters
3. gpc vitals anr           → inspect ANR rate
4. Fix the regression       → ship a new build to internal
5. gpc train start --resume → resume from the paused stage
```

If the fix requires a brand-new release (new version code), abort the current train and start a new one:

```bash
gpc train abort
# ... upload new AAB, set release notes ...
gpc train start
```

## CI usage

Run the train check in CI to assert that a train is healthy before a deployment step:

```yaml
- name: Check train gate health
  run: gpc train status
  # Exits non-zero if the train is in a failed/aborted state
```

Or start and detach (fire-and-forget) in an async CI pipeline:

```yaml
- name: Start release train
  run: gpc train start
```

The train state persists in `~/.cache/gpc/` — use a persistent cache volume if running across CI jobs.

## Timing reference

| Gate data type | Data lag |
|----------------|----------|
| Crash rate for new version | 6–48 hours after rollout begins |
| ANR rate for new version | 6–48 hours after rollout begins |
| Play Store review data | 1–24 hours |

Set `after` delays that are long enough for meaningful vitals data to accumulate before gate checks run. A minimum of `2d` on any production stage is recommended.
