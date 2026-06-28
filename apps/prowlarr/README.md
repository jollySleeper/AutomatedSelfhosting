# Prowlarr - Indexer Manager

Prowlarr is an indexer manager/proxy that integrates with Radarr, Sonarr, Lidarr, and Readarr. It manages all your indexers in one place and syncs them to your *arr apps automatically.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/linuxserver/prowlarr:latest` |
| **Internal Port** | 9696 |
| **Host Port** | 8060 |
| **Subdomain** | `prowlarr.aevion.lan` |
| **Container Name** | `prowlarr` |

## Access

- HTTP: `http://prowlarr.aevion.lan`

## Configuration

After first launch:
1. Navigate to the Prowlarr web UI
2. Add your indexers (torrent trackers, usenet providers)
3. Add applications (Radarr, Sonarr, Lidarr, Readarr) under Settings → Apps
4. Prowlarr will automatically sync indexers to all connected *arr apps

### Integration with FlareSolverr

If indexers are behind Cloudflare protection, add FlareSolverr as a proxy under Settings → Indexers → Add Indexer Proxy → FlareSolverr:
- Host: `http://10.0.2.2:8191` (or `http://localhost:8191` from host)
- Tag: `flaresolverr`

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | Prowlarr configuration and database |

## Dependencies

- None (standalone service, but connects to other *arr apps)
- Optional: FlareSolverr for Cloudflare bypass

## Documentation

- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [TRaSH Guides - Prowlarr](https://trash-guides.info/Prowlarr/)
