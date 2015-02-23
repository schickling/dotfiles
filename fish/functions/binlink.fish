function binlink --description "Creates a symlink to ~/.bin"
  mkdir -p ~/.bin
  ln -sfv (pwd)/$argv[1] ~/.bin/$argv[1]
end

