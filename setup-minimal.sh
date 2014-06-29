#! /bin/bash

# setup dotfiles
git clone https://github.com/schickling/dotfiles.git ~/.dotfiles

# set env
echo "export DOTFILES=$HOME/.dotfiles" >> ~/.bashrc
echo "source $DOTFILES/aliases/unix.sh" >> ~/.bashrc
echo "source $DOTFILES/aliases/git.sh" >> ~/.bashrc
source ~/.bashrc

# setup vim
wget -P ~/.vim/colors https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim
ln -s $DOTFILES/vimrc ~/.vimrc

# setup vundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
