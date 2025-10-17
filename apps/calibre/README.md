# Calibre App

Calibre is a powerful and easy-to-use e-book manager and library management system that allows you to organize, convert, and sync your e-book collection.

## Overview

Calibre provides a comprehensive solution for e-book management with features like format conversion, library organization, metadata editing, and device synchronization. This deployment runs Calibre as a web-accessible application in a containerized environment using Podman.

## Features

- **E-book Library Management**: Organize and manage large e-book collections
- **Format Conversion**: Convert between various e-book formats (EPUB, PDF, MOBI, etc.)
- **Metadata Editing**: Edit book metadata, covers, and tags
- **Device Sync**: Sync books with e-readers and tablets
- **Web Interface**: Access Calibre library through a web browser
- **Content Server**: Built-in web server for remote access
- **News Download**: Download and convert news feeds to e-books
- **Plugin System**: Extensible with plugins for additional functionality

## Prerequisites

- **System Requirements**: Minimum 1GB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: Multiple ports (9080, 9181, 9081, 9092) for web interfaces
- **Storage**: Variable based on e-book library size
- **Podman**: Latest version with rootless container support

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/calibre
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/calibre
   ```

2. **Configure Environment Variables**
   ```bash
   cp environments/sample.env environments/local.env
   # Edit environments/local.env with your preferred settings
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with dynamic user ID matching current user
- **Volume Permissions**: Automatic permission handling via PUID/PGID environment variables
- **Security Notes**: Standard container security with user isolation

### Configuration Files Modified

NGINX site configuration is automatically generated at `apps/nginx/configs/sites/calibre.conf`.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| PUID | User ID for container | Auto (current user) | No |
| PGID | Group ID for container | Auto (current group) | No |
| TZ | Timezone | Etc/UTC | No |
| PASSWORD | Web interface password | (empty) | No |
| CLI_ARGS | Additional Calibre arguments | (empty) | No |
| UMASK | File permissions mask | 022 | No |

**Volume Mounts**:
- `volumes:/config` - Calibre configuration and database
- `~/media/Books:/books` - E-book library directory

**Note**: PUID and PGID are automatically set to match the current user's ID (`$(id -u)` and `$(id -g)`) for proper file permissions. You can override these in `local.env` if you need specific user/group IDs.

## Configuration

### Container Details

- **Image**: `lscr.io/linuxserver/calibre:latest`
- **Ports** (exposed to LAN):
  - 9080:8080 (HTTP web interface - legacy)
  - 9181:8181 (Calibre desktop GUI - HTTPS required)
  - 9081:8081 (Calibre content server - HTTP)
  - 9092:9090 (Additional interface - HTTP)
- **Volumes**:
  - `volumes:/config` - Calibre configuration and database
  - `~/media/Books:/books` - E-book library directory
- **Networks**: Host networking with LAN port exposure

### Service Configuration

Calibre is configured with multiple web interfaces:
- **Library Location**: /books (mounted from ~/media/Books)
- **Configuration**: /config (persistent Calibre settings)
- **Web Interfaces**: Multiple ports for different access methods
- **User Permissions**: Non-root user with proper file access

### Architecture

Calibre runs as a single container with multiple web interfaces exposed directly to LAN:

```
┌─────────────────┐
│   Calibre Web   │
│   Interfaces    │
│   (LAN Access)  │
│                 │  ┌─────────────────┐
│ • Port 9181     │  │   E-book        │
│   (HTTPS Main)  │  │   Library       │
│                 │  │   ~/media/Books │
│ • Port 9081     │  │                 │
│   (HTTP Content)│  │                 │
│                 │  └─────────────────┘
│ • Port 9092     │          │
│   (HTTP Extra)  │          ▼
└─────────────────┘  ┌─────────────────┐
                     │   Calibre       │
                     │   Config & DB   │
                     │   volumes/      │
                     └─────────────────┘
```

## Usage

### Accessing the Service

**Important**: Calibre requires HTTPS by default. Ports are exposed directly to LAN (not behind reverse proxy).

- **Main Interface**: https://aevion.lan:9181 (Calibre desktop application in web - HTTPS required)
- **Content Server**: http://aevion.lan:9081 (library browsing and download)
- **Legacy HTTP**: http://aevion.lan:9080 (deprecated - use HTTPS instead)

### Getting Started

1. **Initial Setup**
   - Access the main interface at https://aevion.lan:9181
   - Accept the self-signed SSL certificate when prompted
   - Calibre will create its library in the mounted /books directory
   - Add your existing e-books or start with an empty library

