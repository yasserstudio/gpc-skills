# CI Troubleshooting

## Authentication Failures

### `AUTH_INVALID` in CI

**Most common cause:** Secret not set correctly.

**Debug steps:**
```yaml
- name: Verify secret exists
  run: |
    if [ -z "$GPC_SERVICE_ACCOUNT" ]; then
      echo "ERROR: GPC_SERVICE_ACCOUNT is not set"
      exit 1
    fi
    echo "Secret length: ${#GPC_SERVICE_ACCOUNT}"
```

**Common mistakes:**
1. Secret name mismatch (`PLAY_SERVICE_ACCOUNT` vs `GPC_SERVICE_ACCOUNT`)
2. Secret contains file path instead of JSON content
3. JSON is truncated (check character limit on CI platform)
4. Wrong env var name in workflow

### `Permission denied`

Service account exists but lacks Play Console permissions.

**Fix:**
1. Play Console → Settings → API access
2. Find service account → Manage → check permissions
3. Ensure "Release to production" is granted (if deploying to production)

## Upload Issues

### Timeout on large AAB

```yaml
env:
  GPC_TIMEOUT: '120000'  # 2 minutes
  GPC_MAX_RETRIES: '5'
```

### `EDIT_CONFLICT` in parallel jobs

Two jobs trying to modify the same app simultaneously.

**Fix:** Add concurrency control:
```yaml
concurrency:
  group: play-store-${{ env.GPC_APP }}
  cancel-in-progress: false
```

### `Version code already used`

CI built the same version code twice.

**Fix:** Ensure version code is unique per build:
```groovy
// build.gradle
android {
    defaultConfig {
        versionCode System.getenv("GITHUB_RUN_NUMBER")?.toInteger() ?: 1
    }
}
```

## Network Issues

### Rate limiting (429 errors)

```yaml
env:
  GPC_BASE_DELAY: '2000'
  GPC_MAX_DELAY: '120000'
  GPC_MAX_RETRIES: '5'
  GPC_RATE_LIMIT: '30'  # Reduce from default 50
```

### Proxy required

```yaml
env:
  HTTPS_PROXY: ${{ secrets.PROXY_URL }}
  GPC_CA_CERT: /path/to/ca-bundle.crt
```

## Exit Code Reference

Use exit codes for conditional CI logic:

```yaml
- name: Check vitals
  id: vitals
  run: gpc vitals crashes --threshold 2.0
  continue-on-error: true

- name: Promote (only if vitals OK)
  if: steps.vitals.outcome == 'success'
  run: gpc releases promote --from beta --to production

- name: Alert (if vitals bad)
  if: steps.vitals.outcome == 'failure'
  run: echo "Vitals threshold breached — promotion blocked"
```

## Rejected or In-Review Releases

If a previous submission is still in review or was rejected, uploading a new version may fail with `EDIT_CONFLICT`.

**Detect before uploading:**
```yaml
- name: Check for pending review
  run: gpc releases status --error-if-in-review
```

The `--error-if-in-review` flag exits with code 4 if any release is in `inReview` or `rejected` status. Handle it before uploading:

```yaml
- name: Check for pending review
  id: review-check
  run: gpc releases status --error-if-in-review
  continue-on-error: true

- name: Upload release
  if: steps.review-check.outcome == 'success'
  run: gpc releases upload app.aab --track beta --changes-not-sent-for-review
```

If a release was rejected, resolve the issue in the Play Console before re-uploading from CI.

## Debugging with Verbose Output

```yaml
- name: Upload with debug logging
  run: gpc releases upload app.aab --track beta --verbose --retry-log retries.log

- name: Upload retry log
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: retry-log
    path: retries.log
```

## Platform-Specific Notes

### GitLab CI
- Use `$CI_JOB_TOKEN` for artifact access, but `GPC_SERVICE_ACCOUNT` for Play Store
- Variables set in Settings → CI/CD → Variables

### Bitbucket Pipelines
- Secrets set in Repository Settings → Pipelines → Repository Variables
- Max secret size is 32KB — base64 encode if needed

### CircleCI
- Use Contexts for shared secrets across projects
- Environment variables in Project Settings → Environment Variables
