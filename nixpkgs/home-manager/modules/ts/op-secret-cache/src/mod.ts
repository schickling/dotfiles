#!/usr/bin/env bun

import { Args, Command, Options } from '@effect/cli'
import { FileSystem } from '@effect/platform'
import { NodeContext, NodeRuntime } from '@effect/platform-node'
import { Console, DateTime, Effect, Option } from 'effect'
import {
  type CacheEntry,
  clearAllCacheEntries,
  clearCacheEntry,
  getCacheInfo,
  listCacheEntries,
  readCacheEntry,
  slugifyPath,
  writeCacheEntry,
} from './cache.ts'
import { formatRelativeTime, parseDuration } from './duration.ts'
import { injectTemplateContent, injectTemplateFile, readSecret } from './op.ts'

/** Default cache directory */
const DEFAULT_CACHE_DIR = '.direnv/secrets'

/** Get cache directory from env or default */
const getCacheDir = (override?: string): string =>
  override ?? process.env['OP_SECRET_CACHE_DIR'] ?? DEFAULT_CACHE_DIR

/** Get default TTL from env (in milliseconds) */
const getDefaultTtl = (): number | undefined => {
  const envTtl = process.env['OP_SECRET_CACHE_TTL']
  if (!envTtl) return undefined
  const result = Effect.runSync(parseDuration(envTtl).pipe(Effect.option))
  return Option.getOrUndefined(result)
}

/** Format bytes as human-readable size */
const formatSize = (bytes: number): string => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

// ─── Shared Options ─────────────────────────────────────────────────────────

const cacheDirOption = Options.text('cache-dir').pipe(
  Options.withAlias('c'),
  Options.withDescription(`Cache directory (default: ${DEFAULT_CACHE_DIR}, env: OP_SECRET_CACHE_DIR)`),
  Options.optional,
)

const jsonOption = Options.boolean('json').pipe(
  Options.withDescription('Output in JSON format'),
  Options.withDefault(false),
)

// ─── Get Command ────────────────────────────────────────────────────────────

const pathArg = Args.text({ name: 'path' }).pipe(
  Args.withDescription('1Password secret path (op://Vault/Item/Field)'),
)

const keyOption = Options.text('key').pipe(
  Options.withAlias('k'),
  Options.withDescription('Cache key (default: slugified from path)'),
  Options.optional,
)

const ttlOption = Options.text('ttl').pipe(
  Options.withAlias('t'),
  Options.withDescription('Cache TTL (e.g., 1h, 7d, 30m) (env: OP_SECRET_CACHE_TTL)'),
  Options.optional,
)

const refreshOption = Options.boolean('refresh').pipe(
  Options.withAlias('r'),
  Options.withDescription('Force re-fetch, ignore cache'),
  Options.withDefault(false),
)

const getCommand = Command.make(
  'get',
  { path: pathArg, key: keyOption, ttl: ttlOption, refresh: refreshOption, cacheDir: cacheDirOption, json: jsonOption },
).pipe(
  Command.withDescription('Get a secret from 1Password (cached)'),
  Command.withHandler(({ path, key, ttl, refresh, cacheDir, json }) =>
    Effect.gen(function* () {
      const dir = getCacheDir(Option.getOrUndefined(cacheDir))
      const cacheKey = Option.getOrElse(key, () => slugifyPath(path))

      // Check cache first (unless refresh)
      if (!refresh) {
        const cached = yield* readCacheEntry(dir, cacheKey)
        if (cached) {
          if (json) {
            yield* Console.log(JSON.stringify({
              key: cached.metadata.key,
              value: cached.value,
              path: cached.metadata.path,
              cachedAt: cached.metadata.cachedAt,
              expiresAt: Option.getOrNull(cached.metadata.expiresAt),
              fromCache: true,
            }))
          } else {
            yield* Console.log(cached.value)
          }
          return
        }
      }

      // Fetch from 1Password
      const value = yield* readSecret(path)

      // Calculate expiration
      const ttlMs = Option.isSome(ttl)
        ? yield* parseDuration(ttl.value)
        : getDefaultTtl()

      const now = DateTime.unsafeNow()
      const expiresAt = ttlMs !== undefined
        ? Option.some(DateTime.add(now, { millis: ttlMs }))
        : Option.none()

      // Create and save cache entry
      const entry: CacheEntry = {
        metadata: {
          key: cacheKey,
          path,
          cachedAt: now,
          expiresAt,
        },
        value,
      }
      yield* writeCacheEntry(dir, entry)

      // Output
      if (json) {
        yield* Console.log(JSON.stringify({
          key: entry.metadata.key,
          value: entry.value,
          path: entry.metadata.path,
          cachedAt: entry.metadata.cachedAt,
          expiresAt: Option.getOrNull(entry.metadata.expiresAt),
          fromCache: false,
        }))
      } else {
        yield* Console.log(value)
      }
    }),
  ),
)

