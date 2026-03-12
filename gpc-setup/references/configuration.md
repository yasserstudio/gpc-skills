# GPC Configuration

## Config File Locations

GPC searches for configuration in this order:

1. `--config` flag (explicit path)
2. `.gpcrc.json` in current directory (project-level)
3. `.gpcrc.json` in parent directories (walks up)
4. `~/.config/gpc/config.json` (user-level, XDG-compliant)

## Config File Schema

```json
{
  "app": "com.example.myapp",
  "output": "table",
  "profile": "default",
  "verbose": false,
  "quiet": false
}
```

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `app` | string | Default package name | — |
| `output` | string | Output format: table, json, yaml, markdown | Auto (TTY=table, pipe=json) |
| `profile` | string | Default auth profile name | "default" |
| `verbose` | boolean | Enable debug logging | false |
| `quiet` | boolean | Suppress non-essential output | false |

## Environment Variable Precedence

Environment variables override config file values:

```
CLI flags > Environment variables > Config file > Defaults
```

| Variable | Overrides |
|----------|-----------|
| `GPC_APP` | `app` |
| `GPC_OUTPUT` | `output` |
| `GPC_PROFILE` | `profile` |
| `GPC_SERVICE_ACCOUNT` | Auth source |
| `GPC_NO_COLOR` | Color output |
| `GPC_NO_INTERACTIVE` | Interactive prompts |
| `GPC_SKIP_KEYCHAIN` | Keychain usage |
| `GPC_MAX_RETRIES` | Retry attempts |
| `GPC_TIMEOUT` | Request timeout (ms) |
| `GPC_BASE_DELAY` | Base retry delay (ms) |
| `GPC_MAX_DELAY` | Max retry delay (ms) |
| `GPC_RATE_LIMIT` | Requests per second |
| `GPC_DEVELOPER_ID` | Developer account ID |
| `GPC_CA_CERT` | Custom CA certificate path |
| `HTTPS_PROXY` | HTTP proxy URL |

## Interactive Config Init

```bash
gpc config init
```

Prompts for:
1. Default package name
2. Output format preference
3. Service account path (optional)

Creates `.gpcrc.json` in the current directory.

## Viewing Resolved Config

```bash
gpc config show    # Display all resolved settings
gpc config path    # Show config file location
```

## Per-Command Overrides

Any config value can be overridden per-command:

```bash
gpc apps list --app com.other.app --output json --profile staging
```
