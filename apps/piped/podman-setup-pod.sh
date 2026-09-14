#!/bin/bash

source ../../scripts/common.sh

POD_NAME="piped"

# action_based_on_query "$1-pod" "$POD_NAME" "$IMAGE_SOURCE"
#
# echo "Creating '$POD_NAME' Pod"
# #-p ${LOCALHOST_IP}:8090:80   `# FE Root` \
# podman pod create \
#  -p ${LOCALHOST_IP}:8021:8080   `# FrontEnd` \
#  -p ${LOCALHOST_IP}:8022:8081   `# API` \
#  -p ${LOCALHOST_IP}:8023:8082   `# Proxy` \
#  --name "$POD_NAME"

function run_pod_container() {
    name=$1
    image_source=$2
    echo "-> Running '$name' Container"

    case "$name" in
        "piped-db")
            echo "-> Making Required Directories & Running"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/data"

            # Making DB Data for Rootless Container
            files=$(ls -A $(get_vol_dir ${POD_NAME})/${name}/data)
            if [[ $? == 0 ]] && [[ -z "$files" ]]; then
                source ./scripts/postgres-rootless-data.sh
            fi

            podman run \
                --pod "$POD_NAME" \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
                -v "$(get_vol_dir ${POD_NAME})/$name/data":/var/lib/postgresql/data \
                --name "$name" \
                "$image_source"
            ;;
        "piped-api")
            podman run \
                --pod "$POD_NAME" \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                -v "$(get_config_dir ${POD_NAME})/$name.properties":/app/config.properties:ro \
                --name "$name" \
                "$image_source"
            action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8022" "http"
            ;;
        "piped-frontend")
            # Getting files for Rootless Container
            source ./scripts/frontend-rootless-assets.sh

            podman run \
                --pod "$POD_NAME" \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                -v "$(get_config_dir ${POD_NAME})/$name-rootless-nginx.conf":/etc/nginx/nginx.conf \
                -v "$(get_vol_dir ${POD_NAME})/$name/nginx-off":/etc/nginx/off \
                -v "$(get_vol_dir ${POD_NAME})/$name/assets":/usr/share/nginx/html/assets \
                -v "$(get_script_dir ${POD_NAME})/frontend-entrypoint.sh":/entrypoint.sh \
                --name "$name" \
                "$image_source"
            action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8021" "http"
            ;;
        "piped-proxy")
            podman run \
                --pod "$POD_NAME" \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
                --name "$name" \
                "$image_source"
            action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8023" "http"
            ;;
        *)
            echo default
            ;;
    esac
}

#for name in "piped-db" "piped-api" "piped-frontend" "piped-proxy"; do
for name in "piped-api"; do
    if [[ "$name" == "piped-db" ]]; then
        image_source="docker.io/postgres:15-alpine"
    elif [[ "$name" == "piped-api" ]]; then
        image_source="docker.io/1337kavin/piped:latest"
    else
        image_source="docker.io/1337kavin/$name:latest"
    fi

    action_based_on_query "$1-con" "$name" "$image_source"

    run_pod_container "$name" "$image_source"

    action_based_on_query "generate-con-quadlet" "$name"
    action_based_on_query "install-con-quadlet" "$name" "$POD_NAME"
done

echo "Done :)"
