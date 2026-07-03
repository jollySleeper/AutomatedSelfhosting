# wger Workout Manager - Complete Setup Guide

This guide provides detailed instructions for setting up wger (a self-hosted fitness/workout/nutrition tracker) on your system using Podman with a shared PostgreSQL and Redis instance.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Post-Installation](#post-installation)
- [Nginx Configuration](#nginx-configuration)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Prerequisites

### Required Services
1. **Podman** - Rootless container runtime
2. **PostgreSQL Database** - Shared `postgres-vector` container running on `127.0.0.1:5432`
3. **Redis Cache** - Shared `redis` container running on `127.0.0.1:6379`
4. **Nginx** - Reverse proxy for serving the application

### System Requirements
- Podman installed and configured for rootless operation
- At least 2GB RAM available
- 5GB disk space (more if syncing all ingredients)
- Network access to wger.de for syncing exercises/ingredients

---

## Architecture Overview

This deployment adapts the official wger Docker setup for Podman with shared services. Key differences from the official setup:
- **Shared Database/Redis**: Uses `postgres-vector` and `redis` instead of dedicated containers for efficiency
- **Dedicated Static Server**: `wger-static` nginx container serves static files to avoid mounting volumes on shared nginx
- **Podman Networking**: Uses `10.0.2.2` (host loopback) instead of Docker DNS resolution

### Container Stack
```
┌─────────────────────────────────────────┐
│           nginx (Port 1080)             │
│  - Proxies static files to wger-static │
│  - Proxies dynamic requests to wger-web│
└─────────────────────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───▼────┐  ┌──────▼──────┐  ┌────▼────────┐
│ wger-  │  │  wger-      │  │  wger-      │
│  web   │  │ celery-     │  │ celery-     │
│ :8051  │  │  worker     │  │  beat       │
└────┬───┘  └──────┬──────┘  └────┬────────┘
     │             │              │
     └─────────┬───┴──────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼──────┐ ┌─▼─────────┐
│ postgres │ │  redis    │
│  -vector │ │  (shared) │
│ (shared) │ │           │
└──────────┘ └───────────┘
```

### Static File Architecture
Static files are served through a dedicated `wger-static` nginx container to maintain isolation from the shared nginx proxy:

```
User Request → Main nginx:1080 → Static/Media → wger-static:8052 (nginx:alpine)
                    │
                    └─→ Dynamic → wger-web:8051 (Django)
```

**Benefits:**
- No volume mounts required on shared nginx
- Optimal static file performance with nginx
- Better security isolation
- Minimal resource overhead (~8MB container)

### Component Details

| Component | Purpose | Port | Network Mode |
|-----------|---------|------|--------------|
| **wger-web** | Django application (Gunicorn) | 127.0.0.1:8051 | `pasta:--map-host-loopback,10.0.2.2` |
| **wger-static** | Dedicated nginx for static/media files | 127.0.0.1:8052 | `pasta:--map-host-loopback,10.0.2.2` |
| **wger-celery-worker** | Background task processor | - | `pasta:--map-host-loopback,10.0.2.2` |
| **wger-celery-beat** | Scheduled task scheduler | - | `pasta:--map-host-loopback,10.0.2.2` |
| **postgres-vector** | Shared PostgreSQL 16 database | 127.0.0.1:5432 | - |
| **redis** | Shared cache & Celery broker | 127.0.0.1:6379 | - |

### Volume Structure
```
apps/wger/volumes/
├── wger-web/
│   ├── static/          # Collected static files (CSS, JS, fonts)
│   └── media/           # User-uploaded content
└── wger-celery-beat/
    └── beat/            # Celery beat schedule data
```

---

## Initial Setup

### Step 1: Database Preparation

Create the wger database and user in your shared PostgreSQL instance:

```bash
# Connect to your postgres-vector container
podman exec postgres-vector psql -U postgresql -d postgres

# Create the wger user and database
CREATE USER wger WITH PASSWORD 'changeme';
CREATE DATABASE wger OWNER wger;
GRANT ALL PRIVILEGES ON DATABASE wger TO wger;
\q
```

### Step 2: Environment Configuration

The main configuration file is `environments/wger-web.env`. Key settings to review:

#### Essential Settings
```bash
# Django secret key - CHANGE THIS for production!
SECRET_KEY=your-unique-secret-key-here

# Domain configuration
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,wger.aevion.lan,wger-web.aevion.lan
CSRF_TRUSTED_ORIGINS=http://wger.aevion.lan,http://wger-web.aevion.lan
SITE_URL=http://wger-web.aevion.lan

# Database connection (using shared postgres-vector)
DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_DATABASE=wger
DJANGO_DB_USER=wger
DJANGO_DB_PASSWORD=changeme
DJANGO_DB_HOST=10.0.2.2          # Host IP from container perspective
DJANGO_DB_PORT=5432

# Redis connection (using shared redis)
CELERY_BROKER=redis://10.0.2.2:6379/2
CELERY_BACKEND=redis://10.0.2.2:6379/2
DJANGO_CACHE_LOCATION=redis://10.0.2.2:6379/1

# Static files
SERVE_STATIC_FILES=True           # Let Django serve static files initially
```

#### Why `10.0.2.2`?
When using `pasta:--map-host-loopback,10.0.2.2`, the container can access the host's `127.0.0.1` services via `10.0.2.2`. (The `10.0.2.2` address is a convention we inherited from slirp4netns — see [`docs/DNS_ARCHITECTURE.md`](../../docs/DNS_ARCHITECTURE.md) §2.1.3.)

---

## Configuration

### Update Domain Names

Replace `aevion.lan` with your actual domain in these files:

1. **environments/wger-web.env**
   - `DJANGO_ALLOWED_HOSTS`
   - `CSRF_TRUSTED_ORIGINS`
   - `SITE_URL`

2. **scripts/first-run.sh**
   - Update the access URL message

### Security Configuration

**IMPORTANT**: Before going to production:

1. Generate a new SECRET_KEY:
   ```bash
   # Use https://djecrety.ir/ or generate one:
   python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

2. Set `DJANGO_DEBUG=False` in production

3. Use strong passwords for the database

4. Consider enabling HTTPS with proper SSL certificates

---

## Deployment

### Step 1: Run the Setup Script

```bash
cd /path/to/selfhost/apps/wger
./podman-setup.sh up-con
```

This script will:
- Pull the `docker.io/wger/server:latest` image
- Create required volume directories
- Start three containers (wger-web, wger-celery-worker, wger-celery-beat)
- Generate systemd quadlet files for auto-start
- Install and enable the systemd services

### Step 2: Wait for Initialization

Give the containers 10-15 seconds to fully start up. Monitor with:

```bash
podman ps --filter name=wger
podman logs -f wger-web
```

### Step 3: Run First-Time Setup

```bash
./scripts/first-run.sh
```

This script performs:
1. **Database migrations** - Creates all necessary tables
2. **Load fixtures** - Installs base data (languages, muscles, equipment, etc.)
3. **Collect static files** - Gathers all CSS/JS/images
4. **Create admin user** - Username: `admin`, Password: `adminadmin`

**Expected output:**
```
Running wger first-time setup...
Waiting for database to be ready...
Running database migrations...
Loading application fixtures...
Installed 30 object(s) from 1 fixture(s)  # Languages
Installed 552 object(s) from 1 fixture(s)  # Exercises
...
Creating admin user...
Admin user created

wger setup complete!
```

---

## Post-Installation

### Access the Application

Visit: `http://wger-web.aevion.lan` (or your configured domain)

**Default credentials:**
- Username: `admin`
- Password: `adminadmin`

**⚠️ Change the admin password immediately after first login!**

### Verify Static Files Setup

Test that static files are being served correctly:

```bash
# Test static file serving through nginx
curl -I http://wger-web.aevion.lan/static/yarn/components-font-awesome/css/all.css
# Should return: 200 OK with proper headers

# Test media endpoint
curl -I http://wger-web.aevion.lan/media/
# Should return: 200 OK

# Test wger-static container directly
curl http://localhost:8052/health
# Should return: "healthy"
```

If static files return 404, see the [troubleshooting section](#issue-static-files-return-404).

### Load Exercise and Nutrition Data (Optional but Recommended)

wger comes with base data, but you can sync the latest exercises and nutrition info from wger.de:

```bash
# Sync exercises from wger.de (recommended)
podman exec wger-web python3 manage.py sync-exercises

# Download exercise images (~500MB)
podman exec wger-web python3 manage.py download-exercise-images

# Download exercise videos (~2GB)
podman exec wger-web python3 manage.py download-exercise-videos

# Sync ingredients database (~1GB, takes several hours)
podman exec wger-web python3 manage.py sync-ingredients
```

**Note:** These syncs can also run automatically via Celery based on the environment settings:
- `SYNC_EXERCISES_CELERY=True` - Syncs once a week
- `SYNC_EXERCISE_IMAGES_CELERY=True`
- `SYNC_EXERCISE_VIDEOS_CELERY=True`
- `SYNC_INGREDIENTS_CELERY=True`

---

## Nginx Configuration

For optimal performance, nginx should serve static and media files directly.

### Configuration File: `apps/nginx/configs/sites/wger-web.conf`

```nginx
server {
    listen 1080;
    server_name wger.aevion.lan wger-web.aevion.lan;

    set $UPSTREAM_IP 10.0.2.2;
    set $UPSTREAM_PORT 8051;

    client_max_body_size 20M;

    # Serve static files directly from nginx (more efficient)
    location /static/ {
        alias /home/legion/selfhost/apps/wger/volumes/wger-web/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Serve media files directly from nginx
    location /media/ {
        alias /home/legion/selfhost/apps/wger/volumes/wger-web/media/;
        expires 7d;
        access_log off;
    }

    include /etc/nginx/snippets/proxy-defaults.conf;

    # Proxy all other requests to Django
    location / {
        proxy_pass http://$UPSTREAM_IP:$UPSTREAM_PORT;
    }
}
```

### Apply nginx Configuration

1. Copy the configuration to nginx
2. Test nginx configuration: `nginx -t`
3. Reload nginx: `systemctl reload nginx` or `podman restart nginx`

### Update wger Environment (Optional)

Once nginx is serving static files, you can optionally disable Django's static file serving:

```bash
# In environments/wger-web.env
SERVE_STATIC_FILES=False
```

Then restart: `podman restart wger-web`

---

## Troubleshooting

### Issue: 500 Internal Server Error on Homepage

**Cause:** Missing fixture data (languages, gym config)

**Solution:**
```bash
cd apps/wger
./scripts/first-run.sh
```

### Issue: Static Files Return 404

**Symptoms:** Page loads but no CSS/images

**Solutions:**

1. **Check if files were collected:**
   ```bash
   podman exec wger-web ls -la /home/wger/static/
   ```

2. **Re-collect static files:**
   ```bash
   podman exec wger-web python3 manage.py collectstatic --noinput --clear
   ```

3. **Verify nginx configuration:**
   - Ensure the alias path matches your volume location
   - Check file permissions: nginx user must be able to read the files
   - Test nginx config: `nginx -t`

4. **Check volume mount:**
   ```bash
   podman inspect wger-web | grep -A 5 Mounts
   ```

### Issue: Can't Create Users / Foreign Key Violations

**Cause:** Missing language or gym configuration data

**Solution:**
```bash
podman exec wger-web wger load-fixtures
```

### Issue: Celery Tasks Not Running

**Check celery worker status:**
```bash
podman logs wger-celery-worker
podman logs wger-celery-beat
```

**Verify Redis connection:**
```bash
podman exec wger-web python3 manage.py shell -c "from django.core.cache import cache; print(cache.get('test') or 'Redis OK')"
```

### Issue: Static Files Return 404

**Symptoms:** Page loads but no CSS/images, broken styling

**Solutions:**

1. **Check if wger-static container is running:**
   ```bash
   podman ps | grep wger-static
   ```

2. **Test static file server directly:**
   ```bash
   curl -I http://localhost:8052/static/yarn/components-font-awesome/css/all.css
   # Should return: 200 OK
   ```

3. **Check if static files exist:**
   ```bash
   ls -la ~/selfhost/apps/wger/volumes/wger-web/static/
   ```

4. **Re-collect static files:**
   ```bash
   podman exec wger-web python3 manage.py collectstatic --noinput
   ```

5. **Check wger-static logs:**
   ```bash
   podman logs wger-static | tail -20
   ```

6. **Test through main nginx:**
   ```bash
   curl -I http://wger-web.aevion.lan/static/yarn/components-font-awesome/css/all.css
   ```

### Issue: Database Connection Failed

**Check:**
1. postgres-vector container is running
2. wger database exists
3. Connection details in `wger-web.env` are correct
4. Container can reach `10.0.2.2:5432`

```bash
podman exec wger-web python3 manage.py dbshell
```

---

## Maintenance

### Backup

#### Database Backup
```bash
podman exec postgres-vector pg_dump -U wger wger > wger_backup_$(date +%Y%m%d).sql
```

#### Restore Database
```bash
podman exec -i postgres-vector psql -U wger wger < wger_backup_20251010.sql
```

#### Media Files Backup
```bash
tar -czf wger_media_$(date +%Y%m%d).tar.gz apps/wger/volumes/wger-web/media/
```

### Updating

Containers are configured with `AutoUpdate=registry` for automatic updates.

**Manual update:**
```bash
cd apps/wger
./podman-setup.sh update-con
```

Or manually:
```bash
podman pull docker.io/wger/server:latest
podman restart wger-web wger-celery-worker wger-celery-beat
```

### Monitoring

**Check container status:**
```bash
podman ps --filter name=wger --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**View logs:**
```bash
podman logs -f wger-web
podman logs wger-celery-worker --tail 50
podman logs wger-celery-beat --tail 50
```

**Check systemd services:**
```bash
systemctl --user status wger-web.service
systemctl --user status wger-celery-worker.service
systemctl --user status wger-celery-beat.service
```

### Regular Maintenance Tasks

1. **Update exercises monthly:**
   ```bash
   podman exec wger-web python3 manage.py sync-exercises
   podman exec wger-web python3 manage.py download-exercise-images
   ```

2. **Clear old sessions:**
   ```bash
   podman exec wger-web python3 manage.py clearsessions
   ```

3. **Check database health:**
   ```bash
   podman exec wger-web python3 manage.py exercises-health-check
   ```

---

## Useful Commands

### Django Management

```bash
# Access Django shell
podman exec -it wger-web python3 manage.py shell

# Create a new superuser
podman exec -it wger-web python3 manage.py createsuperuser

# Run database migrations
podman exec wger-web python3 manage.py migrate

# Check for pending migrations
podman exec wger-web python3 manage.py showmigrations

# Clear cache
podman exec wger-web python3 manage.py shell -c "from django.core.cache import cache; cache.clear(); print('Cache cleared')"
```

### Container Management

```bash
# Stop all wger containers
podman stop wger-web wger-celery-worker wger-celery-beat

# Start all wger containers
podman start wger-web wger-celery-worker wger-celery-beat

# Restart containers
podman restart wger-web wger-celery-worker wger-celery-beat

# Remove containers (data persists in volumes)
podman rm -f wger-web wger-celery-worker wger-celery-beat

# View container resource usage
podman stats wger-web wger-celery-worker wger-celery-beat
```

---

## Resources

- **Official Documentation:** https://wger.readthedocs.io/
- **GitHub Repository:** https://github.com/wger-project/wger
- **Docker Hub:** https://hub.docker.com/r/wger/server
- **Community Forum:** https://github.com/wger-project/wger/discussions

---

## Support

For issues specific to this deployment:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review container logs
3. Verify all prerequisites are met
4. Check the official wger documentation

For wger-specific questions:
- File issues on GitHub
- Join community discussions
- Check the documentation

---

**Last Updated:** October 2025
**wger Version:** Latest (auto-updating)
**Deployment Method:** Podman with systemd quadlets
