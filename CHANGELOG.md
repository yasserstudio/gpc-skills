# Changelog

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
