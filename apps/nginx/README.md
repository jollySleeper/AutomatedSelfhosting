# NGINX Reverse Proxy

NGINX is the single entry point for every self-hosted app on `aevion`. It
terminates HTTP/HTTPS on the host's ports 80/443, matches the request's
hostname to a service, and proxies to the backend running on the host. It also
serves a service dashboard, a quiet catch-all, and a health endpoint, and
applies a shared security-hardening layer.

## Overview

- **Image**: `docker.io/library/nginx:stable-alpine`
- **Runtime**: rootless Podman, as a systemd **user** service (`legion` user)
- **Network**: pasta with host-loopback mapping (`10.0.2.2` → host `127.0.0.1`)
- **Ports**: `80 → 1080` (HTTP), `443 → 1443` (HTTPS)
- **Domain**: `*.aevion.lan` (resolved by AdGuard Home)
- **tmpfs**: `/tmp` is RAM-backed (1 GB) so proxy buffer temp files never touch the NVMe SSD
- **Security**: security headers, request limits, suspicious-request detection, path blocking, `server_tokens off`, and a quiet default server that discloses no service inventory

## Rootless Architecture

This container runs **fully rootless** — no root anywhere in the chain — which
is the core security posture for the whole `aevion` stack.

### What "rootless" means here

- **No root on the host**: the container is launched by `systemctl --user`, so
  everything runs as the unprivileged `legion` user. There is no root daemon
  (unlike Docker); Podman is daemonless and forks processes under your UID.
- **No root in the container**: the upstream nginx image normally starts as
  root and drops to the `nginx` user for workers. We instead use
  `UserNS=keep-id`, which maps the **container's UID to your host UID** via a
  user namespace. Combined with the unprivileged listener ports below, nginx
  never needs root.
- **Unprivileged ports inside**: a rootless process cannot bind to ports < 1024.
  That is why nginx listens on **1080/1443** internally, and Podman publishes
  the host's **80/443** to them (`PublishPort=80:1080`, `443:1443`). The host
  side can bind 80/443 because Podman's `rootlessport` helper handles it, and
  the system is configured to allow it.
- **`pid /tmp/nginx.pid` and temp paths under `/tmp`**: the stock nginx image
  writes its PID and temp files to root-owned locations (`/var/run`,
  `/var/cache/nginx`). Rootless nginx can't write there, so `rootless/nginx.conf`
  redirects the PID and all `*_temp_path` directories into `/tmp` (which is a
  writable tmpfs mount).
- **Logs to stdout/stderr and `/tmp`**: the container can't write to
  `/var/log/nginx`. Access/error logs go to the container's stdout/stderr
  (viewable via `podman logs nginx`), and the security log is written to
  `/tmp/security.log` (see the snippets).

### Why rootless

- **Blast-radius reduction**: a compromise of nginx yields an unprivileged user
  namespace, not host root.
- **No privileged daemon**: nothing runs as root to be attacked or misconfigured.
- **Volume permissions "just work"**: `UserNS=keep-id` means files nginx reads
  (configs, certs, html) are owned by `legion` on the host and appear correctly
  owned inside the container — no `chmod 777` hacks.

See `.cursor/rules/security-practices.mdc` for the stack-wide rootless and
host-loopback guidance.

## Request Flow

```
client (browser on LAN / Tailscale)
        │  http(s)://<something>.aevion.lan
        ▼
AdGuard Home  ──►  *.aevion.lan resolves to 192.168.1.105 (the server)
        ▼
nginx :80/:443  ──►  matches Host header against server_name in conf.d/*.conf
        │
        ├── matches a service  ──►  proxy_pass to 10.0.2.2:<port> (host loopback)
        ├── home.aevion.lan     ──►  static dashboard (configs/html/index.html)
        ├── /health (any host)  ──►  200 "ok"  (container health check)
        └── no match / bare IP  ──►  default_server: quiet branded 404, no inventory
```

Backends bind to `127.0.0.1:<port>` on the host; nginx reaches them through the
pasta host-loopback address `10.0.2.2`.

## Special Virtual Hosts

