# BiblioReads

BiblioReads is a self-hosted book tracking and reading management application that helps you organize your personal library and track your reading progress.

## Overview

BiblioReads provides a clean, web-based interface for managing your personal book collection, tracking reading progress, and maintaining a digital reading journal. It focuses on simplicity and privacy, storing all data locally without any external dependencies.

## Features

- **Book Collection Management**: Add and organize your personal book library
- **Reading Progress Tracking**: Track reading progress with page counts and percentages
- **Reading Journal**: Maintain a digital reading log with notes and reviews
- **Book Metadata**: Store book details including authors, genres, and publication info
- **Search and Filtering**: Find books by title, author, genre, or reading status
- **Reading Statistics**: View reading progress and completion statistics
- **Clean Interface**: Simple, distraction-free web interface
- **Self-Hosted**: Complete privacy with local data storage
- **No External Dependencies**: Runs entirely on your infrastructure

## Prerequisites

- **System Requirements**: Minimum 128MB RAM, modern web browser
- **Dependencies**: None (standalone web application)
- **Network**: HTTP port 8017 (web UI)
- **Storage**: Minimal (SQLite database for book data)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/biblioreads
./podman-setup.sh run-con biblioreads
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/biblioreads
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh run-con biblioreads
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: Matches host user for file access
- **Volume Permissions**: No persistent volumes (data stored in container)
- **Security Notes**: Standard container security with network isolation

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/biblioreads.conf` - Reverse proxy configuration for domain access

### Environment Variables

None - BiblioReads uses default configuration.

## Configuration

### Container Details

- **Image**: `docker.io/nesaku/biblioreads:latest`
- **Ports**: Internal 3000 → External 8017 (localhost)
- **Volumes**: None (stateless, data stored in container)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

BiblioReads is configured for simple book management:
- **SQLite Database**: Embedded database for all book data
- **Single User**: Designed for personal use
- **Web Interface**: Clean, responsive web UI
- **No Authentication**: Direct access without login

### Architecture

BiblioReads provides a simple web interface for book management:

```
┌─────────────────┐    ┌──────────────────┐
│   User Browser  │───▶│   BiblioReads    │
│                 │    │   (localhost:8017)│
│ br.aevion.lan   │    │   Web Application│
└─────────────────┘    └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   SQLite         │
                       │   Database       │
                       │   (Embedded)     │
                       └──────────────────┘
```

#### Key Components
- **Web Interface**: Book management and tracking interface
- **Database Engine**: SQLite for book data storage
- **Reading Tracker**: Progress tracking and statistics
- **Search Engine**: Book search and filtering capabilities

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8017
- **Domain Access**: https://br.aevion.lan or https://biblioreads.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Access Application**
   - Open http://localhost:8017 in your browser
   - No authentication required

2. **Add Books**
   - Click "Add Book" to add books to your library
   - Enter book details: title, author, genre, page count
   - Upload or link to book cover images

3. **Track Reading Progress**
   - Mark books as "Currently Reading", "Read", or "Want to Read"
   - Update reading progress with page numbers or percentages
   - Add reading notes and reviews

4. **Organize Library**
   - Sort and filter books by various criteria
   - Create custom categories and tags
   - View reading statistics and progress

### Command Line Operations

```bash
# Service management
podman ps | grep biblioreads
podman logs biblioreads

# Container operations
podman exec -it biblioreads /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Book Sources**: Manual entry or integration with book APIs
- **Backup Systems**: SQLite database backup integration

### API Integration

BiblioReads is a web application - no direct API integration available.

## Backup & Recovery

### Important Data to Backup

- **SQLite Database**: Contains all book data, reading progress, and notes
- **Configuration**: Any custom settings (minimal)

### Backup Commands

```bash
# Find and backup SQLite database (inside container)
podman exec biblioreads find /app -name "*.db" -exec cp {} /tmp/ \;

# Copy database from container
podman cp biblioreads:/path/to/database.db ./biblioreads-backup.db

# Full backup with timestamp
podman exec biblioreads tar -czf - /app/data > biblioreads-backup-$(date +%Y%m%d).tar.gz
```

### Restore Commands

```bash
# Stop container
podman stop biblioreads

# Restore database
podman cp ./biblioreads-backup.db biblioreads:/app/data/database.db

# Restart container
podman start biblioreads
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep biblioreads

# Web interface check
curl -I http://localhost:8017
```

### Logs

```bash
# Container logs
podman logs biblioreads

# Recent errors
podman logs biblioreads | grep -i error
```

### Common Issues

**Cannot Access Web Interface**
- Symptoms: Web interface not accessible
- Cause: Container not running or port conflicts
- Solution: Check container status and port availability

**Data Loss on Restart**
- Symptoms: Book data lost after container restart
- Cause: Data not properly persisted
- Solution: Ensure database file is properly stored and backed up

**Performance Issues**
- Symptoms: Slow loading or response times
- Cause: Large database or insufficient resources
- Solution: Check resource usage and database size

### Performance Tuning

- **Database Optimization**: Regular SQLite maintenance
- **Memory Allocation**: Monitor and adjust container memory
- **Backup Frequency**: Regular backups for data safety

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (no external exposure)
- **Data Protection**: Local SQLite database storage
- **No Authentication**: Direct access (suitable for personal use)

## System Resources

- **Memory**: 64-256MB typical usage
- **CPU**: Minimal CPU usage
- **Storage**: Variable based on book collection size
- **Network**: Low usage (primarily web interface)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/nesaku/biblioreads:latest
podman restart biblioreads
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check database size
podman exec biblioreads du -sh /app/data/
```

## Notes

- **Personal Library**: Designed for individual book collection management
- **Reading Progress**: Detailed tracking of reading habits and progress
- **Self-Hosted Privacy**: Complete control over your reading data
- **Simple Interface**: Focus on functionality over complex features
- **SQLite Backend**: Lightweight database for reliable data storage

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
