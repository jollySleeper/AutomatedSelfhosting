#!/bin/bash

source ../../scripts/common.sh

NAME="calibre-web-automated"
IMAGE_SOURCE="docker.io/crocodilestick/calibre-web-automated:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Creating required directories"
mkdir -p "$(get_vol_dir ${NAME})"
mkdir -p "$(get_vol_dir ${NAME})/book-ingest"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --replace \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env PUID=$(id -u) \
 --env PGID=$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8083:8083 \
 -v "$(get_vol_dir ${NAME})":/config \
 -v "$(get_vol_dir ${NAME})/book-ingest":/cwa-book-ingest \
 -v ~/media/Books:/calibre-library \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8083" "http"

echo "Done :)"
