# Exit Code Reference

Complete reference for all GPC exit codes and their meaning.

## Exit codes

| Code | Category | Error Class | When |
|------|----------|-------------|------|
| 0 | Success | — | Command completed successfully |
| 1 | Config | `ConfigError` | Invalid config, missing fields, bad .gpcrc.json |
| 2 | Usage | — | Invalid arguments, unknown flags, missing required args |
| 3 | Auth | `AuthError` | Bad credentials, expired token, no auth configured |
| 4 | API | `PlayApiError` | Google Play API returned an error (4xx, 5xx) |
| 5 | Network | `NetworkError` | Connection failed, timeout, DNS error, SSL error |
| 6 | Threshold | — | Vitals metric exceeded `--threshold` value, or no value came back to compare (`THRESHOLD_NO_DATA`, v1.0.0-rc.1+) |
| 10 | Plugin | — | Plugin permission validation failed |

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

## JSON error output

All errors include structured JSON when using `--json`:

```json
{
  "success": false,
  "error": {
    "code": "API_FORBIDDEN",
    "message": "Service account lacks permission to manage production releases",
    "suggestion": "Grant 'Release to production' permission in Play Console → Users & permissions"
  }
}
```

Fields:
- `code` — machine-readable error identifier
- `message` — human-readable description
- `suggestion` — actionable fix (present on all GPC errors)

## Exit code 6 — threshold breach

Rate thresholds are fractions (`0.02` is 2%). A rate threshold of 1 or more is a usage error (`THRESHOLD_INVALID`, exit 2), because a rate never exceeds 1.

This is **not an error** — it's an intentional signal for CI gating.

```bash
# Returns exit 0 if crash rate ≤ 1.5%, exit 6 if > 1.5%
gpc vitals crashes --threshold 0.015

# JSON output includes threshold details
gpc vitals crashes --threshold 0.015 --json
```

```json
{
  "success": false,
  "thresholdBreached": true,
  "value": 2.3,
  "threshold": 1.5
}
```
