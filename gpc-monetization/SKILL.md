---
name: gpc-monetization
description: "Use when managing in-app purchases, subscriptions, pricing, or Real-Time Developer Notifications in Google Play. Make sure to use this skill whenever the user mentions gpc subscriptions, gpc iap, gpc purchases, gpc pricing, gpc rtdn, in-app products, base plans, subscription offers, one-time products, consumable products, purchase verification, purchase acknowledgement, purchase token, subscription cancellation, subscription deferral, voided purchases, refunds, regional pricing, currency conversion, price migration, SKU management, monetization, revenue, billing, subscription analytics, churn, trial conversion, subscriber count, RTDN, Real-Time Developer Notifications, Pub/Sub notifications, subscription events, purchase events — even if they don't explicitly say 'monetization.' Also trigger when someone wants to create or update subscriptions, manage base plan lifecycle (activate/deactivate), set up introductory offers, verify server-side purchases, handle refunds, convert prices across regions, sync IAP products from files, migrate subscribers to new prices, view subscription analytics, decode Pub/Sub notification payloads, or check RTDN topic configuration. For release management, see gpc-release-flow. For CI automation, see gpc-ci-integration."
compatibility: "GPC v0.9+. Requires authenticated GPC setup (see gpc-setup skill). Subscriptions and IAP require products configured in Google Play Console."
metadata:
  version: 0.11.1
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

# Specify a regions version (defaults to 2022/02)
gpc subscriptions create --file subscription.json --regions-version "2022/02"
```

`Read:` `references/subscription-schema.md` for the JSON structure and field reference.

#### C. Update a subscription

```bash
# Update specific fields
gpc subscriptions update <product-id> --file updated.json --update-mask "listings"

# Preview changes
gpc subscriptions update <product-id> --file updated.json --dry-run

# Upsert: create the subscription if it does not already exist
gpc subscriptions update <product-id> --file updated.json --allow-missing

# Control propagation speed (default: LATENCY_SENSITIVE)
gpc subscriptions update <product-id> --file updated.json --latency-tolerance LATENCY_TOLERANT
```

The `--update-mask` flag controls which fields are updated. Omit it to replace the entire subscription.

The `--allow-missing` flag enables upsert behavior: if the subscription does not exist, it will be created instead of returning an error.

The `--latency-tolerance` flag controls how quickly changes propagate. Use `LATENCY_SENSITIVE` (default) for immediate propagation, or `LATENCY_TOLERANT` when you can accept a delay in exchange for higher throughput during bulk operations.

#### D. Batch operations

```bash
# Batch-get multiple subscriptions at once
gpc subscriptions batch-get <id1> <id2> <id3>

# Batch-update multiple subscriptions from JSON
gpc subscriptions batch-update --file batch-updates.json --dry-run
gpc subscriptions batch-update --file batch-updates.json
```

#### E. Delete a subscription

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

# Upsert: create the offer if it does not already exist
gpc subscriptions offers update <product-id> <base-plan-id> <offer-id> --file offer.json --allow-missing

# Control propagation speed for bulk offer updates
gpc subscriptions offers update <product-id> <base-plan-id> <offer-id> --file offer.json --latency-tolerance LATENCY_TOLERANT

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

# Paginated listing (useful for apps with many products)
gpc iap list --page-size 50
gpc iap list --page-size 50 --next-page <page-token>

gpc iap get <sku>
```

> **New in v0.9.51:** `gpc iap list` (aliased as `gpc one-time-products list`) now supports `--page-size` and `--next-page` for paginated results. The response includes a `nextPageToken` field when more results are available.

#### B. Create and update

```bash
# Create from JSON
gpc iap create --file product.json --dry-run
gpc iap create --file product.json

# Specify a regions version on create (defaults to 2022/02)
gpc iap create --file product.json --regions-version "2022/02"

# Update
gpc iap update <sku> --file updated.json --dry-run
gpc iap update <sku> --file updated.json

# Upsert: create the product if it does not already exist
gpc iap update <sku> --file updated.json --allow-missing

# Control propagation speed
gpc iap update <sku> --file updated.json --latency-tolerance LATENCY_TOLERANT

# Delete
gpc iap delete <sku>
```

`Read:` `references/iap-schema.md` for the JSON structure and field reference.

#### C. Batch delete

```bash
# Delete multiple IAP products at once
gpc iap batch-delete <sku1> <sku2> <sku3> --dry-run
gpc iap batch-delete <sku1> <sku2> <sku3>
```

#### D. Sync from directory

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
# Acknowledge a subscription purchase (v1 — required within 3 days)
gpc purchases subscription acknowledge <subscription-id> <token>
gpc purchases subscription acknowledge <subscription-id> <token> --payload "order-456"

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
# List voided purchases (default: in-app only)
gpc purchases voided --start-time 2025-01-01 --end-time 2025-03-01

# Include subscription voids (type=1)
gpc purchases voided --type 1

# Include quantity-based partial refunds
gpc purchases voided --include-partial-refunds

# Refund an order
gpc purchases orders refund <order-id> --full-refund
gpc purchases orders refund <order-id> --prorated-refund
```

> **New in v0.9.47:** `--type 0` (default) returns only in-app purchase voids. `--type 1` includes subscription voids. `--include-partial-refunds` includes quantity-based partial refunds.

All write operations support `--dry-run`.

`Read:` `references/purchase-verification.md` for server-side verification patterns and best practices.

### 6. Real-Time Developer Notifications (RTDN)

RTDN delivers Pub/Sub messages when subscription and purchase events occur. GPC can decode and inspect these notifications.

```bash
# Check RTDN topic configuration
gpc rtdn status

# Decode a base64-encoded Pub/Sub notification payload
gpc rtdn decode <base64-payload>

# Show setup instructions for RTDN
gpc rtdn test
```

Notification types include: `SUBSCRIPTION_PURCHASED`, `SUBSCRIPTION_CANCELED`, `SUBSCRIPTION_RENEWED`, `SUBSCRIPTION_REVOKED`, `SUBSCRIPTION_EXPIRED`, `ONE_TIME_PRODUCT_PURCHASED`, `VOIDED_PURCHASE`, and more.

> **New in v0.9.47:** RTDN commands help debug subscription lifecycle events. Set up a Pub/Sub topic in GCP, configure it in Play Console > Monetization setup, and use `gpc rtdn decode` to inspect payloads.

### 7. Subscription analytics

Get insights on subscriber counts, conversion, and churn:

```bash
# Active subscribers, in-trial counts, trial→paid conversion, churn cohort
gpc subscriptions analytics

# JSON output for dashboards
gpc subscriptions analytics --json
```

Reports: active count, in-trial count, cancelled count, trial-to-paid conversion rate, estimated churn by cohort.

### 8. Base plan price migration

Migrate existing subscribers to a new price point:

```bash
# Migrate all subscribers on a base plan to a new price
gpc subscriptions base-plans migrate-prices <product-id> <base-plan-id> \
  --file prices.json

# Prices file format: regional prices JSON (same as base plan prices)
```

Subscribers are notified by Google Play and must accept or cancel. Use `--dry-run` to preview the migration.

### 9. Regional pricing

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
