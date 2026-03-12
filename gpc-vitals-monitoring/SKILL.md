---
name: gpc-vitals-monitoring
description: "Use when monitoring Android app health metrics from Google Play. Make sure to use this skill whenever the user mentions gpc vitals, crash rate, ANR rate, startup time, Android vitals, crash monitoring, threshold alerting, vitals gating, frame rate, battery usage, memory issues, error tracking, app quality, user reviews, review replies, Play Store reviews, star rating, negative reviews, review export, financial reports, stats reports, or wants to check app health, respond to reviews, or download Play Console reports. Also trigger when someone asks about gating deployments on crash data, monitoring app performance after a release, or tracking review sentiment — even if they don't mention GPC. For releases, see gpc-release-flow. For CI gating, see gpc-ci-integration."
compatibility: "GPC v0.9.9+. Requires authenticated GPC setup (see gpc-setup skill). Vitals data requires the app to have sufficient install volume."
metadata:
  version: 1.0.0
---

# GPC Vitals Monitoring

## When to use

Use this skill when the task involves:

- Monitoring crash rates, ANR rates, and other Android Vitals metrics
- Setting up threshold-based alerting for CI/CD
- Tracking app startup times, frame rates, battery, and memory
- Reviewing and responding to user reviews
- Building monitoring pipelines with GPC output
- Comparing vitals across time periods
- Investigating error issues and anomalies

## Inputs required

- Package name (or configured default)
- Metric type(s) to monitor (crashes, ANR, startup, rendering, battery, memory)
- Version code (optional — for filtering by release)
- Threshold values (for CI alerting)

## Procedure

### 0) Vitals overview dashboard

Get a high-level summary of all vitals:

```bash
gpc vitals overview
```

### 1) Crash monitoring

```bash
# Crash rate and top clusters
gpc vitals crashes

# Filter by version code
gpc vitals crashes --version 142

# CI threshold alerting — exit code 6 if crash rate exceeds threshold
gpc vitals crashes --threshold 2.0
```

Exit code 6 means threshold was breached — use this to gate deployments.

### 2) ANR monitoring

```bash
gpc vitals anr
gpc vitals anr --version 142
gpc vitals anr --threshold 0.47  # Google's bad behavior threshold
```

### 3) Performance metrics

```bash
# Cold/warm startup times
gpc vitals startup

# Frame rate / rendering
gpc vitals rendering

# Battery usage
gpc vitals battery

# Low memory killer rate
gpc vitals memory
```

### 4) Error tracking and anomalies

```bash
# Detected anomalies
gpc vitals anomalies

# Error issues and reports
gpc vitals errors search

# Compare metrics: this week vs last week
gpc vitals compare crashes --days 7
```

### 5) Review monitoring

```bash
# Recent reviews
gpc reviews list

# Filter by rating
gpc reviews list --stars 1-2

# Filter by language
gpc reviews list --lang en

# Filter by time
gpc reviews list --since 7d

# Single review details
gpc reviews get <review-id>

# Reply to a review
gpc reviews reply <review-id> "Thank you for your feedback"
gpc reviews reply <review-id> --file reply.txt

# Export reviews
gpc reviews export --format csv --output reviews.csv
```

Read:
- `references/review-management.md`

### 6) Threshold-based CI gating

Use `--threshold` to gate rollouts on vitals quality:

```bash
# Gate on crash rate (exits with code 6 if breached)
gpc vitals crashes --threshold 2.0

# Gate on ANR rate
gpc vitals anr --threshold 0.47

# Combine in a script
gpc vitals crashes --threshold 2.0 && \
gpc vitals anr --threshold 0.47 && \
echo "Vitals OK — safe to promote"
```

In CI, use exit code 6 to block promotion:
```yaml
- name: Check vitals before promotion
  run: |
    gpc vitals crashes --threshold 2.0
    gpc vitals anr --threshold 0.47
- name: Promote to production
  if: success()
  run: gpc releases promote --from beta --to production --rollout 10
```

Read:
- `references/ci-gating.md`

### 7) Monitoring pipelines

Pipe JSON output to your monitoring stack:

```bash
# Send crash data to your monitoring tool
gpc vitals crashes --output json | jq '.data' | curl -X POST ...

# Periodic check (cron)
gpc vitals overview --output json >> /var/log/gpc-vitals.jsonl
```

### 8) Reports

```bash
# List available reports
gpc reports list financial --month 2026-02
gpc reports list stats --month 2026-02

# Download reports
gpc reports download financial --month 2026-02
gpc reports download stats --month 2026-02 --type installs --output-file installs.csv
```

Report types — financial: `earnings`, `estimated_sales`, `play_balance`. Stats: `installs`, `crashes`, `ratings`, `reviews`, `store_performance`.

## Verification

- `gpc vitals overview` returns data (requires sufficient install volume)
- Threshold commands return exit code 0 (OK) or 6 (breached)
- `gpc reviews list` returns recent reviews
- JSON output is parseable: `gpc vitals crashes --output json | jq .`

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No vitals data | App has insufficient installs | Vitals require significant install volume; small apps may not have data |
| `--threshold` always passes | Threshold too high | Check current crash rate with `gpc vitals crashes` first, then set appropriate threshold |
| Reviews API rate limit | Too many requests | Reviews API: 200 GET/hour, 2,000 POST/day. Space out requests. |
| Reports not found | Wrong month format | Use `YYYY-MM` format (e.g., `2026-02`) |
| Empty crash clusters | New release | Crash data takes time to aggregate; check again in 24-48 hours |

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-release-flow**: Upload and rollout management
- **gpc-ci-integration**: Automated vitals checks in CI
