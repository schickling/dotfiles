#! /bin/bash

# clone dotfiles
git clone https://github.com/schickling/dotfiles.git ~/.dotfiles

# link vim
ln -s ~/.dotfiles/vim/bundle ~/.vim/bundle
ln -s ~/.dotfiles/vim/colors ~/.vim/colors
ln -s ~/.dotfiles/vimrc ~/.vimrc

# setup env
echo "export DOTFILES=$HOME/.dotfiles" >> ~/.bashrc
echo "source $DOTFILES/aliases/unix.sh" >> ~/.bashrc
echo "source $DOTFILES/aliases/git.sh" >> ~/.bashrc
