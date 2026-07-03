#!/bin/bash

source ../../scripts/common.sh

POD_NAME="wger"

function run_wger_container() {
    name=$1
    image_source=$2
    echo "-> Running '$name' Container"

    case "$name" in
        "wger-db")
            echo "-> Making Required Directories & Running"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/data"

            # Making DB Data for Rootless Container
            files=$(ls -A $(get_vol_dir ${POD_NAME})/${name}/data)
            if [[ $? == 0 ]] && [[ -z "$files" ]]; then
                source ./scripts/postgres-rootless-data.sh
            fi

            podman run \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
                -p ${LOCALHOST_IP}:5433:5432 \
                -v "$(get_vol_dir ${POD_NAME})/$name/data":/var/lib/postgresql/data \
                --name "$name" \
                "$image_source"
            ;;
        "wger-cache")
            echo "-> Making Required Directories & Running"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/data"

            podman run \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                -p ${LOCALHOST_IP}:6379:6379 \
                -v "$(get_vol_dir ${POD_NAME})/$name/data":/data \
                --name "$name" \
                "$image_source"
            ;;
        "wger-web")
            echo "-> Making Required Directories & Running"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/static"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/media"

            podman run \
                --detach \
                --replace \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --network 'pasta:--map-host-loopback,10.0.2.2' \
                --env-file "$(get_env_dir ${POD_NAME})/wger-web.env" \
                -p ${LOCALHOST_IP}:8051:8000 \
                -v "$(get_vol_dir ${POD_NAME})/$name/static":/home/wger/static \
                -v "$(get_vol_dir ${POD_NAME})/$name/media":/home/wger/media \
                --name "$name" \
                "$image_source"

            # action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8051" "http"
            ;;
        "wger-celery-worker")
            echo "-> Making Required Directories & Running"

            podman run \
                --detach \
                --replace \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --network 'pasta:--map-host-loopback,10.0.2.2' \
                --env-file "$(get_env_dir ${POD_NAME})/wger-web.env" \
                -v "$(get_vol_dir ${POD_NAME})/wger-web/media":/home/wger/media \
                --memory=512m \
                --name "$name" \
                "$image_source" \
                /start-worker
            ;;
        "wger-celery-beat")
            echo "-> Making Required Directories & Running"
            mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/beat"

            podman run \
                --detach \
                --replace \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --network 'pasta:--map-host-loopback,10.0.2.2' \
                --env-file "$(get_env_dir ${POD_NAME})/wger-web.env" \
                -v "$(get_vol_dir ${POD_NAME})/$name/beat":/home/wger/beat \
                --name "$name" \
                "$image_source" \
                /start-beat
            ;;
        "wger-static")
            echo "-> Making Required Directories & Running"
            # Volumes are already created by wger-web

            podman run \
                --detach \
                --replace \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                -p ${LOCALHOST_IP}:8052:80 \
                -v "$(get_vol_dir ${POD_NAME})/wger-web/static":/usr/share/nginx/html/static:ro \
                -v "$(get_vol_dir ${POD_NAME})/wger-web/media":/usr/share/nginx/html/media:ro \
                -v "$(get_config_dir ${POD_NAME})/wger-static-nginx.conf":/etc/nginx/conf.d/default.conf:ro \
                --name "$name" \
                "$image_source"
            ;;
        *)
            echo "Unknown container: $name"
            ;;
    esac
}

# Setup containers - using shared postgres-vector and redis
# Database: postgres-vector on 127.0.0.1:5432 (10.0.2.2:5432 from container)
# Cache: redis on 127.0.0.1:6379 (10.0.2.2:6379 from container)
# Static files: wger-static nginx on 127.0.0.1:8052
for name in "wger-web" "wger-celery-worker" "wger-celery-beat" "wger-static"; do
    if [[ "$name" == "wger-web" ]] || [[ "$name" == "wger-celery-worker" ]] || [[ "$name" == "wger-celery-beat" ]]; then
        image_source="docker.io/wger/server:latest"
    elif [[ "$name" == "wger-static" ]]; then
        image_source="docker.io/nginx:alpine"
    fi

    action_based_on_query "$1-con" "$name" "$image_source"

    run_wger_container "$name" "$image_source"

    action_based_on_query "generate-con-quadlet" "$name"
    action_based_on_query "install-con-quadlet" "$name" "$POD_NAME"
done

echo "Done :)"
