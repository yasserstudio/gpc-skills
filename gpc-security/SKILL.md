---
name: gpc-security
description: "Use when dealing with GPC credential security, secret management, audit logging, or access control. Make sure to use this skill whenever the user mentions credentials, service account key, secret rotation, key rotation, credential storage, audit log, audit trail, security best practices, .gpcrc.json security, secrets in CI, GPC_SERVICE_ACCOUNT safety, keychain, token cache, credential leak, key compromise, secure deployment — even if they don't explicitly say 'security.' Also trigger when someone asks about where GPC stores credentials, how to rotate service account keys, how to audit who did what with GPC, how to securely pass credentials in CI/CD, or how to handle a compromised service account key. For auth setup, see gpc-setup. For CI configuration, see gpc-ci-integration."
compatibility: "GPC v0.9.9+. Covers credential storage, audit logging, and security patterns across all packages."
metadata:
  version: 1.0.0
---

# gpc-security

Credential management, audit logging, and security best practices for GPC.

## When to use

- Securing service account keys and credentials
- Setting up credential rotation
- Reviewing audit logs for compliance
- Handling a compromised service account key
- Securing GPC in CI/CD pipelines
- Understanding where GPC stores sensitive data

## Inputs required

- **GPC installed and authenticated** — `gpc auth status`
- **Service account key files** — for rotation procedures
- **CI/CD platform access** — for updating secrets

## Procedure

### 0. Credential storage locations

GPC stores credentials in platform-appropriate secure locations:

| Data | Location | Security |
|------|----------|----------|
| OAuth tokens | OS keychain (macOS/Linux/Windows) | OS-managed encryption |
| Token cache | `~/.cache/gpc/tokens/` | File permissions (0600) |
| User config | `~/.config/gpc/config.json` | File permissions |
| Project config | `.gpcrc.json` | Version-controlled (no secrets!) |
| Audit log | `~/.config/gpc/audit.log` | JSON Lines, append-only |

**XDG overrides:** `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`

`Read:` `references/credential-storage.md` for detailed storage architecture and security model.

### 1. Service account key security

#### Never commit keys to git

```bash
# .gitignore
*.json.key
*-sa.json
service-account*.json
play-store-key.json
```

#### Use environment variables in CI

```yaml
# GitHub Actions — key stored as secret
env:
  GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
```

Never store keys in:
- `.gpcrc.json` (version-controlled)
- Dockerfiles or docker-compose files
- Shell scripts committed to git
- CI config files (even if they seem private)

### 2. Key rotation

Rotate service account keys periodically (recommended: every 90 days).

```bash
# 1. Create new key in Google Cloud Console
# IAM & Admin → Service Accounts → Keys → Add Key

# 2. Test new key locally
gpc auth login --service-account /path/to/new-key.json
gpc doctor

# 3. Update CI secrets with new key
# GitHub: Settings → Secrets → PLAY_SA_KEY → Update
# GitLab: Settings → CI/CD → Variables → PLAY_SA_KEY → Update

# 4. Verify CI works with new key
# Trigger a test pipeline

# 5. Delete old key in Google Cloud Console
# IAM & Admin → Service Accounts → Keys → Delete old key

# 6. Clear local token cache
rm -rf ~/.cache/gpc/tokens/
```

`Read:` `references/key-rotation.md` for automated rotation patterns and multi-environment strategies.

### 3. Audit logging

GPC logs all commands to `~/.config/gpc/audit.log` in JSON Lines format:

```bash
# View recent audit entries
tail -20 ~/.config/gpc/audit.log | jq .

# Filter by command
cat ~/.config/gpc/audit.log | jq 'select(.command == "releases upload")'

# Filter by app
cat ~/.config/gpc/audit.log | jq 'select(.app == "com.example.app")'

# Filter failures
cat ~/.config/gpc/audit.log | jq 'select(.success == false)'

# Filter by date range
cat ~/.config/gpc/audit.log | jq 'select(.timestamp >= "2026-03-01")'
```

#### Audit entry structure

```json
{
  "timestamp": "2026-03-09T14:30:00.000Z",
  "command": "releases upload",
  "app": "com.example.app",
  "args": { "track": "beta", "file": "app-release.aab" },
  "user": "sa@project.iam.gserviceaccount.com",
  "success": true,
  "durationMs": 12340
}
```

### 4. Secrets redaction

GPC automatically redacts sensitive data in all output:

- Service account JSON content is never logged
- Access tokens are never shown in verbose output
- Private keys are never included in error messages
- `--json` output redacts credential fields

### 5. Least-privilege permissions

Grant only the permissions each service account needs:

#### Upload-only service account

Play Console permissions:
- View app information
- Manage testing (for internal/alpha/beta)
- Release to production (only if needed)

#### Read-only monitoring service account

Play Console permissions:
- View app information
- View financial data (for reports)

```bash
# Verify what a service account can do
gpc auth status --json | jq '.email'
# Then check that email's permissions in Play Console
```

### 6. Handling compromised keys

If a service account key is leaked:

```bash
# 1. IMMEDIATELY delete the compromised key in Google Cloud Console
# IAM & Admin → Service Accounts → Keys → Delete

# 2. Create a new key
# Same page → Add Key → JSON

# 3. Update all locations using the key
gpc auth login --service-account /path/to/new-key.json

# 4. Update CI secrets
# All platforms using the old key

# 5. Clear token cache
rm -rf ~/.cache/gpc/tokens/

# 6. Review audit log for unauthorized actions
cat ~/.config/gpc/audit.log | jq 'select(.timestamp >= "LEAK_DATE")'

# 7. Review Google Cloud audit logs
# Cloud Console → IAM & Admin → Audit Logs
```

### 7. CI/CD security patterns

#### GitHub Actions

```yaml
# Use OIDC for keyless auth (advanced)
# Or encrypted secrets (standard)
env:
  GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}

# Restrict to specific branches
if: github.ref == 'refs/heads/main'

# Use environments for approval gates
environment: production
```

#### Secret scanning

```bash
# Check if keys are in git history
git log --all --full-history -p -- '*.json' | grep -l '"private_key"'

# If found, rotate immediately and clean git history
```

## Verification

- `gpc auth status` shows the expected service account email
- `gpc doctor` passes all checks
- `.gpcrc.json` contains no secrets or key paths
- Audit log at `~/.config/gpc/audit.log` is being written
- CI secrets are encrypted and not visible in logs
- Old keys are deleted after rotation

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Key file committed to git | Not in .gitignore | Add to .gitignore; rotate key immediately |
| Token cache stale after rotation | Old cached tokens | Delete `~/.cache/gpc/tokens/` |
| Audit log not writing | Config dir not writable | Check permissions on `~/.config/gpc/` |
| Service account email unknown | Key not inspected | `gpc auth status --json \| jq '.email'` |
| CI shows credential in logs | Key passed as argument | Use environment variables, never CLI args |
| Keychain prompt every command | macOS keychain access not granted | Click "Always Allow" on the prompt |

## Related skills

- **gpc-setup** — initial authentication and configuration
- **gpc-user-management** — managing team access and permissions
- **gpc-ci-integration** — secure CI/CD pipeline configuration
- **gpc-troubleshooting** — debugging auth errors