| Host / Path | Config | Purpose |
|-------------|--------|---------|
| `home.aevion.lan` | `sites/home.conf` | Service dashboard (static landing page listing every service). Lives on its own hostname so the inventory is **never** exposed on bare IP. Optional HTTP Basic Auth is wired but disabled. |
| `default_server` (bare IP, unknown hosts) | `sites/000-default.conf` | Quiet catch-all on **both** HTTP (1080) and HTTPS (1443). Returns a minimal branded 404 (`html/404.html`) with **no** service list. Applies the full hardening snippet stack. Named `000-` so it always loads first (see below). |
| `/health` (served by default server) | `sites/000-default.conf` | Minimal `200 "ok"` endpoint for the container health check. Deliberately dumb — real metrics live in Prometheus/Grafana. |

## Services and Ports

All backends run on the host, reached via `10.0.2.2:<port>`.

| Port | Service | Subdomains | Description |
|------|---------|------------|-------------|
| 8000 | **AdGuard Home** | `agh`, `adguardhome` | Network-wide ad blocker and DNS |
| 8010 | **Priviblur** | `priviblur` | Tumblr alternative frontend |
| 8011 | **AnonymousOverflow** | `ao`, `anonymousoverflow` | Stack Overflow alternative frontend |
| 8012 | **Quetre** | `qo`, `quora`, `quetre` | Quora alternative frontend |
| 8013 | **Redlib** | `rd`, `reddit`, `redlib` | Reddit alternative frontend |
| 8014 | **LibMedium** | `mid`, `libmedium` | Medium alternative frontend |
| 8015 | **LibreMDB** | `imdb`, `libremdb` | IMDb alternative frontend |
| 8016 | **Dumb** | `dumb` | Genius lyrics alternative frontend |
| 8017 | **BiblioReads** | `gr`, `br`, `biblioreads` | Goodreads alternative frontend |
| 8018 | **Nitter** | `nitter` | Twitter/X alternative frontend |
| 8019 | **Rimgo** | `rimgo` | Imgur alternative frontend |
| 8021 | **Piped Frontend** | `yt`, `piped`, `piped-frontend` | YouTube alternative frontend |
| 8022 | **Piped API** | `piped-api` | Piped backend API |
| 8023 | **Piped Proxy** | `piped-proxy` | Piped media proxy |
| 8031 | **Syncthing** | `sync`, `syncthing` | File synchronization |
| 8032 | **File Browser** | `fb`, `filebrowser` | Web-based file manager |
| 8033 | **Paperless-ngx** | `paperless`, `docs` | Document management |
| 8034 | **PairDrop** | `pairdrop`, `pd`, `drop` | Peer-to-peer file sharing (AirDrop alternative) |
| 8037 | **GoatSync** | `goatsync` | EteSync-compatible calendar/contacts sync |
| 8041 | **Jellyfin** | `jf`, `jellyfin` | Media server (movies, TV, music) |
| 8042 | **Audiobookshelf** | `abs`, `audiobookshelf` | Audiobook and podcast server |
| 8043 | **Navidrome** | `navi`, `navidrome` | Music streaming server |
| 8051/8052 | **Wger** | `wger`, `wger-web` | Workout & fitness tracker (web + static) |
| 8053 | **BeaverHabits** | `bh`, `habits`, `beaverhabits` | Habit tracking |
| 8054 | **Speedtest Tracker** | `speedtest`, `st` | Network speed monitoring |
| 8055 | **Actual Budget** | `budget`, `actual-budget` | Personal finance / budgeting |
| 8056 | **Sure** ⚠️ | `sure` | Personal finance & wealth dashboard *(config in repo, not yet deployed)* |
| 8057 | **Paisa** ⚠️ | `paisa` | Ledger-based finance manager *(config in repo, not yet deployed)* |
| 8060 | **Prowlarr** | `prowlarr` | Indexer manager for *arr apps |
| 8061 | **qBittorrent** | `qbt`, `qbittorrent` | Torrent download client |
| 8062 | **aria2 RPC** | *(internal)* | Download daemon (HTTP/FTP/BT) |
| 8063 | **AriaNg** | `ariang` | Web UI for aria2 |
| 8064 | **Radarr** | `radarr` | Movie management & automation |
| 8065 | **Sonarr** | `sonarr` | TV management & automation |
| 8066 | **Lidarr** | `lidarr` | Music management & automation |
| 8067 | **Readarr** | `readarr` | Book & audiobook automation |
| 8068 | **Seerr** | `seerr` | Media request & discovery |
| 8069 | **Jellystat** | `jellystat` | Jellyfin usage analytics |
| 8081 | **systemd-switch** | `sysdwitch`, `control`, `systemd-switch`, `service-control` | Web UI to control systemd user services |
| 8083 | **Calibre-Web-Automated** | `calibre-web-automated` | eBook library |
| 8088 | **Qwiklip** | `ig`, `reels`, `qwiklip` | Instagram alternative frontend |
| 8191 | **FlareSolverr** | *(internal)* | Cloudflare bypass proxy for Prowlarr |
| 8888 | **Open WebUI** | `ai`, `open-webui` | LLM chat interface (Ollama) |

