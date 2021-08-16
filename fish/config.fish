set -x DOTFILES $HOME/.config
set -x SECFILES $HOME/.secret


# Define global path
# set -x PATH /usr/local/bin /usr/bin /bin /usr/sbin /sbin $DOTFILES/bin $GOPATH/bin $HOME/.npm-global/bin $HOME/.cargo/bin $HOME/.deno/bin


# Setup terminal, and turn on colors
set -x TERM xterm-256color

# Enable color in grep
set -x GREP_OPTIONS '--color=auto'
set -x GREP_COLOR '3;33'

# Disable fish greeting
# set -x fish_greeting ""

# needed for gpg-agent
# set -x GPG_TTY (tty)

set -x LANG en_US.UTF-8
set -x LC_CTYPE "en_US.UTF-8"
set -x LC_MESSAGES "en_US.UTF-8"
set -x LC_COLLATE C

set -x EDITOR vim

# Enable direnv
eval (direnv hook fish)

# Add fenv to path
# set fish_function_path $fish_function_path ~/.config/fish/plugin-foreign-env/functions

# Source Nix setup script
# fenv source ~/.nix-profile/etc/profile.d/nix.sh

# Start or re-use a gpg-agent.
#gpgconf --launch gpg-agent

# Ensure that GPG Agent is used as the SSH agent
# set -e SSH_AUTH_SOCK
# set -U -x SSH_AUTH_SOCK ~/.gnupg/S.gpg-agent.ssh

# aws autocompletion
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

# Enable autojump
#[ -f /usr/local/share/autojump/autojump.fish ]; and . /usr/local/share/autojump/autojump.fish

# Import aliases
[ -f $DOTFILES/fish/aliases.fish ]; and . $DOTFILES/fish/aliases.fish

# Import secret config
[ -f $SECFILES/fish/config.fish ]; and . $SECFILES/fish/config.fish

[ (uname) = Darwin ]; and . $DOTFILES/fish/config/mac.fish
