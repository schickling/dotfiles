# other aliases #######
source "$HOME/Dropbox/Apps/ZSH/sub2home.alias"

# config ##############
alias cvim="v $DOTFILES/vim/config.vim"
alias cbundle="v $DOTFILES/vim/plugins.vim"
alias cterm="v $DOTFILES/zsh/3-alias.zsh"
alias cknown="v $HOME/.ssh/known_hosts"
alias chost="sudo v /etc/hosts"
alias cdot="cd $DOTFILES"
alias csub="cd ~/Library/Application\ Support/Sublime\ Text\ 3"

# misc ################
alias sshkey="cat ~/.ssh/id_rsa.pub | pbcopy && echo 'Copied to clipboard.'"
alias rnginx="sudo nginx -s stop && sudo nginx"
alias rr="source $HOME/.zshrc && clear"
alias rbundle="rm Gemfile.lock && bundle"
alias rrm="rm -rf"
alias rmc="cd .. && rm -rf '${OLDPWD}'"
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"
alias ard="vlc http://daserste_live-lh.akamaihd.net/i/daserste_de@91204/master.m3u8"
alias l="ls -lh"
alias ym="youtube-dl -x"
alias ws="python -m SimpleHTTPServer"
alias lip="ifconfig en0 | grep 'inet ' | cut -d' ' -f2"
alias t="touch"
alias lo="pmset displaysleepnow"

# cordova #############
alias cor="cordova"
alias cb="cordova build"

# docker ##############
alias d="docker"
alias dcc="docker ps -q | xargs docker kill && docker ps -a -q | xargs docker rm"
alias dci="dcc && docker images -q | xargs docker rmi"
alias dir="docker run -i -t"
alias b2d="boot2docker-cli"

# vim #################
alias v="vim"
alias m="mvim"
alias uvim="vim +BundleUpdate +qall"

# folders #############
alias dr="cd $HOME/Dropbox"
alias de="cd $HOME/Desktop"
alias p="cd $HOME/Desktop/projects"

# git #################
alias gs="git status -s"
alias gl="git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short"
alias gps="git push"
alias gpl="git pull"
alias gcm="git commit"
alias ga="git add"
alias gfix="git rm -r --cached . && git add ."
alias gco="git checkout"
alias gcl="git clone"
alias gr="git clean -fd && git checkout ."
alias gt="git tag"

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

