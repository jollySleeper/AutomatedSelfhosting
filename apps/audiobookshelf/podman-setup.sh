#!/bin/bash

source ../../scripts/common.sh

NAME="audiobookshelf"
IMAGE_SOURCE="ghcr.io/advplyr/audiobookshelf:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$(get_vol_dir ${NAME})/metadata"

# Making Files Data for Rootless Container
files=$(ls -A $(get_vol_dir ${NAME})/config)
if [[ $? == 0 ]] && [[ -z "$files" ]]; then
    source ./scripts/${NAME}-rootless-data.sh
fi

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/rootless.env" \
 -p ${LOCALHOST_IP}:8042:8080 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$(get_vol_dir ${NAME})/metadata":/metadata \
 -v "$HOME/media/Books":/audiobooks \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8042" "http"

echo "Done :)"
