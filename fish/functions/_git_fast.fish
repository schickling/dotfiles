function _git_fast
  git pull
  git add -A
  git commit -m $argv
  git push origin HEAD
end
