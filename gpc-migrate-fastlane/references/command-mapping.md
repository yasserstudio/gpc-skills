# Fastlane → GPC Command Mapping

Complete mapping of Fastlane supply commands to GPC equivalents.

## Uploads and releases

| Fastlane | GPC |
|----------|-----|
| `supply --aab app.aab --track internal` | `gpc releases upload app.aab --track internal` |
| `supply --aab app.aab --track beta` | `gpc releases upload app.aab --track beta` |
| `supply --aab app.aab --track production` | `gpc releases upload app.aab --track production` |
| `supply --aab app.aab --track production --rollout 0.1` | `gpc releases upload app.aab --track production --rollout 10` |
| `supply --apk app.apk --track beta` | `gpc releases upload app.apk --track beta` |

**Rollout difference:** Fastlane uses decimal (0.0–1.0), GPC uses percentage (0–100).

## Metadata

| Fastlane | GPC |
|----------|-----|
| `supply --download_metadata --metadata_path dir/` | `gpc listings pull --dir dir/` |
| `supply --skip_upload_aab --metadata_path dir/` | `gpc listings push --dir dir/` |
| `supply --skip_upload_aab --skip_upload_metadata` | `gpc listings images upload --lang en-US --type phoneScreenshots *.png` |

## Track promotion

| Fastlane | GPC |
|----------|-----|
| `supply --track_promote_to production --track beta` | `gpc releases promote --from beta --to production` |
| (no direct equivalent) | `gpc releases rollout increase --track production --rollout 50` |
| (no direct equivalent) | `gpc releases rollout halt --track production` |
| (no direct equivalent) | `gpc releases rollout complete --track production` |

GPC provides granular rollout control that Fastlane doesn't support natively.

## Release notes

| Fastlane | GPC |
|----------|-----|
| `supply --aab app.aab --track beta --release_notes "..." ` | `gpc releases upload app.aab --track beta --release-notes "en-US=..."` |
| Changelogs in `metadata/android/en-US/changelogs/142.txt` | `gpc releases upload --release-notes-dir release-notes/` |

**Release-notes automation (v0.9.62+):** Fastlane users manage per-locale `metadata/android/<lang>/changelogs/<version>.txt` files by hand. GPC v0.9.62+ can generate them from your git log:

```bash
gpc changelog generate --target play-store --locales auto --format json --app com.example.app
```

Pair with `--ai` (v0.9.63+) for automatic LLM translation and `--apply` (v0.9.64+) to write translated notes directly into the draft release. End-to-end: `gpc changelog generate --target play-store --locales auto --ai --apply`.

## App information

| Fastlane | GPC |
|----------|-----|
| `supply --validate_only` | `gpc validate app.aab` |
| `supply --json_key key.json` | `gpc auth login --service-account key.json` |
| `supply --package_name com.example.app` | `gpc config set app com.example.app` or `--app com.example.app` |

## Environment variables

| Fastlane | GPC |
|----------|-----|
| `SUPPLY_JSON_KEY` | `GPC_SERVICE_ACCOUNT` |
| `SUPPLY_JSON_KEY_DATA` | `GPC_SERVICE_ACCOUNT` (accepts JSON content directly) |
| `SUPPLY_PACKAGE_NAME` | `GPC_APP` |
| (no equivalent) | `GPC_TIMEOUT`, `GPC_MAX_RETRIES`, `GPC_BASE_DELAY` |
| (no equivalent) | `GPC_DEBUG=1` |

## Features GPC has that Fastlane doesn't

| Feature | GPC Command |
|---------|-------------|
| Validate bundle | `gpc validate app.aab` |
| Staged rollout control | `gpc releases rollout increase/halt/complete` |
| Vitals monitoring | `gpc vitals crashes/anr --threshold` |
| Review management | `gpc reviews list/reply` |
| Subscription management | `gpc subscriptions create/update` |
| IAP sync | `gpc iap sync --dir` |
| User/tester management | `gpc users invite`, `gpc testers add` |
| Dry-run mode | `--dry-run` on all write commands |
| JSON output | `--json` on all commands |
| Plugin system | `@gpc-cli/plugin-sdk` |
| Threshold-gated CI | Exit code 6 on vitals breach |
