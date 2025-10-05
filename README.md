# dotfiles

Almost everything is set up using Nix.

## Declarative config (Home Manager)

The following user-level tools are managed declaratively via Home Manager modules in `nixpkgs/home-manager/modules`:

- fish, git, neovim, lazygit, ssh, zellij, tmux (existing)
- NEW: GitHub CLI (`gh`), Ghostty, lsd, bat, ripgrep (grouped in `nixpkgs/home-manager/modules/tools.nix`)

Notes
- `gh`: Only non-secret `config.yml` is managed. Do not manage `hosts.yml` (tokens).
- `ghostty`: Managed via `xdg.configFile` to write `~/.config/ghostty/config` (see `modules/tools.nix`). Switch to a native `programs.ghostty` module if available in your HM channel.
- If any of these had `~/.config/<name>` pointing into the repo, remove the symlink so Home Manager writes real files outside the repo.

Apply
- macOS (darwin): `nix build .#darwinConfigurations.mbp2025.system; ./result/sw/bin/darwin-rebuild switch --flake .`
- Linux (dev hosts): `home-manager switch --flake ~/.dotfiles#<host>`

 

## Related

- Video of me helping @paulshen to set up Nix on macOS: https://youtu.be/1dzgVkgQ5mE

## Inspiration

### Nix

- https://github.com/nitsky/config
- https://github.com/pimeys/nixos
- https://github.dev/Mic92/dotfiles/blob/master/nixos/eve/modules/home-assistant/weather.nix
- https://github.com/PaulGrandperrin/nix-systems
- https://github.com/fufexan/dotfiles (deploy-rs, distributed builds)
- https://github.com/viperML/neoinfra

## TODO

- Rename to `nixconfig` and re-clone on machines as `~/.nixconfig` instead of `~/.config`
- Move to Nix: Tmux
- Auto-link VSC settings (e.g. via nix-darwin)
- Improved macOS settings via nix-darwin

## Notes

- Currently NixOS doesn't support RPI5
