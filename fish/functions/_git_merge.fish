function _git_merge
  set -x WIP_BRANCH (git symbolic-ref --short HEAD)
  set -x TARGET_BRANCH $argv[1]
  git pull origin $WIP_BRANCH
  git checkout $TARGET_BRANCH
  git pull origin $TARGET_BRANCH
  git merge $WIP_BRANCH
  git push origin $TARGET_BRANCH
  git checkout $WIP_BRANCH
end