// ─── List Command ───────────────────────────────────────────────────────────

const verboseOption = Options.boolean('verbose').pipe(
  Options.withAlias('v'),
  Options.withDescription('Show detailed information'),
  Options.withDefault(false),
)

const listCommand = Command.make('list', { cacheDir: cacheDirOption, json: jsonOption, verbose: verboseOption }).pipe(
  Command.withDescription('List all cached secrets'),
  Command.withHandler(({ cacheDir, json, verbose }) =>
    Effect.gen(function* () {
      const dir = getCacheDir(Option.getOrUndefined(cacheDir))
      const entries = yield* listCacheEntries(dir)

      if (json) {
        const output = entries.map((e) => ({
          key: e.metadata.key,
          path: e.metadata.path,
          cachedAt: e.metadata.cachedAt,
          expiresAt: Option.getOrNull(e.metadata.expiresAt),
          size: e.value.length,
        }))
        yield* Console.log(JSON.stringify(output, null, 2))
        return
      }

      if (entries.length === 0) {
        yield* Console.log('No cached secrets found.')
        return
      }

      yield* Console.log(`Cached secrets (${entries.length}):`)
      yield* Console.log('')

      for (const entry of entries) {
        const cachedAt = new Date(DateTime.toEpochMillis(entry.metadata.cachedAt))
        const cachedAgo = formatRelativeTime(cachedAt)

        if (verbose) {
          yield* Console.log(`  ${entry.metadata.key}`)
          yield* Console.log(`    Path: ${entry.metadata.path}`)
          yield* Console.log(`    Cached: ${cachedAgo}`)
          if (Option.isSome(entry.metadata.expiresAt)) {
            const expiresAt = new Date(DateTime.toEpochMillis(entry.metadata.expiresAt.value))
            yield* Console.log(`    Expires: ${formatRelativeTime(expiresAt)}`)
          } else {
            yield* Console.log(`    Expires: never`)
          }
          yield* Console.log(`    Size: ${formatSize(entry.value.length)}`)
          yield* Console.log('')
        } else {
          const expiry = Option.isSome(entry.metadata.expiresAt)
            ? formatRelativeTime(new Date(DateTime.toEpochMillis(entry.metadata.expiresAt.value)))
            : 'never'
          yield* Console.log(`  ${entry.metadata.key} (cached ${cachedAgo}, expires ${expiry})`)
        }
      }
    }),
  ),
)

// ─── Clear Command ──────────────────────────────────────────────────────────

const keyArg = Args.text({ name: 'key' }).pipe(
  Args.withDescription('Cache key to clear'),
  Args.optional,
)

const allOption = Options.boolean('all').pipe(
  Options.withDescription('Clear all cached secrets'),
  Options.withDefault(false),
)

const clearCommand = Command.make('clear', { key: keyArg, all: allOption, cacheDir: cacheDirOption, json: jsonOption }).pipe(
  Command.withDescription('Clear cached secrets'),
  Command.withHandler(({ key, all, cacheDir, json }) =>
    Effect.gen(function* () {
      const dir = getCacheDir(Option.getOrUndefined(cacheDir))

      if (all) {
        const cleared = yield* clearAllCacheEntries(dir)
        if (json) {
          yield* Console.log(JSON.stringify({ cleared, count: cleared.length }))
        } else if (cleared.length > 0) {
          yield* Console.log(`Cleared ${cleared.length} cached secret(s):`)
          for (const k of cleared) {
            yield* Console.log(`  - ${k}`)
          }
        } else {
          yield* Console.log('No cached secrets to clear.')
        }
        return
      }

      if (Option.isNone(key)) {
        yield* Console.error('Error: Provide a key to clear, or use --all to clear everything.')
        return yield* Effect.fail({ _tag: 'ExitWithCode' as const, code: 1 })
      }

      const removed = yield* clearCacheEntry(dir, key.value)
      if (json) {
        yield* Console.log(JSON.stringify({ cleared: removed ? [key.value] : [], count: removed ? 1 : 0 }))
      } else if (removed) {
        yield* Console.log(`Cleared: ${key.value}`)
      } else {
        yield* Console.log(`Not found: ${key.value}`)
      }
    }).pipe(Effect.catchTag('ExitWithCode', () => Effect.void)),
  ),
)

// ─── Info Command ───────────────────────────────────────────────────────────

const infoCommand = Command.make('info', { cacheDir: cacheDirOption, json: jsonOption }).pipe(
  Command.withDescription('Show cache information'),
  Command.withHandler(({ cacheDir, json }) =>
    Effect.gen(function* () {
      const dir = getCacheDir(Option.getOrUndefined(cacheDir))
      const info = yield* getCacheInfo(dir)

      if (json) {
        yield* Console.log(JSON.stringify(info))
      } else {
        yield* Console.log(`Cache directory: ${info.cacheDir}`)
        yield* Console.log(`Cached secrets:  ${info.count}`)
        yield* Console.log(`Total size:      ${formatSize(info.totalSize)}`)
      }
    }),
  ),
)

