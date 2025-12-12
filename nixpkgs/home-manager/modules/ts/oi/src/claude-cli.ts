/**
 * Claude CLI LanguageModel provider for Effect AI
 *
 * Implements the LanguageModel interface by delegating to the `claude` CLI,
 * allowing use without OpenAI API keys by re-using Claude CLI authentication.
 */
import { AiError, LanguageModel, Prompt, Response } from '@effect/ai'
import { Command, CommandExecutor } from '@effect/platform'
import type { PlatformError } from '@effect/platform/Error'
import { Effect, Exit, JSONSchema, Layer, Ref, Scope, Stream } from 'effect'

/** Options for the Claude CLI provider */
export interface ClaudeCliOptions {
  /** Model to use (e.g. 'sonnet', 'opus', 'haiku') */
  readonly model?: string
  /** Additional tools to allow */
  readonly allowedTools?: string
}

/** Converts Effect AI prompt to a string for claude CLI */
const promptToString = (
  prompt: Prompt.Prompt,
  responseFormat: LanguageModel.ProviderOptions['responseFormat'],
): string => {
  const parts: string[] = []

  for (const message of prompt.content) {
    if (message.role === 'system') {
      // SystemMessage has content as string
      parts.push(`[System]: ${message.content}`)
    } else if (message.role === 'user') {
      // UserMessage has content as array of parts
      for (const part of message.content) {
        if (part.type === 'text') {
          parts.push(part.text)
        }
      }
    } else if (message.role === 'assistant') {
      // AssistantMessage has content as array of parts
      for (const part of message.content) {
        if (part.type === 'text') {
          parts.push(`[Assistant]: ${part.text}`)
        }
      }
    }
  }

  // Add JSON schema instructions if JSON response format is requested
  if (responseFormat.type === 'json') {
    const jsonSchema = JSONSchema.make(responseFormat.schema)
    parts.push(
      `[System]: CRITICAL: Your response must be ONLY raw JSON. Do NOT use markdown code blocks (\`\`\`). Do NOT add any explanation before or after. Start your response with { and end with }. The JSON must conform to this schema:\n${JSON.stringify(jsonSchema, null, 2)}`,
    )
  }

  return parts.join('\n\n')
}

/** Schema for Claude CLI JSON output */
interface ClaudeCliJsonOutput {
  readonly type: 'result'
  readonly subtype: 'success' | 'error'
  readonly result?: string
  readonly total_cost_usd?: number
  readonly session_id?: string
}

/** Strip markdown code blocks from text (for JSON responses) */
const stripMarkdownCodeBlocks = (text: string): string => {
  // Remove ```json ... ``` or ``` ... ``` wrappers
  const codeBlockMatch = text.match(/^```(?:json)?\s*\n?([\s\S]*?)\n?```$/m)
  if (codeBlockMatch?.[1]) {
    return codeBlockMatch[1].trim()
  }
  return text.trim()
}

/** Wrap platform errors into AiError */
const wrapPlatformError = (error: PlatformError): AiError.AiError =>
  new AiError.UnknownError({
    module: 'claude-cli',
    method: 'command',
    description: error.message,
    cause: error,
  })

