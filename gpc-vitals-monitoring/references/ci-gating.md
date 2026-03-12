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

## Considerations

- **Data lag:** Vitals data may be delayed by 24-48 hours
- **Volume requirements:** Small apps may not have enough data for meaningful metrics
- **New releases:** Crash data for a new version takes time to accumulate
- **False positives:** A single bad device/OS can spike crash rates temporarily
