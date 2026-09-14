#!/bin/bash

source ../../scripts/common.sh

POD_NAME="piped"

# Generate Quadlet container files with proper dependencies and cleanup
# These are the source of truth - don't rely on auto-generation
function write_container_quadlet() {
    local name=$1
    local quadlet_dir="$HOME/.config/containers/systemd"
    local container_file="$quadlet_dir/$name.container"

    echo "-> Writing Quadlet file: $container_file"

    case "$name" in
        "piped-api")
            cat > "$container_file" << 'EOF'
[Unit]
Description=piped-api
# Start after postgres-vector database and bg-helper are available
After=postgres-vector.service piped-bg-helper.service
Wants=postgres-vector.service piped-bg-helper.service

[Container]
AutoUpdate=registry
ContainerName=piped-api
Group=1001
Image=ghcr.io/jollysleeper/piped-backend:feature-feed-freshness-fix-2
Network=pasta:--map-host-loopback,10.0.2.2
PublishPort=127.0.0.1:8022:8081
User=1001
Volume=%h/selfhost/apps/piped/configs/piped-api.properties:/app/config.properties:ro

[Service]
Restart=always
# Clean up any stale container resources before starting
ExecStartPre=-/usr/bin/podman container cleanup piped-api

[Install]
WantedBy=default.target
EOF
            ;;
        "piped-proxy")
            cat > "$container_file" << 'EOF'
[Unit]
Description=piped-proxy
# Start after the API is up to ensure proper initialization order
After=piped-api.service
Wants=piped-api.service

[Container]
AutoUpdate=registry
ContainerName=piped-proxy
EnvironmentFile=%h/selfhost/apps/piped/environments/piped-proxy.env
Group=1001
Image=docker.io/1337kavin/piped-proxy:latest
PublishPort=127.0.0.1:8023:8082
User=1001

[Service]
Restart=always
# Clean up any stale container resources before starting
ExecStartPre=-/usr/bin/podman container cleanup piped-proxy

[Install]
WantedBy=default.target
EOF
            ;;
        "piped-frontend")
            cat > "$container_file" << 'EOF'
[Unit]
Description=piped-frontend
# Start after both API and Proxy are up
After=piped-api.service piped-proxy.service
Wants=piped-api.service piped-proxy.service

[Container]
AutoUpdate=registry
ContainerName=piped-frontend
Group=1001
Image=docker.io/1337kavin/piped-frontend:latest
PublishPort=127.0.0.1:8021:8080
User=1001
Volume=%h/selfhost/apps/piped/configs/piped-frontend-rootless-tmp-nginx.conf:/etc/nginx/nginx.conf
Volume=%h/selfhost/apps/piped/volumes/piped-frontend/nginx-off:/etc/nginx/off
Volume=%h/selfhost/apps/piped/scripts/frontend-entrypoint-replace.sh:/entrypoint.sh

[Service]
Restart=always
# Clean up any stale container resources before starting
ExecStartPre=-/usr/bin/podman container cleanup piped-frontend

[Install]
WantedBy=default.target
EOF
            ;;
        "piped-db")
            cat > "$container_file" << EOF
[Unit]
Description=piped-db

[Container]
AutoUpdate=registry
ContainerName=piped-db
EnvironmentFile=%h/selfhost/apps/piped/environments/piped-db.env
Group=$(id -g)
Image=docker.io/postgres:15-alpine
PublishPort=127.0.0.1:5432:5432
User=$(id -u)
Volume=%h/selfhost/apps/piped/volumes/piped-db/data:/var/lib/postgresql/data

[Service]
Restart=always
ExecStartPre=-/usr/bin/podman container cleanup piped-db

[Install]
WantedBy=default.target
EOF
            ;;
        "piped-bg-helper")
            cat > "$container_file" << 'EOF'
[Unit]
Description=piped-bg-helper
# BG Helper Server for PoToken generation
# Should start before piped-api for proper initialization

[Container]
AutoUpdate=registry
ContainerName=piped-bg-helper
Group=1001
Image=docker.io/1337kavin/bg-helper-server:latest
PublishPort=127.0.0.1:8024:3000
User=1001

[Service]
Restart=always
# Clean up any stale container resources before starting
ExecStartPre=-/usr/bin/podman container cleanup piped-bg-helper

