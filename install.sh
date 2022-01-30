#!/usr/bin/bash -iex

(

  _await_file="/tmp/await-dotfile";
  _bashrc="$(< "$HOME/.bashrc")";
  printf '%s\n' "until test -e \"$_await_file\"; do printf . && sleep 1; done" "$_bashrc" > "$HOME/.bashrc";
  
  date

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

  # Unlock the terminals

)
