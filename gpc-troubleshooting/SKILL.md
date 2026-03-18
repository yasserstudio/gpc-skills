---
name: gpc-troubleshooting
description: "Use when debugging GPC errors, failures, or unexpected behavior. Make sure to use this skill whenever the user mentions gpc error, gpc failing, exit code, AUTH_FAILED, API_FORBIDDEN, NETWORK_ERROR, CONFIG_MISSING, EDIT_CONFLICT, upload failed, permission denied, timeout, rate limit, gpc doctor failing, unexpected exit code, command not working, GPC crash, debug GPC, verbose output, --json error, threshold breach — even if they don't explicitly say 'troubleshoot.' Also trigger when someone encounters any GPC error they don't understand, when gpc doctor reports issues, when CI pipelines fail with GPC commands, or when they need to interpret exit codes. For auth-specific setup issues, see gpc-setup. For CI-specific issues, see gpc-ci-integration."
compatibility: "GPC v0.9+. Covers all packages: @gpc-cli/cli, @gpc-cli/core, @gpc-cli/api, @gpc-cli/auth, @gpc-cli/config."
metadata:
  version: 0.11.0
---

# gpc-troubleshooting

Unified debugging guide for all GPC errors, exit codes, and common issues.

## When to use

- GPC command fails with an error code
- `gpc doctor` reports issues
- CI pipeline fails with a GPC step
- Unexpected behavior or output
- Need to interpret exit codes
- Need to enable verbose/debug output

## Inputs required

- **Error message or exit code** — what GPC reported
- **Command that failed** — the full command that was run
- **Environment** — local vs CI, OS, Node.js version

## Procedure

### 0. Quick diagnosis

```bash
# Check GPC health
gpc doctor

# Get version info
gpc --version

# Run failing command with verbose output
GPC_DEBUG=1 gpc <failing-command>

# Get error as JSON for parsing
gpc <failing-command> --json
```

`Read:` `references/exit-codes.md` for the complete exit code reference.

### 1. Exit codes

| Code | Category | Meaning |
|------|----------|---------|
| 0 | Success | Command completed successfully |
| 1 | Config | Configuration error (missing .gpcrc.json, invalid fields) |
| 2 | Usage | Invalid arguments or flags |
| 3 | Auth | Authentication failure (expired token, invalid key, no credentials) |
| 4 | API | Google Play API error (403, 404, 409, rate limit) |
| 5 | Network | Connection failure, DNS error, timeout |
| 6 | Threshold | Vitals threshold breached (used in CI gating) |
| 10 | Plugin | Plugin permission validation error |

### 2. Authentication errors (exit code 3)

`Read:` `references/error-catalog.md` for the full error catalog.

| Error | Cause | Fix |
|-------|-------|-----|
| `AUTH_FAILED` | Invalid or corrupted credentials | Re-run `gpc auth login --service-account <key.json>` |
| `AUTH_EXPIRED` | Token expired and refresh failed | Re-authenticate; check network/proxy |
| `AUTH_NO_CREDENTIALS` | No auth configured | Run `gpc auth login` or set `GPC_SERVICE_ACCOUNT` |
| `AUTH_INVALID_KEY` | Malformed service account JSON | Re-download key from Google Cloud Console |
| `AUTH_KEYCHAIN_ERROR` | OS keychain access denied | Grant keychain access or use env var auth |

```bash
# Check current auth status
gpc auth status

# Re-authenticate
gpc auth login --service-account ~/path/to/key.json

# Bypass keychain with env var
export GPC_SERVICE_ACCOUNT=$(cat ~/path/to/key.json)
```

### 3. API errors (exit code 4)

| Error | HTTP | Cause | Fix |
|-------|------|-------|-----|
| `API_FORBIDDEN` | 403 | Insufficient permissions | Grant required roles in Play Console |
| `API_NOT_FOUND` | 404 | App, track, or resource doesn't exist | Verify package name, track name, or resource ID |
| `API_CONFLICT` | 409 | Edit already in progress | Wait and retry; another edit may be open |
| `API_RATE_LIMITED` | 429 | Too many requests | GPC auto-retries; increase `GPC_BASE_DELAY` |
| `API_SERVER_ERROR` | 5xx | Google server issue | Retry later; check Google status dashboard |
| `EDIT_CONFLICT` | 409 | Concurrent edit from another tool/user | Only one edit at a time; check if Fastlane or Play Console has an open edit |

```bash
# Check if an edit is stuck
gpc apps list --json

# API errors include suggestion field
gpc releases upload app.aab --track beta --json 2>&1 | jq '.error'
```

### 4. Network errors (exit code 5)

