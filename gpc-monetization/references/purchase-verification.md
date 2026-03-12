# Purchase Verification

Server-side purchase verification patterns using GPC.

## Why verify server-side

- Client-side purchase data can be tampered with
- Server verification confirms the purchase is genuine
- Required for acknowledging purchases (must acknowledge within 3 days)
- Needed for granting entitlements, managing consumables, and handling subscriptions

## Product purchase verification

```bash
# Verify a one-time purchase
gpc purchases get <product-id> <purchase-token>

# JSON output for parsing
gpc purchases get <product-id> <purchase-token> --json
```

### Purchase states

| State | Value | Meaning |
|-------|-------|---------|
| `PURCHASED` | 0 | Purchase completed |
| `CANCELED` | 1 | Purchase cancelled |
| `PENDING` | 2 | Purchase pending (e.g., slow payment method) |

### Acknowledgement states

| State | Value | Meaning |
|-------|-------|---------|
| `NOT_ACKNOWLEDGED` | 0 | Not yet acknowledged — must acknowledge within 3 days |
| `ACKNOWLEDGED` | 1 | Already acknowledged |

### Acknowledgement flow

```bash
# 1. Verify the purchase
gpc purchases get coins_100 <token> --json

# 2. Check purchaseState=0 and acknowledgementState=0

# 3. Acknowledge with optional developer payload
gpc purchases acknowledge coins_100 <token> --payload "order-abc-123"
```

If a purchase is not acknowledged within 3 days, Google automatically refunds it.

### Consumption flow (consumable products)

```bash
# 1. Verify and acknowledge
gpc purchases get coins_100 <token> --json
gpc purchases acknowledge coins_100 <token>

# 2. Grant the item to the user in your backend

# 3. Consume to allow re-purchase
gpc purchases consume coins_100 <token>
```

## Subscription purchase verification

```bash
# Get subscription details (v2 API)
gpc purchases subscription get <purchase-token> --json
```

### Subscription states (v2)

| State | Meaning |
|-------|---------|
| `SUBSCRIPTION_STATE_ACTIVE` | Active and billing |
| `SUBSCRIPTION_STATE_CANCELED` | User cancelled, active until period end |
| `SUBSCRIPTION_STATE_IN_GRACE_PERIOD` | Payment failed, grace period active |
| `SUBSCRIPTION_STATE_ON_HOLD` | Payment failed, account on hold |
| `SUBSCRIPTION_STATE_PAUSED` | User paused the subscription |
| `SUBSCRIPTION_STATE_EXPIRED` | Subscription expired |
| `SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED` | Pending purchase was cancelled |

### Subscription lifecycle management

```bash
# Cancel (takes effect at end of billing period)
gpc purchases subscription cancel <subscription-id> <token>

# Defer expiry (extend the subscription)
gpc purchases subscription defer <subscription-id> <token> \
  --expiry 2025-12-31T00:00:00Z

# Revoke (immediate termination, v2 API)
gpc purchases subscription revoke <token>
```

## Voided purchases

Monitor refunds, chargebacks, and revoked purchases:

```bash
# List voided purchases in a date range
gpc purchases voided --start-time 2025-01-01 --end-time 2025-03-01

# With pagination
gpc purchases voided --start-time 2025-01-01 --max-results 100

# JSON for processing
gpc purchases voided --start-time 2025-01-01 --json
```

### Void reasons

| Reason | Meaning |
|--------|---------|
| `OTHER` | Unspecified |
| `REMORSE` | User requested refund |
| `NOT_RECEIVED` | User claims item not received |
| `DEFECTIVE` | User claims item is defective |
| `ACCIDENTAL_PURCHASE` | Accidental purchase |
| `FRAUD` | Fraudulent transaction |
| `FRIENDLY_FRAUD` | Chargeback |

## Refunds

```bash
# Full refund
gpc purchases orders refund <order-id> --full-refund

# Prorated refund (for subscriptions)
gpc purchases orders refund <order-id> --prorated-refund

# Preview
gpc purchases orders refund <order-id> --full-refund --dry-run
```

## CI/CD integration

Automate purchase verification in your backend deployment:

```bash
# Verify a test purchase in CI
gpc purchases get $PRODUCT_ID $TEST_TOKEN --json | jq '.purchaseState'
```

Exit code 0 means the purchase exists. Check the JSON `purchaseState` field for the actual state.
