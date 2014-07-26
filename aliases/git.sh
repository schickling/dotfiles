# helper function
function _git_fast() {
  git pull
  git add -A .
  git commit -m "$1"
  git push
}

alias g="git"
alias gs="git status -s"
alias gd="git diff"
alias gl="git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short"
alias gps="git push"
alias gp="git pull"
alias gcm="git commit"
alias ga="git add"
alias gfix="git rm -r --cached . && git add ."
alias gco="git checkout"
alias gcl="git clone"
alias gr="git clean -fd && git checkout ."
alias gt="git tag"
alias gf="_git_fast"
