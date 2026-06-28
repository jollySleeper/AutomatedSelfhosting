# Media Server Enhancement Guide

Complete guide for setting up the *arr stack and media automation on the SelfHost server.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DISCOVERY & REQUESTS                        │
│                                                                     │
│  ┌──────────┐     ┌──────────┐                                      │
│  │  Seerr   │────>│  Radarr  │──┐                                   │
│  │ (8068)   │     │  (8064)  │  │                                   │
│  │          │     └──────────┘  │    ┌─────────────┐                │
│  │          │     ┌──────────┐  ├───>│ qBittorrent │                │
│  │          │────>│  Sonarr  │──┘    │   (8061)    │                │
│  │          │     │  (8065)  │       └──────┬──────┘                │
│  └──────────┘     └──────────┘              │                       │
│                                             ▼                       │
│                   ┌──────────┐    ~/media/Downloads/                 │
│                   │  Lidarr  │──────────────┤                       │
│                   │  (8066)  │              │                        │
│                   └──────────┘              │                        │
│                   ┌──────────┐              │                        │
│                   │ Readarr  │──────────────┘                       │
│                   │  (8067)  │                                       │
│                   └──────────┘                                       │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                         INDEXER MANAGEMENT                          │
│                                                                     │
│  ┌──────────────┐     ┌──────────────┐                              │
│  │   Prowlarr   │────>│ FlareSolverr │  (optional, port 8191)       │
│  │    (8060)    │     │              │                              │
│  └──────┬───────┘     └──────────────┘                              │
│         │                                                           │
│         ├── Syncs indexers to Radarr                                │
│         ├── Syncs indexers to Sonarr                                │
│         ├── Syncs indexers to Lidarr                                │
│         └── Syncs indexers to Readarr                               │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                         MEDIA SERVERS                               │
│                                                                     │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────────┐   │
│  │ Jellyfin │  │Audiobookshelf│  │ Navidrome  │  │ Calibre-Web  │   │
│  │  (8041)  │  │   (8042)     │  │   (8043)   │  │   (8083)     │   │
│  │          │  │              │  │            │  │              │   │
│  │ Movies   │  │ Audiobooks   │  │   Music    │  │   eBooks     │   │
│  │ TV Shows │  │ Podcasts     │  │            │  │              │   │
│  └──────────┘  └──────────────┘  └───────────┘  └──────────────┘   │
│       │                                                             │
│  ┌──────────┐                                                       │
│  │Jellystat │  Analytics & monitoring                               │
│  │  (8069)  │                                                       │
│  └──────────┘                                                       │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                     ALTERNATIVE DOWNLOAD CLIENT                     │
│                                                                     │
│  ┌──────────┐     ┌──────────┐                                      │
│  │  AriaNg  │────>│  aria2   │──> ~/media/Downloads/aria2/          │
│  │  (8063)  │     │  (8062)  │                                      │
│  └──────────┘     └──────────┘                                      │
│  For HTTP/FTP direct downloads (not *arr integrated)                │
└─────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

The shared media directory enables **hardlinking** — when *arr apps "move" files from downloads to the library, they create a hardlink (instant, zero extra disk space) instead of copying.

```
~/media/
├── Movies/              ← Radarr library → Jellyfin
├── TV/                  ← Sonarr library → Jellyfin
├── Songs/               ← Lidarr library → Navidrome
├── Books/               ← Readarr library → Calibre-Web / Audiobookshelf
├── Photos/              ← Immich
└── Downloads/           ← Shared download root
    ├── complete/        ← qBittorrent completed downloads
    │   ├── movies/      ← Radarr category in qBittorrent
    │   ├── tv/          ← Sonarr category in qBittorrent
    │   ├── music/       ← Lidarr category in qBittorrent
    │   └── books/       ← Readarr category in qBittorrent
    ├── incomplete/      ← qBittorrent in-progress downloads
    └── aria2/           ← aria2 downloads (manual/HTTP)
```

**Why this structure matters**: All *arr apps mount `~/media` as `/media` inside their containers. Since `/media/Downloads` and `/media/Movies` (etc.) are on the same filesystem, hardlinking works. If you used separate volume mounts (e.g., `/downloads` and `/movies`), the *arr apps would have to **copy** files instead.

## Deployment Order

Install services in this order due to dependencies:

### Phase 1: Download Infrastructure
1. **qBittorrent** — `cd apps/qbittorrent && bash podman-setup.sh`
2. **aria2 + AriaNg** — `cd apps/aria2 && bash podman-setup.sh`

### Phase 2: Indexer Management
3. **Prowlarr** — `cd apps/prowlarr && bash podman-setup.sh`
4. **FlareSolverr** (optional) — `cd apps/flaresolverr && bash podman-setup.sh`

