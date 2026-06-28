# MKVToolNix

MKVToolNix is a set of tools to create, alter, and inspect Matroska (.mkv) files. This deployment provides a web-based interface for MKV manipulation using the LinuxServer.io container with noVNC.

## Overview

MKVToolNix is a comprehensive toolset for working with Matroska multimedia container files. It allows users to create, modify, and inspect MKV files through a graphical interface. This deployment provides remote access via web browser using noVNC for desktop-like MKV editing capabilities.

## Features

- **MKV Creation**: Create new Matroska files from various input formats
- **File Editing**: Modify existing MKV files - add/remove tracks, chapters, tags
- **Track Management**: Manipulate audio, video, and subtitle tracks
- **Chapter Editor**: Create and edit chapter markers
- **Header Editor**: View and modify Matroska file headers
- **Job Queue**: Batch processing of multiple files
- **Web Interface**: Access via browser using noVNC remote desktop
- **File Browser**: Navigate and manage media files
- **Dark Mode**: Optional dark theme for the interface

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern web browser with HTML5 support
- **Dependencies**: None (standalone container with GUI)
- **Network**: HTTP port 5800 (noVNC web interface)
- **Storage**: Variable based on media file sizes

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/mkvtoolnix
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/mkvtoolnix
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Root container (required for GUI applications)
- **UID/GID**: Root user (0:0) required for X11/display operations
- **Volume Permissions**: Access to media directories
- **Security Notes**: Root access required for GUI display server

### Configuration Files Modified

None - MKVToolNix uses default configuration.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| USER_ID | ID of the user the application runs as | `1000` | No |
| GROUP_ID | ID of the group the application runs as | `1000` | No |
| SUP_GROUP_IDS | Comma-separated list of supplementary group IDs | (empty) | No |
| UMASK | Mask controlling permissions for newly created files | `0022` | No |
| LANG | Sets the locale/language for the application | `en_US.UTF-8` | No |
| TZ | TimeZone used by the container | `Etc/UTC` | No |
| KEEP_APP_RUNNING | Restart application if it crashes | `0` | No |
| APP_NICENESS | Priority at which the application runs (-20 to 19) | `0` | No |
| DISPLAY_WIDTH | GUI display width in pixels | `1920` | No |
| DISPLAY_HEIGHT | GUI display height in pixels | `1080` | No |
| DARK_MODE | Enable dark theme for the interface | `1` | No |
| WEB_AUDIO | Enable audio support in web browser | `0` | No |
| WEB_FILE_MANAGER | Enable web-based file manager | `0` | No |
| WEB_FILE_MANAGER_ALLOWED_PATHS | Paths accessible by file manager | `AUTO` | No |
| WEB_FILE_MANAGER_DENIED_PATHS | Paths denied access by file manager | (empty) | No |
| VNC_PASSWORD | Password for VNC access (max 8 chars) | (empty) | No |
| WEB_AUTHENTICATION | Enable web authentication | `0` | No |
| WEB_AUTHENTICATION_USERNAME | Username for web authentication | (empty) | No |
| WEB_AUTHENTICATION_PASSWORD | Password for web authentication | (empty) | No |

## Configuration

### Container Details

- **Image**: `docker.io/jlesage/mkvtoolnix:latest`
- **Ports**: Internal 5800 → External 5800 (localhost)
- **Volumes**:
  - `volumes/config:/config` - Application configuration
  - `~/media:/storage` - Media file access
- **Networks**: Host networking for direct port access

### Service Configuration

MKVToolNix is configured for web-based MKV editing:
- **Display Resolution**: 1920x1080 for optimal GUI experience
- **Dark Mode**: Enabled for better user experience
- **Media Access**: Direct access to ~/media directory
- **Web Interface**: noVNC for browser-based access

### Architecture

MKVToolNix provides desktop-like MKV editing through web interface:

```
┌─────────────────┐
│   Web Browser   │
│   (User)        │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   noVNC Web     │    │   MKVToolNix     │
│   Interface     │◄──►│   GUI Application│
│   (Port 5800)   │    │   Container       │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Media Files   │
│   ~/media       │
│                 │
│ • MKV Files     │
│ • Source Videos │
│ • Audio Tracks  │
└─────────────────┘
```

#### Key Components
- **noVNC Interface**: Web-based VNC client for GUI access
- **MKVToolNix GUI**: Full desktop application for MKV manipulation
- **File Browser**: Access to media files for processing
- **Display Server**: Virtual display for GUI rendering

## Reverse Proxy Configuration

MKVToolNix supports reverse proxy deployment through NGINX for secure external access. Below are example NGINX configurations.

