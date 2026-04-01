# Metadata Directory Structure

## Standard Layout

When you run `gpc listings pull --dir metadata/`, GPC creates this structure:

```
metadata/
├── en-US/
│   ├── title.txt                    # App title (max 50 chars)
│   ├── short_description.txt        # Short description (max 80 chars)
│   ├── full_description.txt         # Full description (max 4000 chars)
│   └── changelogs/
│       ├── 142.txt                  # Release notes for version code 142
│       └── default.txt              # Default release notes
├── ja-JP/
│   ├── title.txt
│   ├── short_description.txt
│   └── full_description.txt
├── fr-FR/
│   ├── title.txt
│   ├── short_description.txt
│   └── full_description.txt
└── ...
```

## File Encoding

- All text files must be **UTF-8** encoded
- No BOM (Byte Order Mark)
- Newlines: LF preferred, CRLF accepted

## Character Limits

| Field | Max Length |
|-------|-----------|
| Title | 50 characters |
| Short description | 80 characters |
| Full description | 4,000 characters |
| Release notes (per language) | 500 characters |

## Language Codes

Use BCP 47 language tags as directory names. Common codes:

| Code | Language |
|------|----------|
| `en-US` | English (US) |
| `en-GB` | English (UK) |
| `ja-JP` | Japanese |
| `ko-KR` | Korean |
| `zh-CN` | Chinese (Simplified) |
| `zh-TW` | Chinese (Traditional) |
| `fr-FR` | French |
| `de-DE` | German |
| `es-ES` | Spanish |
| `pt-BR` | Portuguese (Brazil) |
| `it-IT` | Italian |
| `ru-RU` | Russian |
| `ar` | Arabic |
| `hi-IN` | Hindi |

## Push Behavior

When running `gpc listings push --dir metadata/`:

1. GPC reads all language directories
2. For each language, reads title, short_description, full_description
3. Compares with current Play Console content
4. Only updates languages/fields that have changed
5. Uses a single edit (atomic commit)

Use `--dry-run` to preview changes:
```bash
gpc listings push --dir metadata/ --dry-run
```

Use `--changes-not-sent-for-review` to prevent the edit from being auto-submitted for review:
```bash
gpc listings push --dir metadata/ --changes-not-sent-for-review
```

Use `--error-if-in-review` to abort if the app is currently in review or rejected:
```bash
gpc listings push --dir metadata/ --error-if-in-review
```
