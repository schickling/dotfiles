
# Set where to install casks
set -x HOMEBREW_CASK_OPTS "--appdir=/Applications"

set -x GOPATH $HOME/Desktop/go

set -x PATH $PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"


# secretive
set -x SSH_AUTH_SOCK /Users/schickling/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh


# Set docker host
# eval (docker-machine env dev)
