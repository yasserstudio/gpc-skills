# CI Vitals Gating

## Concept

Use GPC's `--threshold` flag to gate deployments on app quality. If crash rate or ANR rate exceeds the threshold, GPC exits with code 6, failing the CI job.

## Google Play Thresholds

Google Play has official "bad behavior" thresholds that can affect app visibility:

| Metric | Bad Threshold | Recommended Gate |
|--------|--------------|-----------------|
| Crash rate | 1.09% (overall) | 2.0% (conservative) |
| ANR rate | 0.47% (overall) | 0.47% (match Google) |

## Basic Gating

```bash
# Fail if crash rate exceeds 2%
gpc vitals crashes --threshold 2.0

# Fail if ANR rate exceeds 0.47%
gpc vitals anr --threshold 0.47
```

Exit codes:
- `0` — Below threshold (safe to proceed)
- `6` — Threshold breached (block promotion)

## GitHub Actions Pattern

```yaml
jobs:
  check-and-promote:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Check crash rate
        run: gpc vitals crashes --threshold 2.0

      - name: Check ANR rate
        run: gpc vitals anr --threshold 0.47

      - name: Promote to production
        run: gpc releases promote --from beta --to production --rollout 10
```

If either check fails (exit code 6), the "Promote" step is skipped.

## Advanced: Scheduled Vitals Check

Run vitals checks on a schedule to catch regressions:

```yaml
name: Vitals Monitor
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  monitor:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Check vitals
        run: |
          gpc vitals crashes --threshold 2.0
          gpc vitals anr --threshold 0.47

      - name: Alert on failure
        if: failure()
        run: |
          # Send Slack/Discord notification
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -d '{"text":"Vitals threshold breached for com.example.app"}'
```

## Comparing Vitals Over Time

```bash
# Compare this week vs last week
gpc vitals compare crashes --days 7
```

Use this in post-release monitoring to detect regressions.

## Vitals gate on rollout increase (v0.9.74+)

The `--vitals-gate` flag on rollout commands checks thresholds **before** applying the rollout increase. If a threshold is breached the increase is skipped and GPC exits 6. This prevents users from being exposed to a higher rollout percentage while metrics are failing.

```bash
# Safe ramp: only increases if vitals are within thresholds
gpc releases rollout --track production --rollout 50 \
  --vitals-gate --crash-threshold 2.0 --anr-threshold 0.47
```

Staged pipeline pattern:

```yaml
- name: Ramp to 25%
  run: gpc releases rollout --track production --rollout 25 --vitals-gate \
       --crash-threshold 2.0 --anr-threshold 0.47

- name: Ramp to 50%
  if: success()
  run: gpc releases rollout --track production --rollout 50 --vitals-gate \
       --crash-threshold 2.0 --anr-threshold 0.47

- name: Full rollout
  if: success()
  run: gpc releases rollout --track production --rollout 100 --vitals-gate \
       --crash-threshold 2.0 --anr-threshold 0.47
```

**Behavior difference from standalone threshold checks:**

| Approach | When check runs | If breached |
|----------|----------------|-------------|
| `gpc vitals crashes --threshold` | After rollout increase | Increase already applied; halt separately |
| `--vitals-gate` on rollout command | Before rollout increase | Increase never applied; exits 6 immediately |

Use `--vitals-gate` for rollout safety. Use standalone `--threshold` for post-deploy monitoring or CI promotion gates.

## Considerations

- **Data lag:** Vitals data may be delayed by 24-48 hours
- **Volume requirements:** Small apps may not have enough data for meaningful metrics
- **New releases:** Crash data for a new version takes time to accumulate
- **False positives:** A single bad device/OS can spike crash rates temporarily
