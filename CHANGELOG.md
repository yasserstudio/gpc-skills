# Changelog

## v1.19.0 -- 2026-04-29

Synced with GPC v0.9.70.

### Updated Skills

- **gpc-release-flow** (1.5.0 -> 1.6.0) -- Added v0.9.70 upload flags section: `--in-app-update-priority <0-5>`, `--retain-version-codes <csv>`, and versioned `--notes-dir` (Fastlane-style `{lang}/{versionCode}.txt` with `default.txt` fallback). Added promote preservation note (priority and name now preserved from source release). Updated skill description with new trigger keywords.

- **gpc-migrate-fastlane** (1.3.0 -> 1.4.0) -- Added v0.9.70 command mappings: `in_app_update_priority`, `version_codes_to_retain`, and Fastlane-style versioned changelogs with `default.txt` fallback.

- **gpc-vitals-monitoring** (1.4.0 -> 1.5.0) -- Added freshness clamping documentation: GPC now queries the freshness endpoint per metric set and clamps date ranges automatically. No more 400 errors when Google's data lags 3-4 days behind.

- **gpc-ci-integration** (1.4.0 -> 1.5.0) -- Updated Node.js version references from 20 to 22 (recommended) across all CI platform examples.

### Marquee features in GPC v0.9.70

- **`--in-app-update-priority <0-5>`**: controls how aggressively Android prompts users to update via the in-app updates API.
- **`--retain-version-codes <csv>`**: keeps previous version codes active in the same track release alongside new uploads.
- **Fastlane changelog fallback**: `--notes-dir` auto-detects versioned directories, reads `{versionCode}.txt` with `default.txt` fallback per language.
- **Vitals freshness clamping**: queries Google's freshness endpoint and clamps date ranges automatically.
- **Promote preservation**: `inAppUpdatePriority` and `name` preserved from source release on promote.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.70

---

## v1.18.0 -- 2026-04-27

Synced with GPC v0.9.68 and v0.9.69.

### Updated Skills

- **gpc-setup** (1.4.0 -> 1.5.0) -- Added `gpc setup` wizard section (1b): interactive one-command onboarding covering auth, app selection, config write, shell completion install, and `gpc doctor` auto-run. Documents `--auto` mode for CI/headless environments. Updated skill description to trigger on "gpc setup", "gpc setup wizard", "one-command onboarding". Updated `GPC_OUTPUT` env var to include csv/tsv formats.

- **gpc-metadata-sync** (1.2.1 -> 1.3.0) -- Added `gpc listings images sync` section (inside section 4): SHA-256 content-hash image dedup command with all options (`--dir`, `--lang`, `--type`, `--delete`, `--dry-run`), key behaviors table, and flag reference. Updated skill description to trigger on "image sync", "image dedup", "listings images sync".

- **gpc-release-flow** (1.4.0 -> 1.5.0) -- Added `gpc bundles list/find/wait` section (5b) with command reference table and CI gate usage pattern. Updated Rejected Apps section to document v0.9.69 auto-rescue behavior (automatic `changesNotSentForReview` retry on 403). Added `--validate-only` dry-run flag documentation for `gpc releases commit`. Updated skill description to trigger on bundle-related keywords.

- **gpc-ci-integration** (1.3.0 -> 1.4.0) -- Renamed section 6 to cover all output formats; added CSV/TSV output subsection with examples and guidance on when to prefer each format. Added "Wait for bundle processing" pattern using `gpc bundles wait` in multi-job pipelines. Updated skill description to trigger on CSV/TSV and bundle-wait keywords.

- **gpc-troubleshooting** (0.15.0 -> 0.16.0) -- Updated `API_CHANGES_NOT_SENT_FOR_REVIEW` entry to note v0.9.69 auto-rescue behavior: `gpc releases commit` now retries automatically on 403 for rejected-update apps.

- **gpc-migrate-fastlane** (1.2.0 -> 1.3.0) -- Added `gpc listings images sync` as the equivalent of Fastlane's `sync_image_upload` action. Added `changesNotSentForReview` auto-rescue to the failure modes table, noting this closes the #1 Fastlane supply pain point.

- **README** -- Updated gpc-setup, gpc-release-flow, and gpc-metadata-sync skill descriptions. Added 18 new entries to the Skill Selection Guide covering setup wizard, CSV/TSV output, bundle commands, image sync, and auto-rescue.

### Marquee features in GPC v0.9.68

- **`gpc setup`**: one-command onboarding wizard. Authenticates, picks app, writes config, installs completions, runs doctor. `--auto` mode for CI.
- **CSV/TSV output**: `--output csv` and `--output tsv` across all commands. No `jq` required for spreadsheet-friendly CI parsing.
- **`--validate-only`** on `gpc releases commit`: dry-run edit validation without committing.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.68

### Marquee features in GPC v0.9.69

- **`gpc listings images sync`**: SHA-256 content-hash image dedup. Skips already-uploaded images, optionally deletes removed ones. `--dry-run` shows diff without touching the API.
- **`gpc bundles list/find/wait`**: standalone bundle API commands. `wait` polls until processing finishes — CI gate between upload and promote.
- **`changesNotSentForReview` auto-rescue**: `gpc releases commit` auto-retries on 403 for rejected-update apps. No manual flag required.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.69

