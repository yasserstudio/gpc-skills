---
name: gpc-sdk-usage
description: "Use when building applications that programmatically interact with the Google Play Developer API using GPC's TypeScript SDK packages. Make sure to use this skill whenever the user mentions @gpc-cli/api, @gpc-cli/auth, PlayApiClient, createApiClient, resolveAuth, Google Play API client, TypeScript SDK, programmatic access, API client, HTTP client, rate limiter, pagination, edit lifecycle in code, Node.js Google Play, server-side Play Store, backend integration — even if they don't explicitly say 'SDK.' Also trigger when someone wants to build a backend service, custom dashboard, automation script, or any TypeScript/JavaScript application that interacts with Google Play programmatically rather than through the CLI. For CLI usage, see other gpc-* skills. For building plugins, see gpc-plugin-development."
compatibility: "GPC v0.9.9+ (new APIs require v0.9.51+). Requires Node.js 20+, TypeScript 5+. Packages: @gpc-cli/api, @gpc-cli/auth."
metadata:
  version: 1.1.0
---

# gpc-sdk-usage

Use @gpc-cli/api and @gpc-cli/auth as standalone TypeScript SDK packages for programmatic Google Play access.

## When to use

- Building a backend service that interacts with Google Play
- Creating custom dashboards or automation scripts
- Programmatic release management from TypeScript/JavaScript
- Using the typed API client directly (not through the CLI)
- Integrating Google Play operations into a larger application

## Inputs required

- **Node.js 20+** and **TypeScript 5+**
- **@gpc-cli/api** and **@gpc-cli/auth** packages
- **Service account key** — JSON file or raw JSON string

## Procedure

### 0. Install packages

```bash
npm install @gpc-cli/api @gpc-cli/auth
```

These are standalone packages — no need to install the full CLI.

### 1. Authenticate

```typescript
import { resolveAuth } from "@gpc-cli/auth";

// From file path
const auth = await resolveAuth({
  serviceAccountPath: "/path/to/key.json",
});

// From JSON string (e.g., from environment variable)
const auth = await resolveAuth({
  serviceAccountJson: process.env.PLAY_SA_KEY,
});

// From environment (GPC_SERVICE_ACCOUNT or GOOGLE_APPLICATION_CREDENTIALS)
const auth = await resolveAuth();
```

`Read:` `references/auth-patterns.md` for advanced auth patterns and token caching.

### 2. Create API client

```typescript
import { createApiClient } from "@gpc-cli/api";

const client = createApiClient({
  auth,
  maxRetries: 3,
  timeout: 30_000,
});
```

The client provides typed access to all 208 Google Play Developer API v3 endpoints.

`Read:` `references/api-reference.md` for the complete client API with all namespaces and methods.

### 3. Edit lifecycle

Most Google Play operations require an edit session:

```typescript
const APP = "com.example.app";

// 1. Create an edit
const edit = await client.edits.insert(APP);

// 2. Make changes within the edit
const tracks = await client.tracks.list(APP, edit.id);
const details = await client.details.get(APP, edit.id);

// 3. Validate before committing
await client.edits.validate(APP, edit.id);

// 4. Commit the edit (applies all changes)
await client.edits.commit(APP, edit.id);

// Optional: commit with options (v0.9.51+)
await client.edits.commit(APP, edit.id, {
  changesNotSentForReview: true,
  changesInReviewBehavior: "HALT_REVIEW",
});
```

**Important:** Only one edit can be open at a time. Always commit or delete edits.

### 4. Common patterns

#### Upload a release

```typescript
const edit = await client.edits.insert(APP);

// Upload the bundle
const bundle = await client.bundles.upload(APP, edit.id, "app-release.aab");

// Upload with device tier config (v0.9.51+)
const bundle2 = await client.bundles.upload(APP, edit.id, "app-release.aab", {
  deviceTierConfigId: "my-tier-config",
});

// Set the track
await client.tracks.update(APP, edit.id, "beta", {
  track: "beta",
  releases: [{
    versionCodes: [bundle.versionCode],
    status: "completed",
    releaseNotes: [
      { language: "en-US", text: "Bug fixes and improvements" },
    ],
  }],
});

// Commit
await client.edits.validate(APP, edit.id);
await client.edits.commit(APP, edit.id);
```

#### List and respond to reviews

```typescript
// No edit needed for reviews
const reviews = await client.reviews.list(APP, {
  maxResults: 50,
  translationLanguage: "en",
  startIndex: 0,  // pagination offset (v0.9.51+)
});

for (const review of reviews.reviews ?? []) {
  if (review.comments?.[0]?.userComment?.starRating <= 2) {
    await client.reviews.reply(APP, review.reviewId, "Thanks for the feedback!");
  }
}
```

#### Manage subscriptions

