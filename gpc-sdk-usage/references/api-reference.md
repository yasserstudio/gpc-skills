# API Client Reference

Complete reference for the PlayApiClient returned by `createApiClient()`. Covers all 208 endpoints.

## Client namespaces

### edits — Edit sessions

```typescript
client.edits.insert(packageName): Promise<AppEdit>
client.edits.get(packageName, editId): Promise<AppEdit>
client.edits.validate(packageName, editId): Promise<void>
client.edits.commit(packageName, editId, options?): Promise<void>  // options: EditCommitOptions
client.edits.delete(packageName, editId): Promise<void>
```

### details — App details

```typescript
client.details.get(packageName, editId): Promise<AppDetails>
client.details.update(packageName, editId, details): Promise<AppDetails>
client.details.patch(packageName, editId, partial): Promise<AppDetails>
```

### bundles — AAB uploads

```typescript
client.bundles.list(packageName, editId): Promise<BundleList>
client.bundles.upload(packageName, editId, filePath, deviceTierConfigId?): Promise<Bundle>
```

### tracks — Release tracks

```typescript
client.tracks.list(packageName, editId): Promise<Track[]>
client.tracks.get(packageName, editId, track): Promise<Track>
client.tracks.update(packageName, editId, track, release): Promise<Track>
client.tracks.patch(packageName, editId, track, release): Promise<Track>
```

### releases — Release lifecycle (no edit needed)

```typescript
client.releases.list(packageName, track): Promise<ReleaseSummary[]>
```

### listings — Store listings

```typescript
client.listings.list(packageName, editId): Promise<Listing[]>
client.listings.get(packageName, editId, language): Promise<Listing>
client.listings.update(packageName, editId, language, listing): Promise<Listing>
client.listings.patch(packageName, editId, language, partial): Promise<Listing>
client.listings.delete(packageName, editId, language): Promise<void>
client.listings.deleteAll(packageName, editId): Promise<void>
```

### images — Store images

```typescript
client.images.list(packageName, editId, language, imageType): Promise<Image[]>
client.images.upload(packageName, editId, language, imageType, filePath): Promise<Image>
client.images.delete(packageName, editId, language, imageType, imageId): Promise<void>
client.images.deleteAll(packageName, editId, language, imageType): Promise<void>
```

### reviews — User reviews (no edit needed)

```typescript
client.reviews.list(packageName, options?): Promise<ReviewsResponse>  // options accepts startIndex
client.reviews.get(packageName, reviewId, translationLanguage?): Promise<Review>
client.reviews.reply(packageName, reviewId, replyText): Promise<ReviewReply>
```

### subscriptions — Subscriptions (no edit needed)

```typescript
client.subscriptions.list(packageName, options?): Promise<SubscriptionList>
client.subscriptions.get(packageName, productId): Promise<Subscription>
client.subscriptions.create(packageName, data): Promise<Subscription>
client.subscriptions.update(packageName, productId, data, updateMask?, mutationOptions?): Promise<Subscription>  // mutationOptions: MutationOptions
client.subscriptions.delete(packageName, productId): Promise<void>
client.subscriptions.batchGet(packageName, productIds): Promise<Subscription[]>
client.subscriptions.batchUpdate(packageName, requests): Promise<SubscriptionsBatchUpdateResponse>
client.subscriptions.activateBasePlan(packageName, productId, basePlanId): Promise<void>
client.subscriptions.deactivateBasePlan(packageName, productId, basePlanId): Promise<void>
client.subscriptions.deleteBasePlan(packageName, productId, basePlanId): Promise<void>
client.subscriptions.migratePrices(packageName, productId, basePlanId, body): Promise<void>
client.subscriptions.listOffers(packageName, productId, basePlanId): Promise<Offer[]>
client.subscriptions.getOffer(packageName, productId, basePlanId, offerId): Promise<Offer>
client.subscriptions.createOffer(packageName, productId, basePlanId, data): Promise<Offer>
client.subscriptions.updateOffer(packageName, productId, basePlanId, offerId, data, updateMask?): Promise<Offer>
client.subscriptions.deleteOffer(packageName, productId, basePlanId, offerId): Promise<void>
client.subscriptions.activateOffer(packageName, productId, basePlanId, offerId): Promise<void>
client.subscriptions.deactivateOffer(packageName, productId, basePlanId, offerId): Promise<void>
```

### inappproducts — IAP (no edit needed)

```typescript
client.inappproducts.list(packageName, options?): Promise<InAppProductList>
client.inappproducts.get(packageName, sku): Promise<InAppProduct>
client.inappproducts.create(packageName, data): Promise<InAppProduct>
client.inappproducts.update(packageName, sku, data): Promise<InAppProduct>
client.inappproducts.delete(packageName, sku): Promise<void>
client.inappproducts.batchDelete(packageName, skus): Promise<void>
```

### purchases — Purchase verification (no edit needed)

