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
}) {}

/** Result of the code review */
export class ReviewResult extends Schema.Class<ReviewResult>('ReviewResult')({
  blocking: Schema.Array(ReviewIssue),
  warnings: Schema.Array(ReviewIssue),
}) {
  get hasBlocking(): boolean {
    return this.blocking.length > 0
  }

  get hasWarnings(): boolean {
    return this.warnings.length > 0
  }

  get isClean(): boolean {
    return !this.hasBlocking && !this.hasWarnings
  }
}

const REVIEW_SYSTEM_PROMPT = `You are a senior engineer reviewing staged git changes. Analyze the diff for:

1. **Blocking issues** (must be fixed before commit):
   - Bugs or logical errors
   - Security vulnerabilities
   - Breaking changes without migration
   - Missing error handling for critical paths
   - Hardcoded secrets or credentials

2. **Warnings** (should consider fixing):
   - Performance concerns
   - Code style inconsistencies
   - Missing documentation for public APIs
   - Potential edge cases
   - TODO/FIXME comments added

Keep messages concise but actionable. If no issues found, return empty arrays.`

export interface ReviewOptions {
  /** Additional context to help guide the review */
  readonly context?: string | undefined
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
    const systemPrompt = options.context
      ? `${REVIEW_SYSTEM_PROMPT}\n\nAdditional context from the developer:\n${options.context}`
      : REVIEW_SYSTEM_PROMPT

    const chat = yield* Chat.fromPrompt([
      { role: 'system', content: systemPrompt },
    ])

    const response = yield* chat
      .generateObject({
        prompt: diff,
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
