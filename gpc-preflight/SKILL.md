---
name: gpc-preflight
description: "Use when scanning an AAB or APK for Google Play policy compliance before submission, or checking signing key consistency across releases. Trigger when the user mentions preflight, compliance check, policy scan, pre-submission check, signing key consistency, certificate mismatch, or wants to verify their AAB/APK meets Google Play requirements. Also trigger for questions about restricted permissions, target SDK requirements, 64-bit compliance, hardcoded secrets detection, or Data Safety form reminders."
compatibility: "GPC v0.9.66+ for signing consistency. v0.9.65+ for April 2026 policy rules. APK support added in v0.9.47. AAB/APK scans are entirely offline; signing consistency requires auth."
metadata:
  version: 1.2.0
---

# GPC Preflight Scanner

## When to use

Use this skill when the task involves:

- Scanning an AAB or APK file before uploading to Google Play
- Checking target SDK version compliance
- Auditing permissions against Google Play policies
- Verifying 64-bit native library support
- Scanning source code for hardcoded secrets or credentials
- Detecting non-Play billing SDKs
- Checking store listing metadata compliance
- CI/CD quality gates based on policy compliance

## Quick reference

```bash
# Full scan (AAB or APK)
gpc preflight app.aab
gpc preflight app.apk

# With metadata and source scanning
gpc preflight app.aab --metadata fastlane/metadata/android --source app/src

# Specific scanners only
gpc preflight manifest app.aab
gpc preflight permissions app.aab
gpc preflight metadata ./metadata
gpc preflight codescan ./src

# CI mode
gpc preflight app.aab --fail-on error --json
```

## 9 scanners

| Scanner | Checks | Severity |
|---------|--------|----------|
| manifest | targetSdk >= 35, debuggable, testOnly, cleartext, missing exported, FGS types, geofencing foreground service (v0.9.65+) | critical/error/warning |
| permissions | 18 restricted permissions, contacts broad-access, Health Connect granular (v0.9.65+), Data Safety reminders | critical/error/warning/info |
| native-libs | 64-bit ARM compliance, ABI detection | critical/warning |
| metadata | Listing character limits, screenshots, privacy policy URL | error/warning |
| secrets | AWS keys, Google API keys, Stripe keys, private keys | critical/warning |
| billing | Stripe, Braintree, PayPal, Razorpay SDK detection | warning |
| privacy | Tracking SDKs, Advertising ID, data collection cross-reference | warning/info |
| policy | Families/COPPA, financial, health, UGC, overlay | warning/info |
| size | Download size, large native libs, large assets | warning/info |

## Configuration (.preflightrc.json)

```json
{
  "failOn": "error",
  "targetSdkMinimum": 35,
  "maxDownloadSizeMb": 150,
  "allowedPermissions": ["android.permission.READ_SMS"],
  "disabledRules": ["cleartext-traffic"],
  "severityOverrides": { "billing-stripe-sdk": "info" }
}
```

## Exit codes

- `0` — all checks passed
- `1` — runtime error
- `6` — findings at or above `--fail-on` severity

## Key rules

| Rule ID | Severity | What |
|---------|----------|------|
| targetSdk-below-minimum | critical | targetSdkVersion < 35 |
| debuggable-true | critical | android:debuggable="true" |
| testOnly-true | critical | android:testOnly="true" |
| missing-arm64 | critical | 32-bit ARM without 64-bit |
| missing-exported | error | Component with intent-filter but no exported attr |
| foreground-service-type-missing | error | Service without foregroundServiceType (API 34+) |
| secret-aws-key | critical | AWS access key in source |
| secret-stripe-key | critical | Stripe secret key in source |
| contacts-permission-broad | warning | READ_CONTACTS / WRITE_CONTACTS (v0.9.65+, April 2026 policy) |
| geofencing-foreground-service | warning | Location FGS + ACCESS_BACKGROUND_LOCATION (v0.9.65+, April 2026 policy) |
| health-connect-granular | warning/info | READ_ALL_HEALTH_DATA; warning on targetSdk >= 36, info otherwise (v0.9.65+, April 2026 policy) |

## Procedures

### Running a full preflight scan

1. Build your AAB or APK: `./gradlew bundleRelease` (or `assembleRelease` for APK)
2. Run: `gpc preflight app/build/outputs/bundle/release/app-release.aab`
   Or for APK: `gpc preflight app/build/outputs/apk/release/app-release.apk`
3. Fix any critical/error findings
4. Add a `.preflightrc.json` to allow approved permissions or disable false positives
5. Re-run until clean

Note: After the scan, GPC shows a reminder about Android developer verification requirements (September 30, 2026 enforcement for BR, ID, SG, TH). Run `gpc verify` for details.

### Signing key consistency (v0.9.66+)

```bash
gpc preflight signing                    # Check cert consistency across two most recent bundles
gpc preflight signing --json             # JSON output for CI
gpc preflight signing --app com.example.app  # Override package name
```

Compares signing certificates across your two most recent bundle versions via the Play API (`generatedApks.list`). Requires auth (service account or OAuth). Exit code 6 on mismatch (same as other preflight threshold breaches). Exit code 4 on API errors.

This is NOT an offline scan. It calls the Play API to create an edit, list bundles, fetch generated APKs for the top two version codes, compare `certificateSha256Fingerprint`, then delete the edit.

### April 2026 policy rules (v0.9.65+)

Three rules added for Google Play's April 15, 2026 policy batch. Compliance deadline: May 15, 2026.

1. **Contacts broad access** (`contacts-permission-broad`): Flags READ_CONTACTS / WRITE_CONTACTS. Google now requires the Android Contact Picker instead of broad access. Emits a single finding even when both permissions are present. Suppress via `allowedPermissions` for dialer/messaging apps.

2. **Geofencing foreground service** (`geofencing-foreground-service`): Fires when a service has `foregroundServiceType` containing "location" AND the app declares `ACCESS_BACKGROUND_LOCATION`. Google removed geofencing as an approved foreground service use case. For legitimate background location tracking (navigation, fitness), suppress via `"disabledRules": ["geofencing-foreground-service"]`.

3. **Health Connect granular permissions** (`health-connect-granular`): Flags `READ_ALL_HEALTH_DATA`. Severity is `warning` when `targetSdk >= 36` (Android 16 requirement), `info` otherwise. Replace with granular permissions like `health.READ_STEPS`, `health.READ_HEART_RATE`, etc.

### Adding to CI

```yaml
# GitHub Actions
- name: Preflight
  run: gpc preflight app.aab --fail-on error --json > preflight.json
- name: Upload report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: preflight-report
    path: preflight.json
```

## Related skills

- `gpc-release-flow` — uploading and releasing after preflight passes
- `gpc-ci-integration` — CI/CD patterns including preflight gates
- `gpc-troubleshooting` — exit code 6 handling
- `gpc-security` — credential handling and key rotation
