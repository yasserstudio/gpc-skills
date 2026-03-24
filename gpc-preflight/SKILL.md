---
name: gpc-preflight
description: "Use when scanning an AAB for Google Play policy compliance before submission. Trigger when the user mentions preflight, compliance check, policy scan, pre-submission check, or wants to verify their AAB meets Google Play requirements. Also trigger for questions about restricted permissions, target SDK requirements, 64-bit compliance, hardcoded secrets detection, or Data Safety form reminders."
compatibility: "GPC v0.9.39+. No API calls — entirely offline."
metadata:
  version: 1.0.0
---

# GPC Preflight Scanner

## When to use

Use this skill when the task involves:

- Scanning an AAB file before uploading to Google Play
- Checking target SDK version compliance
- Auditing permissions against Google Play policies
- Verifying 64-bit native library support
- Scanning source code for hardcoded secrets or credentials
- Detecting non-Play billing SDKs
- Checking store listing metadata compliance
- CI/CD quality gates based on policy compliance

## Quick reference

```bash
# Full scan
gpc preflight app.aab

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
| manifest | targetSdk >= 35, debuggable, testOnly, cleartext, missing exported, FGS types | critical/error |
| permissions | 18 restricted permissions + Data Safety reminders | critical/error/info |
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

## Procedures

### Running a full preflight scan

1. Build your AAB: `./gradlew bundleRelease`
2. Run: `gpc preflight app/build/outputs/bundle/release/app-release.aab`
3. Fix any critical/error findings
4. Add a `.preflightrc.json` to allow approved permissions or disable false positives
5. Re-run until clean

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

## Known limitations

### Manifest parsing on large AABs

Some large or complex AABs have binary manifests that the protobuf decoder cannot fully parse. When this happens, GPC does **not** crash — instead it:

1. Emits a **warning** finding: "Manifest could not be fully parsed"
2. **Skips** manifest-dependent scanners (manifest, permissions, policy, privacy)
3. **Runs** all other scanners normally (native-libs, size, secrets, billing)

To run manifest checks separately, use the metadata scanner:

```bash
gpc preflight --metadata fastlane/metadata/android
```
