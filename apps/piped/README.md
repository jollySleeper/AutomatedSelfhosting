# Piped

Piped is a privacy-focused alternative frontend for YouTube that provides a clean, lightweight interface for browsing YouTube content without ads, tracking, or other privacy-invasive elements.

## Overview

Piped offers an alternative way to access YouTube content with enhanced privacy features. It uses a decentralized approach with self-hosted instances that don't rely on YouTube's official API, providing better privacy and avoiding rate limits while maintaining full functionality for video playback and channel browsing.

## Features

- **Privacy Protection**: No ads, tracking scripts, or analytics from YouTube
- **Decentralized**: Self-hosted instances reduce reliance on centralized services
- **Clean Interface**: Minimalist, distraction-free YouTube browsing experience
- **Video Playback**: Full support for YouTube video streaming
- **Channel Support**: Browse channels, playlists, and subscriptions
- **Search Functionality**: Search YouTube videos, channels, and playlists
- **RSS Feeds**: Generate RSS feeds for channels and playlists
- **Import/Export**: Import subscriptions from YouTube/Google
- **Multi-Instance**: Part of a federated network of Piped instances
- **SponsorBlock Integration**: Skip sponsored segments in videos
- **Return YouTube Dislike**: Show dislike counts on videos

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern web browser
- **Dependencies**: PostgreSQL (postgres-vector shared database)
- **Network**: HTTP ports 8021-8023 (frontend, API, proxy), internet access for YouTube
- **Storage**: ~1GB for database + variable for cached video data

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/piped
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/piped
   ```

2. **Configure Environment**
   ```bash
   # Database environment: environments/piped-db.env
   # Proxy environment: environments/piped-proxy.env
   # API configuration: configs/piped-api.properties
   ```

3. **Setup Database**
   ```bash
   # Database is configured to use shared postgres-vector
   # Ensure postgres-vector is running and database is created
   ```

4. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: User namespace mapping for database access
- **Security Notes**: Multi-container setup with network isolation

### Configuration Files Modified

- **NGINX Configs**: Multiple reverse proxy configurations for frontend, API, and proxy
- **API Config**: `apps/piped/configs/piped-api.properties` - Backend API configuration
- **Environment Files**: Database and proxy environment configurations

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| POSTGRES_DB | Database name | piped | Yes |
| POSTGRES_USER | Database user | piped | Yes |
| POSTGRES_PASSWORD | Database password | - | Yes |
| HTTP_PROXY_HOST | Proxy host | - | Yes |
| HTTP_PROXY_PORT | Proxy port | 8080 | Yes |
| HTTPS_PROXY_HOST | HTTPS proxy host | - | Yes |
| HTTPS_PROXY_PORT | HTTPS proxy port | 8080 | Yes |

## Configuration

### Container Details

- **Images**:
  - `docker.io/1337kavin/piped-frontend:latest` - Web interface
  - `docker.io/1337kavin/piped:latest` - API backend
  - `docker.io/1337kavin/piped-proxy:latest` - YouTube proxy
  - `docker.io/1337kavin/bg-helper-server:latest` - PoToken generation helper
  - `docker.io/postgres:15-alpine` - Database (alternative to shared)
- **Ports**:
  - Frontend 8080 → External 8021 (web UI)
  - API 8081 → External 8022 (backend API)
  - Proxy 8082 → External 8023 (YouTube proxy)
  - BG Helper 3000 → External 8024 (PoToken generation)
- **Volumes**:
  - `volumes/piped-db/data:/var/lib/postgresql/data` - Database storage
  - `configs/piped-api.properties:/app/config.properties:ro` - API config
- **Networks**: `pasta:--map-host-loopback,10.0.2.2` for `piped-api` (reaches host Postgres and the BG helper); plain pasta for the other services

### Service Configuration

Piped uses a sophisticated multi-container architecture:
- **Frontend**: NGINX serving static web interface
- **API**: Java backend providing YouTube data and functionality
- **Proxy**: Specialized proxy for YouTube video streaming
- **BG Helper**: PoToken generation server for bypassing YouTube's bot detection
- **Database**: PostgreSQL for user data and cache storage

### Architecture

Piped implements a complex architecture for privacy-preserving YouTube access:

#### Container Architecture
```
┌─────────────────┐
│   User Browser  │
│                 │
│ yt.aevion.lan   │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   NGINX Proxy   │    │   Piped Frontend │
│   (Port 1080)   │◄──►│   (Port 8021)    │
│                 │    │   Web Interface  │
└─────────────────┘    └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   Piped API      │
         │              │   (Port 8022)    │
         │              │   Backend        │
         │              └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   PostgreSQL     │
         │              │   (Shared DB)    │
         │              │   postgres-vector│
         │              └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Piped Proxy   │    │   YouTube API    │
