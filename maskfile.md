# maskfile

## bootstrap
Enable lingering, link the user service, and start it.
```bash
set -euo pipefail
loginctl enable-linger "$USER" || true
mkdir -p "$HOME/.config/systemd/user"
cd "$HOME/.config/systemd/user"
ln -sf "${SELFHOST_ROOT_DIR:-$HOME/selfhost}/selfhost.service" .
systemctl --user daemon-reload
systemctl --user enable --now selfhost.service
```

## enable-auto-update
Enable Podman auto-update timer for the current user.
```bash
set -euo pipefail
systemctl --user enable --now podman-auto-update.timer
systemctl --user status podman-auto-update.timer | cat
```

## link-units
Symlink all .container/.kube/.pod units under user containers systemd dir.
```bash
set -euo pipefail
mkdir -p "$HOME/.config/containers/systemd"
cd "$HOME/.config/containers/systemd"
find "${SELFHOST_ROOT_DIR:-$HOME/selfhost}/apps" -maxdepth 2 -type f \( -name "*.container" -o -name "*.kube" -o -name "*.pod" \) -print0 | while IFS= read -r -d '' f; do
  ln -sf "$f" .
done
systemctl --user daemon-reload
```

## enable [unit]
Enable a specific unit.
```bash
set -euo pipefail
systemctl --user enable "$MASK_unit"
```

## disable [unit]
Disable a specific unit.
```bash
set -euo pipefail
systemctl --user disable "$MASK_unit"
```

## start-all
Enable and start all linked units.
```bash
set -euo pipefail
mapfile -t services < <(find "$HOME/.config/containers/systemd" -maxdepth 1 -type l -o -type f \( -name "*.container" -o -name "*.kube" -o -name "*.pod" \) -printf '%f\n' | sed 's/\..*$/.service/')
for s in "${services[@]}"; do
  systemctl --user enable --now "$s" || true
done
```

## stop-all
Stop all linked units.
```bash
set -euo pipefail
mapfile -t services < <(find "$HOME/.config/containers/systemd" -maxdepth 1 -type l -o -type f \( -name "*.container" -o -name "*.kube" -o -name "*.pod" \) -printf '%f\n' | sed 's/\..*$/.service/')
for s in "${services[@]}"; do
  systemctl --user stop "$s" || true
done
```

## secrets-create [name] [file]
Create a podman secret.
```bash
set -euo pipefail
podman secret create "$MASK_name" "$MASK_file"
```

## secrets-ls
List secrets.
```bash
set -euo pipefail
podman secret ls
```

## kube-generate [pod]
Generate Kubernetes YAML from a running pod/containers.
```bash
set -euo pipefail
podman kube generate "$MASK_pod"
```

## kube-play [file]
Play a Kubernetes YAML once (for testing).
```bash
set -euo pipefail
podman kube play "$MASK_file"
```

## start [unit]
Start a specific unit (e.g., anonymousoverflow.service).
```bash
set -euo pipefail
systemctl --user start "$MASK_unit"
```

## stop [unit]
Stop a specific unit.
```bash
set -euo pipefail
systemctl --user stop "$MASK_unit"
```

## restart [unit]
Restart a specific unit.
```bash
set -euo pipefail
systemctl --user restart "$MASK_unit"
```

## status [unit]
Show status of a specific unit.
```bash
set -euo pipefail
systemctl --user status "$MASK_unit" | cat
```

## logs [unit]
Tail logs for a specific unit.
```bash
set -euo pipefail
journalctl --user -u "$MASK_unit" -n 100 | cat
```

## logs-follow [unit]
Follow logs for a specific unit.
```bash
set -euo pipefail
journalctl --user -u "$MASK_unit" -f
```

## auto-update
Run Podman auto-update now and prune old images.
```bash
set -euo pipefail
podman auto-update --dry-run | grep pending || true
podman auto-update
podman images --format '{{.Tag}},{{.ID}}' | grep '<none>' | cut -d ',' -f 2 | xargs -r podman rmi || true
```

## nginx-generate [subdomain] [domain] [tld] [port] [protocol]
Generate nginx site file from template and reload nginx.
```bash
set -euo pipefail
"${SELFHOST_ROOT_DIR:-$HOME/selfhost}"/scripts/common.sh generate-nginx-conf-file "$MASK_subdomain" "$MASK_domain" "$MASK_tld" "$MASK_port" "$MASK_protocol"
```

## ssl-generate [domain1] [domain2] ...
Generate SSL certificates for your homelab services using self-signed certificates.
Based on: https://akashrajpurohit.com/blog/https-with-selfsigned-certificates-for-your-homelab-services/
```bash
set -euo pipefail
"${SELFHOST_ROOT_DIR:-$HOME/selfhost}"/scripts/generate_ssl_cert.sh "$@"
```
