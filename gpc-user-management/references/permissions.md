# Google Play Permission Constants

Reference for permission values used with `gpc users invite` and `gpc users update`.

## Developer-level permissions (`--role`)

These apply across all apps in the developer account.

| Permission | Description |
|-----------|-------------|
| `VIEW_APP_INFORMATION` | View app info, listings, and stats |
| `VIEW_FINANCIAL_DATA` | View financial reports, revenue, pricing |
| `MANAGE_ORDERS` | View and refund orders |
| `MANAGE_STORE_PRESENCE` | Edit store listings, graphics, descriptions |
| `MANAGE_PRODUCTION_RELEASES` | Create and manage production releases |
| `MANAGE_TESTING` | Manage testing tracks and testers |
| `MANAGE_POLICY_ISSUES` | View and respond to policy violations |
| `MANAGE_DEEP_LINKS` | Configure deep links and app links |

## Per-app permissions (`--grant`)

These are scoped to a specific app. Format: `com.example.app:PERM1,PERM2`.

Per-app grants use the same permission constants as developer-level roles, but apply only to the specified app.

### Examples

```bash
# Developer-level: can view all apps' info
gpc users invite user@example.com \
  --role VIEW_APP_INFORMATION \
  --developer-id 1234567890

# Per-app: can manage releases only for com.example.app
gpc users invite user@example.com \
  --grant "com.example.app:MANAGE_PRODUCTION_RELEASES,MANAGE_TESTING" \
  --developer-id 1234567890

# Mixed: view all apps, manage releases for one app
gpc users invite user@example.com \
  --role VIEW_APP_INFORMATION \
  --grant "com.example.app:MANAGE_PRODUCTION_RELEASES" \
  --developer-id 1234567890
```

### Multiple app grants

```bash
# Grant different permissions for different apps
gpc users invite user@example.com \
  --grant "com.example.app1:MANAGE_PRODUCTION_RELEASES" \
  --grant "com.example.app2:VIEW_APP_INFORMATION,MANAGE_TESTING" \
  --developer-id 1234567890
```

## Common role patterns

### Read-only reviewer

```bash
gpc users invite reviewer@example.com \
  --role VIEW_APP_INFORMATION \
  --developer-id 1234567890
```

### Finance team

```bash
gpc users invite finance@example.com \
  --role VIEW_APP_INFORMATION VIEW_FINANCIAL_DATA MANAGE_ORDERS \
  --developer-id 1234567890
```

### QA / Release engineer

```bash
gpc users invite qa@example.com \
  --role VIEW_APP_INFORMATION MANAGE_TESTING \
  --grant "com.example.app:MANAGE_PRODUCTION_RELEASES" \
  --developer-id 1234567890
```

### Full app manager (single app)

```bash
gpc users invite manager@example.com \
  --grant "com.example.app:VIEW_APP_INFORMATION,VIEW_FINANCIAL_DATA,MANAGE_ORDERS,MANAGE_STORE_PRESENCE,MANAGE_PRODUCTION_RELEASES,MANAGE_TESTING" \
  --developer-id 1234567890
```

## Propagation delay

Permission changes may take up to **48 hours** to propagate across Google's systems. During this time:

- The user's access may be inconsistent
- API calls made by the user's credentials may intermittently fail
- `gpc users get` will show the new permissions immediately, but enforcement is delayed

## Service account requirements

To manage users, your service account needs **Admin** access in the Google Play Console. This is a developer account-level setting, not a per-app grant.
