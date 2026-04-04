# File Browser

File Browser is a web-based file manager that provides a clean, modern interface for managing files and directories. This deployment provides secure file management capabilities with user authentication, file operations, and media preview support.

## Overview

File Browser is a simple, fast, and modern web-based file manager designed to be lightweight and easy to use. It allows users to browse, upload, download, and manage files through a web interface with features like user authentication, file sharing, and media previews.

## Features

- **File Management**: Upload, download, delete, rename, and move files and directories
- **User Authentication**: Secure login system with user management
- **File Preview**: Preview images, videos, audio files, and documents
- **Search Functionality**: Quick file and folder search capabilities
- **File Sharing**: Generate shareable links with optional passwords
- **Responsive Design**: Mobile-friendly interface that works on all devices
- **Command Execution**: Run shell commands (configurable)
- **Dark Mode**: Optional dark theme for the interface
- **Multi-user Support**: Multiple user accounts with different permissions
- **Web Interface**: Access via browser with no client installation required

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, modern web browser
- **Dependencies**: None (standalone container)
- **Network**: HTTP port 8032 (internal, reverse proxy via NGINX)
- **Storage**: Variable based on file storage needs

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/filebrowser
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/filebrowser
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless container operation
- **Volume Permissions**: Automatic permission handling
- **Security Notes**: Runs with standard user permissions

### Configuration Files Modified

None - File Browser uses environment variables and database for configuration.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| FB_PORT | Internal port for File Browser | `80` | No |
| FB_DATABASE | Path to database file | `/database/filebrowser.db` | No |
| FB_CONFIG | Path to configuration file | `/config/settings.json` | No |
| FB_ROOT | Root directory for file management | `/srv` | No |
| FB_NOAUTH | Disable authentication | `false` | No |
| FB_ADDRESS | Listen address | `0.0.0.0` | No |
| FB_ALLOW_COMMANDS | Allow command execution | `true` | No |
| FB_ALLOW_EDIT | Allow file editing | `true` | No |
| FB_ALLOW_NEW | Allow creating new files/directories | `true` | No |
| FB_ALLOW_DELETE | Allow file deletion | `true` | No |

## Configuration

### Container Details

- **Image**: `docker.io/filebrowser/filebrowser:latest`
- **Ports**: Internal 8080 → External 127.0.0.1:8032 (localhost, reverse proxy)
- **Volumes**:
  - `volumes/database:/database` - SQLite database for users/settings
  - `volumes/config:/config` - Configuration files
  - `~/media:/srv` - Root directory for file management
- **Networks**: Bound to 127.0.0.1 for reverse proxy security

### Service Configuration

File Browser is configured for secure file management:
- **Root Directory**: Access to ~/media directory for file operations
- **Database Storage**: Persistent user accounts and settings
- **Authentication**: Built-in user management system
- **File Permissions**: Respects underlying filesystem permissions

### Architecture

File Browser provides web-based file management:

```
┌─────────────────┐
│   Web Browser   │
│   (User)        │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   File Browser  │    │   File Browser   │
│   Web Interface │◄──►│   Container       │
│   (Port 8020)   │    │   Application     │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   File Storage  │
│   ~/media       │
│                 │
│ • Documents     │
│ • Images        │
│ • Videos        │
│ • Downloads     │
└─────────────────┘
```

#### Key Components
- **Web Interface**: Modern, responsive web application
- **File Browser Backend**: Go-based file management server
- **Database**: SQLite for user accounts and configuration
- **Authentication**: Built-in user management system

## Usage

### Accessing File Browser

1. **Direct Access**: Open `http://127.0.0.1:8032` in your web browser
2. **Reverse Proxy**: Access via configured subdomain `http://fb.aevion.lan`

### Initial Setup

On first access, you'll need to create an admin user:

```bash
# The application will prompt for admin user creation
# Default username: admin
# Set a secure password
```

### Basic Operations

- **Upload Files**: Click "Upload" button or drag-and-drop files
- **Create Folders**: Right-click → "New Folder"
- **Download Files**: Select files → "Download"
- **Delete Files**: Select files → "Delete"
- **Search**: Use the search bar to find files/folders

### User Management

- **Add Users**: Settings → Users → Add User
- **Set Permissions**: Configure read/write permissions per user
- **User Roles**: Admin, user, or readonly permissions

## Reverse Proxy Configuration

File Browser supports reverse proxy deployment through NGINX for secure external access.

### Routing Based on Hostname

For hostname-based routing (e.g., `filebrowser.aevion.lan`):

