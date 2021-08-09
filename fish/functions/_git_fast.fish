function _git_fast --argument-names 'message'
  if begin not type -q commitizen; and test -z $message; end
    echo "No commit message provided or `commitizen` not installed"
    exit 1
  end

  set -x WIP_BRANCH (git symbolic-ref --short HEAD)
  git pull origin $WIP_BRANCH
  git add -A
  if test -z $message
    git cz
  else
    git commit -m $message
  end
  and git push origin $WIP_BRANCH
end
