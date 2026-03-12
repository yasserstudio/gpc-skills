# Subscription JSON Schema

Reference for the JSON structure used with `gpc subscriptions create` and `gpc subscriptions update`.

## Subscription object

```json
{
  "productId": "premium_monthly",
  "listings": [
    {
      "languageCode": "en-US",
      "title": "Premium Monthly",
      "description": "Unlock all premium features with monthly billing.",
      "benefits": [
        "Unlimited access",
        "No ads",
        "Priority support"
      ]
    }
  ],
  "basePlans": [
    {
      "basePlanId": "monthly",
      "state": "ACTIVE",
      "autoRenewingBasePlanType": {
        "billingPeriodDuration": "P1M",
        "gracePeriodDuration": "P3D",
        "accountHoldDuration": "P30D",
        "resubscribeState": "RESUBSCRIBE_STATE_ACTIVE",
        "prorationMode": "CHARGE_ON_NEXT_BILLING_DATE"
      },
      "regionalConfigs": [
        {
          "regionCode": "US",
          "price": {
            "currencyCode": "USD",
            "units": "4",
            "nanos": 990000000
          }
        }
      ],
      "offerTags": [
        { "tag": "premium" }
      ]
    }
  ],
  "taxAndComplianceSettings": {
    "eeaWithdrawalRightType": "EEA_WITHDRAWAL_RIGHT_TYPE_DIGITAL_CONTENT",
    "isTokenizedDigitalAsset": false
  }
}
```

## Key fields

### Subscription

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `productId` | string | Yes | Unique product identifier (letters, numbers, underscores) |
| `listings` | array | Yes | Localized title, description, and benefits |
| `basePlans` | array | Yes | One or more billing configurations |
| `taxAndComplianceSettings` | object | No | EEA withdrawal rights, tokenized asset flags |

### Base plan

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `basePlanId` | string | Yes | Unique within the subscription |
| `state` | string | No | `ACTIVE` or `INACTIVE` (set via activate/deactivate commands) |
| `autoRenewingBasePlanType` | object | Yes* | For auto-renewing plans |
| `prepaidBasePlanType` | object | Yes* | For prepaid plans (mutually exclusive with autoRenewing) |
| `regionalConfigs` | array | Yes | Per-region pricing |
| `offerTags` | array | No | Tags for offer eligibility filtering |

*One of `autoRenewingBasePlanType` or `prepaidBasePlanType` is required.

### Billing period durations

| Duration | Meaning |
|----------|---------|
| `P1W` | Weekly |
| `P1M` | Monthly |
| `P3M` | 3 months |
| `P6M` | 6 months |
| `P1Y` | Yearly |

### Price object

```json
{
  "currencyCode": "USD",
  "units": "4",
  "nanos": 990000000
}
```

- `units` — whole currency units (string)
- `nanos` — fractional units in billionths (990000000 = $0.99)
- Together: `units=4` + `nanos=990000000` = $4.99

### Listing object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `languageCode` | string | Yes | BCP-47 language code (e.g., `en-US`, `ja-JP`) |
| `title` | string | Yes | Display name (max 55 characters) |
| `description` | string | No | Description (max 80 characters) |
| `benefits` | array | No | Up to 4 benefit strings (max 40 chars each) |

## Offer JSON structure

```json
{
  "offerId": "intro_free_week",
  "phases": [
    {
      "recurrenceCount": 1,
      "duration": "P1W",
      "pricingInfo": {
        "pricingPhaseType": "PRICING_PHASE_TYPE_FREE"
      }
    }
  ],
  "eligibilityCriteria": {
    "acquisitionRule": {
      "scope": {
        "anySubscriptionInApp": true
      }
    }
  },
  "offerTags": [
    { "tag": "intro" }
  ],
  "state": "ACTIVE"
}
```

### Pricing phase types

| Type | Description |
|------|-------------|
| `PRICING_PHASE_TYPE_FREE` | Free trial period |
| `PRICING_PHASE_TYPE_DISCOUNTED` | Reduced price (requires `price` field) |
| `PRICING_PHASE_TYPE_REGULAR` | Regular subscription price |

## Price migration JSON

Used with `gpc subscriptions base-plans migrate-prices`:

```json
{
  "regionalPriceMigrations": [
    {
      "regionCode": "US",
      "oldestAllowedPriceVersionTime": "2025-01-01T00:00:00Z",
      "newPrice": {
        "currencyCode": "USD",
        "units": "5",
        "nanos": 990000000
      }
    }
  ],
  "regionsVersion": {
    "version": "2024.1"
  }
}
```

## Update masks

Common `--update-mask` values for `gpc subscriptions update`:

| Mask | What it updates |
|------|----------------|
| `listings` | All localized listings |
| `basePlans` | All base plan configurations |
| `taxAndComplianceSettings` | Tax and compliance settings |

Multiple masks can be comma-separated: `--update-mask "listings,basePlans"`.