```typescript
client.purchases.getProduct(packageName, productId, token): Promise<ProductPurchase>
client.purchases.getProductV2(packageName, token): Promise<ProductPurchaseV2>
client.purchases.acknowledgeProduct(packageName, productId, token, body?): Promise<void>
client.purchases.consumeProduct(packageName, productId, token): Promise<void>
client.purchases.getSubscriptionV2(packageName, token): Promise<SubscriptionPurchaseV2>
client.purchases.getSubscriptionV1(packageName, subscriptionId, token): Promise<SubscriptionPurchase>
client.purchases.cancelSubscription(packageName, subscriptionId, token): Promise<void>
client.purchases.cancelSubscriptionV2(packageName, token, body?): Promise<void>
client.purchases.deferSubscription(packageName, subscriptionId, token, body): Promise<DeferralInfo>
client.purchases.deferSubscriptionV2(packageName, token, body): Promise<DeferralResponse>
client.purchases.revokeSubscriptionV2(packageName, token): Promise<void>
client.purchases.refundSubscriptionV2(packageName, token): Promise<void>
client.purchases.acknowledgeSubscription(packageName, subscriptionId, token, body?): Promise<void>
client.purchases.listVoided(packageName, options?): Promise<VoidedPurchaseList>
```

### orders — Orders and refunds (no edit needed)

```typescript
client.orders.get(packageName, orderId): Promise<Order>
client.orders.batchGet(packageName, orderIds): Promise<Order[]>
client.orders.refund(packageName, orderId, body?): Promise<void>
```

### monetization — Pricing (no edit needed)

```typescript
client.monetization.convertRegionPrices(packageName, price): Promise<RegionPrices>
```

### deobfuscation -- Deobfuscation files (requires edit, v0.9.51+)

```typescript
client.deobfuscation.upload(packageName, editId, versionCode, filePath, fileType?): Promise<DeobfuscationFile>
// fileType: DeobfuscationFileType ('proguard' | 'nativeCode')
```

### expansionFiles -- APK expansion files (requires edit, v0.9.51+)

```typescript
client.expansionFiles.get(packageName, editId, versionCode, expansionFileType): Promise<ExpansionFile>
client.expansionFiles.update(packageName, editId, versionCode, expansionFileType, data): Promise<ExpansionFile>
client.expansionFiles.patch(packageName, editId, versionCode, expansionFileType, partial): Promise<ExpansionFile>
client.expansionFiles.upload(packageName, editId, versionCode, expansionFileType, filePath): Promise<ExpansionFile>
```

### oneTimeProducts -- One-time products (no edit needed, v0.9.51+)

```typescript
client.oneTimeProducts.list(packageName, options?): Promise<OneTimeProductList>
// options accepts pageSize and pageToken for pagination
```

### testers -- Beta testers (requires edit)

```typescript
client.testers.get(packageName, editId, track): Promise<Testers>
client.testers.update(packageName, editId, track, testers): Promise<Testers>
```

## Types (v0.9.51+)

```typescript
// Options for edits.commit()
type EditCommitOptions = {
  changesNotSentForReview?: boolean;
  changesInReviewBehavior?: "UNSPECIFIED" | "HALT_REVIEW";
};

// Options for subscriptions.update() and similar mutation endpoints
type MutationOptions = {
  allowMissing?: boolean;
  latencyTolerance?: ProductUpdateLatencyTolerance;
};

type ProductUpdateLatencyTolerance =
  | "PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED"
  | "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE"
  | "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT";

// File type for deobfuscation uploads
type DeobfuscationFileType = "proguard" | "nativeCode";
```

## Utilities

### Pagination

```typescript
import { paginate, paginateAll } from "@gpc-cli/api";

// Async generator
for await (const page of paginate(fetchFn, { limit: 100 })) { ... }

// Collect all
const all = await paginateAll(fetchFn);
```

### Rate limiting

```typescript
import { createRateLimiter, RATE_LIMIT_BUCKETS } from "@gpc-cli/api";

const limiter = createRateLimiter([
  RATE_LIMIT_BUCKETS.default,       // 200 req/s
  RATE_LIMIT_BUCKETS.reviewsGet,    // 200 req/hour
  RATE_LIMIT_BUCKETS.reviewsPost,   // 2000 req/day
  RATE_LIMIT_BUCKETS.voidedBurst,   // 30 req/30s
  RATE_LIMIT_BUCKETS.voidedDaily,   // 6000 req/day
]);
```

## Client options

```typescript
createApiClient({
  auth,                              // Required: AuthClient
  maxRetries: 3,                     // Retry on 5xx and network errors
  timeout: 30_000,                   // Request timeout in ms
  baseDelay: 1_000,                  // Initial retry backoff
  maxDelay: 60_000,                  // Maximum retry backoff
  rateLimiter: createRateLimiter(),  // Optional rate limiter
  onRetry: (entry) => { ... },       // Retry event callback
});
```
