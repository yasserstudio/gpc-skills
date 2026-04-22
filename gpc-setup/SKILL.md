---
name: gpc-setup
description: "Use when setting up GPC (Google Play Console CLI): authentication with service accounts, OAuth, or Application Default Credentials; configuration files (.gpcrc.json, env vars, XDG paths); auth profiles; running gpc doctor; troubleshooting auth errors. Make sure to use this skill whenever the user mentions gpc auth, service account setup, gpc config, gpc doctor, GPC_SERVICE_ACCOUNT, gpc auth login, Google Play API credentials, Play Console authentication, or wants to install/configure GPC — even if they don't explicitly say 'setup.' Also trigger when someone is troubleshooting auth failures, token expiration, keychain issues, or proxy/network configuration for GPC."
compatibility: "GPC v0.9+. Requires Node.js 20+, pnpm 9+ (for development). npm for installation."
metadata:
  version: 1.3.0
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

**New to Google Cloud or setting up for the first time?** Use the interactive GCP setup guide:

```bash
gpc auth setup-gcp
```

This fully interactive wizard walks through every step required to connect GPC to the Play Developer API:

1. Enabling the Google Play Developer API in your GCP project
2. Creating a service account in the GCP Console
3. Granting the service account access in Google Play Console (Settings → API access)
4. Downloading the JSON key file to your machine
5. Running `gpc auth login` with the downloaded key

No flags needed -- just run the command and follow the prompts. Ideal for first-time setup on any machine.

**Already have a key file?** Skip the wizard with `--key`:

```bash
gpc auth setup-gcp --key /path/to/service-account.json
```

This validates the JSON, authenticates, and saves to config in one step.

Once the wizard completes, or if you already have a key file:

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

#### Interactive setup wizard:
```bash
gpc config init
```

Guided wizard that:
1. Selects auth method (`service-account` / `adc` / `skip`)
2. For service account: validates the file exists (retries if path is wrong)
3. Prompts for default package name (warns if format is invalid)
4. Writes `.gpcrc.json` and prints a post-init summary
5. Ends with: `Run \`gpc doctor\` to verify your setup.`

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

Checks (20 total):
- Node.js version (≥ 20)
- Configuration loaded
- Default app set and valid Android package name format
- Authentication valid
- API connectivity (googleapis.com + playdeveloperreporting.googleapis.com)
- Proxy configuration (if set)
- GPC version (suggests update if outdated)
- HTTPS probe
- App access verification
- Service account key age
- Unknown config keys
- Token cache health
- Disk space
- CI detection
- Developer verification status

Use `gpc doctor --fix` to auto-remediate fixable issues (version, auth, config keys).

JSON output is supported: `gpc doctor --json` or `gpc doctor --output json`.

### 5a) Check developer verification

```bash
gpc verify              # Status, deadlines, resources
gpc verify --open       # Open verification page in browser
```

Google's Android developer verification enforcement begins September 2026 for BR, ID, SG, TH. `gpc doctor` includes this as check #20.

### 5b) Browse documentation from CLI (v0.9.64+ embedded docs)

Since v0.9.64, GPC ships 99 documentation pages embedded in the binary. No network required.

```bash
gpc docs list                     # List all 99 embedded topics
gpc docs show authentication      # Render a guide in the terminal (ANSI-formatted)
gpc docs show auth                # Fuzzy slug matching
gpc docs search "staged rollout"  # Full-text search across all pages
gpc docs init                     # Write GPC.md quick-reference into repo (for AI agents)
gpc docs web                      # Open docs site in browser (previous default behavior)
```

`gpc docs show` pipes through `$PAGER` for long pages. `gpc docs list --json` and `gpc docs search --json` for machine-readable output.

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

## Shell completion (v0.9.58+ walker, v0.9.60+ dynamic values)

GPC ships shell completion for bash, zsh, fish, and PowerShell. The completion tree is introspection-based (v0.9.58+) -- new commands and plugin-registered commands auto-complete without generator edits. Flags declared with `.choices()` surface their candidate list at TAB time.

```bash
# One-time setup (macOS/Linux)
gpc completion bash >> ~/.bash_completion      # or source in ~/.bashrc
gpc completion zsh  >> ~/.zshrc
gpc completion fish > ~/.config/fish/completions/gpc.fish

# Homebrew auto-installs completion files -- no eval step needed
brew install yasserstudio/tap/gpc
```

### Dynamic values (v0.9.60+)

The completion scripts fill in live values for several flags at TAB time, backed by a hidden `gpc __complete <ctx>` subcommand. No API call -- reads your config and `~/.cache/gpc/status-*.json` cache, returns in under 150ms cold.

| Flag            | Source                                                        |
|-----------------|---------------------------------------------------------------|
| `--profile`     | Profile names from `~/.config/gpc/config.json`                |
| `--app` / `--apps` | Package names from config + status cache                   |
| `--track`       | Track names for the current app (from status cache)           |

If your package/track completions are stale, run any command that touches `gpc status` (or `gpc status` directly) to refresh the cache.

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