> ⚠️ **Deployment drift**: `sure.conf` and `paisa.conf` exist in this repo but
> are **not** currently present on the server. Either deploy them or remove them
> from the repo to keep source and server in sync.

## Direct Infrastructure Ports

These protocols are published directly and do not pass through NGINX:

| Port | Service | Protocol | Scope | Purpose |
|---|---|---|---|---|
| 3478 | **Coturn** | TCP/UDP | LAN/Tailscale only | Authenticated STUN/TURN listener for PairDrop |
| 49160-49200 | **Coturn** | UDP | LAN/Tailscale only | Restricted WebRTC relay allocation range |

Coturn must never be port-forwarded from the public Internet in its current
plain-TURN, private-realm configuration.

### Port Ranges

- **8000–8019**: Privacy-focused alternative frontends
- **8020–8029**: Piped (YouTube) stack
- **8030–8039**: Sync, files, documents (Syncthing, File Browser, Paperless, PairDrop, GoatSync)
- **8040–8049**: Media servers (Jellyfin, Audiobookshelf, Navidrome)
- **8050–8059**: Fitness, habits, and personal finance
- **8060–8069**: *arr stack, download clients, media requests/analytics
- **8080–8089**: Utilities (systemd-switch, Calibre-Web, Qwiklip)
- **8191**: Internal proxy (FlareSolverr)
- **8888**: AI / Open WebUI

## Configuration Structure

```
apps/nginx/
├── nginx.container            # Quadlet unit (source of truth for the systemd service)
├── podman-setup.sh            # Bootstraps/recreates the container, generates the quadlet
└── configs/
    ├── rootless/
    │   ├── nginx.conf                       # Main config (rootless: PID + temp under /tmp, server_tokens off)
    │   └── nginx-confd-default.conf.bak     # Legacy stock default (unused; kept for reference)
    ├── root/                  # Legacy ROOTFUL config set (unused; superseded by rootless/)
    │   ├── nginx.conf.bak
    │   └── nginx-confd-default.conf.bak
    ├── sites/                 # One file per service (mounted as /etc/nginx/conf.d)
    │   ├── 000-default.conf   # default_server (HTTP + HTTPS): quiet 404 + /health; loads first
    │   ├── home.conf          # home.aevion.lan dashboard vhost
    │   └── <service>.conf     # per-service reverse-proxy vhosts
    ├── snippets/              # Reusable includes
    │   ├── proxy-defaults.conf       # Proxy headers + WebSocket upgrade handling
    │   ├── security-headers.conf     # CSP, X-Frame-Options, Permissions-Policy, etc.
    │   ├── request-limits.conf       # Body size + timeouts (anti-DoS)
    │   ├── rate-limiting.conf        # Optional rate limiting (documented, off by default)
    │   ├── suspicious-detection.conf # Attack-pattern detection → 444, logs to /tmp/security.log
    │   ├── path-blocking.conf        # Blocks dotfiles, admin panels, script extensions
    │   ├── ssl-params.conf           # TLS protocols/ciphers
    │   └── self-signed.conf          # Points to the self-signed cert/key
    ├── html/
    │   ├── index.html         # Dashboard served on home.aevion.lan
    │   └── 404.html           # Minimal branded 404 for the default server
    └── certs/                 # Self-signed cert + key (fullchain.pem, cert-key.pem)
```

> **`.bak` files**: everything in `root/` and `rootless/nginx-confd-default.conf.bak`
> are retired configs kept only for reference. They are **not** mounted or loaded
> by the running container.

