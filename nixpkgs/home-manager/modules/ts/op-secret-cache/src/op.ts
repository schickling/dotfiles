import { Command, CommandExecutor, FileSystem, Path } from '@effect/platform'
import { Effect, Schema } from 'effect'

/** Error when 1Password CLI fails */
export class OpCliError extends Schema.TaggedError<OpCliError>()('OpCliError', {
  message: Schema.String,
  cause: Schema.Defect,
}) {}

/** Error when secret path is invalid */
export class InvalidSecretPathError extends Schema.TaggedError<InvalidSecretPathError>()('InvalidSecretPathError', {
  message: Schema.String,
  path: Schema.String,
}) {}

/** Validate an op:// secret path */
export const validateSecretPath = (path: string): Effect.Effect<string, InvalidSecretPathError> => {
  if (!path.startsWith('op://')) {
    return Effect.fail(new InvalidSecretPathError({
      message: `Invalid secret path: must start with 'op://'`,
      path,
    }))
  }
  return Effect.succeed(path)
}

/** Read a secret from 1Password CLI */
export const readSecret = (path: string): Effect.Effect<string, OpCliError | InvalidSecretPathError, CommandExecutor.CommandExecutor> =>
  Effect.gen(function* () {
    yield* validateSecretPath(path)

    const command = Command.make('op', 'read', path)
    const result = yield* Command.string(command).pipe(
      Effect.mapError((cause) => new OpCliError({
        message: `Failed to read secret from 1Password: ${path}`,
        cause,
      })),
    )

    return result.trim()
  })

/** Inject secrets into a template file using 1Password CLI */
export const injectTemplateFile = (templatePath: string): Effect.Effect<string, OpCliError, CommandExecutor.CommandExecutor> =>
  Effect.gen(function* () {
    const command = Command.make('op', 'inject', '-i', templatePath)
    const result = yield* Command.string(command).pipe(
      Effect.mapError((cause) => new OpCliError({
        message: `Failed to inject secrets from template: ${templatePath}`,
        cause,
      })),
    )
    return result
  })

/** Inject secrets into template content using 1Password CLI (writes to temp file) */
export const injectTemplateContent = (content: string): Effect.Effect<string, OpCliError, CommandExecutor.CommandExecutor | FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path

    // Create temp file with template content
    const tmpDir = yield* fs.makeTempDirectoryScoped().pipe(
      Effect.mapError((cause) => new OpCliError({
        message: `Failed to create temp directory`,
        cause,
      })),
    )
    const tmpFile = path.join(tmpDir, 'template.tpl')
    yield* fs.writeFileString(tmpFile, content).pipe(
      Effect.mapError((cause) => new OpCliError({
        message: `Failed to write temp file`,
        cause,
      })),
    )

    // Run op inject
    const command = Command.make('op', 'inject', '-i', tmpFile)
    const result = yield* Command.string(command).pipe(
      Effect.mapError((cause) => new OpCliError({
        message: `Failed to inject secrets from template`,
        cause,
      })),
    )
    return result
  }).pipe(Effect.scoped)
