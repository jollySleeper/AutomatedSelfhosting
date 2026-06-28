# Radarr - Movie Management & Automation

Radarr is a movie collection manager for Usenet and BitTorrent users. It monitors RSS feeds for new movies and interfaces with download clients to grab, sort, and rename them.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/linuxserver/radarr:latest` |
| **Internal Port** | 7878 |
| **Host Port** | 8064 |
| **Subdomain** | `radarr.aevion.lan` |
| **Container Name** | `radarr` |

## Access

- HTTP: `http://radarr.aevion.lan`

## Initial Setup

1. Open the Radarr web UI
2. Set authentication method under Settings → General → Security
3. Add download client: Settings → Download Clients → Add → qBittorrent
   - Host: `10.0.2.2` (or `localhost` from host perspective)
   - Port: `8061`
   - Category: `movies`
4. Add root folder: Settings → Media Management → Root Folders → `/media/Movies`
5. Prowlarr will auto-sync indexers (no manual indexer setup needed)

### Hardlinking Path Layout

The `/media` volume maps to `~/media` on the host. Both the download path (`/media/Downloads/complete/movies`) and the library path (`/media/Movies`) are under the same mount — enabling hardlinks.

```
/media/                    (container) = ~/media/ (host)
├── Downloads/
│   └── complete/
│       └── movies/        ← qBittorrent downloads here
└── Movies/                ← Radarr moves/hardlinks here
```

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | Radarr configuration and database |
| `/media` | `~/media` | Shared media root (downloads + libraries) |

## Dependencies

- Download client: qBittorrent (port 8061) or aria2
- Indexer manager: Prowlarr (auto-syncs indexers)
- Media server: Jellyfin (reads from `~/media/Movies`)

## Documentation

- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [TRaSH Guides - Radarr](https://trash-guides.info/Radarr/)
