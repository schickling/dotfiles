function local-docker
  # Prepare boot2docker
  set -gx DOCKER_HOST tcp://192.168.59.103:2376
  set -gx DOCKER_CERT_PATH $HOME/.boot2docker/certs/boot2docker-vm
  set -gx DOCKER_TLS_VERIFY 1
end
