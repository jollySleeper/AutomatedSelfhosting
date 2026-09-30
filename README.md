# Automated Selfhosting
Selfhosting made easy with Podman Quadlet and user services.

## What this repo provides
- **Simple app folders**: Each app under `apps/<name>` has a `podman-setup.sh`, optional `configs/`, `environments/`, and generates a Quadlet unit (`.container`/`.pod`).
- **User-level systemd service**: Starts all apps on login/boot via `selfhost.service` and your user’s lingering session.
- **Auto-updates**: Uses `io.containers.autoupdate=registry` and can be paired with `podman-auto-update.timer`.
- **Reverse proxy helper**: Nginx config templating via `scripts/common.sh`.

## Documentation

All cross-cutting infrastructure docs, runbooks, and guides live under
[`docs/`](./docs/). See [`docs/README.md`](./docs/README.md) for the full index.
Highlights:

- [`docs/DNS_ARCHITECTURE.md`](./docs/DNS_ARCHITECTURE.md) — end-to-end DNS flow (AGH, Tailscale, pasta, `containers.conf`, per-container `--dns` bypass, AAAA policy, the Podman 5.x `--dns` append quirk).
- [`docs/MEDIA_SERVER_GUIDE.md`](./docs/MEDIA_SERVER_GUIDE.md) — *arr-stack setup.
- [`docs/README_TEMPLATE.md`](./docs/README_TEMPLATE.md) — the per-service README template.

App-specific docs stay inside each `apps/<service>/README.md`.

## Prerequisites
- Podman 5.4+ (Quadlet included)
- Systemd user session (Linux) with `loginctl enable-linger <user>`
- Optional: `podman-auto-update.timer` for unattended image refresh

Note for macOS users: Podman runs inside a Podman Machine VM and systemd user services aren’t available on macOS. The automation in this repo is designed for Linux hosts. You can still run individual `podman-setup.sh` scripts on macOS.

## Quickstart (Linux)
1) Clone the repo and, for convenience, symlink to `~/selfhost` or export `SELFHOST_ROOT_DIR`:
```bash
git clone https://github.com/<you>/SelfHost
ln -s $(pwd)/SelfHost ~/selfhost  # optional, but recommended
```
2) Enable user lingering and the service (or use Mask tasks below):
```bash
~/selfhost/scripts/systemd/enable_service.sh
```
3) Verify:
```bash
systemctl --user status selfhost.service | cat
```

## How it works
- Each `apps/<name>/podman-setup.sh`:
  - Pulls/builds the image if needed
  - Runs the container once (labels, ports, volumes)
  - Generates a Quadlet unit (`<name>.container`) and installs it under `~/.config/containers/systemd/`
  - Optionally generates an nginx site config from a template
- `selfhost.service` calls `scripts/systemd/service.sh` which iterates over `apps/*` and installs/starts apps.

## Using Podman 5.4 effectively
- **Lean into Quadlet**: Write and track `.container`, `.pod`, or `.kube` files directly as source-of-truth. Shell can be minimized to one-time bootstrap.
- **Kube + Quadlet**: For multi-service apps, keep a K8s YAML and install it as a Quadlet `.kube` unit. Then `podman auto-update` can manage it just like containers.
- **Secrets**: Move credentials to `podman secret` and reference via Quadlet `Secret=` instead of `.env` where possible.
- **Healthchecks**: Define `HealthCmd=`/`HealthInterval=` in Quadlet (or `--health-*` flags) so systemd can restart on failures.
- **Rootless networking improvements**: The whole stack is now on `pasta` (Podman 5.x default). Containers that need the host's `127.0.0.1` services use `pasta:--map-host-loopback,10.0.2.2`; the rest use plain `pasta`. Privileged ports (<1024) still require host-level changes; otherwise publish higher ports and reverse proxy. See [`docs/DNS_ARCHITECTURE.md`](docs/DNS_ARCHITECTURE.md) and [`docs/HOST_LOOPBACK_SECURITY.md`](docs/HOST_LOOPBACK_SECURITY.md).
- **Auto-update timer**: Enable `podman-auto-update.timer` at the user level instead of a custom cron.

## Using Mask tasks
Install Mask and run tasks from the repo root.
```bash
# bootstrap service and link
mask bootstrap

# link all Quadlet units and reload
mask link-units

# enable auto-update timer
mask enable-auto-update

# start/stop/status/logs for a unit
mask start unit=anonymousoverflow.service
mask status unit=anonymousoverflow.service
mask logs unit=anonymousoverflow.service
```

## Directory layout
```
apps/
  <name>/
    podman-setup.sh
    <name>.container | <name>.pod | <name>.kube   # generated or curated
    configs/
    environments/
scripts/
  podman/{container.sh,image.sh,pod.sh}
  systemd/{enable_service.sh,service.sh}
selfhost.service
```

