#!/usr/bin/bash -i

set -ex

date

# Run in background as it's blocking
sudo tailscaled &> ~/.tailscale.log &

time sudo -E tailscale up --hostname "gitpod-${GITPOD_WORKSPACE_ID}" --authkey "${TAILSCALE_AUTHKEY}"

date

mkdir -p ~/.ssh
# created via `cat ~/.ssh/id_rsa | base64 -w 0`
echo "${SSHKEY_PRIVATE}" | base64 --decode > ~/.ssh/id_rsa
echo "${SSHKEY_PUBLIC}" | base64 --decode > ~/.ssh/id_rsa.pub
chmod 400 ~/.ssh/id_rsa

ssh -o "StrictHostKeyChecking no" schickling@100.110.12.76 "echo ok"

# wget --no-verbose https://storage.googleapis.com/gitpod-test/nix-store.tar

# date

# tar -xv nix-store.tar -C /

# date


nix-copy-closure --from schickling@100.110.12.76 /nix/store/jvkqf636nzw4y6j9908innfgwyyh9f2z-home-manager-generation

date

/nix/store/jvkqf636nzw4y6j9908innfgwyyh9f2z-home-manager-generation/activate

date

# TMP Return early
exit 0

# link VSC settings

# install script for gitpod dotfiles support
# https://gitpod.notion.site/Dotfiles-in-Gitpod-workspaces-b46b8723e9fe4efdbede72daa311961f

mv ~/.config/nix ~/.config/nix-backup
ln -sv $HOME/.dotfiles/nix $HOME/.config/nix
mv ~/.config/nixpkgs ~/.config/nixpkgs-backup
ln -sv $HOME/.dotfiles/nixpkgs $HOME/.config/nixpkgs

nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz home-manager
nix-channel --update

nix-env -iA nixpkgs.nix

export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

nix-shell '<home-manager>' -A install

pushd ~/.config/nixpkgs
home-manager switch --flake .#gitpod
popd

# use VSC settings.json from dotfiles
mkdir -p $HOME/.config/Code/User
mv $HOME/.config/Code/User/settings.json $HOME/.config/Code/User/settings.json-backup
ln -s $HOME/.dotfiles/VSCode/settings.json $HOME/.config/Code/User/settings.json

date
