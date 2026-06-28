# Seerr - Media Request & Discovery Manager

Seerr (successor to Jellyseerr/Overseerr) is a media request and discovery platform that integrates with Jellyfin, Radarr, and Sonarr. It provides a Netflix-like interface for users to discover and request content.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/seerr-team/seerr:latest` |
| **Internal Port** | 5055 |
| **Host Port** | 8068 |
| **Subdomain** | `seerr.aevion.lan` |
| **Container Name** | `seerr` |

## Access

- HTTP: `http://seerr.aevion.lan`

## Initial Setup

1. Open Seerr web UI — you'll see the setup wizard
2. Select **Jellyfin** as your media server
3. Enter Jellyfin connection details:
   - Hostname: `10.0.2.2`
   - Port: `8041`
   - Sign in with your Jellyfin admin account
4. Sync Jellyfin libraries (Movies, TV Shows)
5. Add Radarr:
   - Hostname: `10.0.2.2`
   - Port: `8064`
   - API Key: from Radarr Settings → General
   - Root folder: `/media/Movies`
6. Add Sonarr:
   - Hostname: `10.0.2.2`
   - Port: `8065`
   - API Key: from Sonarr Settings → General
   - Root folder: `/media/TV`

### User Management

- Seerr imports users from Jellyfin automatically
- You can set per-user permissions and request limits
- Users can browse your library and request new content through a clean interface

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/app/config` | `volumes/config` | Seerr configuration and database |

## Dependencies

- Jellyfin (port 8041) — media server integration
- Radarr (port 8064) — movie request fulfillment
- Sonarr (port 8065) — TV show request fulfillment

## Documentation

- [Seerr Documentation](https://docs.seerr.dev/getting-started/)
- [Seerr GitHub](https://github.com/seerr-team/seerr)
