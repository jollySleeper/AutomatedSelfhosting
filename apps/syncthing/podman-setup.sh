#!/bin/bash

source ../../scripts/common.sh

NAME="syncthing"
IMAGE_SOURCE="docker.io/$NAME/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
# Keep Adding Folder Path as Volumes
 #-p ${LOCALHOST_IP}:8384:8384 \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --userns keep-id \
 -p ${LOCALHOST_IP}:8031:8384 \
 -p 22000:22000/tcp \
 -p 22000:22000/udp \
 -p 21027:21027/udp \
 -v "$(get_vol_dir ${NAME})/config":/var/syncthing/config \
 -v ~/selfhost:/home/selfhost \
 -v ~/media/Docs/Logseq:/home/docs/Logseq \
 -v ~/media/Songs:/home/songs \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8031" "http"

echo "Done :)"
