---
name: gpc-ci-integration
description: "Use when integrating GPC into CI/CD pipelines. Make sure to use this skill whenever the user mentions GitHub Actions, GitLab CI, Bitbucket Pipelines, CircleCI, CI/CD, automated release, pipeline, GPC_SERVICE_ACCOUNT, JSON output, exit codes, gpc in CI, automate Play Store deployment, release workflow, deploy to Play Store from CI, automated rollout, step summary, or wants to set up any kind of automated Google Play deployment pipeline. Also trigger when someone asks about running GPC in a headless environment, parsing GPC output in scripts, using GPC exit codes for conditional logic, or configuring retries and timeouts for CI — even if they don't mention a specific CI platform. For local setup, see gpc-setup. For release commands, see gpc-release-flow."
compatibility: "GPC v0.9.9+. Works with any CI platform that supports Node.js 20+ or standalone binary."
metadata:
  version: 1.0.0
---

# GPC CI Integration

## When to use

Use this skill when the task involves:

- Setting up GPC in GitHub Actions, GitLab CI, Bitbucket Pipelines, or CircleCI
- Automating Play Store releases from CI/CD
- Configuring environment variables for CI authentication
- Using GPC's JSON output for scripting and automation
- Implementing vitals-gated rollouts in CI
- Building release pipelines with upload → promote → monitor flows
- Using `--dry-run` for safe CI testing

## Inputs required

- CI platform (GitHub Actions, GitLab CI, Bitbucket, CircleCI, or generic)
- Auth method (usually service account via env var)
- Release workflow: upload only, upload + promote, or full pipeline
- Whether vitals gating is desired
- Package name of the Android app

## Procedure

### 0) CI environment behavior

GPC auto-detects CI environments:

- **Output:** Defaults to JSON when stdout is not a TTY (piped or CI)
- **Interactive:** Prompts are disabled automatically when `CI=true`
- **Colors:** Disabled in non-TTY environments
- **Plugin-CI:** Writes GitHub Actions step summaries when `$GITHUB_STEP_SUMMARY` is available

Environment variables for CI override:
```bash
GPC_NO_INTERACTIVE=1   # Explicitly disable prompts
GPC_NO_COLOR=1         # Explicitly disable colors
GPC_OUTPUT=json        # Force JSON output
```

### 1) GitHub Actions

#### Minimal — upload to internal track:

```yaml
name: Upload to Play Store
on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build AAB
        run: ./gradlew bundleRelease

      - name: Upload to Play Store
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
          GPC_APP: com.example.app
        run: |
          npm install -g @gpc-cli/cli
          gpc releases upload app/build/outputs/bundle/release/app-release.aab --track internal
```

#### Full pipeline — upload, check vitals, promote:

```yaml
name: Release Pipeline
on:
  workflow_dispatch:
    inputs:
      track:
        description: 'Target track'
        default: 'beta'
      rollout:
        description: 'Rollout percentage'
        default: '100'

jobs:
  release:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - uses: actions/checkout@v4

      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Upload release
        run: |
          gpc releases upload app-release.aab \
            --track ${{ inputs.track }} \
            --rollout ${{ inputs.rollout }}

      - name: Check vitals
        if: inputs.track == 'production'
        run: |
          gpc vitals crashes --threshold 2.0
          gpc vitals anr --threshold 0.47

      - name: Release status
        if: always()
        run: gpc releases status --output markdown >> $GITHUB_STEP_SUMMARY
```

Read:
- `references/github-actions.md`

### 2) GitLab CI

```yaml
release:
  image: node:20
  stage: deploy
  variables:
    GPC_SERVICE_ACCOUNT: $PLAY_SERVICE_ACCOUNT
    GPC_APP: com.example.app
  script:
    - npm install -g @gpc-cli/cli
    - gpc releases upload app-release.aab --track internal
  only:
    - tags
```

### 3) Bitbucket Pipelines

```yaml
pipelines:
  tags:
    'v*':
      - step:
          name: Upload to Play Store
          image: node:20
          script:
            - npm install -g @gpc-cli/cli
            - gpc releases upload app-release.aab --track internal
          deployment: production
```

### 4) CircleCI

```yaml
jobs:
  release:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run:
          name: Upload to Play Store
          command: |
            npm install -g @gpc-cli/cli
            gpc releases upload app-release.aab --track internal
          environment:
            GPC_APP: com.example.app
```

