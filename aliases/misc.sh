# config ##############
alias cv="v $DOTFILES/vim/settings/config.vim"
alias cbundle="v $DOTFILES/vim/settings/plugins.vim"
alias ct="v $DOTFILES/aliases/misc.sh"
alias cm="v $DOTFILES/tmux.conf"
alias ck="v $HOME/.ssh/known_hosts"
alias cs="v $HOME/.ssh/config"
alias ch="sudo v /etc/hosts"
alias dot="cd $DOTFILES"

# misc ################
alias sshkey="cat ~/.ssh/id_rsa.pub | pbcopy && echo 'Copied to clipboard.'"
alias rnginx="sudo nginx -s stop && sudo nginx"
alias rr="source $HOME/.zshrc && clear"
alias rbundle="rm Gemfile.lock && bundle"
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"
alias ard="vlc http://daserste_live-lh.akamaihd.net/i/daserste_de@91204/master.m3u8"
alias ym="youtube-dl -x"
alias ws="python -m SimpleHTTPServer"
alias lip="ifconfig en0 | grep 'inet ' | cut -d' ' -f2"
alias lo="pmset displaysleepnow"
alias tl="translate {=de}"

# cordova #############
alias cor="cordova"
alias cb="cordova build"

# docker ##############
alias d="docker"
alias dcc="docker ps -q | xargs docker kill && docker ps -a -q | xargs docker rm"
alias dci="dcc && docker images -q | xargs docker rmi"
alias dir="docker run -i -t"
alias b2d="boot2docker"

# folders #############
alias dr="cd $HOME/Dropbox"
alias de="cd $HOME/Desktop"
alias p="cd $HOME/Desktop/projects"

# haskell #############
alias ghci="ghci -v0"
alias h="ghci"

# karma ###############
alias k="karma start"
alias kd="karma start --browsers /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"

# php #################
alias c="composer"
alias a="php artisan"
alias pu="phpunit"
alias rdb="a migrate:refresh --seed"

# capistrano ##########
alias deploy="cap production deploy"

# grunt ###############
alias grsv="grunt server"
alias grp="grunt publish"
alias grr="grunt reset"

# repeats a command
function again() {
	while [ 1 ]; do
		eval $2 $3 $4 $5
		sleep $1
	done
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
