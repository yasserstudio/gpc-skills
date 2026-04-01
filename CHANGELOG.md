# Changelog

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
