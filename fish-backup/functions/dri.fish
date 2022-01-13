function dri
  for arg in $argv
    docker ps -a | grep $arg | cut -f 1 -d " " | xargs docker kill | xargs docker rm
    docker rmi -f $arg
  end
end
