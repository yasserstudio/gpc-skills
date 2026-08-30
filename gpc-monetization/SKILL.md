---
name: gpc-monetization
description: "Use when managing in-app purchases, subscriptions, pricing, or Real-Time Developer Notifications in Google Play. Make sure to use this skill whenever the user mentions gpc subscriptions, gpc iap, gpc purchases, gpc pricing, gpc rtdn, in-app products, base plans, subscription offers, one-time products, consumable products, purchase verification, purchase acknowledgement, purchase token, subscription cancellation, subscription deferral, voided purchases, refunds, regional pricing, currency conversion, price migration, SKU management, monetization, revenue, billing, subscription analytics, churn, trial conversion, subscriber count, RTDN, Real-Time Developer Notifications, Pub/Sub notifications, subscription events, purchase events — even if they don't explicitly say 'monetization.' Also trigger when someone wants to create or update subscriptions, manage base plan lifecycle (activate/deactivate), set up introductory offers, verify server-side purchases, handle refunds, convert prices across regions, sync IAP products from files, migrate subscribers to new prices, view subscription analytics, decode Pub/Sub notification payloads, respond to a chargeback dispute (chargeback, pending refund review, pendingRefundReviewNotification, pendingRefundToken, gpc purchases orders review-refund), or check RTDN topic configuration. For release management, see gpc-release-flow. For CI automation, see gpc-ci-integration."
compatibility: "GPC v0.9.82+. Requires authenticated GPC setup (see gpc-setup skill). Subscriptions and IAP require products configured in Google Play Console. v0.9.84+ sends --regions-version to the API on subscription/OTP writes. v0.9.96+ fixes one-time-products create/update and the four single-offer commands (which now require --purchase-option), and adds gpc purchases orders review-refund for chargeback disputes."
metadata:
  version: 0.17.0
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

> **Fixed in v0.9.84:** `--regions-version` is now actually sent to the Google Play API on subscriptions and one-time-products create, update, and offer commands. In v0.9.77-v0.9.83 it was accepted by GPC but silently ignored. Default is `2022/02` if not specified. IAP and subscription `list --json` also now use the unified `{ <key>, nextPageToken, meta.count }` envelope (GPC v0.9.83).

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

### One-time product offers -- single-offer commands (v0.9.96)

Google Play publishes only **batch** endpoints for one-time product offers, so `otp offers get`, `create`, `update`, and `delete` are sent as single-item batch requests and **require `--purchase-option`**. Omitting it fails immediately as a missing-option error, before any API call. The `-` wildcard works only with `offers list` -- run that first if you do not know which purchase option an offer belongs to.

```bash
# Find the purchase option an offer belongs to
gpc otp offers list premium_upgrade

gpc otp offers get premium_upgrade launch_discount --purchase-option buy_once
gpc otp offers create premium_upgrade --file offer.json --purchase-option buy_once
gpc otp offers update premium_upgrade launch_discount --file offer-update.json --purchase-option buy_once
gpc otp offers delete premium_upgrade launch_discount --purchase-option buy_once
```

`offers create` probes for the offer ID first and refuses with `API_ALREADY_EXISTS` (409) rather than overwriting -- the underlying batch endpoint is an upsert. Use `offers update` to change an existing offer.

> **Fixed in v0.9.96:** `gpc one-time-products create` / `update` and the four single-offer commands above previously failed with a route-not-found error (Play serves the write route under a different spelling than the read routes). Requires v0.9.96+.

### Activating/deactivating OTP offers (v0.9.57+)

One-time product offers support explicit activation/deactivation:

```bash
gpc otp offers activate --app com.example.app --product-id sku_id --offer-id offer_id
gpc otp offers deactivate --app com.example.app --product-id sku_id --offer-id offer_id
```

Matches the subscription-offer lifecycle. Without this, OTP offers relied on state being set through batch update calls only.

### OTP offer and purchase-option batch operations (v0.9.79+)

Batch operations on one-time product offers and purchase options:

```bash
# Retrieve multiple OTP offers in one call
gpc one-time-products offers batch-get --product-id <sku> --offer-ids "offer_a,offer_b"

# Update multiple OTP offers from JSON
gpc one-time-products offers batch-update --file otp-offers.json --dry-run
gpc one-time-products offers batch-update --file otp-offers.json

# Bulk activate or deactivate OTP offers
gpc one-time-products offers batch-update-states --file otp-states.json --dry-run
gpc one-time-products offers batch-update-states --file otp-states.json

# Delete multiple OTP offers at once
gpc one-time-products offers batch-delete --product-id <sku> --offer-ids "offer_a,offer_b" --dry-run
gpc one-time-products offers batch-delete --product-id <sku> --offer-ids "offer_a,offer_b"

# Bulk delete purchase options across products
gpc one-time-products purchase-options batch-delete --file po-delete.json --dry-run
gpc one-time-products purchase-options batch-delete --file po-delete.json

# Bulk update purchase-option states (activate/deactivate)
gpc one-time-products purchase-options batch-update-states --file po-states.json --dry-run
gpc one-time-products purchase-options batch-update-states --file po-states.json
```

