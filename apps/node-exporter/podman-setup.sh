#!/bin/bash

source ../../scripts/common.sh

NAME="node-exporter"
IMAGE_SOURCE="quay.io/prometheus/$NAME:latest"
PORT="9090"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#-p ${LOCALHOST_IP}:${PORT}:5555 \
#-p $PORT:9090 \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network host \
 --pid="host" \
 -v "/:/host:ro,rslave" \
 --name "$NAME" \
 "$IMAGE_SOURCE" \
 --path.rootfs=/host

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
