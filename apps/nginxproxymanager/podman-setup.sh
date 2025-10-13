#!/bin/bash

source ../../scripts/common.sh

NAME="nginxproxymanager"
IMAGE_SOURCE="docker.io/jc21/nginx-proxy-manager:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"
mkdir -pv "$(get_vol_dir ${NAME})/letsencrypt"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#--userns keep-id   `# Reqd for Reading Config` \
#--hostname "$NAME" \
#--network slirp4netns:allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network pasta:--map-gw \
 -p 80:80     `# HTTP Traffic` \
 -p ${LOCALHOST_IP}:8000:81     `# Dashboard` \
 -p 443:443    `# HTTPS Traffic` \
 -v "$(get_vol_dir ${NAME})/data":/data \
 -v "$(get_vol_dir ${NAME})/letsencrypt":/etc/letsencrypt \
 --name "$NAME" \
 "$IMAGE_SOURCE"

echo "Done :)"
