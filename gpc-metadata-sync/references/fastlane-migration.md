# Migrating from Fastlane Supply

## Compatibility

GPC reads and writes the same metadata directory structure that Fastlane supply uses. Migration is straightforward.

## Fastlane Directory Layout

Fastlane stores Android metadata at:
```
fastlane/metadata/android/
├── en-US/
│   ├── title.txt
│   ├── short_description.txt
│   ├── full_description.txt
│   ├── changelogs/
│   │   └── 142.txt
│   └── images/
│       ├── phoneScreenshots/
│       │   ├── 1.png
│       │   └── 2.png
│       ├── icon.png
│       └── featureGraphic.png
├── ja-JP/
│   └── ...
└── ...
```

## Using GPC with Existing Fastlane Metadata

Point GPC directly at your Fastlane metadata directory:

```bash
# Push existing Fastlane metadata to Play Console
gpc listings push --dir fastlane/metadata/android/

# Pull latest from Play Console into Fastlane directory
gpc listings pull --dir fastlane/metadata/android/
```

No conversion needed — the format is identical.

## Command Mapping: Fastlane → GPC

| Fastlane Command | GPC Equivalent |
|-----------------|----------------|
| `fastlane supply --track beta --aab app.aab` | `gpc releases upload app.aab --track beta` |
| `fastlane supply --track production --rollout 0.1` | `gpc releases upload app.aab --track production --rollout 10` |
| `fastlane supply --skip_upload_aab --metadata_path metadata/` | `gpc listings push --dir metadata/` |
| `fastlane supply --skip_upload_aab --download_metadata` | `gpc listings pull --dir metadata/` |
| `fastlane supply --track production --version_code 42` | `gpc releases promote --from beta --to production` |

## Key Differences

| Aspect | Fastlane supply | GPC |
|--------|----------------|-----|
| Runtime | Ruby + Bundler | Node.js (or standalone binary) |
| Startup | 2-3 seconds | <500ms |
| API coverage | ~20 endpoints | 162 endpoints |
| Config | Fastfile + Appfile | `.gpcrc.json` + env vars |
| Output | Ruby logs | JSON/table/yaml/markdown |
| Auth | JSON key file only | Service account + OAuth + ADC |
| Rollout syntax | `--rollout 0.1` (decimal) | `--rollout 10` (percentage) |

## Migration Checklist

1. **Install GPC:** `npm install -g @gpc-cli/cli`
2. **Set up auth:** `gpc auth login --service-account path/to/key.json` (same key file works)
3. **Configure app:** `gpc config set app com.example.app`
4. **Test with existing metadata:** `gpc listings push --dir fastlane/metadata/android/ --dry-run`
5. **Update CI:** Replace `fastlane supply` with `gpc` commands
6. **Remove Fastlane (optional):** Delete Gemfile, Fastfile, Appfile if no longer needed

## Keeping Both During Migration

You can run both tools during transition. They share:
- Service account key files (same JSON format)
- Metadata directory structure (compatible)

They don't conflict because each creates its own API edit.
