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
| `API_DUPLICATE_VERSION_CODE` | 409 | Version code already uploaded | Increment versionCode in build.gradle and rebuild |
| `API_VERSION_CODE_TOO_LOW` | 400 | Version code lower than current | Version code must increase per track |
| `API_PACKAGE_NAME_MISMATCH` | 400 | Package name doesn't match | Verify applicationId matches target app |
| `API_APP_NOT_FOUND` | 404 | App not in developer account | Verify package name and developer account |
| `API_INSUFFICIENT_PERMISSIONS` | 403 | Service account missing permissions | Grant required roles in Play Console → Settings → API access |
| `API_BUNDLE_TOO_LARGE` | 400 | AAB or APK exceeds size limit | AAB max 2 GB, APK max 1 GB |
| `API_INVALID_BUNDLE` | 400 | Corrupt or improperly signed bundle | Ensure properly signed AAB/APK |
| `API_CHANGES_NOT_SENT_FOR_REVIEW` | 400/403 | App rejected update, requires review acknowledgment | Add `--changes-not-sent-for-review` flag |
| `API_CHANGES_ALREADY_IN_REVIEW` | 400 | Changes already in review | Use `--error-if-in-review` to prevent silent cancellation |

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

## Upload errors (exit code 4)

| Code | Message | Fix |
|------|---------|-----|
| `UPLOAD_CHUNK_FAILED` | Chunk could not be sent after retries | Check network; increase `GPC_MAX_RETRIES` or `GPC_UPLOAD_TIMEOUT` |
| `UPLOAD_NO_COMPLETION` | All bytes sent but no completion response | Retry upload; check `GPC_UPLOAD_TIMEOUT` |
| `UPLOAD_INITIATE_FAILED` | Session initiation failed | Check auth and permissions; retry |
| `UPLOAD_NO_SESSION_URI` | No Location header in initiation response | API error; retry or check service account permissions |
| `UPLOAD_SESSION_NOT_FOUND` | Session expired (404) | Start a new upload session |
| `UPLOAD_SESSION_EXPIRED` | Session gone (410) | Start a new upload session |
| `UPLOAD_INVALID_CHUNK_SIZE` | Chunk size not multiple of 256 KB | Set `GPC_UPLOAD_CHUNK_SIZE` to a multiple of 262144 (256 KB) |

## Release errors (exit code 4)

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

## Review-state errors (exit code 4)

### `API_CHANGES_NOT_SENT_FOR_REVIEW`

**HTTP:** 400 or 403

**Cause:** The app has been flagged by Google Play and any update must explicitly acknowledge that changes are not sent for review. This commonly happens when a previous submission was rejected or when the app is in a policy compliance state that requires the flag.

**Fix:** Add the `--changes-not-sent-for-review` flag to your release or upload command.

```bash
# Upload with the required flag
gpc releases upload app.aab --track production --changes-not-sent-for-review

# Promote with the required flag
gpc releases promote --from beta --to production --changes-not-sent-for-review
```

**JSON error output:**
```json
{
  "success": false,
  "error": {
    "code": "API_CHANGES_NOT_SENT_FOR_REVIEW",
    "message": "This app requires the changesNotSentForReview flag to be set",
    "suggestion": "Re-run the command with --changes-not-sent-for-review"
  }
}
```

**Notes:**
- This flag tells the API that you acknowledge the changes will not be sent for review automatically.
- Some apps enter this state after a policy violation or rejected review.
- The flag is safe to include on every call if your workflow requires it.
- **Technical detail (v0.9.52+):** When this flag is set, GPC skips the `edits.validate` API call and goes straight to `edits.commit`. Google's validate endpoint does not accept the `changesNotSentForReview` parameter and returns "Unknown name" if you try. The commit endpoint handles validation internally.
- **Requires GPC v0.9.52+.** Versions 0.9.51 and earlier had a bug where `edits.validate` blocked this flag from ever reaching `edits.commit`.

---

### `API_CHANGES_ALREADY_IN_REVIEW`

**HTTP:** 400

**Cause:** The track already has changes that are currently being reviewed by Google Play. Committing a new edit would silently cancel the in-progress review and replace it with the new submission, which may not be what you intended.

**Fix:** Use `--error-if-in-review` to make GPC fail early instead of silently replacing the in-review changes. If you do want to replace the in-review changes, omit the flag.

```bash
# Fail early if changes are already in review (recommended for CI)
gpc releases upload app.aab --track production --error-if-in-review

# If you intentionally want to replace the in-review release, omit the flag
gpc releases upload app.aab --track production
```

**JSON error output:**
```json
{
  "success": false,
  "error": {
    "code": "API_CHANGES_ALREADY_IN_REVIEW",
    "message": "Track already has changes in review; committing would cancel the pending review",
    "suggestion": "Use --error-if-in-review to prevent silent cancellation, or omit the flag to replace the in-review changes"
  }
}
```

**Notes:**
- In CI pipelines, always use `--error-if-in-review` to avoid accidentally overwriting a release that is under review.
- If you need to check the current review state before uploading, use `gpc releases list --track <track> --json` to inspect the release status.
- Without this flag, GPC will proceed and the previous in-review submission will be silently cancelled by the Google Play API.

---

## Signing errors (exit code 4 or 6)

### `EDIT_CREATE_FAILED`

**Cause:** Failed to create an edit session via the Play API. Usually a permissions issue with the service account.

**Fix:** Ensure the service account has "Release manager" or "Admin" role in Play Console (Setup > API access). Check that the package name is correct.

### `BUNDLES_LIST_FAILED`

**Cause:** Failed to list bundles for the app within the edit session.

**Fix:** Verify the app has at least one uploaded AAB. Check service account permissions.

### `NO_BUNDLES`

**Cause:** The bundles list returned empty. No AABs have been uploaded to this app.

**Fix:** Upload at least one AAB: `gpc publish` or `gpc releases upload app.aab --track internal`.

### `NO_SIGNING_CERT`

**Cause:** The `generatedApks` endpoint returned no signing certificate fingerprint for the bundle version. This can happen if the service account lacks sufficient permissions or if Play App Signing is not enrolled.

**Fix:** Enroll in Play App Signing in Play Console. Ensure the service account has access to view generated APKs.

### `GENERATED_APKS_FAILED`

**Cause:** HTTP error fetching generated APKs for a specific version code.

**Fix:** Check that the version code exists and the service account has permissions.

### Signing key mismatch (exit code 6)

**Cause:** `gpc preflight signing` detected that the signing certificate changed between your two most recent bundle versions. This could indicate an unintended key rotation or a misconfigured upload.

**Fix:** If the change was intentional (key upgrade), this is safe to ignore. If not, investigate which build produced the mismatched bundle.

---

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
| `GPC_UPLOAD_TIMEOUT` | 300000 | Upload request timeout in ms (5 min) |
| `GPC_UPLOAD_CHUNK_SIZE` | 8388608 | Upload chunk size in bytes (8 MB) |
