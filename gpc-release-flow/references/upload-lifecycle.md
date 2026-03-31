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

For large files, GPC uses resumable uploads:
- File is uploaded in chunks
- Progress is reported during upload
- If interrupted, the upload can resume from where it left off
