#!/bin/bash

source ../../scripts/common.sh

NAME="filebrowser"
IMAGE_SOURCE="docker.io/filebrowser/filebrowser:latest"
PORT="8032"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/database"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Giving Permissions to the Directories"
# chmod -R 777 "$(get_vol_dir ${NAME})/database"
chmod -R 777 "$(get_vol_dir ${NAME})/config"

# Function to run the container (callable for debugging)
run_container() {
    echo "-> Running '$NAME' Container"
    podman run \
     --detach \
     --replace \
     --label io.containers.autoupdate=registry \
     --userns keep-id \
     --group-add $(id -g) \
     --env-file "$(get_env_dir ${NAME})/local.env" \
     -p ${LOCALHOST_IP}:$PORT:8080 \
     -v "$(get_vol_dir ${NAME})/database":/database \
     -v "$(get_vol_dir ${NAME})/config":/config \
     -v "$HOME/media":/srv \
     --name "$NAME" \
     "$IMAGE_SOURCE"
}

# Run the container
run_container

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
