function _git_release
  git pull
  git add -A
  git commit --allow-empty -m "Release Version $argv[1]"
  git tag -a -m "Version $argv[1]" $argv[1]
  git push --follow-tags origin HEAD
end
