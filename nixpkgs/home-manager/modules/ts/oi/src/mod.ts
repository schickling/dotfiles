#!/usr/bin/env bun

import { Command, Options, Prompt } from '@effect/cli'
import type { Terminal } from '@effect/platform'
import { NodeContext, NodeRuntime } from '@effect/platform-node'
import { Console, Effect, Option } from 'effect'
import { AiCommitLive, AiReviewLive, generateCommitMessage } from './ai.ts'
import { ReviewAbortedError } from './errors.ts'
import { commit, ensureGitRepo, ensureStagedChanges, getRecentCommits, getUnstagedDiff, runPreCommitHook } from './git.ts'
import { reviewChanges, ReviewIssue, ReviewResult, UnstagedSuggestion } from './review.ts'

/** Format location string for an issue */
const formatLocation = (issue: ReviewIssue): string | undefined => {
  if (Option.isSome(issue.file)) {
    if (Option.isSome(issue.line)) {
      return `${issue.file.value}:${issue.line.value}`
    }
    return issue.file.value
  }
  return undefined
}

/** Format a single issue as a multi-line block */
const formatIssueBlock = (issue: ReviewIssue, index: number): string => {
  const lines: string[] = []
  const location = formatLocation(issue)

  lines.push(`${index}. ${location ?? 'General'}`)
  lines.push(`   ${issue.message}`)

  if (Option.isSome(issue.suggestion)) {
    lines.push(`   → ${issue.suggestion.value}`)
  }

  return lines.join('\n')
}

/** Format issues as readable sections */
const formatIssuesList = (issues: readonly ReviewIssue[], label: string): string => {
  if (issues.length === 0) return ''

  const lines: string[] = []
  lines.push(`\n${label}\n`)

  for (let i = 0; i < issues.length; i++) {
    lines.push(formatIssueBlock(issues[i]!, i + 1))
    if (i < issues.length - 1) lines.push('')
  }

  return lines.join('\n')
}

/** Format unstaged suggestions */
const formatUnstagedSuggestions = (suggestions: readonly UnstagedSuggestion[]): string => {
  if (suggestions.length === 0) return ''

  const lines: string[] = []
  lines.push(`\n📁 Related unstaged files to consider:\n`)

  for (const suggestion of suggestions) {
    lines.push(`  • ${suggestion.file}`)
    lines.push(`    ${suggestion.reason}`)
  }

  return lines.join('\n')
}

/** Display review results to the user */
const displayReviewResults = (result: ReviewResult): Effect.Effect<void> =>
  Effect.gen(function* () {
    if (result.hasBlocking) {
      yield* Console.log(formatIssuesList(result.blocking, '❌ Blocking issues (must fix before commit):'))
    }

    if (result.hasWarnings) {
      yield* Console.log(formatIssuesList(result.warnings, '⚠️  Warnings (consider fixing):'))
    }

    if (result.hasUnstagedSuggestions) {
      yield* Console.log(formatUnstagedSuggestions(result.unstagedSuggestions))
    }

    if (result.isClean && !result.hasUnstagedSuggestions) {
      yield* Console.log('✅ No issues found in review')
    } else if (result.isClean && result.hasUnstagedSuggestions) {
      yield* Console.log('\n✅ No code issues found')
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
        const [unstagedDiff, recentCommits] = yield* Effect.all([
          getUnstagedDiff,
          getRecentCommits(5),
        ])
        const review = yield* reviewChanges(diff, {
          context: Option.getOrUndefined(context),
          unstagedDiff: unstagedDiff || undefined,
          recentCommits: recentCommits || undefined,
        }).pipe(Effect.provide(AiReviewLive))
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
      const message = yield* generateCommitMessage(diff).pipe(Effect.provide(AiCommitLive))

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
      const [unstagedDiff, recentCommits] = yield* Effect.all([
        getUnstagedDiff,
        getRecentCommits(5),
      ])
      const review = yield* reviewChanges(diff, {
        context: Option.getOrUndefined(context),
        unstagedDiff: unstagedDiff || undefined,
        recentCommits: recentCommits || undefined,
      }).pipe(Effect.provide(AiReviewLive))
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
  Effect.provide(NodeContext.layer),
  NodeRuntime.runMain,
)