### Routing Based on Hostname

For hostname-based routing (e.g., `mkvtoolnix.aevion.lan`):

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream docker-mkvtoolnix {
    server 127.0.0.1:5800;
}

server {
    listen 80;
    server_name mkvtoolnix.aevion.lan;

    location / {
        proxy_pass http://docker-mkvtoolnix;
    }

    location /websockify {
        proxy_pass http://docker-mkvtoolnix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 86400;
    }

    # Required for audio support
    location /websockify-audio {
        proxy_pass http://docker-mkvtoolnix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 86400;
    }
}
```

### Routing Based on URL Path

For path-based routing (e.g., `aevion.lan/mkvtoolnix/`):

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream docker-mkvtoolnix {
    server 127.0.0.1:5800;
}

server {
    listen 80;
    server_name aevion.lan;

    location = /mkvtoolnix { return 301 $scheme://$http_host/mkvtoolnix/; }
    location /mkvtoolnix/ {
        proxy_pass http://docker-mkvtoolnix/;
        location /mkvtoolnix/websockify {
            proxy_pass http://docker-mkvtoolnix/websockify;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_read_timeout 86400;
        }
        # Required for audio support
        location /mkvtoolnix/websockify-audio {
            proxy_pass http://docker-mkvtoolnix/websockify-audio;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_read_timeout 86400;
        }
    }
}
```

### Additional Features

#### Web Audio Support
Enable `WEB_AUDIO=1` for audio streaming through the browser (Raw PCM, 44.1kHz, 16-bit, stereo).

#### Web File Manager
Enable `WEB_FILE_MANAGER=1` for browser-based file operations. Configure allowed paths:
```bash
WEB_FILE_MANAGER_ALLOWED_PATHS=/storage,/config
WEB_FILE_MANAGER_DENIED_PATHS=/storage/private
```

## Usage

### Accessing the Service

- **Web Interface**: http://localhost:5800 (noVNC MKVToolNix access)
- **No External Access**: Local access only (no reverse proxy configured)

### Getting Started

1. **Access MKVToolNix**
   - Open http://localhost:5800 in your web browser
   - MKVToolNix GUI will load in the noVNC interface
   - Interface may take a moment to fully load

2. **File Operations**
   - Use the file browser to navigate to your media files
   - Open MKV files for inspection and editing
   - Create new Matroska files from source materials

3. **Track Management**
   - View all tracks (video, audio, subtitles) in MKV files
   - Add or remove tracks from files
   - Modify track properties and metadata

### Command Line Operations

```bash
# Service management
podman ps | grep mkvtoolnix
podman logs mkvtoolnix

# Container operations
podman exec -it mkvtoolnix /bin/bash

# Check display
podman exec mkvtoolnix ps aux | grep Xvfb
```

## Integration

### With Other Services

- **File Storage**: Direct access to media files in ~/media
- **Media Processing**: Part of media management workflow
- **Remote Access**: Web-based access without local installation

### API Integration

MKVToolNix is a GUI application - no direct API integration available.

## Backup & Recovery

### Important Data to Backup

- **Configuration**: `volumes/config/` - Application settings and preferences
- **Media Files**: External media directory (backed up separately)

### Backup Commands

```bash
# Backup configuration
tar -czf mkvtoolnix-config-$(date +%Y%m%d).tar.gz volumes/config

# Full backup
tar -czf mkvtoolnix-full-backup-$(date +%Y%m%d).tar.gz volumes/
```

### Restore Commands

```bash
# Restore configuration
tar -xzf mkvtoolnix-config-YYYYMMDD.tar.gz

# Restart service
podman restart mkvtoolnix
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep mkvtoolnix

# Web interface check
curl -I http://localhost:5800

# Process check
podman exec mkvtoolnix ps aux | grep mkvtoolnix
```

### Logs

```bash
# Container logs
podman logs mkvtoolnix

# Recent errors
podman logs mkvtoolnix | grep -i error
```

### Common Issues

**GUI Not Loading / Blank Screen**
- **Symptoms**: Blank screen, noVNC connection issues, or interface not responding
- **Cause**: Virtual display not starting, browser compatibility, or container initialization issues
- **Solutions**:
  - Wait 30-60 seconds for full initialization
  - Try different browser (Chrome/Firefox recommended)
  - Check container logs: `podman logs mkvtoolnix`
  - Verify display server: `podman exec mkvtoolnix ps aux | grep Xvfb`

**File Access Issues**
- **Symptoms**: Cannot access media files or permission errors
- **Cause**: Permission issues with mounted volumes or UID/GID mismatch
- **Solutions**:
  - Check volume mount permissions: `ls -la ~/media`
  - Verify user mapping: set `USER_ID` and `GROUP_ID` to match host user
  - Test file access: `podman exec -it mkvtoolnix ls -la /storage`

