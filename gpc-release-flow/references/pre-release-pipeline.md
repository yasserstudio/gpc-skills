# Pre-Release Validation Pipeline

End-to-end workflow for safely getting a release from build to production.

## Full pipeline

```
validate AAB → upload to internal → smoke test → promote to beta →
wait for vitals → gate on crash rate → promote to production → staged rollout
```

## Step 1 — Validate before upload

Always validate before uploading to avoid wasted edit sessions:

```bash
# Pre-submission checks: file format, size, track compatibility
gpc validate app.aab --track beta

# With ProGuard mapping and release notes
gpc validate app.aab --track production --mapping mapping.txt --notes-dir changelogs/

# In CI — exits non-zero if validation fails
gpc validate app.aab --track beta --output json | jq '.valid'
```

`gpc validate` checks: AAB file integrity, file size (warns if >100 MB), track name validity, ProGuard mapping file existence, release notes length.

## Step 2 — Upload to internal first

```bash
gpc releases upload app.aab --track internal
```

Internal track has no minimum requirements and is always the right first destination. Lets you smoke test before touching beta or production.

## Step 3 — Check current status

```bash
gpc status
# → RELEASES shows internal with your new version
# → VITALS shows current crash/ANR rates
# → REVIEWS shows recent sentiment
```

If `gpc status` exits with code 6, vitals are breached — do not promote.

## Step 4 — Promote to beta

```bash
gpc releases promote --from internal --to beta --rollout 100
```

Or use `gpc publish` for the end-to-end flow (validate + upload + promote in one command):

```bash
gpc publish app.aab --track beta --notes "Release notes here"
```

## Step 5 — Wait and check vitals

Crash data from a new release takes 6-48 hours to appear. Check:

```bash
# After waiting (next day or per monitoring schedule)
gpc vitals crashes --version <versionCode>
gpc vitals anr --version <versionCode>

# Or use the unified status with a fresh fetch
gpc status --refresh
```

## Step 6 — Gate on vitals before production

```bash
# Check crash rate (exits 6 if breached)
gpc vitals crashes --threshold 2.0

# Check ANR rate
gpc vitals anr --threshold 0.47

# Or check both via gpc status (exits 6 if any threshold breached)
gpc status
```

## Step 7 — Promote to production with staged rollout

```bash
# Start at 10% to catch issues before full rollout
gpc releases promote --from beta --to production --rollout 10

# Increase over time once stable
gpc releases rollout increase --track production --to 25
gpc releases rollout increase --track production --to 50
gpc releases rollout increase --track production --to 100

# Emergency brake if needed
gpc releases rollout halt --track production
```

## GitHub Actions example

```yaml
name: Release to Production
on:
  workflow_dispatch:
    inputs:
      version_name:
        description: 'Version name (e.g. 1.5.0)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - uses: actions/checkout@v4

      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Validate AAB
        run: gpc validate app-release.aab --track internal

      - name: Upload to internal
        run: gpc releases upload app-release.aab --track internal

      - name: Gate on vitals before promotion
        run: |
          gpc vitals crashes --threshold 2.0
          gpc vitals anr --threshold 0.47

      - name: Promote to production (10% rollout)
        run: gpc releases promote --from internal --to production --rollout 10

      - name: Post status to step summary
        if: always()
        run: gpc status --refresh --output markdown >> $GITHUB_STEP_SUMMARY
```

## Timing notes

| Action | Data availability |
| --- | --- |
| Upload completes | Immediate |
| Release visible in Play Console | 5-30 minutes |
| Crash/ANR data for new version | 6-48 hours |
| vitals compare (trend) | 2+ days of data needed |
| Review sentiment shift after release | 1-7 days |

## Rollback

If production release has issues:

```bash
# Halt the rollout immediately
gpc releases rollout halt --track production

# Promote the previous stable version back
gpc releases promote --from internal --to production --rollout 100
```
