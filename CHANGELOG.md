# Changelog

## v1.31.0 -- 2026-08-30

Synced with GPC v0.9.96. One-time product writes reach Google again, chargebacks can be answered from the terminal, and Play App Signing with a self-hosted Cloud KMS key is now a documented path.

### Updated Skills

- **gpc-monetization** (0.16.0 -> 0.17.0) -- New section on the one-time product single-offer commands: Google publishes only batch endpoints for OTP offers, so `otp offers get/create/update/delete` are sent as single-item batch requests and now **require `--purchase-option`** (the `-` wildcard works only on `offers list`). `offers create` probes first and refuses an existing offer id with `API_ALREADY_EXISTS` rather than silently overwriting, since the underlying batch endpoint is an upsert. Notes that `one-time-products create` / `update` and those four commands failed with a route-not-found error before v0.9.96. New section 5F for `gpc purchases orders review-refund`: the 24-hour chargeback response window, the required `--pending-refund-token` / `--preference` / one of `--sample-content-provided` / `--no-sample-content-provided`, optional `--consumption-percent` and `--usage-events-file`, and the usage-event JSON shape (RFC 3339 timestamps, CLDR `location.regionCode`, max 1,000 events). RTDN section records that `gpc rtdn decode` now surfaces `pendingRefundReviewNotification` and prints the full token only with `--output json`. Three new failure-mode rows.
- **gpc-security** (0.15.0 -> 0.16.0) -- New section 12 on `gpc app-signing enroll` and `gpc app-signing rotate`. Leads with what these are not: standard Play App Signing with a Google-generated or Google-managed key cannot be set up through the API and stays in Play Console. Documents the security properties that matter: `--cert` / `--upload-cert` take PEM certificates only and a private key is refused as a usage error before anything is sent, Play needs Decrypt and Sign IAM grants on the key version first, `rotate` needs an `apksigner rotate` lineage file and applies only to self-hosted enrollments, `--reason` rejects the unspecified value locally, and **there is no confirmation prompt in CI** so a pipeline has to gate it itself. Verification section now points at the 11-item `gpc verify checklist`.
- **gpc-metadata-sync** (1.5.1 -> 1.6.0) -- `--ai-generated` on `listings images upload` and `listings images sync` records Google Play's AI-generated image attestation. Notes that on `sync` the flag applies to every image the run uploads, so an AI-generated set should be synced separately rather than attesting a mixed directory.
- **gpc-setup** (1.8.0 -> 1.9.0) -- `gpc verify checklist` now documented in full: 11 readiness items, every one of them promptable as of v0.9.96, including the new February 2027 memory and DEX optimization requirements and the April 2027 Zero-Tap Sign-In requirement (Android Restore Credentials API, games currently exempt). Manual items stay at `?` under `--no-interactive`, `--json`, or CI.
- **gpc-troubleshooting** (0.20.0 -> 0.21.0) -- Three new codes in both the SKILL table and `references/error-catalog.md`: `API_ALREADY_EXISTS` (409, use `update` instead of `create`), `API_ENDPOINT_RETIRED` (404, Google removed the endpoint, do it in Play Console), and `ORDER_REVIEW_REFUND_INVALID` (exit 2, validated locally so a bad command never burns part of the 24-hour chargeback window).
- **gpc-games** (1.0.0 -> 1.1.0) -- Documents directory `push`/`pull` and `set-icon`, with the caveat that icon upload rides the `imageConfigurations` resource Google removed from its published API (discovery revision 20260820). If the route is off, the command reports `API_ENDPOINT_RETIRED` with Google's own message as of v0.9.96 instead of a bare 404; set the icon in Play Console. Every other `games` command, `push` and `pull` included, is unaffected.
- **gpc-release-flow** (1.10.0 -> 1.11.0) -- The `--device-tier-config` row now says where the configuration comes from and covers `gpc device-tiers create --allow-unknown-devices`, for selectors naming devices Play has not catalogued yet.
- **gpc-sdk-usage** (1.9.0 -> 1.9.1) -- Endpoint count corrected to 230, and the API list now includes Games Configuration v1configuration alongside Android Publisher v3, Play Developer Reporting v1beta1, and Play Custom App Publishing v1.
- **README** -- 8 new routing rows (chargeback disputes, `--purchase-option`, app signing enroll/rotate, AI-generated attestation, unknown devices, retired icon endpoint), refreshed gpc-monetization / gpc-security / gpc-games descriptions, and a v0.9.96 requirements line.

