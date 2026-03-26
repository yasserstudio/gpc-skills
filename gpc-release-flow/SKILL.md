---
name: gpc-release-flow
description: "Use when uploading, releasing, promoting, or managing rollouts on Google Play. Make sure to use this skill whenever the user mentions gpc releases, upload AAB, upload APK, staged rollout, promote to production, halt rollout, gpc publish, release notes, track management, internal testing, beta release, production rollout, version code, rollout percentage, or wants to ship an Android app to any Play Store track. Also trigger when someone asks about the Google Play edit lifecycle, release validation, or how to do a phased rollout — even if they don't mention GPC by name. For metadata and listings, see gpc-metadata-sync. For CI/CD integration, see gpc-ci-integration."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill)."
metadata:
  version: 1.1.0
---

# GPC Release Flow

## When to use

Use this skill when the task involves:

- Uploading AAB/APK files to Google Play
- Creating releases on any track (internal, alpha, beta, production)
- Promoting releases between tracks
- Managing staged rollouts (increase, halt, resume, complete)
- Setting release notes
- Using `gpc publish` for end-to-end release workflow
- Pre-submission validation with `gpc validate`
- Checking release status across tracks

## Inputs required

- Path to AAB/APK file
- Target track (internal, alpha, beta, production, or custom)
- Rollout percentage (for staged rollouts)
- Release notes (inline or from file)
- Whether `--dry-run` is desired (preview without executing)

## Procedure

### 0) Pre-flight validation

Before uploading, validate the bundle:

```bash
gpc validate app-release.aab
gpc validate app-release.aab --track beta  # Validate for specific track
```

This checks file format, version code conflicts, and track compatibility.

### 1) Upload and release

#### A) Quick release (one command)

The `publish` command handles the full flow — upload, track assignment, release notes, and commit:

```bash
gpc publish app-release.aab --track internal
gpc publish app-release.aab --track beta --notes "Bug fixes and improvements"
gpc publish app-release.aab --track production --rollout 10
```

Multi-language release notes from directory:
```bash
gpc publish app-release.aab --track beta --notes-dir ./release-notes/
```

#### B) Step-by-step release

For more control, use individual commands:

```bash
# Upload AAB (creates edit, uploads, assigns to track)
gpc releases upload app-release.aab --track internal

# Upload with staged rollout
gpc releases upload app-release.aab --track production --rollout 10

# Set release notes
gpc releases notes set --track beta --lang en-US --notes "Bug fixes"
gpc releases notes set --track beta --file release-notes/  # From directory
```

Read:
- `references/upload-lifecycle.md`

### 2) Check release status

```bash
# Full picture — releases, vitals, and reviews in one command
gpc status

# Releases only, all tracks
gpc releases status

# Specific track detail
gpc releases status --track production

# JSON for scripting
gpc status --output json | jq '.releases[] | select(.track == "production")'
```

### 3) Promote between tracks

```bash
# Promote from internal to beta
gpc releases promote --from internal --to beta

# Promote from beta to production with staged rollout
gpc releases promote --from beta --to production --rollout 5

# Copy release notes from another track when promoting
gpc releases promote --from internal --to production --copy-notes-from internal
```

> **Note:** Since v0.9.39, `gpc releases promote` auto-retries once on 409 EDIT_CONFLICT (another edit is open).

### 3b) Preview before publishing

```bash
# Read-only preview of release state across all tracks
gpc diff

# Compare two specific tracks
gpc diff --from internal --to production

# Compare local metadata vs remote
gpc diff --metadata fastlane/metadata
```

### 3c) Release lifecycle visibility

```bash
# List releases on a track with lifecycle states (DRAFT, IN_REVIEW, PUBLISHED, etc.)
gpc releases list --track production
gpc releases list --track beta --json
```

> **New in v0.9.46:** The `releases.list` endpoint provides release lifecycle states without opening an edit session. Use it to check whether a release is still in review, has been published, or is in draft — useful for CI pipelines that need to gate on review completion.

### 3d) Release stats and history

```bash
# Release count per track with status breakdown
gpc releases count

# Show release history from GitHub
gpc changelog
gpc changelog --version v0.9.44
```

### 4) Manage staged rollouts

```bash
# Increase rollout percentage
gpc releases rollout increase --track production --to 50

# Halt rollout (stops further distribution)
gpc releases rollout halt --track production

# Resume halted rollout
gpc releases rollout resume --track production

# Complete rollout (100%)
gpc releases rollout complete --track production
```

Read:
- `references/rollout-strategies.md`

### 5) Track management

```bash
gpc tracks list                    # List all tracks
gpc tracks get production          # Show track details + current releases
```

### 6) Preview with dry-run

All write operations support `--dry-run`:

```bash
gpc releases upload app.aab --track beta --dry-run
gpc releases promote --from beta --to production --rollout 10 --dry-run
gpc releases rollout increase --track production --to 50 --dry-run
```

### 7) Interactive mode

When flags are omitted, GPC prompts interactively (if TTY detected):

```bash
gpc releases upload app.aab
# Prompts for: track, rollout percentage, release notes
```

Disable with `--no-interactive` or `GPC_NO_INTERACTIVE=1`.

## Verification

- `gpc status` shows the release on the expected track with correct status and rollout
- `gpc releases status` confirms version code matches the uploaded AAB
- Rollout percentage is correct
- Release notes are set for the expected languages
- `gpc vitals crashes --version <code>` shows no spikes post-release (or use `gpc status` to check vitals across all metrics)

## Failure modes / debugging

| Error Code | Symptom | Fix |
|------------|---------|-----|
| `API_DUPLICATE_VERSION_CODE` | Version code already uploaded | Increment `versionCode` in build.gradle. Check current: `gpc releases status` |
| `API_VERSION_CODE_TOO_LOW` | Version code lower than current | Google Play requires increasing version codes per track |
| `API_PACKAGE_NAME_MISMATCH` | AAB package doesn't match target app | Verify `applicationId` in build.gradle. Check: `gpc config show` |
| `API_BUNDLE_TOO_LARGE` | File exceeds size limit | AAB max: 2 GB, APK max: 1 GB. Check: `gpc preflight <file>` |
| `API_INVALID_BUNDLE` | Corrupted or malformed file | Ensure properly signed. Validate: `gpc preflight <file>`. Rebuild: `./gradlew bundleRelease` |
| `API_EDIT_CONFLICT` | Another edit session open | GPC auto-retries once. Wait and retry, or discard stale edit in Console |
| `API_ROLLOUT_ALREADY_COMPLETED` | Release at 100% | Deploy a new version: `gpc releases upload --track <track>` |
| `API_RELEASE_NOTES_TOO_LONG` | Notes exceed 500 chars | Shorten per language. Preview: `gpc releases notes get` |
| `APK_NOT_SIGNED` | Missing or invalid signing | Use Play App Signing or check keystore |
| Rollout stuck | Rollout was halted | `gpc releases rollout resume --track <track>` |

Read:
- `references/troubleshooting.md`
- `references/pre-release-pipeline.md` — end-to-end: validate → upload → vitals gate → promote → staged rollout

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-metadata-sync**: Store listings and screenshots
- **gpc-vitals-monitoring**: Post-release crash monitoring
- **gpc-ci-integration**: Automated releases in CI/CD
