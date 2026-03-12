# API Client Reference

Complete reference for the PlayApiClient returned by `createApiClient()`.

## Client namespaces

### edits — Edit sessions

```typescript
client.edits.insert(packageName): Promise<AppEdit>
client.edits.get(packageName, editId): Promise<AppEdit>
client.edits.validate(packageName, editId): Promise<void>
client.edits.commit(packageName, editId): Promise<void>
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
client.bundles.upload(packageName, editId, filePath): Promise<Bundle>
```

### tracks — Release tracks

```typescript
client.tracks.list(packageName, editId): Promise<Track[]>
client.tracks.get(packageName, editId, track): Promise<Track>
client.tracks.update(packageName, editId, track, release): Promise<Track>
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
client.reviews.list(packageName, options?): Promise<ReviewsResponse>
client.reviews.get(packageName, reviewId, translationLanguage?): Promise<Review>
client.reviews.reply(packageName, reviewId, replyText): Promise<ReviewReply>
```

### subscriptions — Subscriptions (no edit needed)

```typescript
client.subscriptions.list(packageName, options?): Promise<SubscriptionList>
client.subscriptions.get(packageName, productId): Promise<Subscription>
client.subscriptions.create(packageName, data): Promise<Subscription>
client.subscriptions.update(packageName, productId, data, updateMask?): Promise<Subscription>
client.subscriptions.delete(packageName, productId): Promise<void>
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
```

### purchases — Purchase verification (no edit needed)

```typescript
client.purchases.getProduct(packageName, productId, token): Promise<ProductPurchase>
client.purchases.acknowledgeProduct(packageName, productId, token, body?): Promise<void>
client.purchases.consumeProduct(packageName, productId, token): Promise<void>
client.purchases.getSubscriptionV2(packageName, token): Promise<SubscriptionPurchaseV2>
client.purchases.getSubscriptionV1(packageName, subscriptionId, token): Promise<SubscriptionPurchase>
client.purchases.cancelSubscription(packageName, subscriptionId, token): Promise<void>
client.purchases.deferSubscription(packageName, subscriptionId, token, body): Promise<DeferralInfo>
client.purchases.revokeSubscriptionV2(packageName, token): Promise<void>
client.purchases.listVoided(packageName, options?): Promise<VoidedPurchaseList>
```

### orders — Refunds (no edit needed)

```typescript
client.orders.refund(packageName, orderId, body?): Promise<void>
```

### monetization — Pricing (no edit needed)

```typescript
client.monetization.convertRegionPrices(packageName, price): Promise<RegionPrices>
```

### testers — Beta testers (requires edit)

```typescript
client.testers.get(packageName, editId, track): Promise<Testers>
client.testers.update(packageName, editId, track, testers): Promise<Testers>
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
