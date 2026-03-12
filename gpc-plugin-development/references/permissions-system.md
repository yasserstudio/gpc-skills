# Plugin Permission System

How GPC manages plugin trust and permissions.

## Trust model

### First-party plugins (`@gpc-cli/*`)

- Auto-trusted — no permission validation
- Loaded automatically if installed
- Full access to all hooks and APIs
- Example: `@gpc-cli/plugin-ci`

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
- `approvedPlugins` — third-party plugins the user has explicitly approved
- First-party plugins don't need to be in `approvedPlugins`

## Permission validation flow

```
Plugin loads
  │
  ├─ Is @gpc-cli/* prefix?
  │   └─ Yes → Auto-trusted, skip validation
  │
  ├─ Is in approvedPlugins?
  │   └─ No → Skip loading (silent)
  │
  ├─ Has gpc.permissions in package.json?
  │   └─ No → Reject with PLUGIN_INVALID_PERMISSION
  │
  ├─ All permissions recognized?
  │   └─ No → Reject with PLUGIN_INVALID_PERMISSION
  │
  └─ Load plugin, enforce permissions
```

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