## Security

### Default server (catch-all)

The `default_server` intentionally reveals nothing:

- Bare IP and unknown hostnames — over **both HTTP and HTTPS** (e.g.
  `http://192.168.1.105`, `https://aevion.lan`) — get a **minimal branded 404**
  with no service list. No inventory disclosure to scanners or a pivoting
  compromised container.
- Declared `default_server` on **both** `:1080` and `:1443`, and the file is
  named `000-default.conf` so it loads first. Either mechanism alone makes it the
  fallback; together they guarantee the quiet catch-all wins even if a
  `default_server` flag is ever accidentally dropped (this is exactly how the
  original "bare host → first alphabetical vhost" bugs happened, on HTTP and
  then HTTPS).
- `server_tokens off` (in `nginx.conf`) hides the nginx version from response
  headers and error pages.
- The full hardening snippet stack (headers, limits, suspicious detection, path
  blocking) is applied here since bare-IP traffic is the most likely to be hostile.

The friendly dashboard is deliberately **not** on the default server — it lives
on `home.aevion.lan` instead.

### Security headers (`security-headers.conf`)

- `X-Frame-Options: DENY` — anti-clickjacking
- `X-Content-Type-Options: nosniff` — no MIME sniffing
- `X-XSS-Protection: 1; mode=block`
- `Content-Security-Policy` — restrictive default-src
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` — all browser features denied
- Cross-Origin `CORP` / `COEP` / `COOP`

### Request protection

- **Body size**: capped (`request-limits.conf`) to blunt large-POST abuse
- **Timeouts**: short header/body/keepalive/send timeouts defeat slowloris-style attacks
- **Path blocking** (`path-blocking.conf`): dotfiles (`.git`, `.env`), admin
  panels (`wp-admin`, `phpmyadmin`, …), and script extensions (`.php`, `.asp`, …) → `444`
- **Suspicious detection** (`suspicious-detection.conf`): path traversal, XSS
  patterns, and known scanner user-agents (sqlmap, nikto, nmap, …) → `444`,
  logged to `/tmp/security.log`

### Optional dashboard auth

`home.conf` contains fully-wired HTTP Basic Auth, **commented out**. To enable:

1. Create the password file on the server (never commit it — it's gitignored):
   ```bash
   htpasswd -c ~/selfhost/apps/nginx/configs/.htpasswd <username>
   # or, without apache2-utils:
   printf '<username>:%s\n' "$(openssl passwd -apr1)" > ~/selfhost/apps/nginx/configs/.htpasswd
   ```
2. Uncomment the `.htpasswd` volume mount in `nginx.container` (and
   `podman-setup.sh`) and recreate the container.
3. Uncomment the `auth_basic` directives in `home.conf` and reload nginx.

Basic Auth is base64, not encryption — it is only safe because it's on the
HTTPS (1443) vhost, behind LAN/Tailscale.

## SSL/TLS

Configured in `ssl-params.conf`, using a self-signed certificate
(`self-signed.conf`):

- **Protocols**: TLSv1.2 and TLSv1.3 only
- **Ciphers**: `EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH`
- **ECDH curve**: `secp384r1`
- **Session cache**: 10 MB shared; session tickets **off**
- **OCSP stapling**: off (self-signed)

## Proxy Buffering Strategy

### The problem

NGINX's `proxy_buffering on` writes temp files to `/tmp/proxy_temp`. Inside a
rootless Podman container, `/tmp` defaults to the overlay filesystem on the NVMe
SSD, causing unnecessary write wear during media streaming.

### The solution: tmpfs + hybrid buffering

The container mounts `/tmp` as tmpfs (RAM, 1 GB), so proxy temp files go to RAM.
Buffering is then chosen per service:

| Service Category | `proxy_buffering` | Why |
|-----------------|-------------------|-----|
| **Media servers** (Jellyfin, Audiobookshelf, Navidrome) | **ON** | Fast localhost upstream vs. slow Wi-Fi client — buffering prevents backpressure stalls. Temp files land in RAM. |
| **Privacy frontends** (Redlib, Nitter, Rimgo, …) | **OFF** | Internet upstream is slower than the client; no speed mismatch to buffer. |
| ***arr stack** (Radarr, Sonarr, Prowlarr, …) | **OFF** | Small JSON/API responses; nothing to buffer. |
| **Download clients** (qBittorrent, AriaNg) | **OFF** | Management UIs; downloads don't flow through nginx. |
| **Requests/Analytics** (Seerr, Jellystat) | **OFF** | Web/API apps; no media through nginx. |
| **LLM/SSE** (Open WebUI) | **OFF** | Server-Sent Events need unbuffered streaming. |
| **Sync** (GoatSync) | **OFF** | Low-latency unbuffered passthrough. |
| **Everything else** | Default (on) | Small responses fit default memory buffers; no temp files. |

### Buffer sizing

| Service | `proxy_max_temp_file_size` | Rationale |
|---------|---------------------------|-----------|
| Jellyfin | 256 MB | Large MKV files need a wide buffer window |
| Audiobookshelf | 128 MB | Audiobook chapters ~50–100 MB |
| Navidrome | 64 MB | Music tracks ~5–30 MB (FLAC) |

Worst-case simultaneous streaming ≈ 448 MB, comfortably within the 1 GB tmpfs.

### WebSocket handling

`proxy-defaults.conf` relies on a `map` in `nginx.conf` for conditional upgrades:

```
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
```

Normal requests get `Connection: close`; WebSocket requests get
`Connection: upgrade`.

### Header inheritance gotcha

NGINX drops **all** inherited `proxy_set_header` directives if a child block
defines any of its own. So site configs that add custom headers include
`proxy-defaults.conf` **inside** each `location` block, not at server scope.

## Deployment

This service follows the repo's script-based deployment (see
`.cursor/rules/deployment-guidelines.mdc`).

### Editing configs (no container change)

For pure config edits (sites, snippets, html, `nginx.conf`), copy to the server
and reload:

```bash
scp apps/nginx/configs/sites/<file>.conf legion@aevion:~/selfhost/apps/nginx/configs/sites/
ssh legion@aevion 'podman exec nginx nginx -t && podman exec nginx nginx -s reload'
```

### Changing the container (volumes, ports, health check)

When `nginx.container` / `podman-setup.sh` changes (e.g. a new volume mount),
the container must be **recreated** — a reload/restart is not enough:

```bash
scp apps/nginx/nginx.container legion@aevion:~/selfhost/apps/nginx/
ssh legion@aevion '
  cd ~/selfhost/apps/nginx
  systemctl --user stop nginx.service
  podman rm -f nginx
  ln -sf ~/selfhost/apps/nginx/nginx.container ~/.config/containers/systemd/nginx.container
  systemctl --user daemon-reload
  systemctl --user start nginx.service
