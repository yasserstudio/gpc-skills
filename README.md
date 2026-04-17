# GPC Agent Skills

Agent skills for the [GPC CLI](https://github.com/yasserstudio/gpc) — the complete Google Play Console CLI.

These skills teach Claude Code how to use GPC for common Google Play workflows: releases, metadata, vitals, CI/CD, and setup.

## Install

```bash
npx skills add yasserstudio/gpc-skills
```

## Available Skills (18)

| Skill | Description |
|-------|-------------|
| **gpc-setup** | Authentication (service account, OAuth, ADC), configuration, profiles, `gpc doctor` |
| **gpc-onboarding** | First-run guided setup, `gpc quickstart`, `gpc init`, `gpc auth` wizard |
| **gpc-release-flow** | Upload AAB/APK, create releases, draft releases, promote tracks, staged rollouts, `gpc publish`, `gpc diff` |
| **gpc-metadata-sync** | Store listings, screenshots, images, Fastlane metadata compatibility, pull/push |
| **gpc-vitals-monitoring** | Crash rates, ANR, startup, LMK, vitals thresholds, reviews (auto-paginate), reports |
| **gpc-ci-integration** | GitHub Actions, GitLab CI, Bitbucket, CircleCI, JSON output, exit codes |
| **gpc-monetization** | Subscriptions, IAP, one-time products, RTDN notifications, voided purchases, pricing, regional conversion |
| **gpc-user-management** | Developer account users, permissions, grants, testers, CSV import |
| **gpc-migrate-fastlane** | Fastlane-to-GPC migration, command mapping, CI migration |
| **gpc-plugin-development** | Plugin SDK, lifecycle hooks, permissions, custom commands |
| **gpc-troubleshooting** | Exit codes, error catalog (40+ codes), debug mode, common fixes |
| **gpc-sdk-usage** | @gpc-cli/api and @gpc-cli/auth as standalone TypeScript SDK, 6-bucket rate limiter |
| **gpc-multi-app** | Multiple apps, profiles, batch operations, monorepo patterns |
| **gpc-security** | Credential storage, key rotation, audit logging, supply chain protection (12 layers), incident response |
| **gpc-preflight** | Offline AAB/APK compliance scanner (9 scanners), `.preflightrc.json` config |
| **gpc-train** | Automated staged rollout pipeline with crash/ANR gates and time gates |
| **gpc-enterprise** | **New in v0.9.56.** Publish private apps to Managed Google Play via the Play Custom App Publishing API. First Android publishing CLI with this support. |
| **gpc-android-cli-interop** | **New in v1.12.0.** Handoff router between [Google's official Android CLI](https://android-developers.googleblog.com/2026/04/build-android-apps-3x-faster-using-any-agent.html) (build/dev) and GPC (publishing). Triggers after `android run` / `android build` to route into the right GPC skill. |

## Skill Structure

Each skill follows the same layout:

```
gpc-<skill>/
├── SKILL.md              # Main procedural guide (entry point)
├── evals/
│   └── evals.json        # Eval scenarios for testing
├── scripts/
│   └── detect_gpc.mjs    # Environment detection script
└── references/           # Deep-dive topic docs linked from SKILL.md
    ├── topic-a.md
    └── topic-b.md
```

- **SKILL.md** — procedural checklist: when to use, inputs, step-by-step procedure, verification, failure modes
- **references/** — detailed guides on specific topics, linked from SKILL.md via `Read:` directives

## Skill Selection Guide

| Task | Skill |
|------|-------|
| "Set up GPC for the first time" | `gpc-setup` |
| "Upload an AAB to the Play Store" | `gpc-release-flow` |
| "Upload an APK to the Play Store" | `gpc-release-flow` |
| "Create a draft release for review" | `gpc-release-flow` |
| "Promote beta to production" | `gpc-release-flow` |
| "Sync store listings from local files" | `gpc-metadata-sync` |
| "Check crash rate before promoting" | `gpc-vitals-monitoring` |
| "Reply to negative reviews" | `gpc-vitals-monitoring` |
| "Fetch all reviews with auto-pagination" | `gpc-vitals-monitoring` |
| "Set up GPC in GitHub Actions" | `gpc-ci-integration` |
| "Automate staged rollout in CI" | `gpc-ci-integration` + `gpc-release-flow` |
| "Create a subscription with a free trial" | `gpc-monetization` |
| "Sync IAP products from JSON files" | `gpc-monetization` |
| "Verify a purchase token" | `gpc-monetization` |
| "Decode a Pub/Sub notification from Play" | `gpc-monetization` |
| "Set up RTDN for subscriptions" | `gpc-monetization` |
| "List voided purchases including subscriptions" | `gpc-monetization` |
| "Invite a team member to Play Console" | `gpc-user-management` |
| "Import beta testers from CSV" | `gpc-user-management` |
| "Migrate from Fastlane supply" | `gpc-migrate-fastlane` |
| "Replace Fastlane in CI" | `gpc-migrate-fastlane` |
| "Build a GPC plugin" | `gpc-plugin-development` |
| "GPC command failing with exit code 4" | `gpc-troubleshooting` |
| "Use @gpc-cli/api to verify purchases" | `gpc-sdk-usage` |
| "Deploy to 3 apps at once" | `gpc-multi-app` |
| "Set up profiles for different clients" | `gpc-multi-app` |
| "Where does GPC store credentials?" | `gpc-security` |
| "Rotate our service account key" | `gpc-security` |
| "Scan AAB for policy violations before upload" | `gpc-preflight` |
| "Configure preflight thresholds" | `gpc-preflight` |
| "Automate staged rollout with crash gates" | `gpc-train` |
| "First time setting up GPC" | `gpc-onboarding` |
| "Show what changed in the latest release" | `gpc-release-flow` |
| "Configure rate limiting for API calls" | `gpc-sdk-usage` |
| "Check Android developer verification status" | `gpc-setup` |
| "Harden supply chain security" | `gpc-security` |
| "Open docs from the terminal" | `gpc-setup` |
| "Scan APK for policy violations" | `gpc-preflight` |
| "Publish a private app to Managed Google Play" | `gpc-enterprise` |
| "Create a custom app for enterprise customers" | `gpc-enterprise` |
| "Upload an internal-only Android app for a specific organization" | `gpc-enterprise` |
| "What's the Play Custom App Publishing API?" | `gpc-enterprise` |
| "Why does `gpc enterprise publish` ask for confirmation?" | `gpc-enterprise` |
| "Why can't I make my private app public?" | `gpc-enterprise` |
| "I just finished `android run`, what's next?" | `gpc-android-cli-interop` |
| "My AAB is built, ship it to Play Store" | `gpc-android-cli-interop` |
| "Scaffold a Compose app and ship it to internal" | `gpc-android-cli-interop` (then hands off to `gpc-release-flow`) |
| "How do Google's Android CLI and GPC work together?" | `gpc-android-cli-interop` |

## Reference Files Index

### gpc-setup
| File | Topic |
|------|-------|
| `references/service-account.md` | Creating and configuring service accounts |
| `references/configuration.md` | Config files, env vars, precedence |
| `references/troubleshooting.md` | Auth and setup debugging |
| `references/oauth-flow.md` | OAuth device flow deep dive |

### gpc-release-flow
| File | Topic |
|------|-------|
| `references/upload-lifecycle.md` | Google Play edit lifecycle (insert → commit) |
| `references/rollout-strategies.md` | Staged rollout patterns and state machine |
| `references/troubleshooting.md` | Upload, promotion, and rollout errors |
| `references/release-notes.md` | Multi-language release notes workflow |

### gpc-metadata-sync
| File | Topic |
|------|-------|
| `references/directory-structure.md` | Metadata file layout and character limits |
| `references/fastlane-migration.md` | Migrating from Fastlane supply |
| `references/image-requirements.md` | Google Play image specs per type |

### gpc-vitals-monitoring
| File | Topic |
|------|-------|
| `references/ci-gating.md` | Threshold-based deployment gating |
| `references/review-management.md` | Listing, filtering, and replying to reviews |

### gpc-ci-integration
| File | Topic |
|------|-------|
| `references/github-actions.md` | GitHub Actions workflow templates |
| `references/troubleshooting.md` | CI-specific debugging guide |
| `references/gitlab-ci.md` | GitLab CI pipeline templates |
| `references/bitbucket-pipelines.md` | Bitbucket Pipelines templates |

### gpc-monetization
| File | Topic |
|------|-------|
| `references/subscription-schema.md` | Subscription JSON structure and field reference |
| `references/iap-schema.md` | In-app product JSON structure and sync behavior |
| `references/purchase-verification.md` | Server-side purchase verification patterns |

### gpc-user-management
| File | Topic |
|------|-------|
| `references/permissions.md` | Permission constants and role patterns |
| `references/tester-workflows.md` | Tester management, CSV import, onboarding |

### gpc-migrate-fastlane
| File | Topic |
|------|-------|
| `references/command-mapping.md` | Complete Fastlane → GPC command mapping |
| `references/ci-migration.md` | CI platform migration examples |

### gpc-plugin-development
| File | Topic |
|------|-------|
| `references/hooks-reference.md` | All 6 lifecycle hooks with type signatures |
| `references/permissions-system.md` | Permission constants and trust model |

### gpc-troubleshooting
| File | Topic |
|------|-------|
| `references/exit-codes.md` | Exit code reference and CI usage |
| `references/error-catalog.md` | All error codes with causes and fixes |

### gpc-sdk-usage
| File | Topic |
|------|-------|
| `references/auth-patterns.md` | Auth resolution, token caching, multiple clients |
| `references/api-reference.md` | Complete PlayApiClient API reference |

### gpc-multi-app
| File | Topic |
|------|-------|
| `references/profile-patterns.md` | Profile configurations for multi-app setups |
| `references/ci-multi-app.md` | CI/CD patterns for deploying multiple apps |

### gpc-security
| File | Topic |
|------|-------|
| `references/credential-storage.md` | Storage architecture and security model |
| `references/key-rotation.md` | Key rotation procedures and automation |

### gpc-preflight
| File | Topic |
|------|-------|
| (inline) | Preflight scanners, `.preflightrc.json` configuration, CI gating |

### gpc-train
| File | Topic |
|------|-------|
| `references/rollout-pipeline.md` | Staged rollout pipeline with crash/ANR gates |

### gpc-onboarding
| File | Topic |
|------|-------|
| (inline) | First-run setup, `gpc quickstart`, `gpc init`, `gpc doctor --fix` |

## Compatibility

- GPC v0.9.52+ (`npm install -g @gpc-cli/cli`) for most skills
- GPC v0.9.56+ required for `gpc-enterprise` (Play Custom App Publishing API support)
- GPC v0.9.58+ recommended for full shell-completion coverage (walker-based, auto-discovers plugin commands)
- GPC v0.9.61+ required for `gpc changelog generate` (referenced by `gpc-release-flow`, `gpc-ci-integration`, `gpc-sdk-usage`)
- GPC v0.9.62+ required for multilingual Play Store release notes (`--target play-store --locales <csv|auto>`; referenced by `gpc-release-flow`, `gpc-metadata-sync`, `gpc-migrate-fastlane`, `gpc-sdk-usage`, `gpc-ci-integration`)
- `gpc-android-cli-interop` (v1.12.0+) pairs with Google's [official Android CLI](https://android-developers.googleblog.com/2026/04/build-android-apps-3x-faster-using-any-agent.html) (released 2026-04-16). Install Google's CLI separately; the interop skill assumes both tools are installed and declares the handoff between them.
- Node.js 20+ (or standalone binary)
- Google Play Developer API access (service account)
- For `gpc-enterprise`: an additional "create and publish private apps" permission granted to the service account in Play Console

## Related

- [GPC Documentation](https://yasserstudio.github.io/gpc/)
- [GPC Commands Reference](https://yasserstudio.github.io/gpc/commands/)
- [GPC CI/CD Recipes](https://yasserstudio.github.io/gpc/ci-cd/)
- [GPC Enterprise Publishing Guide](https://yasserstudio.github.io/gpc/guide/enterprise-publishing) (v0.9.56+)
- [GPC Multilingual Release Notes Guide](https://yasserstudio.github.io/gpc/guide/multilingual-release-notes) (v0.9.62+)
- [Android CLI Interop Guide](https://yasserstudio.github.io/gpc/guide/android-cli-interop) (v1.12.0+; paired with Google's Android CLI)

## Licensing

Free to use. Source code is on GitHub at [yasserstudio/gpc-skills](https://github.com/yasserstudio/gpc-skills).
