# Application Default Credentials (ADC)

Using your own Google account for local development, without a service account key file.

GPC has two auth methods: a service account key, or Application Default Credentials. There is no built-in browser or device-code login. To act as your own Google account, sign in once with the `gcloud` CLI; GPC then picks up those credentials through ADC.

## When to use ADC

- **Local development**: no key file on disk
- **Google Cloud runtimes**: Cloud Build, Cloud Run, GKE and Compute Engine provide ADC automatically
- **Workload identity federation**: CI that exchanges an OIDC token for Google credentials

For CI/CD without federation, use a service account. See `references/service-account.md`.

## Sign in as yourself

```bash
# One-time: create user ADC with the Play scope
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/androidpublisher,https://www.googleapis.com/auth/cloud-platform

# Verify that GPC can mint a token from ADC
gpc auth login --adc

# Check
gpc auth status
gpc doctor
```

ADC is ambient: `gpc auth login --adc` verifies it but stores nothing, and it cannot be combined with `--profile` (usage error, exit 2). GPC falls back to ADC whenever no service account is configured through a flag, `GPC_SERVICE_ACCOUNT`, the config or the active profile.

Your Google account must have access to the app in Play Console (Users and permissions), the same as a service account would.

## Where the credentials live

| Data | Location | Owner |
|------|----------|-------|
| User refresh token | `~/.config/gcloud/application_default_credentials.json` (Windows: `%APPDATA%\gcloud\`) | gcloud |
| Cached access tokens | GPC cache dir (`~/.cache/gpc/`) | GPC; clear with `gpc auth clear-cache` |

GPC never stores your Google password or refresh token itself.

## Revoking access

```bash
# Revoke the gcloud user credentials
gcloud auth application-default revoke

# Drop GPC's cached access tokens
gpc auth clear-cache
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `invalid_grant` / "reauth required" | Re-run `gcloud auth application-default login` with the scopes above |
| 403 insufficient scopes | The ADC login omitted the `androidpublisher` scope; log in again with `--scopes` |
| 403 permission denied | Your Google account has no Play Console access to this app |
| Wrong account used | A service account (flag, env var or profile) takes precedence over ADC; check `gpc auth status` |

## ADC vs service account

| Aspect | ADC (your account) | Service account |
|--------|--------------------|-----------------|
| Setup | `gcloud` login | GCP project + key file + Play Console invite |
| CI/CD | Only via workload identity federation | Yes |
| Identity | You | A machine identity |
| Best for | Local dev, Google Cloud runtimes | CI/CD, automation |
