
# Set where to install casks
set -x HOMEBREW_CASK_OPTS "--appdir=/Applications"

set -x GOPATH $HOME/Code/go

set -x PATH /usr/local/bin /usr/bin /bin /usr/sbin /sbin $DOTFILES/bin $GOPATH/bin $HOME/.cargo/bin $HOME/.deno/bin $HOME/.npm-global-packages/bin

set -x PATH $PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# needed for gpg-agent
set -x GPG_TTY (tty)

# secretive
set -x SSH_AUTH_SOCK /Users/schickling/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh


# Source Nix setup script
fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Nix
# if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
#   . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
# fi
# End Nix


# Set docker host
# eval (docker-machine env dev)
