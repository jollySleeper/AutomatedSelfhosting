# Navidrome

Navidrome is an open-source music server and streamer compatible with Subsonic/Airsonic clients, providing a modern web interface for music libraries.

## Overview

Navidrome indexes your music collection and provides multiple ways to access it: through a modern web interface, or by using any Subsonic-compatible client. It supports transcoding, multiple users, playlists, and more.

## Features

- **Web Interface**: Modern, responsive web interface for browsing and playing music
- **Subsonic API**: Compatible with all Subsonic/Airsonic clients (apps for mobile, desktop)
- **Multi-User Support**: Multiple users with individual playlists and preferences
- **Transcoding**: Automatic audio transcoding for compatibility and bandwidth optimization
- **Playlists**: Create and manage playlists across devices
- **Album Art**: Automatic album art fetching and caching
- **Star Ratings**: Rate your favorite songs and albums
- **Last.fm Integration**: Scrobble plays to Last.fm (optional)
- **Jukebox Mode**: Stream music directly from the server

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP access (port 8043 internally)
- **Storage**: Variable based on music library size + ~100MB for database/cache

## Installation

### Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd /home/legion/selfhost/apps/navidrome
   ```

2. **Configure Environment**
   ```bash
   # Environment file: environments/local.env
   ND_DATAFOLDER=/data
   ND_CACHEFOLDER=/data/cache
   ND_LOGLEVEL=info
   ND_BASEURL=http://navi.aevion.lan
   ND_PORT=4533
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

4. **Configure Reverse Proxy**
   - NGINX configuration: `apps/nginx/configs/sites/navidrome.conf`
   - Server names: `navi.aevion.lan`, `navidrome.aevion.lan`
   - Internal port: 8043

5. **Start Service**
   ```bash
   # Service starts automatically via systemd
   systemctl --user start navidrome
   ```

### Configuration Files Modified

- **NGINX Configuration**: `apps/nginx/configs/sites/navidrome.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| ND_DATAFOLDER | Database and configuration storage | /data | Yes |
| ND_CACHEFOLDER | Cache directory for transcoding/images | /data/cache | No |
| ND_LOGLEVEL | Logging verbosity (error, warn, info, debug, trace) | info | No |
| ND_BASEURL | Base URL for reverse proxy | (empty) | No |
| ND_PORT | Internal service port | 4533 | Yes |
| ND_MUSICFOLDER | Music library path | /music | No |

## Configuration

### Container Configuration

- **Image**: `docker.io/deluan/navidrome:latest`
- **Ports**: Internal 4533 → External 8043 (localhost)
- **User**: Non-root user (UID/GID 1001)
- **Volumes**:
  - `volumes/data:/data` - Database, configuration, and cache
  - `$HOME/media/Songs:/music` - Music library directory
- **Auto-update**: Registry-based automatic updates

### Service-Specific Configuration

Navidrome stores all data in the `/data` volume:
- SQLite database with user accounts, playlists, and ratings
- Cached album art and transcoded audio files
- User preferences and settings

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8043
- **Domain Access**: https://navi.aevion.lan or https://navidrome.aevion.lan
- **API Endpoints**: Subsonic API available at `/rest` path

### Basic Usage Instructions

1. **Initial Setup**
   - Access the web interface
   - Create an admin account
   - The service will automatically scan your music library

2. **Library Management**
   - Music is automatically indexed from the mounted directory
   - Browse by artist, album, genre, or folder structure
   - Star favorite songs and albums

3. **Client Apps**
   - Use any Subsonic-compatible app (DSub, Ultrasonic, etc.)
   - Web interface works on all modern browsers
   - Mobile apps available for iOS and Android

### Command Line Usage

```bash
# Check service status
systemctl --user status navidrome

# View logs
podman logs navidrome

# Restart service
systemctl --user restart navidrome

# Force library scan
podman exec navidrome navidrome scan
```

## Integration

### With Other Services

- **File Storage**: Integrates with local file system for music storage
- **Reverse Proxy**: NGINX provides secure domain-based access
- **Media Organization**: Complements other media services like Jellyfin

### API Integration

Navidrome implements the Subsonic API for:
- Music streaming and download
- Playlist management
- User authentication
- Library browsing

Compatible clients include:
- DSub (Android)
- Ultrasonic (Android)
- Subsonic Music (iOS)
- Many desktop applications

## Backup and Recovery

### What to Backup

- **Database**: `volumes/data/` - Contains user accounts, playlists, ratings
- **Cache**: Optional, can be regenerated
- **Music Files**: External music directory (backed up separately)

### Backup Commands

```bash
# Backup data directory
tar -czf navidrome-data-$(date +%Y%m%d).tar.gz volumes/data

# Backup with podman (if needed)
podman commit navidrome navidrome-backup:$(date +%Y%m%d)
```

### Restore Commands

```bash
# Restore from backup
tar -xzf navidrome-data-YYYYMMDD.tar.gz

# Restart service
systemctl --user restart navidrome
```

## Monitoring

### Health Checks

```bash
# Check if service is running
systemctl --user is-active navidrome

# Check web interface
curl -I http://localhost:8043
```

### Logs

```bash
# View recent logs
podman logs --tail 50 navidrome

# Follow logs in real-time
podman logs -f navidrome
```

### Metrics

Navidrome provides basic statistics through its web interface and API.

## Troubleshooting

### Common Issues

**Library Not Scanning**
- Symptoms: Music not appearing in library
- Cause: Permission issues or incorrect music folder path
- Solution: Check volume mounts and file permissions

**Transcoding Issues**
- Symptoms: Audio not playing on some devices
- Cause: Missing transcoding tools or permission issues
- Solution: Check container logs and ensure proper permissions

**Client Connection Issues**
- Symptoms: Apps can't connect to server
- Cause: Network configuration or firewall issues
- Solution: Verify API endpoints and network accessibility

### Logs Analysis

```bash
# Check for scan errors
podman logs navidrome | grep -i scan

# Check for API errors
podman logs navidrome | grep -i error
```

### Performance Tuning

- **Library Size**: Large libraries benefit from SSD storage and more RAM
- **Transcoding**: CPU-intensive, consider hardware acceleration
- **Cache Size**: Monitor cache directory size and clean periodically

## Security Considerations

- **Authentication**: Built-in user authentication system
- **Network Security**: Reverse proxy provides additional security layer
- **API Security**: Subsonic API requires authentication
- **Updates**: Keep container image updated for security patches

## System Resource Usage

- **Memory**: 256MB - 1GB depending on library size and concurrent users
- **CPU**: Low usage for browsing, higher for transcoding
- **Storage**: Database ~50-200MB, cache grows with usage
- **Network**: Variable based on audio streaming bitrate and transcoding

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/deluan/navidrome:latest
systemctl --user restart navidrome
```

### Cleanup

```bash
# Clean up old images
podman image prune -f

# Clear cache if needed
rm -rf volumes/data/cache/*
systemctl --user restart navidrome
```

## Notes

- Navidrome supports all common audio formats (MP3, FLAC, AAC, etc.)
- Automatic format conversion for compatibility
- Community-driven project with active development
- Extensive client support through Subsonic API compatibility

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
