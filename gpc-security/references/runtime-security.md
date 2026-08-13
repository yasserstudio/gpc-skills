# Runtime Security Hardening

GPC v0.9.74 resolved 16 findings from a deepsec (Vercel Labs AI security scanner) audit. This document covers the threat model, code location, and fix for each finding, plus design conventions that apply across the codebase.

## Design conventions

### `p()` helper — URL path encoding

**File:** `packages/api/src/client.ts`

```typescript
const p = (segment: string): string => encodeURIComponent(segment);
```

Every user-supplied path segment in an API URL must be wrapped with `p()`. This is a codebase-wide convention introduced in v0.9.74.

```typescript
// Correct
`/applications/${p(packageName)}/edits/${p(editId)}/tracks/${p(track)}`

// Wrong — do not do this
`/applications/${packageName}/edits/${editId}/tracks/${track}`
```

Without `p()`, a package name containing `/`, `?`, or `#` could alter the URL structure and target unintended API endpoints.

### `redactPath()` — HTTP error message sanitization

**File:** `packages/api/src/http.ts`

```typescript
const SENSITIVE_PATH_SEGMENTS = /\/(tokens|purchases|purchaseToken)\/([^/?#]*)/gi;

function redactPath(path: string): string {
  return path.replace(SENSITIVE_PATH_SEGMENTS, (_match, segment: string) => {
    return `/${segment}/***REDACTED***`;
  });
}
```

`redactPath()` is called on every path before it appears in an error message, timeout message, or `--json` error output. This is applied globally at the HTTP client layer — individual commands do not need their own redaction logic for URL paths.

### Env allowlist — subprocess spawning

**File:** `packages/cli/src/commands/install-skills.ts`

When spawning a subprocess (e.g., `npx skills add`), GPC builds an explicit `safeEnv` object rather than passing through `process.env`. Only these keys are forwarded:

```
PATH, HOME, USER, SHELL, TMPDIR, LANG, LC_ALL,
NODE_ENV, NODE_PATH, NODE_OPTIONS, NODE_EXTRA_CA_CERTS,
npm_config_registry, npm_config_cache,
HTTPS_PROXY, HTTP_PROXY, NO_PROXY,
https_proxy, http_proxy, no_proxy
```

This prevents the subprocess from inheriting sensitive variables (`GPC_SERVICE_ACCOUNT`, `GOOGLE_APPLICATION_CREDENTIALS`, CI tokens, etc.) that happen to be set in the parent environment.

Pattern for new subprocess calls:

```typescript
const allowedEnvKeys = new Set(["PATH", "HOME", /* ... */]);
const safeEnv: Record<string, string> = {};
for (const [k, v] of Object.entries(process.env)) {
  if (v !== undefined && allowedEnvKeys.has(k)) {
    safeEnv[k] = v;
  }
}
execFileSync("npx", args, { env: safeEnv });
```

## Finding catalog (v0.9.74)

### F-01: Plugin RCE via untrusted `import()`

**Severity:** Critical
**File:** `packages/core/src/plugins.ts`
**Threat:** A plugin specifier pointing to a malicious local or remote module could execute arbitrary code at import time (top-level module code runs before any exports are inspected).

**Fix:** `isPluginTrusted(specifier, approved)` is called before every `import()`. Only specifiers in the `FIRST_PARTY_PLUGINS` set or in the user's approved set are loaded. Untrusted specifiers are skipped entirely.

```typescript
function isPluginTrusted(specifier: string, approved?: Set<string>): boolean { ... }

// In the plugin loader loop:
if (!isPluginTrusted(name, approved)) continue;
const mod = await import(name);
```

**Guidance:** Never call `import()` on a user-supplied or config-supplied value without passing it through `isPluginTrusted()` first.

---

### F-02: SSRF via crafted resumable upload session URI

**Severity:** High
**File:** `packages/api/src/resumable-upload.ts`
**Threat:** The Google API returns a `Location` header with the resumable upload session URI. A compromised or MITM'd response could return a URI pointing to an internal service (e.g., `http://169.254.169.254/...`).

**Fix:** `validateSessionUri(sessionUri, uploadUrl)` is called before the session URI is used. It parses both URLs and checks that the session URI hostname either matches the original upload hostname or ends with `.googleapis.com`.

