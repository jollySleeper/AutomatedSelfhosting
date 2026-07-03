# GoatSync

Self-hosted EteSync/Etebase compatible server for syncing contacts and calendars.

## Overview

GoatSync is a Go implementation of the EteSync server with 100% API compatibility. It provides end-to-end encrypted synchronization for contacts and calendars.

- **Source**: https://github.com/jollySleeper/GoatSync
- **Image**: `ghcr.io/jollysleeper/goatsync:latest` (v0.1.2)
- **Port**: 8037 (host) → 3735 (container)
- **Domain**: `goatsync.aevion.lan` / `sync.aevion.lan`
- **Dependencies**: postgres-vector (shared), redis (shared)

## Prerequisites

GoatSync uses shared infrastructure services:

1. **PostgreSQL** (`postgres-vector` on port 5432)
2. **Redis** (`redis` on port 6379)

Ensure both services are running before deploying GoatSync.

## Database Setup

Before first deployment, create the goatsync database in postgres-vector:

```bash
# Generate a secure password
PASSWORD=$(openssl rand -base64 16)
echo "Save this password: $PASSWORD"

# Run the setup script
./scripts/create-database.sh "$PASSWORD"
```

Or manually:

```bash
# Create database (DDL - cannot be transactional)
podman exec -it postgres-vector psql -U postgresql -d postgres -c "CREATE DATABASE goatsync;"

# Create user and grant permissions
podman exec -it postgres-vector psql -U postgresql -d postgres -c "
CREATE USER goatsync WITH PASSWORD 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE goatsync TO goatsync;
ALTER DATABASE goatsync OWNER TO goatsync;
GRANT USAGE ON SCHEMA public TO goatsync;
"
```

## Environment Configuration

1. Copy sample environment file:
   ```bash
   cp environments/sample.env environments/local.env
   ```

2. Update `local.env` with secure values:
   - `DATABASE_URL`: Update the password in the connection string
   - `ENCRYPTION_SECRET`: Generate with `openssl rand -base64 32`

**Note**: The environment variable is `ENCRYPTION_SECRET` (not `SECRET_KEY` as shown in `.env.example`). See [config.go](https://github.com/jollySleeper/GoatSync/blob/main/internal/config/config.go) for actual variable names.

## Deployment

```bash
# Deploy container
./podman-setup.sh

# Verify health
curl http://localhost:8037/health
# Expected: {"status":"ok"}

# Test API
curl http://localhost:8037/api/v1/authentication/is_etebase/
# Expected: 200 OK
```

## Service Management

```bash
# Start service
systemctl --user start goatsync.service

# Stop service
systemctl --user stop goatsync.service

# Restart service
systemctl --user restart goatsync.service

# View logs
podman logs goatsync
journalctl --user -u goatsync.service --no-pager

# Check status
systemctl --user status goatsync.service
```

## Client Configuration

### EteSync Mobile/Web Apps

1. Open EteSync app (iOS, Android, or https://pim.etesync.com)
2. Click "Change Server" or "Custom Server"
3. Enter: `https://goatsync.aevion.lan` (or `http://goatsync.aevion.lan:1080`)
4. Sign up or log in

### CalDAV/CardDAV (Optional)

For Thunderbird, Apple Calendar, or other CalDAV/CardDAV clients, you'll need to deploy `etesync-dav` bridge separately. See the [GoatSync DEPLOYMENT.md](https://github.com/jollySleeper/GoatSync/blob/main/docs/DEPLOYMENT.md) for details.

## Backup

### Database Backup

```bash
podman exec -it postgres-vector pg_dump -U goatsync goatsync > goatsync_backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat goatsync_backup_YYYYMMDD.sql | podman exec -i postgres-vector psql -U goatsync goatsync
```

### Volume Backup

Chunk data is stored in `volumes/chunks/`. Back up this directory for complete data preservation.

## Troubleshooting

### Container won't start

1. Check if postgres-vector and redis are running:
   ```bash
   podman ps | grep -E "postgres-vector|redis"
   ```

2. Verify database exists:
   ```bash
   podman exec -it postgres-vector psql -U postgresql -d postgres -c "\l" | grep goatsync
   ```

3. Check container logs:
   ```bash
   podman logs goatsync
   ```

### "ENCRYPTION_SECRET not set" warning

Ensure `ENCRYPTION_SECRET` (not `SECRET_KEY`) is set in `environments/local.env`.

### Connection refused to database

Ensure the container uses `pasta:--map-host-loopback,10.0.2.2` network mode to access host services at `10.0.2.2`. See [`docs/DNS_ARCHITECTURE.md`](../../docs/DNS_ARCHITECTURE.md) §2.1.3 for why `10.0.2.2` is the convention.

### Authentication issues

Verify `ENCRYPTION_SECRET` is at least 32 characters and hasn't changed between deployments.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   EteSync App   │────▶│     NGINX       │
│  (Mobile/Web)   │     │  (Reverse Proxy)│
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │    GoatSync     │
                        │   (Port 8037)   │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
           ┌─────────────────┐       ┌─────────────────┐
           │  postgres-vector│       │      redis      │
           │   (Port 5432)   │       │   (Port 6379)   │
           └─────────────────┘       └─────────────────┘
```

## References

- [GoatSync GitHub](https://github.com/jollySleeper/GoatSync)
- [GoatSync Deployment Guide](https://github.com/jollySleeper/GoatSync/blob/main/docs/DEPLOYMENT.md)
- [GoatSync Config Source](https://github.com/jollySleeper/GoatSync/blob/main/internal/config/config.go)
- [EteSync Documentation](https://www.etesync.com/user-guide/)
