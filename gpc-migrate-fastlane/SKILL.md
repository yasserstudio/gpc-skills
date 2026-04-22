---
name: gpc-migrate-fastlane
description: "Use when migrating from Fastlane supply to GPC for Google Play operations. Make sure to use this skill whenever the user mentions Fastlane, fastlane supply, Fastfile, Appfile, Gemfile, migrate from Fastlane, replace Fastlane, Fastlane to GPC, supply command, Fastlane metadata, Fastlane screenshots, ruby-based deployment, bundle exec fastlane — even if they don't explicitly say 'migrate.' Also trigger when someone has an existing Fastlane setup and wants to use GPC alongside or instead of it, when they're comparing Fastlane and GPC, or when they ask about compatibility between the two tools. For general metadata management, see gpc-metadata-sync. For CI/CD setup, see gpc-ci-integration."
compatibility: "GPC v0.9.9+. Works alongside existing Fastlane installations. Same service account keys and metadata directory structure are compatible."
metadata:
  version: 1.2.0
---

# gpc-migrate-fastlane

Complete guide for migrating from Fastlane supply to GPC.

## When to use

- Migrating from Fastlane supply to GPC (partial or full)
- Running GPC alongside Fastlane during a transition period
- Comparing Fastlane and GPC commands
- Converting Fastlane CI workflows to GPC
- Understanding metadata directory compatibility

## Inputs required

- **Existing Fastlane setup** — Fastfile, Appfile, metadata directory
- **Service account key** — same key file works for both tools
- **App package name** — from Appfile or Fastfile configuration

## Procedure

### 1. Assess current Fastlane usage

Identify which Fastlane supply features you use:

```bash
# Check your Fastfile for supply lanes
cat fastlane/Fastfile | grep -A 10 'supply'

# Check metadata directory
ls fastlane/metadata/android/

# Check Appfile for config
cat fastlane/Appfile
```

### 2. Install GPC (keep Fastlane installed)

```bash
npm install -g @gpc-cli/cli
```

Both tools can coexist — they share the same service account keys and metadata directory structure.

### 3. Authenticate with the same service account

```bash
# Use the same key file from Fastlane
gpc auth login --service-account path/to/play-store-key.json

# Or set via environment variable (same as SUPPLY_JSON_KEY)
export GPC_SERVICE_ACCOUNT=$(cat path/to/play-store-key.json)

# Configure default app (from your Appfile)
gpc config set app com.example.app

# Verify
gpc doctor
```

### 4. Map your Fastlane commands to GPC

`Read:` `references/command-mapping.md` for the complete command mapping table.

Key mappings:

```bash
# Upload AAB
# Fastlane: fastlane supply --aab app.aab --track beta
# GPC:
gpc releases upload app.aab --track beta

# Upload with rollout
# Fastlane: fastlane supply --aab app.aab --track production --rollout 0.1
# GPC:      (note: percentage, not decimal)
gpc releases upload app.aab --track production --rollout 10

# Download metadata
# Fastlane: fastlane supply --download_metadata --metadata_path metadata/
# GPC:
gpc listings pull --dir metadata/

# Push metadata
# Fastlane: fastlane supply --skip_upload_aab --metadata_path metadata/
# GPC:
gpc listings push --dir metadata/

# Upload screenshots
# Fastlane: fastlane supply --skip_upload_aab --skip_upload_metadata
# GPC:
gpc listings images upload --lang en-US --type phoneScreenshots *.png
```

### 5. Test with dry-run

Before switching any CI pipeline, verify GPC produces the same results:

```bash
# Preview metadata push (no changes applied)
gpc listings push --dir fastlane/metadata/android/ --dry-run

# Preview upload (validates AAB without uploading)
gpc validate app.aab

# Compare listing output
gpc listings view --lang en-US --json
```

### 6. Migrate CI configuration

`Read:` `references/ci-migration.md` for platform-specific CI migration examples.

Replace Fastlane supply calls in your CI with GPC equivalents:

```yaml
# Before (GitHub Actions with Fastlane)
- name: Deploy to beta
  run: bundle exec fastlane supply --aab app.aab --track beta

# After (GitHub Actions with GPC)
- name: Deploy to beta
  env:
    GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
    GPC_APP: com.example.app
  run: npx @gpc-cli/cli releases upload app.aab --track beta
```

### 7. Clean up Fastlane (optional)

Once fully migrated and confident:

```bash
# Remove Fastlane files
rm -rf fastlane/Fastfile fastlane/Appfile fastlane/Pluginfile
rm Gemfile Gemfile.lock

# Keep metadata directory — GPC uses the same structure
# fastlane/metadata/android/ → works with both tools
```

**Note:** The metadata directory (`fastlane/metadata/android/`) is fully compatible. You can rename it if you want (e.g., `metadata/`) — just update the `--dir` flag.

## Verification

- `gpc doctor` passes all checks
- `gpc listings push --dir fastlane/metadata/android/ --dry-run` shows no errors
- `gpc releases upload app.aab --track internal --dry-run` validates the bundle
- CI pipeline runs successfully with GPC commands
- Metadata and screenshots match what was uploaded via Fastlane

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Auth fails with same key | Key path differs between tools | Use absolute path or `GPC_SERVICE_ACCOUNT` env var |
| Metadata push shows no changes | GPC already matches Play Store | This is expected — both tools read the same source |
| Rollout percentage wrong | Fastlane uses decimal (0.1), GPC uses percentage (10) | Convert: multiply Fastlane value by 100 |
| Screenshots missing after push | GPC listings push doesn't push images | Use `gpc listings images upload` separately |
| CI slower than Fastlane | Ruby/Bundler vs Node.js startup | Use `npx @gpc-cli/cli` or pre-install globally; both are fast |
| `EDIT_CONFLICT` error | Fastlane and GPC both have open edits | Don't run both tools simultaneously on the same app |

## Related skills

- **gpc-setup** — initial authentication and configuration
- **gpc-metadata-sync** — detailed metadata management beyond migration
- **gpc-release-flow** — full release lifecycle with GPC
- **gpc-ci-integration** — CI/CD pipeline setup with GPC