**Performance Issues**
- **Symptoms**: Slow GUI response, high resource usage, or unresponsive interface
- **Cause**: Insufficient RAM, complex file operations, or high display resolution
- **Solutions**:
  - Increase container memory limits
  - Reduce display resolution: `DISPLAY_WIDTH=1280 DISPLAY_HEIGHT=720`
  - Process files in smaller batches
  - Close unused applications within the container

**VNC Connection Issues**
- **Symptoms**: Cannot connect via VNC client or password rejected
- **Cause**: VNC password not set or connection security issues
- **Solutions**:
  - Ensure `VNC_PASSWORD` is set (max 8 characters)
  - Use secure connection for password protection
  - Check VNC port accessibility: `podman port mkvtoolnix`

**Web Authentication Problems**
- **Symptoms**: Cannot login or authentication not working
- **Cause**: Incorrect credentials or secure connection required
- **Solutions**:
  - Verify `WEB_AUTHENTICATION=1` and credentials are set
  - Ensure HTTPS is configured when using web authentication
  - Check password database: `podman exec mkvtoolnix cat /config/webauth-htpasswd`

**Audio Not Working**
- **Symptoms**: No audio in web interface
- **Cause**: Web audio not enabled or browser compatibility
- **Solutions**:
  - Set `WEB_AUDIO=1` environment variable
  - Use compatible browser (Chrome recommended)
  - Check browser audio permissions

**File Manager Issues**
- **Symptoms**: Cannot upload/download files or access restricted
- **Cause**: File manager not enabled or path restrictions
- **Solutions**:
  - Set `WEB_FILE_MANAGER=1`
  - Configure `WEB_FILE_MANAGER_ALLOWED_PATHS`
  - Check volume permissions for read/write access

### Performance Tuning

- **Memory Allocation**: Increase RAM for large file processing
- **Display Settings**: Adjust resolution for performance vs quality
- **File Operations**: Process files in batches to manage resources

## Security

### Container Security
- **Root Container**: Required for GUI applications and display operations
- **User Permissions**: UID/GID mapping for file access control
- **Resource Limits**: Configurable CPU and memory constraints

### Network Security
- **Local Access Only**: No external exposure by default
- **Port Binding**: Binds to localhost (127.0.0.1) for security
- **Reverse Proxy**: Optional NGINX configuration for controlled access

### Authentication & Access Control

#### VNC Password Protection
Enable VNC password protection by setting `VNC_PASSWORD` environment variable:
```bash
VNC_PASSWORD=mysecret  # Maximum 8 characters
```

**Security Notes**:
- Password is limited to 8 characters (RFB protocol limitation)
- Stored obfuscated in `/config/.vncpass`
- Requires secure connection to prevent clear-text transmission

#### Web Authentication
Enable web-based authentication for additional security:
```bash
WEB_AUTHENTICATION=1
WEB_AUTHENTICATION_USERNAME=admin
WEB_AUTHENTICATION_PASSWORD=secure_password
```

**Features**:
- HTTP Basic Authentication for web interface access
- Requires secure HTTPS connection when enabled
- Optional bcrypt-hashed password database at `/config/webauth-htpasswd`

**Managing Users** (when using password database):
```bash
# Add user
podman exec -ti mkvtoolnix webauth-user add username

# Update password
podman exec -ti mkvtoolnix webauth-user update username

# Remove user
podman exec mkvtoolnix webauth-user del username

# List users
podman exec mkvtoolnix webauth-user list
```

### SSL/TLS Configuration
When exposing externally, configure SSL termination through NGINX reverse proxy with valid certificates.

### File Access Security
- **Volume Mounting**: Controlled access to media directories
- **Web File Manager**: Optional file operations with path restrictions
- **Permission Control**: UMASK settings for new file creation

## System Resources

- **Memory**: 1-4GB depending on file processing and GUI usage
- **CPU**: Variable based on file operations and GUI interactions
- **Storage**: Minimal base + access to media files
- **Network**: Low usage (primarily web interface)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/jlesage/mkvtoolnix:latest
podman restart mkvtoolnix
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear temporary files
podman exec -it mkvtoolnix rm -rf /tmp/*
```

## Notes

- **GUI Application**: Full desktop MKVToolNix accessible via web browser
- **Web-based Access**: noVNC provides remote desktop functionality
- **Media Processing**: Direct access to media files for MKV operations
- **Resource Intensive**: Higher resource requirements for GUI and file processing

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
