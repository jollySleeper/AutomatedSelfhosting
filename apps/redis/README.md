# Redis

Redis is an open-source, in-memory data structure store used as a database, cache, and message broker.

## Overview

Redis (REmote DIctionary Server) is a high-performance key-value database that supports various data structures like strings, hashes, lists, sets, and more. It can be used as a cache, session store, message queue, or primary database for applications requiring fast data access.

## Features

- **In-Memory Storage**: Extremely fast data access with memory-based storage
- **Data Structures**: Support for strings, hashes, lists, sets, sorted sets, bitmaps, and more
- **Persistence**: Optional disk persistence with RDB snapshots and AOF logging
- **Pub/Sub**: Built-in publish/subscribe messaging system
- **Lua Scripting**: Server-side scripting with Lua
- **Clustering**: Horizontal scaling with Redis Cluster (not configured in this setup)

## Prerequisites

- **System Requirements**: Minimum 256MB RAM (more for data storage)
- **Dependencies**: None (standalone service)
- **Network**: TCP port 6379 for Redis protocol
- **Storage**: Minimal (primarily in-memory, optional persistence)

## Installation & Deployment

### Quick Deploy

```bash
cd /home/legion/selfhost/apps/redis
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd /home/legion/selfhost/apps/redis
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with root user (container runs as root internally)
- **UID/GID**: Container runs as root (0:0) for Redis server access
- **Volume Permissions**: No persistent volumes required (in-memory by default)
- **Security Notes**: Runs as root due to Redis requirement for privileged operations, network isolated via pasta

### Configuration Files Modified

None - Redis runs with default configuration optimized for containerized deployment.

### Environment Variables

Redis uses default configuration with no environment variables configured in this setup.

## Configuration

### Container Details

- **Image**: `docker.io/valkey/valkey:alpine` (Valkey, Redis fork)
- **Ports**: Internal 6379 → External 6379 (localhost)
- **Volumes**: None (in-memory storage)
- **Networks**: plain pasta (server-only — receives connections from other containers, doesn't initiate to host services)

### Service Configuration

Redis runs with Alpine Linux optimized defaults:
- **Memory Management**: No memory limits (uses available container memory)
- **Persistence**: Disabled (in-memory only, data lost on restart)
- **Security**: No authentication configured (accessible only via localhost)
- **Logging**: Basic logging to stdout

## Usage

### Accessing the Service

- **Redis Protocol**: redis://localhost:6379
- **No Web Interface**: Command-line access only

### Getting Started

1. **Connect via redis-cli**
   ```bash
   podman exec -it redis redis-cli
   ```

2. **Basic Operations**
   ```bash
   # Set a key-value pair
   SET mykey "Hello World"

   # Get a value
   GET mykey

   # Check server info
   INFO
   ```

3. **Integration with Applications**
   - Configure applications to connect to `redis://localhost:6379`
   - Used by services like Open WebUI for session management

### Command Line Operations

```bash
# Service management
systemctl --user status redis
systemctl --user restart redis

# Container operations
podman logs redis
podman exec -it redis redis-cli

# Redis operations
podman exec -it redis redis-cli PING
podman exec -it redis redis-cli INFO
```

## Integration

### With Other Services

- **Open WebUI**: Session storage and caching
- **Other Applications**: Generic Redis integration for caching, sessions, queues

### API Integration

Redis provides:
- **TCP Protocol**: Direct Redis protocol connections
- **No HTTP API**: Raw protocol access only
- **Client Libraries**: Available for all major programming languages

## Backup & Recovery

### Important Data to Backup

Redis runs in-memory only in this configuration - no persistent data to backup. Data is lost on container restart.

### Backup Commands

```bash
# No persistent data to backup
# For persistent Redis, configure RDB/AOF persistence
```

### Restore Commands

```bash
# No persistent data to restore
# Restart service to get fresh Redis instance
systemctl --user restart redis
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active redis

# Container status
podman ps | grep redis

# Redis connectivity
podman exec redis redis-cli PING
```

### Logs

```bash
# View recent logs
podman logs --tail 50 redis

# Follow logs
podman logs -f redis
```

### Common Issues

**Connection Refused**
- Symptoms: Applications can't connect to Redis
- Cause: Container not running or port not accessible
- Solution: Check service status and container logs

**Permission Issues (Rootless)**
- Symptoms: Container fails to start with permission errors
- Cause: Redis requires root privileges for network binding
- Solution: Container is correctly configured to run as root

**Memory Issues**
- Symptoms: Container killed due to OOM
- Cause: Redis using too much memory without limits
- Solution: Monitor memory usage and consider memory limits

### Performance Tuning

- **Memory Limits**: Consider adding memory limits for production use
- **Persistence**: Enable RDB snapshots for data persistence if needed
- **Connection Pooling**: Use connection pooling in applications to reduce overhead

## Security

- **Container Security**: Rootless container with network isolation
- **Network Security**: Only accessible via localhost, no external exposure
- **Data Protection**: No authentication (localhost-only access)
- **Access Control**: Network-level isolation via Podman networking

## System Resources

- **Memory**: 50MB - 2GB+ depending on data stored (currently minimal usage)
- **CPU**: Low baseline usage, spikes during operations
- **Storage**: Minimal (no persistent storage)
- **Network**: Low network usage (localhost connections only)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/valkey/valkey:alpine
systemctl --user restart redis
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check memory usage
podman stats redis
```

## Notes

- **In-Memory Only**: Data is lost when container restarts - suitable for cache/session storage
- **Valkey Fork**: Uses Valkey (Redis fork) instead of official Redis for licensing reasons
- **No Persistence**: Configure RDB/AOF if persistent storage is needed
- **Single Instance**: No clustering configured - suitable for development/testing

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
