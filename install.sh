#! /bin/bash

set -e

# install script for gitpod dotfiles support
# https://gitpod.notion.site/Dotfiles-in-Gitpod-workspaces-b46b8723e9fe4efdbede72daa311961f

mv ~/.config ~/.config-backup
ln -sv $HOME/.dotfiles $HOME/.config
mv ~/.config/fish ~/.config/fish-backup

nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz home-manager
nix-channel --update

nix-env -iA nixpkgs.nix

export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

nix-shell '<home-manager>' -A install


pushd ~/.dotfiles/nixpkgs
home-manager switch --flake .#gitpod
popd
