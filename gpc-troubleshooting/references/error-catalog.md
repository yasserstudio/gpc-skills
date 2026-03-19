# Error Catalog

All known GPC error codes with causes and fixes.

## Authentication errors (exit code 3)

| Code | Message | Fix |
|------|---------|-----|
| `AUTH_FAILED` | Authentication failed | Re-run `gpc auth login --service-account <key>` |
| `AUTH_EXPIRED` | Token expired | Re-authenticate; check network if refresh fails |
| `AUTH_NO_CREDENTIALS` | No credentials found | Run `gpc auth login` or set `GPC_SERVICE_ACCOUNT` |
| `AUTH_INVALID_KEY` | Malformed service account JSON | Re-download from Google Cloud Console |
| `AUTH_KEYCHAIN_ERROR` | Cannot access OS keychain | Grant access or use `GPC_SERVICE_ACCOUNT` env var |
| `AUTH_SCOPE_DENIED` | OAuth scope not granted | Re-authorize with required scopes |

## API errors (exit code 4)

| Code | HTTP | Message | Fix |
|------|------|---------|-----|
| `API_FORBIDDEN` | 403 | Insufficient permissions | Grant required roles in Play Console |
| `API_NOT_FOUND` | 404 | Resource not found | Verify app, track, or resource ID |
| `API_CONFLICT` | 409 | Edit conflict | Wait; another edit may be open |
| `API_RATE_LIMITED` | 429 | Rate limit exceeded | Auto-retries; increase `GPC_BASE_DELAY` |
| `API_REQUEST_TIMEOUT` | 408 | Request timeout | Auto-retries with exponential backoff |
| `API_SERVER_ERROR` | 5xx | Google server error | Retry later |
| `API_BAD_REQUEST` | 400 | Invalid request data | Check JSON payload structure |
| `API_GONE` | 410 | Resource no longer available | Resource was deleted or deprecated |

## Network errors (exit code 5)

| Code | Message | Fix |
|------|---------|-----|
| `NETWORK_ERROR` | Connection failed | Check internet and proxy settings |
| `NETWORK_TIMEOUT` | Request timed out | Increase `GPC_TIMEOUT` |
| `NETWORK_DNS` | DNS resolution failed | Check DNS; try `8.8.8.8` |
| `NETWORK_SSL` | SSL/TLS error | Set `GPC_CA_CERT` for custom CA |

## Configuration errors (exit code 1)

| Code | Message | Fix |
|------|---------|-----|
| `CONFIG_MISSING` | No configuration found | Run `gpc config init` |
| `CONFIG_INVALID` | Malformed .gpcrc.json | Fix JSON syntax |
| `CONFIG_APP_MISSING` | No app specified | `gpc config set app` or `--app` flag |

## Upload and release errors (exit code 4)

| Code | Message | Fix |
|------|---------|-----|
| `INVALID_BUNDLE` | AAB is corrupted | Rebuild; run `gpc validate` first |
| `VERSION_CODE_CONFLICT` | Version code exists | Increment versionCode |
| `RELEASE_NOT_FOUND` | No release on track | Check with `gpc releases list` |
| `ROLLOUT_INVALID` | Bad rollout percentage | Use 0-100, not decimal |
| `PROMOTE_NO_SOURCE` | Source track empty | Upload to source track first |
| `EDIT_CONFLICT` | Another edit is open | Only one edit at a time |

## Monetization errors (exit code 4)

| Code | Message | Fix |
|------|---------|-----|
| `PRODUCT_NOT_FOUND` | Invalid product ID | Verify with `gpc subscriptions list` or `gpc iap list` |
| `INVALID_PURCHASE_TOKEN` | Token invalid or expired | Check token matches app/product |
| `PURCHASE_NOT_ACKNOWLEDGED` | Purchase not ack'd in 3 days | Auto-refunded; acknowledge immediately next time |
| `SUBSCRIPTION_NOT_FOUND` | Wrong subscription ID | Use `gpc purchases subscription get` |

## User and tester errors (exit code 4)

| Code | Message | Fix |
|------|---------|-----|
| `DEVELOPER_ID_REQUIRED` | Missing developer ID | Set `GPC_DEVELOPER_ID` or `--developer-id` |
| `USER_NOT_FOUND` | Email not in account | Check with `gpc users list` |
| `INVALID_GRANT` | Bad grant format | Use `com.example.app:PERM1,PERM2` |
| `TESTER_LIMIT_EXCEEDED` | Too many testers | Use Google Groups for scale |
| `TRACK_NOT_FOUND` | Invalid track name | Use `internal`, `alpha`, `beta`, or custom |

## Plugin errors (exit code 10)

| Code | Message | Fix |
|------|---------|-----|
| `PLUGIN_INVALID_PERMISSION` | Unknown permission | Check valid permission list |
| `PLUGIN_NOT_APPROVED` | Not in approvedPlugins | Add to `approvedPlugins` in .gpcrc.json |

## Environment variables for error recovery

| Variable | Default | Purpose |
|----------|---------|---------|
| `GPC_TIMEOUT` | 30000 | Request timeout in ms |
| `GPC_MAX_RETRIES` | 5 | Max retry attempts |
| `GPC_BASE_DELAY` | 1000 | Initial retry delay in ms |
| `GPC_MAX_DELAY` | 15000 | Maximum retry delay in ms |
| `GPC_CA_CERT` | — | Path to custom CA certificate |
| `HTTPS_PROXY` | — | HTTP proxy URL |
| `GPC_DEBUG` | — | Set to `1` for verbose output |