```typescript
// No edit needed for subscriptions
const subs = await client.subscriptions.list(APP);

// Get a specific subscription
const sub = await client.subscriptions.get(APP, "premium_monthly");

// Update with mutation options (v0.9.51+)
await client.subscriptions.update(APP, "premium_monthly", data, "price", {
  allowMissing: true,
  latencyTolerance: "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
});

// Activate a base plan
await client.subscriptions.activateBasePlan(APP, "premium_monthly", "monthly");
```

#### Verify purchases

```typescript
// No edit needed for purchases
const purchase = await client.purchases.getProduct(APP, "coins_100", purchaseToken);

if (purchase.purchaseState === 0 && purchase.acknowledgementState === 0) {
  await client.purchases.acknowledgeProduct(APP, "coins_100", purchaseToken);
}
```

#### Upload deobfuscation files (v0.9.51+)

```typescript
// Upload ProGuard mapping
await client.deobfuscation.upload(APP, edit.id, versionCode, "mapping.txt", "proguard");

// Upload native debug symbols
await client.deobfuscation.upload(APP, edit.id, versionCode, "symbols.zip", "nativeCode");
```

#### Manage expansion files (v0.9.51+)

```typescript
// Get expansion file info
const obb = await client.expansionFiles.get(APP, edit.id, versionCode, "main");

// Upload a new expansion file
const uploaded = await client.expansionFiles.upload(APP, edit.id, versionCode, "main", "main.obb");

// Patch expansion file references
await client.expansionFiles.patch(APP, edit.id, versionCode, "main", {
  referencesVersion: 10,
});
```

#### List one-time products with pagination (v0.9.51+)

```typescript
const products = await client.oneTimeProducts.list(APP, {
  pageSize: 25,
  pageToken: nextToken,
});
```

### 5. Pagination

Use the built-in pagination utilities for large result sets:

```typescript
import { paginate, paginateAll } from "@gpc-cli/api";

// Async generator (stream results)
for await (const page of paginate(
  (token) => client.subscriptions.list(APP, { pageToken: token }),
  { limit: 100 },
)) {
  for (const sub of page) {
    console.log(sub.productId);
  }
}

// Collect all results
const all = await paginateAll(
  (token) => client.subscriptions.list(APP, { pageToken: token }),
);
```

### 6. Rate limiting

Since v0.9.47, `createApiClient()` automatically applies rate limiting to all API calls using Google's 6-bucket model (3,000 queries/min each). No manual configuration needed:

```typescript
// Rate limiting is automatic — all calls are throttled by resource type
const client = createApiClient({ auth });
// Buckets: edits, purchases, reviews, reporting, monetization, default
```

To customize rate limits (e.g., for shared quota across multiple processes):

```typescript
import { createRateLimiter, RATE_LIMIT_BUCKETS } from "@gpc-cli/api";

// Override specific buckets
const limiter = createRateLimiter([
  { ...RATE_LIMIT_BUCKETS.edits, maxTokens: 1500 },     // Half of default
  { ...RATE_LIMIT_BUCKETS.purchases, maxTokens: 1500 },
]);

const client = createApiClient({ auth, rateLimiter: limiter });
```

The `resolveBucket(path)` function maps API paths to buckets automatically:
- `/edits/` paths → `edits` bucket
- `/purchases/`, `/orders` → `purchases` bucket
- `/reviews` → `reviews` bucket
- Reporting API → `reporting` bucket
- `/subscriptions`, `/oneTimeProducts`, `/inappproducts` → `monetization` bucket
- Everything else → `default` bucket

### 7. Error handling

```typescript
import { PlayApiError } from "@gpc-cli/api";
import { AuthError } from "@gpc-cli/auth";

try {
  await client.edits.insert(APP);
} catch (error) {
  if (error instanceof AuthError) {
    console.error(`Auth failed: ${error.code}`);
  } else if (error instanceof PlayApiError) {
    console.error(`API error ${error.status}: ${error.code}`);
    console.error(`Suggestion: ${error.suggestion}`);
  }
}
```

## Verification

- `resolveAuth()` returns a valid auth client
- `createApiClient({ auth })` creates a working client
- `client.edits.insert(APP)` successfully opens an edit
- API calls return typed responses
- Error handling catches `PlayApiError` and `AuthError`

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `AUTH_NO_CREDENTIALS` | No auth source found | Pass `serviceAccountPath` or set `GPC_SERVICE_ACCOUNT` |
| `AUTH_INVALID_KEY` | Bad JSON in key file | Re-download from Google Cloud Console |
| Edit insert fails with 403 | Service account lacks API access | Enable Google Play Developer API in GCP |
| Concurrent edit conflict | Another edit is open | Commit or delete the existing edit first |
| `PlayApiError` with status 429 | Rate limited | Use `createRateLimiter()` with appropriate buckets |
| Types not resolving | Wrong TypeScript config | Ensure `moduleResolution: "bundler"` or `"node16"` |

## Related skills

- **gpc-setup** — service account creation and auth configuration
- **gpc-plugin-development** — building plugins that use the SDK internally
- **gpc-troubleshooting** — interpreting API error codes
