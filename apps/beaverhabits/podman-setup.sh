#!/bin/bash

source ../../scripts/common.sh

NAME="beaverhabits"
IMAGE_SOURCE="docker.io/daya0576/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -v "$(get_vol_dir ${NAME})/data":/app/.user \
 -p ${LOCALHOST_IP}:8053:8080 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# Generate NGINX Conf File
# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8053" "http"

echo "Done :)"
