# Plugin Hooks Reference

Complete type signatures and behavior for all 6 GPC plugin hooks.

## Hook execution order

```
Command invoked
  │
  ├─ beforeCommand(event)
  │
  ├─ For each API call:
  │   ├─ beforeRequest(requestEvent)
  │   ├─ [HTTP request]
  │   └─ afterResponse(requestEvent, responseEvent)
  │
  ├─ On success: afterCommand(event, result)
  │  On failure: onError(event, error)
  │
  └─ Done
```

Hooks run sequentially in registration order across plugins.

## 1. beforeCommand

Runs before any GPC command executes.

```typescript
hooks.beforeCommand(async (event: CommandEvent) => {
  // event.command — "releases upload", "vitals crashes", etc.
  // event.args — resolved arguments { track: "beta", app: "com.example.app" }
  // event.app — package name (if available)
  // event.startedAt — Date when command started
});
```

**Behavior:** Errors in this hook propagate and can prevent the command from running.

**Use cases:** Validation, prerequisite checks, command logging.

## 2. afterCommand

Runs after a command completes successfully.

```typescript
hooks.afterCommand(async (event: CommandEvent, result: CommandResult) => {
  // result.success — always true in this hook
  // result.data — command output data (varies by command)
  // result.durationMs — execution time in milliseconds
  // result.exitCode — 0 for success
});
```

**Behavior:** Errors in this hook are logged but don't change the command's exit code.

**Use cases:** Notifications (Slack, email), metrics, audit logging, CI step summaries.

## 3. onError

Runs when a command fails.

```typescript
hooks.onError(async (event: CommandEvent, error: PluginError) => {
  // error.code — "API_FORBIDDEN", "AUTH_FAILED", etc.
  // error.message — human-readable error description
  // error.exitCode — 1-10 (see exit code reference)
  // error.cause — original Error object (if available)
});
```

**Behavior:** Errors in this handler are **swallowed** to prevent cascading failures.

**Use cases:** Error reporting, alerting, logging failures to external systems.

## 4. beforeRequest

Runs before each HTTP request to the Google Play API.

```typescript
hooks.beforeRequest(async (event: RequestEvent) => {
  // event.method — "GET", "POST", "PUT", "PATCH", "DELETE"
  // event.path — API path (relative to base URL)
  // event.startedAt — Date
});
```

**Behavior:** Errors are **swallowed** — never blocks API calls.

**Use cases:** Request tracing, custom headers, API call logging.

## 5. afterResponse

Runs after each HTTP response from the Google Play API.

```typescript
hooks.afterResponse(async (event: RequestEvent, response: ResponseEvent) => {
  // response.status — HTTP status code (200, 403, 404, etc.)
  // response.durationMs — request duration
  // response.ok — true if 2xx status
});
```

**Behavior:** Errors are **swallowed**.

**Use cases:** Performance monitoring, rate-limit tracking, API metrics.

## 6. registerCommands

Register custom CLI commands from your plugin.

```typescript
hooks.registerCommands((registry: CommandRegistry) => {
  registry.add({
    name: "my-command",
    description: "Does something custom",
    options: [
      { flags: "--format <type>", description: "Output format" },
    ],
    action: async (args) => {
      console.log("Running custom command with:", args);
    },
  });
});
```

**Behavior:** Commands are registered synchronously during plugin load.

**Use cases:** Domain-specific tools, workflow shortcuts, report generators.

## Error handling summary

| Hook | Error behavior |
|------|---------------|
| `beforeCommand` | **Propagates** — can block the command |
| `afterCommand` | Logged, swallowed |
| `onError` | Swallowed (prevents cascading) |
| `beforeRequest` | Swallowed (never blocks API calls) |
| `afterResponse` | Swallowed |
| `registerCommands` | Propagates during load |

## Example: Slack notification plugin

```typescript
import type { GpcPlugin } from "@gpc-cli/plugin-sdk";

export const plugin: GpcPlugin = {
  name: "gpc-plugin-slack",
  version: "1.0.0",
  register(hooks) {
    hooks.afterCommand(async (event, result) => {
      if (event.command.startsWith("releases")) {
        await fetch(process.env.SLACK_WEBHOOK!, {
          method: "POST",
          body: JSON.stringify({
            text: `✓ gpc ${event.command} completed in ${result.durationMs}ms`,
          }),
        });
      }
    });

    hooks.onError(async (event, error) => {
      await fetch(process.env.SLACK_WEBHOOK!, {
        method: "POST",
        body: JSON.stringify({
          text: `✗ gpc ${event.command} failed: ${error.code} — ${error.message}`,
        }),
      });
    });
  },
};
```