### Phase 3: *Arr Apps
5. **Radarr** — `cd apps/radarr && bash podman-setup.sh`
6. **Sonarr** — `cd apps/sonarr && bash podman-setup.sh`
7. **Lidarr** — `cd apps/lidarr && bash podman-setup.sh`
8. **Readarr (Bookshelf)** — `cd apps/readarr && bash podman-setup.sh`

### Phase 4: User-Facing
9. **Seerr** — `cd apps/seerr && bash podman-setup.sh`
10. **Jellystat** — `cd apps/jellystat && bash podman-setup.sh`

## Configuration Walkthrough

### Step 1: qBittorrent

1. Start the container, check logs for temporary password:
   ```bash
   podman logs qbittorrent
   ```
2. Open `http://qbt.aevion.lan`, login with `admin` and the temp password
3. Change the admin password under Tools → Options → Web UI
4. Set default save path: Options → Downloads → Default Save Path → `/downloads/complete`
5. Create download categories:
   - `movies` → `/downloads/complete/movies`
   - `tv` → `/downloads/complete/tv`
   - `music` → `/downloads/complete/music`
   - `books` → `/downloads/complete/books`

### Step 2: Prowlarr

1. Open `http://prowlarr.aevion.lan`
2. Set authentication (Settings → General → Security)
3. Add indexers (Indexers → Add Indexer)
4. Add download client: Settings → Download Clients → qBittorrent
   - Host: `10.0.2.2`, Port: `8061`
