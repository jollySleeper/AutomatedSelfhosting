#!/bin/bash

source ../../scripts/common.sh

NAME="readarr"
# Temporary fork: upstream Bookshelf (pennydreadful) fails qBittorrent 5.2+ auth
# (HTTP 204 empty body). See README "Upstream image" for when to switch back.
IMAGE_SOURCE="ghcr.io/alvaroestradadev/bookshelf:hardcover"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$HOME/media/Downloads/complete/books"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 -p ${LOCALHOST_IP}:8067:8067 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media":/media \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8067" "http"

echo "Done :)"