```typescript
function validateSessionUri(sessionUri: string, uploadUrl: string): void {
  const session = new URL(sessionUri);
  const upload = new URL(uploadUrl);
  if (session.hostname !== upload.hostname && !session.hostname.endsWith(".googleapis.com")) {
    throw new PlayApiError(`Session URI host "${session.hostname}" does not match ...`);
  }
}
```

---

### F-03: Symlink traversal in `--notes-dir`

**Severity:** High
**File:** `packages/core/src/utils/release-notes.ts`
**Threat:** A crafted notes directory containing symlinks to `/etc/passwd`, `~/.config/gpc/config.json`, or other sensitive files could cause GPC to read and include those files as release notes.

**Fix:** `lstat()` is called on each directory entry before `readFile()`. If `stats.isSymbolicLink()` is true, the entry is skipped.

```typescript
const stats = await lstat(filePath);
if (stats.isSymbolicLink()) continue; // reject symlinks
const content = await readFile(filePath, "utf-8");
```

---

### F-04: Config set echoes sensitive values

**Severity:** Medium
**File:** `packages/cli/src/commands/config.ts`
**Threat:** `gpc config set auth.serviceAccount /path/to/key.json` previously echoed the full value, which could appear in CI logs.

**Fix:** The confirmation message prints the key name only: `Set ${key}`. The value is never echoed.

---

### F-05: Doctor exposes proxy credentials

**Severity:** Medium
**File:** `packages/cli/src/commands/doctor.ts`
**Threat:** If `HTTPS_PROXY=http://user:password@proxy:8080`, the doctor output would show the full URL including credentials.

**Fix:** `checkProxy()` strips credentials before display using `new URL()`: only `protocol + host + pathname` are shown.

```typescript
const safeUrl = `${parsed.protocol}//${parsed.host}${parsed.pathname}`;
```

---

### F-06: Skills installer env passthrough

**Severity:** Medium
**File:** `packages/cli/src/commands/install-skills.ts`
**Threat:** `execFileSync("npx", args, { env: process.env })` would pass `GPC_SERVICE_ACCOUNT`, `GOOGLE_APPLICATION_CREDENTIALS`, and any other secrets to the npx subprocess.

**Fix:** Replaced with an explicit env allowlist (see "Env allowlist" design convention above).

---

### F-07: Vitals gate checks threshold after rollout mutation

**Severity:** Medium
**Files:** `packages/core/` (vitals gate, rollout commands)
**Threat:** The rollout percentage could increment and then fail the crash/ANR gate check, leaving the app at a higher-than-intended rollout with a degraded vitals signal.

**Fix:** Threshold gate evaluation runs before any rollout state is mutated. If the gate fails (exit code 6), the rollout increase is never written.

---

### F-08: Image upload/delete ignores `--dry-run`

**Severity:** Medium
**Files:** `packages/core/src/commands/image-sync.ts`, `packages/core/src/commands/listings.ts`
**Threat:** `--dry-run` was only checked before the final edit commit, not before the individual upload and delete API calls. Images could be mutated even in dry-run mode.

**Fix:** `dryRun` is now checked before each upload and delete call:

```typescript
if (!options?.dryRun) {
  await client.images.upload(...);
}
```

---

### F-09: API paths missing `encodeURIComponent`

**Severity:** Medium
**Files:** Multiple files under `packages/api/src/`
**Threat:** User-supplied values (package names, email addresses, track names) interpolated directly into URL paths could contain characters that alter URL structure.

**Fix:** All path parameters now use the `p()` helper (see design convention above). The fix was applied uniformly across all API client files.

---

### F-10: RTDN exposes full purchase tokens

**Severity:** Medium
**File:** `packages/core/src/commands/rtdn.ts`
**Threat:** Decoded RTDN notification output included full `purchaseToken` values, which are sensitive identifiers that should not appear in logs or CLI output.

**Fix:** Purchase tokens are truncated to the first 16 characters: `n.purchaseToken.slice(0, 16) + "..."`. The full token is never surfaced.

---

### F-11: HTTP errors expose sensitive URL segments

**Severity:** Medium
**File:** `packages/api/src/http.ts`
**Threat:** Error messages, timeout messages, and JSON error output included raw API paths, which could contain purchase tokens, user email fragments, or other sensitive data.

**Fix:** All paths pass through `redactPath()` before appearing in any error output (see design convention above). Applied at the HTTP client layer so every command inherits the protection.

---

### F-12: Webhook payload includes sensitive CLI flags

**Severity:** Medium
**File:** `packages/core/src/utils/webhooks.ts`
**Threat:** The `argv` field in webhook notification payloads could include flags like `--service-account /path/to/key.json` if those flags were present in the process arguments.

**Fix:** Sensitive flags are filtered from `argv` before the payload is constructed. The webhook payload never includes credential-related flags.

---

### F-13: CSV export vulnerable to formula injection

**Severity:** Medium
**Files:** Reports and CSV export commands
**Threat:** If a value from the Play API (e.g., an app name or reviewer text) starts with `=`, `+`, `-`, or `@`, spreadsheet applications treat it as a formula when the CSV is opened.

**Fix:** CSV fields are prefixed with `'` when they start with a formula-triggering character. The apostrophe is interpreted by spreadsheets as a string escape, not rendered as content.

