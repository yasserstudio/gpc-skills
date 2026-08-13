# Plugin Permission System

How GPC manages plugin trust and permissions.

## Trust model

### First-party plugins (v0.9.94+)

- The allowlist is exactly one package: `@gpc-cli/plugin-ci`
- Trusted only when the **resolved package's own `package.json` name** matches the configured specifier
- Verified before `import()`; a mismatch is refused with `PLUGIN_IDENTITY_MISMATCH` and the module never runs
- Full access to all hooks and APIs once that check passes

**Changed in v0.9.94.** Trust used to be granted on the specifier string alone — anything beginning with `@gpc-cli/` was treated as first party without checking the package was really ours, so an npm alias or a local replacement resolving to that name inherited unrestricted access. `@gpc-cli/plugin-sdk` was also removed from the list: it is a library, not a plugin.

### Third-party plugins (`gpc-plugin-*`)

- Must declare permissions in `package.json`
- Must be listed in `approvedPlugins` config
- Permission violations throw `PLUGIN_INVALID_PERMISSION` (exit code 10)
- Users must explicitly approve each plugin

## Declaring permissions

In your plugin's `package.json`:

```json
{
  "name": "gpc-plugin-slack-notifier",
  "version": "1.0.0",
  "gpc": {
    "permissions": [
      "hooks:afterCommand",
      "hooks:onError"
    ]
  }
}
```

## All permissions

| Permission | Description | Required for |
|-----------|-------------|--------------|
| `read:config` | Read .gpcrc.json values | Accessing user config |
| `write:config` | Modify .gpcrc.json | Changing config programmatically |
| `read:auth` | Access credentials | Custom API calls with user's auth |
| `api:read` | Make read API calls | Fetching data from Google Play |
| `api:write` | Make write API calls | Uploading, modifying releases |
| `commands:register` | Register CLI commands | Adding custom commands |
| `hooks:beforeCommand` | Hook before commands | Pre-command validation |
| `hooks:afterCommand` | Hook after commands | Post-command notifications |
| `hooks:onError` | Hook on errors | Error reporting |
| `hooks:beforeRequest` | Hook before API requests | Request inspection |
| `hooks:afterResponse` | Hook after API responses | Response monitoring |

## Approving third-party plugins

In `.gpcrc.json`:

```json
{
  "plugins": [
    "@gpc-cli/plugin-ci",
    "gpc-plugin-slack-notifier"
  ],
  "approvedPlugins": [
    "gpc-plugin-slack-notifier"
  ]
}
```

- `plugins` — list of plugins to load
- `approvedPlugins` — third-party plugins the user has explicitly approved. Stored as a canonical identity, so a relative path approved in one project cannot approve a different project's plugin
- `legacyApprovedPlugins` — approvals grandfathered once when manifest permissions became mandatory in v0.9.94. User config only; not something to hand-edit
- `@gpc-cli/plugin-ci` does not need to be in `approvedPlugins`, but it is still identity-checked against its resolved manifest

## Permission validation flow

The trust check runs **before** `import()` is called on any plugin specifier. This prevents untrusted top-level module code from executing during discovery.

```
discoverPluginEntries() resolves specifier
  │
  ├─ Is it the allowlisted first-party package (@gpc-cli/plugin-ci)?
  │   └─ Yes → read the resolved package.json (no import() yet)
  │         ├─ Manifest name matches the specifier? → trusted, skip permission validation
  │         └─ Mismatch → PLUGIN_IDENTITY_MISMATCH, module never imported
  │
  ├─ Is in approvedPlugins?
  │   └─ No → Skip (silent, no import())
  │
  └─ Yes → read the resolved package.json (still no import())
        │
        ├─ Has gpc.permissions in package.json?
        │   └─ No → PLUGIN_PERMISSIONS_REQUIRED (v0.9.94+), unless grandfathered once
        │           via legacyApprovedPlugins with a deprecation warning
        │
        ├─ All permissions recognized?
        │   └─ No → Reject with PLUGIN_INVALID_PERMISSION
        │
        └─ Enforce permissions
```

> **Security note:** Prior to v0.9.74, GPC imported the plugin module first and checked approval afterward. This allowed untrusted top-level module code (side effects on `import()`) to run during discovery -- an RCE risk. The new model gates `import()` behind `isPluginTrusted()`, so unapproved plugins never execute any code.

## Common permission patterns

### Notification plugin (read-only)

```json
{
  "gpc": {
    "permissions": ["hooks:afterCommand", "hooks:onError"]
  }
}
```

### Metrics plugin (observability)

```json
{
  "gpc": {
    "permissions": [
      "hooks:beforeCommand",
      "hooks:afterCommand",
      "hooks:onError",
      "hooks:beforeRequest",
      "hooks:afterResponse"
    ]
  }
}
```

### Custom command plugin

```json
{
  "gpc": {
    "permissions": [
      "commands:register",
      "api:read",
      "read:config"
    ]
  }
}
```

### Full-access plugin

```json
{
  "gpc": {
    "permissions": [
      "read:config", "write:config",
      "read:auth",
      "api:read", "api:write",
      "commands:register",
      "hooks:beforeCommand", "hooks:afterCommand", "hooks:onError",
      "hooks:beforeRequest", "hooks:afterResponse"
    ]
  }
}
```

## Standalone binary

Plugins are **disabled** when running GPC as a standalone binary (`__GPC_BINARY=1`). Use the npm-installed version for plugin support.
