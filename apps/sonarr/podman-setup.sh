#!/bin/bash

source ../../scripts/common.sh

NAME="sonarr"
IMAGE_SOURCE="ghcr.io/linuxserver/sonarr:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$HOME/media/TV"
mkdir -pv "$HOME/media/Downloads/complete/tv"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 -p ${LOCALHOST_IP}:8065:8065 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media":/media \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8065" "http"

echo "Done :)"
