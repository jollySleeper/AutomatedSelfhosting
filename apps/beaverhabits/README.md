# Beaver Habits Tracker

Beaver Habits is a simple, fast, and privacy-focused habit tracking web application that emphasizes speed and privacy with a clean interface for tracking daily habits.

## Overview

Beaver Habits is a lightweight habit tracker that emphasizes speed and privacy. It offers a clean interface for tracking daily habits with features like streaks, categories, and flexible date ranges. All data is stored locally on your infrastructure with no external dependencies or tracking.

## Features

- **Privacy-First**: No accounts, no data collection, runs entirely on your infrastructure
- **Fast & Lightweight**: Minimal dependencies, quick loading
- **Flexible Tracking**: Daily, weekly, and custom periodic habits
- **Streak Tracking**: Visual streak counters for motivation
- **Categories**: Organize habits by categories
- **iOS Standalone**: PWA support for iOS home screen installation
- **Multiple Storage Options**: SQLite database or local JSON files
- **Dark Mode**: Automatic dark/light theme support
- **Single/Multi-User**: Configurable user management

## Prerequisites

- **System Requirements**: Minimum 64MB RAM, modern web browser
- **Dependencies**: None (standalone web application)
- **Network**: HTTP port 8080 (web UI)
- **Storage**: Minimal (JSON files or SQLite database)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/beaverhabits
./podman-setup.sh run-con beaverhabits
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/beaverhabits
   ```

2. **Configure Environment**
   ```bash
   cp environments/local.env environments/production.env
   # Edit production.env with your desired configuration
   # At minimum, set HABITS_STORAGE to either DATABASE or USER_DISK
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh run-con beaverhabits
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: Data directory for habit storage
- **Security Notes**: Local data storage, configurable authentication

### Configuration Files Modified

- **Environment Config**: `apps/beaverhabits/environments/local.env` - Application configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| HABITS_STORAGE | Storage method: DATABASE or USER_DISK | USER_DISK | Yes |
| FIRST_DAY_OF_WEEK | First day of week (0=Monday, 6=Sunday) | 0 | No |
| MAX_USER_COUNT | Maximum users (1=disable signups) | 1 | No |
| ENABLE_IOS_STANDALONE | Enable iOS PWA standalone mode | true | No |
| DARK_MODE | Dark mode setting (true/false/auto) | auto | No |
| TRUSTED_EMAIL_HEADER | HTTP header for reverse proxy auth | - | No |
| TRUSTED_LOCAL_EMAIL | Skip login, auto-create account | - | No |

## Configuration

### Container Details

- **Image**: `docker.io/daya0576/beaverhabits:latest`
- **Ports**: 8080:8080 (Web interface)
- **Volumes**: `data:/app/.user` (habit data storage)
- **Networks**: Host networking for direct access

### Service Configuration

Beaver Habits is configured for privacy-focused habit tracking:
- **Storage Options**: JSON files or SQLite database
- **Single User Mode**: Authentication disabled by default
- **Dark Mode**: Automatic theme switching
- **iOS PWA Support**: Progressive web app capabilities

### Architecture

Beaver Habits provides a simple web interface for habit tracking:

```
┌─────────────────┐    ┌──────────────────┐
│   User Browser  │───▶│   Beaver Habits  │
│                 │    │   (Port 8080)    │
│ localhost:8080  │    │   Web Application│
└─────────────────┘    └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Data Storage   │
                       │   JSON/SQLite    │
                       │   (Persistent)   │
                       └──────────────────┘
```

#### Key Components
- **Web Interface**: Clean habit tracking interface
- **Storage Engine**: JSON files or SQLite database
- **Authentication**: Optional user management
- **PWA Support**: Progressive web app capabilities

#### Storage Options

- **USER_DISK**: Saves habits and records as JSON files in the data directory
- **DATABASE**: Uses SQLite database for all data storage

#### Authentication

- **Default**: No authentication required (single user)
- **Single User**: Set `MAX_USER_COUNT=1` to prevent new signups
- **Reverse Proxy**: Use `TRUSTED_EMAIL_HEADER` for proxy-based authentication
- **Auto Login**: Use `TRUSTED_LOCAL_EMAIL` to skip login entirely

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8080 (web interface)
- **No External Access**: Local access only (configure reverse proxy for external access)

