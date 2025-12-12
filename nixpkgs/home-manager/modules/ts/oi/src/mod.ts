#!/usr/bin/env bun

import { Command, Options, Prompt } from '@effect/cli'
import type { Terminal } from '@effect/platform'
import { NodeContext, NodeRuntime } from '@effect/platform-node'
import { Console, Effect, Option } from 'effect'
import { AiLive, generateCommitMessage } from './ai.ts'
import { ReviewAbortedError } from './errors.ts'
import { commit, ensureGitRepo, ensureStagedChanges, runPreCommitHook } from './git.ts'
import { reviewChanges, ReviewIssue, ReviewResult } from './review.ts'

/** Format a review issue for display */
const formatIssue = (issue: ReviewIssue): string => {
  const location = Option.isSome(issue.file)
    ? Option.isSome(issue.line)
      ? `${issue.file.value}:${issue.line.value}`
      : issue.file.value
    : undefined

  return location ? `  • [${location}] ${issue.message}` : `  • ${issue.message}`
}

/** Display review results to the user */
const displayReviewResults = (result: ReviewResult): Effect.Effect<void> =>
  Effect.gen(function* () {
    if (result.hasBlocking) {
      yield* Console.log('\n❌ Blocking issues found:\n')
      for (const issue of result.blocking) {
        yield* Console.log(formatIssue(issue))
      }
    }

    if (result.hasWarnings) {
      yield* Console.log('\n⚠️  Warnings:\n')
      for (const issue of result.warnings) {
        yield* Console.log(formatIssue(issue))
      }
    }

    if (result.isClean) {
      yield* Console.log('✅ No issues found in review')
    }

    yield* Console.log('')
  })

/** Prompt user to confirm proceeding with warnings */
const confirmWithWarnings: Effect.Effect<boolean, never, Terminal.Terminal> = Effect.gen(function* () {
  const prompt = Prompt.confirm({
    message: 'Warnings found. Continue with commit?',
    initial: false,
  })

  // Run the prompt - it may throw QuitException if user quits
  const result = yield* prompt.pipe(
    Effect.catchTag('QuitException', () => Effect.succeed(false)),
  )

  return result
})

const noVerify = Options.boolean('no-verify').pipe(
  Options.withDescription('Skip commit hooks with --no-verify'),
  Options.withDefault(false),
)

const skipReview = Options.boolean('skip-review').pipe(
  Options.withDescription('Skip the AI code review step'),
  Options.withDefault(false),
)

const reviewContext = Options.text('context').pipe(
  Options.withDescription('Additional context to guide the review (e.g. "this is a quick fix" or "focus on security")'),
  Options.optional,
)

const commitCommand = Command.make('commit', { noVerify, skipReview, context: reviewContext }).pipe(
  Command.withDescription('Generate AI commit message and commit staged changes'),
  Command.withHandler(({ noVerify, skipReview, context }) =>
    Effect.gen(function* () {
      yield* ensureGitRepo
      const diff = yield* ensureStagedChanges

      // Step 1: Run pre-commit hook early to fail fast (unless --no-verify)
      if (!noVerify) {
        yield* Console.log('Running pre-commit hook...')
        yield* runPreCommitHook
      }

      // Step 2: Review changes (unless skipped)
      if (!skipReview) {
        yield* Console.log('Reviewing staged changes...')
        const review = yield* reviewChanges(diff, {
          context: Option.getOrUndefined(context),
        })
        yield* displayReviewResults(review)

        // Block on blocking issues
        if (review.hasBlocking) {
          return yield* new ReviewAbortedError({
            message: 'Commit aborted due to blocking issues',
          })
        }

        // Prompt for confirmation on warnings
        if (review.hasWarnings) {
          const proceed = yield* confirmWithWarnings
          if (!proceed) {
            return yield* new ReviewAbortedError({
              message: 'Commit aborted by user',
            })
          }
        }
      }

      // Step 3: Generate commit message
      yield* Console.log('Generating commit message...')
      const message = yield* generateCommitMessage(diff)

      yield* Console.log('\nGenerated commit message:')
      yield* Console.log('---')
      yield* Console.log(message)
      yield* Console.log('---')

      // Step 4: Commit
      yield* commit(message, { noVerify })
      yield* Console.log('\n✅ Committed successfully!')
    }),
  ),
)

const reviewCommand = Command.make('review', { context: reviewContext }).pipe(
  Command.withDescription('Review staged changes for issues'),
  Command.withHandler(({ context }) =>
    Effect.gen(function* () {
      yield* ensureGitRepo
      const diff = yield* ensureStagedChanges

      yield* Console.log('Reviewing staged changes...')
      const review = yield* reviewChanges(diff, {
        context: Option.getOrUndefined(context),
      })
      yield* displayReviewResults(review)

      if (review.hasBlocking) {
        return yield* Effect.fail({ _tag: 'ExitWithCode' as const, code: 1 })
      }
    }).pipe(Effect.catchTag('ExitWithCode', () => Effect.void)),
  ),
)

const oi = Command.make('oi').pipe(
  Command.withDescription('AI-assisted git operations'),
  Command.withSubcommands([commitCommand, reviewCommand]),
)

const cli = Command.run(oi, {
  name: 'oi',
  version: '0.1.0',
})

Effect.suspend(() => cli(process.argv)).pipe(
  Effect.provide(AiLive),
  Effect.provide(NodeContext.layer),
  NodeRuntime.runMain,
)
