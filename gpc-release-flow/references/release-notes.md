# Multi-Language Release Notes

Managing release notes (what's new text) across languages with GPC.

## Setting release notes during upload

```bash
# Upload with release notes
gpc releases upload app-release.aab \
  --track beta \
  --release-notes "en-US=Bug fixes and performance improvements"

# Multiple languages
gpc releases upload app-release.aab \
  --track beta \
  --release-notes "en-US=Bug fixes and improvements" \
  --release-notes "ja-JP=バグ修正とパフォーマンスの向上" \
  --release-notes "fr-FR=Corrections de bugs et améliorations"
```

## Using a release notes file

For many languages, use a directory of text files:

```bash
gpc releases upload app-release.aab \
  --track production \
  --release-notes-dir release-notes/
```

### Directory structure

```
release-notes/
├── en-US.txt
├── ja-JP.txt
├── fr-FR.txt
├── de-DE.txt
└── es-ES.txt
```

Each file contains the plain text release notes for that language.

## Release notes with gpc publish

```bash
gpc publish app-release.aab \
  --track production \
  --rollout 10 \
  --release-notes-dir release-notes/
```

## Character limits

| Field | Limit |
|-------|-------|
| Release notes | 500 characters per language |

## Tips

- Keep release notes under 500 characters per language
- Use the same `release-notes/` directory across releases — update files per version
- Commit release notes to git for history and review
- Release notes carry forward when promoting between tracks
- If no release notes are provided during promotion, the previous track's notes are used
