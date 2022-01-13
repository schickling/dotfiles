function fixgpg
  ssh $argv 'killall gpg-agent'
  rm ~/.ssh/sockets/*
  killall gpg-agent
  echo 'test' | gpg --clearsign
  ssh $argv 'ls /run/user/1000/gnupg/'
  ssh $argv 'echo 'test' | gpg --clearsign'
end
