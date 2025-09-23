# gwt Fish CLI

`gwt` is the Git worktree helper exposed in the Fish shell configuration. The implementation lives in `cli.fish` with completions in `completion.fish`.

## Usage

| Subcommand   | Arguments                         | Purpose                                                     |
|--------------|-----------------------------------|-------------------------------------------------------------|
| `setup-repo` | `<repo> <git-url>`                | Bootstrap a repository into the `.main` worktree slot       |
| `new`        | `<repo> [slug] [--carry-changes]` | Create `<github-user>/YYYY-MM-DD-slug` off the default ref  |
| `branch`     | `<repo> <remote/branch>`          | Materialise a worktree for an existing remote branch        |
| `archive`    | `<repo> <worktree|branch>` *(or run inside worktree)* | Move a worktree under `.archive` and prune related metadata |
| `zellij`     | *(run inside worktree)*           | Attach to (or create) the canonical Zellij session for a worktree |

Example session:

```fish
$ gwt setup-repo livestore git@github.com:schickling/livestore.git
/home/schickling/code/worktrees/livestore/.main

$ gwt new livestore chore-fix-ci
/home/schickling/code/worktrees/livestore/schickling--2025-09-23-chore-fix-ci

$ gwt new livestore
/home/schickling/code/worktrees/livestore/schickling--2025-09-23-bright-curie-42

$ gwt new livestore --carry-changes
/home/schickling/code/worktrees/livestore/schickling--2025-09-23-valiant-ada-07

$ cd /home/schickling/code/worktrees/livestore/schickling--2025-09-23-bright-curie-42
$ gwt zellij
gwt: attaching to zellij session 'livestore--schickling--2025-09-23-bright-curie-42'
```

The second `gwt new` example shows the random Docker-style slug that is generated when no slug is provided.
The `gwt archive` command accepts either `gwt archive <repo> <worktree|branch>` or simply `gwt archive` when executed from inside a worktree directory.
Pass `--carry-changes` (from inside an existing worktree) to replicate staged, unstaged, and untracked changes in the new worktree via git patches.
The `gwt zellij` subcommand must be run from inside a worktree directory and refuses to start if you are already inside another Zellij session.

## Testing changes
- Run `home-manager switch --flake .#$(hostname)` from the repository root to rebuild your profile and reload the function and completions.
- Open a fresh Fish session (or `exec fish`) to pick up the updated definitions.
- Smoke-test the core flows, e.g. `gwt setup-repo <repo> <git-url>` and `gwt new <repo>`.

Note: keep `cli.fish` and `completion.fish` in sync whenever command names or flags change.
