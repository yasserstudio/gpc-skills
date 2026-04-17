---
name: gpc-android-cli-interop
description: "Use when the agent has just finished building an Android app with Google's official `android` CLI (android create, android run, android sdk install, android build), or when the user says their app is built and they need to ship to Play Store, their AAB is ready, they just finished scaffolding, the APK is generated, or they want the next step after `android run`. Trigger whenever a prompt bridges the build-and-device half (Google's Android CLI) to the publishing half (GPC) -- even without explicit product names. For the release mechanics themselves, see gpc-release-flow. For offline compliance checks, see gpc-preflight. For CI/CD, see gpc-ci-integration. For private enterprise apps, see gpc-enterprise."
compatibility: "Google's Android CLI (released 2026-04-16) for build/dev, GPC v0.9.62+ for publishing. Both tools ship SKILL.md skill packs and are installed via npx skills add."
metadata:
  version: 1.0.0
---

# GPC Android CLI Interop

## What this skill is

A router. Google's official [Android CLI](https://android-developers.googleblog.com/2026/04/build-android-apps-3x-faster-using-any-agent.html) covers the build-and-device half of Android app development (scaffold, SDK, emulator, run). GPC covers the Play Store half (preflight, upload, release, vitals, metadata, subscriptions). This skill handles the transition between the two — the moment an AAB or APK is on disk and needs to be shipped.

## When to use

Trigger this skill when:

- An agent has just run `android run`, `android build`, or equivalent and has an AAB/APK on disk
- The user is coming from a "build worked, now ship it" posture
- A prompt spans both toolchains ("scaffold a Compose app and ship it to internal")
- The user asks "what's the next step" after a successful Google CLI operation

## When NOT to use

This skill is a dispatcher, not an implementation. For actual Play Store operations, delegate to the right GPC skill:

| Task                                    | Skill                     |
| --------------------------------------- | ------------------------- |
| Upload, release, promote, rollout       | `gpc-release-flow`        |
| Offline AAB policy scanning             | `gpc-preflight`           |
| Crash rate, ANR, startup, reviews       | `gpc-vitals-monitoring`   |
| Store listings, screenshots, metadata   | `gpc-metadata-sync`       |
| Subscriptions, IAP, pricing, RTDN       | `gpc-monetization`        |
| Service account, OAuth, ADC, profiles   | `gpc-setup`               |
| GitHub Actions, GitLab CI, JSON output  | `gpc-ci-integration`      |
| Managed Google Play private apps        | `gpc-enterprise`          |
| Fastlane-to-GPC migration               | `gpc-migrate-fastlane`    |
| Multiple apps / profiles                | `gpc-multi-app`           |
| GPC-specific errors and exit codes      | `gpc-troubleshooting`     |

## Handoff procedure

### 1) Confirm you're at the handoff point

You have an AAB or APK at a known path. Typical locations after `android run --release` or Gradle:

```
app/build/outputs/bundle/release/app-release.aab
app/build/outputs/apk/release/app-release.apk
```

If no bundle exists, the build hasn't completed — loop back to Google's Android CLI skills, not this one.

### 2) Confirm GPC is configured

Run once per environment:

```bash
gpc doctor
```

Exit code 0 means auth, config, and API reach are all healthy. Non-zero means the user must authenticate first — delegate to `gpc-setup`.

### 3) Offline compliance scan

Before any network call:

```bash
gpc preflight app-release.aab --fail-on error
```

9 offline policy scanners (target SDK, permissions, 64-bit libs, secrets, etc.). Catches Play Store rejections before upload. For deeper config, delegate to `gpc-preflight`.

### 4) Ship

Hand off to `gpc-release-flow` for upload, rollout, and promote. Typical one-command release:

```bash
gpc publish \
  --package com.example.app \
  --file app-release.aab \
  --track internal \
  --rollout 1.0
```

`gpc publish` handles the full edit lifecycle (open → upload → release → commit). For staged production rollouts, promote, or halt, see `gpc-release-flow`.

### 5) Verify post-release

After the release is live, check vitals:

```bash
gpc vitals crashes --package com.example.app --days 1 --json
gpc vitals anr --package com.example.app --days 1 --json
```

For thresholds, alerting, and review monitoring, delegate to `gpc-vitals-monitoring`.

## End-to-end example

A user says: *"Scaffold a Compose app called Notes, ship a 10% production rollout, and check crash rate after one day."*

The full agent path:

```bash
# Google's Android CLI (not this skill)
android create --template compose-tutorial --name Notes
android sdk install --platform 34
android run --release

# Handoff (this skill)
gpc doctor
gpc preflight app-release.aab --fail-on error

# GPC release flow (delegate to gpc-release-flow)
gpc publish --package com.example.notes --file app-release.aab --track production --rollout 0.1

# GPC vitals (delegate to gpc-vitals-monitoring, typically after waiting a day)
gpc vitals crashes --package com.example.notes --days 1 --json
```

## Output contract for agents

GPC commands that this skill delegates to all share the same machine-readable contract:

- `--json` on every command (TTY-aware — structured output when piped)
- Semantic exit codes: 0 success, 1 error, 2 usage, 3 auth, 4 API, 5 network, 6 threshold breach
- `--dry-run` on every write operation
- `gpc changelog generate --format prompt` for LLM-ready release-notes prompts (no model bundled — the CLI emits the prompt, the agent runs the inference)

For the full contract, see `gpc-sdk-usage` and the [JSON Output Contract](https://yasserstudio.github.io/gpc/reference/json-contract) in the docs.

## Related

- [Android CLI Interop guide (docs)](https://yasserstudio.github.io/gpc/guide/android-cli-interop) — the user-facing version of this skill, with screenshots and end-to-end example
- [Google's Android CLI announcement](https://android-developers.googleblog.com/2026/04/build-android-apps-3x-faster-using-any-agent.html) — scope definition and commands
- `gpc-release-flow` — the actual release procedure this skill hands off to
- `gpc-preflight` — the compliance scanner
- `gpc-vitals-monitoring` — post-release monitoring
