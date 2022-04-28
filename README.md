# dotfiles

NOTE: These dotfiles a heavily work in progress. Most things are being moved to Nix right now.

## Includes

- fish
- tmux
- neovim
- ...

## TODO move to Nix

- Vim/Nvim (unify)
- Tmux
- Makefile stuff

## Gitpod workflows

- I've configured Gitpod to pickup the [`install.sh`](./install.sh) file to set up my dotfiles for every new workspace
- TODO auto-generate `result.closure.lz` in CI [#18](https://github.com/schickling/dotfiles/issues/18)
- The dotfiles setup can be skipped by setting `GITPOD_DOTFILES_SKIP=1`
  - Example: `https://gitpod.io/#GITPOD_DOTFILES_SKIP=1/https://github.com/contentlayerdev/videos`

## Related

- Video of me helping @paulshen to set up Nix on macOS: https://youtu.be/1dzgVkgQ5mE

## Inspiration

- https://github.com/nitsky/config
- https://github.com/pimeys/nixos
- https://github.dev/Mic92/dotfiles/blob/master/nixos/eve/modules/home-assistant/weather.nix
