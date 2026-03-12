---
name: gpc-user-management
description: "Use when managing Google Play developer account users, permissions, or testers. Make sure to use this skill whenever the user mentions gpc users, gpc testers, developer account permissions, user roles, invite user, remove user, permission grants, per-app permissions, tester groups, beta testers, internal testers, alpha testers, Google Group testers, tester CSV import, team management, access control, user audit — even if they don't explicitly say 'user management.' Also trigger when someone wants to invite team members to their Play Console, update permissions for existing users, manage who can test their app, import testers from a CSV file, or audit who has access to their developer account. For authentication setup, see gpc-setup. For release track management, see gpc-release-flow."
compatibility: "GPC v0.9.9+. Requires authenticated GPC setup (see gpc-setup skill). User commands require developer account ID. Tester commands require an app with testing tracks configured."
metadata:
  version: 1.0.0
---

# gpc-user-management

Manage developer account users, permissions, and testers with GPC.

## When to use

- Inviting or removing users from a Google Play developer account
- Updating user permissions (developer-level or per-app)
- Listing and auditing who has access to the developer account
- Adding or removing testers from testing tracks (internal, alpha, beta)
- Importing testers in bulk from a CSV file
- Setting up Google Group-based tester access

## Inputs required

- **Authenticated GPC** — `gpc auth status` must show valid credentials
- **Developer account ID** — required for user commands (`--developer-id` or `GPC_DEVELOPER_ID`)
- **App package name** — required for tester commands and per-app grants (`--app`)
- **Email addresses** — for inviting users or adding testers
- **CSV file** — for bulk tester import (`--file`)

## Procedure

### 0. Verify setup

```bash
gpc auth status
gpc config get app
```

User commands require `--developer-id`. Set it once:

```bash
export GPC_DEVELOPER_ID=1234567890
```

Or pass it per command: `gpc users list --developer-id 1234567890`.

### 1. Users — list and inspect

```bash
# List all users in the developer account
gpc users list --developer-id 1234567890

# Get details for a specific user
gpc users get user@example.com --developer-id 1234567890

# JSON output for scripting
gpc users list --developer-id 1234567890 --json
```

### 2. Users — invite

Invite a new user with developer-level permissions and optional per-app grants:

```bash
# Invite with developer-level permissions
gpc users invite user@example.com \
  --role VIEW_APP_INFORMATION VIEW_FINANCIAL_DATA \
  --developer-id 1234567890

# Invite with per-app grants
gpc users invite user@example.com \
  --grant "com.example.app:VIEW_APP_INFORMATION,MANAGE_TESTING" \
  --developer-id 1234567890

# Combine developer-level and per-app permissions
gpc users invite user@example.com \
  --role VIEW_APP_INFORMATION \
  --grant "com.example.app:MANAGE_PRODUCTION_RELEASES" \
  --developer-id 1234567890

# Preview first
gpc users invite user@example.com \
  --role VIEW_APP_INFORMATION \
  --developer-id 1234567890 \
  --dry-run
```

`Read:` `references/permissions.md` for the full list of developer-level and per-app permission constants.

**Note:** Permission changes may take up to 48 hours to propagate across Google's systems.

### 3. Users — update permissions

```bash
# Update developer-level permissions
gpc users update user@example.com \
  --role VIEW_APP_INFORMATION VIEW_FINANCIAL_DATA MANAGE_ORDERS \
  --developer-id 1234567890

# Update per-app grants
gpc users update user@example.com \
  --grant "com.example.app:MANAGE_PRODUCTION_RELEASES,MANAGE_TESTING" \
  --developer-id 1234567890

# Preview changes
gpc users update user@example.com \
  --role VIEW_APP_INFORMATION \
  --developer-id 1234567890 \
  --dry-run
```

### 4. Users — remove

```bash
# Preview removal
gpc users remove user@example.com --developer-id 1234567890 --dry-run

# Remove
gpc users remove user@example.com --developer-id 1234567890
```

### 5. Testers — list

```bash
# List testers for a track
gpc testers list --track internal
gpc testers list --track alpha
gpc testers list --track beta

# JSON output
gpc testers list --track beta --json
```

### 6. Testers — add and remove

```bash
# Add individual testers (Google Group emails or individual emails)
gpc testers add tester1@gmail.com tester2@gmail.com --track internal

# Add a Google Group
gpc testers add testers-group@googlegroups.com --track beta

# Remove testers
gpc testers remove tester1@gmail.com --track internal

# Preview changes
gpc testers add tester1@gmail.com --track beta --dry-run
```

### 7. Testers — bulk import from CSV

Import testers from a CSV file containing email addresses:

```bash
# Preview import
gpc testers import --track beta --file testers.csv --dry-run

# Import
gpc testers import --track beta --file testers.csv
```

CSV format — one email per line:

```csv
email
tester1@gmail.com
tester2@gmail.com
qa-team@googlegroups.com
```

`Read:` `references/tester-workflows.md` for common tester management patterns and Google Group best practices.

## Verification

- `gpc users list --developer-id <id>` returns current users with their permissions
- `gpc users get <email> --developer-id <id>` shows the user's current role and grants
- `gpc testers list --track <track>` returns testers for the specified track
- All `--dry-run` commands show what would change without modifying data
- JSON output works on all commands (`--json` flag)
- Permission changes may take up to 48 hours to propagate

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `DEVELOPER_ID_REQUIRED` | Missing `--developer-id` flag | Set `GPC_DEVELOPER_ID` env var or pass `--developer-id` |
| `PERMISSION_DENIED` on user commands | Service account lacks admin permissions | Service account needs "Admin" access in Play Console |
| `USER_NOT_FOUND` | Email not in the developer account | Check spelling; use `gpc users list` to verify |
| `INVALID_GRANT` format | Wrong `--grant` syntax | Format: `com.example.app:PERM1,PERM2` (colon between app and perms, commas between perms) |
| `INVALID_PERMISSION` | Unknown permission constant | Check `references/permissions.md` for valid constants |
| Permissions not taking effect | 48-hour propagation delay | Wait; changes are eventual — verify after 48 hours |
| `TRACK_NOT_FOUND` for testers | Track doesn't exist or wrong name | Valid tracks: `internal`, `alpha`, `beta`, or custom track names |
| CSV import fails | Wrong CSV format or encoding | Ensure UTF-8, one email per line, header row with `email` |
| `TESTER_LIMIT_EXCEEDED` | Track has maximum tester count | Internal: 100, Alpha/Beta: no hard limit but Google Groups recommended for scale |

## Related skills

- **gpc-setup** — authentication and developer account configuration
- **gpc-release-flow** — releasing to testing tracks that testers access
- **gpc-ci-integration** — automating tester management in CI/CD pipelines