---

## v1.17.0 -- 2026-04-25

Synced with GPC v0.9.67. Real-time rollout monitoring with `gpc watch`.

### Updated Skills

- **gpc-vitals-monitoring** (1.3.0 -> 1.4.0) -- Added comprehensive `gpc watch` section (section 4b): unified rollout monitoring with 6 vitals metrics, 3 breach actions (notify, halt, webhook), configurable thresholds, CI mode with NDJSON output, webhook payload documentation. Old `gpc vitals watch` section replaced with note pointing to `gpc watch`. Updated skill description triggers to include rollout monitoring, auto-halt, breach notification, and webhook alerting keywords. Added verification step for `gpc watch --rounds 1`.

- **README** -- Updated gpc-vitals-monitoring description to lead with `gpc watch`. Added 3 new entries to the Skill Selection Guide: rollout monitoring, auto-halt on breach, Slack webhook on breach.

### Marquee features in GPC v0.9.67

- **`gpc watch`**: real-time rollout monitoring with 6 metrics (crashes, ANR, LMK, slow starts, slow render, error count), configurable thresholds, and 3 breach actions (OS notification, auto-halt rollout, webhook POST).
- **Smarter `gpc doctor`**: stale cache warning (>7 days) and shell completion detection.
- Webhook dispatch validates HTTP response status. Breach callbacks deduplicated via state tracking.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.67

---

## v1.16.0 -- 2026-04-24

Synced with GPC v0.9.66. Developer verification tooling: signing key audit, verification readiness checklist, signing consistency checks.

### Updated Skills

- **gpc-setup** (1.3.0 -> 1.4.0) -- Expanded developer verification section with `gpc verify checklist` (interactive 7-step readiness walkthrough), `gpc doctor --verify` (API-side signing cert + local keystore comparison via keytool), and `gpc preflight signing` (cert consistency across releases). Updated enforcement date to September 30, 2026.

- **gpc-preflight** (1.1.0 -> 1.2.0) -- Added "Signing key consistency" section documenting `gpc preflight signing` subcommand. This is NOT an offline scan: it calls the Play API to compare signing certificates across the two most recent bundle versions. Exit code 6 on mismatch. Updated description to include signing consistency triggers.

- **gpc-security** (0.12.0 -> 0.13.0) -- Added "Signing key audit" section documenting `gpc doctor --verify` and `gpc preflight signing` as tools for verifying signing key correctness before Google's enforcement deadline.

- **gpc-troubleshooting** (0.14.0 -> 0.15.0) -- Added 6 signing-related error codes to the error catalog: `EDIT_CREATE_FAILED`, `BUNDLES_LIST_FAILED`, `NO_BUNDLES`, `NO_SIGNING_CERT`, `GENERATED_APKS_FAILED`, and signing key mismatch (exit 6).

- **README** -- Updated gpc-preflight description to include signing key consistency. Added 3 new entries to the Skill Selection Guide: verification checklist, signing key comparison, cert consistency.

### Marquee features in GPC v0.9.66

- **`gpc verify`**: enriched account-aware status with app info, bundle count, signing enrollment, and days until enforcement.
- **`gpc verify checklist`**: interactive 7-step readiness walkthrough (4 auto-detected, 3 prompted). Markdown report output for CI artifacts.
- **`gpc doctor --verify`**: signing key fingerprint comparison. Pulls API-side cert via `generatedApks`, optionally compares against local keystore via `keytool`.
- **`gpc preflight signing`**: signing cert consistency across two most recent bundle versions. Exit code 6 on mismatch for CI gating.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.66

---

## v1.15.0 -- 2026-04-23

Synced with GPC v0.9.65. Three new preflight scanner rules for Google Play's April 2026 policy batch (compliance deadline: May 15, 2026).

### Updated Skills

- **gpc-preflight** (1.0.0 -> 1.1.0) -- Added "April 2026 policy rules" section documenting three new scanner rules: `contacts-permission-broad` (flags READ_CONTACTS/WRITE_CONTACTS, warning), `geofencing-foreground-service` (flags location FGS + ACCESS_BACKGROUND_LOCATION, warning), `health-connect-granular` (flags READ_ALL_HEALTH_DATA, warning on targetSdk >= 36, info otherwise). Updated scanner table to reflect new checks and severity ranges. Added all three rules to the Key rules table with version tags.

- **README** -- Added GPC v0.9.65+ compatibility bullet for April 2026 policy scanners. Added "Check May 2026 policy compliance" entry to the Skill Selection Guide.

### Marquee features in GPC v0.9.65

- **Contacts broad access:** `contacts-permission-broad` flags READ_CONTACTS/WRITE_CONTACTS. Google requires the Android Contact Picker instead. Single finding for both permissions.
- **Geofencing foreground service:** `geofencing-foreground-service` fires on location FGS + ACCESS_BACKGROUND_LOCATION. Geofencing removed as approved FGS use case.
- **Health Connect granular:** `health-connect-granular` flags READ_ALL_HEALTH_DATA. Warning on targetSdk >= 36, info otherwise. Android 16 requires per-data-type permissions.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.65

### Why this matters

