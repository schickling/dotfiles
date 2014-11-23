# config ##############
alias cv="v $DOTFILES/vim/config.vim"
alias cbundle="v $DOTFILES/vim/plugins.vim"
alias ct="v $DOTFILES/aliases/misc.sh"
alias cm="v $DOTFILES/tmux.conf"
alias ck="v $HOME/.ssh/known_hosts"
alias cs="v $HOME/.ssh/config"
alias ch="sudo v /etc/hosts"
alias dot="cd $DOTFILES"
alias sec="cd $SECFILES"

# misc ################
alias sshkey="cat ~/.ssh/id_rsa.pub | pbcopy && echo 'Copied to clipboard.'"
alias rr="source $HOME/.zshrc && clear"
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"
alias ard="vlc http://daserste_live-lh.akamaihd.net/i/daserste_de@91204/master.m3u8"
alias ws="python -m SimpleHTTPServer"
alias lip="ifconfig en0 | grep 'inet ' | cut -d' ' -f2"
alias lo="pmset displaysleepnow"
alias todo="v ~/Dropbox/Documents/TODO.md"

# docker ##############
alias d="docker"
alias dcc="docker ps -q | xargs docker kill ; docker ps -aq | xargs docker rm"
alias dci="dcc && docker images -q | xargs docker rmi"
alias dir="docker run -i -t --rm"
alias b2d="boot2docker"

# haskell #############
alias ghci="ghci -v0"
alias h="ghci"

# karma ###############
alias k="karma start"
alias kd="karma start --browsers /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"

# repeats a command
function again() {
	while [ 1 ]; do
		eval $2 $3 $4 $5
		sleep $1
	done
}

function de() {
  docker exec -it $1 bash
}

function dknown() {
  vim ~/.ssh/known_hosts +$1 +d +wq
}

function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

function dri() {
  docker ps -a | grep $1 | cut -f 1 -d " " | xargs docker kill | xargs docker rm && docker rmi $1
}
