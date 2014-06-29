#! /bin/bash

DOTFILES=$( cd $(dirname $0) ; pwd -P )

# zsh
ln -sf $DOTFILES/zshrc ~/.zshrc

# vim
ln -sf $DOTFILES/vimrc ~/.vimrc

# tmux
ln -sf $DOTFILES/tmux/tmux.conf ~/.tmux.conf
ln -sf $DOTFILES/tmux/tmux.conf.user ~/.tmux.conf.user
