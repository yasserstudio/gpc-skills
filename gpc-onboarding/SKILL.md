---
name: gpc-onboarding
description: "Use when a user is setting up GPC for the first time or going through initial configuration. Trigger when the user mentions gpc quickstart, first-time setup, initial configuration, onboarding, getting started, service account creation, doctor --fix, auth setup-gcp — even if they don't say 'onboarding.' Also trigger when someone is brand new to GPC and needs guided setup."
compatibility: "GPC v0.9.38+. For existing config issues, see gpc-setup. For troubleshooting, see gpc-troubleshooting."
metadata:
  version: 0.10.0
---

# GPC Onboarding

## When to use

Use this skill when the task involves:

- A user running GPC for the very first time
- Guided first-run setup via `gpc quickstart`
- Interactive auth setup via `gpc auth login` wizard or `gpc auth setup-gcp`
- Resolving failing doctor checks with `gpc doctor --fix`
- Configuring a default app or a second app profile
- General "how do I get started with GPC?" questions

## Inputs required

- Whether the user has a service account JSON key already, or needs to create one
- The Android package name (e.g., `com.example.app`)
- Whether this is a fresh machine or an existing partial setup

## Commands

### `gpc quickstart`

Guided setup flow. Idempotent — safe to re-run.

```
Step 1/4  Checking for existing config...     ✓ Found profile "myapp"
Step 2/4  Verifying credentials...            ✓ Service account valid
Step 3/4  Checking package name...            ✓ com.example.app
Step 4/4  Running doctor...                   ✓ All checks passed

Ready. Here's what you can do next:
  gpc status              → app health snapshot
  gpc releases list       → current tracks
  gpc reviews list        → recent reviews
  gpc vitals overview     → crash and ANR rates
```

`gpc quickstart` is the recommended entry point for all new users. It detects existing config, validates credentials, confirms the package name, and runs a full doctor check — all in one flow.

**Note (v0.9.38+):** The quickstart spawn fix means `gpc quickstart` now works correctly on Homebrew and standalone binary installs. Previously, the internal `gpc doctor` spawn could fail on non-npm installs.

### `gpc auth login` (interactive wizard)

When run without flags in a TTY, `gpc auth login` prompts interactively:

1. Auth method: service account or ADC
2. Credentials file path (with validation loop — retries until a valid path is given)
3. Profile name (optional, defaults to `"default"`)
4. Default package name

Use this when `gpc quickstart` fails at the credentials step, or when the user wants more control over how auth is configured.

### `gpc auth setup-gcp`

Step-by-step service account creation guidance for users who do not yet have a GCP project or JSON key:

- Walks through creating a GCP project and enabling the Google Play Developer API
- Shows required IAM roles for the service account
- Explains how to grant the service account access in Play Console (Settings → API access)
- Guides downloading the JSON key file
- Verifies the result with `gpc auth status`

Use this when the user is starting from zero — no GCP project, no key file.

### `gpc doctor --fix`

Runs all doctor checks and applies inline remediation for each failing check.

```bash
gpc doctor          # show current health
gpc doctor --fix    # auto-fix what can be fixed
```

Each failing check displays a suggestion. `--fix` applies those suggestions automatically where possible. Issues that require manual steps (e.g., Play Console API access grants) are shown with instructions but cannot be auto-fixed.

## Procedure

### 0) Install GPC (if not already installed)

```bash
npm install -g @gpc-cli/cli
```

### 1) Run `gpc quickstart`

This covers the majority of first-time setups:

```bash
gpc quickstart
```

Follow the prompts. The wizard is idempotent — re-run it at any point.

### 2) If credentials are not yet set up

Option A — you already have a service account JSON key:
```bash
gpc auth login
```

Option B — you need to create a GCP project and service account from scratch:
```bash
gpc auth setup-gcp
```

### 3) Fix remaining doctor issues

```bash
gpc doctor --fix
```

Review any checks that still fail and follow the inline suggestions.

### 4) Verify

```bash
gpc status
```

A successful status output confirms GPC is fully configured and connected.

## After successful setup

Once onboarded, common next commands:

- `gpc status` — app health snapshot
- `gpc releases list` — view release tracks
- `gpc vitals overview` — crash/ANR dashboard
- `gpc reviews list` — recent user reviews

## Failure modes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `gpc quickstart` fails at Step 2 | Invalid or missing service account key | Re-run `gpc auth login` or `gpc auth setup-gcp` |
| `gpc doctor --fix` can't fix an issue | Manual intervention needed | Follow the suggestion shown for that check |
| No package name found | App not configured | `gpc config set app com.example.app` |
| Auth wizard loops on file path | File path is wrong or file doesn't exist | Provide the absolute path to the JSON key |
| `gpc quickstart` skips to Step 3/4 | Existing partial config found | Safe — it resumes from where setup left off |

## Related skills

- `gpc-setup` — detailed auth configuration, profiles, env vars, proxy setup
- `gpc-troubleshooting` — error codes, debug mode, common fixes
