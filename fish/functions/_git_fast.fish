function _git_fast
  set -x WIP_BRANCH (git symbolic-ref --short HEAD)
  git pull origin $WIP_BRANCH
  git add -A
  git commit -m $argv[1]
  git push origin $WIP_BRANCH
end
