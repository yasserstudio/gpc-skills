# Games configuration JSON schemas

Config shapes for `gpc games achievements create/update --file` and `gpc games leaderboards create/update --file` (Games Configuration API, `gamesconfiguration v1configuration`).

## Achievement

```json
{
  "achievementType": "STANDARD",
  "initialState": "HIDDEN",
  "draft": {
    "name": {
      "translations": [{ "locale": "en-US", "value": "First Victory" }]
    },
    "description": {
      "translations": [{ "locale": "en-US", "value": "Win your first match" }]
    },
    "pointValue": 10
  }
}
```

| Field | Values | Notes |
| --- | --- | --- |
| `achievementType` | `STANDARD`, `INCREMENTAL` | Incremental achievements unlock after N steps. |
| `initialState` | `HIDDEN`, `REVEALED` | Hidden achievements are not shown until unlocked. |
| `draft.name.translations[]` | `{ locale, value }` | At least one locale (e.g. `en-US`). |
| `draft.description.translations[]` | `{ locale, value }` | Per-locale description. |
| `draft.pointValue` | integer | Achievement points. |
| `draft.stepsToUnlock` | integer | **Required when `achievementType` is `INCREMENTAL`.** |

Incremental example: add `"achievementType": "INCREMENTAL"` and `"stepsToUnlock": 100` to `draft`.

## Leaderboard

```json
{
  "scoreOrder": "LARGER_IS_BETTER",
  "draft": {
    "name": {
      "translations": [{ "locale": "en-US", "value": "High Scores" }]
    },
    "scoreFormat": {
      "numberFormatType": "NUMERIC"
    }
  }
}
```

| Field | Values | Notes |
| --- | --- | --- |
| `scoreOrder` | `LARGER_IS_BETTER`, `SMALLER_IS_BETTER` | `SMALLER_IS_BETTER` for time/rank leaderboards. |
| `draft.name.translations[]` | `{ locale, value }` | At least one locale. |
| `draft.scoreFormat.numberFormatType` | `NUMERIC`, `TIME_DURATION`, `CURRENCY` | How scores are displayed. |

## Notes

- IDs in `get`/`update`/`delete`/`diff` are the Play Games config IDs (e.g. `CgkI1234567890`), returned by `list`.
- All write commands accept `--dry-run` to preview the request body.
- `diff --file` reports field-by-field differences between the local file and remote state; use it to detect drift before `update`.
