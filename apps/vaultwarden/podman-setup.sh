#!/bin/bash
set -euo pipefail

source ../../scripts/common.sh

NAME="vaultwarden"
IMAGE_SOURCE="docker.io/vaultwarden/server:1.37.3"
PORT="8035"
# Must match ROCKET_PORT in local.env. Vaultwarden runs as the unprivileged
# keep-id user, which cannot bind the image's default port 80.
CONTAINER_PORT="8080"

ENV_FILE="$(get_env_dir ${NAME})/local.env"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $1: $2"
}

stop_existing_quadlet_service() {
    if systemctl --user cat "${NAME}.service" >/dev/null 2>&1; then
        log INFO "Stopping existing ${NAME}.service before container replacement"
        systemctl --user stop "${NAME}.service"
    fi
}

if [[ ! -f "$ENV_FILE" ]]; then
    log ERROR "Missing $ENV_FILE"
    echo "Copy environments/sample.env to environments/local.env and set DOMAIN and ROCKET_PORT."
    exit 1
fi

if ! grep -qx "ROCKET_PORT=${CONTAINER_PORT}" "$ENV_FILE"; then
    log ERROR "$ENV_FILE must contain ROCKET_PORT=${CONTAINER_PORT}"
    exit 1
fi

if [[ -z "${1:-}" ]]; then
    stop_existing_quadlet_service
fi
action_based_on_query "${1:-}-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

log INFO "Running '$NAME' container"
podman run \
    --detach \
    --restart unless-stopped \
    --label io.containers.autoupdate=registry \
    --userns keep-id \
    --group-add "$(id -g)" \
    --env-file "$ENV_FILE" \
    --read-only \
    --cap-drop all \
    --security-opt no-new-privileges \
    --memory 512m \
    --cpus 2 \
    --health-cmd /healthcheck.sh \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    --health-start-period 30s \
    -p ${LOCALHOST_IP}:${PORT}:${CONTAINER_PORT} \
    -v "$(get_vol_dir ${NAME})/data":/data \
    --name "$NAME" \
    "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME" "$IMAGE_SOURCE"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# NGINX configuration (HTTPS-only, alias redirects, WebSocket passthrough) is maintained in:
# apps/nginx/configs/sites/vaultwarden.conf

log INFO "Vaultwarden deployment complete"
