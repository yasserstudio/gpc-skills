---
name: gpc-enterprise
description: "Use when publishing private Android apps to Managed Google Play via the Play Custom App Publishing API. Trigger when the user mentions enterprise app publishing, Managed Google Play, custom apps, private apps, Play Custom App API, internal enterprise app distribution, organization-scoped apps, or B2B Android app delivery. Also trigger for questions about the `gpc enterprise publish` or `gpc enterprise create` commands, developer account IDs for the Custom App API, or granting the 'create and publish private apps' permission in Play Console."
compatibility: "GPC v0.9.56+. First Android publishing CLI with Play Custom App Publishing API support. Requires authenticated GPC setup (see gpc-setup skill) plus an additional Play Console permission granted to your service account."
metadata:
  version: 1.0.0
---

# GPC Enterprise — Managed Google Play

## When to use

Use this skill when the task involves:

- Publishing a **private app** to Managed Google Play (not to the public Play Store)
- Creating a custom app visible only to specific enterprise customers
- Setting up CI/CD to publish internal/B2B Android apps
- Understanding the difference between public Play Store publishing and Managed Google Play
- Troubleshooting `gpc enterprise publish` / `gpc enterprise create` errors
- Finding the correct developer account ID for the Play Custom App Publishing API
- Granting the "create and publish private apps" permission to a service account
- Adding enterprise organizations to a private app after creation
- Updating a private app's versions, tracks, or listings after initial creation

**Do NOT use this skill for:**
- Publishing public apps to the regular Play Store (use `gpc-release-flow`)
- Distributing internal test builds for QA (use `gpc internal-sharing upload`, covered by `gpc-release-flow`)
- Managed configurations (in-app settings delivered by EMM) — that's a client-side Android concern with no GPC command

## What Managed Google Play is

Managed Google Play is Google's app store for enterprise-managed Android devices. Apps fall into two categories:

- **Public apps** — regular Play Store apps that enterprises can approve and distribute to their employees. Published via the standard Android Publisher API (`gpc-release-flow`).
- **Private apps** — custom apps distributed exclusively to specific enterprise customers, invisible to the public Play Store. Published via the **Play Custom App Publishing API** (`gpc enterprise publish`).

This skill is for the second category.

## Permanently private — one-way door

::: warning
Apps created via `gpc enterprise publish` / `gpc enterprise create` are **permanently private**. They cannot be made public later. The CLI prints a confirmation prompt before running and requires explicit `--yes` in CI. Use a clearly-named test title if you're just experimenting.
:::

## Competitive landscape

**GPC is the first Android publishing CLI to support this API.**

- Fastlane `supply` — no support
- `gradle-play-publisher` — no support
- Individual scripts exist in the wild, but no productized CLI

If you're publishing to Managed Google Play today, you've been clicking through the Play Console UI for every release. This skill teaches the one-command alternative.

## Quick reference

```bash
# One-shot publish (most common)
gpc enterprise --account 1234567890 publish ./app.aab \
  --title "My Internal App" \
  --org-id customer-acme-org-id \
  --yes                                    # CI: skip confirmation prompt

# With multiple target organizations and display names
gpc enterprise --account 1234567890 publish ./app.aab \
  --title "My Internal App" \
  --org-id org-acme  --org-name "Acme Corp" \
  --org-id org-beta  --org-name "Beta Inc"

# Explicit-arg form (create)
gpc enterprise --account 1234567890 create \
  --title "My Internal App" \
  --bundle ./app.aab \
  --org-id customer-acme-org-id

# Probe setup before first run
gpc doctor                                 # checks Play Custom App Publishing API access
```

After the initial publish, the private app becomes a regular app in your developer account. Subsequent version uploads, tracks, listings, rollouts all go through the standard commands:

```bash
# Update the private app with a new version (uses the returned packageName)
gpc --app com.google.customapp.A1B2C3D4E5 releases upload ./app-v2.aab --track production
```

## Flags reference

**Parent command** (`gpc enterprise`):