// ─── Inject Command ─────────────────────────────────────────────────────────

/** Read all stdin as a string */
const readStdin = (): Effect.Effect<string> =>
  Effect.promise(async () => {
    const chunks: Buffer[] = []
    for await (const chunk of process.stdin) {
      chunks.push(chunk)
    }
    return Buffer.concat(chunks).toString('utf-8')
  })

const templateArg = Args.text({ name: 'template' }).pipe(
  Args.withDescription('Template file with {{ op://... }} placeholders, or "-" for stdin'),
)

const injectCommand = Command.make(
  'inject',
  { template: templateArg, key: keyOption, ttl: ttlOption, refresh: refreshOption, cacheDir: cacheDirOption, json: jsonOption },
).pipe(
  Command.withDescription('Inject secrets into a template (single auth prompt)'),
  Command.withHandler(({ template, key, ttl, refresh, cacheDir, json }) =>
    Effect.gen(function* () {
      const dir = getCacheDir(Option.getOrUndefined(cacheDir))
      const isStdin = template === '-'

      // For stdin, key is required
      if (isStdin && Option.isNone(key)) {
        yield* Console.error('Error: --key is required when reading from stdin')
        return yield* Effect.fail({ _tag: 'ExitWithCode' as const, code: 1 })
      }

      const cacheKey = Option.getOrElse(key, () => slugifyPath(template))

      // Check cache first (unless refresh)
      if (!refresh) {
        const cached = yield* readCacheEntry(dir, cacheKey)
        if (cached) {
          if (json) {
            yield* Console.log(JSON.stringify({
              key: cached.metadata.key,
              value: cached.value,
              path: cached.metadata.path,
              cachedAt: cached.metadata.cachedAt,
              expiresAt: Option.getOrNull(cached.metadata.expiresAt),
              fromCache: true,
            }))
          } else {
            yield* Console.log(cached.value)
          }
          return
        }
      }

      // Read template content to check for potential issues
      const fs = yield* Effect.serviceOption(FileSystem.FileSystem)
      const templateContent = isStdin
        ? yield* readStdin()
        : Option.isSome(fs)
          ? yield* fs.value.readFileString(template).pipe(Effect.orElseSucceed(() => ''))
          : ''

      // Warn if template uses double quotes around placeholders ($ in secrets will be interpreted)
      if (templateContent.includes('"{{') || templateContent.includes('}}"')) {
        yield* Console.error('Warning: Template uses double quotes around {{ }} placeholders.')
        yield* Console.error('         Use single quotes to prevent $VAR interpolation in secrets.')
        yield* Console.error('         Example: export KEY=\'{{ op://Vault/Item/field }}\'')
      }

      // Inject secrets via op inject (single auth prompt)
      const value = isStdin
        ? yield* injectTemplateContent(templateContent)
        : yield* injectTemplateFile(template)

      // Calculate expiration
      const ttlMs = Option.isSome(ttl)
        ? yield* parseDuration(ttl.value)
        : getDefaultTtl()

      const now = DateTime.unsafeNow()
      const expiresAt = ttlMs !== undefined
        ? Option.some(DateTime.add(now, { millis: ttlMs }))
        : Option.none()

      // Create and save cache entry
      const entry: CacheEntry = {
        metadata: {
          key: cacheKey,
          path: isStdin ? '<stdin>' : template,
          cachedAt: now,
          expiresAt,
        },
        value,
      }
      yield* writeCacheEntry(dir, entry)

      // Output
      if (json) {
        yield* Console.log(JSON.stringify({
          key: entry.metadata.key,
          value: entry.value,
          path: entry.metadata.path,
          cachedAt: entry.metadata.cachedAt,
          expiresAt: Option.getOrNull(entry.metadata.expiresAt),
          fromCache: false,
        }))
      } else {
        yield* Console.log(value)
      }
    }).pipe(Effect.catchTag('ExitWithCode', () => Effect.void)),
  ),
)

// ─── Main CLI ───────────────────────────────────────────────────────────────

const cli = Command.make('op-secret-cache').pipe(
  Command.withDescription('Cache 1Password secrets locally for faster access'),
  Command.withSubcommands([getCommand, listCommand, clearCommand, infoCommand, injectCommand]),
)

const app = Command.run(cli, {
  name: 'op-secret-cache',
  version: '0.1.0',
})

Effect.suspend(() => app(process.argv)).pipe(
  Effect.provide(NodeContext.layer),
  NodeRuntime.runMain,
)
