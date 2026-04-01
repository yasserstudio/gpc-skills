# GitLab CI Templates for GPC

Ready-to-use `.gitlab-ci.yml` configurations for GPC.

## Authentication setup

Store your service account JSON as a GitLab CI/CD variable:

1. Go to **Settings > CI/CD > Variables**
2. Add variable `PLAY_SA_KEY` with the JSON content
3. Set type to **Variable** (not File)
4. Mark as **Protected** and **Masked** if possible

## Basic upload on tag

```yaml
stages:
  - deploy

upload-to-internal:
  stage: deploy
  image: node:20
  only:
    - tags
  variables:
    GPC_SERVICE_ACCOUNT: $PLAY_SA_KEY
    GPC_APP: com.example.app
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc validate app/build/outputs/bundle/release/app-release.aab
    - gpc releases upload app/build/outputs/bundle/release/app-release.aab --track internal --changes-not-sent-for-review
```

## Full pipeline with promotion

```yaml
stages:
  - upload
  - verify
  - promote

variables:
  GPC_SERVICE_ACCOUNT: $PLAY_SA_KEY
  GPC_APP: com.example.app
  GPC_MAX_RETRIES: "5"
  GPC_TIMEOUT: "120000"

upload-beta:
  stage: upload
  image: node:20
  only:
    - tags
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc releases upload app-release.aab --track beta --changes-not-sent-for-review
    - echo "Uploaded to beta"

check-vitals:
  stage: verify
  image: node:20
  only:
    - tags
  when: delayed
  start_in: "24 hours"
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc vitals crashes --threshold 1.5
    - gpc vitals anr --threshold 0.4
  allow_failure: false

promote-production:
  stage: promote
  image: node:20
  only:
    - tags
  when: manual
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc releases promote --from beta --to production --rollout 10
    - echo "Promoted to production at 10%"
```

## Scheduled vitals check

```yaml
vitals-report:
  image: node:20
  only:
    - schedules
  variables:
    GPC_SERVICE_ACCOUNT: $PLAY_SA_KEY
    GPC_APP: com.example.app
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc vitals overview --json > vitals.json
    - gpc vitals crashes --threshold 2.0
    - gpc vitals anr --threshold 0.5
  artifacts:
    paths:
      - vitals.json
    expire_in: 30 days
```

## IAP sync on merge to main

```yaml
sync-iap:
  stage: deploy
  image: node:20
  only:
    - main
  changes:
    - products/**/*.json
  variables:
    GPC_SERVICE_ACCOUNT: $PLAY_SA_KEY
    GPC_APP: com.example.app
  before_script:
    - npm install -g @gpc-cli/cli
  script:
    - gpc iap sync --dir products/ --dry-run
    - gpc iap sync --dir products/
```

## Tips

- Use `when: delayed` with `start_in` for time-gated stages
- Use `when: manual` for promotion steps that need human approval
- Use `changes:` to run IAP/metadata sync only when relevant files change
- Set `GPC_MAX_RETRIES` and `GPC_TIMEOUT` as global variables for shared runners
- Use `artifacts` to save vitals reports and upload logs