2. **Library Management**
   - Import books from the /books directory
   - Organize books by author, series, genre, and tags
   - Edit metadata and covers for better organization

3. **Format Conversion**
   - Convert books between different formats
   - Optimize books for specific e-readers
   - Batch convert multiple books at once

### Command Line Operations

```bash
# Container management
podman ps | grep calibre
podman logs calibre
podman exec -it calibre /bin/bash

# Calibre operations inside container
podman exec -it calibre calibredb list
podman exec -it calibre calibre --version
```

## Integration

### With Other Services

- **File Storage**: Direct access to e-book library in ~/media/Books
- **Audiobookshelf**: Can complement e-book management with audiobook features
- **File Synchronization**: Can sync with external devices and services

### API Integration

Calibre provides:
- **Command Line Tools**: Extensive CLI tools for automation
- **Content Server API**: RESTful API for library access
- **Plugin API**: Python-based plugin system for extensions

## Backup & Recovery

### Important Data to Backup

- **Library Database**: `volumes/` - Contains all book metadata and settings
- **E-book Files**: `~/media/Books/` - Actual e-book files
- **Configuration**: User preferences and library settings

### Backup Commands

```bash
# Backup configuration and database
tar -czf calibre-config-$(date +%Y%m%d).tar.gz volumes/

# Backup entire library
tar -czf calibre-library-$(date +%Y%m%d).tar.gz ~/media/Books/

# Full backup
tar -czf calibre-full-backup-$(date +%Y%m%d).tar.gz volumes/ ~/media/Books/
```

### Restore Commands

```bash
# Restore configuration
tar -xzf calibre-config-YYYYMMDD.tar.gz -C volumes/

# Restore library
tar -xzf calibre-library-YYYYMMDD.tar.gz

# Restart container
systemctl --user restart calibre.service
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep calibre

# Web interface checks
curl -I http://localhost:9080
curl -I http://localhost:9181
curl -I http://localhost:9081
curl -I http://localhost:9092
```

### Logs

```bash
# View container logs
podman logs calibre

# Follow logs in real-time
podman logs -f calibre

# Systemd service logs
journalctl --user -u calibre.service -f
```

### Common Issues

**Library Access Issues**
- Symptoms: Cannot access or modify library
- Cause: Permission issues with mounted volumes
- Solution: Check file ownership and container user permissions

**Web Interface Not Loading**
- Symptoms: Browser cannot connect to Calibre web interfaces
- Cause: Container not running or port conflicts
- Solution: Check container status and port availability

**Database Corruption**
- Symptoms: Library shows errors or missing books
- Cause: Improper shutdown or disk issues
- Solution: Restore from backup or repair database

### Performance Tuning

- **Library Size**: Large libraries may need more RAM
- **Conversion Performance**: CPU-intensive operations benefit from more cores
- **Storage**: Use fast storage for better performance
- **Memory**: Increase container memory limits for large operations

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Ports exposed directly to LAN (see risks below)
- **Data Protection**: Local file access with standard permissions
- **Web Security**: Built-in authentication required (PASSWORD in local.env)

### Security Considerations for Direct LAN Exposure

**Risks:**
- Ports accessible from all devices on your local network
- Potential unauthorized access if authentication is bypassed
- No additional security layer from reverse proxy

**Mitigations:**
- Strong password set in `PASSWORD` environment variable
- Monitor access logs for suspicious activity
- Consider firewall rules to restrict access to specific IP ranges
- Keep Calibre updated for security patches

**Recommendation:** If security is a major concern, consider setting up SSL certificates for nginx reverse proxy instead of direct LAN exposure.

## System Resources

- **Memory**: 512MB - 2GB depending on library size and operations
- **CPU**: Low baseline, high during format conversion
- **Storage**: Library size + ~100MB for configuration and database
- **Network**: Minimal (primarily local web access)

## Maintenance

### Updates

```bash
# Check for updates
podman pull lscr.io/linuxserver/calibre:latest

# Restart with new image
systemctl --user restart calibre.service
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clean temporary files
podman exec -it calibre rm -rf /tmp/*
```

## Notes

- **E-book Management**: Comprehensive solution for personal e-book libraries
- **Device Integration**: Supports syncing with Kindle, Kobo, and other e-readers
- **Format Support**: Converts between 20+ e-book formats
- **Web Access**: Full desktop application functionality through web browser
- **Rootless Operation**: Runs as non-privileged user for enhanced security

---

*Last updated: October 16, 2025*
*Deployed on: legion (aevion.lan)*
*Compatible with: LinuxServer Calibre v8.12.0-ls363 (HTTPS required)*
