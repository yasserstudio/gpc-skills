---
name: gpc-monetization
description: "Use when managing in-app purchases, subscriptions, or pricing in Google Play. Make sure to use this skill whenever the user mentions gpc subscriptions, gpc iap, gpc purchases, gpc pricing, in-app products, base plans, subscription offers, one-time purchases, consumable products, purchase verification, purchase acknowledgement, purchase token, subscription cancellation, subscription deferral, voided purchases, refunds, regional pricing, currency conversion, price migration, SKU management, monetization, revenue, billing, subscription analytics, churn, trial conversion, subscriber count — even if they don't explicitly say 'monetization.' Also trigger when someone wants to create or update subscriptions, manage base plan lifecycle (activate/deactivate), set up introductory offers, verify server-side purchases, handle refunds, convert prices across regions, sync IAP products from files, migrate subscribers to new prices, or view subscription analytics. For release management, see gpc-release-flow. For CI automation, see gpc-ci-integration."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill). Subscriptions and IAP require products configured in Google Play Console."
metadata:
  version: 0.10.0
---

# gpc-monetization

Manage subscriptions, in-app products, purchases, and pricing with GPC.

## When to use

- Creating, updating, or deleting subscriptions and base plans
- Managing subscription offers (introductory, upgrade, winback)
- Creating, updating, or syncing in-app products (one-time purchases)
- Verifying, acknowledging, or consuming purchases server-side
- Cancelling, deferring, or revoking subscriptions
- Handling refunds and voided purchases
- Viewing subscription analytics (active, trial, churn, conversion)
- Migrating subscribers to new price points
- Converting prices across regions and currencies

## Inputs required

- **Authenticated GPC** — `gpc auth status` must show valid credentials
- **App package name** — set via `--app` or `gpc config set app`
- **Product JSON files** — for create/update operations (subscription or IAP definitions)
- **Purchase tokens** — for verification, acknowledgement, and consumption
- **Developer account ID** — for some purchase operations (`--developer-id`)

## Procedure

### 0. Verify setup

```bash
gpc auth status
gpc config get app
```

Confirm auth is valid and default app is set. If not, `Read:` the gpc-setup skill.

### 1. Subscriptions

#### A. List and inspect subscriptions

```bash
# List all subscriptions
gpc subscriptions list

# Get details for a specific subscription
gpc subscriptions get <product-id>

# Paginated listing
gpc subscriptions list --limit 50
```

#### B. Create a subscription

Create a JSON file defining the subscription, then:

```bash
# Preview first
gpc subscriptions create --file subscription.json --dry-run

# Create
gpc subscriptions create --file subscription.json
```

`Read:` `references/subscription-schema.md` for the JSON structure and field reference.

#### C. Update a subscription

```bash
# Update specific fields
gpc subscriptions update <product-id> --file updated.json --update-mask "listings"

# Preview changes
gpc subscriptions update <product-id> --file updated.json --dry-run
```

The `--update-mask` flag controls which fields are updated. Omit it to replace the entire subscription.

#### D. Delete a subscription

```bash
gpc subscriptions delete <product-id> --dry-run
gpc subscriptions delete <product-id>
```

### 2. Base plans

Base plans define the billing period and pricing for a subscription.

```bash
# Activate a base plan (makes it available for purchase)
gpc subscriptions base-plans activate <product-id> <base-plan-id>

# Deactivate a base plan (stops new purchases, existing subscribers unaffected)
gpc subscriptions base-plans deactivate <product-id> <base-plan-id>

# Delete a base plan
gpc subscriptions base-plans delete <product-id> <base-plan-id>

# Migrate prices for a base plan
gpc subscriptions base-plans migrate-prices <product-id> <base-plan-id> --file prices.json
```

All base plan commands support `--dry-run`.

### 3. Subscription offers

Offers define promotional pricing (introductory, upgrade, winback).

```bash
# List offers for a base plan
gpc subscriptions offers list <product-id> <base-plan-id>

# Get offer details
gpc subscriptions offers get <product-id> <base-plan-id> <offer-id>

# Create an offer
gpc subscriptions offers create <product-id> <base-plan-id> --file offer.json --dry-run
gpc subscriptions offers create <product-id> <base-plan-id> --file offer.json

# Update an offer
gpc subscriptions offers update <product-id> <base-plan-id> <offer-id> --file offer.json

# Activate / deactivate an offer
gpc subscriptions offers activate <product-id> <base-plan-id> <offer-id>
gpc subscriptions offers deactivate <product-id> <base-plan-id> <offer-id>

# Delete an offer
gpc subscriptions offers delete <product-id> <base-plan-id> <offer-id>
```

### 4. In-app products (IAP)

One-time purchases — consumables, non-consumables, entitlements.

#### A. List and inspect

```bash
gpc iap list
gpc iap get <sku>
```

#### B. Create and update

```bash
# Create from JSON
gpc iap create --file product.json --dry-run
gpc iap create --file product.json

# Update
gpc iap update <sku> --file updated.json --dry-run
gpc iap update <sku> --file updated.json

# Delete
gpc iap delete <sku>
```

`Read:` `references/iap-schema.md` for the JSON structure and field reference.

#### C. Sync from directory

Bulk-manage IAP products from a directory of JSON files:

```bash
# Preview what would change
gpc iap sync --dir products/ --dry-run

# Apply changes
gpc iap sync --dir products/
```

Each JSON file in the directory represents one product. GPC compares local files against the Play Store and creates, updates, or deletes as needed.

### 5. Purchases — verification and lifecycle

#### A. Product purchases

```bash
# Verify a purchase
gpc purchases get <product-id> <token>

# Acknowledge (required within 3 days or purchase is refunded)
gpc purchases acknowledge <product-id> <token>
gpc purchases acknowledge <product-id> <token> --payload "order-123"

# Consume (for consumable products — allows re-purchase)
gpc purchases consume <product-id> <token>
```

#### B. Subscription purchases

```bash
# Get subscription purchase details (v2 API)
gpc purchases subscription get <token>

# Cancel a subscription (v1 — requires subscription-id)
gpc purchases subscription cancel <subscription-id> <token>

# Cancel a subscription (v2 — supports cancellation types)
gpc purchases subscription cancel-v2 <token>
gpc purchases subscription cancel-v2 <token> --type DEVELOPER_CANCELED

# Defer expiry to a later date (v1)
gpc purchases subscription defer <subscription-id> <token> --expiry 2025-06-01T00:00:00Z

# Defer expiry (v2 — supports add-on subscriptions)
gpc purchases subscription defer-v2 <token> --until 2026-07-01T00:00:00Z

# Revoke a subscription (v2 API)
gpc purchases subscription revoke <token>
```

#### C. Product purchases (v2 API)

```bash
# Get product purchase details (v2 — supports multi-offer OTPs)
gpc purchases product get-v2 <token>
```

The v2 product purchase API returns `ProductPurchaseV2` with line items, offer details, and multi-product bundle support.

#### D. Orders

```bash
# Get order details
gpc purchases orders get <order-id>

# Batch retrieve orders (up to 1000)
gpc purchases orders batch-get --ids "GPA.1234,GPA.5678"
```

#### E. Voided purchases and refunds

```bash
# List voided purchases
gpc purchases voided --start-time 2025-01-01 --end-time 2025-03-01

# Refund an order
gpc purchases orders refund <order-id> --full-refund
gpc purchases orders refund <order-id> --prorated-refund
```

All write operations support `--dry-run`.

`Read:` `references/purchase-verification.md` for server-side verification patterns and best practices.

### 6. Subscription analytics

Get insights on subscriber counts, conversion, and churn:

```bash
# Active subscribers, in-trial counts, trial→paid conversion, churn cohort
gpc subscriptions analytics

# JSON output for dashboards
gpc subscriptions analytics --json
```

Reports: active count, in-trial count, cancelled count, trial-to-paid conversion rate, estimated churn by cohort.

### 7. Base plan price migration

Migrate existing subscribers to a new price point:

```bash
# Migrate all subscribers on a base plan to a new price
gpc subscriptions base-plans migrate-prices <product-id> <base-plan-id> \
  --file prices.json

# Prices file format: regional prices JSON (same as base plan prices)
```

Subscribers are notified by Google Play and must accept or cancel. Use `--dry-run` to preview the migration.

### 8. Regional pricing

Convert a base price to all Google Play supported regions:

```bash
# Convert USD 4.99 to all regional prices
gpc pricing convert --from USD --amount 4.99

# Output as JSON for scripting
gpc pricing convert --from USD --amount 4.99 --json
```

The conversion uses Google Play's official exchange rates and rounds to locally appropriate price points.

## Verification

- `gpc subscriptions list` returns your subscriptions
- `gpc iap list` returns your in-app products
- `gpc purchases get <product-id> <token>` returns v1 purchase details for a valid token
- `gpc purchases product get-v2 <token>` returns v2 purchase details with line items
- `gpc purchases orders get <order-id>` returns order details
- `gpc pricing convert --from USD --amount 9.99 --json` returns regional prices
- All `--dry-run` commands show what would change without modifying data
- JSON output works on all commands (`--json` flag)

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `PRODUCT_NOT_FOUND` | Invalid product ID or SKU | Verify with `gpc subscriptions list` or `gpc iap list` |
| `INVALID_PURCHASE_TOKEN` | Token expired, already consumed, or wrong app | Verify token matches the app and product |
| `PURCHASE_NOT_ACKNOWLEDGED` | Purchase not acknowledged within 3 days | Acknowledge immediately; if >3 days, purchase was auto-refunded |
| `SUBSCRIPTION_NOT_FOUND` | Wrong subscription ID in cancel/defer | Use `gpc purchases subscription get <token>` to find the correct ID |
| `INVALID_JSON` in create/update | Malformed product JSON file | Validate JSON structure against the schema reference |
| `PERMISSION_DENIED` on purchases | Service account lacks financial permissions | Grant "View financial data" and "Manage orders" in Play Console |
| `--update-mask` error | Invalid field path in update mask | Check API docs for valid field names; omit flag to replace all fields |
| `iap sync` deletes unexpected products | Directory missing some product files | Use `--dry-run` first; sync deletes products not in the directory |

## Related skills

- **gpc-setup** — authentication and configuration required before monetization commands
- **gpc-release-flow** — releasing app updates that include new products or pricing changes
- **gpc-vitals-monitoring** — monitoring reviews that mention billing issues
- **gpc-ci-integration** — automating IAP sync and purchase verification in CI/CD