Google's April 2026 policy batch affects three common permission patterns. GPC is the first CLI to catch these offline before upload. The May 15 deadline is 22 days away. Skills stay accurate: only `gpc-preflight` needed updating since the new rules are scanner additions, not new commands.

---

## v1.14.0 -- 2026-04-22

Synced with GPC v0.9.64. Closes the changelog-generation series (v0.9.61-v0.9.64): from git commits to translated Play Store release notes written into a draft release, one command.

### Updated Skills

- **gpc-release-flow** (1.3.1 → 1.4.0) -- Added full `--apply` + `--track` section (v0.9.64+) for writing translated notes directly into a Play Store draft release. Documented the bundle upload race fix (Fibonacci-backoff poll after AAB upload for 65MB+ bundles). Updated the "Two different release notes flows" tip to show the end-to-end `--ai --apply` pipeline.

- **gpc-ci-integration** (1.2.1 → 1.3.0) -- Added "Write translated notes into a Play Store draft" CI step example showing `--ai --apply --track production`.

- **gpc-sdk-usage** (1.3.0 → 1.4.0) -- Compatibility string extended with v0.9.64 exports: `applyReleaseNotes`, `waitForBundleProcessing`, `validateBundleForApply`, `bundleToReleaseNotes`. New "Apply release notes to a draft" code example.

- **gpc-troubleshooting** (0.13.0 → 0.14.0) -- Added `RELEASE_NO_DRAFT` and `BUNDLE_PROCESSING_TIMEOUT` error codes (v0.9.64+).

- **gpc-setup** (1.2.0 → 1.3.0) -- Rewrote "Browse documentation from CLI" section for the v0.9.64 embedded docs system: `gpc docs list` (99 pages), `gpc docs show <topic>` (fuzzy matching, ANSI rendering, `$PAGER`), `gpc docs search <query>`, `gpc docs init` (GPC.md for AI agents), `gpc docs web` (browser fallback).

- **gpc-onboarding** (0.12.0 → 0.13.0) -- Updated post-setup commands: replaced `gpc docs --list` (58 topics) with the new v0.9.64 subcommands (`docs list`, `docs show`, `docs search`, `docs init`; 99 topics).

- **gpc-migrate-fastlane** (1.1.0 → 1.2.0, via `references/command-mapping.md`) -- Updated forward-refs: `--ai` and `--apply` are now shipped (no longer future tense). Added end-to-end one-liner.

- **README** -- Added v0.9.64+ compatibility bullet (`--apply`, bundle race fix, embedded docs). Added 5 new entries in the Skill Selection Guide. Added Embedded Docs Command Reference to Related links.

### Marquee features in GPC v0.9.64

- **`--apply` + `--track`:** `gpc changelog generate --target play-store --locales auto --ai --apply` does commit → translated Play Store notes → written into draft release, one command. Uses `withRetryOnConflict` for 409s. Exits `RELEASE_NO_DRAFT` if no draft exists.
- **Bundle upload race fix:** After uploading a large AAB (65MB+), GPC polls `bundles.list` with Fibonacci backoff (2s, 3s, 5s, 8s, 13s) before `edits.validate`. Fixes `INVALID_ARGUMENT: Some of the Android App Bundle uploads are not completed yet`.
- **Embedded docs:** 99 pages built at compile time into a JSON bundle. `gpc docs list/show/search/init/web`. Zero runtime deps. Works offline, in SSH, in CI.
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.64

### Why this matters

The v0.9.61-v0.9.64 changelog-generation series is complete. GPC is the first Android publishing CLI to go from git commits to translated, budget-enforced Play Store release notes in one command. The embedded docs system means the full 99-page documentation is available offline, in SSH sessions, and in CI.

---

## v1.13.0 -- 2026-04-20

Synced with GPC v0.9.63 (AI-assisted Play Store translation). Marquee addition: `gpc changelog generate --target play-store --locales auto --ai` translates non-source locales via the user's own LLM key, with Gateway-primary routing when `AI_GATEWAY_API_KEY` is present (cost-per-run in USD reported back).

### Updated Skills

- **gpc-release-flow** (1.3.0 → 1.3.1) -- Multilingual Play Store release notes section expanded with the v0.9.63 `--ai` flag as the primary translation path. Added env priority (`AI_GATEWAY_API_KEY` → `ANTHROPIC_API_KEY` → `OPENAI_API_KEY` → `GOOGLE_GENERATIVE_AI_API_KEY`) and non-reasoning model defaults. Added `--dry-run` preview workflow. Called out the lazy-loading invariant so agents know the feature is opt-in with no cold-start cost. Existing `--format prompt` workflow retained as the offline / no-key alternative.

- **gpc-metadata-sync** (1.2.0 → 1.2.1) -- Tip that points at `gpc changelog generate --target play-store` now mentions `--ai` (v0.9.63+) and the four env keys the resolver auto-detects.

- **gpc-ci-integration** (1.2.0 → 1.2.1) -- New "Translate release notes on every tag" section with a GitHub Actions YAML example wiring `ANTHROPIC_API_KEY` (or equivalents) through `--ai --strict --format json`. Highlights the new `ai` block in the JSON output (provider / model / tokens / runId / costUsd) for log aggregation.

