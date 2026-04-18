# Immich

Immich is a self-hosted photo and video backup solution that provides secure, private media storage with advanced features like facial recognition, object detection, and machine learning-powered search.

## Overview

Immich offers a comprehensive solution for managing personal photos and videos with features like automatic backup, facial recognition, object detection, and advanced search capabilities. It provides a modern, user-friendly interface while maintaining full privacy and control over your media.

## Features

- **Photo/Video Backup**: Automatic upload and backup from mobile devices
- **Facial Recognition**: AI-powered face detection and recognition
- **Object Detection**: Automatic tagging and categorization of objects in photos
- **Advanced Search**: Search by faces, objects, locations, and metadata
- **Timeline View**: Chronological view of all your memories
- **Album Management**: Create and share albums with family and friends
- **Mobile Apps**: Dedicated iOS and Android apps for automatic backup
- **Web Interface**: Modern, responsive web interface for browsing and management
- **Hardware Acceleration**: GPU-accelerated video transcoding and image processing
- **Machine Learning**: On-device ML for privacy-preserving AI features

## Prerequisites

- **System Requirements**: Minimum 4GB RAM, modern CPU with hardware acceleration support
- **Dependencies**: PostgreSQL (postgres-vector), Redis (shared services)
- **Network**: HTTP port 2283 (web UI), various internal ports
- **Storage**: Variable based on photo/video library size + ~10GB for ML models

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/immich
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/immich
   ```

2. **Configure Environment**
   ```bash
   # Environment file: environments/server.env
   # Configure database and Redis connections
   # DB_HOSTNAME=10.0.2.2
   # REDIS_HOSTNAME=10.0.2.2
   ```

3. **Setup Database**
   ```bash
   # Create immich database in shared postgres-vector
   podman exec postgres-vector psql -U postgresql -d postgres -c "CREATE USER immich WITH PASSWORD 'your_secure_password';"
   podman exec postgres-vector psql -U postgresql -d postgres -c "CREATE DATABASE immich OWNER immich;"
   ```

4. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Privileged root containers for hardware acceleration
- **UID/GID**: Root user (0:0) required for GPU device access
- **Volume Permissions**: Root access to media directories and GPU devices
- **Security Notes**: Privileged mode required for hardware acceleration and media processing

### Configuration Files Modified

No NGINX configuration - Immich serves directly.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| DB_HOSTNAME | PostgreSQL host | - | Yes |
| DB_PORT | PostgreSQL port | 5432 | Yes |
| DB_USERNAME | Database user | - | Yes |
| DB_DATABASE_NAME | Database name | - | Yes |
| DB_PASSWORD | Database password | - | Yes |
| REDIS_HOSTNAME | Redis host | - | Yes |
| UPLOAD_LOCATION | Upload directory | ./library | No |
| TZ | Timezone | Etc/UTC | No |

## Configuration

### Container Details

- **Images**:
  - `ghcr.io/immich-app/immich-server:release`
  - `ghcr.io/immich-app/immich-machine-learning:release-armnn`
- **Ports**:
  - Internal 2283 → External 2283 (web UI)
  - Internal 3003 (machine learning)
- **Volumes**:
  - `~/media/Photos:/usr/src/app/photos` - Photo library
  - `~/media/Photos/Immich:/usr/src/app/upload` - Upload directory
  - `model-cache:/cache` - ML model cache (named volume)
- **Devices**: Hardware acceleration devices (/dev/dri, /dev/rga, /dev/mali0, etc.)
- **Networks**: `pasta:--map-host-loopback,10.0.2.2` for shared services (Postgres, Redis on host loopback)

### Service Configuration

Immich uses a multi-container architecture:
- **immich-server**: Main application server with web UI and API
- **immich-machine-learning**: ML service for facial recognition and object detection
- **Shared Services**: Uses postgres-vector (PostgreSQL) and redis

### Architecture

Immich deployment uses specialized hardware acceleration for optimal performance:

#### Container Architecture
```
┌─────────────────────────────────────────┐
│           Immich Server (2283)          │
│  - Web UI and API                       │
│  - Photo/video processing               │
│  - Hardware-accelerated transcoding     │
└─────────────────────────────────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
┌─────────▼────────┐ ┌────────▼──────────┐
│   PostgreSQL     │ │      Redis        │
│   (shared DB)    │ │   (shared cache)  │
│                  │ │                   │
│ 10.0.2.2:5432    │ │  10.0.2.2:6379   │
└──────────────────┘ └───────────────────┘
          │
