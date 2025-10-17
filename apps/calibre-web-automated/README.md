# Calibre-Web-Automated

Calibre-Web-Automated (CWA) is an enhanced version of Calibre-Web with powerful automation features for e-book management. It provides a web interface for your Calibre library with automatic book ingestion, format conversion, and KOReader syncing capabilities.

## Overview

Calibre-Web-Automated builds upon the excellent Calibre-Web foundation by adding:

- **Automatic Book Ingestion**: Drop books into a watched folder for automatic processing
- **Smart Format Conversion**: Automatically convert books to your preferred formats
- **KOReader Syncing**: Built-in progress synchronization across devices
- **Enhanced Metadata**: Improved metadata fetching and management
- **Modern UI**: Clean, responsive web interface

This deployment runs CWA as a containerized web application accessible through the local domain.

## Features

- **Web-Based Library Management**: Full Calibre library access through web browser
- **Automatic Book Processing**: Drop books in `/cwa-book-ingest` for automatic import and conversion
- **Format Conversion**: Convert between EPUB, MOBI, PDF, AZW3, and more
- **KOReader Integration**: Sync reading progress across devices with KOReader
- **Metadata Enhancement**: Automatic metadata fetching and cover downloads
- **User Management**: Multi-user support with configurable permissions
- **Mobile-Friendly**: Responsive design works on all devices
- **OPDS Support**: Compatible with e-book readers and apps

## Prerequisites

- **System Requirements**: Minimum 1GB RAM, modern web browser
- **Existing Calibre Library**: Compatible with existing Calibre libraries
- **Dependencies**: None (standalone service)
- **Network**: Port 8083 for web interface
- **Podman**: Latest version with rootless container support

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/calibre-web-automated
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/calibre-web-automated
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
- **Volume Permissions**: Automatic permission handling
- **Security Notes**: Standard container security with user isolation

### Configuration Files Modified

NGINX site configuration is automatically generated at `apps/nginx/configs/sites/calibre-web-automated.conf`.

## Configuration

### Container Details

- **Image**: `lscr.io/linuxserver/calibre-web-automated:latest`
- **Port**: 127.0.0.1:8083:8083 (accessed via nginx reverse proxy)
- **Volumes**:
  - `volumes:/config` - CWA configuration and database
  - `volumes/book-ingest:/cwa-book-ingest` - Automatic book ingestion folder
  - `~/media/Books:/calibre-library` - Calibre library directory

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| TARGET_FORMAT | Default conversion format | epub | No |
| REQ_FINISH | Require complete downloads before processing | True | No |
| GOOGLE_API_KEY | Google Books API key for metadata | (empty) | No |
| UPLOAD_MAX_SIZE | Maximum upload size in MB | 100 | No |

### Service Configuration

CWA is configured with:
- **Library Location**: ~/media/Books (shared with Calibre desktop)
- **Configuration**: Persistent settings in volumes/ directory
- **Ingestion Folder**: Automatic processing from volumes/book-ingest/
- **Web Interface**: Available at https://calibre-web-automated.aevion.lan

## Usage

### Accessing the Service

**Web Interface**: https://calibre-web-automated.aevion.lan

### Default Admin Login

- **Username**: admin
- **Password**: admin123

### Getting Started

1. **Initial Setup**
   - Access https://calibre-web-automated.aevion.lan
   - **First login may take 5+ minutes** with large libraries due to metadata indexing
   - Log in with default admin credentials
   - Configure basic settings in the admin panel

2. **Library Configuration**
   - CWA will automatically detect your existing Calibre library at ~/media/Books
   - If no library exists, CWA will create one
   - Configure metadata sources and conversion settings

3. **Book Ingestion**
   - Drop e-books into `~/selfhost/apps/calibre-web-automated/volumes/book-ingest/`
   - Books are automatically processed, converted, and added to your library
   - Supported formats: EPUB, PDF, MOBI, AZW3, and more

### KOReader Syncing

CWA includes built-in KOReader syncing:

1. Install the CWA KOReader plugin from: `https://calibre-web-automated.aevion.lan/kosync`
2. Configure the plugin with your CWA instance URL
3. Sync reading progress across all your KOReader devices

### Advanced Features

- **Automatic Conversion**: Set target formats for different devices
- **Metadata Enhancement**: Configure metadata sources (Google Books, etc.)
- **User Management**: Create multiple user accounts with different permissions
- **Email Integration**: Send books via email (requires SMTP configuration)
- **OPDS Feeds**: Access your library through compatible e-reader apps

## Integration

### With Other Services

- **Existing Calibre**: Shares the same library at ~/media/Books
- **Audiobookshelf**: Can complement with audiobook management
- **File Synchronization**: Works with external sync services
- **E-Reader Apps**: OPDS-compatible with many mobile reading apps

### KOReader Integration

```bash
# Access KOReader plugin downloads
https://calibre-web-automated.aevion.lan/kosync
```

### OPDS Access

```bash
# OPDS catalog for e-reader apps
https://calibre-web-automated.aevion.lan/opds
```

