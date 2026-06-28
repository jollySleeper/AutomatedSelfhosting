#!/bin/bash

source ../../scripts/common.sh

NAME="lidarr"
IMAGE_SOURCE="ghcr.io/linuxserver/lidarr:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$HOME/media/Downloads/complete/music"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 -p ${LOCALHOST_IP}:8066:8066 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media":/media \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8066" "http"

echo "Done :)"
