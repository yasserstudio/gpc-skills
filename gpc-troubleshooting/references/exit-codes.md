# Exit Code Reference

Complete reference for all GPC exit codes and their meaning.

## Exit codes

| Code | Category | Error Class | When |
|------|----------|-------------|------|
| 0 | Success | — | Command completed successfully |
| 1 | Config / general | `ConfigError`, `PluginError` | Invalid config, missing fields, bad .gpcrc.json, plugin permission or runtime failure (`PLUGIN_*`) |
| 2 | Usage | — | Invalid arguments, unknown flags, missing required args |
| 3 | Auth | `AuthError` | Bad credentials, expired token, no auth configured |
| 4 | API | `PlayApiError` | Google Play API returned an error (4xx, 5xx) |
| 5 | Network | `NetworkError` | Connection failed, timeout, DNS error, SSL error |
| 6 | Threshold | — | Vitals metric exceeded `--threshold` value, or no value came back to compare (`THRESHOLD_NO_DATA`, v1.0.0-rc.1+) |

Since v1.0.0-rc.1, a usage mistake such as an unknown option or a missing argument exits 2, as this table has always said. Those exited 1 before, so a CI job that branched on `1` for config problems may now see `2` instead. Two other changes in the same release affect scripted exits: a vitals or anomalies 403 exits 4 instead of printing "no data" and exiting 0, and a refund or revocation run without a terminal and without `--yes` exits 2 with `CONFIRMATION_REQUIRED`.

## Using exit codes in scripts

```bash
# Simple check
gpc vitals crashes --threshold 0.02
if [ $? -eq 6 ]; then
  echo "Crash rate too high — blocking promotion"
  exit 1
fi

# Case statement
gpc releases upload app.aab --track beta
case $? in
  0) echo "Upload successful" ;;
  3) echo "Auth failed — re-authenticate" ;;
  4) echo "API error — check permissions" ;;
  5) echo "Network error — check connectivity" ;;
  *) echo "Unknown error" ;;
esac
```

## Using exit codes in CI

### GitHub Actions

```yaml
- name: Check vitals
  id: vitals
  continue-on-error: true
  run: gpc vitals crashes --threshold 0.015

- name: Block if threshold breached
  if: steps.vitals.outcome == 'failure'
  run: |
    echo "Vitals check failed — blocking deployment"
    exit 1
```

### GitLab CI

```yaml
check-vitals:
  script:
    - gpc vitals crashes --threshold 0.015
    - gpc vitals anr --threshold 0.004
  allow_failure: false  # Block pipeline on exit code != 0
```

## Error output

Errors are never JSON, not even with `--json`. They print to stderr as plain text, stdout stays empty, and the exit code carries the category:

```text
Error [API_FORBIDDEN]: Service account lacks permission to manage production releases
Suggestion: Grant 'Release to production' permission in Play Console → Users & permissions
```

Lines:
- `Error [CODE]` -- machine-readable error identifier plus the message (always present)
- `Suggestion:` -- actionable fix (when available)
- `Details:` -- extra context, such as Google's own message (when available)

To branch on a specific error, match the code in stderr:

```bash
if ! gpc releases status --json 2> status.err; then
  grep -q 'Error \[API_APP_NOT_FOUND\]' status.err && echo "App has no Play listing"
fi
```

## Exit code 6 — threshold breach

Rate thresholds are fractions (`0.02` is 2%). A rate threshold of 1 or more is a usage error (`THRESHOLD_INVALID`, exit 2), because a rate never exceeds 1.

This is **not an error** — it's an intentional signal for CI gating.

```bash
# Returns exit 0 if crash rate ≤ 1.5%, exit 6 if > 1.5%
gpc vitals crashes --threshold 0.015
```

The breach itself is reported on stderr, while stdout keeps the metric output:

```text
✗ Threshold breached: 0.023 > 0.015
```

With `--json`, stdout is Google's own Play Developer Reporting rows (`{ "rows": [...] }`, values as strings), so gate on the exit code rather than parsing them. For the rate as a number, read `gpc status --json` (`.vitals.crashes.value`, a fraction); it also exits 6 on a breach, so under `set -e` call it as `gpc status --json || true`.
