# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
DOTFILES=$HOME/.dotfiles

plugins=(git node npm capistrano composer grunt bower yeoman vagrant gem rake heroku brew pip go)
DEFAULT_USER="johannes"
UPDATE_ZSH_DAYS=4
ZSH_THEME="agnoster"

source $ZSH/oh-my-zsh.sh
source $DOTFILES/.zsh.init
source $DOTFILES/.zsh.path
source $DOTFILES/.zsh.alias
source $DOTFILES/.zsh.functions