┌─────────┴─────────┐
│ Machine Learning  │
│ Service (3003)    │
│ - Facial recognition│
│ - Object detection │
│ - ML model cache   │
└───────────────────┘
```

#### Key Components
- **Immich Server**: Main application with hardware-accelerated media processing
- **Machine Learning**: AI service for advanced photo analysis features
- **Shared Database**: PostgreSQL for metadata and application data
- **Shared Cache**: Redis for session management and caching

#### Hardware Acceleration
Immich uses GPU acceleration for:
- Video transcoding and thumbnail generation
- Image processing and format conversion
- Machine learning inference for facial recognition
- Hardware-specific optimizations for ARM/Rockchip platforms

## Usage

### Accessing the Service

- **Local Access**: http://localhost:2283
- **Domain Access**: Direct access (no NGINX proxy configured)
- **API Endpoints**: RESTful API available for integrations

### Getting Started

1. **Initial Setup**
   - Access the web interface at http://localhost:2283
   - Create an admin account
   - Configure storage settings

2. **Upload Media**
   - Use mobile apps for automatic backup
   - Upload via web interface
   - Import from existing directories

3. **Configure Features**
   - Enable facial recognition
   - Set up object detection
   - Configure backup schedules
   - Set storage policies

### Command Line Operations

```bash
# Service management
podman ps | grep immich
podman logs immich-server
podman logs immich-machine-learning

# Container operations
podman exec -it immich-server /bin/bash

# Database operations (via postgres-vector)
podman exec postgres-vector psql -U immich immich
```

## Integration

### With Other Services

- **PostgreSQL**: Uses shared postgres-vector database
- **Redis**: Uses shared redis for caching and sessions
- **Mobile Apps**: Automatic backup from iOS/Android devices
- **External Storage**: Direct access to media directories

### API Integration

Immich provides comprehensive APIs for:
- **Media Upload**: Programmatic photo/video uploads
- **Library Management**: Album and asset management
- **Search**: Advanced search with ML-powered features
- **User Management**: Multi-user support and permissions

## Backup & Recovery

### Important Data to Backup

- **Database**: PostgreSQL data in postgres-vector (immich database)
- **Media Files**: `~/media/Photos/` - Original photo/video files
- **Upload Directory**: `~/media/Photos/Immich/` - Processed uploads
- **ML Models**: model-cache volume (regenerates if lost)

### Backup Commands

```bash
# Database backup
podman exec postgres-vector pg_dump -U immich immich > immich-db-backup.sql

# Media files backup
tar -czf immich-media-backup-$(date +%Y%m%d).tar.gz ~/media/Photos

# Full backup
podman exec postgres-vector pg_dump -U immich immich > immich-db-$(date +%Y%m%d).sql
tar -czf immich-full-backup-$(date +%Y%m%d).tar.gz ~/media/Photos
```

### Restore Commands

```bash
# Database restore
podman exec -i postgres-vector psql -U immich immich < immich-db-backup.sql

# Media files restore
tar -xzf immich-media-backup-YYYYMMDD.tar.gz

# Restart services
podman restart immich-server immich-machine-learning
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
podman ps | grep immich

# Web interface check
curl -I http://localhost:2283

# API health check
curl http://localhost:2283/api/server/ping

# Database connectivity
podman exec immich-server pg_isready -h 10.0.2.2 -p 5432 -U immich
```

### Logs

```bash
# Server logs
podman logs immich-server

# Machine learning logs
podman logs immich-machine-learning

# Recent errors
podman logs immich-server | grep -i error
```

### Common Issues

**Hardware Acceleration Issues**
- Symptoms: Slow transcoding, high CPU usage
- Cause: GPU devices not accessible or drivers missing
- Solution: Verify device passthrough and hardware acceleration setup

**Database Connection Issues**
- Symptoms: Application fails to start or shows DB errors
- Cause: PostgreSQL not running or connection misconfigured
- Solution: Check postgres-vector status and connection settings

**ML Service Issues**
- Symptoms: Facial recognition not working, object detection fails
- Cause: ML service not running or model cache issues
- Solution: Check ML service logs and restart if needed

**Storage Permission Issues**
- Symptoms: Cannot upload or access media files
- Cause: File permission issues with media directories
- Solution: Verify directory ownership and permissions

### Performance Tuning

- **Hardware Acceleration**: Ensure GPU drivers are properly configured
- **Database Tuning**: Monitor PostgreSQL performance
- **Storage**: Use fast storage for media files
- **ML Processing**: Balance ML features with system resources

## Security

- **Container Security**: Privileged containers for hardware access
- **Network Security**: No external exposure (localhost only)
- **Data Protection**: Local storage with encryption options
- **User Authentication**: Built-in user management and permissions

## System Resources

- **Memory**: 2-8GB depending on library size and ML processing
- **CPU**: Variable - GPU acceleration reduces CPU load significantly
- **Storage**: Media library size + ~10GB for ML models and cache
- **Network**: Variable based on upload/download activity

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/immich-app/immich-server:release
podman pull ghcr.io/immich-app/immich-machine-learning:release-armnn
podman restart immich-server immich-machine-learning
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clean ML model cache if needed
podman volume rm immich_model-cache  # This will force model re-download

# Database maintenance
podman exec postgres-vector psql -U immich immich -c "VACUUM ANALYZE;"
```

## Notes

- **Hardware Acceleration**: Complex privileged setup for GPU access and optimal performance
- **Machine Learning**: Resource-intensive ML features can be disabled if needed
- **Mobile Backup**: Primary use case is automatic backup from mobile devices
- **Shared Services**: Relies on postgres-vector and redis for data persistence

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
