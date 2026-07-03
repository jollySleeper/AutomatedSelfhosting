#!/bin/bash

source ../../scripts/common.sh

NAME="goatsync"
IMAGE_SOURCE="ghcr.io/jollysleeper/goatsync:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/chunks"

echo "-> Running '$NAME' Container"
# Uses pasta with --map-host-loopback=10.0.2.2 to access host services (postgres-vector, redis) at 10.0.2.2
# See docs/DNS_ARCHITECTURE.md and docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8037:3735 \
 -v "$(get_vol_dir ${NAME})/chunks":/data/chunks \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
echo ""
echo "=== POST-DEPLOYMENT STEPS ==="
echo "1. Ensure postgres-vector has goatsync database (run scripts/create-database.sh first)"
echo "2. Verify health: curl http://localhost:8037/health"
echo "3. Test API: curl http://localhost:8037/api/v1/authentication/is_etebase/"
