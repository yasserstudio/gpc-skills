# GitHub Actions Integration

## Authentication Setup

1. **Create a repository secret:**
   - Go to repo → Settings → Secrets and variables → Actions
   - Add `PLAY_SERVICE_ACCOUNT` containing the service account JSON content

2. **Reference in workflow:**
   ```yaml
   env:
     GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
   ```

## Workflow Templates

### Upload on Tag Push

```yaml
name: Release to Play Store
on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - name: Build AAB
        run: ./gradlew bundleRelease

      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Upload to internal track
        run: |
          gpc publish \
            app/build/outputs/bundle/release/app-release.aab \
            --track internal \
            --notes "Release ${GITHUB_REF_NAME}" \
            --changes-not-sent-for-review

      - name: Release summary
        if: always()
        run: gpc releases status --output markdown >> $GITHUB_STEP_SUMMARY
```

### Manual Release with Inputs

```yaml
name: Manual Release
on:
  workflow_dispatch:
    inputs:
      track:
        description: Target track
        type: choice
        options: [internal, alpha, beta, production]
        default: internal
      rollout:
        description: Rollout percentage (production only)
        type: number
        default: 100
      dry_run:
        description: Dry run (preview only)
        type: boolean
        default: false

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
          FLAGS=""
          if [ "${{ inputs.dry_run }}" = "true" ]; then
            FLAGS="--dry-run"
          fi
          gpc releases upload app-release.aab \
            --track ${{ inputs.track }} \
            --rollout ${{ inputs.rollout }} \
            --changes-not-sent-for-review \
            $FLAGS
```

### Scheduled Vitals Check

```yaml
name: Vitals Monitor
on:
  schedule:
    - cron: '0 9 * * 1-5'  # Weekdays at 9am UTC

jobs:
  check:
    runs-on: ubuntu-latest
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
      GPC_APP: com.example.app
    steps:
      - name: Install GPC
        run: npm install -g @gpc-cli/cli

      - name: Vitals dashboard
        run: gpc vitals overview --output markdown >> $GITHUB_STEP_SUMMARY

      - name: Check thresholds
        run: |
          gpc vitals crashes --threshold 2.0
          gpc vitals anr --threshold 0.47
```

## Step Summary Output

GPC supports `--output markdown` which works perfectly with `$GITHUB_STEP_SUMMARY`:

```bash
# Add release status to step summary
gpc releases status --output markdown >> $GITHUB_STEP_SUMMARY

# Add vitals dashboard to step summary
gpc vitals overview --output markdown >> $GITHUB_STEP_SUMMARY

# Add review summary
gpc reviews list --stars 1-2 --since 7d --output markdown >> $GITHUB_STEP_SUMMARY
```

## Plugin-CI Integration

GPC's `@gpc-cli/plugin-ci` automatically detects GitHub Actions and writes step summaries:

- After each command: markdown table with app, duration, exit code
- On errors: error details with code and message

This happens automatically — no configuration needed.

## Concurrency Control

Prevent parallel releases to the same app:

```yaml
concurrency:
  group: play-store-release-${{ github.ref }}
  cancel-in-progress: false  # Don't cancel running releases
```

## Caching GPC

Speed up workflows by caching GPC installation:

```yaml
- name: Cache GPC
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: gpc-${{ hashFiles('**/package-lock.json') }}

- name: Install GPC
  run: npm install -g @gpc-cli/cli
```