### Why this matters

v0.9.63 turns the `[needs translation]` placeholder that v0.9.62 shipped into real translated text. The series (v0.9.61 GitHub Release notes → v0.9.62 per-locale Play Store budget → v0.9.63 AI translation → v0.9.64 `--apply`) is now three of four shipped. Skills stayed accurate through v0.9.63's additive changes — no existing command behavior changed, only new flags surfaced. Patch-bump skills rather than minor because the updates are documentation-only.

## v1.12.0 -- 2026-04-17

New interop skill bridging Google's official [Android CLI](https://android-developers.googleblog.com/2026/04/build-android-apps-3x-faster-using-any-agent.html) (released 2026-04-16; build/dev scope) with GPC (publishing scope).

### New Skills

- **gpc-android-cli-interop** (1.0.0) -- Handoff router between Google's Android CLI and GPC. Triggers when an agent has just finished `android create` / `android run` / `android build`, or when a prompt bridges the build-and-device half of Android development with the Play Store publishing half. The skill is intentionally thin: it confirms the handoff point (AAB/APK on disk), runs `gpc doctor` and `gpc preflight`, then delegates to the right GPC skill (`gpc-release-flow`, `gpc-vitals-monitoring`, `gpc-metadata-sync`, etc.) for the actual procedure. Trigger phrases include "my AAB is ready", "just finished scaffolding", "scaffold a Compose app and ship it to internal", "what's next after android run".

### Updated

- **README** -- Skill count bumped 17 → 18. New row for `gpc-android-cli-interop` in the Available Skills table. New rows in the Skill Selection Guide covering the interop triggers. New Compatibility bullet noting v1.12.0+ pairs with Google's Android CLI. New Related link pointing at the [Android CLI Interop guide](https://yasserstudio.github.io/gpc/guide/android-cli-interop) in the GPC docs (published same day as v1.12.0 in commit `674deb5`).

### Why this matters

Google's announcement standardizes `SKILL.md` as the agent-readable format for Android tooling. gpc-skills has shipped this pattern since v0.9.56, so no architecture change was needed. `gpc-android-cli-interop` is the explicit handoff layer that lets an agent route a prompt like "scaffold and ship this Compose app" across both skill packs without the user having to know which tool owns which stage. The prior versions of gpc-skills already cover every Play Store operation this requires — the new skill is a 1-file router that makes the handoff legible at prompt-routing time.

## v1.11.0 -- 2026-04-17

Synced with GPC v0.9.57 → v0.9.62 (6 GPC releases since the v1.10.0 sync). Marquee additions: `gpc changelog generate` (v0.9.61) and its multilingual Play Store target (v0.9.62), plus shell-completion walker + dynamic TAB values, vitals `error-count`, LMK API correction, and OTP offer activate/deactivate.

### Updated Skills

- **gpc-release-flow** (1.2.1 → 1.3.0) -- Added the v0.9.61 `gpc changelog generate` commands with prompt-mode example (`--format prompt | pbcopy`) and the `gh release create -F -` one-liner. Added a "Two different release notes flows" tip clarifying the GitHub Release vs Play Store `recentChanges[]` distinction. Added a full "Multilingual Play Store release notes (v0.9.62+)" section covering `--target play-store --locales <csv|auto>`, the 500-char budget meter, the `[needs translation]` placeholder, and `--strict` overflow handling.

- **gpc-ci-integration** (1.1.0 → 1.2.0) -- Added a v0.9.61 `Generate GitHub Release notes` step to the GitHub Actions workflow example (`gpc changelog generate | gh release create -F -`). Added a v0.9.62 "Gate Play Store release notes on character budget" step (`--target play-store --locales auto --strict`) for CI gates.

- **gpc-sdk-usage** (1.2.0 → 1.3.0) -- Compatibility string extended with the v0.9.62 changelog exports (`generateChangelog`, `renderPlayStore`, `resolveLocales`, `buildLocaleBundle`, `PLAY_STORE_LIMIT`, `LocaleBundle`, `LocaleEntry`). Endpoint count bumped 216 → 217 (v0.9.57 API correctness pass). New "Changelog generation (v0.9.62+)" section with a typed TypeScript example covering both GitHub and Play Store targets. New "API correctness history (recent)" section documenting the v0.9.57 `apprecovery` URL + `dataSafety.update` verb fixes, the removed phantom `dataSafety.get`, the added OTP offer `activateOffer`/`deactivateOffer` methods, the new `getVitalsErrorCount` function, and the v0.9.58/v0.9.59 LMK resource-name correction arc.

- **gpc-metadata-sync** (1.1.0 → 1.2.0) -- Added a multilingual tip in the Multi-language workflow section pointing users at `gpc changelog generate --target play-store` (v0.9.62+) for per-locale "What's new" generation.

- **gpc-migrate-fastlane** (1.0.0 → 1.1.0, via `references/command-mapping.md`) -- Added "Release-notes automation (v0.9.62+)" block showing the GPC equivalent of Fastlane's per-locale `metadata/android/<lang>/changelogs/<version>.txt` pattern. Forward-refs to v0.9.63 (`--ai` translation) and v0.9.64 (`--apply` into draft release).

