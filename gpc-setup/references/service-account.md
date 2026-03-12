# Service Account Setup

## Creating a Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **IAM & Admin → Service Accounts**
4. Click **Create Service Account**
5. Name it (e.g., `gpc-release-manager`)
6. No roles needed at this step — permissions are granted in Play Console
7. Click **Done**
8. Click the service account → **Keys** tab → **Add Key → Create New Key → JSON**
9. Download the key file — this is your `key.json`

## Granting Play Console Access

1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to **Settings → API access**
3. Link your Google Cloud project (if not already linked)
4. Find your service account in the list
5. Click **Grant access**
6. Set permissions:
   - **App access:** Select specific apps or all apps
   - **Account permissions:** Set based on what GPC will do
   - **App permissions:** Release management, store listing, etc.

### Recommended Permissions by Use Case

| Use Case | Required Permissions |
|----------|---------------------|
| Upload + release | Release to production, Manage testing tracks |
| Metadata sync | Edit store listing, Manage store presence |
| Reviews | Reply to reviews |
| Vitals | View app quality information |
| Full access | All of the above |

## Security Best Practices

- **Never commit key files to git.** Add `*.json` key files to `.gitignore`.
- **Use environment variables in CI.** Store the JSON content as a secret, not a file.
- **Rotate keys periodically.** Delete old keys after creating new ones.
- **Principle of least privilege.** Grant only the permissions GPC needs.
- **Use separate service accounts** for development vs production.

## Environment Variable Formats

```bash
# File path
export GPC_SERVICE_ACCOUNT=/path/to/key.json

# Inline JSON (useful in CI where you can't write files)
export GPC_SERVICE_ACCOUNT='{"type":"service_account","project_id":"my-project",...}'

# Base64 encoded (alternative for CI)
export GPC_SERVICE_ACCOUNT=$(echo '{"type":"service_account",...}' | base64)
```

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `The caller does not have permission` | Service account not granted Play Console access | Add in Play Console → Settings → API access |
| `Could not load the default credentials` | Key file not found or invalid | Check file path and JSON validity |
| `Request had insufficient authentication scopes` | Wrong scopes | GPC handles scopes automatically — ensure the key file is valid |
