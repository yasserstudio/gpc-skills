# Tester Workflows

Common patterns for managing testers with GPC.

## Track types

| Track | Max testers | Use case |
|-------|------------|----------|
| `internal` | 100 | Core team, QA — fastest approval, no review |
| `alpha` | No hard limit | Extended team, dogfooding |
| `beta` | No hard limit | External beta users, public testing |

## Adding individual testers

```bash
# Add to internal testing
gpc testers add dev1@gmail.com dev2@gmail.com --track internal

# Add to beta
gpc testers add beta-user@gmail.com --track beta

# Add without auto-submitting changes for review
gpc testers add beta-user@gmail.com --track beta --changes-not-sent-for-review

# Abort if the app is currently in review or rejected
gpc testers add beta-user@gmail.com --track beta --error-if-in-review
```

## Using Google Groups

For large tester pools, use Google Groups instead of individual emails:

```bash
# Add a Google Group to beta
gpc testers add beta-testers@googlegroups.com --track beta
```

Benefits of Google Groups:
- Manage membership in Google Workspace — no GPC/API calls needed
- No per-track tester limits
- Self-service join/leave via group settings
- One API call to add/remove the group vs. N calls for individuals

## Bulk import from CSV

```bash
# Create CSV file
cat > testers.csv << 'EOF'
email
tester1@gmail.com
tester2@gmail.com
tester3@gmail.com
qa-group@googlegroups.com
EOF

# Preview import
gpc testers import --track beta --file testers.csv --dry-run

# Import
gpc testers import --track beta --file testers.csv
```

### CSV requirements

- UTF-8 encoding
- Header row with `email` column
- One email per row
- Supports individual emails and Google Group addresses

## Audit current testers

```bash
# List testers per track
gpc testers list --track internal --json
gpc testers list --track alpha --json
gpc testers list --track beta --json
```

## Remove testers

```bash
# Remove specific testers
gpc testers remove old-tester@gmail.com --track beta

# Remove multiple
gpc testers remove user1@gmail.com user2@gmail.com --track internal

# Remove without auto-submitting changes for review
gpc testers remove old-tester@gmail.com --track beta --changes-not-sent-for-review
```

## Onboarding workflow

Typical team onboarding sequence:

```bash
# 1. Invite user to developer account with permissions
gpc users invite newdev@example.com \
  --role VIEW_APP_INFORMATION MANAGE_TESTING \
  --developer-id 1234567890

# 2. Add them as internal tester
gpc testers add newdev@gmail.com --track internal

# 3. Verify
gpc users get newdev@example.com --developer-id 1234567890
gpc testers list --track internal
```

## Offboarding workflow

```bash
# 1. Remove from testing tracks
gpc testers remove olddev@gmail.com --track internal
gpc testers remove olddev@gmail.com --track beta

# 2. Remove from developer account
gpc users remove olddev@example.com --developer-id 1234567890
```

## CI/CD automation

Automate tester management in your pipeline:

```yaml
# GitHub Actions example — sync testers on PR merge
- name: Sync beta testers
  env:
    GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
    GPC_APP: com.example.app
  run: |
    npx @gpc-cli/cli testers import --track beta --file testers.csv --dry-run
    npx @gpc-cli/cli testers import --track beta --file testers.csv
```

Keep `testers.csv` in your repo — PR reviews for tester changes, git history for audit trail.
