#!/bin/bash

source ../../scripts/common.sh

NAME="paisa"
IMAGE_SOURCE="docker.io/ananthakumaran/paisa:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --userns keep-id \
 --group-add $(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8057:7500 \
 -v "$(get_vol_dir ${NAME})/data":/root/Documents/paisa \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8057" "http"

echo ""
echo "Paisa is running at http://127.0.0.1:8057"
echo "First visit: set up your journal files and paisa.yaml"
echo ""
echo "Done :)"
