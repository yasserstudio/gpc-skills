# Auth Patterns for SDK Usage

Advanced authentication patterns when using @gpc-cli/auth programmatically.

## Resolution order

`resolveAuth()` tries credentials in this order:

1. `serviceAccountJson` option (raw JSON string)
2. `serviceAccountPath` option (file path)
3. `GPC_SERVICE_ACCOUNT` environment variable
4. `GOOGLE_APPLICATION_CREDENTIALS` environment variable
5. Application Default Credentials (ADC)

## Pattern 1: Service account from file

```typescript
import { resolveAuth } from "@gpc-cli/auth";

const auth = await resolveAuth({
  serviceAccountPath: "/path/to/key.json",
});

const token = await auth.getAccessToken();
const email = auth.getClientEmail();
```

## Pattern 2: Service account from environment

```typescript
// Set GPC_SERVICE_ACCOUNT to the JSON content or file path
const auth = await resolveAuth();
```

Works in CI where the secret is injected as an env var.

## Pattern 3: Application Default Credentials

```typescript
// Uses gcloud auth application-default login locally
// or metadata server on GCP
const auth = await resolveAuth();
```

No key file needed — uses the ambient credentials.

## Pattern 4: Token caching

```typescript
const auth = await resolveAuth({
  serviceAccountPath: "/path/to/key.json",
  cachePath: "/tmp/gpc-cache",
});

// First call: fetches token from Google
// Subsequent calls: returns cached token
// Auto-refreshes when token expires (1 hour)
const token = await auth.getAccessToken();
```

## Pattern 5: Multiple auth clients

```typescript
const mainAuth = await resolveAuth({
  serviceAccountPath: "/keys/main.json",
});

const clientAuth = await resolveAuth({
  serviceAccountPath: "/keys/client.json",
});

const mainClient = createApiClient({ auth: mainAuth });
const clientClient = createApiClient({ auth: clientAuth });
```

## Pattern 6: Clear cached tokens

```typescript
import { clearTokenCache } from "@gpc-cli/auth";

await clearTokenCache("/tmp/gpc-cache");
```

## Error handling

```typescript
import { AuthError } from "@gpc-cli/auth";

try {
  const auth = await resolveAuth();
} catch (error) {
  if (error instanceof AuthError) {
    switch (error.code) {
      case "AUTH_NO_CREDENTIALS":
        console.error("No credentials found");
        break;
      case "AUTH_INVALID_KEY":
        console.error("Key file is malformed");
        break;
      case "AUTH_FILE_NOT_FOUND":
        console.error("Key file doesn't exist");
        break;
      case "AUTH_TOKEN_FAILED":
        console.error("Couldn't get access token");
        break;
    }
  }
}
```
