---
name: gpc-release-flow
description: "Use when uploading, releasing, promoting, or managing rollouts on Google Play. Make sure to use this skill whenever the user mentions gpc releases, upload AAB, upload APK, staged rollout, promote to production, halt rollout, gpc publish, release notes, track management, internal testing, beta release, production rollout, version code, rollout percentage, or wants to ship an Android app to any Play Store track. Also trigger when someone asks about the Google Play edit lifecycle, release validation, or how to do a phased rollout — even if they don't mention GPC by name. For metadata and listings, see gpc-metadata-sync. For CI/CD integration, see gpc-ci-integration."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill). For private-app publishing to Managed Google Play, see gpc-enterprise (v0.9.56+)."
metadata:
  version: 1.4.0
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
- **Updating a private app** (created via `gpc enterprise publish` in v0.9.56+) — after the initial custom-app creation, all subsequent operations use the standard commands in this skill against the assigned `packageName`

**Not this skill:**
- Creating a new *private* app for Managed Google Play — use `gpc-enterprise` (v0.9.56+). After creation, come back here for version uploads and track management.

## Inputs required

- Path to AAB/APK file
- Target track (internal, alpha, beta, production, or custom)
- Rollout percentage (for staged rollouts)
- Release notes (inline or from file)
- Whether `--dry-run` is desired (preview without executing)

## Procedure

### 0) Pre-flight validation

Before uploading, run the preflight compliance scanner and validate the bundle:

```bash
# Policy compliance scan (offline -- checks manifest, permissions, 64-bit, secrets)
gpc preflight app-release.aab --fail-on error
gpc preflight app-release.apk --fail-on error  # APK also supported

# File format and track validation
gpc validate app-release.aab
gpc validate app-release.aab --track beta  # Validate for specific track
```

`gpc preflight` checks the AAB/APK against Google Play policies (target SDK, permissions, native libs, etc.). `gpc validate` checks file format, version code conflicts, and track compatibility.

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

# Upload APK (auto-detected, uses correct endpoint)
gpc releases upload app-release.apk --track internal

# Upload with staged rollout
gpc releases upload app-release.aab --track production --rollout 10

# Upload as draft (not visible to users until explicitly released)
gpc releases upload app-release.aab --track production --status draft

# Set release notes
gpc releases notes set --track beta --lang en-US --notes "Bug fixes"
gpc releases notes set --track beta --file release-notes/  # From directory
```

> **New in v0.9.47:** APK files are auto-detected and uploaded via the correct `edits.apks.upload` endpoint. Use `--status draft` to create draft releases for manual review in the Play Console before going live.

#### Additional upload flags (v0.9.51+)

```bash
# Upload native debug symbols (ProGuard mapping or native code symbols)
gpc releases upload app.aab --track internal --mapping-type proguard  # default
gpc releases upload app.aab --track internal --mapping-type nativeCode

# Target a specific device tier configuration
gpc releases upload app.aab --track production --device-tier-config 12345
gpc releases upload app.aab --track production --device-tier-config LATEST

# Skip sending changes for review (required for rejected apps)
gpc releases upload app.aab --track production --changes-not-sent-for-review

# Fail safely if there are changes already in review
gpc releases upload app.aab --track production --error-if-in-review
```

| Flag | Values | Description |
|------|--------|-------------|
| `--mapping-type` | `proguard` (default), `nativeCode` | Specifies the type of debug symbols to upload alongside the bundle. Use `nativeCode` when shipping native (C/C++) libraries |
| `--device-tier-config` | numeric ID or `LATEST` | Applies a device tier targeting configuration so different APKs are served to different device classes |
| `--changes-not-sent-for-review` | boolean flag | Commits the edit without sending changes for review. Required when a previous submission was rejected and you are not yet ready for re-review |
| `--error-if-in-review` | boolean flag | Causes the command to exit with a non-zero code if there are already changes in review, instead of silently overwriting them |

### Rejected Apps

When Google Play rejects a submission, your app enters a "changes in review" state. Subsequent uploads or promotions will fail unless you handle this explicitly:

1. **If you want to push changes without triggering a new review** (e.g., updating metadata while fixing the rejection reason), use `--changes-not-sent-for-review`. This commits your edit but leaves the review state untouched.
2. **If you want to guard against accidentally overwriting in-review changes** (e.g., a CI pipeline that should not clobber a pending review), use `--error-if-in-review`. The command will exit with code 4 (`API` error) if changes are currently in review.
3. **If you are ready to re-submit for review**, omit both flags and upload normally. Google Play will replace the pending submission with your new one.

These flags apply to `gpc releases upload`, `gpc publish`, `gpc releases promote`, `gpc releases rollout`, `gpc listings push/update/delete`, `gpc listings images upload/delete`, `gpc testers add/remove/import`, `gpc tracks create/update`, and `gpc apps update`.

> **Note (v0.9.52+):** When `--changes-not-sent-for-review` is set, GPC skips server-side edit validation (`edits.validate`) and goes straight to `edits.commit`. This is required because Google's validate endpoint does not accept the `changesNotSentForReview` parameter and rejects edits for apps with rejected updates. Your changes are still validated by the commit call itself.
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

# Promote as draft (review in Play Console before going live)
gpc releases promote --from internal --to beta --status draft
```

> **Note:** Since v0.9.39, `gpc releases promote` auto-retries once on 409 EDIT_CONFLICT (another edit is open).

Promote also supports the review-control flags (v0.9.51+):

```bash
# Promote without sending for review (rejected app workflow)
gpc releases promote --from internal --to beta --changes-not-sent-for-review

# Fail if changes are already in review
gpc releases promote --from beta --to production --rollout 5 --error-if-in-review
```

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