/** Creates a LanguageModel that delegates to claude CLI */
export const make = (
  options: ClaudeCliOptions = {},
): Effect.Effect<LanguageModel.Service, never, CommandExecutor.CommandExecutor> =>
  Effect.gen(function* () {
    const executor = yield* CommandExecutor.CommandExecutor

    const generateText = (
      providerOptions: LanguageModel.ProviderOptions,
    ): Effect.Effect<Array<Response.PartEncoded>, AiError.AiError> =>
      Effect.gen(function* () {
        const promptText = promptToString(providerOptions.prompt, providerOptions.responseFormat)

        const args = [
          '-p', // print mode
          '--output-format',
          'json',
          '--tools',
          '', // disable tools for simple text generation
        ]

        if (options.model) {
          args.push('--model', options.model)
        }

        const command = Command.make('claude', ...args).pipe(Command.stdin('pipe'))

        const result = yield* Effect.scoped(
          Effect.gen(function* () {
            const process = yield* executor.start(command)

            // Write prompt to stdin
            yield* Stream.make(new TextEncoder().encode(promptText)).pipe(
              Stream.run(process.stdin),
            )

            const stdout = yield* Stream.runCollect(
              Stream.decodeText(process.stdout),
            ).pipe(Effect.map((chunks) => Array.from(chunks).join('')))

            const exitCode = yield* process.exitCode

            return { stdout, exitCode }
          }),
        ).pipe(Effect.mapError(wrapPlatformError))

        if (result.exitCode !== 0) {
          return yield* new AiError.UnknownError({
            module: 'claude-cli',
            method: 'generateText',
            description: `Claude CLI exited with code ${result.exitCode}`,
          })
        }

        const lines = result.stdout.trim().split('\n')
        let resultText = ''

        for (const line of lines) {
          if (!line.trim()) continue
          try {
            const parsed = JSON.parse(line) as ClaudeCliJsonOutput
            if (parsed.type === 'result' && parsed.subtype === 'success' && parsed.result) {
              resultText = parsed.result
            } else if (parsed.type === 'result' && parsed.subtype === 'error') {
              return yield* new AiError.UnknownError({
                module: 'claude-cli',
                method: 'generateText',
                description: `Claude CLI returned error: ${parsed.result ?? 'Unknown error'}`,
              })
            }
          } catch {
            // Skip non-JSON lines
          }
        }

        if (!resultText) {
          return yield* new AiError.UnknownError({
            module: 'claude-cli',
            method: 'generateText',
            description: 'Claude CLI returned no result',
          })
        }

        // Strip markdown code blocks if JSON response format is expected
        const finalText =
          providerOptions.responseFormat.type === 'json'
            ? stripMarkdownCodeBlocks(resultText)
            : resultText

        const parts: Array<Response.PartEncoded> = [
          { type: 'text', text: finalText },
          {
            type: 'finish',
            reason: 'stop',
            usage: {
              inputTokens: undefined,
              outputTokens: undefined,
              totalTokens: undefined,
            },
          },
        ]

        return parts
      }).pipe(
        Effect.catchAllDefect((defect) =>
          new AiError.UnknownError({
            module: 'claude-cli',
            method: 'generateText',
            description: `Unexpected error: ${String(defect)}`,
            cause: defect,
          }),
        ),
      )

    const streamText = (
      providerOptions: LanguageModel.ProviderOptions,
    ): Stream.Stream<Response.StreamPartEncoded, AiError.AiError> =>
      Stream.unwrap(
        Effect.gen(function* () {
          const promptText = promptToString(providerOptions.prompt, providerOptions.responseFormat)

          const args = [
            '-p',
            '--output-format',
            'stream-json',
            '--tools',
            '',
          ]

          if (options.model) {
            args.push('--model', options.model)
          }

          const command = Command.make('claude', ...args).pipe(Command.stdin('pipe'))

          const scope = yield* Scope.make()
          const startEmittedRef = yield* Ref.make(false)

          const process = yield* executor.start(command).pipe(
            Effect.provideService(Scope.Scope, scope),
            Effect.mapError(wrapPlatformError),
          )

          // Write prompt to stdin
          yield* Stream.make(new TextEncoder().encode(promptText)).pipe(
            Stream.run(process.stdin),
          ).pipe(Effect.mapError(wrapPlatformError))

          const textId = 'text-0'

          const outputStream: Stream.Stream<Response.StreamPartEncoded, AiError.AiError> = process.stdout.pipe(
            Stream.decodeText(),
            Stream.splitLines,
            Stream.filter((line) => line.trim().length > 0),
            Stream.mapError(wrapPlatformError),
            Stream.mapEffect((line) =>
              Effect.gen(function* () {
                try {
                  const parsed = JSON.parse(line) as {
                    type?: string
                    subtype?: string
                    result?: string
                    message?: { content?: string }
                    delta?: { text?: string }
                  }

                  if (parsed.type === 'assistant' && parsed.message?.content) {
                    const content = parsed.message.content
                    if (typeof content === 'string') {
                      const startEmitted = yield* Ref.get(startEmittedRef)
                      const parts: Response.StreamPartEncoded[] = []
                      if (!startEmitted) {
                        parts.push({ type: 'text-start', id: textId })
                        yield* Ref.set(startEmittedRef, true)
                      }
                      parts.push({ type: 'text-delta', id: textId, delta: content })
                      return parts
                    }
                  }

                  if (parsed.type === 'content_block_delta' && parsed.delta?.text) {
                    const startEmitted = yield* Ref.get(startEmittedRef)
                    const parts: Response.StreamPartEncoded[] = []
                    if (!startEmitted) {
                      parts.push({ type: 'text-start', id: textId })
                      yield* Ref.set(startEmittedRef, true)
                    }
                    parts.push({ type: 'text-delta', id: textId, delta: parsed.delta.text })
                    return parts
                  }

                  if (parsed.type === 'result') {
                    if (parsed.subtype === 'success' && parsed.result) {
                      const startEmitted = yield* Ref.get(startEmittedRef)
                      const parts: Response.StreamPartEncoded[] = []
                      if (!startEmitted) {
                        parts.push({ type: 'text-start', id: textId })
                      }
                      parts.push({ type: 'text-delta', id: textId, delta: parsed.result })
                      parts.push({ type: 'text-end', id: textId })
                      return parts
                    }
                    if (parsed.subtype === 'error') {
                      return yield* new AiError.UnknownError({
                        module: 'claude-cli',
                        method: 'streamText',
                        description: `Claude CLI error: ${parsed.result ?? 'Unknown'}`,
                      })
                    }
                  }

                  return [] as Response.StreamPartEncoded[]
                } catch {
                  return [] as Response.StreamPartEncoded[]
                }
              }),
            ),
            Stream.flatMap((parts) => Stream.fromIterable(parts)),
            Stream.ensuring(Scope.close(scope, Exit.void)),
          )

          const finishPart: Response.StreamPartEncoded = {
            type: 'finish',
            reason: 'stop',
            usage: {
              inputTokens: undefined,
              outputTokens: undefined,
              totalTokens: undefined,
            },
          }

          return Stream.concat(outputStream, Stream.succeed(finishPart))
        }),
      )

    return yield* LanguageModel.make({ generateText, streamText })
  })

/** Layer providing Claude CLI as the LanguageModel */
export const layer = (
  options: ClaudeCliOptions = {},
): Layer.Layer<LanguageModel.LanguageModel, never, CommandExecutor.CommandExecutor> =>
  Layer.effect(LanguageModel.LanguageModel, make(options))
