#!/usr/bin/bash -i

# This script is ideally run on a Gitpod workspace.

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

# get path via `home-manager generations`
nix-store --export (nix-store -qR /nix/store/mpkhk2l3036rb1516b2cfzbr4bb8gpag-home-manager-generation) | lz4 > result.closure.lz4

# Requires `gcloud auth login` before running
# (will prompt to run a similar command on machine with visual browser e.g. Mac)
nix shell nixpkgs#google-cloud-sdk --command gcloud auth login

nix shell nixpkgs#google-cloud-sdk --command gsutil cp result.closure.lz4 gs://schickling-gitpod-nix/result.closure.lz4
nix shell nixpkgs#google-cloud-sdk --command gsutil acl ch -u AllUsers:R gs://schickling-gitpod-nix/result.closure.lz4