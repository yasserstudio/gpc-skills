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
| `API_DECLARATION_REQUIRED` | 403 | A Play Console "App content" declaration is incomplete | Complete it under Policy > App content. Not a permissions problem; changing roles will not help |
| `API_ALREADY_EXISTS` | 409 | The resource you tried to create is already there | Use the matching `update` command instead of `create` |
| `API_ENDPOINT_RETIRED` | 404 | Google removed the endpoint from its published API | Do the task in Play Console. Currently affects `gpc games ... set-icon` (the `imageConfigurations` route) |
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
| `UPLOAD_INSECURE_URI` | Session URI uses a non-HTTPS scheme | GPC rejects non-HTTPS upload URIs; check proxy or MITM stripping TLS |
| `UPLOAD_URI_HOST_MISMATCH` | Session URI host does not match expected upload host | URI returned by Google API points to an unexpected host; do not proceed |
| `UPLOAD_INVALID_URI` | Session URI is malformed or unparseable | API returned a bad Location header; retry the upload |

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

## Order refund review errors (exit code 2, v0.9.96+)

Emitted by `gpc purchases orders review-refund`, which answers a chargeback dispute within Google's 24-hour window.

| Code | Message | Fix |
|------|---------|-----|
| `ORDER_REVIEW_REFUND_INVALID` | Invalid refund review input | Pass exactly one of `--sample-content-provided` / `--no-sample-content-provided`, keep `--consumption-percent` a plain 0-100 decimal, and make `--usage-events-file` a JSON array of objects (max 1,000) |

Validated locally before the request is sent. An empty or whitespace-only `--consumption-percent` is treated as not provided, so a typo never claims "0% consumed" on your behalf.

## User and tester errors (exit code 4)

| Code | Message | Fix |
|------|---------|-----|
| `DEVELOPER_ID_REQUIRED` | Missing developer ID | Set `GPC_DEVELOPER_ID` or `--developer-id` |
| `USER_NOT_FOUND` | Email not in account | Check with `gpc users list` |
| `INVALID_GRANT` | Bad grant format | Use `com.example.app:PERM1,PERM2` |
| `TESTER_LIMIT_EXCEEDED` | Too many testers | Use Google Groups for scale |
| `TRACK_NOT_FOUND` | Invalid track name | Use `internal`, `alpha`, `beta`, or custom |

## Bulk report errors (v0.9.93+)

Raised by `gpc reports list` and `gpc reports download stats|financial`, which read Play's monthly bulk-report CSVs from the developer account's Cloud Storage bucket.

| Code | Exit | Message | Fix |
|------|------|---------|-----|
| `REPORT_ACCESS_DENIED` | 4 | Access denied reading the Play reports bucket | Enable "View app information and download bulk reports (read-only)" for the service account in Play Console → Users and permissions → Account permissions; allow a few minutes to propagate |
| `REPORT_AUTH_REJECTED` | 3 | Authentication rejected (HTTP 401) | Verify the key with `gpc auth status` and the system clock; `gpc auth clear-cache` and retry |
| `REPORT_BUCKET_UNKNOWN` | 2 | Cannot determine the reports bucket | Set `developerId` / `GPC_DEVELOPER_ID`, or pass `--bucket` / `GPC_REPORTS_BUCKET` / `reports.bucket` |
| `REPORT_BUCKET_INVALID` | 2 | Configured bucket name is not valid | Copy the exact Cloud Storage URI from Play Console → Download reports |
| `REPORT_BUCKET_NOT_FOUND` | 4 | Bucket not found | Default is `pubsite_prod_<developerId>`; override if the account's bucket differs |
| `REPORT_OBJECT_NOT_FOUND` | 4 | No report for that type / month / dimension | Error lists available dimensions or months; a month publishes only after it ends |
| `REPORT_LIST_FAILED` | 4 | Bucket listing call failed | Retry; check network |
| `REPORT_DOWNLOAD_FAILED` | 4 | Object fetch failed | Retry; check network |
| `REPORT_DECODE_FAILED` | 4 | Could not gunzip or decode UTF-16 | Retry; save the raw object with `--output-file` if it persists |
| `REPORT_ARCHIVE_UNREADABLE` | 4 | Financial ZIP archive could not be read | Save it raw with `--output-file report.zip` |
| `REPORT_MULTIPLE_ENTRIES` | 2 | Archive holds several CSVs | Use `--output-file report.zip` or `--json` (inlines every entry) |
| `INVALID_REPORT_DIMENSION` | 2 | Unsupported `--dimension` | One of `overview`, `country`, `language`, `os_version`, `device`, `app_version`, `carrier`, `traffic_source` |
| `MISSING_REQUIRED_OPTION` | 2 | Required flag omitted | Stats downloads need `--month` and `--type`; financial downloads need `--month` |
| `INVALID_LIMIT` | 2 | `--limit` is not a positive integer | Pass a positive whole number |

