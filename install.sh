#! /bin/bash

nix-channel --update
nix-env -iA nixpkgs.nix

nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz home-manager
nix-channel --update

export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

nix-shell '<home-manager>' -A install


pushd ~/.dotfiles/nixpkgs
home-manager switch --flake .#gitpod
popd
