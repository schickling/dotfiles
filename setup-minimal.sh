#! /bin/bash

# link vim
mkdir ~/.vim
ln -s ~/.dotfiles/vim/colors ~/.vim/colors
ln -s ~/.dotfiles/vimrc ~/.vimrc

# setup env
echo "export DOTFILES=$HOME/.dotfiles" >> ~/.bashrc
echo "source $DOTFILES/aliases/unix.sh" >> ~/.bashrc
echo "source $DOTFILES/aliases/git.sh" >> ~/.bashrc

# setup vundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
