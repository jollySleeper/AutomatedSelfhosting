#!/bin/bash

source ../../scripts/common.sh

NAME="mkvtoolnix"
IMAGE_SOURCE="docker.io/jlesage/$NAME:latest"
PORT="5800"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
#-p ${LOCALHOST_IP}:${PORT}:5555 \
#-p 5900:5900 `# VNC Protocol Port`\
#--user $(id -u):$(id -g) \ # NOTE: Cannot Run without Root, Ask on Github
podman run \
 --detach \
 --replace \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p $PORT:5800 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media":/storage \
 -v "/mnt/ssd/home/Media":/storage-ssd \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
