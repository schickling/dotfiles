# dotfiles

Almost everything is set up using Nix.

## Includes

- fish
- tmux
- neovim
- ...

## Gitpod workflows

- I've configured Gitpod to pickup the [`install.sh`](./install.sh) file to set up my dotfiles for every new workspace
- The dotfiles setup can be skipped by setting `GITPOD_DOTFILES_SKIP=1`
  - Example: `https://gitpod.io/#GITPOD_DOTFILES_SKIP=1/https://github.com/contentlayerdev/videos`

## Related

- Video of me helping @paulshen to set up Nix on macOS: https://youtu.be/1dzgVkgQ5mE

## Inspiration

### Nix

- https://github.com/nitsky/config
- https://github.com/pimeys/nixos
- https://github.dev/Mic92/dotfiles/blob/master/nixos/eve/modules/home-assistant/weather.nix
- https://github.com/PaulGrandperrin/nix-systems
- https://github.com/fufexan/dotfiles (deploy-rs, distributed builds)

## TODO

- Rename to `nixconfig` and re-clone on machines as `~/.nixconfig` instead of `~/.config`
- Move to Nix: Tmux
- Auto-link VSC settings (e.g. via nix-darwin)
- Improved macOS settings via nix-darwin
- Gitpod: auto-generate `result.closure.lz` in CI [#18](https://github.com/schickling/dotfiles/issues/18)
