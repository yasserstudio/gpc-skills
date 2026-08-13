---
name: gpc-security
description: "Use when dealing with GPC credential security, secret management, audit logging, or access control. Make sure to use this skill whenever the user mentions credentials, service account key, secret rotation, key rotation, credential storage, audit log, audit trail, security best practices, .gpcrc.json security, secrets in CI, GPC_SERVICE_ACCOUNT safety, keychain, token cache, credential leak, key compromise, secure deployment — even if they don't explicitly say 'security.' Also trigger when someone asks about where GPC stores credentials, how to rotate service account keys, how to audit who did what with GPC, how to securely pass credentials in CI/CD, or how to handle a compromised service account key. For auth setup, see gpc-setup. For CI configuration, see gpc-ci-integration."
compatibility: "GPC v0.9.82+. Covers credential storage, audit logging, supply chain hardening, and security patterns across all packages."
metadata:
  version: 0.15.0
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
cat ~/.config/gpc/audit.log | jq 'select(.timestamp >= "2025-03-01")'
```

#### Audit entry structure

```json
{
  "timestamp": "2025-03-09T14:30:00.000Z",
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
- Webhook payloads are redacted via `redactSensitive()` before dispatch to Slack/Discord/custom endpoints (v0.9.80+)
- Auth error messages redact long inputs that look like pasted credentials (v0.9.80+)
- ADC token cache uses hash-based keys per credential source to prevent multi-account confusion (v0.9.80+)
- Project `.gpcrc.json` cannot self-approve plugins -- `approvedPlugins` is only trusted from user config (v0.9.80+)

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
# npm publish: OIDC via Trusted Publisher (v0.9.77+, no stored NPM_TOKEN)
permissions:
  id-token: write  # Required for OIDC token exchange with npm

# Google Play service account: encrypted secret
env:
  GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}

# Restrict to specific branches
if: github.ref == 'refs/heads/main'

# Use environments for approval gates (staged publishing uses this)
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

### 8. Supply chain protection (v0.9.77+)

GPC uses 15 layers of defense against dependency and publish supply chain attacks:

| Layer | What it does |
|-------|-------------|
| Trusted Publisher (OIDC) | npm publish authenticates via GitHub OIDC -- no long-lived NPM_TOKEN stored anywhere |
| Staged Publishing | CI stages packages; maintainer approves with 2FA before they go live on npm |
| NPM_TOKEN deleted | No stored npm token in GitHub secrets -- OIDC is the only auth path |
| `min-release-age=7` in `.npmrc` | Blocks packages published less than 7 days ago |
| `pnpm-lock.yaml` | Exact version pinning, no unexpected upgrades |
| Socket.dev CI scan | `socket ci` on every PR, blocks on critical alerts |
| Socket.dev GitHub App | Inline PR comments on risky dependency changes |
| `pnpm audit` in CI | Gates PRs on high-severity CVEs (production deps) |
| GitHub Actions SHA pins | All 14 action refs pinned to commit hashes, not mutable tags |
| SBOM (CycloneDX) | Bill of materials generated and archived on every npm release |
| CODEOWNERS | Security-sensitive paths require explicit review |
| Dependabot | Weekly update PRs (direct dependencies only, actions grouped) |
| Socket CLI wrapper | Scans every local `npm install` and `npx` |
| CodeQL | Static analysis on every push |
| GitHub secret scanning | Blocks pushes containing 200+ secret patterns |

GPC only has 4 runtime dependencies: `google-auth-library`, `commander`, `protobufjs`, `yauzl`. All API calls use Node.js built-in `fetch`.

Configuration: `socket.yml` at repo root controls Socket.dev alert rules. `.npmrc` controls `min-release-age`. `.github/CODEOWNERS` controls review requirements. Release workflow uses `pnpm release-staged` with OIDC authentication.

### 9. Security audit posture (v0.9.80 + v0.9.82)

**v0.9.80 deepsec re-scan**: A full-codebase deepsec audit was run after the v0.9.80 security fixes. Result: 0 new findings. All previously tracked findings from the v0.9.74 audit were resolved.

**Webhook redaction (v0.9.80)**: Webhook payloads dispatched to Slack, Discord, and custom endpoints via `--webhook-url` are now redacted before dispatch. Sensitive fields are stripped from the payload before it leaves the process. This applies to all `gpc watch` breach events and any other webhook dispatch paths.

**google-auth-library bump (v0.9.82)**: `google-auth-library` was upgraded to 10.7.0. This clears the only remaining tracked production audit finding: a `brace-expansion` transitive vulnerability. GPC now has zero production audit findings.

### 9a. GPC GitHub Action security

The GPC GitHub Action (`yasserstudio/gpc-action`) is a TypeScript action running on Node 24 with the following security properties:

- **OIDC auth**: The action authenticates to Google Play using OIDC token exchange. No long-lived secrets are stored in the action itself.
- **Built-in preflight gate**: The action runs `gpc preflight` before upload. A failing preflight scan blocks the publish step.
- **No stored NPM token**: The action uses Trusted Publisher (OIDC) for any npm operations. No `NPM_TOKEN` is stored in GitHub secrets.
- **Node 24 runtime**: Matches the current GPC CLI CI matrix for consistency.

Usage:
```yaml
- uses: yasserstudio/gpc-action@v1
  with:
    service-account: ${{ secrets.PLAY_SA_KEY }}
    package-name: com.example.app
    aab: app/build/outputs/bundle/release/app-release.aab
    track: beta
```

### 10. Developer verification

Google's Android developer verification enforcement begins September 2026 (BR, ID, SG, TH):

```bash
gpc verify              # Status, deadlines, resources
gpc verify --open       # Open verification page in browser
gpc verify --json       # Machine-readable output
```

`gpc doctor` includes a verification check. `gpc status` shows a footer reminder. `gpc preflight` shows a post-scan reminder.

### 11. Signing key verification (v0.9.75+)

Verify your local signing key matches the Play signing certificate:

```bash
gpc doctor --verify                                              # Show Play cert fingerprint
gpc doctor --verify --keystore release.keystore --store-pass $PW  # Compare local vs Play
```

If fingerprints don't match, you're distributing with a different key than Play uses. Register it in Play Console to avoid installation blocks after September 30, 2026.

## Verification

- `gpc auth status` shows the expected service account email
- `gpc doctor` passes all checks
- `.gpcrc.json` contains no secrets or key paths
- Audit log at `~/.config/gpc/audit.log` is being written
- CI secrets are encrypted and not visible in logs
- Old keys are deleted after rotation

## Related skills

- **gpc-setup** — initial authentication and configuration
- **gpc-user-management** — managing team access and permissions
- **gpc-ci-integration** — secure CI/CD pipeline configuration
- **gpc-troubleshooting** — debugging auth errors