### 5) Using standalone binary (no Node.js)

For minimal CI images without Node.js:

```yaml
- name: Install GPC binary
  run: curl -fsSL https://raw.githubusercontent.com/yasserstudio/gpc/main/scripts/install.sh | bash

- name: Upload
  run: gpc releases upload app-release.aab --track internal
```

### 6) JSON output for scripting

GPC auto-outputs JSON in CI (non-TTY). Parse with `jq`:

```bash
# Get version code from upload result
VERSION=$(gpc releases upload app.aab --track beta | jq -r '.data.versionCode')

# Check if vitals are OK
CRASH_RATE=$(gpc vitals crashes --output json | jq -r '.data.crashRate')

# Conditional promotion
if (( $(echo "$CRASH_RATE < 2.0" | bc -l) )); then
  gpc releases promote --from beta --to production --rollout 10
fi
```

### 7) Exit codes for CI logic

| Code | Meaning | CI Action |
|------|---------|-----------|
| `0` | Success | Continue |
| `1` | General error | Fail job |
| `2` | Usage error (bad arguments) | Fix command |
| `3` | Authentication error | Check secrets |
| `4` | API error (rate limit, permission) | Retry or fix permissions |
| `5` | Network error | Retry |
| `6` | Threshold breach (vitals) | Block promotion |
| `10` | Plugin error | Check plugin config |

```yaml
- name: Check vitals
  run: gpc vitals crashes --threshold 2.0
  continue-on-error: false  # Exit code 6 fails the job
```

### 8) Vitals-gated rollout pattern

```yaml
- name: Upload to beta
  run: gpc publish app.aab --track beta

- name: Wait for crash data
  run: sleep 3600  # Wait 1 hour for crash data

- name: Gate on vitals
  run: |
    gpc vitals crashes --threshold 2.0
    gpc vitals anr --threshold 0.47

- name: Promote to production
  run: gpc releases promote --from beta --to production --rollout 10
```

### 9) Dry-run for testing pipelines

Test your CI pipeline without making real changes:

```yaml
- name: Test release pipeline (dry-run)
  run: |
    gpc releases upload app.aab --track beta --dry-run
    gpc releases promote --from beta --to production --rollout 10 --dry-run
```

### 10) Markdown output for GitHub step summaries

```bash
gpc releases status --output markdown >> $GITHUB_STEP_SUMMARY
gpc vitals overview --output markdown >> $GITHUB_STEP_SUMMARY
```

### 11) Retry and timeout configuration

GPC automatically retries HTTP 408 (Request Timeout), 429 (Rate Limited), and 5xx (Server Error) responses with exponential backoff.

```yaml
env:
  GPC_MAX_RETRIES: '5'
  GPC_TIMEOUT: '60000'
  GPC_BASE_DELAY: '2000'
  GPC_MAX_DELAY: '120000'
  GPC_RATE_LIMIT: '50'
```

Use `--retry-log` to debug transient failures:
```bash
gpc releases upload app.aab --track beta --retry-log retries.log
```

## Verification

- CI job completes with exit code 0
- `gpc releases status` (in subsequent step) confirms release is on expected track
- GitHub Actions step summary shows release details
- Vitals check exits 0 (below threshold) or 6 (above threshold) as expected

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `AUTH_INVALID` in CI | Secret not set or wrong format | Verify `PLAY_SERVICE_ACCOUNT` secret contains valid JSON |
| `Permission denied` | Service account lacks Play Console access | Grant access in Play Console → Settings → API access |
| Timeout on upload | Large AAB + slow CI network | Increase `GPC_TIMEOUT` |
| Rate limited | Too many API calls | Increase `GPC_BASE_DELAY`, reduce parallelism |
| Exit code 6 | Vitals threshold breached | Review crash/ANR data, fix issues before promoting |
| `EDIT_CONFLICT` | Parallel runs editing same app | Serialize release jobs or use job concurrency limits |

Read:
- `references/troubleshooting.md`

## Related skills

- **gpc-setup**: Initial authentication and configuration
- **gpc-release-flow**: Release commands and rollout management
- **gpc-vitals-monitoring**: Vitals metrics and review management
- **gpc-metadata-sync**: Store listing automation
