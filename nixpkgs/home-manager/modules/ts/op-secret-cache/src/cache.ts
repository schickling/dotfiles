import { FileSystem } from '@effect/platform'
import { DateTime, Effect, Option, Schema } from 'effect'

/** Metadata stored alongside each cached secret */
export const CacheMetadataSchema = Schema.Struct({
  key: Schema.String,
  path: Schema.String,
  cachedAt: Schema.DateTimeUtc,
  expiresAt: Schema.OptionFromNullOr(Schema.DateTimeUtc),
})
export type CacheMetadata = typeof CacheMetadataSchema.Type

/** Cache entry combining metadata and value */
export const CacheEntrySchema = Schema.Struct({
  metadata: CacheMetadataSchema,
  value: Schema.String,
})
export type CacheEntry = typeof CacheEntrySchema.Type

/** Slugify an op:// path into a valid filename */
export const slugifyPath = (opPath: string): string =>
  opPath
    .replace(/^op:\/\//, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')

/** Get the file path for a cache entry */
const getCacheFilePath = (cacheDir: string, key: string): string =>
  `${cacheDir}/${key}.json`

/** Check if a cache entry has expired */
const isExpired = (metadata: CacheMetadata): boolean => {
  if (Option.isNone(metadata.expiresAt)) return false
  const now = DateTime.unsafeNow()
  return DateTime.greaterThan(now, metadata.expiresAt.value)
}

/** Read a cache entry if it exists and is valid */
export const readCacheEntry = (
  cacheDir: string,
  key: string,
): Effect.Effect<CacheEntry | undefined, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const filePath = getCacheFilePath(cacheDir, key)

    const exists = yield* fs.exists(filePath)
    if (!exists) return undefined

    const content = yield* fs.readFileString(filePath).pipe(
      Effect.catchAll(() => Effect.succeed(undefined)),
    )
    if (!content) return undefined

    const parsed = yield* Schema.decodeUnknown(CacheEntrySchema)(JSON.parse(content)).pipe(
      Effect.catchAll(() => Effect.succeed(undefined)),
    )
    if (!parsed) return undefined

    if (isExpired(parsed.metadata)) {
      yield* fs.remove(filePath).pipe(Effect.catchAll(() => Effect.void))
      return undefined
    }

    return parsed
  }).pipe(Effect.catchAll(() => Effect.succeed(undefined)))

/** Write a cache entry */
export const writeCacheEntry = (
  cacheDir: string,
  entry: CacheEntry,
): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const filePath = getCacheFilePath(cacheDir, entry.metadata.key)

    yield* fs.makeDirectory(cacheDir, { recursive: true }).pipe(
      Effect.catchAll(() => Effect.void),
    )

    const encoded = yield* Schema.encode(CacheEntrySchema)(entry)
    const content = JSON.stringify(encoded, null, 2)
    yield* fs.writeFileString(filePath, content)
  }).pipe(Effect.catchAll(() => Effect.void))

/** List all cache entries */
export const listCacheEntries = (
  cacheDir: string,
): Effect.Effect<readonly CacheEntry[], never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem

    const exists = yield* fs.exists(cacheDir)
    if (!exists) return []

    const files = yield* fs.readDirectory(cacheDir).pipe(
      Effect.catchAll(() => Effect.succeed([] as string[])),
    )

    const entries: CacheEntry[] = []
    for (const file of files) {
      if (!file.endsWith('.json')) continue
      const key = file.replace(/\.json$/, '')
      const entry = yield* readCacheEntry(cacheDir, key)
      if (entry) entries.push(entry)
    }

    return entries
  }).pipe(Effect.catchAll(() => Effect.succeed([] as CacheEntry[])))

/** Clear a single cache entry */
export const clearCacheEntry = (
  cacheDir: string,
  key: string,
): Effect.Effect<boolean, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const filePath = getCacheFilePath(cacheDir, key)

    const exists = yield* fs.exists(filePath)
    if (!exists) return false

    yield* fs.remove(filePath)
    return true
  }).pipe(Effect.catchAll(() => Effect.succeed(false)))

/** Clear all cache entries */
export const clearAllCacheEntries = (
  cacheDir: string,
): Effect.Effect<readonly string[], never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem

    const exists = yield* fs.exists(cacheDir)
    if (!exists) return []

    const files = yield* fs.readDirectory(cacheDir).pipe(
      Effect.catchAll(() => Effect.succeed([] as string[])),
    )

    const cleared: string[] = []
    for (const file of files) {
      if (!file.endsWith('.json')) continue
      const key = file.replace(/\.json$/, '')
      yield* fs.remove(`${cacheDir}/${file}`).pipe(
        Effect.catchAll(() => Effect.void),
      )
      cleared.push(key)
    }

    return cleared
  }).pipe(Effect.catchAll(() => Effect.succeed([] as string[])))

/** Get cache info (directory, count, total size) */
export const getCacheInfo = (
  cacheDir: string,
): Effect.Effect<{ cacheDir: string; count: number; totalSize: number }, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem

    const exists = yield* fs.exists(cacheDir)
    if (!exists) return { cacheDir, count: 0, totalSize: 0 }

    const files = yield* fs.readDirectory(cacheDir).pipe(
      Effect.catchAll(() => Effect.succeed([] as string[])),
    )

    let count = 0
    let totalSize = 0

    for (const file of files) {
      if (!file.endsWith('.json')) continue
      count++
      const stat = yield* fs.stat(`${cacheDir}/${file}`).pipe(
        Effect.catchAll(() => Effect.succeed({ size: 0 as number })),
      )
      totalSize += Number(stat.size)
    }

    return { cacheDir, count, totalSize }
  }).pipe(Effect.catchAll(() => Effect.succeed({ cacheDir, count: 0, totalSize: 0 })))
