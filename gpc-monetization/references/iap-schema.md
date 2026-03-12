# In-App Product (IAP) JSON Schema

Reference for the JSON structure used with `gpc iap create`, `gpc iap update`, and `gpc iap sync`.

## IAP object

```json
{
  "sku": "coins_100",
  "status": "statusActive",
  "purchaseType": "managedUser",
  "defaultPrice": {
    "priceMicros": "990000",
    "currency": "USD"
  },
  "listings": {
    "en-US": {
      "title": "100 Coins",
      "description": "A pack of 100 coins to use in-game."
    },
    "ja-JP": {
      "title": "100\u30b3\u30a4\u30f3",
      "description": "\u30b2\u30fc\u30e0\u5185\u3067\u4f7f\u3048\u308b100\u30b3\u30a4\u30f3\u30d1\u30c3\u30af\u3002"
    }
  },
  "defaultLanguage": "en-US"
}
```

## Key fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sku` | string | Yes | Unique product ID (letters, numbers, underscores, periods) |
| `status` | string | No | `statusActive` or `statusInactive` |
| `purchaseType` | string | Yes | `managedUser` (one-time) or `subscription` (legacy) |
| `defaultPrice` | object | Yes | Base price for the product |
| `listings` | object | Yes | Localized title and description by language code |
| `defaultLanguage` | string | Yes | Primary language code |

## Price object

```json
{
  "priceMicros": "4990000",
  "currency": "USD"
}
```

- `priceMicros` — price in micros (1,000,000 micros = 1 currency unit)
- `4990000` = $4.99
- `990000` = $0.99

## Purchase types

| Type | Description |
|------|-------------|
| `managedUser` | One-time purchase (non-consumable by default; call `consume` to allow re-purchase) |
| `subscription` | Legacy subscription type (use `gpc subscriptions` for new subscriptions) |

## Sync directory structure

When using `gpc iap sync --dir products/`, each file represents one product:

```
products/
├── coins_100.json
├── coins_500.json
├── premium_unlock.json
└── remove_ads.json
```

File names don't matter — the `sku` field inside each file is the identifier.

### Sync behavior

| Local file | Play Store | Action |
|-----------|-----------|--------|
| Exists | Missing | Create |
| Exists | Exists | Update (if different) |
| Missing | Exists | Delete |

Use `--dry-run` to preview changes before applying.

## Listing limits

| Field | Max length |
|-------|-----------|
| `title` | 55 characters |
| `description` | 80 characters |
