import { Command, CommandExecutor, Error as PlatformError } from '@effect/platform'
import { Effect } from 'effect'
import {
  GitCommandError,
  NoStagedChangesError,
  NotInGitRepoError,
  PreCommitHookError,
} from './errors.ts'

/** Checks if the current directory is inside a git repository */
export const isInsideGitRepo: Effect.Effect<
  boolean,
  PlatformError.PlatformError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  const command = Command.make('git', 'rev-parse', '--is-inside-work-tree')
  const result = yield* Command.exitCode(command)
  return result === 0
}).pipe(Effect.withSpan('git.isInsideGitRepo'))

/** Ensures we're inside a git repository, fails with NotInGitRepoError otherwise */
export const ensureGitRepo: Effect.Effect<
  void,
  NotInGitRepoError | PlatformError.PlatformError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  const isRepo = yield* isInsideGitRepo
  if (!isRepo) {
    return yield* new NotInGitRepoError({
      message: 'Not inside a git repository',
    })
  }
}).pipe(Effect.withSpan('git.ensureGitRepo'))

/** Gets the staged diff */
export const getStagedDiff: Effect.Effect<
  string,
  GitCommandError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  const command = Command.make('git', 'diff', '--cached')
  const result = yield* Command.string(command).pipe(
    Effect.catchAll((cause) =>
      Effect.fail(
        new GitCommandError({
          cause,
          command: 'git diff --cached',
          message: 'Failed to get staged diff',
        }),
      ),
    ),
  )
  return result.trim()
}).pipe(Effect.withSpan('git.getStagedDiff'))

/** Gets the unstaged diff (working directory changes not yet staged) */
export const getUnstagedDiff: Effect.Effect<
  string,
  GitCommandError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  const command = Command.make('git', 'diff')
  const result = yield* Command.string(command).pipe(
    Effect.catchAll((cause) =>
      Effect.fail(
        new GitCommandError({
          cause,
          command: 'git diff',
          message: 'Failed to get unstaged diff',
        }),
      ),
    ),
  )
  return result.trim()
}).pipe(Effect.withSpan('git.getUnstagedDiff'))

/** Gets recent commit history (last N commits, one-line format) */
export const getRecentCommits = (
  count: number = 5,
): Effect.Effect<string, GitCommandError, CommandExecutor.CommandExecutor> =>
  Effect.gen(function* () {
    const command = Command.make(
      'git',
      'log',
      `--oneline`,
      `-n`,
      `${count}`,
      '--pretty=format:%h %s',
    )
    const result = yield* Command.string(command).pipe(
      Effect.catchAll((cause) =>
        Effect.fail(
          new GitCommandError({
            cause,
            command: `git log --oneline -n ${count}`,
            message: 'Failed to get recent commits',
          }),
        ),
      ),
    )
    return result.trim()
  }).pipe(Effect.withSpan('git.getRecentCommits'))

/** Ensures there are staged changes, fails with NoStagedChangesError otherwise */
export const ensureStagedChanges: Effect.Effect<
  string,
  NoStagedChangesError | GitCommandError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  const diff = yield* getStagedDiff
  if (diff.length === 0) {
    return yield* new NoStagedChangesError({
      message: 'No staged changes to commit',
    })
  }
  return diff
}).pipe(Effect.withSpan('git.ensureStagedChanges'))

/** Runs the pre-commit hook without creating a commit */
export const runPreCommitHook: Effect.Effect<
  void,
  PreCommitHookError | GitCommandError,
  CommandExecutor.CommandExecutor
> = Effect.gen(function* () {
  // Get the hooks directory using git's own resolution (respects core.hooksPath config)
  const hooksPathCommand = Command.make('git', 'rev-parse', '--git-path', 'hooks')
  const hooksDir = yield* Command.string(hooksPathCommand).pipe(
    Effect.map((s) => s.trim()),
    Effect.catchAll((cause) =>
      Effect.fail(
        new GitCommandError({
          cause,
          command: 'git rev-parse --git-path hooks',
          message: 'Failed to get hooks directory',
        }),
      ),
    ),
  )

  const hookPath = `${hooksDir}/pre-commit`

  // Check if pre-commit hook exists and is executable
  const testCommand = Command.make('test', '-x', hookPath)
  const hookExists = yield* Command.exitCode(testCommand).pipe(
    Effect.map((code) => code === 0),
    Effect.catchAll(() => Effect.succeed(false)),
  )

  if (!hookExists) {
    // No pre-commit hook, nothing to do
    return
  }

  // Run the pre-commit hook from the repo root
  const repoRootCommand = Command.make('git', 'rev-parse', '--show-toplevel')
  const repoRoot = yield* Command.string(repoRootCommand).pipe(
    Effect.map((s) => s.trim()),
    Effect.catchAll((cause) =>
      Effect.fail(
        new GitCommandError({
          cause,
          command: 'git rev-parse --show-toplevel',
          message: 'Failed to get repo root',
        }),
      ),
    ),
  )

  const hookCommand = Command.make(hookPath).pipe(Command.workingDirectory(repoRoot))
  const exitCode = yield* Command.exitCode(hookCommand).pipe(
    Effect.catchAll((cause) =>
      Effect.fail(
        new GitCommandError({
          cause,
          command: hookPath,
          message: 'Failed to run pre-commit hook',
        }),
      ),
    ),
  )

  if (exitCode !== 0) {
    return yield* new PreCommitHookError({
      message: 'Pre-commit hook failed',
    })
  }
}).pipe(Effect.withSpan('git.runPreCommitHook'))

/** Commits with the given message */
export const commit = (
  message: string,
  options: { noVerify: boolean },
): Effect.Effect<void, GitCommandError, CommandExecutor.CommandExecutor> =>
  Effect.gen(function* () {
    const args = options.noVerify
      ? ['commit', '--no-verify', '-m', message]
      : ['commit', '-m', message]

    const command = Command.make('git', ...args)

    yield* Command.string(command).pipe(
      Effect.catchAll((cause) =>
        Effect.fail(
          new GitCommandError({
            cause,
            command: `git ${args.join(' ')}`,
            message: 'Failed to create commit',
          }),
        ),
      ),
    )
  }).pipe(Effect.withSpan('git.commit'))
