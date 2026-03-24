---
name: gpc-vitals-monitoring
description: "Use when monitoring Android app health metrics from Google Play. Make sure to use this skill whenever the user mentions gpc vitals, gpc status, crash rate, ANR rate, startup time, Android vitals, crash monitoring, threshold alerting, vitals gating, frame rate, battery usage, memory issues, error tracking, app quality, user reviews, review replies, Play Store reviews, star rating, negative reviews, review export, financial reports, stats reports, or wants to check app health, respond to reviews, or download Play Console reports. Also trigger when someone asks about gating deployments on crash data, monitoring app performance after a release, or tracking review sentiment — even if they don't mention GPC. For releases, see gpc-release-flow. For CI gating, see gpc-ci-integration."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill). Vitals data requires the app to have sufficient install volume."
metadata:
  version: 1.1.0
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

### 0) Unified health snapshot — start here

The fastest way to see the full picture: releases, vitals, and reviews in one command.

```bash
gpc status
```

Output:
```
App: com.example.myapp · My App  (fetched 10:42:01 AM)

RELEASES
  production   v1.4.2   completed    —
  beta         v1.5.0   inProgress  10%

VITALS  (last 7 days)
  crashes     0.80%  ✓    anr         0.20%  ✓
  slow starts 2.10%  ✓    slow render 4.30%  ⚠

REVIEWS  (last 30 days)
  ★ 4.6   142 new   89% positive   ↑ from 4.4
```

6 parallel API calls, result in under 3 seconds. Cached for 1 hour.

```bash
gpc status --days 14          # Wider vitals window
gpc status --cached           # Instant — no API calls (uses last fetch)
gpc status --refresh          # Force live fetch, ignore cache
gpc status --output json      # Full structured output for scripts
```

Exit code 6 if any vitals threshold is breached — use as a deployment gate.

### 1) Per-metric vitals dashboard

For per-metric details beyond what `gpc status` shows:

```bash
gpc vitals overview
```

### 2) Crash monitoring

```bash
# Crash rate and top clusters
gpc vitals crashes

# Filter by version code
gpc vitals crashes --version 142

# CI threshold alerting — exit code 6 if crash rate exceeds threshold
gpc vitals crashes --threshold 2.0
```

Exit code 6 means threshold was breached — use this to gate deployments.

### 3) ANR monitoring

```bash
gpc vitals anr
gpc vitals anr --version 142
gpc vitals anr --threshold 0.47  # Google's bad behavior threshold
```

### 4) Performance metrics

```bash
# Cold/warm startup times (auto-includes startType as a required dimension)
gpc vitals startup

# Frame rate / rendering
gpc vitals rendering

# Battery usage
gpc vitals battery

# Low memory killer rate
gpc vitals memory

# Wakeup time metric (low-memory killer)
gpc vitals wakeup

# Low memory killer stats (LMK)
gpc vitals lmk
```

`gpc vitals wakeup` shows the wakeup rate from low-memory kills (LMK events). Supports the same flags as other vitals subcommands: `--days <n>`, `--threshold <value>`, `--json`.

`gpc vitals lmk` shows low memory killer statistics. Columns: `stuckBgWakelockRate`, `stuckBgWakelockRate7dUserWeighted`, `stuckBgWakelockRate28dUserWeighted`, `distinctUsers`. Supports the same flags as other vitals subcommands: `--days <n>`, `--threshold <value>`, `--json`.

**Note:** Vitals lmk/memory data accuracy was improved in v0.9.41 (Bug H: metric field names corrected from `stuckBackground` to `stuckBg`).

### 4a) Compare vitals across versions

Side-by-side comparison of two version codes across all key metrics:

```bash
gpc vitals compare-versions <v1> <v2>

# Example
gpc vitals compare-versions 141 142

# Wider time window
gpc vitals compare-versions 141 142 --days 14

# JSON output for scripting
gpc vitals compare-versions 141 142 --json

# Markdown table (for GitHub comments, Slack, etc.)
gpc vitals compare-versions 141 142 --format markdown
```

Compares: crash rate, ANR rate, startup time, rendering, battery, and memory. Uses non-overlapping 7-day windows for each version. Regressions are highlighted in red in terminal output.

**Note:** `gpc vitals compare-versions` uses non-overlapping 7-day windows, both capped 2 days before today to account for API data lag.

### 4b) Continuous monitoring with auto-halt

Background monitoring that polls vitals on an interval and automatically halts a rollout if any threshold is breached:

```bash
gpc vitals watch

# With auto-halt on threshold breach
gpc vitals watch --auto-halt-rollout

# Custom poll interval (default: 300 seconds)
gpc vitals watch --interval 60 --auto-halt-rollout

# Scope to a specific track and threshold
gpc vitals watch \
  --track production \
  --threshold crash_rate=2.0 \
  --threshold anr_rate=0.47 \
  --auto-halt-rollout
```

Flags:
- `--interval <seconds>` — poll interval (default: 300)
- `--threshold <metric=value>` — breach threshold per metric; repeatable
- `--auto-halt-rollout` — automatically calls `gpc releases rollout halt` when any threshold is breached
- `--package <name>` — override package name
- `--track <name>` — which track to monitor (default: production)

`gpc vitals watch` runs in the foreground only. Press Ctrl+C (SIGINT) to stop.

### 5) Error tracking and anomalies

```bash
# Detected anomalies
gpc vitals anomalies

# Error issues and reports
gpc vitals errors search
```

### 6) Review sentiment analysis

Local NLP-based sentiment analysis of reviews — no external API required:

```bash
gpc reviews analyze

# Filter by date range
gpc reviews analyze --since 2026-01-01
gpc reviews analyze --days 30

# Filter by language
gpc reviews analyze --lang en

# JSON output
gpc reviews analyze --json

# Markdown report (for GitHub, Confluence, etc.)
gpc reviews analyze --format markdown
```

Output includes:
- Sentiment trend over time (positive/neutral/negative)
- Topic clustering (what users talk about most)
- Keyword frequency table
- Rating distribution broken down by version

All processing is local — no third-party NLP service is called.

### 7) Review monitoring

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

### 8) Threshold-based CI gating

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

### 9) Reporting API rate limit

The Play Developer Reporting API is rate-limited to **10 queries per second**. GPC handles this automatically — if you hit the limit, requests are queued and retried with backoff. No configuration needed.

### 10) Monitoring pipelines

Pipe JSON output to your monitoring stack:

```bash
# Send crash data to your monitoring tool
gpc vitals crashes --output json | jq '.data' | curl -X POST ...

# Periodic check (cron)
gpc vitals overview --output json >> /var/log/gpc-vitals.jsonl
```

### 11) Reports

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

- `gpc status` shows all three sections (releases, vitals, reviews) without errors
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
