---
name: selfhost-service
description: >-
  Add new self-hosted services to the SelfHost server. Handles complete app setup
  including podman-setup.sh, environment files, nginx reverse proxy config, README
  documentation, and port allocation. Use when the user wants to add a new container,
  self-host a new app, deploy a service, or set up a new application on the server.
---

# Self-Host New Service

## Pre-flight Checklist

Before creating a new service, gather:
1. **Service name** (lowercase, no spaces)
2. **Container image** (verify on Docker Hub / GHCR — check ARM64 support for Orange Pi 5 Plus)
3. **Internal port** the service listens on
4. **User handling**: LinuxServer images use PUID/PGID; others use `--userns keep-id`
5. **Required volumes** and their container paths
6. **Required environment variables**
7. **Dependencies** (databases, other services)

## Port Allocation

Read `apps/nginx/README.md` for the current port table. Allocate the next available port in the appropriate range:

| Range | Category |
|-------|----------|
| 8000-8019 | Privacy frontends |
| 8020-8029 | Piped/YouTube |
| 8030-8039 | File sync / utilities / document management |
| 8040-8049 | Media servers |
| 8050-8059 | Fitness / productivity / personal finance |
| 8060-8069 | *Arr stack / media automation |
| 8070-8079 | Media add-ons (Bazarr, Tdarr, etc.) |
| 8080-8089 | Books / reading |
| 8888 | AI services |
| 8191 | Internal proxies |

## Step-by-Step Workflow

### 1. Create Directory Structure

```bash
mkdir -p apps/<service>/{environments,volumes}
# Optional: mkdir -p apps/<service>/{configs,scripts}
```

### 2. Create podman-setup.sh

Follow this template (read `apps/audiobookshelf/podman-setup.sh` as a reference):

```bash
#!/bin/bash
source ../../scripts/common.sh

NAME="<service>"
IMAGE_SOURCE="<registry>/<image>:<tag>"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/<dir>"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:<HOST_PORT>:<CONTAINER_PORT> \
 -v "$(get_vol_dir ${NAME})/<dir>":/<container-path> \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# Uncomment when nginx config is ready:
# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "<HOST_PORT>" "http"

echo "Done :)"
```

**Key rules**:
- Always use `${LOCALHOST_IP}` for port binding (127.0.0.1)
- Always add `--label io.containers.autoupdate=registry`
- For LinuxServer images: use PUID/PGID env vars (no `--user` or `--userns`)
- For other images: prefer `--userns keep-id --group-add $(id -g)` over `--user $(id -u):$(id -g)`
- For media apps: mount `$HOME/media:/media` for hardlinking support

### 3. Create environments/sample.env and local.env

**Every app MUST have both `sample.env` and `local.env`:**

#### sample.env — Complete reference with ALL possible variables

Follow the pattern from `apps/filebrowser/environments/sample.env`:

```env
# Service Name Environment Configuration
# Image: registry/image:tag
# Source: https://docs.example.com/configuration/
# Copy this file to local.env and override only the values you need.

# ── Section Name ─────────────────────────────────────────────────────────────

# Description of what this variable does (default: value)
#VARIABLE_NAME=default_value

# Another variable that IS overridden in local.env
ACTIVE_VAR=default_value
```

**sample.env rules:**
- Include header with image name, docs URL, and copy instruction
- Group variables into logical sections with `# ── Section ──` headers
- Document every possible env var with its default value
- Comment out variables that use defaults (prefixed with `#`)
- Leave uncommented only variables that are commonly overridden
- Source documentation URLs for every section
- Never include actual secrets — use placeholder values like `changeme`

#### local.env — Only overrides

```env
# Service Name - Local Configuration
# Only overrides from sample.env are listed here

ACTIVE_VAR=my_custom_value
```

**local.env rules:**
- Only include variables that differ from sample.env defaults
- Add a brief comment header explaining this is a local override file
- Never commit secrets (local.env should be gitignored for sensitive services)

For LinuxServer images, sample.env should include:
```env
# User/group ID for file permissions (LinuxServer convention)
PUID=1001
PGID=1001

# Timezone (default: Etc/UTC)
TZ=Etc/UTC
```

**Never put inline comments** after values. Use separate comment lines.

### 4. Create NGINX Site Config

Create `apps/nginx/configs/sites/<service>.conf`. Use the appropriate buffering strategy:

- **Media streaming** (video/audio): `proxy_buffering on` with temp file limits
- **API/management UIs** (*arr apps, dashboards): `proxy_buffering off`
- **SSE/WebSocket heavy**: `proxy_buffering off`
- **Static frontends**: Default buffering (small responses)

Reference: `apps/nginx/configs/sites/radarr.conf` for API services, `apps/nginx/configs/sites/jellyfin.conf` for media services.

### 5. Create README.md

Include these sections:

```markdown
# Service Name - Short Description

## Quick Reference
| Property | Value |
|----------|-------|
| **Image** | `registry/image:tag` |
| **Internal Port** | XXXX |
| **Host Port** | XXXX |
| **Subdomain** | `service.aevion.lan` |

## Access
## Initial Setup
## Volumes
## Dependencies
## Documentation
```

### 6. Update nginx README

Add the new service to **both** port tables (by port number and alphabetical) in `apps/nginx/README.md`.

### 7. Deploy

```bash
cd apps/<service>
bash podman-setup.sh
```

Then on the server:
```bash
scp -r apps/<service> legion@aevion:~/selfhost/apps/
ssh legion@aevion "cd ~/selfhost/apps/<service> && bash podman-setup.sh"
```

## Database Dependencies

If the service needs PostgreSQL, use the **shared `postgres-vector` instance** (port 5432) rather than running a separate database container:

1. Add the new database to `apps/postgres-vector/environments/db.env` in `POSTGRES_MULTIPLE_DATABASES`:
   ```
   POSTGRES_MULTIPLE_DATABASES=...:newapp,newapp,password
   ```
   Format: `database,user,password` separated by colons.

2. Or create manually on a running instance:
   ```bash
   podman exec -it postgres-vector psql -U postgresql -d postgres -c "
   CREATE USER newapp WITH PASSWORD 'password';
   CREATE DATABASE newapp OWNER newapp;
   "
   ```

3. Update `apps/postgres-vector/README.md` — add to the "Current Databases" table.

4. In the service's `local.env`, use `10.0.2.2:5432` as the DB host (via pasta loopback).

If the service needs **Redis**, use the shared Valkey/Redis on port 6379. Set a key prefix (e.g., `PAPERLESS_REDIS_PREFIX=paperless`) to avoid key collisions.

Services using host loopback for database access **must** use `--network 'pasta:--map-host-loopback,10.0.2.2'` in `podman run`.

## Networking Reference

- Containers reach host services via `10.0.2.2` (pasta loopback)
- NGINX container uses pasta network mode
- Web UIs bind to `127.0.0.1` — only accessible via NGINX reverse proxy
- BitTorrent/peer ports bind to `0.0.0.0` for incoming connections

## Rules Reference

These cursor rules provide additional context:
- `.cursor/rules/project-overview.mdc` — Architecture and conventions
- `.cursor/rules/security-practices.mdc` — Container security, user permissions
- `.cursor/rules/coding-guidelines.mdc` — Script format, port allocation, env vars
- `.cursor/rules/contribution-guidelines.mdc` — App structure, quality standards
- `.cursor/rules/deployment-guidelines.mdc` — Deploy workflow, troubleshooting