- **gpc-vitals-monitoring** (1.2.0 → 1.3.0) -- New "Count of error occurrences (`gpc vitals error-count`, v0.9.57+)" section with a CI threshold example. Rewrote the `gpc vitals lmk` block to reflect the v0.9.59-corrected API shape (`lmkRateMetricSet` with `userPerceivedLmkRate` + weighted variants + `distinctUsers`); documented the v0.9.58/v0.9.59 hotfix arc so users know to use v0.9.59+ for LMK.

- **gpc-monetization** (0.11.1 → 0.12.0) -- Added an OTP offers activate/deactivate section (v0.9.57+) mirroring the subscription-offer lifecycle.

- **gpc-setup** (1.1.0 → 1.2.0) -- New "Shell completion" section covering the v0.9.58+ walker-based scripts (auto-discover plugin commands, surface `.choices()` candidates) and the v0.9.60+ dynamic TAB values for `--profile`, `--app`/`--apps`, `--track` (backed by the hidden `gpc __complete` subcommand reading config + status cache, under 150ms cold).

- **gpc-troubleshooting** (0.12.0 → 0.13.0) -- Added "Changelog generation errors (v0.9.61+)" table covering `CHANGELOG_NO_TAG`, `CHANGELOG_BAD_REF`, `CHANGELOG_LOCALES_REQUIRED`, `CHANGELOG_LOCALES_INVALID`, `CHANGELOG_LOCALES_AUTO_NO_APP`, `CHANGELOG_LOCALES_EMPTY`.

- **gpc-onboarding** (0.11.0 → 0.12.0) -- Added a tab-completion callout at the end of the "After successful setup" flow pointing at the v0.9.58+ walker-based scripts with v0.9.60+ dynamic values.