### Getting Started

1. **Access Application**
   - Open http://localhost:8080 in your browser
   - No authentication required by default

2. **Create Habits**
   - Click "Add Habit" to create new tracking items
   - Set habit name, category, and frequency
   - Choose between daily, weekly, or custom intervals

3. **Track Progress**
   - Click checkboxes to mark habits as completed
   - View streaks and completion statistics
   - Organize habits by categories

4. **iOS PWA**
   - Add to home screen for native app experience
   - Works offline for habit tracking

### Command Line Operations

```bash
# Service management
podman ps | grep beaverhabits
podman logs beaverhabits

# Container operations
podman exec -it beaverhabits /bin/sh
```

## Integration

### With Other Services

- **Reverse Proxy**: NGINX for secure external access
- **Backup Systems**: Integrate with automated backup solutions
- **Monitoring**: Basic health checks and resource monitoring

### API Integration

Beaver Habits is a web application - no direct API integration available.

## Backup & Recovery

### Important Data to Backup

- **USER_DISK Mode**: JSON files containing habits and records
- **DATABASE Mode**: SQLite database file with all habit data
- **Configuration**: Environment files and settings

### Backup Commands

#### USER_DISK Mode
```bash
# Backup data directory
cp -r data/ backup/

# Full backup
tar -czf beaverhabits-user-disk-backup-$(date +%Y%m%d).tar.gz data/
```

#### DATABASE Mode
```bash
# Backup SQLite database
sqlite3 data/habits.db .dump > habits_backup.sql

# Full backup
tar -czf beaverhabits-database-backup-$(date +%Y%m%d).tar.gz data/ environments/
```

### Restore Commands

#### USER_DISK Mode
```bash
# Stop container
podman stop beaverhabits

# Restore data
cp -r backup/ data/

# Restart container
podman start beaverhabits
```

#### DATABASE Mode
```bash
# Stop container
podman stop beaverhabits

# Restore database
sqlite3 data/habits.db < habits_backup.sql

# Restart container
podman start beaverhabits
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep beaverhabits

# Web interface check
curl -I http://localhost:8080

# Check data directory
ls -la data/
```

### Logs

```bash
# Container logs
podman logs beaverhabits

# Recent errors
podman logs beaverhabits | grep -i error
```

### Common Issues

**Permission Issues**
- Symptoms: Cannot write to data directory
- Cause: Container user doesn't have write permissions
- Solution: Ensure data directory permissions match container user (1001:1001)

**Data Not Persisting**
- Symptoms: Habit data lost after restart
- Cause: Volume mount issues or permission problems
- Solution: Check volume mount `data:/app/.user` and directory permissions

**Cannot Access Web Interface**
- Symptoms: Web interface not accessible
- Cause: Port conflicts or container not running
- Solution: Check container status and port availability

**Storage Mode Issues**
- Symptoms: Data not saving correctly
- Cause: Incorrect HABITS_STORAGE setting
- Solution: Verify HABITS_STORAGE is set to DATABASE or USER_DISK

### Performance Tuning

- **Storage Choice**: DATABASE mode for better performance with many habits
- **Memory Allocation**: Minimal memory requirements
- **Backup Frequency**: Regular backups for habit data preservation

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only by default
- **Data Protection**: Local data storage, no external dependencies
- **Authentication**: Optional user management and authentication

## System Resources

- **Memory**: 32-128MB typical usage
- **CPU**: Minimal CPU usage
- **Storage**: Minimal (JSON files or SQLite database)
- **Network**: Low usage (primarily web interface)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/daya0576/beaverhabits:latest
podman restart beaverhabits
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check data directory size
du -sh data/
```

## Notes

- **Privacy-First**: No external tracking or data collection
- **Offline-Capable**: Works without internet connection
- **PWA Support**: Can be installed as standalone app on mobile
- **Flexible Storage**: Choose between JSON files or SQLite database
- **Single/Multi-User**: Configurable authentication and user management

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
