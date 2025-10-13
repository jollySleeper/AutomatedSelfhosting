#!/bin/bash

source ../../scripts/common.sh

NAME="kibana"
IMAGE_SOURCE="docker.io/library/kibana:8.10.4"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"
# echo "-> Making Required Directories"
# mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#--detach \
#-v "$(get_vol_dir ${NAME})/data":/var/lib/$NAME \
podman run \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -p 5601:5601 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
