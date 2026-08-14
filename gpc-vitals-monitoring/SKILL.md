---
name: gpc-vitals-monitoring
description: "Use when monitoring Android app health metrics from Google Play. Make sure to use this skill whenever the user mentions gpc vitals, gpc watch, gpc status, crash rate, ANR rate, startup time, Android vitals, crash monitoring, threshold alerting, vitals gating, rollout monitoring, auto-halt, breach notification, webhook alerting, frame rate, battery usage, memory issues, error tracking, app quality, user reviews, review replies, Play Store reviews, star rating, negative reviews, review export, financial reports, stats reports, gpc reports, reports list, reports download, bulk reports, earnings report, sales report, play balance, installs report, subscriptions report, reports bucket, GPC_REPORTS_BUCKET, pubsite_prod, REPORT_ACCESS_DENIED, download bulk reports permission, or wants to check app health, monitor a staged rollout, respond to reviews, or download Play Console reports. Also trigger when someone asks about gating deployments on crash data, monitoring app performance after a release, watching a rollout for regressions, or tracking review sentiment — even if they don't mention GPC. For releases, see gpc-release-flow. For CI gating, see gpc-ci-integration."
compatibility: "GPC v0.9.82+. Requires authenticated GPC setup (see gpc-setup skill). Vitals data requires the app to have sufficient install volume. v0.9.83+ adds reviews fidelity fields and the unified list envelope. v0.9.93+ downloads Play bulk reports live from the account's Cloud Storage bucket (needs the 'View app information and download bulk reports (read-only)' grant on the service account)."
metadata:
  version: 1.9.1
---

# GPC Vitals Monitoring

## When to use

Use this skill when the task involves:

- Real-time rollout monitoring with `gpc watch` (multi-metric, auto-actions)
- Monitoring crash rates, ANR rates, and other Android Vitals metrics
- Setting up threshold-based alerting for CI/CD
- Tracking app startup times, frame rates, battery, and memory
- Reviewing and responding to user reviews
- Building monitoring pipelines with GPC output
- Comparing vitals across time periods
- Investigating error issues and anomalies
- Downloading Play bulk reports (installs, crashes, ratings, earnings, subscriptions) as CSV

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

### Low-Memory-Killer rate (`gpc vitals lmk`, v0.9.58+, corrected in v0.9.59)

Background: v0.9.58 shipped a misnamed resource (`lowMemoryKillerRateMetricSet`) that 404'd. **v0.9.59 is the working build** — the real Google resource is `lmkRateMetricSet` with metrics `userPerceivedLmkRate`, `userPerceivedLmkRate7dUserWeighted`, `userPerceivedLmkRate28dUserWeighted`, and `distinctUsers`. Use v0.9.59+ for LMK queries.

```bash
gpc vitals lmk --app com.example.app --since 7d
```

Supports the same flags as other vitals subcommands: `--days <n>`, `--threshold <value>`, `--json`.

**Note:** Vitals memory data accuracy was improved in v0.9.41 (Bug H: metric field names corrected from `stuckBackground` to `stuckBg`).

### Count of error occurrences (`gpc vitals error-count`, v0.9.57+)

`gpc vitals error-count` returns a time-windowed count of error-issue occurrences from the Play Developer Reporting API. Use for CI gates when you want an absolute count rather than a rate.

```bash
gpc vitals error-count --app com.example.app --since 7d
gpc vitals error-count --app com.example.app --since 7d --threshold 100
```

Exits 6 if the count exceeds --threshold (same CI convention as other vitals commands).

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

**Freshness clamping (v0.9.70+):** Google's vitals data typically lags 3-4 days behind real-time. GPC now queries the freshness endpoint for each metric set before running any vitals query and automatically clamps the date range. This prevents `400 INVALID_ARGUMENT` errors that previously occurred when the requested date range exceeded Google's available data window. No configuration needed.

### 4b) Real-time rollout monitoring (`gpc watch`, v0.9.67+)

`gpc watch` is the unified rollout monitoring command. It polls rollout status (near real-time) and vitals data (24-48h delayed) on an interval, checks thresholds, and takes action on breach.

