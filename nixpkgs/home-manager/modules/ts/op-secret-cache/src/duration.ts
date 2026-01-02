import { Effect, Schema } from 'effect'

/** Error when duration string is invalid */
export class InvalidDurationError extends Schema.TaggedError<InvalidDurationError>()('InvalidDurationError', {
  message: Schema.String,
  input: Schema.String,
}) {}

/** Parse a duration string like "1h", "7d", "30m" into milliseconds */
export const parseDuration = (input: string): Effect.Effect<number, InvalidDurationError> => {
  const match = input.match(/^(\d+)(s|m|h|d|w)$/)
  if (!match) {
    return Effect.fail(new InvalidDurationError({
      message: `Invalid duration format. Expected: <number><unit> where unit is s/m/h/d/w (e.g., "1h", "7d", "30m")`,
      input,
    }))
  }

  const value = parseInt(match[1]!, 10)
  const unit = match[2]!

  const multipliers: Record<string, number> = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
    w: 7 * 24 * 60 * 60 * 1000,
  }

  const multiplier = multipliers[unit]
  if (!multiplier) {
    return Effect.fail(new InvalidDurationError({
      message: `Unknown duration unit: ${unit}`,
      input,
    }))
  }

  return Effect.succeed(value * multiplier)
}

/** Format milliseconds as a human-readable duration */
export const formatDuration = (ms: number): string => {
  const seconds = Math.floor(ms / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  const weeks = Math.floor(days / 7)

  if (weeks > 0) return `${weeks}w`
  if (days > 0) return `${days}d`
  if (hours > 0) return `${hours}h`
  if (minutes > 0) return `${minutes}m`
  return `${seconds}s`
}

/** Format a date as relative time (e.g., "2 hours ago", "in 3 days") */
export const formatRelativeTime = (date: Date): string => {
  const now = new Date()
  const diffMs = date.getTime() - now.getTime()
  const absDiffMs = Math.abs(diffMs)
  const isPast = diffMs < 0

  const duration = formatDuration(absDiffMs)
  return isPast ? `${duration} ago` : `in ${duration}`
}