│   (Port 8023)   │◄──►│   & Video        │
│   Video Proxy   │    │   Streams        │
└─────────────────┘    └──────────────────┘
```

#### Key Components
- **Piped Frontend**: Modern web interface with search and browsing
- **Piped API**: Backend service handling YouTube data and user management
- **Piped Proxy**: Specialized proxy for video streaming and API calls
- **BG Helper Server**: PoToken generation for bypassing YouTube bot detection
- **PostgreSQL Database**: User data, subscriptions, and cache storage
- **Reverse Proxy**: NGINX providing secure domain-based access

#### Data Flow
1. User accesses YouTube content through web interface
2. Frontend makes API calls to Piped backend
3. API service queries database and external YouTube APIs
4. Proxy service handles video streaming requests
5. All requests are routed through reverse proxy for security

## Usage

### Accessing the Service

- **Main Interface**: https://yt.aevion.lan or https://piped.aevion.lan
- **API Access**: https://piped-api.aevion.lan
- **Proxy Access**: https://piped-proxy.aevion.lan

### Getting Started

1. **Browse YouTube Content**
   - Access the main interface
   - Search for videos, channels, or playlists
   - Browse trending content and recommendations

2. **Video Playback**
   - Click videos to start streaming
   - Choose quality options for different bandwidths
   - SponsorBlock integration skips sponsored segments

3. **Channel Management**
   - Subscribe to channels without YouTube account
   - Import subscriptions from YouTube (if available)
   - RSS feed generation for external readers

### Command Line Operations

```bash
# Service management
podman ps | grep piped
podman logs piped-frontend
podman logs piped-api
podman logs piped-proxy

# Container operations
podman exec -it piped-frontend /bin/sh
podman exec -it piped-api /bin/bash

# Database operations (via postgres-vector)
podman exec postgres-vector psql -U piped piped
```

## Integration

### With Other Services

- **PostgreSQL**: Uses shared postgres-vector database
- **NGINX Proxy**: Multiple reverse proxy configurations
- **YouTube Alternatives**: Complements other privacy frontends

### API Integration

Piped provides extensive APIs for:
- **Video Data**: Search, trending, and video information
- **Channel Data**: Channel information and video listings
- **Playlist Management**: Create and manage playlists
- **Subscription Management**: User subscriptions and feeds
- **RSS Feeds**: Generate RSS feeds for content

## Backup & Recovery

### Important Data to Backup

- **Database**: PostgreSQL data in postgres-vector (piped database)
- **API Configuration**: `configs/piped-api.properties`
- **User Data**: Subscriptions, playlists, and preferences

### Backup Commands

```bash
# Database backup
podman exec postgres-vector pg_dump -U piped piped > piped-db-backup.sql

# Configuration backup
tar -czf piped-config-$(date +%Y%m%d).tar.gz configs/ environments/

# Full backup
podman exec postgres-vector pg_dump -U piped piped > piped-db-$(date +%Y%m%d).sql
tar -czf piped-full-backup-$(date +%Y%m%d).tar.gz configs/ environments/
```

### Restore Commands

```bash
# Database restore
podman exec -i postgres-vector psql -U piped piped < piped-db-backup.sql

# Configuration restore
tar -xzf piped-config-YYYYMMDD.tar.gz

# Restart services
podman restart piped-frontend piped-api piped-proxy
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep piped

# Web interface checks
curl -I http://localhost:8021  # Frontend
curl -I http://localhost:8022  # API
curl -I http://localhost:8023  # Proxy

# API health check
curl http://localhost:8022/health
```

### Logs

```bash
# Frontend logs
podman logs piped-frontend

# API logs
podman logs piped-api

# Proxy logs
podman logs piped-proxy

# Database logs (if using dedicated container)
podman logs piped-db
```

### Common Issues

**API Connection Issues**
- Symptoms: Videos not loading, search not working
- Cause: API service not running or misconfigured
- Solution: Check API logs and configuration

**Proxy Issues**
- Symptoms: Video streaming failures
- Cause: Proxy service down or YouTube blocking
- Solution: Verify proxy service and check for YouTube changes

**YouTube Live Stream Spinner**
- Symptoms: Livestream media downloads, but the frontend remains buffering
- Cause: Shaka cannot reconcile the separate live audio/video HLS timelines
- Solution: Play the stream with hls.js or an external player instead of the
  Piped frontend; hls.js handles the same HLS master correctly

**Database Connection Issues**
- Symptoms: User data not saving, subscriptions lost
- Cause: PostgreSQL connection problems
- Solution: Check postgres-vector status and connection settings

**Import/Export Problems**
- Symptoms: Cannot import YouTube subscriptions
- Cause: YouTube API changes or authentication issues
- Solution: Check API compatibility and YouTube policies

### Performance Tuning

- **Database Optimization**: Regular PostgreSQL maintenance
- **Caching**: API response caching for better performance
- **Proxy Configuration**: Adjust proxy settings for reliability
- **Resource Allocation**: Increase memory for high-usage scenarios

## Security

- **Container Security**: Rootless containers with user isolation
- **Network Security**: Multiple reverse proxy layers
- **Data Protection**: Local user data storage
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: 1-3GB depending on usage and concurrent users
- **CPU**: Variable based on video processing and API requests
- **Storage**: ~1GB database + cache for video data
- **Network**: High bandwidth for video streaming

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/1337kavin/piped-frontend:latest
podman pull docker.io/1337kavin/piped:latest
podman pull docker.io/1337kavin/piped-proxy:latest
podman pull docker.io/1337kavin/bg-helper-server:latest
podman restart piped-frontend piped-api piped-proxy piped-bg-helper
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Database maintenance
podman exec postgres-vector psql -U piped piped -c "VACUUM ANALYZE;"

# Clear API cache (if applicable)
podman exec piped-api [cache-clear-command]
```

## Notes

- **Multi-Container Complexity**: Sophisticated setup with multiple specialized services
- **YouTube Compatibility**: Independent from YouTube's official API for better privacy
- **Federated Network**: Part of a network of Piped instances
- **Resource Intensive**: Higher resource requirements due to video processing

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
