---
name: gpc-metadata-sync
description: "Use when managing Google Play store listings, metadata, screenshots, or images. Make sure to use this skill whenever the user mentions gpc listings, store listing, metadata sync, screenshots, Fastlane metadata, localization, app description, pull listings, push listings, feature graphic, Play Store images, app title, short description, full description, changelogs, or wants to update any text or visual content on their Play Store page. Also trigger when someone asks about migrating from Fastlane supply, syncing metadata to/from local files, managing multi-language listings, or bulk-updating store content — even if they don't mention GPC explicitly. For releases and uploads, see gpc-release-flow."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill)."
metadata:
  version: 1.0.0
---

# GPC Metadata Sync

## When to use

Use this skill when the task involves:

- Viewing or updating store listings (title, description, short description)
- Syncing metadata between local files and Google Play Console
- Managing screenshots and images (upload, delete, list)
- Working with Fastlane-compatible metadata directory structure
- Multi-language listing management
- Pulling listings to local for version control
- Pushing local listings to Play Console

## Inputs required

- Package name (or configured default via `GPC_APP`)
- Language code(s) (e.g., `en-US`, `ja-JP`)
- For push/pull: local directory path for metadata files
- For images: image type and file paths

## Procedure

### 0) View current listings

```bash
# Default language listing
gpc listings get

# Specific language
gpc listings get --lang ja-JP

# All languages at once
gpc listings get --all-languages

# JSON output for scripting
gpc listings get --output json
```

### 1) Update listings inline

```bash
gpc listings update --lang en-US \
  --title "My App" \
  --short-desc "A great app for great things" \
  --full-desc "Full description here..."
```

Or from a metadata directory:
```bash
gpc listings update --lang en-US --file metadata/en-US/
```

### 1a) Validate listings locally (lint)

Local validation with no API call — checks character limits before pushing:

```bash
gpc listings lint

# Point at a specific metadata directory
gpc listings lint --dir metadata/
gpc listings lint --dir fastlane/metadata/android/
```

Output table:

```
Field             Chars  Limit   %    Status
────────────────────────────────────────────
title              28     30    93%    ✓
shortDescription   76     80    95%    ✓
fullDescription   3820   4000   96%    ✓
video URL          0      256    0%    ✓
```

Character limits enforced: `title` = 30, `shortDescription` = 80, `fullDescription` = 4000, video URL = 256.

Returns exit code 1 if any field exceeds its limit. Use as a pre-commit or pre-push gate.

### 1b) Validate live listings (analyze)

Fetches the live listings from Play Store and runs the same character-limit check:

```bash
gpc listings analyze

# Compare against an expected set of locales
gpc listings analyze --expected en-US,ja-JP,de-DE

# JSON output
gpc listings analyze --json
```

Same output table as `lint` but reflects what is currently live on the Play Store. The `--expected` flag will flag any locales present in your list but missing from Play Console (or vice versa).

### 2) Pull/Push workflow (bidirectional sync)

This is the recommended workflow for version-controlling your listings.

#### Pull (download from Play Console to local):

```bash
gpc listings pull --dir metadata/
```

Creates a directory structure:
```
metadata/
├── en-US/
│   ├── title.txt
│   ├── short_description.txt
│   ├── full_description.txt
│   └── changelogs/
│       └── 142.txt
├── ja-JP/
│   ├── title.txt
│   ├── short_description.txt
│   └── full_description.txt
└── ...
```

#### Push (upload local files to Play Console):

```bash
gpc listings push --dir metadata/

# Preview changes without applying
gpc listings push --dir metadata/ --dry-run

# Bypass the preflight lint gate (not recommended)
gpc listings push --dir metadata/ --force
```

**Preflight lint gate:** `gpc listings push` automatically runs `gpc listings lint` before uploading. If any field exceeds its character limit the push is aborted with exit code 1. Pass `--force` to skip the gate and push anyway.

Read:
- `references/directory-structure.md`

### 3) Fastlane compatibility

GPC reads and writes the Fastlane metadata directory format. If you're migrating from Fastlane:

```bash
# Your existing Fastlane metadata/ directory works as-is
gpc listings push --dir fastlane/metadata/android/

# Pull into Fastlane-compatible structure
gpc listings pull --dir fastlane/metadata/android/
```

Read:
- `references/fastlane-migration.md`

### 4) Image management

#### List existing images:
```bash
gpc listings images list --lang en-US --type phoneScreenshots
```

Image types: `phoneScreenshots`, `sevenInchScreenshots`, `tenInchScreenshots`, `tvScreenshots`, `wearScreenshots`, `icon`, `featureGraphic`, `tvBanner`, `promoGraphic`.

#### Upload images:
```bash
# Single image
gpc listings images upload --lang en-US --type phoneScreenshots screenshot.png

# Multiple images (glob)
gpc listings images upload --lang en-US --type phoneScreenshots ./screens/*.png
```

#### Delete images:
```bash
gpc listings images delete --lang en-US --type phoneScreenshots --id <image-id>
```

### 5) Multi-language workflow

For apps with many languages:

```bash
# Pull all languages
gpc listings pull --dir metadata/

# Edit locally (use your preferred text editor or translation tools)

# Push all languages back
gpc listings push --dir metadata/ --dry-run  # Preview first
gpc listings push --dir metadata/            # Apply
```

### 6) Preview with dry-run

All write operations support `--dry-run`:

```bash
gpc listings update --lang en-US --title "New Title" --dry-run
gpc listings push --dir metadata/ --dry-run
```

## Verification

- `gpc listings get --lang <lang>` shows updated content
- `gpc listings get --all-languages` confirms all languages are correct
- `gpc listings images list --lang <lang> --type <type>` shows uploaded images
- Play Console UI reflects the changes (may take a few minutes)

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `LISTING_NOT_FOUND` | Language not set up in Play Console | Add the language in Console first, then push |
| Image upload fails | Wrong format or size | Check Google's image requirements (PNG/JPEG, size limits per type) |
| Truncated description | Exceeds character limit | Title: 30 chars, short desc: 80 chars, full desc: 4000 chars |
| Push shows no changes | Local files match remote | Confirm edits are saved in the correct file paths |
| Encoding issues | Non-UTF-8 file encoding | Ensure all text files are UTF-8 encoded |

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-release-flow**: Upload and release management
- **gpc-ci-integration**: Automated metadata sync in CI/CD
