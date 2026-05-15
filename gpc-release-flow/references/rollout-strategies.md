# Rollout Strategies

## Staged Rollout Overview

Staged rollouts let you release to a percentage of users before going to 100%. This reduces risk by catching issues early.

## Recommended Rollout Pattern

```
Day 1:  Release to internal track (QA team)
Day 2:  Promote to beta track (beta testers)
Day 3:  Promote to production at 1% rollout
Day 4:  Check vitals → increase to 10%
Day 5:  Check vitals → increase to 50%
Day 7:  Check vitals → complete (100%)
```

### Commands for this pattern:

```bash
# Day 1
gpc publish app.aab --track internal

# Day 2
gpc releases promote --from internal --to beta

# Day 3
gpc releases promote --from beta --to production --rollout 1

# Day 4 (check vitals first)
gpc vitals crashes --threshold 2.0
gpc releases rollout increase --track production --to 10

# Day 5
gpc vitals crashes --threshold 2.0
gpc releases rollout increase --track production --to 50

# Day 7
gpc vitals crashes --threshold 2.0
gpc releases rollout complete --track production
```

## Rollout State Machine

```
             upload/promote
                  │
                  ▼
            ┌──────────┐
            │ inProgress│ (rollout < 100%)
            └─────┬─────┘
                  │
          ┌───────┼───────┐
          ▼       ▼       ▼
       increase  halt  complete
          │       │       │
          ▼       ▼       ▼
     inProgress halted  completed
                  │       (done)
                  ▼
               resume
                  │
                  ▼
             inProgress
```

## Rollout Commands

| Command | What it does |
|---------|-------------|
| `rollout increase --to N` | Increase percentage to N% |
| `rollout halt` | Stop distribution (users who have it keep it) |
| `rollout resume` | Resume a halted rollout at previous percentage |
| `rollout complete` | Push to 100% |

## Vitals-Gated Rollout (CI)

> **v0.9.74+ behavior change:** `gpc releases rollout increase` now checks crash/ANR thresholds **before** executing the rollout increase. If any threshold is breached, the command exits with code 6 and the rollout percentage is **not changed**. In earlier versions, the vitals check ran after the API call.

```bash
#!/bin/bash
set -e

# Upload to production at 5%
gpc releases upload app.aab --track production --rollout 5

# Wait for crash data
sleep 3600  # 1 hour

# Option A (v0.9.74+): pass thresholds directly — vitals are checked before the increase
# Exits 6 without touching rollout if thresholds are breached
gpc releases rollout increase --track production --to 50 \
  --crash-threshold 2.0 --anr-threshold 0.47

# Option B: explicit pre-check (any version)
gpc vitals crashes --threshold 2.0   # exits 6 if breached
gpc vitals anr --threshold 0.47      # exits 6 if breached
gpc releases rollout increase --track production --to 50
```

## Halting a Rollout

If you detect issues after release:

```bash
# Immediately halt distribution
gpc releases rollout halt --track production

# Investigate
gpc vitals crashes --version <code>

# After fixing, create a new release (don't resume the bad one)
gpc publish fixed-app.aab --track production --rollout 5
```

## Important Notes

- You can only increase rollout percentage, never decrease (except by halting)
- Halting stops new installs but doesn't remove the app from existing users
- Completing a rollout is irreversible
- Each track can have only one active staged rollout