### Bundle

19 skills. Synced to GPC v0.9.96.

---

## v1.30.2 -- 2026-08-14

Profiles can now be created from the command line (GPC v0.9.95), so the skills stop teaching the hand-edit-only workflow.

### Updated Skills

- **gpc-setup** (1.7.1 -> 1.8.0) -- Profile management now leads with `gpc auth login --service-account key.json --profile <name>` to create a profile, documents that re-login updates credentials in place while keeping the profile's other settings (safe key rotation), and that `auth logout --profile` clears only credentials. Notes the v0.9.95+ requirement: older versions silently ignored `--profile` on login and logout.
- **gpc-multi-app** (1.0.1 -> 1.1.0) -- The per-app profiles section creates each profile by command first, then adds the per-app `app` field in `config.json`, instead of presenting hand-editing as the only path.

### Bundle

19 skills. Synced to GPC v0.9.95.

---

## v1.30.1 -- 2026-08-14

Synced with GPC v0.9.95, which fixed subcommand flags being silently swallowed by same-named global flags and renamed the flags that never worked because of it.

### Updated Skills

- **gpc-vitals-monitoring** (1.9.0 -> 1.9.1) -- `gpc reviews export` examples now use `--output-file` (the renamed flag; the old `--output` spelling bound to the global format flag and never wrote a file).
- **gpc-setup** (1.7.0 -> 1.7.1) -- `gpc auth logout --profile` is described as clearing that profile's credentials while keeping its other settings, matching the v0.9.95 behavior.

### Bundle

19 skills. Synced to GPC v0.9.95.

---

## v1.30.0 -- 2026-08-13

Corrects guidance that went stale when GPC retired its AI-backed security scanner. The CI skill was telling users to add a `pnpm security:deep` step to their own pipelines; that script no longer exists.

### Updated Skills

- **gpc-ci-integration** (1.7.0 -> 1.8.0) -- Replaced the `pnpm security:deep` recipe with the free layers that actually cover a publishing pipeline: CodeQL (including GitHub Actions workflow files), `pnpm audit --prod --audit-level=high`, and secret scanning with push protection. Push protection is called out specifically because it blocks a leaked Play service account at `git push`, which matters more for a publishing pipeline than any post-hoc scan.

- **gpc-security** (0.14.1 -> 0.15.0) -- `references/runtime-security.md` no longer describes a `deepsec:` CI job running on every push. Documents what replaced it and the shift from continuous scanning of unchanged code to a deliberate pre-release review of the release diff. The v0.9.74 and v0.9.80 audit findings and their fixes are unchanged; those were real and remain documented.

### Why

The scanner billed per token per file. Across GPC's ~205 scannable source files a full pass cost tens of dollars, charged on every push including documentation-only commits. A control you cannot afford to keep running is not a control.

### Bundle

19 skills. Synced to GPC v0.9.94.

---

## v1.29.0 -- 2026-08-13

Synced with GPC v0.9.94. Two themes: upload failures caused by an incomplete Play Console "App content" declaration are no longer misreported as service account permission errors, and plugin trust is decided from the installed package rather than its name. The plugin change is breaking for third-party plugin authors.

### Updated Skills

- **gpc-plugin-development** (1.3.1 -> 1.4.0) -- Corrected the trust model, which the skill had been describing wrongly since v0.9.94 shipped: "First-party plugins (`@gpc-cli/*`) are auto-trusted" is no longer true. Only `@gpc-cli/plugin-ci` is allowlisted, and only when the resolved package's own `package.json` name matches the specifier; a mismatch is refused with `PLUGIN_IDENTITY_MISMATCH` before `import()` runs, so an npm alias or local replacement can no longer inherit unrestricted access. `@gpc-cli/plugin-sdk` removed from the first-party list (it is a library, not a plugin). Declaring `gpc.permissions` is now mandatory for third-party plugins (`PLUGIN_PERMISSIONS_REQUIRED`, exit 10); prior approvals are grandfathered once with a deprecation warning, and approvals stored as relative paths need approving again. Loose plugin files are now identified by path rather than by the enclosing project. `references/permissions-system.md` trust-model section and decision-flow diagram rewritten; `references/hooks-reference.md` gains a section documenting that `beforeRequest` / `afterResponse` / `onError` existed but were never wired until v0.9.94, plus credential redaction and the new `sensitive` flag on plugin command options and arguments.

