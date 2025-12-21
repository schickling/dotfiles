/**
 * AI-powered code review for staged changes
 */
import { Chat, LanguageModel } from '@effect/ai'
import { Effect, Schema } from 'effect'
import { AiGenerationError } from './errors.ts'

/** A single review issue (blocking or warning) */
export class ReviewIssue extends Schema.Class<ReviewIssue>('ReviewIssue')({
  file: Schema.optionalWith(Schema.String, { as: 'Option' }),
  line: Schema.optionalWith(Schema.Number, { as: 'Option' }),
  message: Schema.String,
  suggestion: Schema.optionalWith(Schema.String, { as: 'Option' }),
}) {}

/** Suggestion about potentially related unstaged changes */
export class UnstagedSuggestion extends Schema.Class<UnstagedSuggestion>('UnstagedSuggestion')({
  file: Schema.String,
  reason: Schema.String,
}) {}

/** Result of the code review */
export class ReviewResult extends Schema.Class<ReviewResult>('ReviewResult')({
  blocking: Schema.Array(ReviewIssue),
  warnings: Schema.Array(ReviewIssue),
  /** Unstaged files that appear related to the staged changes */
  unstagedSuggestions: Schema.optionalWith(Schema.Array(UnstagedSuggestion), { default: () => [] }),
}) {
  get hasBlocking(): boolean {
    return this.blocking.length > 0
  }

  get hasWarnings(): boolean {
    return this.warnings.length > 0
  }

  get hasUnstagedSuggestions(): boolean {
    return this.unstagedSuggestions.length > 0
  }

  get isClean(): boolean {
    return !this.hasBlocking && !this.hasWarnings
  }
}

const REVIEW_SYSTEM_PROMPT = `You are a senior engineer performing a code review on staged git changes.

Focus your review on the STAGED changes only. Analyze for:

## Blocking issues (must fix before commit)
- Bugs, logical errors, or incorrect behavior
- Security vulnerabilities (injection, XSS, exposed secrets, etc.)
- Breaking changes without migration path
- Critical missing error handling
- Type errors or incorrect type usage

## Warnings (should consider)
- Performance concerns
- Code style inconsistencies with surrounding code
- Missing documentation for public APIs
- Potential edge cases not handled
- TODO/FIXME comments added without tracking

For each issue, provide:
- The file and line number if applicable
- A clear, concise description of the issue
- A suggested fix when possible

## Unstaged suggestions (VERY STRICT criteria)
ONLY report unstaged files if you can verify IN THE DIFF that:
- The staged code directly imports/references a file that appears in the unstaged diff
- The unstaged file modifies the SAME function/class that is modified in staged changes
- The unstaged file is a test file for code that is being modified in staged changes

DO NOT report unstaged files based on:
- Assumptions about what "might" be related
- Similar naming patterns
- Being in the same directory
- General topic similarity

If you cannot point to a specific line in the staged diff that references the unstaged file, do NOT include it. When in doubt, leave it out. Return an empty array for unstagedSuggestions unless you have concrete evidence.

Be concise and actionable. Only report genuine issues - do not be overly pedantic.`

export interface ReviewOptions {
  /** Additional context to help guide the review */
  readonly context?: string | undefined
  /** Unstaged changes to check for potentially forgotten related changes */
  readonly unstagedDiff?: string | undefined
  /** Recent commit history for context */
  readonly recentCommits?: string | undefined
}

/** Reviews staged changes and returns blocking issues and warnings */
export const reviewChanges = (
  diff: string,
  options: ReviewOptions = {},
): Effect.Effect<
  ReviewResult,
  AiGenerationError,
  LanguageModel.LanguageModel
> =>
  Effect.gen(function* () {
    let systemPrompt = REVIEW_SYSTEM_PROMPT

    if (options.context) {
      systemPrompt += `\n\nAdditional context from the developer:\n${options.context}`
    }

    const chat = yield* Chat.fromPrompt([
      { role: 'system', content: systemPrompt },
    ])

    let prompt = ''

    if (options.recentCommits) {
      prompt += `## Recent commit history (for context):\n\n${options.recentCommits}\n\n`
    }

    prompt += `## Staged changes (to be committed):\n\n\`\`\`diff\n${diff}\n\`\`\``

    if (options.unstagedDiff) {
      prompt += `\n\n## Unstaged changes (not being committed):\n\n\`\`\`diff\n${options.unstagedDiff}\n\`\`\``
    }

    const response = yield* chat
      .generateObject({
        prompt,
        schema: ReviewResult,
        objectName: 'ReviewResult',
      })
      .pipe(
        Effect.catchAll((cause) =>
          Effect.fail(
            new AiGenerationError({
              cause,
              message: 'Failed to review changes',
            }),
          ),
        ),
      )

    return response.value
  }).pipe(Effect.withSpan('review.reviewChanges'))