```bash
# Basic: monitor crashes + ANR on production, poll every 15 minutes
gpc watch

# Watch a beta rollout with tighter thresholds
gpc watch --track beta --crash-threshold 0.015 --anr-threshold 0.005

# Auto-halt the rollout on any threshold breach
gpc watch --on-breach halt

# Notify + halt + send webhook on breach
gpc watch --on-breach notify,halt,webhook \
  --webhook-url https://hooks.slack.com/services/XXX

# CI mode: 3 rounds, 5-minute interval, NDJSON output
gpc watch --rounds 3 --interval 300 --json

# Monitor all 6 metrics
gpc watch --metrics crashes,anr,lmk,slowStarts,slowRender,errorCount
```

**Six metrics:** `crashes`, `anr`, `lmk`, `slowStarts`, `slowRender`, `errorCount`.

**Three breach actions** (combinable with `--on-breach`):
- `notify` — OS notification (macOS, Linux, Windows)
- `halt` — halt the active rollout via Google Play API
- `webhook` — POST breach event as JSON to `--webhook-url`

**Thresholds** resolve in priority order: CLI flags > `.gpcrc.json` `vitals.thresholds.*` > defaults (crash 2%, ANR 1%, LMK 3%, slow start 5%, slow render 10%).

**Auto-stop:** the watch loop stops when the rollout reaches 100%, a breach triggers halt, `--rounds` limit is hit, or Ctrl+C.

**Exit codes:** 0 = clean, 6 = at least one threshold breached.

**Webhook payload:**
```json
{
  "type": "breach",
  "round": 3,
  "rollout": { "track": "production", "versionCode": "142", "userFraction": 0.1 },
  "vitals": { "crashes": { "value": 0.025, "threshold": 0.02, "breached": true } },
  "breaches": ["crashes"],
  "halted": true
}
```

Set the webhook URL in config to avoid passing it every time:
```json
{
  "webhooks": { "watch": "https://hooks.slack.com/services/XXX" }
}
```

> **Note:** `gpc vitals watch` (single-metric watcher) still works but `gpc watch` is the recommended command for rollout monitoring as of v0.9.67.

### 5) Error tracking and anomalies

```bash
# Detected anomalies
gpc vitals anomalies

# Error issues and reports
gpc vitals errors search
```

> **New in v0.9.47:** If the Reporting API is not enabled for your GCP project, vitals and anomalies commands now show a helpful message with the enable URL instead of a raw 403 error. Non-vitals commands continue to work normally.

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

# Full text of truncated reviews (v0.9.83+)
gpc reviews list --full-text

# Single review details
gpc reviews get <review-id>

# Reply to a review (max 350 chars — validated before sending)
gpc reviews reply <review-id> --text "Thank you for your feedback"

# Auto-paginate all reviews (API returns max 10 per page by default)
gpc reviews list --all

# Start from a specific index (for manual pagination)
gpc reviews list --start-index 20

# Export reviews
gpc reviews export --format csv --output-file reviews.csv
```

> **New in v0.9.47:** `--all` auto-paginates through all review pages. Reply text is validated against the 350-character Google Play limit before sending — exceeding the limit exits code 2 immediately. Note: the Reviews API only returns production reviews from the last 7 days.

> **New in v0.9.83:** `reviews list` adds `hasReply`, `lang`, and an explicit `[truncated]` marker to each review, plus a `--full-text` flag that fetches the complete untruncated text. `reviews list --json` uses the unified `{ reviews, nextPageToken, meta.count }` envelope (breaking for scripts reading a bare array).

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

### 8a) Vitals gate on rollout increase (`--vitals-gate`, v0.9.74+)

The `--vitals-gate` flag on rollout commands checks crash and ANR thresholds **before** increasing the rollout percentage. If any threshold is breached, the increase is skipped entirely and GPC exits with code 6. No users are exposed to the higher percentage while metrics are failing.

**Previous behavior (before v0.9.74):** GPC increased the rollout percentage first, then checked vitals and halted if thresholds were breached. This left users on the new, higher percentage during the breach window.

**New behavior (v0.9.74+):** GPC checks vitals first. If thresholds are breached, the rollout increase never happens.

```bash
# Increase rollout only if crash and ANR rates are within thresholds
gpc releases rollout --track production --rollout 50 \
  --vitals-gate --crash-threshold 2.0 --anr-threshold 0.47

