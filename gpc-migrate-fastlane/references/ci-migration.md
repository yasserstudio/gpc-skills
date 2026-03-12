# CI Migration: Fastlane → GPC

Platform-specific examples for replacing Fastlane supply with GPC in CI pipelines.

## GitHub Actions

### Before (Fastlane)

```yaml
name: Deploy
on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Deploy to beta
        env:
          SUPPLY_JSON_KEY_DATA: ${{ secrets.PLAY_SA_KEY }}
        run: bundle exec fastlane supply --aab app.aab --track beta
```

### After (GPC)

```yaml
name: Deploy
on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Deploy to beta
        env:
          GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
          GPC_APP: com.example.app
        run: npx @gpc-cli/cli releases upload app.aab --track beta
```

**Key differences:**
- No Ruby/Bundler setup needed
- `SUPPLY_JSON_KEY_DATA` → `GPC_SERVICE_ACCOUNT`
- `bundle exec fastlane supply` → `npx @gpc-cli/cli releases upload`
- Add `GPC_APP` (Fastlane reads from Appfile)

## GitLab CI

### Before (Fastlane)

```yaml
deploy:
  image: ruby:3.2
  stage: deploy
  only: [tags]
  before_script:
    - bundle install
  script:
    - bundle exec fastlane supply --aab app.aab --track beta
```

### After (GPC)

```yaml
deploy:
  image: node:20
  stage: deploy
  only: [tags]
  variables:
    GPC_SERVICE_ACCOUNT: $PLAY_SA_KEY
    GPC_APP: com.example.app
  script:
    - npx @gpc-cli/cli releases upload app.aab --track beta
```

## Bitbucket Pipelines

### Before (Fastlane)

```yaml
pipelines:
  tags:
    'v*':
      - step:
          image: ruby:3.2
          script:
            - bundle install
            - bundle exec fastlane supply --aab app.aab --track beta
```

### After (GPC)

```yaml
pipelines:
  tags:
    'v*':
      - step:
          image: node:20
          script:
            - npx @gpc-cli/cli releases upload app.aab --track beta
```

## Secrets migration

| CI Platform | Fastlane Secret | GPC Secret |
|------------|----------------|------------|
| GitHub Actions | `PLAY_SA_KEY` (as `SUPPLY_JSON_KEY_DATA`) | `PLAY_SA_KEY` (as `GPC_SERVICE_ACCOUNT`) |
| GitLab CI | `PLAY_SA_KEY` variable | `PLAY_SA_KEY` variable |
| Bitbucket | `PLAY_SA_KEY` repository variable | `PLAY_SA_KEY` repository variable |

The same secret value works — just change the environment variable name.

## Added benefits after migration

Once on GPC, you can add these capabilities that Fastlane doesn't have:

```yaml
# Vitals gating before production promotion
- name: Check vitals
  run: npx @gpc-cli/cli vitals crashes --threshold 1.5

# Staged rollout with percentage control
- name: Promote with rollout
  run: npx @gpc-cli/cli releases promote --from beta --to production --rollout 10

# Step summary in GitHub Actions (via plugin-ci)
- name: Upload with summary
  run: npx @gpc-cli/cli releases upload app.aab --track beta
  # Automatically writes to $GITHUB_STEP_SUMMARY
```
