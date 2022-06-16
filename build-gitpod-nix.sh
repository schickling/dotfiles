#!/usr/bin/bash -i

set -ex

nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz home-manager
nix-channel --update

nix-env -iA nixpkgs.nix

export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

nix-shell '<home-manager>' -A install

# Needed since Gitpod already has their own `direnv` version installed
# See https://discourse.nixos.org/t/home-manager-conflict-after-nix-upgrade/16967
nix-env --set-flag priority 4 direnv

pushd ~/.dotfiles/nixpkgs
home-manager switch --flake .#gitpod
popd

nix shell nixpkgs#google-cloud-sdk

gsutil cp result.closure.lz4 gs://schickling-gitpod-nix/result.closure.lz4