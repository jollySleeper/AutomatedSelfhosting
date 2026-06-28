# Lidarr - Music Management & Automation

Lidarr is a music collection manager for Usenet and BitTorrent users. It monitors artists and albums, and automatically downloads new releases.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/linuxserver/lidarr:latest` |
| **Internal Port** | 8686 |
| **Host Port** | 8066 |
| **Subdomain** | `lidarr.aevion.lan` |
| **Container Name** | `lidarr` |

## Access

- HTTP: `http://lidarr.aevion.lan`

## Initial Setup

1. Open the Lidarr web UI
2. Set authentication method under Settings → General → Security
3. Add download client: Settings → Download Clients → Add → qBittorrent
   - Host: `10.0.2.2`
   - Port: `8061`
   - Category: `music`
4. Add root folder: Settings → Media Management → Root Folders → `/media/Songs`
5. Prowlarr will auto-sync indexers

### Integration with Navidrome

Lidarr downloads and organizes music into `~/media/Songs`, which is the same directory Navidrome reads from. New music appears in Navidrome automatically after its periodic scan (or manual rescan).

### Hardlinking Path Layout

```
/media/                    (container) = ~/media/ (host)
├── Downloads/
│   └── complete/
│       └── music/         ← qBittorrent downloads here
└── Songs/                 ← Lidarr moves/hardlinks here (Navidrome reads this)
```

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | Lidarr configuration and database |
| `/media` | `~/media` | Shared media root (downloads + libraries) |

## Dependencies

- Download client: qBittorrent (port 8061)
- Indexer manager: Prowlarr (auto-syncs indexers)
- Music server: Navidrome (reads from `~/media/Songs`)

## Documentation

- [Lidarr Wiki](https://wiki.servarr.com/lidarr)
