#!/bin/bash

source ../../scripts/common.sh

NAME="nitter"
# IMAGE_SOURCE="docker.io/zedeus/$NAME:latest-arm64"
IMAGE_SOURCE="ghcr.io/sekai-soft/$NAME-self-contained:latest"
PORT="8018"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"
touch "$(get_vol_dir ${NAME})/data/guest_accounts.json"


echo "-> Running '$NAME' Container"
# --detach \
# --env-file "$(get_env_dir ${NAME})/nitter.env" \
# --user $(id -u):$(id -g) \
# -v "$(get_env_dir ${NAME})/nitter.env":/src/.env \
podman run \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network pasta `#Image is self-contained (bundled redis); no host loopback needed` \
 --env-file "$(get_env_dir ${NAME})/nitter2.env" \
 -v "$(get_env_dir ${NAME})/nitter.env":/src/.env \
 -v "$(get_config_dir ${NAME})/$NAME.conf":/src/${NAME}.conf \
 -v "$(get_vol_dir ${NAME})/data":/nitter-data \
 -p ${LOCALHOST_IP}:${PORT}:8080 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