---

### F-14: AI changelog prompt injection

**Severity:** Medium
**Files:** `packages/core/` (changelog generation, AI path)
**Threat:** Commit messages or file paths containing LLM instruction syntax (e.g., `"Ignore previous instructions and..."`) could alter the behavior of the AI prompt.

**Fix:** User-supplied content is wrapped in XML boundary tags before interpolation. The model sees the user content as a clearly bounded data block, not as instructions. This follows the same defense used in the Anthropic documentation for untrusted input.

---

### F-15: Rate limiter bucket race condition

**Severity:** Low
**File:** `packages/api/src/rate-limiter.ts`
**Threat:** Multiple concurrent commands sharing a rate limiter instance could race on the same bucket, allowing combined burst throughput to exceed the per-minute quota limit.

**Fix:** Each bucket uses a promise-chain mutex. Acquire calls chain onto the previous acquire for the same bucket, serializing access within each bucket.

```typescript
const mutexes = new Map<string, Promise<void>>();
// ...
const prev = mutexes.get(bucket) ?? Promise.resolve();
const next = prev.then(() => acquire());
mutexes.set(bucket, next);
```

---

### F-16: CI template exposes secrets at job level

**Severity:** Low
**Files:** `.github/workflows/` CI templates
**Threat:** Defining `env: GPC_SERVICE_ACCOUNT: ${{ secrets.PLAY_SA_KEY }}` at the job level exposes the secret to every step in that job, including any third-party actions.

**Fix:** Secrets are scoped to the individual steps that require them. Each step that calls a GPC command declares its own `env:` block. Steps that do not need the secret cannot access it.

---

## Supply chain additions (v0.9.74)

### `pnpm.onlyBuiltDependencies`

Added to `package.json`:

```json
"pnpm": {
  "onlyBuiltDependencies": ["turbo", "esbuild"]
}
```

All other transitive dependencies are blocked from running install lifecycle hooks. Only `turbo` and `esbuild` (which require native compilation) are whitelisted.

### `--frozen-lockfile --ignore-scripts` in all CI workflows

Every `pnpm install` call in CI now uses both flags. `--frozen-lockfile` prevents lock file drift. `--ignore-scripts` provides a second layer of install hook suppression at the pnpm level, in addition to the `onlyBuiltDependencies` whitelist.

### Automated CI security (deepsec retired August 2026)

The `deepsec:` job that ran on every push was removed on cost: it billed per token per file, and a full pass over the codebase ran into tens of dollars per push. Its two audits (v0.9.74, v0.9.80) found real bugs and those fixes are documented above.

What runs now, all free and on every push or pull request: CodeQL static analysis, Socket.dev supply-chain checks, GitHub Dependency Review, Dependabot security updates, `pnpm audit --prod --audit-level=high`, a licence check, and GitHub secret scanning with push protection.

Deeper review is now deliberate rather than scheduled: before each release, the release diff is reviewed for anything crossing a trust boundary (plugin loading, credential handling, auth paths, parsing untrusted input) instead of re-scanning unchanged code.
