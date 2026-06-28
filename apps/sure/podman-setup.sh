#!/bin/bash

source ../../scripts/common.sh

NAME="sure"
IMAGE_SOURCE="ghcr.io/we-promise/sure:stable"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/postgres-data"
mkdir -pv "$(get_vol_dir ${NAME})/redis-data"
mkdir -pv "$(get_vol_dir ${NAME})/app-storage"

echo "-> Creating Sure Pod"
podman pod create \
  --name sure-pod \
  -p ${LOCALHOST_IP}:8056:3000 \
  2>/dev/null || echo "Pod already exists"

echo "-> Running PostgreSQL for Sure"
podman run \
  --detach \
  --restart unless-stopped \
  --pod sure-pod \
  --env-file "$(get_env_dir ${NAME})/local.env" \
  -v "$(get_vol_dir ${NAME})/postgres-data":/var/lib/postgresql/data \
  --name sure-postgres \
  docker.io/library/postgres:16-alpine \
  2>/dev/null || echo "sure-postgres already running"

echo "-> Running Redis for Sure"
podman run \
  --detach \
  --restart unless-stopped \
  --pod sure-pod \
  -v "$(get_vol_dir ${NAME})/redis-data":/data \
  --name sure-redis \
  docker.io/library/redis:7-alpine \
  2>/dev/null || echo "sure-redis already running"

echo "-> Waiting for PostgreSQL to be ready..."
sleep 5

echo "-> Running Sure Web (Rails)"
podman run \
  --detach \
  --restart unless-stopped \
  --label io.containers.autoupdate=registry \
  --pod sure-pod \
  --env-file "$(get_env_dir ${NAME})/local.env" \
  -v "$(get_vol_dir ${NAME})/app-storage":/rails/storage \
  --name sure-web \
  "$IMAGE_SOURCE" \
  2>/dev/null || echo "sure-web already running"

echo "-> Running Sure Worker (Sidekiq)"
podman run \
  --detach \
  --restart unless-stopped \
  --label io.containers.autoupdate=registry \
  --pod sure-pod \
  --env-file "$(get_env_dir ${NAME})/local.env" \
  -v "$(get_vol_dir ${NAME})/app-storage":/rails/storage \
  --name sure-worker \
  "$IMAGE_SOURCE" \
  bundle exec sidekiq \
  2>/dev/null || echo "sure-worker already running"

echo ""
echo "Sure is running at http://127.0.0.1:8056"
echo "First visit will prompt account creation."
echo ""
echo "Done :)"
