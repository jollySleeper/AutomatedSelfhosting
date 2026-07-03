# wger - Self-hosted Fitness/Workout/Nutrition/Weight Tracker

[wger](https://github.com/wger-project/wger) is a free, open source, self-hosted web application that manages and tracks your exercises, workouts, nutrition, and weight.

## Overview

wger provides a comprehensive fitness tracking solution with workout planning, exercise database, nutrition tracking, and progress monitoring. This multi-container deployment uses shared PostgreSQL and Redis services for optimal resource utilization.

## Features

- **Workout Management**: Create custom workouts and exercise routines
- **Exercise Database**: Extensive database of exercises with images and videos
- **Nutrition Tracking**: Track meals, calories, and macronutrients
- **Weight Tracking**: Monitor weight progress with charts and statistics
- **Progress Analytics**: Visualize fitness journey with detailed charts
- **Mobile Support**: Responsive design works on all devices
- **Data Export**: Export data in various formats (CSV, JSON, PDF)
- **Multi-User**: Support for multiple users with individual accounts
- **Offline Support**: Progressive Web App capabilities

## Prerequisites

- **System Requirements**: Minimum 1GB RAM, modern web browser
- **Dependencies**: PostgreSQL (postgres-vector), Redis (shared services)
- **Network**: HTTP access (ports 8051-8052 internally)
- **Storage**: Variable based on user data + ~500MB for exercise images/videos

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/wger
./podman-setup.sh up-con
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/wger
   ```

2. **Configure Environment**
   ```bash
   # Update environment files
   # Change DJANGO_SECRET_KEY to a secure random string in wger-web.env
   ```

3. **Setup Database**
   ```bash
   # Create wger database in shared postgres-vector
   podman exec postgres-vector psql -U postgresql -d postgres -c "CREATE USER wger WITH PASSWORD 'changeme';"
   podman exec postgres-vector psql -U postgresql -d postgres -c "CREATE DATABASE wger OWNER wger;"
   ```

4. **Deploy Container**
   ```bash
   ./podman-setup.sh up-con
   ```

5. **Initialize Application**
   ```bash
   ./scripts/first-run.sh
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: User namespace mapping for file access
- **Security Notes**: Multi-container setup with shared service dependencies

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/wger-web.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| DJANGO_SECRET_KEY | Django encryption key | - | Yes |
| DATABASE_URL | PostgreSQL connection string | - | Yes |
| REDIS_URL | Redis connection string | - | Yes |
| DJANGO_DEBUG | Debug mode | False | No |
| SYNC_*_CELERY | Auto-sync settings | False | No |

## Configuration

### Container Details

- **Images**: `docker.io/wger/server:latest`, `docker.io/nginx:alpine`
- **Ports**:
  - Internal 8000 → External 8051 (web app)
  - Internal 80 → External 8052 (static files)
- **Volumes**:
  - `wger-web/static:/home/wger/static` - Static files
  - `wger-web/media:/home/wger/media` - User media
  - `wger-celery-beat/beat:/home/wger/beat` - Celery schedules
- **Networks**: `pasta:--map-host-loopback,10.0.2.2` for shared services (Postgres, Redis on host loopback)

### Service Configuration

wger uses a multi-container architecture:
- **wger-web**: Django application with Gunicorn
- **wger-static**: Dedicated nginx for static/media files
- **wger-celery-worker**: Background task processing
- **wger-celery-beat**: Scheduled task management
- **Shared Services**: Uses postgres-vector (PostgreSQL) and redis

### Architecture

This deployment uses **shared services** for efficiency and follows the official wger architecture with Podman adaptations:

#### Container Stack
```
┌─────────────────────────────────────────┐
│           nginx (Port 1080)             │
│  - Serves static files from wger-static │
│  - Proxies to wger-web                  │
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

#### Key Components
- **wger-web**: Django application (Gunicorn) with shared postgres-vector DB
- **wger-static**: Dedicated nginx for static/media files (nginx:alpine, ~8MB)
- **wger-celery-worker/beat**: Background task processing with shared redis
- **Shared Services**: Uses `postgres-vector` (PostgreSQL) and `redis` instead of dedicated containers

#### Static File Architecture
Static files are served through a dedicated nginx container (`wger-static`) to avoid mounting volumes on the shared nginx proxy. This provides better isolation while maintaining optimal performance.

#### Network Architecture
Containers use `pasta:--map-host-loopback,10.0.2.2` to access shared services on the host via `10.0.2.2`.

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8051 (web app), http://localhost:8052 (static)
- **Domain Access**: https://wger.aevion.lan or https://wger-web.aevion.lan
- **API Endpoints**: REST API available for integrations

### Getting Started

1. **Initial Setup**
   - Access the web interface
   - Default credentials: admin/adminadmin
   - **Change password immediately**

2. **Load Exercise Data**
   ```bash
   # Manual data sync (disabled by default for resource optimization)
   podman exec wger-web python3 manage.py sync-exercises
   podman exec wger-web python3 manage.py download-exercise-images
   ```

3. **Create Workouts**
   - Add exercises from the database
   - Create custom workout routines
   - Track progress and statistics

### Command Line Operations

```bash
# Service management
podman ps | grep wger
podman logs wger-web

# Django management
podman exec wger-web python manage.py collectstatic --noinput
podman exec wger-web python manage.py createsuperuser

# Data management
podman exec wger-web python manage.py sync-exercises
podman exec wger-web python manage.py dumpdata > backup.json
```

## Integration

### With Other Services

- **PostgreSQL**: Uses shared postgres-vector database
- **Redis**: Uses shared redis for caching and Celery broker
- **NGINX Proxy**: Reverse proxy for secure domain access

### API Integration

wger provides extensive REST APIs for:
- **Workout Management**: CRUD operations on workouts and exercises
- **Nutrition Tracking**: Meal and ingredient management
- **Progress Tracking**: Weight and measurement data
- **User Management**: Account and authentication

## Backup & Recovery

### Important Data to Backup

- **Database**: PostgreSQL data in postgres-vector (wger database)
- **Media Files**: `volumes/wger-web/media/` - User-uploaded images
- **Static Files**: Can be regenerated, but backup for consistency

### Backup Commands

```bash
# Database backup
podman exec postgres-vector pg_dump -U wger wger > wger-db-backup.sql

# Media files backup
tar -czf wger-media-backup-$(date +%Y%m%d).tar.gz volumes/wger-web/media

# Full application data
podman exec wger-web python manage.py dumpdata > wger-data-$(date +%Y%m%d).json
```

### Restore Commands

```bash
# Database restore
podman exec -i postgres-vector psql -U wger wger < wger-db-backup.sql

# Media files restore
tar -xzf wger-media-backup-YYYYMMDD.tar.gz

# Application data restore
podman exec -i wger-web python manage.py loaddata < wger-data-YYYYMMDD.json
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep wger

# Web interface check
curl -I http://localhost:8051

# Database connectivity
podman exec wger-web python manage.py dbshell --command "SELECT 1;"
```

### Logs

```bash
# Web application logs
podman logs wger-web

# Worker logs
podman logs wger-celery-worker

# Beat scheduler logs
podman logs wger-celery-beat
```

### Common Issues

**Static Files Not Loading**
- Symptoms: CSS/JS/images don't load properly
- Cause: Static files not collected or nginx misconfiguration
- Solution: Run `python manage.py collectstatic --noinput`

**Database Connection Issues**
- Symptoms: Application fails to start or shows database errors
- Cause: PostgreSQL not running or connection string incorrect
- Solution: Check postgres-vector status and connection settings

**Permission Issues (Rootless)**
- Symptoms: File access errors in logs
- Cause: User namespace mapping conflicts
- Solution: Check volume ownership and permissions

**Celery Tasks Not Running**
- Symptoms: Background tasks not executing
- Cause: Redis not available or Celery configuration issues
- Solution: Check redis connectivity and Celery logs

### Performance Tuning

- **Data Synchronization**: Disabled by default to save resources
- **Static File Caching**: nginx handles static file serving
- **Database Optimization**: Regular PostgreSQL maintenance
- **Redis Caching**: Shared redis instance for optimal performance

## Security

- **Container Security**: Rootless containers with non-root users
- **Network Security**: Reverse proxy protection
- **Data Protection**: Django security features and user authentication
- **Database Security**: PostgreSQL user isolation and access controls

## System Resources

- **Memory**: 512MB - 2GB depending on usage and data sync
- **CPU**: Low baseline, higher during data synchronization
- **Storage**: ~100MB base + variable for user data and exercise media
- **Network**: Variable during data synchronization from wger.de

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/wger/server:latest
podman pull docker.io/nginx:alpine
podman restart wger-web wger-static wger-celery-worker wger-celery-beat
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Django cleanup
podman exec wger-web python manage.py clearsessions

# Database maintenance
podman exec postgres-vector psql -U wger wger -c "VACUUM ANALYZE;"
```

## Notes

- **Resource Optimization**: Automatic data sync disabled by default
- **Shared Services**: Uses postgres-vector and redis for efficiency
- **Multi-Container**: Complex setup with dedicated static file serving
- **Exercise Database**: Large dataset available (~500MB images, ~2GB videos)

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
