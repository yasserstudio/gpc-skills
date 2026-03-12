# GPC Setup Troubleshooting

## Authentication Issues

### `AUTH_EXPIRED` — Token expired
```
Error: Access token has expired
Suggestion: Run 'gpc auth login' to re-authenticate
```

**Fix:** Re-authenticate:
```bash
gpc auth login                                    # OAuth
gpc auth login --service-account path/to/key.json # Service account
```

### `AUTH_INVALID` — Invalid credentials
```
Error: Invalid authentication credentials
```

**Possible causes:**
1. Service account key file is malformed or truncated
2. Key has been deleted in Google Cloud Console
3. Service account not linked in Play Console

**Fix:**
```bash
# Verify key file is valid JSON
cat key.json | jq .type  # Should output "service_account"

# Re-download key from Google Cloud Console
# Re-grant access in Play Console → Settings → API access
```

### `Permission denied` — Missing Play Console access

**Fix:**
1. Go to Play Console → Settings → API access
2. Find the service account
3. Click **Manage** → Grant required permissions
4. Wait up to 48 hours for propagation (usually instant)

## Network Issues

### `NETWORK_ERROR` — Cannot reach API

**Behind a proxy:**
```bash
export HTTPS_PROXY=http://proxy.company.com:8080
```

**Custom CA certificate:**
```bash
export GPC_CA_CERT=/path/to/corporate-ca.crt
```

**Increase timeout:**
```bash
export GPC_TIMEOUT=60000  # 60 seconds
```

### Rate limiting

```bash
# Increase delays between retries
export GPC_BASE_DELAY=2000
export GPC_MAX_DELAY=120000
export GPC_MAX_RETRIES=5
```

## Configuration Issues

### Config file not found

```bash
# Check where GPC looks for config
gpc config path

# Create one interactively
gpc config init

# Or set via env var
export GPC_APP=com.example.app
```

### Wrong app being used

```bash
# Check resolved config
gpc config show

# Override per-command
gpc apps list --app com.correct.app
```

## `gpc doctor` Failures

| Check | Fix |
|-------|-----|
| Node.js version | Install Node.js 20+ |
| Configuration | Run `gpc config init` or set `GPC_APP` |
| Authentication | Run `gpc auth login` |
| API connectivity | Check network, proxy, or service account permissions |
