# Multi-App Profile Patterns

Configuration patterns for managing multiple apps with GPC profiles.

## Basic profile setup

`~/.config/gpc/config.json`:

```json
{
  "app": "com.example.main",
  "profiles": {
    "main": {
      "app": "com.example.main"
    },
    "lite": {
      "app": "com.example.lite"
    }
  }
}
```

```bash
gpc releases list --profile main
gpc releases list --profile lite
```

## Different service accounts per profile

When apps belong to different developer accounts:

```json
{
  "profiles": {
    "our-app": {
      "app": "com.ourcompany.app",
      "auth": { "serviceAccount": "/keys/our-sa.json" }
    },
    "client-a": {
      "app": "com.client-a.app",
      "auth": { "serviceAccount": "/keys/client-a-sa.json" },
      "developerId": "1111111111"
    },
    "client-b": {
      "app": "com.client-b.app",
      "auth": { "serviceAccount": "/keys/client-b-sa.json" },
      "developerId": "2222222222"
    }
  }
}
```

## Environment-based profiles

```json
{
  "profiles": {
    "dev": {
      "app": "com.example.app.dev",
      "auth": { "serviceAccount": "/keys/dev-sa.json" }
    },
    "staging": {
      "app": "com.example.app.staging",
      "auth": { "serviceAccount": "/keys/staging-sa.json" }
    },
    "production": {
      "app": "com.example.app",
      "auth": { "serviceAccount": "/keys/prod-sa.json" }
    }
  }
}
```

```bash
# Deploy to each environment
gpc releases upload app.aab --track internal --profile dev
gpc releases upload app.aab --track beta --profile staging
gpc releases upload app.aab --track production --profile production
```

## White-label apps

```json
{
  "profiles": {
    "brand-a": {
      "app": "com.brand-a.app",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    },
    "brand-b": {
      "app": "com.brand-b.app",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    },
    "brand-c": {
      "app": "com.brand-c.app",
      "auth": { "serviceAccount": "/keys/main-sa.json" }
    }
  }
}
```

Same service account if all apps are under one developer account.

## Profile via environment variable

```bash
export GPC_PROFILE=production
gpc releases list  # uses production profile

# Override per command
gpc releases list --profile staging
```

## Monorepo pattern

Instead of profiles, use `.gpcrc.json` per app directory:

```
monorepo/
├── apps/main/.gpcrc.json       → { "app": "com.example.main" }
├── apps/lite/.gpcrc.json       → { "app": "com.example.lite" }
└── .gpcrc.json                 → shared config (no app set)
```

```bash
cd apps/main && gpc releases list    # uses com.example.main
cd apps/lite && gpc releases list    # uses com.example.lite
```

## Combining profiles with CI

```yaml
# GitHub Actions — deploy all white-label apps
jobs:
  deploy:
    strategy:
      matrix:
        profile: [brand-a, brand-b, brand-c]
    steps:
      - name: Deploy
        run: npx @gpc-cli/cli releases upload app-${{ matrix.profile }}.aab --track beta --profile ${{ matrix.profile }}
```
