#!/bin/bash

source ../../scripts/common.sh

NAME="elasticsearch"
IMAGE_SOURCE="docker.io/library/elasticsearch:8.10.4"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#--detach \
#-v "$(get_vol_dir ${NAME})/data":/var/lib/$NAME \
podman run \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -m 2048m \
 -e "xpack.security.enabled=false" \
 -e "discovery.type=single-node" \
 -p 9200:9200 \
 -p 9300:9300 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

#action_based_on_query "generate-con-quadlet" "$NAME"
#action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