> **New in v0.9.46:** The `releases.list` endpoint provides release lifecycle states without opening an edit session. Use it to check whether a release is still in review, has been published, or is in draft -- useful for CI pipelines that need to gate on review completion.

### 3d) Release stats and history

```bash
# Release count per track with status breakdown
gpc releases count

# Show release history from GitHub
gpc changelog
gpc changelog --tag v0.9.47

# Generate GitHub Release notes from local commits (v0.9.61+)
gpc changelog generate                              # markdown for the next release
gpc changelog generate --format prompt | pbcopy     # paste into Claude/ChatGPT
gpc changelog generate | gh release create vX -F -  # one-command release
gpc changelog generate --strict                     # fail CI on linter warnings (jargon, scope leaks)
```

::: tip Two different release notes flows
- **Play Store** `recentChanges[]` (per-locale, 500-char): `gpc changelog generate --target play-store --locales auto --ai --apply` (v0.9.64+, end-to-end) or `gpc publish --notes-from-git --since vX`
- **GitHub Release** notes (canonical markdown template, smart clustering, LLM-prompt mode): `gpc changelog generate` (v0.9.61+)
:::

### Multilingual Play Store release notes (v0.9.62+)

For per-locale Play Store "What's new" text, pass `--target play-store` with `--locales`:

```bash
# Translate via your own LLM key (BYO, v0.9.63+)
gpc changelog generate --target play-store --locales auto --ai

# Explicit locales, no AI — placeholder text for non-source locales
gpc changelog generate --target play-store --locales en-US,fr-FR,de-DE

# Auto-detect from your live Play listing (one API round-trip)
gpc changelog generate --target play-store --locales auto --app com.example.app

# Preview the prompt without spending tokens
gpc --dry-run changelog generate --target play-store --locales auto --ai
```

**Key behaviors:**
- en-US source is the same bullet list as the github target, truncated to 500 Unicode code points if over
- With `--ai` (v0.9.63+): non-source locales are translated via the user's own LLM key. Auto-detects priority env order: `AI_GATEWAY_API_KEY` → `ANTHROPIC_API_KEY` → `OPENAI_API_KEY` → `GOOGLE_GENERATIVE_AI_API_KEY`. Non-reasoning model defaults (`claude-sonnet-4-6`, `gpt-4o-mini`, `gemini-2.5-flash`). Override with `--provider` / `--model`.
- Without `--ai`: non-source locales get a `[needs translation]` placeholder. Use `--format prompt` to emit a translation-ready LLM prompt for the offline / no-key workflow.
- `--strict` exits 1 if any locale overflows 500 chars OR (with `--ai`) any locale fails to translate
- Lazy-loaded: running without `--ai` imports none of the AI SDK deps. Cold-start budget preserved.

### Writing translated notes into a draft release (v0.9.64+)

Once your release notes are generated (with or without `--ai`), write them directly into the latest draft on a Play Store track:

```bash
# Full pipeline: generate + translate + apply
gpc changelog generate --target play-store --locales auto --ai --apply

# Apply to a specific track (default: production)
gpc changelog generate --target play-store --locales auto --ai --apply --track beta

# Preview what would be written (no API call)
gpc changelog generate --target play-store --locales auto --ai --apply --dry-run
```

**Key behaviors:**
- `--apply` requires `--target play-store` (not compatible with `--format prompt`)
- Writes into the **latest draft** release on the track. If no draft exists, exits with `RELEASE_NO_DRAFT` (exit code 1) and suggests creating one first
- Uses `withRetryOnConflict` for 409 edit conflicts
- `--dry-run` shows the notes that would be written without touching the API

> **Bundle upload race fix (v0.9.64+):** After uploading a large AAB (65MB+), GPC now polls `bundles.list` with Fibonacci backoff (2s, 3s, 5s, 8s, 13s) before calling `edits.validate`. This fixes intermittent `INVALID_ARGUMENT: Some of the Android App Bundle uploads are not completed yet` errors that affected all AAB upload paths.

See `apps/docs/guide/multilingual-release-notes.md` for the full walkthrough, including the Vercel AI Gateway path (cost-per-run in USD reported back).

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

Rollout commands also support review-control flags (v0.9.51+):

```bash
# Increase rollout without triggering review (rejected app workflow)
gpc releases rollout increase --track production --to 50 --changes-not-sent-for-review

# Complete rollout, but fail if there are changes in review
gpc releases rollout complete --track production --error-if-in-review
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

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Version code already used` | Same version code exists on this track | Increment `versionCode` in build |
| `APK_NOT_SIGNED` | Missing or invalid signing | Use Play App Signing or check keystore |
| `EDIT_CONFLICT` | Another edit is in progress | Wait and retry, or use Console UI to discard pending edit |
| Rollout stuck | Rollout was halted | `gpc releases rollout resume --track <track>` |
| Wrong track | Promoted to wrong track | Create new release on correct track |

Read:
- `references/troubleshooting.md`
- `references/pre-release-pipeline.md` — end-to-end: validate → upload → vitals gate → promote → staged rollout

### 8) Real-Time Developer Notifications (RTDN)

Monitor subscription and purchase events in real time:

```bash
gpc rtdn status              # Check Pub/Sub topic configuration
gpc rtdn decode <payload>    # Decode base64 notification payload
gpc rtdn test                # Guidance for testing RTDN setup
```

## Related skills

- **gpc-setup**: Authentication and configuration
- **gpc-metadata-sync**: Store listings and screenshots
- **gpc-vitals-monitoring**: Post-release crash monitoring
- **gpc-ci-integration**: Automated releases in CI/CD
- **gpc-monetization**: Subscriptions, IAP, RTDN notifications
- **gpc-enterprise**: Private app publishing to Managed Google Play via the Play Custom App Publishing API (v0.9.56+)
