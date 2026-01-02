# op-secret-cache

Cache 1Password secrets locally for faster access. Eliminates repeated `op read` calls by storing secrets in a local cache with optional TTL.

## Usage

```bash
# Get a secret (fetches from 1Password, caches locally)
op-secret-cache get "op://Vault/Item/Field"

# Get with custom cache key and TTL
op-secret-cache get --key my-secret --ttl 7d "op://Vault/Item/Field"

# Force refresh (bypass cache)
op-secret-cache get --refresh "op://Vault/Item/Field"

# Inject secrets from stdin (single auth prompt)
op-secret-cache inject --key envrc --ttl 7d - << 'EOF'
export API_KEY='{{ op://Vault/API/key }}'
EOF

# List cached secrets
op-secret-cache list
op-secret-cache list --verbose

# Clear cache
op-secret-cache clear my-secret    # single key
op-secret-cache clear --all        # everything

# Show cache info
op-secret-cache info
```

## Commands

### `get <path>`

Fetch a secret from 1Password, caching the result locally.

| Option | Short | Description |
|--------|-------|-------------|
| `--key <name>` | `-k` | Cache key (default: slugified from path) |
| `--ttl <duration>` | `-t` | Cache TTL, e.g. `1h`, `7d`, `30m` |
| `--refresh` | `-r` | Force re-fetch, ignore cache |
| `--cache-dir <path>` | `-c` | Cache directory (default: `.direnv/secrets`) |
| `--json` | | Output as JSON |

### `inject <template>`

Inject secrets into a template using `{{ op://... }}` placeholders. Uses `op inject` under the hood, triggering only a single 1Password auth prompt for all secrets.

Pass `-` as template to read from stdin (requires `--key`).

| Option | Short | Description |
|--------|-------|-------------|
| `--key <name>` | `-k` | Cache key (required for stdin, default: slugified from path) |
| `--ttl <duration>` | `-t` | Cache TTL, e.g. `1h`, `7d`, `30m` |
| `--refresh` | `-r` | Force re-fetch, ignore cache |
| `--cache-dir <path>` | `-c` | Cache directory (default: `.direnv/secrets`) |
| `--json` | | Output as JSON |

### `list`

List all cached secrets.

| Option | Short | Description |
|--------|-------|-------------|
| `--verbose` | `-v` | Show detailed info (path, TTL, size) |
| `--json` | | Output as JSON |

### `clear [key]`

Clear cached secrets.

| Option | Description |
|--------|-------------|
| `--all` | Clear all cached secrets |
| `--json` | Output as JSON |

### `info`

Show cache directory, count, and total size.

| Option | Description |
|--------|-------------|
| `--json` | Output as JSON |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OP_SECRET_CACHE_DIR` | Default cache directory |
| `OP_SECRET_CACHE_TTL` | Default TTL for cached secrets |

## Usage in `.envrc.local`

```bash
# Single secret
export API_KEY=$(op-secret-cache get --ttl 7d "op://Vault/API/key")

# Source multiple secrets from a 1Password note
source <(op-secret-cache get --key envrc --ttl 7d "op://Vault/Env Vars/text")

# Inject secrets from a template file (single auth prompt)
source <(op-secret-cache inject --ttl 7d .envrc.local.tpl)

# Inject with inline heredoc (recommended - single auth, all in one file)
source <(op-secret-cache inject --key envrc --ttl 7d - << 'EOF'
export API_KEY='{{ op://Vault/API/key }}'
export DB_PASSWORD='{{ op://Vault/Database/password }}'
export SECRET_TOKEN='{{ op://Vault/App/secret-token }}'
EOF
)
```

The heredoc approach keeps everything in `.envrc.local`, triggers only one 1Password auth prompt, and caches the processed output.

**Note:** Use single quotes around `{{ }}` placeholders to prevent bash from interpreting `$` characters in secret values.

## Cache Location

By default, secrets are cached in `.direnv/secrets/` (git-ignored). Each secret is stored as a JSON file containing:

- `metadata.key` - cache key
- `metadata.path` - original 1Password path
- `metadata.cachedAt` - timestamp
- `metadata.expiresAt` - expiration timestamp (if TTL set)
- `value` - the secret value
