# CI/CD for Multiple Apps

Platform-specific patterns for deploying multiple apps in CI.

## GitHub Actions — Matrix strategy

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
        include:
          - app: com.example.main
            aab: main/app-release.aab
          - app: com.example.lite
            aab: lite/app-release.aab
          - app: com.example.pro
            aab: pro/app-release.aab
      fail-fast: false  # Don't cancel other apps if one fails
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Upload to beta
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
          GPC_APP: ${{ matrix.app }}
        run: npx @gpc-cli/cli releases upload ${{ matrix.aab }} --track beta
```

## GitHub Actions — Different service accounts

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        include:
          - app: com.ourcompany.app
            secret: PLAY_SA_KEY_MAIN
          - app: com.client.app
            secret: PLAY_SA_KEY_CLIENT
    steps:
      - name: Upload
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets[matrix.secret] }}
          GPC_APP: ${{ matrix.app }}
        run: npx @gpc-cli/cli releases upload app.aab --track beta
```

## GitLab CI — Parallel jobs

```yaml
.deploy-template:
  image: node:20
  stage: deploy
  only: [tags]
  script:
    - npx @gpc-cli/cli releases upload ${AAB_PATH} --track beta

deploy-main:
  extends: .deploy-template
  variables:
    GPC_APP: com.example.main
    AAB_PATH: main/app-release.aab

deploy-lite:
  extends: .deploy-template
  variables:
    GPC_APP: com.example.lite
    AAB_PATH: lite/app-release.aab
```

## Batch vitals check in CI

```yaml
# GitHub Actions
- name: Check vitals for all apps
  env:
    GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
  run: |
    FAILED=0
    for app in com.example.main com.example.lite com.example.pro; do
      echo "Checking $app..."
      if ! npx @gpc-cli/cli vitals crashes --threshold 2.0 --app "$app"; then
        echo "::warning::$app crash rate exceeds threshold"
        FAILED=1
      fi
    done
    exit $FAILED
```

## Sequential deployment with promotion gates

```yaml
jobs:
  deploy-internal:
    strategy:
      matrix:
        app: [com.example.main, com.example.lite]
    steps:
      - name: Upload to internal
        env:
          GPC_APP: ${{ matrix.app }}
        run: npx @gpc-cli/cli releases upload app.aab --track internal

  promote-beta:
    needs: deploy-internal
    strategy:
      matrix:
        app: [com.example.main, com.example.lite]
    steps:
      - name: Promote to beta
        env:
          GPC_APP: ${{ matrix.app }}
        run: npx @gpc-cli/cli releases promote --from internal --to beta
```