All batch commands support `--dry-run` and `--json`. These operations cover the full v0.9.79 OTP batch surface: 4 offer methods (`batch-get`, `batch-update`, `batch-update-states`, `batch-delete`) and 2 purchase-option methods (`batch-delete`, `batch-update-states`).

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
# Returns SubscriptionPurchaseV2 with onHoldStateContext, inGracePeriodStateContext (v0.9.76+)
# Both context objects are surfaced in --json output and structured display
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

> **New in v0.9.79:** Orders now expose an `OfferPhaseDetails` type that replaces the flat `offerPhase` field. `OfferPhaseDetails` is a structured object with richer phase information (phase type, cycle counts, and pricing details). The flat `offerPhase` field is deprecated; read from `offerPhaseDetails` in new code.

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

#### F. Chargeback disputes -- `purchases orders review-refund` (v0.9.96+)

When a user disputes a charge with their bank, Play sends a `pendingRefundReviewNotification` RTDN carrying a `pendingRefundToken` and the disputed `orderId`. You have **24 hours** to answer. Play decides the outcome; your preference and evidence are inputs to that decision, not the decision itself.

```bash
# 1. Pull the token out of the notification (full token only in JSON output)
TOKEN=$(gpc rtdn decode "<base64-payload>" --output json \
  | jq -r .pendingRefundReviewNotification.pendingRefundToken)

# 2. Answer the dispute
gpc purchases orders review-refund "GPA.1234-5678-9012-34567" \
  --app com.example.app \
  --pending-refund-token "$TOKEN" \
  --preference decline \
  --sample-content-provided \
  --consumption-percent 82 \
  --usage-events-file ./usage-events.json

# Take no side, no evidence
gpc purchases orders review-refund "GPA.1234-5678-9012-34567" \
  --pending-refund-token "$TOKEN" \
  --preference neutral \
  --no-sample-content-provided
```

| Flag | Required | Notes |
|------|----------|-------|
| `--pending-refund-token` | yes | Token from the `pendingRefundReviewNotification` |
| `--preference` | yes | `approve`, `decline`, or `neutral` |
| `--sample-content-provided` / `--no-sample-content-provided` | yes (exactly one) | Whether a free sample, trial, or functionality info was offered before purchase. Google has no default, so GPC makes you state it |
| `--consumption-percent` | no | How much was consumed, 0-100, decimals allowed (sent as milliunits) |
| `--usage-events-file` | no | JSON **array** of consumption usage events, max 1,000 |

`usage-events.json` uses RFC 3339 timestamps, and `location.regionCode` is a required CLDR region code whenever a location is supplied:

```json
[
  {
    "consumptionTime": "2026-08-30T10:15:00Z",
    "consumptionItemDescription": "Opened chapter 4",
    "obfuscatedAccountId": "user-account-id",
    "ipAddress": "203.0.113.10",
    "location": { "regionCode": "US" }
  }
]
```

Bad input is rejected locally as `ORDER_REVIEW_REFUND_INVALID` (exit 2) before anything is sent. An empty or whitespace-only `--consumption-percent` counts as not provided, so a typo never claims "0% consumed" on your behalf. `--dry-run` previews the request.

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

> **New in v0.9.96:** `gpc rtdn decode` recognises `pendingRefundReviewNotification` (a chargeback sent for your review) and surfaces its `orderId` and `pendingRefundToken` -- the full token is printed only with `--output json`. It also no longer crashes on a partial chargeback notification. Answer within 24 hours with `gpc purchases orders review-refund` (section 5F).

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

### 10. Data safety (v0.9.75+)

Manage your app's Data Safety section declarations via the API:

```bash
# Get current data safety labels
gpc data-safety get

# Update data safety declarations from CSV
gpc data-safety update --file safety.csv
```

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
| Missing `--purchase-option` on `otp offers get/create/update/delete` | v0.9.96 routes these through Play's batch offer endpoints, which need a concrete purchase option | Run `gpc otp offers list <product-id>` to find it; `-` works only on `list` |
| `API_ALREADY_EXISTS` on `otp offers create` | That offer ID already exists; the batch endpoint is an upsert, so GPC probes and refuses rather than overwriting | Use `gpc otp offers update` instead |
| `ORDER_REVIEW_REFUND_INVALID` | `--sample-content-provided` unanswered, `--consumption-percent` outside 0-100, or `--usage-events-file` is not a JSON array of objects | Pass one of `--sample-content-provided` / `--no-sample-content-provided`, use a plain decimal, and make the file an array |

## Related skills

- **gpc-setup** — authentication and configuration required before monetization commands
- **gpc-release-flow** — releasing app updates that include new products or pricing changes
- **gpc-vitals-monitoring** — monitoring reviews that mention billing issues
- **gpc-ci-integration** — automating IAP sync and purchase verification in CI/CD
