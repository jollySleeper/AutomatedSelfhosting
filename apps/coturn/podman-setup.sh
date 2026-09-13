#!/bin/bash
set -euo pipefail

source ../../scripts/common.sh

NAME="coturn"
IMAGE_SOURCE="docker.io/coturn/coturn:4.18.0"
LISTEN_PORT="3478"
RELAY_MIN_PORT="49160"
RELAY_MAX_PORT="49200"

stop_existing_quadlet_service() {
    if systemctl --user cat "${NAME}.service" >/dev/null 2>&1; then
        echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] INFO: Stopping existing ${NAME}.service before container replacement"
        systemctl --user stop "${NAME}.service"
    fi
}

escape_turn_environment_references() {
    local quadlet_file="${NAME}.container"
    local temporary_file="${quadlet_file}.tmp"

    if [[ ! -f "$quadlet_file" ]]; then
        echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Generated Quadlet not found: $quadlet_file" >&2
        return 1
    fi

    # Podlet copies the command arguments literally into Exec=. systemd would
    # expand ${TURN_*} itself, before Podman loads the container env file.
    # Doubling '$' makes systemd pass the references to the image entrypoint,
    # which expands them after local.env has been loaded inside the container.
    sed \
        -e 's/${TURN_REALM}/$${TURN_REALM}/g' \
        -e 's/${TURN_USERNAME}/$${TURN_USERNAME}/g' \
        -e 's/${TURN_PASSWORD}/$${TURN_PASSWORD}/g' \
        "$quadlet_file" > "$temporary_file"
    mv "$temporary_file" "$quadlet_file"

    if grep -Eq '(^|[^$])\$\{TURN_(REALM|USERNAME|PASSWORD)\}' "$quadlet_file"; then
        echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Unescaped TURN reference remains in $quadlet_file" >&2
        return 1
    fi
}

./scripts/generate-local-config.sh

if [[ -z "${1:-}" ]]; then
    stop_existing_quadlet_service
fi
action_based_on_query "${1:-}-con" "$NAME" "$IMAGE_SOURCE"

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] INFO: Running '$NAME' container"
podman run \
    --detach \
    --restart unless-stopped \
    --label io.containers.autoupdate=registry \
    --env-file "$(get_env_dir ${NAME})/local.env" \
    --read-only \
    --cap-drop all \
    --cap-add net_bind_service \
    --security-opt no-new-privileges \
    --memory 256m \
    --cpus 2 \
    --tmpfs /tmp:rw,noexec,nosuid,nodev,size=16m \
    --tmpfs /var/lib/coturn:rw,noexec,nosuid,nodev,size=16m \
    --health-cmd "turnutils_stunclient -p ${LISTEN_PORT} 127.0.0.1" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    --health-start-period 10s \
    -p ${LISTEN_PORT}:${LISTEN_PORT}/tcp \
    -p ${LISTEN_PORT}:${LISTEN_PORT}/udp \
    -p ${RELAY_MIN_PORT}-${RELAY_MAX_PORT}:${RELAY_MIN_PORT}-${RELAY_MAX_PORT}/udp \
    --name "$NAME" \
    "$IMAGE_SOURCE" \
    -n \
    --log-file=stdout \
    --listening-port=${LISTEN_PORT} \
    --min-port=${RELAY_MIN_PORT} \
    --max-port=${RELAY_MAX_PORT} \
    --fingerprint \
    --lt-cred-mech \
    --no-tls \
    --no-multicast-peers \
    --unauthorized-ratelimit \
    --total-quota=24 \
    --user-quota=12 \
    '--realm=${TURN_REALM}' \
    '--user=${TURN_USERNAME}:${TURN_PASSWORD}'

action_based_on_query "generate-con-quadlet" "$NAME" "$IMAGE_SOURCE"
escape_turn_environment_references
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] INFO: Coturn deployment complete"
