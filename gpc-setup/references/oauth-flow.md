# OAuth Device Flow

Using OAuth for local development and interactive authentication with GPC.

## When to use OAuth

- **Local development** — when you don't have a service account key file
- **Personal use** — managing your own Play Console account
- **Quick setup** — no Google Cloud Console project required
- **Multiple accounts** — switching between personal and team accounts

For CI/CD, always use service accounts instead. See `references/service-account.md`.

## OAuth login

```bash
# Start OAuth device flow
gpc auth login --oauth

# GPC will display:
# 1. A URL to open in your browser
# 2. A code to enter on that page
# 3. Wait for you to authorize
```

### Flow steps

1. GPC generates a device code and verification URL
2. You open the URL in any browser (can be a different device)
3. Enter the code shown in your terminal
4. Sign in with your Google account
5. Grant GPC access to Google Play Developer API
6. GPC receives the token and stores it securely

## Token storage

OAuth tokens are stored in your OS keychain:

| OS | Storage |
|----|---------|
| macOS | Keychain Access |
| Linux | libsecret (GNOME Keyring) |
| Windows | Windows Credential Manager |

Fallback: `~/.config/gpc/credentials.json` (file-based, less secure).

## Token refresh

- Access tokens expire after 1 hour
- GPC automatically refreshes using the stored refresh token
- If the refresh token is revoked, re-run `gpc auth login --oauth`

## OAuth with profiles

Use named profiles for multiple accounts:

```bash
# Login with a profile name
gpc auth login --oauth --profile personal
gpc auth login --oauth --profile work

# Switch between profiles
gpc auth switch personal
gpc auth switch work

# Use a profile for a single command
gpc releases list --profile work
```

## Revoking access

```bash
# Revoke OAuth token
gpc auth logout

# Revoke a specific profile
gpc auth logout --profile personal
```

You can also revoke from Google Account settings: **Security > Third-party apps > GPC**.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Token expired" after long idle | Re-run `gpc auth login --oauth` |
| "Access denied" during authorization | Ensure your Google account has Play Console access |
| Keychain prompt on every command | Grant "Always Allow" when prompted |
| Linux: "No secret service available" | Install `gnome-keyring` or `libsecret` |
| Browser doesn't open | Copy the URL manually from the terminal output |

## OAuth vs Service Account

| Aspect | OAuth | Service Account |
|--------|-------|----------------|
| Setup complexity | Low (browser login) | Medium (GCP project + key file) |
| CI/CD compatible | No | Yes |
| Token expiry | 1 hour (auto-refresh) | 1 hour (auto-refresh) |
| Security | User-scoped | Machine-scoped |
| Best for | Local dev | CI/CD, automation |
