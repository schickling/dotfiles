function _npm_release
  git pull
  yarn
  npm version $argv[1]
  npm publish
  git push --tags
  git push
end