```nginx
upstream docker-filebrowser {
    server 127.0.0.1:8020;
}

server {
    listen 80;
    server_name filebrowser.aevion.lan;

    location / {
        proxy_pass http://docker-filebrowser;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Routing Based on URL Path

For path-based routing (e.g., `aevion.lan/filebrowser/`):

```nginx
server {
    listen 80;
    server_name aevion.lan;

    location /filebrowser/ {
        proxy_pass http://127.0.0.1:8020/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Rewrite URLs
        rewrite ^/filebrowser/(.*) /$1 break;
    }
}
```

## Integration with Other Services

### systemd-switch Integration

File Browser is integrated with systemd-switch for on-demand service management:

- **Service Control**: Start/stop via web interface at port 8081
- **Resource Management**: Automatic cleanup when not in use
- **ALLOWED_SERVICES**: Must be added to systemd-switch configuration

### Media Server Integration

File Browser can complement media management services:

- **Jellyfin**: File Browser for file organization, Jellyfin for streaming
- **Audiobookshelf**: File management alongside audiobook library
- **Calibre**: Document organization and management

## Backup & Recovery

### Data Backup

```bash
# Backup File Browser data
cd ~/selfhost/apps/filebrowser
tar -czf filebrowser-backup-$(date +%Y%m%d).tar.gz volumes/
```

### Database Backup

```bash
# Backup user accounts and settings
cp volumes/database/filebrowser.db volumes/database/filebrowser.db.backup
```

### Recovery Process

```bash
# Restore from backup
cd ~/selfhost/apps/filebrowser
tar -xzf filebrowser-backup-YYYYMMDD.tar.gz
systemctl --user restart filebrowser
```

## Monitoring

### Health Checks

```bash
# Check service status
systemctl --user status filebrowser.service

# Check container logs
podman logs filebrowser

# Verify web interface
curl -I http://localhost:8020
```

### Resource Usage

```bash
# Monitor container resources
podman stats filebrowser

# Check disk usage
du -sh ~/selfhost/apps/filebrowser/volumes/
```

### Log Analysis

```bash
# View application logs
podman logs -f filebrowser

# Systemd logs
journalctl --user -u filebrowser.service --no-pager
```

## Security

### Container Security

- **Rootless Operation**: Runs without root privileges
- **Minimal Attack Surface**: Single-purpose container
- **Resource Limits**: Configurable CPU/memory limits

### Access Control

- **Authentication Required**: User login mandatory
- **Permission Levels**: Granular user permissions
- **Session Management**: Automatic session timeouts

### Network Security

- **Reverse Proxy**: SSL termination via NGINX
- **Firewall Rules**: Restrict access to necessary ports
- **VPN Access**: Secure remote access via Tailscale

## Maintenance

### Updates

```bash
# Update container image
cd ~/selfhost/apps/filebrowser
./podman-setup.sh stop
podman pull docker.io/filebrowser/filebrowser:latest
./podman-setup.sh start
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clean up volumes (CAUTION: destroys data)
# podman volume rm filebrowser_data filebrowser_database filebrowser_config
```

### Log Rotation

File Browser handles log rotation automatically. Monitor disk usage:

```bash
# Check log sizes
podman exec filebrowser du -sh /var/log/
```

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check container status
podman ps -a | grep filebrowser

# Check logs
podman logs filebrowser

# Verify volume permissions
ls -la ~/selfhost/apps/filebrowser/volumes/
```

#### Cannot Access Web Interface
```bash
# Check port binding
ss -tlnp | grep :8020

# Test local access
curl http://localhost:8020

# Check firewall rules
sudo ufw status | grep 8020
```

#### Permission Errors
```bash
# Check volume ownership
ls -la ~/selfhost/apps/filebrowser/volumes/

# Fix permissions if needed
chown -R $USER:$USER ~/selfhost/apps/filebrowser/volumes/
```

#### Database Issues
```bash
# Check database file
ls -la ~/selfhost/apps/filebrowser/volumes/database/

# Reset database (WARNING: loses all users/settings)
rm ~/selfhost/apps/filebrowser/volumes/database/filebrowser.db
systemctl --user restart filebrowser
```

### Performance Tuning

- **Memory Limits**: Increase if handling large file operations
- **CPU Limits**: Adjust based on concurrent user load
- **Disk I/O**: Monitor for storage performance bottlenecks

### Debug Mode

```bash
# Enable verbose logging
podman exec -it filebrowser filebrowser --help
```

## Development & Testing

### Local Testing

```bash
# Test container deployment
cd ~/selfhost/apps/filebrowser
./podman-setup.sh

# Verify functionality
curl -I http://localhost:8020
```

### Integration Testing

```bash
# Test with reverse proxy
# Configure NGINX and test subdomain access

# Test file operations
# Upload/download files through web interface
```

### Load Testing

```bash
# Basic load test
ab -n 100 -c 10 http://127.0.0.1:8032/
```

---

*File Browser deployment for SelfHost ecosystem*
*Port: 8032 (internal: 8080) | Image: filebrowser/filebrowser:latest*
*Last updated: November 8, 2025*