### `REPORT_ACCESS_DENIED`

**Exit code:** 4

**Cause:** The service account authenticated fine but is not authorized to read the reports bucket. This is the common first-run failure: Play grants the "download bulk reports" permission to your own user login automatically, but **never** to a service account.

**Fix:** In Play Console → Users and permissions, open the service account, and under **Account permissions** enable **"View app information and download bulk reports (read-only)"**. Allow a few minutes for it to propagate, then retry.

```bash
# Confirm the grant landed
gpc doctor            # look for the reports-bucket check

# Drop cached tokens if the grant is new
gpc auth clear-cache

gpc reports list installs --app com.example.myapp --month 2026-02
```

**Notes:**
- The grant is account-level, not per-app: one grant covers stats and financial reports.
- Only the reports commands (and the `gpc doctor` probe) request the `devstorage.read_only` scope, and those tokens are cached separately from regular ones.
- If the bucket name itself is wrong you get `REPORT_BUCKET_NOT_FOUND` instead; copy the exact Cloud Storage URI from Play Console → Download reports.

---

### `API_DECLARATION_REQUIRED`

**Exit code:** 4 — added in v0.9.94

**Cause:** Google Play refused the request because a **Play Console → Policy → App content** declaration is incomplete. The service account's permissions are irrelevant here; no role change will fix it.

**This used to be misreported.** Before v0.9.94, GPC classified 403s by looking for the word "permission" anywhere in Google's message. The foreground service declaration reads *"You must let us know whether your app uses any Foreground Service permissions."* — so it matched, and GPC replaced Google's explanation with "The service account does not have permission for this operation" and pointed at Users and permissions. If you are on an older version and see a permissions error you cannot explain, **check App content before touching any roles.**

**Fix:** read the message body. GPC now quotes Google verbatim, and Google names the specific declaration. Complete it in Play Console → your app → Policy → App content, then retry.

```bash
# Catch it before spending an upload
gpc preflight app.aab
# look for: policy-app-content-declaration (info)
```

**Notes:**
- Common gates: foreground service permissions, data safety, ads, target audience, government apps.
- The declaration lives in Play Console and cannot be read from the AAB or through the Publisher API, so preflight can only advise that one is likely required — it cannot confirm whether you have completed it.
- Distinct from the manifest check `foreground-service-type-missing`: that one verifies `android:foregroundServiceType` in your manifest. You can have that entirely correct and still be blocked by the Console declaration.
- v0.9.94 also stopped reporting insufficient **OAuth scope** failures as missing Play Console permissions. Those now surface Google's own wording.

---

## Plugin errors (exit code 10)

| Code | Message | Fix |
|------|---------|-----|
| `PLUGIN_INVALID_PERMISSION` | Unknown permission | Check valid permission list |
| `PLUGIN_NOT_APPROVED` | Not in approvedPlugins | Add to `approvedPlugins` in .gpcrc.json |
| `PLUGIN_PERMISSIONS_REQUIRED` | Third-party plugin declares no `gpc.permissions` (v0.9.94+) | Ask the author to declare the hooks it uses, then approve it again |
| `PLUGIN_IDENTITY_MISMATCH` | Specifier claims a first-party package but resolves to a different one (v0.9.94+) | Remove the npm alias or local replacement for `@gpc-cli/plugin-ci` |

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
| `GPC_REPORTS_BUCKET` | — | Override the Play reports bucket (default `pubsite_prod_<developerId>`, v0.9.93+) |
