---
name: gpc-security
description: "Use when dealing with GPC credential security, secret management, audit logging, access control, or runtime security hardening. Trigger whenever the user mentions credentials, service account key, secret rotation, key rotation, credential storage, audit log, audit trail, security best practices, .gpcrc.json security, secrets in CI, GPC_SERVICE_ACCOUNT safety, keychain, token cache, credential leak, key compromise, secure deployment, plugin trust, SSRF, path traversal, symlink, supply chain, deepsec, redactPath, formula injection, prompt injection, env allowlist — even if they don't explicitly say 'security.' Also trigger when someone asks about where GPC stores credentials, how to rotate service account keys, how to audit who did what with GPC, how to securely pass credentials in CI/CD, how to handle a compromised service account key, or how to run a security audit with deepsec. For auth setup, see gpc-setup. For CI configuration, see gpc-ci-integration."
compatibility: "GPC v0.9+. Covers credential storage, audit logging, and security hardening across all packages. Supply chain hardening and deepsec scanning added in v0.9.74."
metadata:
  version: 0.14.0
---

# gpc-security

Credential management, audit logging, and security hardening for GPC.

## When to use

- Securing service account keys and credentials
- Setting up credential rotation
- Reviewing audit logs for compliance
- Handling a compromised service account key
- Securing GPC in CI/CD pipelines
- Understanding where GPC stores sensitive data
- Investigating a security finding or running a deepsec audit
- Understanding GPC's runtime security model (plugin trust, SSRF mitigations, redaction)

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
| Project config | `.gpcrc.json` | Version-controlled (no secrets) |
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
# GitHub Actions — key stored as secret, scoped to the step that needs it
steps:
  - name: Upload AAB
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
    run: gpc releases upload --app com.example.app --file app.aab
```

Scoping secrets to the step (not the job) is the v0.9.74 CI template convention. It limits the blast radius if a step is compromised.

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

GPC automatically redacts sensitive data in all output. Several redaction layers apply:

#### `redactPath()` — HTTP error messages (api/src/http.ts)

All HTTP error paths pass through `redactPath()` before being shown or logged. It strips sensitive URL segments matching `/tokens/`, `/purchases/`, and `/purchaseToken/`:

```
/purchases/products/purchaseToken/abc123...
  becomes:
