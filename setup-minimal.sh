#! /bin/bash

# configure git
git config --global user.name "Johannes Schickling"
git config --global user.email "schickling.j@gmail.com"
git config --global push.default simple

# setup bashrc
echo 'export DOTFILES=$HOME/.dotfiles' >> ~/.bashrc
echo 'source $DOTFILES/aliases/unix.sh' >> ~/.bashrc
echo 'source $DOTFILES/aliases/git.sh' >> ~/.bashrc
echo 'source ~/.bashrc' >> ~/.bash_profile

# setup dotfiles
git clone https://github.com/schickling/dotfiles.git ~/.dotfiles
source ~/.bashrc
mkdir -p ~/.vim/{backups,swaps}
ln -s ~/.dotfiles/vim/colors ~/.vim/colors
ln -s ~/.dotfiles/vimrc ~/.vimrc
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

# setup vundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
#vim +PluginInstall +qall
