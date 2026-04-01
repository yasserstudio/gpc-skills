# Upload & Edit Lifecycle

## How Google Play Edits Work

Google Play uses an "edit" lifecycle for all mutations. GPC manages this automatically, but understanding it helps debug issues.

### Edit Flow

```
1. Insert Edit    → Creates a new edit (gets editId)
2. Modify Edit    → Upload AAB, set track, set release notes
3. Validate Edit  → Check for errors before committing
4. Commit Edit    → Apply all changes atomically
   (or Delete Edit → Discard all changes on failure)
```

### Key Rules

- **Only one active edit per app** — if another edit exists (from Console UI or another tool), GPC will get an `EDIT_CONFLICT` error
- **Edits expire after 1 hour** — long-running operations may need a new edit
- **Commit is atomic** — all changes in an edit are applied together or not at all
- **GPC handles this automatically** — you don't need to manage edits manually

## Upload Process

### What `gpc releases upload` does:

1. Creates a new edit
2. Uploads the AAB/APK file (with progress reporting)
3. Assigns the uploaded bundle to the specified track
4. Sets the rollout percentage (default: 100%)
5. Optionally sets release notes
6. Validates the edit
7. Commits the edit (or deletes on failure)

### What `gpc publish` does (end-to-end):

Same as above, but also:
- Reads release notes from `--notes` flag or `--notes-dir` directory
- Supports multi-language notes from directory structure
- Provides a single-command UX for the most common workflow

## File Requirements

| Type | Format | Max Size |
|------|--------|----------|
| AAB | Android App Bundle (.aab) | 150 MB |
| APK | Android Package (.apk) | 100 MB |

- AAB is strongly preferred (required for new apps since August 2021)
- Version code must be higher than any existing version on the target track
- App must be signed (Play App Signing or legacy keystore)

## Resumable Uploads

GPC uses Google's resumable upload protocol for reliable transfers:

- Files >= 5 MB are uploaded in **8 MB chunks** (streamed from disk, never buffered in memory)
- Files < 5 MB use simple upload (single POST, less overhead)
- **Auto-resume on failure** -- interrupted uploads resume from the last successful byte; session URIs valid for 1 week
- **Real-time progress bar** -- shows bytes uploaded, throughput, and ETA in interactive terminals

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GPC_UPLOAD_CHUNK_SIZE` | `8388608` (8 MB) | Chunk size in bytes. Must be a multiple of 256 KB |
| `GPC_UPLOAD_RESUMABLE_THRESHOLD` | `5242880` (5 MB) | File size threshold for switching to resumable upload |
| `GPC_UPLOAD_TIMEOUT` | Auto (30s + 1s/MB) | Upload timeout in milliseconds |

## Expansion Files (OBB)

APK expansion files (OBB) allow you to attach additional data files to an APK when the APK itself is under the size limit but your app needs extra assets. Expansion files are only supported for APK uploads (not AAB).

### Types

| Type | File Name Pattern | Max Size | Description |
|------|-------------------|----------|-------------|
| Main | `main.<versionCode>.<packageName>.obb` | 2 GB | Primary expansion file, downloaded with the APK |
| Patch | `patch.<versionCode>.<packageName>.obb` | 2 GB | Optional secondary file for incremental updates |

### Upload via GPC

```bash
# Upload main expansion file for a specific APK version code
gpc releases upload-expansion main app.obb --apk-version-code 143

# Upload patch expansion file
gpc releases upload-expansion patch patch.obb --apk-version-code 143
```

### Key Rules

- Expansion files are linked to a specific APK version code. Each APK version can have at most one main and one patch OBB.
- When you upload a new APK without new expansion files, the previous version's expansion files carry forward automatically.
- AAB (Android App Bundle) does not use expansion files. AAB handles asset delivery through Play Asset Delivery instead.
- Maximum size per expansion file is 2 GB.
- Expansion files use the `edits.expansionfiles.upload` API endpoint under the hood.
