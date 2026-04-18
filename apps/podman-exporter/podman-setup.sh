#!/bin/bash

source ../../scripts/common.sh

NAME="podman-exporter"
IMAGE_SOURCE="quay.io/navidys/prometheus-$NAME:v1.10.1" # For Podman 4
PORT="9882"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
systemctl start --user podman.socket

#-p ${LOCALHOST_IP}:${PORT}:5555 \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -e CONTAINER_HOST=unix:///run/podman/podman.sock \
 -v $XDG_RUNTIME_DIR/podman/podman.sock:/run/podman/podman.sock \
 -p $PORT:9882 \
 --userns=keep-id:uid=65534 \
 --security-opt label=disable \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
