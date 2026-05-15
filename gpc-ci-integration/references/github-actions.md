# GitHub Actions Integration

## Authentication Setup

1. **Create a repository secret:**
   - Go to repo → Settings → Secrets and variables → Actions
   - Add `PLAY_SERVICE_ACCOUNT` containing the service account JSON content

2. **Reference in workflow — step-scoped only (v0.9.74+):**
   ```yaml
   # Scope GPC_SERVICE_ACCOUNT to the specific upload step, not the job
   - name: Upload release
     env:
       GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
     run: gpc releases upload app-release.aab --track internal
   ```

   Never set `GPC_SERVICE_ACCOUNT` at the `jobs.<job>.env` level — this exposes the secret to every step including third-party actions.

## Workflow Templates

### Upload on Tag Push

```yaml
name: Release to Play Store
on:
  push:
    tags: ['v*']
  workflow_dispatch: {}

jobs:
  release:
    runs-on: ubuntu-latest
    env:
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
        run: npm install -g @gpc-cli/cli --ignore-scripts

      - name: Upload to internal track
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
        run: |
          gpc publish \
            app/build/outputs/bundle/release/app-release.aab \
            --track internal \
            --notes "Release ${GITHUB_REF_NAME}" \
            --changes-not-sent-for-review

      - name: Release summary
        if: always()
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
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
      GPC_APP: com.example.app
    steps:
      - uses: actions/checkout@v4

      - name: Install GPC
        run: npm install -g @gpc-cli/cli --ignore-scripts

      - name: Upload release
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
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
  workflow_dispatch: {}

jobs:
  check:
    runs-on: ubuntu-latest
    env:
      GPC_APP: com.example.app
    steps:
      - name: Install GPC
        run: npm install -g @gpc-cli/cli --ignore-scripts

      - name: Vitals dashboard
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
        run: gpc vitals overview --output markdown >> $GITHUB_STEP_SUMMARY

      - name: Check thresholds
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
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
