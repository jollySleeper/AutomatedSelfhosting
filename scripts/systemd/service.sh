#!/bin/bash

# Quadlet-first service orchestration
# - Symlink all .container/.pod/.kube files to ~/.config/containers/systemd
# - Reload systemd user daemon
# - Enable+start or stop all discovered units based on argument

set -euo pipefail

SELFHOST_ROOT_DIR=${SELFHOST_ROOT_DIR:-$HOME/selfhost}
UNITS_DIR="$HOME/.config/containers/systemd"

mkdir -p "$UNITS_DIR"
cd "$UNITS_DIR"

# Link all units from apps
find "$SELFHOST_ROOT_DIR/apps" -maxdepth 2 -type f \( -name "*.container" -o -name "*.kube" -o -name "*.pod" \) -print0 | while IFS= read -r -d '' f; do
    ln -sf "$f" .
done

systemctl --user daemon-reload

# Collect unit service names
mapfile -t services < <(find . -maxdepth 1 -type l -o -type f \( -name "*.container" -o -name "*.kube" -o -name "*.pod" \) -printf '%f\n' | sed 's/\..*$/.service/')

action=${1:-start}
case "$action" in
    start)
        for s in "${services[@]}"; do
            systemctl --user enable --now "$s" || true
        done
        ;;
    stop)
        for s in "${services[@]}"; do
            systemctl --user stop "$s" || true
        done
        ;;
    *)
        echo "Usage: $0 [start|stop]" >&2
        exit 1
        ;;
esac
