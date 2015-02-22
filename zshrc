#########################
# exports ###############
#########################

DOTFILES=$HOME/.dotfiles
SECFILES=$HOME/.secret
PROJECTS=$HOME/Desktop/projects

# oh my zsh
ZSH=$DOTFILES/oh-my-zsh
ZSH_CUSTOM=$DOTFILES/oh-my-zsh-custom
plugins=(git npm brew go docker)
DEFAULT_USER="johannes"
UPDATE_ZSH_DAYS=4
ZSH_THEME="pure"

# paths
export EDITOR=vim
export DOCKER_HOST=tcp://192.168.59.103:2376
export DOCKER_CERT_PATH=$HOME/.boot2docker/certs/boot2docker-vm
export DOCKER_TLS_VERIFY=1
export GOPATH=$PROJECTS/go
export DOTFILES=$HOME/.dotfiles
#export PYTHONPATH=/usr/local/lib/python2.7/site-packages
#export PYTHONPATH=/usr/local/lib/python3.4/site-packages
export NVM_DIR=~/.nvm

unset PYTHONPATH

PATH=/usr/local/bin
PATH=/usr/bin:$PATH
PATH=/bin:$PATH
PATH=/usr/sbin:$PATH
PATH=/sbin:$PATH
PATH=/sbin:$PATH
PATH=/usr/local/bin:$PATH
PATH=/usr/local/sbin:$PATH
PATH=$HOME/.bin:$PATH
PATH=$DOTFILES/bin:$PATH
PATH=$HOME/Library/Haskell/bin:$PATH
PATH=$GOPATH/bin:$PATH

#########################
# sources ###############
#########################

source $ZSH/oh-my-zsh.sh
source $(brew --prefix)/etc/profile.d/z.sh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix nvm)/nvm.sh

for f in $DOTFILES/aliases/*.sh; do source $f; done

eval "$(direnv hook zsh)"

#########################
# keybinding ############
#########################

#set -o vi

#typeset -A key
#key[Up]=${terminfo[kcuu1]}
#key[Down]=${terminfo[kcud1]}

#[[ -n "${key[Up]}"   ]] && bindkey "${key[Up]}"   history-search-backward
#[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" history-search-forward