- **README** -- Added new Compatibility bullets for v0.9.58+ (full completion coverage), v0.9.61+ (`gpc changelog generate`), and v0.9.62+ (multilingual release notes). Added the [Multilingual Release Notes guide](https://yasserstudio.github.io/gpc/guide/multilingual-release-notes) to the Related links.

### Marquee features in GPC v0.9.57 → v0.9.62

- **v0.9.62 — Multilingual Changelog: Play Store target.** `gpc changelog generate --target play-store --locales <csv|auto>` emits per-locale "What's new" text with 500-char Unicode code-point budget enforcement. `--locales auto` reads your live listing via the listings API. `--format prompt` emits a translation-ready LLM prompt. `--strict` exits 1 on overflow (collects all overflows first). Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.62
- **v0.9.61 — Smarter Changelog Generation.** New `gpc changelog generate` subcommand clusters git commits via Union-Find on file-path overlap + Jaccard keyword similarity + time proximity, lints subjects against project voice, emits canonical GitHub Release markdown / JSON / paste-ready LLM prompt. `--strict` for CI voice enforcement. Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.61
- **v0.9.60 — Dynamic Tab Completion.** Hidden `gpc __complete <ctx>` subcommand feeds live `profiles` / `packages` / `tracks-for-app` / `releases-for-track` from config + status cache into bash/zsh/fish at TAB time. Zsh upgraded to real `_arguments` integration.
- **v0.9.58 — Shell Completion Walker.** Introspection-based command tree replaces hand-maintained completion; plugin commands auto-complete. Constrained flags with `.choices()` surface their candidate list at TAB time.
- **v0.9.59 — LMK Hotfix.** v0.9.58 shipped the wrong `VitalsMetricSet` resource name; v0.9.59 is the corrected build (`lmkRateMetricSet` with `userPerceivedLmkRate` + weighted variants).
- **v0.9.57 — API Correctness.** `apprecovery.cancel/deploy` URL plural fix; `dataSafety.update` verb corrected to POST; phantom `dataSafety.get` removed; OTP offer `activateOffer`/`deactivateOffer` added; new `gpc vitals error-count` command; type completeness audit.

### Why this matters

The v0.9.61 → v0.9.62 changelog-generation series is the single most user-visible change in this sync. Fastlane's `supply` and gradle-play-publisher don't generate release notes from git, and they don't solve per-locale Play Store "What's new" budget enforcement. GPC v0.9.62 is the first publishing CLI to solve this end-to-end. Skills `gpc-release-flow`, `gpc-ci-integration`, and `gpc-migrate-fastlane` surface this new surface so Claude Code can guide users through the commit → markdown and commit → per-locale flows. v0.9.63 will add `--ai` (Vercel AI SDK translation) and v0.9.64 closes the loop with `--apply` into draft releases.

---

## v1.10.0 -- 2026-04-11

Synced with GPC v0.9.56. **First Android publishing CLI with Managed Google Play support** — rewrote `gpc enterprise` against the Play Custom App Publishing API, shipped a new dedicated skill, and updated downstream skills to reference the new surface.

### New Skills

- **gpc-enterprise** (1.0.0) -- NEW SKILL. Covers `gpc enterprise publish <bundle>` / `gpc enterprise create` for publishing private apps to Managed Google Play via the Play Custom App Publishing API. Includes the permanent-private warning, the `--account` vs deprecated `--org` flag surface, the repeatable `--org-id`/`--org-name` flag matching, the required setup (enable API in Google Cloud + grant "create and publish private apps" permission in Play Console), a CI/CD GitHub Actions recipe, and the troubleshooting table for `ENTERPRISE_INVALID_ACCOUNT_ID`, `ENTERPRISE_BUNDLE_NOT_FOUND`, and `MISSING_REQUIRED_OPTION`. Also documents the "subsequent updates via regular commands" pattern (once a private app is created, it's a normal draft app in your developer account — use `gpc releases upload` against the returned `packageName` for future versions).

### Updated Skills

- **gpc-sdk-usage** (1.1.1 → 1.2.0) -- Adds a new "Create the Enterprise client" section covering `createEnterpriseClient`, `CustomApp` type, `HttpClient.uploadCustomApp<T>`, and `ResumableUploadOptions.initialMetadata`. Updates the endpoint count from 215 to 216 (Play Custom App API adds one). Documents the multipart resumable upload pattern where the initial session-initiation POST carries JSON metadata alongside the binary — reusable infrastructure for any Google API that wants both metadata and a binary in a single resumable session.
- **gpc-release-flow** (1.2.0 → 1.2.1) -- Adds a "Not this skill" note pointing at `gpc-enterprise` for initial private-app creation. Clarifies that subsequent updates to private apps still go through `gpc-release-flow` (upload, promote, rollout) against the assigned `packageName`. Adds `gpc-enterprise` to the Related skills list.
- **README** -- Added `gpc-enterprise` to the available skills table (total 16 → 17). Added 6 new entries in the Skill Selection Guide for enterprise queries. Updated the Compatibility section to flag that `gpc-enterprise` requires GPC v0.9.56+. Added a link to the Enterprise Publishing guide in the Related section. Fixed the License section to reflect "Free to use" framing per the main repo policy (not "MIT licensed" in marketing).

### Marquee feature in GPC v0.9.56

- `gpc enterprise publish <bundle>` — one-shot private app publishing to Managed Google Play
- `gpc enterprise create --bundle <path>` — explicit-arg variant
- `gpc doctor` probes the Play Custom App Publishing API and flags missing permissions or a disabled API
- New docs guide: https://yasserstudio.github.io/gpc/guide/enterprise-publishing
- Release: https://github.com/yasserstudio/gpc/releases/tag/v0.9.56

### Why this matters

**Fastlane `supply` does not support this API. `gradle-play-publisher` does not support this API.** GPC v0.9.56 is the first Android publishing CLI to wrap the Play Custom App Publishing API. This sync releases the corresponding agent skill so Claude Code can guide users through the private-app publishing flow end-to-end: initial setup, the permanent-private confirmation, the one-command publish, and the hand-off back to standard `gpc releases upload` for subsequent updates.

---

## v1.9.2 -- 2026-04-09

Synced with GPC v0.9.55. API freshness audit and multi-profile CLI fix.

### Updated Skills

- **gpc-sdk-usage** (1.1.1) -- `revokeSubscriptionV2(body?: RevokeSubscriptionV2Request)` and `acknowledgeSubscription(body?: AcknowledgeSubscriptionRequest)` now show typed request bodies. Removed stale `refundSubscriptionV2` reference (endpoint was deleted in v0.9.54).
- **gpc-monetization** (0.11.1) -- Version bump for API type corrections in this domain (`offerPhase` object shape, `externalAccountId` on acknowledge, `itemBasedRefund` on revoke).
- **gpc-multi-app** (1.0.1) -- Version bump. The `--profile` / `-p` global flag now actually switches profiles as this skill has always documented. Previously silently ignored in v0.9.54 and earlier.

---

## v1.9.1 -- 2026-04-01

Synced with GPC v0.9.52. Documents the validate-skip behavior for rejected apps.

### Updated Skills

- **gpc-release-flow** -- Added v0.9.52 note: `--changes-not-sent-for-review` skips `edits.validate` (validate rejects the flag). Expanded command list that supports the flag.
- **gpc-troubleshooting** -- Added technical detail and version requirement note to `API_CHANGES_NOT_SENT_FOR_REVIEW` error catalog entry.

---

## v1.9.0 -- 2026-04-01

Synced with GPC v0.9.51. Rejected app support, native debug symbols, expansion files, monetization upsert, review pagination.

### Updated Skills

- **gpc-release-flow** (1.2.0) -- `--changes-not-sent-for-review` and `--error-if-in-review` flags on upload/promote/rollout, `--mapping-type nativeCode` for NDK debug symbols, `--device-tier-config` for device tier targeting, expansion files (OBB) upload procedure
- **gpc-troubleshooting** (0.12.0) -- Two new error codes: `API_CHANGES_NOT_SENT_FOR_REVIEW`, `API_CHANGES_ALREADY_IN_REVIEW` with causes, fixes, and examples
- **gpc-monetization** (0.11.0) -- `allowMissing` upsert on subscription/OTP/offer patch, `latencyTolerance` propagation control, configurable `regionsVersion` on create, one-time products list pagination
- **gpc-sdk-usage** (1.1.0) -- 208 endpoints, `EditCommitOptions`, `MutationOptions`, `ProductUpdateLatencyTolerance`, `DeobfuscationFileType` types, `expansionFiles` namespace, updated method signatures
- **gpc-ci-integration** (1.1.0) -- Rejected app handling in CI pipelines, `--error-if-in-review` safety pattern, `--mapping-type` and `--device-tier-config` in pipeline examples
- **gpc-vitals-monitoring** (1.2.0) -- `--start-index` on `gpc reviews list`
- **gpc-metadata-sync** (1.1.0) -- Commit flags on listings push for rejected apps
- **gpc-user-management** (0.11.0) -- Commit flags on testers add/remove
- **gpc-onboarding** (0.11.0) -- Version alignment
- **README** -- Compatibility updated to GPC v0.9.51+

---

## v1.8.0 -- 2026-03-31

Synced with GPC v0.9.50. Security hardening, supply chain protection, developer verification, expanded docs.

### Updated Skills

- **gpc-security** -- Added 12-layer supply chain protection table (Socket.dev CI, SHA-pinned Actions, SBOM, pnpm audit gate, CODEOWNERS, min-release-age), developer verification section (`gpc verify`)
- **gpc-setup** -- Added `gpc auth setup-gcp --key` shortcut, expanded doctor checks (20 total with descriptions), added `gpc verify` and `gpc docs` (58 topics) sections
- **gpc-onboarding** -- Added `--key` shortcut for `setup-gcp`, added `gpc verify` and `gpc docs --list` to post-setup commands
- **gpc-release-flow** -- Added APK upload examples, `--status draft` on upload and promote, RTDN commands section (`gpc rtdn status/decode/test`)
- **gpc-preflight** -- Added APK support throughout (description, quick reference, procedures), developer verification reminder note
- **gpc-ci-integration** -- Added supply chain security section (version pinning, Socket.dev CI pattern), APK upload examples, draft release workflow

---

## v1.7.0 -- 2026-03-28

Synced with GPC v0.9.47. RTDN commands, APK upload, rate limiter rewrite, draft releases, batch endpoints.

### Updated Skills

- **gpc-release-flow** — Added APK upload procedure, `--status draft` workflow, fixed `--version` → `--tag` on changelog command
- **gpc-vitals-monitoring** — Added `--all` auto-pagination for reviews, 350-char reply validation, graceful 403 degradation note for disabled Reporting API
- **gpc-monetization** — Added RTDN section (`gpc rtdn status/decode/test`), voided purchases `--type` and `--include-partial-refunds` flags
- **gpc-sdk-usage** — Updated rate limiter docs with 6-bucket model (3,000 queries/min each), auto rate-limiting for all API calls
- **gpc-setup** — Added developer ID format validation to doctor checks, `qa` and `google_play_games_pc` form factor tracks
- **README** — Compatibility updated to GPC v0.9.47+

---

## v1.6.0 — 2026-03-26

Synced with GPC v0.9.46. Doctor enhancements, 7 new API endpoints, batch operations, error handling overhaul.

### Updated Skills

- **gpc-setup** — Expanded doctor checks list (6 → 16), added token verification on login, `auth logout --profile`, `--json` auth output
- **gpc-onboarding** — Updated doctor `--fix` capabilities (token cache fix), documented expanded check list
- **gpc-release-flow** — Added `releases.list` lifecycle visibility (DRAFT, IN_REVIEW, PUBLISHED states)
- **gpc-monetization** — Added `subscriptions batch-get/batch-update`, `iap batch-delete`, `purchases subscription acknowledge`
- **gpc-sdk-usage** — Added 7 new client methods: `releases.list`, `tracks.patch`, `subscriptions.batchGet/batchUpdate`, `purchases.acknowledgeSubscription`, `inappproducts.batchDelete`
- **gpc-troubleshooting** — Fixed `ApiError` → `PlayApiError` in exit codes reference
- **README** — Compatibility updated to GPC v0.9.46+

---

## v1.5.0 — 2026-03-26

Synced with GPC v0.9.45. Orders API, v2 purchases, subscription v2 cancel/defer.

### Updated Skills

- **gpc-monetization** — Added Orders API commands (`gpc orders get`, `gpc orders batch-get`), product purchases v2 (`gpc purchases product get-v2`), subscription v2 cancel/defer (`cancel-v2`, `defer-v2`), restructured purchase sections, deprecation guidance for subscription refunds via Orders API
- **gpc-sdk-usage** — Added `getProductV2`, `cancelSubscriptionV2`, `deferSubscriptionV2`, `orders.get`, `orders.batchGet` to API reference

---

## v1.4.1 — 2026-03-24

Synced with GPC v0.9.44.

- **gpc-preflight** — Added to repo (was missing). Added "Known limitations" section for manifest parsing fallback on large AABs.
- **gpc-release-flow** — Updated `gpc changelog` example version to v0.9.44.
- **README** — Compatibility updated to GPC v0.9.44+.

---

## v1.4.0 — 2026-03-24

Synced with GPC v0.9.43. Major update across all 16 skills — 13 issues fixed.

### Critical Fixes

- **gpc-sdk-usage** — Renamed `ApiError` → `PlayApiError` throughout (class renamed in GPC v0.9.37, old name causes import errors)
- **gpc-release-flow** — Fixed file size limits in upload-lifecycle reference (was 150 MB/100 MB, corrected to 2 GB AAB / 1 GB APK)
- **gpc-metadata-sync** — Fixed title character limit in failure modes (was 50, corrected to 30)

### Feature Updates

- **gpc-release-flow** — Added `--copy-notes-from`, `gpc releases count`, `gpc diff`, `gpc changelog`, 409 auto-retry, 5 new error codes, resumable upload details (X-GUploader-No-308)
- **gpc-troubleshooting** — Added 12 upload/API error codes, fixed GPC_MAX_RETRIES default (3 → 5), HTTP 408 retryable, GPC_UPLOAD_TIMEOUT env var
- **gpc-vitals-monitoring** — Added `gpc vitals lmk` command, Bug H accuracy note
- **gpc-ci-integration** — Added GPC_UPLOAD_TIMEOUT and GPC_UPLOAD_CHUNK_SIZE env vars
- **gpc-setup** — Added `gpc init`, GPC_UPLOAD_TIMEOUT, GPC_UPLOAD_CHUNK_SIZE, GPC_DEBUG env vars
- **gpc-onboarding** — Added `gpc init` as post-quickstart step
- **gpc-monetization** — Added `gpc purchase-options` and `gpc one-time-products` commands
- **gpc-multi-app** — Added `gpc status --all-apps`
- **gpc-security** — Updated example dates (2025 → 2026)
- **gpc-migrate-fastlane** — Fixed step numbering gap

### README

- Updated skill count from 13 to 16 (added gpc-onboarding, gpc-preflight, gpc-train)
- Added missing skills to Selection Guide and Reference Files Index
- Updated compatibility to GPC v0.9.43+

---

## v1.3.0 — 2026-03-19

Synced with GPC v0.9.38. Resumable uploads, retry improvements, vitals and monetization updates.

### Updated Skills

- **gpc-release-flow** — File size limits updated (AAB 2 GB, APK 1 GB), resumable upload protocol with chunked streaming and auto-resume, edit expiry warning at 5 minutes
- **gpc-setup** — Default `GPC_MAX_RETRIES` updated from 3 to 5
- **gpc-troubleshooting** — `GPC_MAX_RETRIES` default updated to 5, added HTTP 408 to retryable errors
- **gpc-ci-integration** — HTTP 408 now retried alongside 429 and 5xx
- **gpc-vitals-monitoring** — Reporting API rate limit (10 queries/sec, automatic), `gpc vitals startup` auto-includes `startType` dimension
- **gpc-monetization** — V1 subscription purchase API deprecation notice (Google shutdown Aug 2027), `gpc pricing convert` friendly error on apps without monetization
- **gpc-onboarding** — `gpc quickstart` spawn fix for Homebrew and binary installs

---

## v1.2.0 — 2026-03-19

Synced with GPC v0.9.37. Two new skills, five updated.

### New Skills

- **gpc-train** — Automated staged rollout pipeline (`gpc train start/status/pause/abort`), `.gpcrc.json` config, crash/ANR gate thresholds, state machine lifecycle
- **gpc-onboarding** — First-run guided setup (`gpc quickstart`, `gpc auth login` interactive wizard, `gpc auth setup-gcp`, `gpc doctor --fix`)

### Updated Skills

- **gpc-monetization** — Added subscription analytics (`gpc subscriptions analytics`) and base plan price migration (`gpc subscriptions base-plans migrate-prices`)
- **gpc-user-management** — Added standalone `gpc grants` CRUD section (list, create, patch, delete per-app permissions independently from user invitations)
- **gpc-troubleshooting** — +3 evals: vitals lmk 400 INVALID_ARGUMENT, quota `[object Object]` display bug (fixed in v0.9.36), stale edit auto-recovery
- **gpc-vitals-monitoring** — +3 evals: `compare-versions`, `watch --auto-halt-rollout`, `reviews analyze`
- **gpc-release-flow** — +2 evals: `gpc train` automation pipeline, EDIT_CONFLICT recovery

---

## v1.0.0 — 2026-03-12

Initial release: 13 GPC agent skills migrated from the [GPC monorepo](https://github.com/yasserstudio/gpc).

### Skills

- **gpc-setup** — Authentication, configuration, profiles, `gpc doctor`
- **gpc-release-flow** — Upload AAB, releases, promote, staged rollouts, `gpc publish`
- **gpc-metadata-sync** — Store listings, screenshots, images, Fastlane compat
- **gpc-vitals-monitoring** — Crash rates, ANR, reviews, reports, CI gating
- **gpc-ci-integration** — GitHub Actions, GitLab CI, Bitbucket, CircleCI
- **gpc-monetization** — Subscriptions, IAP, base plans, offers, pricing
- **gpc-user-management** — Users, permissions, grants, testers, CSV import
- **gpc-migrate-fastlane** — Fastlane-to-GPC migration, command mapping
- **gpc-plugin-development** — Plugin SDK, lifecycle hooks, custom commands
- **gpc-troubleshooting** — Exit codes, error catalog, debug mode
- **gpc-sdk-usage** — @gpc-cli/api and @gpc-cli/auth as standalone SDK
- **gpc-multi-app** — Multiple apps, profiles, batch operations
- **gpc-security** — Credential storage, key rotation, audit logging
