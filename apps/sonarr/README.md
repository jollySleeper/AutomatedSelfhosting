# Sonarr - TV Show Management & Automation

Sonarr is a PVR for Usenet and BitTorrent users. It monitors RSS feeds for new episodes of your TV shows, grabs them, sorts them, and renames them automatically.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/linuxserver/sonarr:latest` |
| **Internal Port** | 8989 |
| **Host Port** | 8065 |
| **Subdomain** | `sonarr.aevion.lan` |
| **Container Name** | `sonarr` |

## Access

- HTTP: `http://sonarr.aevion.lan`

## Initial Setup

1. Open the Sonarr web UI
2. Set authentication method under Settings → General → Security
3. Add download client: Settings → Download Clients → Add → qBittorrent
   - Host: `10.0.2.2`
   - Port: `8061`
   - Category: `tv`
4. Add root folder: Settings → Media Management → Root Folders → `/media/TV`
5. Prowlarr will auto-sync indexers

### Anime Support

Sonarr has built-in anime support. Under Settings → Profiles, you can create anime-specific quality profiles. Use the "Anime" category in Prowlarr indexers for better anime tracking.

### Hardlinking Path Layout

```
/media/                    (container) = ~/media/ (host)
├── Downloads/
│   └── complete/
│       └── tv/            ← qBittorrent downloads here
└── TV/                    ← Sonarr moves/hardlinks here
```

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | Sonarr configuration and database |
| `/media` | `~/media` | Shared media root (downloads + libraries) |

## Dependencies

- Download client: qBittorrent (port 8061) or aria2
- Indexer manager: Prowlarr (auto-syncs indexers)
- Media server: Jellyfin (reads from `~/media/TV`)

## Documentation

- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [TRaSH Guides - Sonarr](https://trash-guides.info/Sonarr/)
