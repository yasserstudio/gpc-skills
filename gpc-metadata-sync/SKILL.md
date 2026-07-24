---
name: gpc-metadata-sync
description: "Use when managing Google Play store listings, metadata, screenshots, or images. Make sure to use this skill whenever the user mentions gpc listings, store listing, metadata sync, screenshots, Fastlane metadata, localization, app description, pull listings, push listings, feature graphic, Play Store images, app title, short description, full description, changelogs, image sync, image dedup, listings images sync, save quota, publish quota exceeded, too many API saves, screenshot display order, or wants to update any text or visual content on their Play Store page. Also trigger when someone asks about migrating from Fastlane supply, syncing metadata to/from local files, managing multi-language listings, or bulk-updating store content — even if they don't mention GPC explicitly. For releases and uploads, see gpc-release-flow."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill)."
metadata:
  version: 1.5.0
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

# Prevent changes from being auto-submitted for review
gpc listings push --dir metadata/ --changes-not-sent-for-review

# Fail if the app is currently in review or rejected
gpc listings push --dir metadata/ --error-if-in-review

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

# Preview what would be uploaded without making API calls (v0.9.74+)
gpc listings images upload --lang en-US --type phoneScreenshots ./screens/*.png --dry-run
```

#### Delete images:
```bash
gpc listings images delete --lang en-US --type phoneScreenshots --id <image-id>

# Preview what would be deleted without making API calls (v0.9.74+)
gpc listings images delete --lang en-US --type phoneScreenshots --dry-run
```

> **New in v0.9.74:** Both `gpc listings images upload` and `gpc listings images delete` respect `--dry-run`. In dry-run mode, the commands print what would happen (files that would be uploaded, image IDs that would be deleted) without calling the Play API.

#### Sync images from a local directory (v0.9.69+) — PREFER THIS over per-image upload/delete

`gpc listings images sync` uses SHA-256 content hashing to deduplicate images — it only uploads files that are not already on Play Store, and optionally deletes remote images that have no local counterpart. It does the entire job inside **one** Play edit and **one** commit.

> **Save-quota rule (important — always reach for `sync` first).** Google enforces a per-app **publish (save) limit** that is far lower than the general API request quota, and every committed edit counts as one save. The per-image `gpc listings images upload` and `gpc listings images delete` commands each open and commit their own edit, so looping them over many locales burns one save per call — e.g. 5 images × 27 locales × 2 form factors with delete-then-upload is roughly 540 saves per run and exhausts the daily limit in a few runs. `sync --dir` (optionally with `--delete`) collapses the whole run into a single save, and a no-op re-run (nothing changed) is discarded without committing, costing zero. Only use the standalone `upload`/`delete` commands for a genuine one-off single-image fix.

```bash
# Sync EVERY locale and image type under a tree, mirror deletions — one save for the whole run
gpc listings images sync --dir ./images --delete

# Sync all phone screenshots for en-US from a local directory
gpc listings images sync --lang en-US --type phoneScreenshots --dir ./screens/

# Sync all image types for a language
gpc listings images sync --lang en-US --dir ./screenshots/en-US/

# Preview what would change without touching the API (spends no save)
gpc listings images sync --dir ./images --delete --dry-run
```

**Key behaviors:**
- SHA-256 hash of each local file is compared against the remote image hash. Already-matching images are skipped (no re-upload).
- Whole run is a single edit + single commit = **one save** (zero on a no-op). This is the quota-safe path; see the save-quota rule above.
- `--delete` removes remote images that have no matching local file. Without this flag, extra remote images are left in place.
- **Display order guaranteed with `--delete` (v0.9.92+):** the Play API has no reorder endpoint and keeps upload order, so a hash-only partial update would leave screenshots out of order (unchanged image keeps its slot, changed one is appended). When a locale/type differs from local in content *or* order, `--delete` clears that combo in one call and re-uploads local files in sorted filename order (`1.png`, `2.png`, ...); a combo already in order is skipped. Name files to sort in display order; zero-pad (`01.png`) near a per-type cap.
- **Absent-directory safety (v0.9.92+):** a type directory that is absent locally is left untouched, so syncing only screenshots never wipes a remote icon or feature graphic. A present-but-empty directory is an explicit "clear this type."
- `--dry-run` prints a diff table (`add / skip / delete`) without making any API calls.
- Supports the same image types as `gpc listings images upload`: `phoneScreenshots`, `sevenInchScreenshots`, `tenInchScreenshots`, `tvScreenshots`, `wearScreenshots`, `icon`, `featureGraphic`, `tvBanner`, `promoGraphic`.

| Flag | Description |
|------|-------------|
| `--dir` | Local directory containing image files to sync |
| `--lang` | Language code (e.g., `en-US`, `ja-JP`) |
| `--type` | Image type filter (omit to sync all types in the directory) |
| `--delete` | Delete remote images with no local counterpart |
| `--dry-run` | Preview changes without uploading or deleting |

### 5) Multi-language workflow

For apps with many languages:

```bash
# Pull all languages
gpc listings pull --dir metadata/

# Edit locally (use your preferred text editor or translation tools)

# Push all languages back
gpc listings push --dir metadata/ --dry-run  # Preview first
gpc listings push --dir metadata/ --changes-not-sent-for-review  # Apply without auto-submitting for review
```

**Tip:** For generating per-locale "What's new" release notes text (not the full listing fields), see `gpc changelog generate --target play-store` (v0.9.62+) — it takes your git log and emits per-locale output with the 500-char Play Store budget enforced. Add `--ai` (v0.9.63+) to translate non-source locales via your own LLM key (auto-detects `AI_GATEWAY_API_KEY` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GOOGLE_GENERATIVE_AI_API_KEY`).

### 6) Preview with dry-run

All write operations support `--dry-run`:

```bash
gpc listings update --lang en-US --title "New Title" --dry-run
gpc listings push --dir metadata/ --dry-run
gpc listings images upload --lang en-US --type phoneScreenshots ./screens/*.png --dry-run
gpc listings images delete --lang en-US --type phoneScreenshots --dry-run
gpc listings images sync --lang en-US --type phoneScreenshots --dir ./screens/ --dry-run
```

In dry-run mode no API calls are made. The output describes what would change: files that would be uploaded, image IDs that would be deleted, and fields that would be updated.

## Verification

- `gpc listings get --lang <lang>` shows updated content
- `gpc listings get --all-languages` confirms all languages are correct
- `gpc listings images list --lang <lang> --type <type>` shows uploaded images
- Play Console UI reflects the changes (may take a few minutes)

## Security notes (v0.9.74+)

### Symlink traversal protection in --notes-dir

When `--notes-dir` is used to load release notes (e.g. `gpc releases upload --notes-dir changelogs/`), GPC now calls `lstat()` on every entry and rejects symbolic links before reading file contents. This prevents directory traversal attacks where a crafted symlink inside the notes directory points to sensitive files outside the tree (e.g. `/etc/passwd`, SSH keys).

If a symlink is encountered, the command exits with a descriptive error identifying the offending path. Use real files in your notes directories.

### CSV formula injection prevention in review exports

`gpc reviews export` and other commands that produce CSV output now prefix cells that begin with `=`, `+`, `-`, `@`, tab (`\t`), or carriage return (`\r`) with a single quote (`'`). This prevents spreadsheet applications (Excel, Google Sheets) from interpreting user-supplied content (review text, app titles) as formulas when the CSV is opened.

If you process the CSV programmatically, strip the leading `'` from string values where needed.

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `LISTING_NOT_FOUND` | Language not set up in Play Console | Add the language in Console first, then push |
| Daily save/publish quota exceeded after a few runs | Looping per-image `upload`/`delete` (one committed edit = one save each) | Switch to `gpc listings images sync --dir ... --delete` (one save for the whole run) and `gpc listings push --dir` for text. See the save-quota rule in section 4. |
| Screenshots out of display order after a partial update | Older GPC, or per-image upload appends changed images last | Upgrade to v0.9.92+ and use `sync --delete` (guarantees order); name files `1.png`, `2.png`, ... |
| Image upload fails | Wrong format or size | Check Google's image requirements (PNG/JPEG, size limits per type) |
| Truncated description | Exceeds character limit | Title: 30 chars, short desc: 80 chars, full desc: 4000 chars |
| Push shows no changes | Local files match remote | Confirm edits are saved in the correct file paths |
| Encoding issues | Non-UTF-8 file encoding | Ensure all text files are UTF-8 encoded |

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-release-flow**: Upload and release management
- **gpc-ci-integration**: Automated metadata sync in CI/CD
