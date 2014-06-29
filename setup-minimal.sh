#! /bin/bash

# clone dotfiles
git clone --recursive https://github.com/schickling/dotfiles.git ~/.dotfiles

# link vim
mkdir ~/.vim
ln -s ~/.dotfiles/vim/colors ~/.vim/colors
ln -s ~/.dotfiles/vimrc ~/.vimrc

# setup env
echo 'source ~/.dotfiles/aliases/unix.sh' >> ~/.bashrc
echo 'source ~/.dotfiles/aliases/git.sh' >> ~/.bashrc
echo 'export DOTFILES=~/.dotfiles' >> ~/.bashrc

# setup vundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
