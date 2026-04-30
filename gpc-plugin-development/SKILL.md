---
name: gpc-plugin-development
description: "Use when building, extending, or debugging GPC plugins. Make sure to use this skill whenever the user mentions gpc plugins, plugin SDK, @gpc-cli/plugin-sdk, plugin hooks, plugin development, plugin scaffolding, gpc plugins init, beforeCommand, afterCommand, onError, beforeRequest, afterResponse, registerCommands, plugin permissions, plugin manifest, custom commands, plugin-ci, extend GPC, GPC addon — even if they don't explicitly say 'plugin.' Also trigger when someone wants to add custom behavior to GPC, integrate GPC with Slack or other services, build CI/CD extensions, hook into the command lifecycle, or register new CLI commands. For using the built-in CI plugin, see gpc-ci-integration."
compatibility: "GPC v0.9.9+. Requires Node.js 20+, TypeScript 5+. Plugin SDK: @gpc-cli/plugin-sdk package."
metadata:
  version: 1.1.0
---

# gpc-plugin-development

Build and publish GPC plugins using the @gpc-cli/plugin-sdk.

## When to use

- Building a new GPC plugin
- Adding custom hooks (notifications, logging, metrics)
- Registering custom CLI commands
- Understanding the plugin lifecycle and permission system
- Debugging plugin loading or hook execution
- Publishing a plugin to npm

## Inputs required

- **Node.js 20+** and **TypeScript 5+**
- **@gpc-cli/plugin-sdk** package (peer dependency)
- **Plugin name** — `@gpc-cli/plugin-*` (first-party) or `gpc-plugin-*` (third-party)

## Procedure

### 0. Scaffold a new plugin

```bash
# Generate plugin boilerplate
gpc plugins init my-notifier --description "Send Slack notifications on release"

# This creates:
# gpc-plugin-my-notifier/
# ├── package.json
# ├── tsconfig.json
# ├── src/index.ts
# └── tests/plugin.test.ts
```

Or manually:

```bash
mkdir gpc-plugin-my-notifier && cd gpc-plugin-my-notifier
npm init -y
npm install --save-peer @gpc-cli/plugin-sdk
npm install --save-dev typescript vitest
```

### 1. Implement the plugin interface

Every plugin exports a `GpcPlugin` object:

```typescript
import type { GpcPlugin, PluginHooks } from "@gpc-cli/plugin-sdk";

export const plugin: GpcPlugin = {
  name: "gpc-plugin-my-notifier",
  version: "1.0.0",
  register(hooks: PluginHooks) {
    // Register your hooks here
    hooks.afterCommand(async (event, result) => {
      if (event.command === "releases upload" && result.success) {
        console.log(`✓ Upload complete in ${result.durationMs}ms`);
      }
    });
  },
};

export default plugin;
```

`Read:` `references/hooks-reference.md` for all 6 hook types with full type signatures.

### 2. Available lifecycle hooks

Register hooks inside the `register()` method:

```typescript
register(hooks: PluginHooks) {
  // Before any command runs
  hooks.beforeCommand(async (event) => {
    console.log(`Running: gpc ${event.command}`);
  });

  // After successful command
  hooks.afterCommand(async (event, result) => {
    console.log(`Done: ${result.durationMs}ms, exit ${result.exitCode}`);
  });

  // On command failure
  hooks.onError(async (event, error) => {
    console.error(`Failed: ${error.code} — ${error.message}`);
  });

  // Before each API request
  hooks.beforeRequest(async (event) => {
    console.log(`API: ${event.method} ${event.path}`);
  });

  // After each API response
  hooks.afterResponse(async (event, response) => {
    console.log(`API: ${response.status} in ${response.durationMs}ms`);
  });

  // Register custom CLI commands
  hooks.registerCommands((registry) => {
    registry.add({
      name: "notify",
      description: "Send a test notification",
      action: async () => {
        console.log("Notification sent!");
      },
    });
  });
}
```

### 3. Declare permissions (third-party plugins)

