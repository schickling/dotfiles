set -x DOTFILES $HOME/.config

# Setup terminal, and turn on colors
set -x TERM xterm-256color

# Enable color in grep
set -x GREP_OPTIONS '--color=auto'
set -x GREP_COLOR '3;33'

# language settings
set -x LANG en_US.UTF-8
set -x LC_CTYPE "en_US.UTF-8"
set -x LC_MESSAGES "en_US.UTF-8"
set -x LC_COLLATE C

set -x EDITOR vim

# Enable direnv
eval (direnv hook fish)

# Start or re-use a gpg-agent.
#gpgconf --launch gpg-agent

# aws autocompletion
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

# Enable autojump
#[ -f /usr/local/share/autojump/autojump.fish ]; and . /usr/local/share/autojump/autojump.fish

# Import aliases
[ -f $DOTFILES/fish/aliases.fish ]; and . $DOTFILES/fish/aliases.fish

[ (uname) = Darwin ]; and . $DOTFILES/fish/config/macos.fish
[ (hostname) = dev2 ]; and . $DOTFILES/fish/config/nixos/nixos.fish