## Common tasks
- Start all apps: `systemctl --user start selfhost.service`
- Stop all apps: `systemctl --user stop selfhost.service`
- Update images and apply: `podman auto-update`
- Tail one app: `journalctl --user -u <app>.service -f`

## Adding a new app
1) Create `apps/<name>/podman-setup.sh` using an existing app as a template.
2) Use an `environments/*.env` file for configuration where possible.
3) Prefer Quadlet fields over runtime flags long-term. Example (tracked file `apps/<name>/<name>.container`):
   - `ContainerName=<name>`
   - `Image=docker.io/library/<image>:<tag>`
   - `Userns=keep-id`
   - `PublishPort=127.0.0.1:8011:8080/tcp`
   - `EnvironmentFile=%h/selfhost/apps/<name>/environments/local.env`
   - `Label=io.containers.autoupdate=registry`
4) If exposed via nginx, call the helper to generate a site file or add your own.
5) Symlink all units: `mask link-units` or `~/selfhost/scripts/systemd/service.sh start`.

## Reverse proxy
Nginx configs are generated from templates in `apps/nginx/configs/site-templates/`. The helper in `scripts/common.sh` fills `{{subdomain}}`, `{{domain}}`, `{{tld}}`, and `{{port}}`.

## Container Testing and Deployment Workflow

### Current Workflow (Recommended)
This repo uses `podlet` for iterative container development:

1. **Test manually**: Run containers with `podman run` to verify functionality
2. **Generate quadlet**: Use `podlet generate container <name>` to create `.container` files
3. **Deploy via systemd**: Quadlets are loaded automatically by systemd user services
4. **Iterate**: Modify, regenerate, and redeploy as needed

**Why this works**: Allows testing container behavior before committing to systemd management, with full podlet automation.

### Direct Quadlet Writing (Alternative)
For new containers, you can write `.container` files directly:

```ini
[Unit]
Description=My App

[Container]
Image=docker.io/library/nginx:alpine
PublishPort=8080:80
AutoUpdate=registry

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

**When to use**: New containers, version control as first-class citizens, complex multi-container setups (use `.kube` files).

### Podman 5 Native Quadlets
- **No external tools needed**: Podman includes native quadlet processing
- **Automatic loading**: Files in `~/.config/containers/systemd/` are processed by systemd
- **Built-in generator**: `/usr/libexec/podman/quadlet` handles the conversion
- **Systemd integration**: `podman-system-generator` creates systemd services

## Upgrading from Podman 4.9 to 5.4 — what you can do better
- Replace ad-hoc generation tooling with native Quadlet files under `~/.config/containers/systemd/` checked into this repo (no external `podlet` needed).
- Convert multi-container setups (e.g., `immich`) to a `.kube` Quadlet unit via `podman kube generate` and commit that YAML; systemd will manage it.
- Adopt `podman secret` and mount them through Quadlet `Secret=` to avoid leaking credentials in env files.
- Add `HealthCmd=` to critical services and set `Restart=on-failure`/`StartLimit*` in the Unit section.
- Consider `--userns=keep-id` for better host file permissions instead of passing `--user`.
- Use the user `podman-auto-update.timer` instead of custom update scripts; still keep `scripts/update_images.sh` for manual runs.

## Troubleshooting
- If ports <1024 fail to bind rootless, either raise `net.ipv4.ip_unprivileged_port_start` on the host, use a reverse proxy on higher ports, or consider `pasta` networking where available.
- If nginx configs don’t render, check that template paths under `apps/nginx/configs/` exist and the user service has access.
- On macOS, run apps manually via `apps/<name>/podman-setup.sh` inside the Podman VM; systemd user units aren’t available.

## Future scope
- Track `.container`/`.kube` files as first-class, minimize shell generation.
- Add `podman secret` for credentials and `tmpfs` for ephemeral data.
- Introduce `healthchecks` for all externally exposed services.
- Provide a `Makefile` or `justfile` with `install`, `start`, `stop`, `update`, `logs` targets.
- Add CI with `shellcheck` and `shfmt` to lint scripts.
- Optional: switch reverse proxy to Caddy for automatic TLS or fully document nginx + ACME.

---

## SystemD Service (Linux)
All containers in `apps` will start on boot via the user service.

### Enable
```bash
./selfhost/scripts/systemd/enable_service.sh
```

### Manual run
To manually run the service script see `selfhost/scripts/systemd/service.sh`.

## TODOs
- [ ] Use `PORT` variables across all `podman-setup.sh`
- [ ] Replace hardcoded domains in `generate_nginx_conf_file` with `SELFHOST_DOMAIN`