| Flag | Required | Description |
| --- | --- | --- |
| `--account <id>` | Yes | Developer account ID (int64, from the Play Console URL) |
| `--org <id>` | — | **[DEPRECATED]** Alias for `--account`. Warns on use. Removed in a future version. |

**Subcommand `publish <bundle>`** (positional bundle path):

| Flag | Required | Description |
| --- | --- | --- |
| `<bundle>` | Yes | Path to AAB or APK file (positional) |
| `--title <title>` | Yes | App title |
| `--lang <code>` | — | BCP 47 language code, default `en_US` |
| `--org-id <id>` | — | Target enterprise organization ID (repeatable) |
| `--org-name <name>` | — | Human-readable organization name (repeatable, matched by position with `--org-id`) |
| `--yes` / `-y` | — | Skip the permanent-private confirmation prompt (required in non-TTY CI) |

**Subcommand `create`** — same flags as `publish` but `--bundle <path>` is required instead of a positional.

**Removed:** `gpc enterprise list` — the Play Custom App Publishing API has no list method. Use `gpc apps list` to find private apps; they appear alongside regular apps in your developer account.

## Finding your developer account ID

Your `--account` argument is a long integer, **not** an email, a Google Workspace organization ID, or a Cloud Identity organization ID. Read it from the Play Console URL:

```
https://play.google.com/console/developers/1234567890/...
                                             ^^^^^^^^^^
                                             this number
```

Copy that integer and pass it as `--account 1234567890`.

## Required setup (one-time, per developer account)

1. **Enable the Play Custom App Publishing API** in your Google Cloud project:
   https://console.cloud.google.com/apis/library/playcustomapp.googleapis.com

2. **Grant the service account the "create and publish private apps" permission:**
   - Open Play Console → Users and permissions
   - Find the service account (its email, e.g. `gpc-sa@myproject.iam.gserviceaccount.com`)
   - Under Account permissions (not per-app permissions), enable **"Create and publish private apps"**
   - Save

3. **Verify with `gpc doctor`:**

```bash
gpc doctor
```

Look for the line:
```
✓ Play Custom App Publishing API is reachable
```

If you instead see a warning about the API not being enabled or the permission missing, re-read steps 1 and 2.

4. **Obtain enterprise organization IDs from your customer.** These are opaque identifiers their IT admin provides. You cannot look them up yourself. If you don't have them yet, you can still publish without `--org-id` — the private app will be created unassociated, and orgs can be added via Play Console UI later.

## Key concepts

### Multipart resumable upload

Unlike the standard Publisher API, the Play Custom App API uses a combined multipart upload: the JSON metadata (title, language, organizations) travels in the *initial* session-initiation POST, then the bundle binary streams in subsequent chunks. GPC handles this via a new `HttpClient.uploadCustomApp<T>` helper and the `ResumableUploadOptions.initialMetadata` option (see `gpc-sdk-usage`).

### Subsequent updates go through regular commands

After `gpc enterprise publish` returns a `packageName`, the private app is a normal draft app in your developer account. All standard GPC commands work against it:

- `gpc releases upload` / `gpc releases promote` / `gpc releases rollout`
- `gpc tracks` for track management
- `gpc listings` for store metadata
- `gpc reviews` for user feedback (once distributed)
- `gpc vitals` for crash/ANR reporting

The only thing you can't do via the API post-creation is **add or remove target enterprise organizations** — that's Play Console UI only. Include all orgs at create time.

### Authorized-org-slug caveat in CI

If you see `SOCKET_CLI_ORG_SLUG` or similar in the CI workflow env, that's unrelated to this skill — it's a workaround for the Socket Security CLI's org resolution in CI runners. See the GPC repo's `.github/workflows/ci.yml` for the actual env var pattern.

## Troubleshooting

