#!/bin/bash

source ../../scripts/common.sh

# NOTE: Postgresql with Vector for Immich
NAME="postgres-vector"
IMAGE_SOURCE="docker.io/tensorchord/pgvecto-rs:pg16-v0.2.1"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories & Running"
# mkdir -pv "$(get_vol_dir ${NAME})/data"
mkdir -pv "$(get_vol_dir ${NAME})"

# NOTE: Not Supporting Rootless Mode Reason: /var/run/postgresql
# Making DB Data for Rootless Container
# files=$(ls -A $(get_vol_dir ${NAME})/data)
# if [[ $? == 0 ]] && [[ -z "$files" ]]; then
#     source ./scripts/rootless-data.sh
# fi

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#--cap-add CHOWN \
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/db.env" \
 -p ${LOCALHOST_IP}:5432:5432 \
 -v "$(get_vol_dir ${NAME})/data":/var/lib/postgresql/data \
 -v "$(get_script_dir ${NAME})/multi-db-entrypoint.sh":/docker-entrypoint-initdb.d/entrypoint.sh \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