- **gpc-troubleshooting** (0.19.0 -> 0.20.0) -- New `API_DECLARATION_REQUIRED` row in SKILL.md and the error catalog, plus a long-form catalog entry explaining the misdiagnosis: Google's 403 for the foreground service gate contains the word "permissions", GPC matched a bare substring, and the real explanation was discarded. The entry tells anyone on an older version to check App content before touching roles. Added `PLUGIN_PERMISSIONS_REQUIRED` and `PLUGIN_IDENTITY_MISMATCH` to the plugin error table, and new trigger keywords so the skill fires on "App content declaration" and "foreground service declaration".

- **gpc-preflight** (1.3.1 -> 1.4.0) -- New `policy-app-content-declaration` rule (info) in the rules table plus a section explaining why it can only advise: the declaration lives in Play Console and is not readable from the AAB or the Publisher API. Documents explicitly that this is **not** the same check as `foreground-service-type-missing` -- an app can have every service correctly typed and still be blocked by the missing Console declaration, which is the exact combination that motivated the rule.

- **gpc-release-flow** (1.9.0 -> 1.10.0) -- Two new failure-mode rows: `API_DECLARATION_REQUIRED`, and a row for anyone on a pre-v0.9.94 build seeing an unexplained permissions error on upload, pointing them at App content before they start changing roles.

- **README** -- Six new intent-routing rows for declaration failures, unexplained permission errors, pre-upload declaration checks, and third-party plugins that stopped loading after upgrading.

### Marquee changes in GPC v0.9.94

- `API_DECLARATION_REQUIRED` replaces the misleading permissions error and quotes Google's own message verbatim
- Insufficient OAuth scope failures are no longer reported as missing Play Console permissions
- `gpc preflight` advises on the App content declaration before an upload is spent
- Plugin trust read from the resolved manifest, verified before `import()`; `gpc.permissions` mandatory for third-party plugins (breaking)
- Plugin request, response, and command-error hooks now actually fire, with credentials redacted

### Bundle

19 skills. Synced to GPC v0.9.94.

---

## v1.28.0 -- 2026-08-01

Synced with GPC v0.9.93: `gpc reports` now downloads Play bulk reports for real, from the developer account's Cloud Storage bucket. Before v0.9.93 the reports commands only printed guidance about where the data lived, so every skill that mentioned them described a facade.

### Updated Skills

- **gpc-vitals-monitoring** (1.8.0 -> 1.9.0) -- Rewrote the Reports section around the live GCS path: the required one-time "View app information and download bulk reports (read-only)" account grant (Play never gives it to a service account automatically), bucket resolution (`pubsite_prod_<developerId>`, overridable with `--bucket` / `GPC_REPORTS_BUCKET` / `reports.bucket`), corrected `reports list <report-type>` usage (it takes a single type, not `stats`/`financial`), the `--dimension` flag and its eight values, `subscriptions` and `sales` report types, the list `--json` envelope, UTF-16 to UTF-8 decoding, ZIP unwrapping rules for financial reports, and the three download JSON envelopes. Six new failure-mode rows for the `REPORT_*` codes plus two verification steps.

- **gpc-troubleshooting** (0.18.0 -> 0.19.0) -- New "Bulk report errors" section in SKILL.md and the error catalog covering all 14 new codes with exit codes (`REPORT_ACCESS_DENIED` 4, `REPORT_AUTH_REJECTED` 3, `REPORT_BUCKET_UNKNOWN`/`REPORT_BUCKET_INVALID`/`REPORT_MULTIPLE_ENTRIES`/`INVALID_REPORT_DIMENSION`/`MISSING_REQUIRED_OPTION`/`INVALID_LIMIT` 2, the rest 4), a long-form `REPORT_ACCESS_DENIED` entry, the `gpc doctor` reports-bucket probe, `gpc auth clear-cache` as the fix for a stale token after a new grant, and `GPC_REPORTS_BUCKET` in the env var table.

