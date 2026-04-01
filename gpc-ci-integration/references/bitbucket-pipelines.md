# Bitbucket Pipelines Templates for GPC

Ready-to-use `bitbucket-pipelines.yml` configurations for GPC.

## Authentication setup

Store your service account JSON as a Bitbucket repository variable:

1. Go to **Repository settings > Pipelines > Repository variables**
2. Add variable `PLAY_SA_KEY` with the JSON content
3. Check **Secured** to encrypt it

## Basic upload on tag

```yaml
image: node:20

pipelines:
  tags:
    'v*':
      - step:
          name: Upload to internal
          script:
            - npm install -g @gpc-cli/cli
            - gpc validate app-release.aab
            - gpc releases upload app-release.aab --track internal --changes-not-sent-for-review
          artifacts:
            - '*.log'
```

Set `GPC_SERVICE_ACCOUNT` and `GPC_APP` as repository variables.

## Full pipeline with manual promotion

```yaml
image: node:20

definitions:
  steps:
    - step: &install-gpc
        name: Install GPC
        script:
          - npm install -g @gpc-cli/cli
          - gpc --version

pipelines:
  tags:
    'v*':
      - step:
          name: Upload to beta
          script:
            - npm install -g @gpc-cli/cli
            - gpc releases upload app-release.aab --track beta --changes-not-sent-for-review
      - step:
          name: Check vitals
          trigger: manual
          script:
            - npm install -g @gpc-cli/cli
            - gpc vitals crashes --threshold 1.5
            - gpc vitals anr --threshold 0.4
      - step:
          name: Promote to production
          trigger: manual
          script:
            - npm install -g @gpc-cli/cli
            - gpc releases promote --from beta --to production --rollout 10
```

## Scheduled vitals check

```yaml
pipelines:
  custom:
    vitals-check:
      - step:
          name: Check app vitals
          script:
            - npm install -g @gpc-cli/cli
            - gpc vitals overview --json
            - gpc vitals crashes --threshold 2.0
            - gpc vitals anr --threshold 0.5
```

Trigger via Bitbucket Schedules: **Pipelines > Schedules > Add schedule** and select the `vitals-check` custom pipeline.

## Environment variables

Set these as repository variables (all secured):

| Variable | Value |
|----------|-------|
| `GPC_SERVICE_ACCOUNT` | Service account JSON content |
| `GPC_APP` | `com.example.app` |
| `GPC_MAX_RETRIES` | `5` |
| `GPC_TIMEOUT` | `120000` |

## Tips

- Use `trigger: manual` for promotion steps
- Bitbucket has a 120-minute step timeout — set `GPC_TIMEOUT` well under this
- Use `artifacts` to save logs and reports
- Secured variables are not available in PRs from forks (security feature)
- Use `definitions` for reusable step templates