# Use in a staged rollout script
gpc releases rollout --track production --rollout 10 --vitals-gate
gpc releases rollout --track production --rollout 25 --vitals-gate
gpc releases rollout --track production --rollout 50 --vitals-gate
gpc releases rollout --track production --rollout 100 --vitals-gate
```

Exit code 6 means a vitals threshold was breached and the rollout increase was **not** applied. Exit code 0 means vitals passed and the rollout was increased.

In CI, use `if: success()` guards to stop the pipeline at the first failing gate:

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

Threshold defaults (if flags are omitted): crash 2%, ANR 0.47%. Override via `.gpcrc.json` `vitals.thresholds.*`.

Read:
- `references/ci-gating.md`

### 8b) Vitals gate crash-rate fix (v0.9.82)

The vitals gate crash-rate check on `rollout increase` (the `--vitals-gate` flag) was silently skipping the check in earlier versions. The root cause: GPC was accessing a `.data` field on the `MetricSetResponse` shape returned by the Reporting API, but that field does not exist. As a result, the gate always passed regardless of crash rate.

The fix in v0.9.82 reads `rows[last].metrics[firstMetric].decimalValue.value`, which matches how `gpc train` reads crash rates from the same API. Upgrading to v0.9.82+ is required for the `--vitals-gate` crash-rate check to work correctly.

### 8c) VitalsThresholds in config (v0.9.82)

`VitalsThresholds` is now a formally typed field in `GpcConfig` and `ResolvedConfig` in `@gpc-cli/config`. Set thresholds project-wide in `.gpcrc.json`:

```json
{
  "vitals": {
    "thresholds": {
      "crashRate": 2.0,
      "anrRate": 0.5
    }
  }
}
```

These values are used as defaults by `--vitals-gate`, `gpc watch`, and `gpc vitals crashes/anr --threshold`. CLI flags still take priority over config.

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

### 11) Reports: bulk CSV downloads (live since v0.9.93)

Play delivers monthly bulk reports as CSV files in a Google Cloud Storage bucket linked to the developer account, not through the Publisher API. Since GPC v0.9.93 `gpc reports` reads that bucket directly with the same service account; before v0.9.93 these commands only printed guidance about where the data lived.

**Required one-time grant.** Play does not give a service account access to the reports bucket automatically: it grants that bucket to your own user login only. In **Play Console -> Users and permissions -> the service account -> Account permissions**, enable **"View app information and download bulk reports (read-only)"**, then allow a few minutes for it to propagate. Without it every reports command fails with `REPORT_ACCESS_DENIED` (exit 4). Check it with `gpc doctor`, which has a `reports-bucket` probe that warns when the grant is missing.

**Bucket resolution.** The default is `pubsite_prod_<developerId>`, derived from the `developerId` config key or `GPC_DEVELOPER_ID`. If the account's bucket differs, copy the exact Cloud Storage URI from Play Console -> Download reports and override it:

| Setting         | How to set it                                        |
|-----------------|------------------------------------------------------|
| Flag (wins)     | `--bucket pubsite_prod_1234567890`                   |
| Env             | `GPC_REPORTS_BUCKET=pubsite_prod_1234567890`         |
| Config          | `"reports": { "bucket": "pubsite_prod_1234567890" }` |
| Derived default | `developerId` / `GPC_DEVELOPER_ID`                   |

```bash
# List report files for a type, optionally narrowed to one month
gpc reports list installs --app com.example.myapp --month 2026-02
gpc reports list earnings --month 2026-02
gpc reports list crashes --app com.example.myapp --limit 20 --next-page <token>

# Stats reports (per app), decoded UTF-8 CSV on stdout
gpc reports download stats --app com.example.myapp --month 2026-02 --type installs
gpc reports download stats --app com.example.myapp --month 2026-02 --type crashes \
  --dimension country --output-file crashes-2026-02.csv

# Financial reports (account-level, no --app)
gpc reports download financial --month 2026-02 --type earnings
gpc reports download financial --month 2026-02 --type play_balance \
  --output-file balance-2026-02.csv
