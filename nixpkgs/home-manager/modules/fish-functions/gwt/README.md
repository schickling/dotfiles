# gwt Fish CLI

`gwt` is the Git worktree helper exposed in the Fish shell configuration. The implementation lives in `cli.fish` with completions in `completion.fish`.

## Usage

| Subcommand   | Purpose                                                     |
|--------------|-------------------------------------------------------------|
| `setup-repo` | Bootstrap a repository into the `.main` worktree slot       |
| `new`        | Create `<github-user>/YYYY-MM-DD-slug` off the default ref  |
| `branch`     | Materialise a worktree for an existing remote branch        |
| `archive`    | Move a worktree under `.archive` and prune related metadata |

Example session:

```fish
$ gwt setup-repo livestore git@github.com:schickling/livestore.git
/home/schickling/code/worktrees/livestore/.main

$ gwt new livestore chore-fix-ci
/home/schickling/code/worktrees/livestore/schickling--2025-09-23-chore-fix-ci

$ gwt new livestore
/home/schickling/code/worktrees/livestore/schickling--2025-09-23-bright-curie-42
```

The second `gwt new` example shows the random Docker-style slug that is generated when no slug is provided.

## Testing changes
- Run `home-manager switch --flake .#$(hostname)` from the repository root to rebuild your profile and reload the function and completions.
- Open a fresh Fish session (or `exec fish`) to pick up the updated definitions.
- Smoke-test the core flows, e.g. `gwt setup-repo <repo> <git-url>` and `gwt new <repo>`.

Note: keep `cli.fish` and `completion.fish` in sync whenever command names or flags change.
