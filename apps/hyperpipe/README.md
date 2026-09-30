# Hyperpipe

Hyperpipe is a privacy-focused alternative frontend for YouTube that provides a clean, lightweight interface for browsing YouTube content without ads, tracking, or other privacy-invasive elements.

## Overview

Hyperpipe offers an alternative way to access YouTube content with enhanced privacy features. It acts as a frontend that proxies YouTube requests while removing ads, tracking scripts, and providing additional features like better search and playlist management.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from YouTube
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Video Playback**: Full support for viewing YouTube videos
- **Search Functionality**: Search YouTube videos and channels
- **Playlist Support**: Create and manage playlists
- **Channel Browsing**: Browse channels and view channel content
- **No JavaScript Required**: Works without JavaScript for basic video viewing
- **Mobile Friendly**: Responsive design that works on all devices

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service, though backend may be needed)
- **Network**: HTTP port 8045 (web UI), internet access for YouTube API
- **Storage**: Minimal (no persistent storage required)

## Installation & Deployment

### Current Status

**Note**: This service is currently on hold as it may require a backend component that is not yet configured in this setup.

**Upstream status**: Hyperpipe has been [discontinued](https://codeberg.org/Hyperpipe/Hyperpipe) by its developers. The image still works but will not receive fixes.

### Quick Deploy (When Ready)

```bash
cd ~/selfhost/apps/hyperpipe
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/hyperpipe
   ```

2. **Configure Environment (required)**
   ```bash
   cp environments/sample.env environments/local.env
   # Set PIPED_API and HYP_API; the container exits if either is missing
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: Standard container security with network isolation

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/hyperpipe.conf` - Reverse proxy configuration for domain access

### Environment Variables

The image's entrypoint exits unless both variables are set (see `environments/sample.env`):

- `PIPED_API`: Piped API hostname, e.g. `piped-api.aevion.lan`
- `HYP_API`: Hyperpipe backend hostname

## Configuration

### Container Details

- **Image**: `codeberg.org/hyperpipe/hyperpipe:latest`
- **Ports**: Internal 80 → External 8045 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Hyperpipe is configured for basic YouTube frontend functionality:
- **Port**: 80 (internal container port, nginx)
- **Privacy Mode**: Designed for privacy-focused YouTube access
- **API Integration**: YouTube API proxy for content access

### Architecture

Hyperpipe follows a simple frontend architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Hyperpipe      │───▶│   YouTube API   │
│                 │    │   (localhost:8045) │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   NGINX Proxy    │
                       │   (hyperpipe.    │
                       │    aevion.lan)   │
                       └──────────────────┘
```

#### Key Components
- **Hyperpipe Application**: Web application providing YouTube frontend
- **Reverse Proxy**: NGINX for domain-based access
- **YouTube API**: Proxied requests to YouTube's public API

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8045
- **Domain Access**: https://hyperpipe.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse YouTube Content**
   - Visit https://hyperpipe.aevion.lan
   - Search for videos, channels, or playlists
   - View content without ads or tracking

2. **Video Playback**
   - Click on videos to start playback
   - Full video player functionality
   - Quality selection and playback controls

3. **Channel Exploration**
   - Browse channel content and playlists
   - Subscribe to channels (local tracking)
   - View channel statistics and information

### Command Line Operations

```bash
# Service management
systemctl --user status hyperpipe
systemctl --user restart hyperpipe

# Container operations
podman logs hyperpipe
podman exec -it hyperpipe /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection
- **YouTube Alternatives**: Complements other YouTube frontends like Piped

### API Integration

Hyperpipe is a web interface only - no API for external integration. It acts as a proxy for YouTube's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - Hyperpipe is stateless and can be recreated from configuration.

### Backup Commands

```bash
# No persistent data to backup
```

### Restore Commands

```bash
# Restart service to get fresh instance
systemctl --user restart hyperpipe
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active hyperpipe

# Container status
podman ps | grep hyperpipe

# Web interface check
curl -I http://localhost:8045
```

### Logs

```bash
# View recent logs
podman logs --tail 50 hyperpipe

# Follow logs
podman logs -f hyperpipe
```

### Common Issues

**YouTube API Issues**
- Symptoms: Content not loading or API errors
- Cause: YouTube API changes or access restrictions
- Solution: Check YouTube API status and Hyperpipe compatibility

**Backend Dependency**
- Symptoms: Service not fully functional
- Cause: May require separate backend service
- Solution: Check if backend service is needed and configured

**Network Issues**
- Symptoms: Cannot reach YouTube API
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Caching**: Consider enabling caching for better performance
- **Workers**: Increase worker processes for higher traffic
- **API Limits**: Monitor YouTube API rate limits

## Security

- **Container Security**: Rootless container with minimal privileges
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~100-300MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (no persistent storage)
- **Network**: Variable based on YouTube content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull codeberg.org/hyperpipe/hyperpipe:latest
systemctl --user restart hyperpipe
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats hyperpipe
```

## Notes

- **YouTube Compatibility**: Designed as a privacy-focused alternative to YouTube
- **Backend Requirements**: May require separate backend service (currently on hold)
- **No Account Required**: Access YouTube content without Google account
- **Community Project**: Part of the privacy-focused frontend ecosystem

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
