# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
DOTFILES=$HOME/.dotfiles

plugins=(git npm composer grunt bower gem rake brew go docker)
DEFAULT_USER="johannes"
UPDATE_ZSH_DAYS=4
ZSH_THEME="agnoster"

source $ZSH/oh-my-zsh.sh

for f in $DOTFILES/zsh/*.zsh; do source $f; done
