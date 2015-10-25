function _git_fast
  git pull
  git add -A
  git commit -m $argv[1]
  git push origin HEAD
end
