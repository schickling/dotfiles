set -x DOTFILES $HOME/.config
set -x SECFILES $HOME/.secret

set -x GOPATH $HOME/.go

# Define global path
set -x PATH /usr/local/bin /usr/bin /bin /usr/sbin /sbin $DOTFILES/bin $GOPATH/bin

# Set where to install casks
set -x HOMEBREW_CASK_OPTS "--appdir=/Applications"

# Prepare boot2docker
set -x DOCKER_HOST tcp://192.168.59.103:2376
set -x DOCKER_CERT_PATH $HOME/.boot2docker/certs/boot2docker-vm
set -x DOCKER_TLS_VERIFY 1

# Setup terminal, and turn on colors
set -x TERM xterm-256color
set -xU LS_COLORS "di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34:su=0:sg=0:tw=0:ow=0:"

# Enable color in grep
set -x GREP_OPTIONS '--color=auto'
set -x GREP_COLOR '3;33'

# Disable fish greeting
set -x fish_greeting ""

set -x LANG en_US.UTF-8
set -x LC_CTYPE "en_US.UTF-8"
set -x LC_MESSAGES "en_US.UTF-8"
set -x LC_COLLATE C

# Enable direnv
eval (direnv hook fish)

# Enable autojump
[ -f /usr/local/share/autojump/autojump.fish ]; and . /usr/local/share/autojump/autojump.fish

# Import aliases
[ -f $DOTFILES/fish/aliases.fish ]; and . $DOTFILES/fish/aliases.fish
