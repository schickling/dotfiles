import { Schema } from 'effect'

export class NotInGitRepoError extends Schema.TaggedError<NotInGitRepoError>()(
  'NotInGitRepoError',
  {
    message: Schema.String,
  },
) {}

export class NoStagedChangesError extends Schema.TaggedError<NoStagedChangesError>()(
  'NoStagedChangesError',
  {
    message: Schema.String,
  },
) {}

export class GitCommandError extends Schema.TaggedError<GitCommandError>()(
  'GitCommandError',
  {
    cause: Schema.Defect,
    command: Schema.String,
    message: Schema.String,
  },
) {}

export class AiGenerationError extends Schema.TaggedError<AiGenerationError>()(
  'AiGenerationError',
  {
    cause: Schema.Defect,
    message: Schema.String,
  },
) {}

export class EmptyCommitMessageError extends Schema.TaggedError<EmptyCommitMessageError>()(
  'EmptyCommitMessageError',
  {
    message: Schema.String,
  },
) {}

export class ReviewAbortedError extends Schema.TaggedError<ReviewAbortedError>()(
  'ReviewAbortedError',
  {
    message: Schema.String,
  },
) {}

export class PreCommitHookError extends Schema.TaggedError<PreCommitHookError>()(
  'PreCommitHookError',
  {
    message: Schema.String,
  },
) {}