[Install]
WantedBy=default.target
EOF
            ;;
        *)
            echo "Unknown container: $name"
            return 1
            ;;
    esac

    echo "-> Reloading systemd daemon"
    systemctl --user daemon-reload
}

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
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
                -p ${LOCALHOST_IP}:5432:5432    `# postgres` \
                -v "$(get_vol_dir ${POD_NAME})/$name/data":/var/lib/postgresql/data \
                --name "$name" \
                "$image_source"
            ;;
        "piped-api")
            podman run \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --network 'pasta:--map-host-loopback,10.0.2.2' `#Pasta w/ host loopback at 10.0.2.2. See docs/DNS_ARCHITECTURE.md` \
                -p ${LOCALHOST_IP}:8022:8081   `# API` \
                -v "$(get_config_dir ${POD_NAME})/$name.properties":/app/config.properties:ro \
                --name "$name" \
                "$image_source"
            # action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8022" "http"
            ;;
        "piped-frontend")
            if [[ $3 == "indirect" ]]; then
                # NOTE: Run this Everytime this Container is Updated
                # Getting files for Rootless containers
                # Not Required Now as handled in entrypoint script
                source ./scripts/frontend-rootless-assets.sh

                podman run \
                    --detach \
                    --restart unless-stopped \
                    --label io.containers.autoupdate=registry \
                    --user $(id -u):$(id -g) \
                    -p ${LOCALHOST_IP}:8021:8080   `# FrontEnd` \
                    -v "$(get_config_dir ${POD_NAME})/$name-rootless-nginx.conf":/etc/nginx/nginx.conf \
                    -v "$(get_vol_dir ${POD_NAME})/$name/nginx-off":/etc/nginx/off \
                    -v "$(get_vol_dir ${POD_NAME})/$name/assets":/usr/share/nginx/html/assets \
                    -v "$(get_script_dir ${POD_NAME})/frontend-entrypoint.sh":/entrypoint.sh \
                    --name "$name" \
                    "$image_source"
            else
                podman run \
                    --detach \
                    --restart unless-stopped \
                    --label io.containers.autoupdate=registry \
                    --user $(id -u):$(id -g) \
                    -p ${LOCALHOST_IP}:8021:8080   `# FrontEnd` \
                    -v "$(get_config_dir ${POD_NAME})/$name-rootless-tmp-nginx.conf":/etc/nginx/nginx.conf \
                    -v "$(get_vol_dir ${POD_NAME})/$name/nginx-off":/etc/nginx/off \
                    -v "$(get_script_dir ${POD_NAME})/frontend-entrypoint-replace.sh":/entrypoint.sh \
                    --name "$name" \
                    "$image_source"
            fi
            # action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8021" "http"
            ;;
        "piped-proxy")
            podman run \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
                -p ${LOCALHOST_IP}:8023:8082   `# Proxy` \
                --name "$name" \
                "$image_source"
            action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8023" "http"
            ;;
        "piped-bg-helper")
            # BG Helper Server for PoToken generation
            # Used by piped-api via BG_HELPER_URL config
            podman run \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                -p ${LOCALHOST_IP}:8024:3000   `# BG Helper` \
                --name "$name" \
                "$image_source"
            ;;
        *)
            echo default
            ;;
    esac
}

# Container deployment options:
# - "piped-api" "piped-proxy" "piped-frontend" "piped-bg-helper" for full stack
# - "piped-db" only if using dedicated database (not postgres-vector)
# NOTE: piped-db is disabled as we use centralized postgres-vector

# Uncomment the containers you want to deploy:
# CONTAINERS=("piped-db" "piped-api" "piped-proxy" "piped-frontend" "piped-bg-helper")
# CONTAINERS=("piped-api" "piped-proxy" "piped-frontend" "piped-bg-helper")
CONTAINERS=("piped-api")

for name in "${CONTAINERS[@]}"; do
    if [[ "$name" == "piped-db" ]]; then
        # NOTE: Now Using Centralized PostgreSQL Container
        image_source="docker.io/postgres:15-alpine"
    elif [[ "$name" == "piped-api" ]]; then
        image_source="ghcr.io/jollysleeper/piped-backend:feature-feed-freshness-fix-2"
    elif [[ "$name" == "piped-bg-helper" ]]; then
        # BG Helper Server for PoToken generation
        image_source="docker.io/1337kavin/bg-helper-server:latest"
    else
        image_source="docker.io/1337kavin/$name:latest"
    fi

    # Stop and remove existing container, pull new image
    action_based_on_query "$1-con" "$name" "$image_source"

    # Run the container (creates it initially)
    run_pod_container "$name" "$image_source" "direct"

    # Write the quadlet file with proper dependencies and cleanup
    # This replaces the auto-generated quadlet with our customized version
    # write_container_quadlet "$name"
done

echo "Done :)"
