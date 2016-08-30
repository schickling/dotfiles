set -x DOTFILES $HOME/.config
set -x SECFILES $HOME/.secret

set -x GOPATH $HOME/.go

# Define global path
set -x PATH /usr/local/bin /usr/bin /bin /usr/sbin /sbin $DOTFILES/bin $HOME/.bin $HOME/.go/bin

# Set where to install casks
set -x HOMEBREW_CASK_OPTS "--appdir=/Applications"

# Setup terminal, and turn on colors
set -x TERM xterm-256color

# Enable color in grep
set -x GREP_OPTIONS '--color=auto'
set -x GREP_COLOR '3;33'

# Disable fish greeting
set -x fish_greeting ""

set -x LANG en_US.UTF-8
set -x LC_CTYPE "en_US.UTF-8"
set -x LC_MESSAGES "en_US.UTF-8"
set -x LC_COLLATE C

set -x EDITOR "vim"

# Enable direnv
eval (direnv hook fish)

# Start or re-use a gpg-agent.
gpgconf --launch gpg-agent

# Ensure that GPG Agent is used as the SSH agent
set -e SSH_AUTH_SOCK
set -U -x SSH_AUTH_SOCK ~/.gnupg/S.gpg-agent.ssh

# Enable autojump
[ -f /usr/local/share/autojump/autojump.fish ]; and . /usr/local/share/autojump/autojump.fish

# Import aliases
[ -f $DOTFILES/fish/aliases.fish ]; and . $DOTFILES/fish/aliases.fish

# Import secret config
[ -f $SECFILES/fish/config.fish ]; and . $SECFILES/fish/config.fish

# Set docker host
# eval (docker-machine env dev)