- **gpc-setup** (1.6.0 -> 1.7.0) -- Documents the extra bulk-reports account permission (set under Users and permissions, not Settings -> API access), the `devstorage.read_only` least-privilege note (only the reports path requests it; storage-scoped tokens cache separately), `gpc auth clear-cache` alongside `gpc auth logout`, the new `reports-bucket` doctor check (22 -> 23), and `developerId` / `reports.bucket` / `GPC_REPORTS_BUCKET` in the configuration reference.

- **gpc-sdk-usage** (1.8.0 -> 1.9.0) -- **Breaking:** `client.reports.list` removed from `@gpc-cli/api` (it never worked) and `downloadReport` removed from `@gpc-cli/core`. New worked example for `listReports` / `downloadStatsReport` / `downloadFinancialReport` / `resolveReportsBucket`, the `ReportsAuth` shape, and requesting `STORAGE_READ_ONLY_SCOPE` explicitly in `resolveAuth`. Three new failure-mode rows.

- **README** -- Five new intent-routing rows for bulk report downloads, bucket questions, `REPORT_ACCESS_DENIED`, and granting reports access.

### Marquee changes in GPC v0.9.93

- `gpc reports list`, `gpc reports download stats`, and `gpc reports download financial` read live from the Play-linked GCS bucket (were dead stubs)
- Requires a one-time "download bulk reports (read-only)" grant on the service account; `REPORT_ACCESS_DENIED` until then
- New `gpc auth clear-cache`, new `gpc doctor` reports-bucket check, `devstorage.read_only` requested only by the reports path

### Bundle

19 skills. Synced to GPC v0.9.93.

---

## v1.27.1 -- 2026-07-24

Flag-accuracy fix for gpc-metadata-sync, from a command-reference audit against GPC v0.9.92 source.

### Updated Skills

- **gpc-metadata-sync** (1.5.0 -> 1.5.1) -- Corrected `gpc listings` flags that did not exist in the CLI: `gpc listings get --all-languages` -> `gpc listings get` (omit `--lang` for all languages), `gpc listings update --short-desc/--full-desc` -> `--short`/`--full`, and the nonexistent `gpc listings update --file <dir>` -> `--full-file <path>` (with a pointer to `gpc listings push --dir` for whole-directory updates). Pre-existing errors, not introduced by v1.27.0.

---

## v1.27.0 -- 2026-07-24

