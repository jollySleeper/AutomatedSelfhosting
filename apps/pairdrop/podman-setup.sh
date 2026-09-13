#!/bin/bash
set -euo pipefail

source ../../scripts/common.sh

NAME="pairdrop"
IMAGE_SOURCE="lscr.io/linuxserver/pairdrop:1.11.2"
PORT="8034"

RTC_CONFIG_FILE="$(get_vol_dir ${NAME})/config/rtc_config.json"

stop_existing_quadlet_service() {
    if systemctl --user cat "${NAME}.service" >/dev/null 2>&1; then
        echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] INFO: Stopping existing ${NAME}.service before container replacement"
        systemctl --user stop "${NAME}.service"
    fi
}

if [[ ! -f "$RTC_CONFIG_FILE" ]]; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Missing $RTC_CONFIG_FILE"
    echo "Run ../coturn/scripts/generate-local-config.sh before deploying PairDrop."
    exit 1
fi

if [[ -z "${1:-}" ]]; then
    stop_existing_quadlet_service
fi
action_based_on_query "${1:-}-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
podman run \
    --detach \
    --restart unless-stopped \
    --label io.containers.autoupdate=registry \
    --env-file "$(get_env_dir ${NAME})/local.env" \
    -p ${LOCALHOST_IP}:${PORT}:3000 \
    -v "$(get_vol_dir ${NAME})/config":/config \
    --name "$NAME" \
    "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME" "$IMAGE_SOURCE"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# NGINX configuration with HTTP/HTTPS and WebSocket signaling is maintained in:
# apps/nginx/configs/sites/pairdrop.conf
# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
