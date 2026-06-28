# Jellystat - Jellyfin Usage Analytics

Jellystat is a monitoring and statistics dashboard for Jellyfin. It tracks user activity, playback statistics, and content popularity.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `docker.io/cyfershepard/jellystat:latest` |
| **Internal Port** | 3000 |
| **Host Port** | 8069 |
| **Subdomain** | `jellystat.aevion.lan` |
| **Container Name** | `jellystat` |

## Access

- HTTP: `http://jellystat.aevion.lan`

## Prerequisites

Jellystat requires a PostgreSQL database. If you don't already have a Postgres instance running, you'll need to set one up, or use the existing `postgres-vector` service if available.

### Database Setup

Create a database and user for Jellystat in your PostgreSQL instance:

```sql
CREATE USER jellystat WITH PASSWORD 'changeme_jellystat_db_password';
CREATE DATABASE jellystat OWNER jellystat;
```

## Initial Setup

1. Open Jellystat web UI
2. Login with credentials from `environments/local.env` (`JS_USER` / `JS_PASSWORD`)
3. Add your Jellyfin server:
   - URL: `http://10.0.2.2:8041`
   - API Key: from Jellyfin Dashboard → API Keys
4. Jellystat will start collecting playback data

**Important**: Change all passwords and secrets in `environments/local.env` before deploying!

## Features

- User activity tracking (who watches what, when)
- Playback statistics and history
- Content popularity rankings
- Library statistics
- Scheduled data synchronization with Jellyfin

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/app/backend/backup-data` | `volumes/backup` | Jellystat database backups |

## Dependencies

- Jellyfin (port 8041) — media server to monitor
- PostgreSQL — database for storing statistics

## Documentation

- [Jellystat GitHub](https://github.com/CyferShepard/Jellystat)