| Error | Cause | Fix |
|-------|-------|-----|
| `NETWORK_ERROR` | Connection failed | Check internet; check proxy settings |
| `NETWORK_TIMEOUT` | Request timed out | Increase `GPC_TIMEOUT` (default 30000ms) |
| `NETWORK_DNS` | DNS resolution failed | Check DNS settings; try Google DNS (8.8.8.8) |
| `NETWORK_SSL` | SSL/TLS handshake failed | Set `GPC_CA_CERT` for custom CA; check proxy |

```bash
# Increase timeout for large uploads
export GPC_TIMEOUT=120000

# Configure retry behavior
export GPC_MAX_RETRIES=5
export GPC_BASE_DELAY=2000
export GPC_MAX_DELAY=30000

# Corporate proxy
export HTTPS_PROXY=http://proxy.corp:8080

# Custom CA certificate
export GPC_CA_CERT=/path/to/ca-cert.pem
```

### 5. Configuration errors (exit code 1)

| Error | Cause | Fix |
|-------|-------|-----|
| `CONFIG_MISSING` | No .gpcrc.json or env vars | Run `gpc config init` |
| `CONFIG_INVALID` | Malformed .gpcrc.json | Validate JSON syntax |
| `CONFIG_APP_MISSING` | No app specified | Set with `gpc config set app` or `--app` flag |

```bash
# Initialize config
gpc config init

# Set required values
gpc config set app com.example.app

# Check current config
gpc config list
```

### 6. Upload and release errors

| Error | Cause | Fix |
|-------|-------|-----|
| `INVALID_BUNDLE` | AAB is corrupted or wrong format | Rebuild the AAB; run `gpc validate` first |
| `VERSION_CODE_CONFLICT` | Version code already used | Increment versionCode in build.gradle |
| `RELEASE_NOT_FOUND` | No release on the specified track | Check track name; use `gpc releases list --track <track>` |
| `ROLLOUT_INVALID` | Invalid rollout percentage | Use 0-100 (not 0.0-1.0); use `--rollout 10` not `--rollout 0.1` |
| `PROMOTE_NO_SOURCE` | Source track has no release to promote | Upload to source track first |

```bash
# Validate before uploading
gpc validate app.aab

# Check existing releases
gpc releases list --track internal
gpc releases list --track beta

# Preview upload
gpc releases upload app.aab --track beta --dry-run
```

### 7. Vitals threshold breach (exit code 6)

Exit code 6 is **not an error** — it's an intentional signal that a vitals metric exceeded the threshold. Used for CI gating.

```bash
# This exits 6 if crash rate > 2.0%
gpc vitals crashes --threshold 2.0

# Check the actual value
gpc vitals crashes --json | jq '.crashRate'

# In CI, use exit code to gate promotion
gpc vitals crashes --threshold 1.5 && gpc releases promote --from beta --to production
```

### 8. Plugin errors (exit code 10)

| Error | Cause | Fix |
|-------|-------|-----|
| `PLUGIN_INVALID_PERMISSION` | Third-party plugin declares unknown permission | Check valid permissions in plugin-sdk docs |
| Plugin not loading | Not in config or not approved | Add to `plugins` and `approvedPlugins` in .gpcrc.json |
| Plugin error in hook | Bug in plugin handler | Check plugin logs; `onError`/API hooks swallow errors |

### 9. Debug mode

Enable verbose output for any command:

```bash
# Debug environment variable
GPC_DEBUG=1 gpc releases upload app.aab --track beta

# JSON output for machine parsing
gpc releases upload app.aab --track beta --json

# Combine for maximum detail
GPC_DEBUG=1 gpc releases upload app.aab --track beta --json 2>debug.log
```

## Verification

- `gpc doctor` passes all checks
- Failing command now succeeds or shows a clear, actionable error
- Exit code matches the expected category
- `--json` output includes `error.code`, `error.message`, and `error.suggestion`

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `gpc doctor` fails on auth | Credentials not configured | Run `gpc auth login` |
| `gpc doctor` fails on API | Service account lacks API access | Enable Google Play Developer API in GCP |
| All commands timeout | Network/proxy issue | Check `HTTPS_PROXY`, `GPC_CA_CERT`, `GPC_TIMEOUT` |
| Commands work locally, fail in CI | Missing env vars in CI | Set `GPC_SERVICE_ACCOUNT` and `GPC_APP` in CI secrets |
| JSON output has no `suggestion` | Unexpected error type | File a bug — all errors should have suggestions |

## Related skills

- **gpc-setup** — initial auth and config setup
- **gpc-ci-integration** — CI-specific troubleshooting
- **gpc-vitals-monitoring** — understanding threshold breaches
- **gpc-plugin-development** — debugging plugin issues
