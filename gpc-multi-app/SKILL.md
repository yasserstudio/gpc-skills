---
name: gpc-multi-app
description: "Use when managing multiple Google Play apps with GPC. Make sure to use this skill whenever the user mentions multiple apps, multi-app, monorepo, white-label, batch operations, bulk upload, several apps, --app flag, app switching, profiles for different apps, fleet management, app portfolio, multiple package names — even if they don't explicitly say 'multi-app.' Also trigger when someone has more than one Android app and wants to manage them efficiently, when they need different configurations per app, when they're running the same command across multiple apps, or when they have a monorepo with multiple Android modules. For single-app setup, see gpc-setup. For CI automation, see gpc-ci-integration."
compatibility: "GPC v0.9.9+ (--profile global flag requires v0.9.55+). Requires authenticated GPC setup (see gpc-setup skill)."
metadata:
  version: 1.0.1
---

# gpc-multi-app

Managing multiple Google Play apps with GPC using profiles, scripting, and automation patterns.

## When to use

- Managing multiple Android apps (portfolio, white-label, variants)
- Running the same GPC command across several apps
- Setting up per-app configurations and credentials
- Monorepo with multiple Android modules
- Different service accounts for different apps

## Inputs required

- **Authenticated GPC** — `gpc auth status` must show valid credentials
- **Package names** — for all apps being managed
- **Service account keys** — may differ per app or developer account

## Procedure

### 0. Understand app resolution

GPC resolves the target app in this order:

1. `--app` CLI flag (highest priority)
2. `GPC_APP` environment variable
3. `.gpcrc.json` in project directory
4. User config at `~/.config/gpc/config.json`
5. Active profile override

### 1. Quick health check across all apps

Use `gpc status --all-apps` to check health across all configured apps at once:

```bash
gpc status --all-apps
```

This reports the status of every app defined in your profiles or config, without needing to switch profiles or pass `--app` for each one.

### 2. Per-app configuration with profiles

Set up named profiles for each app:

```bash
# Configure profiles in ~/.config/gpc/config.json
```

```json
{
  "app": "com.example.main",
  "profiles": {
    "main": {
      "app": "com.example.main",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    },
    "lite": {
      "app": "com.example.lite",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    },
    "enterprise": {
      "app": "com.example.enterprise",
      "auth": { "serviceAccount": "/keys/enterprise-sa.json" }
    }
  }
}
```

Use profiles per command:

```bash
gpc releases list --profile main
gpc releases list --profile lite
gpc releases list --profile enterprise
```

Or set via environment:

```bash
export GPC_PROFILE=enterprise
gpc releases list  # uses enterprise profile
```

`Read:` `references/profile-patterns.md` for advanced profile configurations.

### 3. Project-level .gpcrc.json

For monorepos, place `.gpcrc.json` in each app's directory:

```
monorepo/
├── apps/
│   ├── main/
│   │   ├── .gpcrc.json          # { "app": "com.example.main" }
│   │   └── build.gradle
│   ├── lite/
│   │   ├── .gpcrc.json          # { "app": "com.example.lite" }
│   │   └── build.gradle
│   └── enterprise/
│       ├── .gpcrc.json          # { "app": "com.example.enterprise" }
│       └── build.gradle
└── .gpcrc.json                  # shared defaults
```

GPC walks up from the current directory to find `.gpcrc.json`, so running commands from each app's directory automatically uses the right package name.

### 4. Batch operations with shell scripts

Run the same command across all apps:

```bash
#!/bin/bash
# deploy-all.sh — upload to internal track for all apps

APPS=(
  "com.example.main"
  "com.example.lite"
  "com.example.enterprise"
)

for app in "${APPS[@]}"; do
  echo "Uploading $app..."
  gpc releases upload "build/$app/app-release.aab" --track internal --app "$app"
done
```

### 5. Batch vitals check

```bash
#!/bin/bash
# check-vitals.sh — check crash rate across all apps

APPS=("com.example.main" "com.example.lite" "com.example.enterprise")
THRESHOLD=2.0
FAILED=0

for app in "${APPS[@]}"; do
  echo "Checking $app..."
  if ! gpc vitals crashes --threshold "$THRESHOLD" --app "$app"; then
    echo "FAIL: $app crash rate exceeds ${THRESHOLD}%"
    FAILED=1
  fi
done

exit $FAILED
```

### 6. CI/CD for multiple apps

`Read:` `references/ci-multi-app.md` for CI platform-specific multi-app workflows.

#### GitHub Actions matrix strategy

```yaml
name: Deploy All Apps
on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app:
          - { package: "com.example.main", aab: "main/app-release.aab" }
          - { package: "com.example.lite", aab: "lite/app-release.aab" }
          - { package: "com.example.enterprise", aab: "enterprise/app-release.aab" }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Upload to internal
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
          GPC_APP: ${{ matrix.app.package }}
        run: npx @gpc-cli/cli releases upload ${{ matrix.app.aab }} --track internal
```

### 7. Different service accounts per app

When apps belong to different developer accounts:

```bash
# Use different env vars per command
GPC_SERVICE_ACCOUNT=$(cat keys/main.json) gpc releases list --app com.example.main
GPC_SERVICE_ACCOUNT=$(cat keys/client.json) gpc releases list --app com.client.app
```

Or use profiles (recommended):

```json
{
  "profiles": {
    "main": {
      "app": "com.example.main",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    },
    "client": {
      "app": "com.client.app",
      "auth": { "serviceAccount": "/keys/client-sa.json" }
    }
  }
}
```

### 8. Bulk metadata sync

Sync listings for all apps from a shared metadata structure:

```bash
# metadata/
# ├── com.example.main/
# │   └── en-US/
# ├── com.example.lite/
# │   └── en-US/

for dir in metadata/*/; do
  app=$(basename "$dir")
  echo "Syncing $app..."
  gpc listings push --dir "$dir" --app "$app" --dry-run
done
```

## Verification

- `gpc config list --profile <name>` shows correct app and auth per profile
- Commands with `--app` or `--profile` target the right app
- Batch scripts exit 0 when all apps succeed
- CI matrix runs deploy independently per app
- `.gpcrc.json` in subdirectories correctly overrides the default app

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Wrong app targeted | `--app` not set, picking up default | Always pass `--app` or use profiles explicitly |
| `API_FORBIDDEN` on one app | Service account lacks access for that app | Check permissions per app in Play Console |
| Batch script fails silently | Missing error handling in loop | Use `set -e` or check `$?` after each command |
| Profile not found | Typo in profile name | Check `gpc config list` for available profiles |
| CI matrix job fails one app | Independent failure | Matrix jobs run independently — check logs per app |
| `.gpcrc.json` not picked up | Running from wrong directory | GPC walks up from `cwd`; ensure you're in the right dir |

## Related skills

- **gpc-setup** — initial auth and profiles configuration
- **gpc-ci-integration** — CI pipeline setup for single apps
- **gpc-sdk-usage** — programmatic multi-app management with the TypeScript SDK
- **gpc-user-management** — managing per-app permissions for team members