## Backup & Recovery

### Important Data to Backup

- **Application Config**: `volumes/` - User settings, database, plugins
- **E-book Library**: `~/media/Books/` - All your books and metadata
- **Ingestion Folder**: `volumes/book-ingest/` - In-progress uploads

### Backup Commands

```bash
# Backup CWA configuration
tar -czf cwa-config-$(date +%Y%m%d).tar.gz volumes/

# Backup complete setup
tar -czf cwa-full-backup-$(date +%Y%m%d).tar.gz \
  volumes/ ~/media/Books/

# Backup ingestion folder (if needed)
tar -czf cwa-ingest-$(date +%Y%m%d).tar.gz volumes/book-ingest/
```

### Restore Commands

```bash
# Restore configuration
tar -xzf cwa-config-YYYYMMDD.tar.gz -C volumes/

# Restore library
tar -xzf cwa-full-backup-YYYYMMDD.tar.gz

# Restart service
systemctl --user restart calibre-web-automated.service
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep calibre-web-automated

# Web interface check
curl -I https://calibre-web-automated.aevion.lan

# Logs
podman logs calibre-web-automated
```

### Common Issues

**Slow First Login**
- Symptoms: Login takes 5+ minutes on first access
- Cause: Large library metadata indexing and scanning
- Solution: Wait for initial processing to complete (normal behavior)

**Library Not Detected**
- Symptoms: Empty library after setup
- Cause: Permission issues with ~/media/Books
- Solution: Check file ownership and container permissions

**Book Ingestion Not Working**
- Symptoms: Books not appearing in library
- Cause: File permissions or unsupported format
- Solution: Check logs and ensure proper file ownership

**KOReader Sync Issues**
- Symptoms: Reading progress not syncing
- Cause: Plugin configuration or network issues
- Solution: Verify plugin settings and connectivity

### Logs

```bash
# View container logs
podman logs calibre-web-automated

# Follow logs in real-time
podman logs -f calibre-web-automated

# Systemd service logs
journalctl --user -u calibre-web-automated.service -f
```

## Security

- **Container Security**: Rootless container with user isolation
- **Web Security**: HTTPS via nginx reverse proxy
- **Authentication**: Built-in user authentication system
- **Access Control**: Configurable user permissions and roles

### Security Considerations

- **HTTPS Required**: All access through nginx reverse proxy with SSL
- **User Authentication**: Strong passwords recommended for all users
- **File Permissions**: Proper ownership of library and config directories
- **Network Security**: Internal-only access through reverse proxy

## System Resources

- **Memory**: 512MB - 1GB depending on library size
- **CPU**: Low baseline, higher during book conversion
- **Storage**: Library size + ~500MB for configuration
- **Network**: Minimal (web access only)

## Maintenance

### Updates

```bash
# Check for updates
podman pull lscr.io/linuxserver/calibre-web-automated:latest

# Restart with new image
systemctl --user restart calibre-web-automated.service
```

### Cleanup

```bash
# Clean processed ingestion files
find volumes/book-ingest/ -type f -mtime +7 -delete

# Remove old images
podman image prune -f
```

## Architecture

```
┌─────────────────┐
│   NGINX Proxy   │
│  (SSL/TLS)      │
│                 │
│ calibre-web-    │
│ automated.      │
│ aevion.lan      │
└─────────────────┘
        │
        ▼
┌─────────────────┐    ┌─────────────────┐
│   CWA Web UI    │    │   Book Ingestion│
│   (Port 8083)   │    │   /cwa-book-    │
│                 │    │   ingest        │
│ • Library Browse│    │                 │
│ • User Mgmt     │    │ • Auto Convert  │
│ • KOReader Sync │    │ • Auto Import   │
└─────────────────┘    └─────────────────┘
        │                        │
        └────────────────────────┘
                 ▼
        ┌─────────────────┐
        │   Calibre       │
        │   Library       │
        │   ~/media/Books │
        │                 │
        │ • metadata.db   │
        │ • Books/        │
        │ • Covers/       │
        └─────────────────┘
```

## Differences from Standard Calibre

| Feature | Standard Calibre | Calibre-Web-Automated |
|---------|------------------|----------------------|
| Interface | Desktop GUI | Web-based |
| Automation | Manual | Automatic ingestion |
| KOReader Sync | Manual setup | Built-in |
| Format Conversion | Manual | Automatic |
| Multi-user | Limited | Full support |
| Mobile Access | Limited | Full responsive |
| OPDS Support | Basic | Enhanced |

## Notes

- **Library Compatibility**: Fully compatible with existing Calibre libraries
- **Automation Features**: Reduces manual book management tasks
- **Device Integration**: Excellent support for e-readers and reading apps
- **Community Driven**: Active development with regular updates
- **Free & Open Source**: GPL-3.0 licensed

---

*Last updated: October 17, 2025*
*Deployed on: legion (aevion.lan)*
*Compatible with: LinuxServer CWA v2.0+*
*Integration: Shares library with Calibre desktop*
