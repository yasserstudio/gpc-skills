# Multi-Language Release Notes

Managing release notes (what's new text) across languages with GPC.

## Setting release notes during upload

```bash
# Upload with release notes (--notes sets en-US only)
gpc releases upload app-release.aab \
  --track beta \
  --notes "Bug fixes and performance improvements"
```

`--notes` takes one plain string for en-US. For more than one language, use `--notes-dir` (below).

## Using a release notes file

For many languages, use a directory of text files:

```bash
gpc releases upload app-release.aab \
  --track production \
  --notes-dir release-notes/
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
  --notes-dir release-notes/
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
