# Audiobookshelf

Audiobookshelf is a self-hosted audiobook and podcast server that streams audio files to any device with a modern web browser.

## Overview

Audiobookshelf provides a complete solution for managing, streaming, and organizing audiobooks and podcasts. It features automatic metadata fetching, chapter navigation, playback speed control, and cross-device synchronization.

## Features

- **Audiobook Management**: Organize and stream audiobooks with full metadata support
- **Podcast Support**: Subscribe to and manage podcasts with automatic episode downloading
- **Multi-Device Sync**: Synchronize playback progress across devices
- **Chapter Navigation**: Navigate chapters with timestamps and titles
- **Playback Controls**: Variable playback speed, sleep timer, and skip controls
- **Web Interface**: Modern, responsive web interface for all devices
- **Mobile Apps**: Dedicated iOS and Android apps available
- **RSS Feeds**: Generate RSS feeds for podcast episodes

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP access (port 8042 internally)
- **Storage**: Variable based on media library size

## Installation

### Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd /home/legion/selfhost/apps/audiobookshelf
   ```

2. **Configure Environment**
   ```bash
   # Environment file: environments/rootless.env
   PORT=8080
   # TOKEN_SECRET=  # Optional: For API authentication
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

4. **Configure Reverse Proxy**
   - NGINX configuration automatically generated at `apps/nginx/configs/sites/audiobookshelf.conf`
   - Server names: `abs.aevion.lan`, `audiobookshelf.aevion.lan`
   - Internal port: 8042

5. **Start Service**
   ```bash
   # Service starts automatically via systemd
   systemctl --user start audiobookshelf
   ```

### Configuration Files Modified

- **NGINX Configuration**: `apps/nginx/configs/sites/audiobookshelf.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| PORT | Internal container port | 8080 | Yes |
| TOKEN_SECRET | API authentication token | (empty) | No |

## Configuration

### Container Configuration

- **Image**: `ghcr.io/advplyr/audiobookshelf:latest`
- **Ports**: Internal 8080 → External 8042 (localhost)
- **User**: Non-root user (UID/GID 1001)
- **Volumes**:
  - `volumes/config:/config` - Application configuration and database
  - `volumes/metadata:/metadata` - Metadata cache and thumbnails
  - `$HOME/media/Books:/audiobooks` - Audiobook library directory
- **Auto-update**: Registry-based automatic updates

### Service-Specific Configuration

Audiobookshelf stores all configuration in the `/config` volume:
- SQLite database with user accounts and library metadata
- User preferences and settings
- Library scan configurations
- Podcast subscription data

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8042
- **Domain Access**: https://abs.aevion.lan or https://audiobookshelf.aevion.lan
- **API Endpoints**: RESTful API available at the same URLs

### Basic Usage Instructions

1. **Initial Setup**
   - Access the web interface
   - Create an admin account
   - Configure your library paths

2. **Add Audiobooks**
   - Place audiobook files in the mounted `/audiobooks` directory
   - Use the web interface to scan and import books
   - Audiobookshelf will automatically fetch metadata from various sources

3. **Library Management**
   - Organize books into collections and series
   - Edit metadata manually if needed
   - Configure automatic library scanning

### Command Line Usage

```bash
# Check service status
systemctl --user status audiobookshelf

# View logs
podman logs audiobookshelf

# Restart service
systemctl --user restart audiobookshelf
```

## Integration

### With Other Services

- **File Storage**: Integrates with local file system for media storage
- **Reverse Proxy**: NGINX provides secure domain-based access
- **Media Organization**: Works alongside other media services like Jellyfin

### API Integration

Audiobookshelf provides a REST API for:
- Library management
- Playback control
- User authentication
- Metadata retrieval

## Backup and Recovery

### What to Backup

- **Configuration**: `volumes/config/` - Contains database and settings
- **Metadata**: `volumes/metadata/` - Cached metadata and thumbnails
- **Media Files**: External media directory (backed up separately)

### Backup Commands

```bash
# Backup configuration and metadata
tar -czf audiobookshelf-config-$(date +%Y%m%d).tar.gz volumes/config volumes/metadata

# Backup with podman (if needed)
podman commit audiobookshelf audiobookshelf-backup:$(date +%Y%m%d)
```

### Restore Commands

```bash
# Restore from backup
tar -xzf audiobookshelf-config-YYYYMMDD.tar.gz

# Restart service to pick up restored configuration
systemctl --user restart audiobookshelf
```

## Monitoring

### Health Checks

```bash
# Check if service is running
systemctl --user is-active audiobookshelf

# Check web interface
curl -I http://localhost:8042
```

### Logs

```bash
# View recent logs
podman logs --tail 50 audiobookshelf

# Follow logs in real-time
podman logs -f audiobookshelf
```

### Metrics

Audiobookshelf provides basic health status through its web interface and API endpoints.

## Troubleshooting

### Common Issues

**Library Scan Issues**
- Symptoms: Books not appearing in library
- Cause: Permission issues or incorrect file paths
- Solution: Check volume mounts and file permissions

**Playback Problems**
- Symptoms: Audio not playing or stuttering
- Cause: Network issues or browser compatibility
- Solution: Check network connectivity and try different browsers

**Metadata Fetching Issues**
- Symptoms: Missing book information
- Cause: Network connectivity or API rate limits
- Solution: Check internet connection and retry metadata fetch

### Logs Analysis

```bash
# Check for errors in logs
podman logs audiobookshelf | grep -i error

# Check recent activity
podman logs --since "1 hour ago" audiobookshelf
```

### Performance Tuning

- **Library Size**: Large libraries may benefit from SSD storage
- **Concurrent Users**: Single-user service, performance scales with hardware
- **Network**: Ensure stable network for streaming large audio files

## Security Considerations

- **Authentication**: Built-in user authentication system
- **Network Security**: Reverse proxy provides additional security layer
- **Data Protection**: Media files should be backed up regularly
- **Updates**: Keep container image updated for security patches

## System Resource Usage

- **Memory**: 512MB - 2GB depending on library size
- **CPU**: Low CPU usage for streaming, higher during library scans
- **Storage**: Database ~10-100MB, metadata cache grows with library size
- **Network**: Variable based on audio streaming bitrate

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/advplyr/audiobookshelf:latest
systemctl --user restart audiobookshelf
```

### Cleanup

```bash
# Clean up old images
podman image prune -f

# Check disk usage
du -sh volumes/
```

## Notes

- Audiobookshelf works best with properly tagged audiobook files
- Supports various audio formats including MP3, M4A, M4B
- Mobile apps available for iOS and Android platforms
- Community plugins available for extended functionality

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
