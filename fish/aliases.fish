# reset abbreviations
set -U fish_user_abbreviations

# config ##############
alias cv "v $DOTFILES/vim/config.vim"
alias cf "v $DOTFILES/fish/aliases.fish"
alias cm "v $DOTFILES/tmux/.tmux.conf"
alias ck "v $HOME/.ssh/known_hosts"
alias cs "v $HOME/.ssh/config"
alias ch "sudo v /etc/hosts"
alias dot "cd $DOTFILES"
alias sec "cd $SECFILES"


# listing #############
alias l "ls -lh"

short rrm "rm -rf"

short t "tmux"
short tl "tmux ls"
short ta "tmux attach -t"
short ts "tmux new -s"
short tk "tmux kill-session -t"

alias v "nvim"

alias z "j"

short s "ssh"

short ka "killall"
short k9 "kill -9"

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias ...... "cd ../../../../.."
alias ....... "cd ../../../../../.."


# git ################
short g "git"
short gs "git status -s"
short gd "git diff"
short gps "git push"
short gp "git pull"
short gcm "git commit"
short ga "git add"
short gco "git checkout"
short gcl "git clone"
short gt "git tag"
alias gfix "git rm -r --cached .; and git add ."
alias gl "git log --pretty=format:'%C(yellow)%h %Cred%ar %Cblue%an%Cgreen%d %Creset%s' --date=short"
short gx "git clean -fd; and git checkout ."
alias gf "_git_fast"
alias gr "_git_release"
alias gm "_git_merge"

# misc ################
alias sshkey "cat ~/.ssh/id_rsa.pub | pbcopy; and echo 'Copied to clipboard.'"
alias rr "source $HOME/.zshrc; and clear"
alias vlc "/Applications/VLC.app/Contents/MacOS/VLC"
alias ard "vlc http://daserste_live-lh.akamaihd.net/i/daserste_de@91204/master.m3u8"
alias ws "python -m http.server"
alias lip "ifconfig en0 | grep 'inet ' | cut -d' ' -f2"
alias lo "pmset displaysleepnow"
alias todo "v ~/Dropbox/Documents/TODO.md"
alias :q "exit"
alias pw "pwgen -Bsn 20 1 | pbcopy; echo 'Password copied to clipboard'"

#alias pip "pip3"
#alias python "python3"
short p "python"
short p2 "python2"
short p3 "python3"

# docker ##############
short d "docker"
short di "docker images"
short dc "docker-compose"
short dm "docker-machine"
short b2d "boot2docker"
short dir "docker run -i -t --rm"
short dirv "docker run -i -t --rm -v (pwd):/source -w /source"
short de "docker exec -it"
alias dcc "docker ps -q | xargs docker kill ; docker ps -aq | xargs docker rm"
alias dci "dcc; and docker images -q | xargs docker rmi"

# haskell #############
alias ghci "ghci -v0"
alias h "ghci"

short findport "sudo lsof -iTCP -sTCP:LISTEN -n -P | grep"


#again() {
	#while [ 1 ]; do
		#eval $2 $3 $4 $5
		#sleep $1
	#done
#}

#de() {
  #docker exec -it $1 bash
#}

#dknown() {
  #vim ~/.ssh/known_hosts +$1 +d +wq
#}

#join() { local IFS "$1"; shift; echo "$*"; }

#tunnel() {
  #n=$#@[@]
  #host=$@[$n]
  #ports=("${@[@]:1:$n-1}")
  #mapped_ports=()
  #for port in ${ports[@]}
  #do
    #mapped_ports+=("-L $port":localhost:"$port")
    #mapped_ports+=("-L $(lip)":"$port":localhost:"$port")
  #done
  #ports_str=$(join " " ${mapped_ports[@]})
  #ssh $(echo "-nNT $ports_str $host")
#}

#o() {
  #if [ $# -eq 0 ]; then
    #open .;
  #else
    #open "$@";
  #fi;
#}

#dri() {
  #docker ps -a | grep $1 | cut -f 1 -d " " | xargs docker kill | xargs docker rm && docker rmi $1
#}

#rmc() {
  #old_dir=$(pwd)
  #ask "Do you really want to delete the current directory?" "Y" && cd .. && rm -rf $old_dir
#}

#ask() {
  ## http://djm.me/ask
  #while true; do

    #if [ "${2:-}" = "Y" ]; then
      #opts "Y/n"
      #default=Y
    #elif [ "${2:-}" = "N" ]; then
      #opts "y/N"
      #default=N
    #else
      #opts "y/n"
      #default=
    #fi

    ## Ask the question
    #read "REPLY?$1 [$opts]"

    ## Default?
    #if [ -z "$REPLY" ]; then
      #REPLY=$default
    #fi

    ## Check if the reply is valid
    #case "$REPLY" in
      #Y*|y*) return 0 ;;
      #N*|n*) return 1 ;;
    #esac

  #done
#}

