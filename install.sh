#! /bin/bash

DOTFILES=$( cd $(dirname $0) ; pwd -P )

# zsh
ln -sf $DOTFILES/zshrc ~/.zshrc

# vim
ln -sf $DOTFILES/vimrc ~/.vimrc

# tmux
ln -sf $DOTFILES/tmux.conf ~/.tmux.conf