| Error | Cause | Fix |
| --- | --- | --- |
| `ENTERPRISE_INVALID_ACCOUNT_ID: Developer account ID must be numeric` | Passed a non-numeric value (email, Workspace org ID, display name) | Re-read the Play Console URL and extract the integer after `/console/developers/` |
| `ENTERPRISE_BUNDLE_NOT_FOUND: Bundle file not found` | `--bundle` / positional bundle path doesn't exist or isn't readable | Check the path, verify the build produced the file, verify permissions |
| `MISSING_REQUIRED_OPTION: Missing required option --account` | Called `gpc enterprise publish` without `--account` on the parent command | Add `--account <id>` before the subcommand. `--org` still works as deprecated alias. |
| `warning: --org is deprecated, use --account instead` | Using the old flag name | Rename to `--account` in your scripts. `--org` is removed in a future version. |
| `Play Custom App Publishing API is not enabled for this project` (from `gpc doctor`) | Step 1 of required setup is incomplete | Enable the API in your Google Cloud project (link above) |
| `Service account is missing the 'create and publish private apps' permission` (from `gpc doctor`) | Step 2 of required setup is incomplete | Grant the permission in Play Console → Users and permissions |
| `Refusing to run interactively in non-TTY environment. Pass --yes to confirm.` | Running in CI without `--yes` | Add `--yes` / `-y` to skip the permanent-private confirmation prompt in non-interactive environments |
| `gpc enterprise list was removed in v0.9.56` | Using the removed subcommand | Use `gpc apps list` instead; private apps appear in your regular developer account |

## Procedures

### First-time publish

1. Complete the required setup (API enable + permission grant + org IDs from customer).
2. Build your AAB: `./gradlew bundleRelease`
3. Run: `gpc doctor` — verify "Play Custom App Publishing API is reachable"
4. Dry run:
   ```bash
   gpc --dry-run enterprise --account <ID> publish ./app.aab --title "Test" --org-id <ORG>
   ```
5. Real run with `--yes` if in CI, or interactive otherwise:
   ```bash
   gpc enterprise --account <ID> publish ./app.aab \
     --title "My Internal App" \
     --org-id <CUSTOMER-ORG-ID>
   ```
6. Confirm the prompt (the CLI prints the target summary and requires explicit `y`).
7. Save the returned `packageName` — you'll need it for every subsequent `gpc releases upload` against this app.

### CI/CD recipe (GitHub Actions)

```yaml
name: Publish private app
on:
  workflow_dispatch:
    inputs:
      flow:
        description: Initial publish (create) or update (regular upload)?
        type: choice
        options: [update, initial]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
      - run: npm install -g @gpc-cli/cli
      - name: Write service account key
        run: echo '${{ secrets.GPC_SA_KEY }}' > /tmp/sa.json
        env:
          GPC_SERVICE_ACCOUNT_KEY: /tmp/sa.json

      - name: Initial publish
        if: inputs.flow == 'initial'
        run: |
          gpc enterprise --account ${{ secrets.DEVELOPER_ACCOUNT_ID }} \
            publish ./app.aab \
            --title "Internal Tools" \
            --org-id ${{ secrets.CUSTOMER_ORG_ID }} \
            --yes

      - name: Update existing
        if: inputs.flow == 'update'
        run: |
          gpc --app com.google.customapp.A1B2C3D4E5 \
              releases upload ./app.aab --track production
```

### Adding orgs after creation

Not supported via the API. Open Play Console → your app → Managed Google Play → Organizations and add/remove there.

## Known limitations

- **One-way door:** private apps cannot be made public later.
- **No list API:** `gpc enterprise list` does not exist. Use `gpc apps list`.
- **No post-creation org management via API:** Play Console UI only.
- **Can't influence package name:** Google assigns `com.google.customapp.<random>`.
- **End-to-end testing requires a real enterprise account:** there is no sandbox. Use a clearly-labeled test title when validating setup.

## Related skills

- `gpc-setup` — authentication (service account) + the "create and publish private apps" Play Console permission
- `gpc-release-flow` — updating a private app after initial creation (uses the same release commands as public apps)
- `gpc-ci-integration` — CI/CD patterns (GitHub Actions, GitLab CI) applied to private app publishing
- `gpc-sdk-usage` — `createEnterpriseClient`, `CustomApp` type, `HttpClient.uploadCustomApp<T>` for building your own tooling
- `gpc-troubleshooting` — error catalog including `ENTERPRISE_*` codes
