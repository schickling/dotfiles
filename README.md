# Dotfiles (Nix Flake)

Declarative system and user configuration with Nix. Targets macOS (nix-darwin + Home Manager) and NixOS hosts.

Location
- Clone this repo at `~/.dotfiles` (assumed by paths and commands).

Quick Start
- macOS (darwin)
  - `nix build .#darwinConfigurations.mbp2025.system`
  - `./result/sw/bin/darwin-rebuild switch --flake .`
- Home Manager (current host)
  - `home-manager switch --flake .#$(hostname -s)`

Layout
- `flake.nix`, `hosts.nix` — flake entry + host matrix
- `lib/builders.nix` — pkgs builders and helpers
- `nixpkgs/darwin/` — shared darwin config; `remote-builder.nix` (uses `dev3`)
- `nixpkgs/home-manager/modules/` — user modules
  - `darwin-common.nix`, `common.nix`, `linux-common.nix`
  - `fish.nix` (shell, aliases, functions)
  - `tools.nix` (gh, ghostty, lsd, bat, ripgrep)
  - `ssh.nix` (match blocks; 1Password agent)
  - `macos/karabiner.nix`
- `nixpkgs/nixos/` — NixOS hosts (e.g. `dev3`, `homepi`)
- `flakes/` — local inputs (amp, codex, opencode, vibetunnel)
- `plan.md` — ongoing migration checklist

Policies
- Home Manager writes configs into `~/.config` (symlinks to Nix store). No repo → `~/.config` symlinks.
- Secrets are local-only. Examples:
  - GitHub CLI: HM manages `~/.config/gh/config.yml`. Tokens live in `~/.config/gh/hosts.yml`.
  - npm: HM exports `NPM_CONFIG_USERCONFIG` → `~/.config/npm/npmrc`.
- SSH is managed by HM (`~/.ssh/config`); uses 1Password agent.

Notes
- macOS can offload builds to `dev3` (see `nixpkgs/darwin/remote-builder.nix`).
- VS Code migration to HM is planned as a final step; current settings live in `VSCode/`.