Save-quota guidance for image sync, plus the v0.9.92 screenshot display-order and absent-directory safety behavior. Prompted by a maintainer report (GH #95) where per-image `upload`/`delete` loops exhausted the daily Play publish (save) quota.

### Updated Skills

- **gpc-metadata-sync** (1.4.0 -> 1.5.0) -- New save-quota rule: prefer `gpc listings images sync --dir ... --delete` (one committed edit = one save for the whole run, zero on a no-op) over looping per-image `upload`/`delete` (one save per call, hundreds per multi-locale run). Documents the v0.9.92 display-order guarantee (`--delete` re-uploads in sorted filename order when a locale/type differs in content or order) and absent-directory safety (an absent type dir is left untouched; a present-but-empty dir clears that type). Two new failure-mode rows (quota exceeded, screenshots out of order) and quota trigger terms in the description.

### Bundle

19 skills. Synced to GPC v0.9.92.

---

## v1.26.0 -- 2026-06-26

New **gpc-games** skill plus a sync covering GPC v0.9.83 through v0.9.87 (v1.25.0 covered through v0.9.82).

### New Skill

- **gpc-games** (1.0.0) -- Google Play Games Services achievement and leaderboard configuration CRUD (`gpc games achievements/leaderboards` list/get/create/update/delete/diff), the `gpc games runtime` read-only commands, and `--game-id` / `GPC_GAME_ID` / `games.applicationId` resolution. New in GPC v0.9.86.

### Updated Skills

- **gpc-user-management** (0.11.0 -> 0.12.0) -- `grants list` and `testers list` now return the unified `--json` envelope (GPC v0.9.87, breaking for scripts reading a bare array). `testers list` emits `googleGroups: []` when a track has no groups. `users list` shares the same envelope (v0.9.83).
- **gpc-release-flow** (1.8.0 -> 1.9.0) -- `tracks list` now returns the unified `--json` envelope (GPC v0.9.87).
- **gpc-sdk-usage** (1.7.1 -> 1.8.0) -- pagination resume fix and unified list envelope (GPC v0.9.83/v0.9.87).
- **gpc-monetization** (0.15.0 -> 0.16.0) -- `--regions-version` now sent on subscription/OTP writes (GPC v0.9.84); IAP/subscription list use the unified envelope (GPC v0.9.83).
- **gpc-vitals-monitoring** (1.7.0 -> 1.8.0) -- `reviews list` gains hasReply/lang/[truncated]/`--full-text` and the unified envelope (GPC v0.9.83).
- **gpc-troubleshooting** (0.17.1 -> 0.18.0) -- npm global install failure resolved (GPC v0.9.84/v0.9.85).

### Bundle

19 skills (was 18). Synced to GPC v0.9.87.

---

## v1.25.0 -- 2026-06-07

Synced with GPC v0.9.78-v0.9.82. Covers GitHub Action launch, config precedence fix, vitals gate fix, and 4 new release versions since v1.24.0.

### Updated Skills

- **gpc-ci-integration** (1.6.0 -> 1.7.0) -- GPC GitHub Action (`yasserstudio/gpc-action`) as the quickest CI path, with Marketplace link, usage example, and r0adkll migration guide. Node.js 24 support. Config resolution precedence table. Pinned install version bumped to 0.9.82.

- **gpc-release-flow** (1.7.0 -> 1.8.0) -- `gpc releases assign` command (v0.9.78). Custom closed testing track creation via `edits.tracks.create` (v0.9.79). `reviewPending`/`nextStep` structured output on commit rejection (v0.9.79). `reviewSkipped` on internal track. Dry-run `executed[]`/`skipped[]` arrays. AI SDK v6 migration note. Known bugs section updated to "fixed in v0.9.78".

- **gpc-setup** (1.5.0 -> 1.6.0) -- Config resolution precedence table (CLI flags > env vars > profile > .gpcrc.json > defaults). Documents the v0.9.81 precedence fix.

- **gpc-troubleshooting** (0.17.0 -> 0.17.1) -- New error catalog entries: `API_EDIT_EXPIRED`, `API_ROLLOUT_DECREASE_FORBIDDEN`, `REVIEW_SKIPPED`. Commit rejection `reviewPending` structured output. Config precedence fix note.

- **gpc-preflight** (1.3.0 -> 1.3.1) -- Compat bumped to v0.9.82+. Manifest scanner row updated with testOnly + targetSdk detail.

- **gpc-vitals-monitoring** (1.6.0 -> 1.7.0) -- Vitals gate crash-rate extraction fix (v0.9.82): now reads correct `MetricSetResponse` shape. `VitalsThresholds` type in `GpcConfig`/`ResolvedConfig` with `.gpcrc.json` example.

- **gpc-security** (0.14.0 -> 0.14.1) -- Compat bumped to v0.9.82+. Production audit finding cleared (google-auth-library 10.7.0). GitHub Action security notes.

- **gpc-monetization** (0.13.0 -> 0.15.0) -- `OfferPhaseDetails` type on Orders deprecating `offerPhase` (v0.9.79). OTP purchase option offers: 7 batch commands (v0.9.79).

- **gpc-sdk-usage** (1.7.0 -> 1.7.1) -- `edits.tracks.create` example (v0.9.79). `VitalsThresholds` config type (v0.9.82). `OfferPhaseDetails` access pattern. Compat bumped to v0.9.82+.

- **gpc-plugin-development** (1.3.0 -> 1.3.1) -- Compat alignment with v0.9.82.

- **gpc-train** (0.10.0 -> 0.10.1) -- Version alignment.

### Marquee changes in GPC v0.9.78-v0.9.82

- v0.9.82: Dependency health, AI SDK v6, vitals gate fix, zero production audit findings
- v0.9.81: GPC GitHub Action on Marketplace, config precedence fix
- v0.9.79: Developer clarity, preflight targetSdk 36, Node 24 CI
- v0.9.78: Track fixes, `gpc releases assign`, validateAndCommit auto-rescue
- 2,345 tests

---

## v1.24.0 -- 2026-05-30

Synced with GPC v0.9.80 (security audit, API alignment, code quality).

### Updated Skills

- **gpc-security** (0.13.0 -> 0.14.0) -- Webhook payload redaction, auth error credential masking, ADC hash-based cache keys, project config plugin trust gate. Compat bumped to v0.9.80+.

- **gpc-preflight** (1.2.0 -> 1.3.0) -- testOnly read from `<application>` element (was `<manifest>` root). 16KB alignment scanner now checks APK native libs. ELF header read increased to 4096 bytes. `skippedScanners` in result JSON. targetSdkMinimum default 36.

- **gpc-plugin-development** (1.2.0 -> 1.3.0) -- Permission enforcement at hook registration time. `register()` crash guard. Project `.gpcrc.json` can no longer self-approve plugins.

- **gpc-troubleshooting** (0.16.0 -> 0.17.0) -- New error codes: CONFIG_INVALID_JSON, CONFIG_INVALID_KEY, CHANGELOG_FETCH_FAILED, CHANGELOG_VERSION_NOT_FOUND, WATCH_WEBHOOK_FAILED.

- **gpc-sdk-usage** (1.6.0 -> 1.7.0) -- API type alignment: canceledStateContext nested shape, signupPromotion {oneTimeCode, vanityCode}, developerAccountPermissions plural, buyOption/rentOption fields. download() retry with backoff. Null-safe bundles.list/tracks.list.

### Marquee changes in GPC v0.9.80

- 15 security fixes (plugin trust gate, CI hardening, webhook redaction, preflight false negatives)
- 13 API alignment fixes (discovery doc rev 20260520)
- 20 code quality fixes (null safety, download retry, permission enforcement)
- 2,343 tests, deepsec re-scan: 0 new findings

---

## v1.23.0 -- 2026-05-22

Synced with GPC v0.9.77 (upload timeout fix, supply chain hardening).

### Updated Skills

- **gpc-release-flow** (1.6.0 -> 1.7.0) -- npm publishing via Trusted Publisher (OIDC) + Staged Publishing. Multi-retry guard on validate/commit (v0.9.77). Known bugs table for v0.9.78 (tracks update wipes, changesNotSentForReview gap, version reassignment).

- **gpc-security** (v0.9+ -> v0.9.77+) -- Supply chain hardening: Trusted Publisher OIDC, Staged Publishing with 2FA, NPM_TOKEN deleted. Defense layers expanded from 12 to 15.

- **gpc-sdk-usage** (1.6.0 -> 1.6.1) -- Fibonacci backoff extended in v0.9.77, multi-retry guard on validate/commit.

- **gpc-troubleshooting** -- Added EDIT_VALIDATE_FAILED row with v0.9.77 multi-retry guard.

- **gpc-monetization** -- Minor version alignment.

- **gpc-setup** -- Minor version alignment.

### Marquee changes in GPC v0.9.77

- Fix large AAB upload timeout: Fibonacci backoff polling (~86s), multi-retry guard on validate/commit (15s, 30s, 45s)
- Supply chain hardening: Trusted Publisher (OIDC), Staged Publishing (human 2FA), NPM_TOKEN deleted
- 2,319 tests

---

## v1.22.0 -- 2026-05-20

Synced with GPC v0.9.76 (Google I/O 2026 response).

### Updated Skills

- **gpc-setup** (1.7.0 -> 1.8.0) -- Embedded docs count 99 -> 108 (blog, new guide pages).

- **gpc-onboarding** (0.13.0 -> 0.14.0) -- Embedded docs count 99 -> 108.

- **gpc-monetization** (0.13.0 -> 0.14.0) -- SubscriptionPurchaseV2 new fields (onHoldStateContext, inGracePeriodStateContext). Data safety API section (get/update from CSV).

- **gpc-sdk-usage** (1.5.0 -> 1.6.0) -- Compatibility line updated for v0.9.76 typed fields and data safety API.

### Marquee changes in GPC v0.9.76

- Full API contract audit (50+ fixes against official reference docs)
- SubscriptionPurchaseV2 new fields: onHoldStateContext, inGracePeriodStateContext
- Data safety API (CSV format, input validation)
- Blog launch, docs restructure (108 pages, nav streamlined from 8 to 5 items)

---

## v1.21.0 -- 2026-05-15

Synced with GPC v0.9.74 (security hardening release).

### Updated Skills

- **gpc-security** (0.13.0 -> 0.14.0) -- Major update: full deepsec audit catalog (16 findings), new runtime-security.md reference covering all fixes, p() helper convention, redactPath() pattern, env allowlist pattern, deepsec audit process, supply chain hardening.

- **gpc-ci-integration** (1.5.0 -> 1.6.0) -- Step-scoped secrets in all workflow templates, --ignore-scripts enforcement, lockfile integrity verification, deepsec CI job, workflow_dispatch triggers.

- **gpc-sdk-usage** (1.4.0 -> 1.5.0) -- API path encoding via p() helper, per-bucket promise-chain mutex in rate limiter, validateSessionUri() SSRF protection, redactPath() in all error paths.

- **gpc-release-flow** (1.6.0 -> 1.7.0) -- Vitals gate checks before rollout increase, prompt injection hardening in AI changelog, step-scoped secrets in CI templates.

- **gpc-metadata-sync** (1.3.0 -> 1.4.0) -- Image upload/delete now respect --dry-run, symlink traversal protection in --notes-dir, CSV formula injection prevention.

- **gpc-plugin-development** (1.1.0 -> 1.2.0) -- Plugin trust model: isPluginTrusted() gates import(), unapproved plugins silently skipped.

- **gpc-setup** (1.6.0 -> 1.7.0) -- Config set no longer echoes values, doctor strips proxy credentials, skills installer env allowlist.

- **gpc-troubleshooting** (0.17.0 -> 0.18.0) -- Three new SSRF error codes, vitals gate behavior change, plugin silent-skip, redacted error message guidance.

- **gpc-vitals-monitoring** (1.5.0 -> 1.6.0) -- Vitals gate checks thresholds before rollout increase (was after), staged pipeline patterns.

- **gpc-monetization** (0.12.0 -> 0.13.0) -- Purchase token redaction in RTDN output and API error messages, URL encoding on all purchase paths.

### Marquee changes in GPC v0.9.74

- **16 security fixes** from deepsec AI audit: plugin RCE, SSRF, symlink traversal, credential redaction, API path encoding, CSV injection, prompt injection, rate limiter race, vitals gate ordering, and more.
- **CI supply chain hardening**: deepsec scanning, restricted install scripts, lockfile verification, step-scoped secrets.
- **deepsec before every release**: `pnpm security:deep` is now step 0 in the release checklist.

## v1.20.0 -- 2026-04-30

Synced with GPC v0.9.71.

### Updated Skills

- **gpc-setup** (1.5.0 -> 1.6.0) -- Doctor checks list updated from 20 to 22: added API quota proximity (warns at >80% daily/per-minute usage) and plugin health (discovers, loads, reports each configured plugin).

- **gpc-troubleshooting** (0.16.0 -> 0.17.0) -- Added doctor failure modes for quota warnings and plugin load failures.

- **gpc-plugin-development** (1.0.0 -> 1.1.0) -- Added `gpc doctor` plugin health check as a debugging tool for broken plugin installs.

### Marquee features in GPC v0.9.71

- **`gpc doctor` quota proximity**: warns when daily or per-minute Google Play API usage exceeds 80%, so you catch rate limits before they hit.
- **`gpc doctor` plugin health**: discovers, loads, and reports each configured plugin. Surfaces broken installs before they cause runtime failures.

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