/purchases/products/purchaseToken/***REDACTED***
```

This applies globally to all API error messages, timeout messages, and `--json` error output.

#### RTDN purchase token redaction (core/src/commands/rtdn.ts)

Decoded RTDN notification payloads truncate `purchaseToken` to the first 16 characters followed by `...`. The full token is never surfaced in output.

#### Webhook argv filtering (core/src/utils/webhooks.ts)

When GPC dispatches webhook notifications, sensitive flags are stripped from the `argv` field of the payload before it is sent.

#### Config set — key name only

`gpc config set <key> <value>` confirms the key name was written but does not echo the value back to stdout.

#### Doctor — proxy URL sanitization

`gpc doctor` validates `HTTPS_PROXY`/`HTTP_PROXY` but strips credentials from the display. Only `protocol + host + pathname` are shown:

```
Proxy configured: http://proxy.corp.example.com:8080
```
(username/password from `http://user:pass@proxy:8080` are dropped)

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

#### GitHub Actions (v0.9.74 template)

Scope secrets to the step level, not the job level:

```yaml
# Step-scoped secrets — v0.9.74 pattern
steps:
  - name: Upload to Play Store
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
    run: gpc releases upload --app com.example.app --file app.aab --track beta

  - name: Promote to production
    env:
      GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}
    run: gpc releases promote --app com.example.app --from beta --to production
```

Job-level `env:` blocks expose the secret to every step in the job, including any compromised third-party actions. Step-level `env:` limits exposure to exactly the steps that need it.

#### Secret scanning

```bash
# Check if keys are in git history
git log --all --full-history -p -- '*.json' | grep -l '"private_key"'

# If found, rotate immediately and clean git history
```

### 8. Supply chain hardening

GPC uses layered defense against dependency supply chain attacks (hardened in v0.9.74):

| Layer | What it does |
|-------|-------------|
| `min-release-age=7` in `.npmrc` | Blocks packages published less than 7 days ago |
| `pnpm.onlyBuiltDependencies: ["turbo","esbuild"]` | All other install hooks are blocked by default |
| `--frozen-lockfile --ignore-scripts` in CI | Prevents unexpected hook execution during install |
| `pnpm-lock.yaml` | Exact version pinning, no unexpected upgrades |
| Socket.dev CI scan | `socket ci` on every PR, blocks on critical alerts |
| Socket.dev GitHub App | Inline PR comments on risky dependency changes |
| `pnpm audit` in CI | Gates PRs on high-severity CVEs (production deps) |
| GitHub Actions SHA pins | All action refs pinned to commit hashes, not mutable tags |
| SBOM (CycloneDX) | Bill of materials generated and archived on every npm release |
| CODEOWNERS | Security-sensitive paths require explicit review |
| Dependabot | Weekly update PRs (direct dependencies only, actions grouped) |
| deepsec CI scan | Vercel Labs AI security scanner runs on every push (see Section 10) |
| CodeQL | Static analysis on every push |
| GitHub secret scanning | Blocks pushes containing 200+ secret patterns |

GPC only has 4 runtime dependencies: `google-auth-library`, `commander`, `protobufjs`, `yauzl`. All API calls use Node.js built-in `fetch`.

`pnpm.onlyBuiltDependencies` is in `package.json` at the repo root. It explicitly whitelists `turbo` and `esbuild` as the only packages allowed to run install hooks. Every other transitive dependency's `preinstall`/`install`/`postinstall` lifecycle scripts are blocked.

### 9. Runtime security hardening (v0.9.74)

These mitigations were added in v0.9.74 as fixes for findings from the deepsec audit.

`Read:` `references/runtime-security.md` for the full threat model, code locations, and remediation notes for each finding.

#### Plugin RCE prevention — `isPluginTrusted()` (core/src/plugins.ts)

`import()` is never called on an untrusted plugin specifier. `isPluginTrusted(specifier, approved)` is checked first. Only first-party plugins (`FIRST_PARTY_PLUGINS` set) or explicitly user-approved plugins pass. Untrusted specifiers are skipped before any module loading, preventing top-level module code execution.

#### Resumable upload SSRF — `validateSessionUri()` (api/src/resumable-upload.ts)

Before following a redirect to a session URI returned by the Google API, `validateSessionUri(sessionUri, uploadUrl)` validates that the session URI's hostname either matches the original upload hostname or ends with `.googleapis.com`. A mismatch throws immediately, preventing SSRF via a crafted redirect.

#### Symlink traversal — `lstat()` checks (core/src/utils/release-notes.ts)

When reading `--notes-dir` for release note files, `lstat()` is called on each entry before `readFile()`. If `stats.isSymbolicLink()` returns `true`, the entry is rejected. This prevents a crafted notes directory from reading arbitrary files on the developer's machine via symlinks.

#### API path encoding — `p()` helper (api/src/client.ts)

All path parameters in API URLs are wrapped with the `p()` helper:

```typescript
const p = (segment: string): string => encodeURIComponent(segment);

// Every path parameter uses p():
`/androidpublisher/v3/applications/${p(packageName)}/edits/${p(editId)}/tracks/${p(track)}`
```

`p()` is a single-character alias for `encodeURIComponent`. Using it consistently on every user-supplied path segment prevents path injection via package names, edit IDs, or other values that could contain `/`, `?`, or `#`.

#### HTTP error path sanitization — `redactPath()` (api/src/http.ts)

`redactPath()` uses a global regex to strip purchase tokens and other sensitive values from URL paths before they appear in error messages. The regex matches `/(tokens|purchases|purchaseToken)/<value>` and replaces the value with `***REDACTED***`. Applied to all error, timeout, and network failure messages.

#### Rate limiter mutex — per-bucket promise chain (api/src/rate-limiter.ts)

The rate limiter maintains a per-bucket promise-chain mutex. Each bucket chains its acquire call onto the previous one, ensuring only one concurrent acquire runs per bucket at a time. This prevents burst races where multiple parallel commands could collectively exceed per-minute quota.

#### CSV formula injection prevention (reports/CSV export)

CSV field values that could be interpreted as spreadsheet formulas (starting with `=`, `+`, `-`, `@`) are prefixed with a single quote `'` before being written. This prevents Excel/Sheets formula injection when users open exported CSV files.

#### AI changelog — prompt injection hardening (core, changelog generation)

User-supplied commit messages, file paths, and app metadata are wrapped in XML boundary tags before being interpolated into AI prompts. This prevents injected instructions in commit messages from escaping their content role in the prompt.

#### Vitals gate ordering (core, vitals/rollout commands)

Crash/ANR thresholds are checked before a rollout increase is written. Previously, the rollout could increment and then fail the gate check, leaving the rollout at a higher percentage. Now the gate exits (code 6) before mutating rollout state.

#### Image upload/delete respects `--dry-run` (core/src/commands/image-sync.ts, listings.ts)

`--dry-run` is now checked before the upload and delete API calls in the image sync path. Previously only the commit step was guarded; upload and delete mutations could run even in dry-run mode.

### 10. Deepsec audit process

GPC uses deepsec (Vercel Labs AI security scanner) as a continuous audit tool.

#### Running a local scan

```bash
# Full scan, process, revalidate, and export
pnpm security:deep

# Or run individual steps
npx deepsec scan
npx deepsec process
npx deepsec revalidate
npx deepsec export --format md-dir --out ./deepsec-findings
```

`deepsec-findings/` is gitignored. Results are exported as structured markdown per finding.

#### CI integration

deepsec runs as a separate CI job (`deepsec:`) on every push. Results are uploaded as a `deepsec-findings` artifact. The job does not gate the build (findings require human triage), but the artifact is archived for each run.

```yaml
# ci.yml — deepsec job
deepsec:
  steps:
    - run: pnpm install --frozen-lockfile --ignore-scripts
    - run: |
        npx deepsec scan
        npx deepsec process
        npx deepsec revalidate
        npx deepsec export --format json --out deepsec-results.json
    - uses: actions/upload-artifact@...
      with:
        name: deepsec-findings
        path: deepsec-results.json
```

#### Triage workflow

1. Review exported findings from `deepsec-findings/` or the CI artifact.
2. For each finding: assess severity, identify the code location, apply a fix.
3. Re-run `npx deepsec revalidate` to confirm the finding is resolved.
4. Commit the fix with a `fix(security):` commit message referencing the finding.

The v0.9.74 release resolved 16 findings from an initial deepsec audit. `references/runtime-security.md` documents each finding and the fix applied.

### 11. Developer verification

Google's Android developer verification enforcement begins September 30, 2026 (BR, ID, SG, TH):

```bash
gpc verify              # Account-aware status with app info, signing enrollment, days until enforcement
gpc verify --open       # Open verification page in browser
gpc verify --json       # Machine-readable output
gpc verify checklist    # Interactive 7-step readiness walkthrough
```

`gpc doctor` includes a verification check. `gpc status` shows a footer reminder. `gpc preflight` shows a post-scan reminder.

#### Signing key audit (v0.9.66+)

```bash
gpc doctor --verify                                       # API-side signing cert
gpc doctor --verify --keystore release.jks --store-pass x # Compare local vs API cert
gpc preflight signing                                     # Cert consistency across releases
```

`gpc doctor --verify` retrieves the signing certificate from Google Play via `generatedApks` and optionally compares it against a local keystore (via `keytool`). `gpc preflight signing` compares certs across the two most recent bundle versions (exit 6 on mismatch). Both complement the verification workflow by ensuring signing keys are correct before enforcement.

## Verification

- `gpc auth status` shows the expected service account email
- `gpc doctor` passes all checks
- `.gpcrc.json` contains no secrets or key paths
- Audit log at `~/.config/gpc/audit.log` is being written
- CI secrets are encrypted, not visible in logs, and scoped to steps
- Old keys are deleted after rotation
- `pnpm security:deep` produces no unreviewed critical findings

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Key file committed to git | Not in .gitignore | Add to .gitignore; rotate key immediately |
| Token cache stale after rotation | Old cached tokens | Delete `~/.cache/gpc/tokens/` |
| Audit log not writing | Config dir not writable | Check permissions on `~/.config/gpc/` |
| Service account email unknown | Key not inspected | `gpc auth status --json \| jq '.email'` |
| CI shows credential in logs | Key passed as argument | Use environment variables, never CLI args |
| Keychain prompt every command | macOS keychain access not granted | Click "Always Allow" on the prompt |
| Plugin not loading after update | Plugin not in approved list | Re-run `gpc plugins add <name>` to re-approve |
| Resumable upload rejected with SSRF error | Session URI returned from API has unexpected host | Check proxy/network config; report to GPC if reproducible |
| deepsec scan failing in CI | npx cache issue or network | Check `deepsec-findings` artifact; run `npx deepsec scan` locally |

## Related skills

- **gpc-setup** — initial authentication and configuration
- **gpc-user-management** — managing team access and permissions
- **gpc-ci-integration** — secure CI/CD pipeline configuration
- **gpc-troubleshooting** — debugging auth errors
- **gpc-plugin-development** — plugin trust model, permissions
