#!/bin/bash

echo "Available Updates"
podman auto-update --dry-run | grep "pending"

podman auto-update

echo "Removing Old Images"
podman images --format '{{.Tag}},{{.ID}}' | grep '<none>' | cut -d ',' -f 2 | xargs podman rmi