'
```

### Verify

```bash
ssh legion@aevion '
  systemctl --user is-active nginx.service
  podman exec nginx nginx -t
  podman inspect nginx --format "{{.State.Health.Status}}"
  curl -s http://127.0.0.1/health          # -> ok
  curl -s -o /dev/null -w "%{http_code}\n" http://192.168.1.105/   # -> 404
'
```

## Troubleshooting

- **Container won't start / restart loop**: `podman logs nginx` or
  `journalctl --user -u nginx.service`. Common causes: a config referencing a
  missing snippet/file, or a write to a root-only path (must be under `/tmp`).
- **`nginx -t` warnings**:
  - *conflicting server name* → two configs claim the same hostname; the second
    is silently dropped. Fix by removing the duplicate alias.
  - *duplicate MIME type "text/html"* → `text/html` is always gzipped by nginx;
    don't list it in `gzip_types`.
- **A service 404s unexpectedly**: check its hostname isn't shadowed by another
  config's `server_name`, and that the backend is listening (`ss -tlnp` on host).
- **Health check killing the container**: the health check hits `/health`;
  ensure `default.conf` still serves it with a `200`.

## Notes

- Backends are reached at `10.0.2.2:<port>` via pasta host loopback.
- Access/error logs → `podman logs nginx`; security log → `/tmp/security.log`
  (ephemeral, cleared on restart since `/tmp` is tmpfs).
- Rate limiting is available but off by default — see `rate-limiting.conf`.
- Keep this README in sync when adding/removing a service config.
