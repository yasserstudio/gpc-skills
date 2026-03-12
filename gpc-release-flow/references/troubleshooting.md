# Release Flow Troubleshooting

## Common Upload Errors

### `Version code already used`

The version code in your AAB/APK already exists on this track.

**Fix:** Increment `versionCode` in your app's `build.gradle`:
```groovy
android {
    defaultConfig {
        versionCode 143  // Increment this
    }
}
```

### `APK_NOT_SIGNED` or signing errors

**Possible causes:**
1. AAB is not signed at all
2. Using wrong signing key
3. Play App Signing not set up

**Fix:** Ensure you're signing with the correct upload key:
```bash
# Check signing info
jarsigner -verify -verbose app-release.aab
```

### `EDIT_CONFLICT`

Another edit is already in progress for this app.

**Possible causes:**
1. Console UI has an unsaved draft
2. Another CI job is running simultaneously
3. Previous GPC command failed mid-edit

**Fix:**
1. Open Play Console → check for unsaved changes → discard
2. Add concurrency limits to CI jobs:
   ```yaml
   concurrency:
     group: play-store-${{ github.ref }}
     cancel-in-progress: false
   ```
3. Wait and retry

### Upload timeout

**Fix:** Increase timeout for large files:
```bash
export GPC_TIMEOUT=120000  # 2 minutes
gpc releases upload large-app.aab --track internal
```

## Promotion Errors

### `No release to promote`

The source track has no release to promote.

**Fix:** Check current releases:
```bash
gpc releases status
```

Ensure the source track has a completed release (not draft or halted).

### `Version code conflicts on target track`

The target track already has a release with the same or higher version code.

**Fix:** Upload a new version with a higher version code.

## Rollout Errors

### `Cannot decrease rollout percentage`

Google Play doesn't allow decreasing rollout percentage.

**Fix:** Either:
- Halt the rollout: `gpc releases rollout halt --track production`
- Or complete it: `gpc releases rollout complete --track production`

### `Cannot resume — rollout is not halted`

The rollout is in `inProgress` state, not `halted`.

**Fix:** Check current state:
```bash
gpc releases status --track production
```

## Debugging with `--dry-run`

Preview any write operation without executing:

```bash
gpc releases upload app.aab --track beta --dry-run
gpc releases promote --from beta --to production --dry-run
gpc releases rollout increase --track production --to 50 --dry-run
```

Dry-run shows what would happen, including edit creation and API calls.

## Debugging with `--verbose`

Enable debug logging to see API requests:

```bash
gpc releases upload app.aab --track beta --verbose
```

Shows: HTTP method, URL, request/response details, timing.
