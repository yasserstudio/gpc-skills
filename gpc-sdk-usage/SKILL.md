---
name: gpc-sdk-usage
description: "Use when building applications that programmatically interact with the Google Play Developer API using GPC's TypeScript SDK packages. Make sure to use this skill whenever the user mentions @gpc-cli/api, @gpc-cli/auth, PlayApiClient, createApiClient, resolveAuth, Google Play API client, TypeScript SDK, programmatic access, API client, HTTP client, rate limiter, pagination, edit lifecycle in code, Node.js Google Play, server-side Play Store, backend integration — even if they don't explicitly say 'SDK.' Also trigger when someone wants to build a backend service, custom dashboard, automation script, or any TypeScript/JavaScript application that interacts with Google Play programmatically rather than through the CLI. For CLI usage, see other gpc-* skills. For building plugins, see gpc-plugin-development."
compatibility: "GPC v0.9.9+. Requires Node.js 20+, TypeScript 5+. Packages: @gpc-cli/api, @gpc-cli/auth."
metadata:
  version: 1.0.0
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

The client provides typed access to all Google Play Developer API v3 endpoints.

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
```

**Important:** Only one edit can be open at a time. Always commit or delete edits.

### 4. Common patterns

#### Upload a release

```typescript
const edit = await client.edits.insert(APP);

// Upload the bundle
const bundle = await client.bundles.upload(APP, edit.id, "app-release.aab");

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

Configure rate limits to avoid API throttling:

```typescript
import { createRateLimiter, RATE_LIMIT_BUCKETS } from "@gpc-cli/api";

const limiter = createRateLimiter([
  RATE_LIMIT_BUCKETS.default,
  RATE_LIMIT_BUCKETS.reviewsGet,
  RATE_LIMIT_BUCKETS.reviewsPost,
]);

const client = createApiClient({ auth, rateLimiter: limiter });
```

### 7. Error handling

```typescript
import { ApiError } from "@gpc-cli/api";
import { AuthError } from "@gpc-cli/auth";

try {
  await client.edits.insert(APP);
} catch (error) {
  if (error instanceof AuthError) {
    console.error(`Auth failed: ${error.code}`);
  } else if (error instanceof ApiError) {
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
- Error handling catches `ApiError` and `AuthError`

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `AUTH_NO_CREDENTIALS` | No auth source found | Pass `serviceAccountPath` or set `GPC_SERVICE_ACCOUNT` |
| `AUTH_INVALID_KEY` | Bad JSON in key file | Re-download from Google Cloud Console |
| Edit insert fails with 403 | Service account lacks API access | Enable Google Play Developer API in GCP |
| Concurrent edit conflict | Another edit is open | Commit or delete the existing edit first |
| `ApiError` with status 429 | Rate limited | Use `createRateLimiter()` with appropriate buckets |
| Types not resolving | Wrong TypeScript config | Ensure `moduleResolution: "bundler"` or `"node16"` |

## Related skills

- **gpc-setup** — service account creation and auth configuration
- **gpc-plugin-development** — building plugins that use the SDK internally
- **gpc-troubleshooting** — interpreting API error codes
