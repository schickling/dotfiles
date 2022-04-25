#!/usr/bin/bash -i

set -ex

# install script for gitpod dotfiles support
# https://gitpod.notion.site/Dotfiles-in-Gitpod-workspaces-b46b8723e9fe4efdbede72daa311961f

date
echo "Starting Gitpod install.sh..."

if [[ -n "${GITPOD_DOTFILES_SKIP}" ]]; then
	echo "Exiting Gitpod install.sh early..."
	exit
fi

setup_tailscale() {
	# Run in background as it's blocking
	sudo tailscaled &> ~/.tailscale.log &

	time sudo -E tailscale up --hostname "gitpod-${GITPOD_WORKSPACE_ID}" --authkey "${TAILSCALE_AUTHKEY}"

	date

	# This is a special SSH key that allows my Gitpod instances to access my other Tailscale machines
	mkdir -p ~/.ssh
	# created via `cat ~/.ssh/id_rsa | base64 -w 0` on my main machine
	echo "${SSHKEY_PRIVATE}" | base64 --decode > ~/.ssh/id_rsa
	echo "${SSHKEY_PUBLIC}" | base64 --decode > ~/.ssh/id_rsa.pub
	chmod 400 ~/.ssh/id_rsa
}

main() {
	setup_tailscale &

	# TODO this ideally lz4 should come pre-installed on Gitpod
	sudo apt-get install lz4

	date

	NIX_RESULT_PATH=$(curl https://storage.googleapis.com/gitpod-test/result.closure.lz4 | lz4 -d  | nix-store --import | tail -1)

	date

	$NIX_RESULT_PATH/activate

	# link VSC settings

	# use VSC settings.json from dotfiles
	mkdir -p $HOME/.config/Code/User
	mv $HOME/.config/Code/User/settings.json $HOME/.config/Code/User/settings.json-backup
	ln -s $HOME/.dotfiles/VSCode/settings.json $HOME/.config/Code/User/settings.json

	date
}

time main