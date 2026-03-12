---
name: gpc-setup
description: "Use when setting up GPC (Google Play Console CLI): authentication with service accounts, OAuth, or Application Default Credentials; configuration files (.gpcrc.json, env vars, XDG paths); auth profiles; running gpc doctor; troubleshooting auth errors. Make sure to use this skill whenever the user mentions gpc auth, service account setup, gpc config, gpc doctor, GPC_SERVICE_ACCOUNT, gpc auth login, Google Play API credentials, Play Console authentication, or wants to install/configure GPC — even if they don't explicitly say 'setup.' Also trigger when someone is troubleshooting auth failures, token expiration, keychain issues, or proxy/network configuration for GPC."
compatibility: "GPC v0.9.9+. Requires Node.js 20+, pnpm 9+ (for development). npm for installation."
metadata:
  version: 1.0.0
---

# GPC Setup

## When to use

Use this skill when the task involves:

- Installing GPC (`npm install -g @gpc-cli/cli` or standalone binary)
- Authenticating with Google Play Developer API (service account, OAuth, ADC)
- Managing auth profiles (`gpc auth profiles`, `gpc auth switch`)
- Configuring GPC (`.gpcrc.json`, env vars, `gpc config init`)
- Diagnosing setup issues (`gpc doctor`)
- Setting up GPC in a new project or CI environment

## Inputs required

- Whether this is local development or CI/CD setup
- Auth method: service account JSON, OAuth, or Application Default Credentials
- Package name of the Android app (e.g., `com.example.app`)
- If CI: which CI platform (GitHub Actions, GitLab, etc.)

## Procedure

### 0) Install GPC

**Via npm (recommended):**
```bash
npm install -g @gpc-cli/cli
```

**Via npx (zero-install trial):**
```bash
npx @gpc-cli/cli --version
```

**Via standalone binary (no Node.js needed):**
```bash
curl -fsSL https://raw.githubusercontent.com/yasserstudio/gpc/main/scripts/install.sh | bash
```

### 1) Authenticate

Three auth strategies, in order of recommendation:

#### A) Service Account (recommended for CI/CD)

1. Create a service account in Google Cloud Console
2. Grant it access in Google Play Console (Settings → API access)
3. Download the JSON key file

```bash
gpc auth login --service-account path/to/key.json
```

Or via environment variable (preferred in CI):
```bash
export GPC_SERVICE_ACCOUNT=path/to/key.json
# or inline JSON:
export GPC_SERVICE_ACCOUNT='{"type":"service_account","project_id":"..."}'
```

Read:
- `references/service-account.md`

#### B) OAuth (for local development)

Interactive OAuth device flow — no key file needed:

```bash
gpc auth login
```

Tokens are cached in the OS keychain (macOS Keychain, Linux libsecret) or file fallback.

#### C) Application Default Credentials (for GCP environments)

Works automatically in Cloud Build, Cloud Run, GKE — no configuration needed:

```bash
# ADC is auto-detected when no other auth is configured
gpc apps list
```

### 2) Configure defaults

#### Interactive setup:
```bash
gpc config init
```

Prompts for package name, output format, and service account path.

#### Manual config file (`.gpcrc.json` in project root or `~/.config/gpc/config.json`):
```json
{
  "app": "com.example.myapp",
  "output": "table",
  "profile": "default"
}
```

#### Environment variables:
| Variable | Description |
|----------|-------------|
| `GPC_APP` | Default package name |
| `GPC_OUTPUT` | Default output format (table/json/yaml/markdown) |
| `GPC_PROFILE` | Auth profile name |
| `GPC_NO_COLOR` | Disable color output |
| `GPC_NO_INTERACTIVE` | Disable interactive prompts |
| `GPC_SKIP_KEYCHAIN` | Skip OS keychain, use file storage |

Read:
- `references/configuration.md`

### 3) Manage auth profiles

For managing multiple Google Play accounts:

```bash
gpc auth profiles              # List profiles
gpc auth switch production     # Switch active profile
gpc auth whoami                # Show current identity
gpc auth status                # Show auth state details
```

Use `--profile` flag to override per-command:
```bash
gpc apps list --profile staging
```

### 4) Verify setup

```bash
gpc doctor
```

Checks:
- Node.js version
- Configuration loaded
- Default app set
- Authentication valid
- API connectivity

### 5) Network configuration (if needed)

For corporate proxies or custom CA certificates:

```bash
export HTTPS_PROXY=http://proxy.example.com:8080
export GPC_CA_CERT=/path/to/ca-bundle.crt
```

Retry configuration:
```bash
export GPC_MAX_RETRIES=3
export GPC_TIMEOUT=30000
export GPC_BASE_DELAY=1000
export GPC_MAX_DELAY=60000
```

## Verification

- `gpc doctor` shows all checks passing
- `gpc auth status` shows authenticated identity
- `gpc apps list` returns real app data
- `gpc config show` displays resolved configuration

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `AUTH_EXPIRED` | Access token expired | `gpc auth login` to re-authenticate |
| `AUTH_INVALID` | Wrong service account or missing permissions | Check Google Play Console → Settings → API access |
| `NETWORK_ERROR` | Proxy or firewall blocking | Set `HTTPS_PROXY` and/or `GPC_CA_CERT` |
| `CONFIG_NOT_FOUND` | No config file | Run `gpc config init` or set `GPC_APP` env var |
| Doctor fails on "API connectivity" | Service account not granted Play Console access | Add service account in Play Console API access settings |

Read:
- `references/troubleshooting.md`

## Escalation

- For Google Play Console API access setup, refer to: https://developers.google.com/android-publisher/getting_started
- For service account creation, refer to: https://cloud.google.com/iam/docs/service-accounts-create
