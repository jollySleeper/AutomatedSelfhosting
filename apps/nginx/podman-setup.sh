#!/bin/bash

source ../../scripts/common.sh

NAME="nginx"
IMAGE_SOURCE="docker.io/library/$NAME:stable-alpine"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
#mkdir -pv "$(get_vol_dir ${NAME})/lib/$NAME"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network slirp4netns:port_handler=slirp4netns,allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
 -p 80:1080 \
 -p 443:1433 \
 -v "$(get_config_dir ${NAME})/rootless/nginx.conf":/etc/nginx/nginx.conf \
 -v "$(get_config_dir ${NAME})/rootless/nginx-confd-default.conf":/etc/nginx/conf.d/default.conf \
 -v "$(get_config_dir ${NAME})/snippets":/etc/nginx/snippets \
 --name "$NAME" \
 "$IMAGE_SOURCE"

echo "Done :)"