Third-party plugins (`gpc-plugin-*`) must declare permissions:

```json
{
  "gpc": {
    "permissions": [
      "hooks:afterCommand",
      "hooks:onError",
      "api:read"
    ]
  }
}
```

`Read:` `references/permissions-system.md` for the full permission list and trust model.

Available permissions:

| Permission | Allows |
|-----------|--------|
| `read:config` | Read .gpcrc.json |
| `write:config` | Modify config |
| `read:auth` | Access credentials |
| `api:read` | Make read API calls |
| `api:write` | Make write API calls |
| `commands:register` | Register new commands |
| `hooks:beforeCommand` | Hook before commands |
| `hooks:afterCommand` | Hook after commands |
| `hooks:onError` | Hook on errors |
| `hooks:beforeRequest` | Hook before API requests |
| `hooks:afterResponse` | Hook after API responses |

First-party plugins (`@gpc-cli/*`) are auto-trusted — no permissions needed.

### 4. Test your plugin

```typescript
// tests/plugin.test.ts
import { describe, it, expect, vi } from "vitest";
import { plugin } from "../src/index.js";

describe("my-notifier plugin", () => {
  it("has required fields", () => {
    expect(plugin.name).toBe("gpc-plugin-my-notifier");
    expect(plugin.version).toBeDefined();
    expect(typeof plugin.register).toBe("function");
  });

  it("registers afterCommand hook", () => {
    const hooks = {
      beforeCommand: vi.fn(),
      afterCommand: vi.fn(),
      onError: vi.fn(),
      beforeRequest: vi.fn(),
      afterResponse: vi.fn(),
      registerCommands: vi.fn(),
    };
    plugin.register(hooks);
    expect(hooks.afterCommand).toHaveBeenCalled();
  });
});
```

```bash
npx vitest run
```

### 5. Install and configure

```bash
# Install locally
npm install ./gpc-plugin-my-notifier

# Or from npm
npm install -g @gpc-cli/cli-plugin-my-notifier
```

Add to `.gpcrc.json`:

```json
{
  "plugins": ["gpc-plugin-my-notifier"],
  "approvedPlugins": ["gpc-plugin-my-notifier"]
}
```

Third-party plugins must be listed in `approvedPlugins` to load.

### 6. Publish to npm

```bash
# Build
npx tsc

# Test
npx vitest run

# Publish
npm publish
```

Naming convention:
- First-party: `@gpc-cli/plugin-<name>` (reserved for official plugins)
- Third-party: `gpc-plugin-<name>`

## Verification

- `gpc plugins list` shows your plugin as loaded
- Hooks fire at the expected lifecycle points
- `npx vitest run` passes all tests
- Third-party permission errors show clear messages
- Plugin loads without blocking GPC startup

## Failure modes / debugging

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Plugin not loading | Not in `plugins` config array | Add to `.gpcrc.json` plugins list |
| `PLUGIN_INVALID_PERMISSION` | Unknown permission declared | Check valid permissions in references/permissions-system.md |
| Third-party plugin blocked | Not in `approvedPlugins` | Add plugin name to `approvedPlugins` in config |
| Hook not firing | Wrong hook name or not registered | Verify hook registration in `register()` method |
| Hook error crashes GPC | Error in `beforeCommand` handler | `onError` and API hooks swallow errors; `beforeCommand` does not |
| Plugin not found | Wrong package name or not installed | Check `node_modules` for `gpc-plugin-*` or `@gpc-cli/plugin-*` |
| Standalone binary ignores plugins | Plugins disabled in binary mode | Use npm-installed GPC for plugin support |
| `gpc doctor` warns on plugin | Plugin fails to load | Run `gpc doctor` to see which plugin failed, then reinstall it (v0.9.71+) |

## Related skills

- **gpc-ci-integration** — uses @gpc-cli/plugin-ci as an example of a first-party plugin
- **gpc-setup** — configuration file where plugins are registered
- **gpc-troubleshooting** — debugging plugin loading issues