```

`reports list <report-type>` takes a single report type (not `stats` / `financial`), and returns the same `--json` envelope as the other list commands: `{ reports, nextPageToken, meta.count, message? }`. Stats types are narrowed to the configured app; financial types are account-level.

Report types. Financial: `earnings`, `sales`, `estimated_sales`, `play_balance`. Stats: `installs`, `crashes`, `ratings`, `reviews`, `store_performance`, `subscriptions`. `sales` and `estimated_sales` are two names for the same Play report and return identical data.

Dimensions (`--dimension`, stats only, default `overview`): `overview`, `country`, `language`, `os_version`, `device`, `app_version`, `carrier`, `traffic_source`. Play publishes one CSV per dimension per month; reviews reports have no dimension. If the requested dimension does not exist for that month, the error lists the ones that do.

Encoding and archives: Play stores these objects gzip-compressed and UTF-16 encoded. GPC decompresses and re-encodes to UTF-8 text, so output pipes straight into standard CSV tools. Financial reports arrive as ZIP archives: a single-CSV archive is unwrapped automatically; a multi-CSV archive needs `--output-file report.zip` (saves the raw archive) or `--json`, which inlines every entry.

With `--json`, the download commands emit one of three envelopes:

```json
{ "objectName": "...", "csv": "..." }
{ "objectName": "...", "outputFile": "...", "bytes": 1234 }
{ "objectName": "...", "entries": [{ "name": "...", "csv": "..." }] }
```

Least privilege: only the reports commands (and the matching `gpc doctor` probe) request the `devstorage.read_only` scope, and storage-scoped tokens are cached separately, so no other command's token carries storage access. `gpc auth clear-cache` drops cached tokens without removing credentials if a freshly granted permission is not visible yet.

Error codes specific to this path: `REPORT_ACCESS_DENIED` (4, missing grant), `REPORT_BUCKET_UNKNOWN` / `REPORT_BUCKET_INVALID` (2), `REPORT_BUCKET_NOT_FOUND` (4), `REPORT_OBJECT_NOT_FOUND` (4), `REPORT_AUTH_REJECTED` (3). Full list in gpc-troubleshooting.

## Verification

- `gpc status` shows all three sections (releases, vitals, reviews) without errors
- `gpc watch --rounds 1` completes one polling round without errors
- `gpc vitals overview` returns data (requires sufficient install volume)
- Threshold commands return exit code 0 (OK) or 6 (breached)
- `gpc reviews list` returns recent reviews
- JSON output is parseable: `gpc vitals crashes --output json | jq .`
- `gpc doctor` shows `reports-bucket` as a pass (the bulk-reports grant is in place)
- `gpc reports list installs --month <last full month>` returns at least one object

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No vitals data | App has insufficient installs | Vitals require significant install volume; small apps may not have data |
| `--threshold` always passes | Threshold too high | Check current crash rate with `gpc vitals crashes` first, then set appropriate threshold |
| Reviews API rate limit | Too many requests | Reviews API: 200 GET/hour, 2,000 POST/day. Space out requests. |
| Reports not found | Wrong month format | Use `YYYY-MM` format (e.g., `2026-02`) |
| `REPORT_ACCESS_DENIED` on any reports command | The service account lacks the bulk-reports grant | Play Console -> Users and permissions -> the service account -> Account permissions -> enable "View app information and download bulk reports (read-only)", wait a few minutes, then `gpc auth clear-cache` and retry |
| `REPORT_BUCKET_UNKNOWN` | No `developerId` and no explicit bucket | Set `developerId` / `GPC_DEVELOPER_ID`, or pass `--bucket` / `GPC_REPORTS_BUCKET` / `reports.bucket` |
| `REPORT_BUCKET_NOT_FOUND` | Account's bucket is not `pubsite_prod_<developerId>` | Copy the exact Cloud Storage URI from Play Console -> Download reports and set it with `--bucket` |
| `REPORT_OBJECT_NOT_FOUND` with a dimension | That dimension is not published for the month | The error lists the dimensions that exist; reviews reports have no dimension |
| Report month returns nothing | Month is not finished | Play publishes a month's reports after it ends; use the last complete month |
| Multi-CSV financial archive refuses to print | `REPORT_MULTIPLE_ENTRIES` | Save the archive with `--output-file report.zip`, or use `--json` to inline every entry |
| Empty crash clusters | New release | Crash data takes time to aggregate; check again in 24-48 hours |

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-release-flow**: Upload and rollout management
- **gpc-ci-integration**: Automated vitals checks in CI
