import { Chat, LanguageModel } from '@effect/ai'
import { OpenAiClient, OpenAiLanguageModel } from '@effect/ai-openai'
import { FetchHttpClient } from '@effect/platform'
import { NodeCommandExecutor } from '@effect/platform-node'
import { Config, Effect, Layer, Option } from 'effect'
import * as ClaudeCli from './claude-cli.ts'
import { AiGenerationError, EmptyCommitMessageError } from './errors.ts'

const SYSTEM_PROMPT = `You are a senior engineer writing a git commit message for the staged diff below. Produce text in this exact format: A single short first line summary (<=72 chars), then a blank line, then a concise list of semantic changes (bullets or short paragraphs). Do not add quotes, prefixes, git trailers, or commentary. Only describe changes present in the staged diff.`
const CLAUDE_REVIEW_MODEL = 'opus'
const CLAUDE_COMMIT_MODEL = 'sonnet'

/** Generates a commit message from a diff using AI */
export const generateCommitMessage = (
  diff: string,
): Effect.Effect<
  string,
  AiGenerationError | EmptyCommitMessageError,
  LanguageModel.LanguageModel
> =>
  Effect.gen(function* () {
    const chat = yield* Chat.fromPrompt([
      { role: 'system', content: SYSTEM_PROMPT },
    ])

    const response = yield* chat.generateText({ prompt: diff }).pipe(
      Effect.catchAll((cause) =>
        Effect.fail(
          new AiGenerationError({
            cause,
            message: 'Failed to generate commit message',
          }),
        ),
      ),
    )

    const message = response.text.trim()

    if (message.length === 0) {
      return yield* new EmptyCommitMessageError({
        message: 'AI returned an empty commit message',
      })
    }

    return message
  }).pipe(Effect.withSpan('ai.generateCommitMessage'))

/** Layer providing OpenAI client configured from environment */
export const OpenAiLive = Layer.unwrapEffect(
  Effect.gen(function* () {
    const apiKey = yield* Config.redacted('OPENAI_API_KEY')

    const client = OpenAiClient.layerConfig({
      apiKey: Config.succeed(apiKey),
    })

    const model = OpenAiLanguageModel.model('gpt-4o').pipe(
      Layer.provide(client),
    )

    return model
  }),
).pipe(Layer.provide(FetchHttpClient.layer))

/** Layer providing Claude CLI as the LanguageModel */
export const ClaudeCliReviewLive = ClaudeCli.layer({ model: CLAUDE_REVIEW_MODEL }).pipe(
  Layer.provide(NodeCommandExecutor.layer),
)

/** Layer providing Claude CLI as the LanguageModel */
export const ClaudeCliCommitLive = ClaudeCli.layer({ model: CLAUDE_COMMIT_MODEL }).pipe(
  Layer.provide(NodeCommandExecutor.layer),
)

/**
 * Smart layer that uses OpenAI if OPENAI_API_KEY is set, otherwise Claude CLI.
 * Prefers Claude CLI since it doesn't require separate API key management.
 */
export const AiReviewLive = Layer.unwrapEffect(
  Effect.gen(function* () {
    const openAiKey = yield* Config.option(Config.redacted('OPENAI_API_KEY'))

    if (Option.isSome(openAiKey)) {
      return OpenAiLive
    }

    return ClaudeCliReviewLive
  }),
)

/**
 * Smart layer that uses OpenAI if OPENAI_API_KEY is set, otherwise Claude CLI.
 * Prefers Claude CLI since it doesn't require separate API key management.
 */
export const AiCommitLive = Layer.unwrapEffect(
  Effect.gen(function* () {
    const openAiKey = yield* Config.option(Config.redacted('OPENAI_API_KEY'))

    if (Option.isSome(openAiKey)) {
      return OpenAiLive
    }

    return ClaudeCliCommitLive
  }),
)