5. (Optional) Add aria2 as a secondary download client: Settings → Download Clients → Aria2
   - Host: `10.0.2.2`
   - **Port: `8062`** (aria2 RPC, NOT 8063 — that's AriaNg's web UI)
   - **XML RPC Path: `/rpc`** (Prowlarr/Sonarr/*arr use **XML-RPC**, and aria2 1.36 serves XML-RPC at `/rpc` — `/jsonrpc` is JSON-RPC only and will return `Parse error`)
   - Secret Token: value of `RPC_SECRET` from `apps/aria2/environments/local.env`
6. Connect *arr apps: Settings → Apps → Add Application
   - For each app, provide the host (`10.0.2.2`), port, and API key

### Step 3: Radarr / Sonarr / Lidarr / Readarr (Bookshelf)

Each *arr app follows the same pattern:

1. Open the web UI
2. Set authentication (Settings → General → Security)
3. Add download client (qBittorrent): Settings → Download Clients
   - Host: `10.0.2.2`, Port: `8061`
   - Category: `movies` / `tv` / `music` / `books` (respectively)
4. Add root folder: Settings → Media Management → Root Folders
   - Radarr: `/media/Movies`
   - Sonarr: `/media/TV`
   - Lidarr: `/media/Songs`
   - Readarr: `/media/Books`
5. Prowlarr will auto-sync indexers (no manual indexer setup needed)

**Readarr (Bookshelf) extra step**: Configure Hardcover metadata source:
- Navigate to `http://readarr.aevion.lan/settings/development` (manual URL entry)
- Set Metadata Provider Source to `https://hardcover.bookinfo.pro`
- Click Save

### Step 3.5: AriaNg (Web UI for aria2)

AriaNg is a static web app — the aria2 RPC connection is made **from your browser**, not from the AriaNg container. The nginx site `ariang.aevion.lan` proxies `/jsonrpc` to aria2's RPC daemon so the browser can reach it on the same origin (no CORS, no port mismatches).

1. Open `http://ariang.aevion.lan` (or `https://`)
2. Go to AriaNg Settings → RPC tab
3. Configure:
   - **Aria2 RPC Address**: `ariang.aevion.lan` (no port — uses default 80/443)
   - **Aria2 RPC Protocol**: `http` (or `https` if using SSL)
   - **Aria2 RPC HTTP Request Method**: `POST`
   - **Aria2 RPC Path**: `/jsonrpc` (NOT `/rpc`)
   - **Aria2 RPC Secret Token**: value of `RPC_SECRET` from `apps/aria2/environments/local.env`
4. Click "Activate" (top of page) — Aria2 Status indicator should turn green
5. Once connected, you can edit settings under Aria2 Settings → RPC Settings (those dropdowns become actionable only when the RPC is reachable)

> **Common pitfall**: Don't put `:8063` after the host — that's AriaNg's static-files port. Don't use `:8062` either — that port is bound to `127.0.0.1` on the server and isn't reachable from your browser. Always go through nginx via `ariang.aevion.lan` (no port).

### Step 4: Seerr

1. Open `http://seerr.aevion.lan`
2. Follow the setup wizard
3. Connect Jellyfin (host: `10.0.2.2`, port: `8041`)
4. Connect Radarr and Sonarr with their API keys
5. Import Jellyfin users

### Step 5: Jellystat

Prerequisites: PostgreSQL database (see `apps/jellystat/README.md`)

1. Update passwords in `apps/jellystat/environments/local.env`
2. Open `http://jellystat.aevion.lan`
3. Connect to Jellyfin with API key

## Port Summary

| Service | Host Port | Container Port | Binding | Network |
|---------|-----------|----------------|---------|---------|
| Prowlarr | 8060 | 8060 | 127.0.0.1 | pasta (host loopback) |
| qBittorrent (Web) | 8061 | 8061 | 127.0.0.1 | default |
| qBittorrent (BT) | 6881 | 6881 | 0.0.0.0 | default |
| aria2 (RPC) | 8062 | 6800 | 127.0.0.1 | default |
| AriaNg (Web) | 8063 | 6880 | 127.0.0.1 | default |
| aria2 (BT) | 6888 | 6888 | 0.0.0.0 | default |
| Radarr | 8064 | 8064 | 127.0.0.1 | pasta (host loopback) |
| Sonarr | 8065 | 8065 | 127.0.0.1 | pasta (host loopback) |
| Lidarr | 8066 | 8066 | 127.0.0.1 | pasta (host loopback) |
| Readarr (Bookshelf) | 8067 | 8067 | 127.0.0.1 | pasta (host loopback) |
| Seerr | 8068 | 5055 | 127.0.0.1 | default |
| Jellystat | 8069 | 3000 | 127.0.0.1 | pasta (host loopback) |
| FlareSolverr | 8191 | 8191 | 127.0.0.1 | default |

**Important**: All *arr apps and Prowlarr use matched internal/external ports (e.g., `8064:8064` not `8064:7878`). This is required because qBittorrent v5.1+ validates that the port in the `Host` header matches the internal WebUI port, rejecting requests with mismatched ports as 401 Unauthorized. The `<APPNAME>__SERVER__PORT` environment variable overrides the default internal port.

## Networking Notes

- All web UIs bind to `127.0.0.1` — accessible only via NGINX reverse proxy
- BitTorrent ports (6881, 6888) bind to `0.0.0.0` for incoming peer connections
- Inter-container communication uses `10.0.2.2` (host loopback via pasta network)
- *arr apps reference each other and download clients via `10.0.2.2:PORT`
- All *arr apps and Prowlarr require `--network 'pasta:--map-host-loopback,10.0.2.2'` to reach host services
- Internal and external ports must match to avoid qBittorrent's Host header port validation (401 errors)

## Resource Estimates (Orange Pi 5 Plus, 8GB RAM)

| Service | RAM (idle) | RAM (active) | Notes |
|---------|-----------|-------------|-------|
| Prowlarr | ~80MB | ~150MB | Spikes during indexer searches |
| qBittorrent | ~50MB | ~200MB | Scales with active torrents |
| aria2 | ~20MB | ~50MB | Very lightweight |
| AriaNg | ~10MB | ~10MB | Static web files |
| Radarr | ~150MB | ~300MB | Database-heavy |
| Sonarr | ~150MB | ~300MB | Database-heavy |
| Lidarr | ~100MB | ~200MB | Lighter than Radarr/Sonarr |
| Readarr | ~100MB | ~200MB | Still in development |
| Seerr | ~150MB | ~250MB | Node.js app |
| Jellystat | ~80MB | ~150MB | Depends on Jellyfin library size |
| FlareSolverr | ~100MB | ~400MB | Runs headless Chromium |
| **Total** | **~1GB** | **~2.2GB** | Leaves ~5-6GB for existing services |

## Troubleshooting

### Downloads not hardlinking (copying instead)

Verify all services mount `~/media` as `/media`:
```bash
podman inspect radarr | grep -A2 '"Mounts"'
```

The download path and library path must be on the same filesystem mount inside the container.

### *arr apps can't connect to download client

From inside any *arr container, the download client is at `10.0.2.2:8061` (not `localhost`). This is because each container has its own network namespace.

### Prowlarr indexers failing

1. Check if the indexer is behind Cloudflare → install FlareSolverr
2. Verify the indexer URL is accessible from the server
3. Check Prowlarr logs: `podman logs prowlarr`

### ARM compatibility issues

Some images may not have ARM64 builds. Check Docker Hub/GHCR for `linux/arm64` platform support. The LinuxServer.io images used here all support ARM64.

## References

- [Servarr Wiki](https://wiki.servarr.com/) — Official docs for all *arr apps
- [TRaSH Guides](https://trash-guides.info/) — Quality profiles, naming conventions, best practices
- [YAMS Configuration](https://yams.media/config/) — Step-by-step config with screenshots
- [Hardlinking Guide](https://trash-guides.info/Hardlinks/Hardlinks-and-Instant-Moves/) — Why directory structure matters
- [Bookshelf (Readarr fork)](https://github.com/pennydreadful/bookshelf) — Actively maintained Readarr replacement
- [rreading-glasses](https://github.com/blampe/rreading-glasses) — Metadata service for Bookshelf (Hardcover/GoodReads)
- [Fork Comparison](https://github.com/blampe/rreading-glasses/blob/main/FORKS.md) — Detailed comparison of Readarr forks
