#!/bin/bash
## TODO

base_dir="/opt/rabbitmq"


docker pull docker.io/rabbitmq:3.8-management

docker run -d --name bitwardenrs \
  --restart unless-stopped \
  -e WEBSOCKET_ENABLED=true \
  -v ./data:/data/ \
  -p 6666:80 \
  -p 3012:3012 \
  vaultwarden/server:latest