# [Service Name]

[Brief one-sentence description of what the service does]

## Overview

[Detailed description of the service, its purpose, and key features]

## Features

- **Feature 1**: Description
- **Feature 2**: Description
- **Feature 3**: Description

## Prerequisites

- **System Requirements**: Minimum hardware requirements
- **Dependencies**: Other services or software required
- **Network**: Required network access or ports
- **Storage**: Disk space requirements

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/[service-name]
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/[service-name]
   ```

2. **Configure Environment (if needed)**
   ```bash
   # Environment variable setup if applicable
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: [Rootless with root user | Rootless with non-root user]
- **UID/GID**: [User ID and Group ID used]
- **Volume Permissions**: [How volume permissions were handled - e.g., "Pre-initialized with correct permissions", "Uses temporary container for permission setup", "Runs as root user"]
- **Security Notes**: [Any specific security considerations for this container]

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/[service-name].conf` - Reverse proxy configuration for domain access
- **[Other files]**: What was changed and why

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| VAR1 | Description | default | Yes/No |
| VAR2 | Description | default | Yes/No |

## Configuration

### Container Details

- **Image**: Container image used
- **Ports**: Internal port → External port (localhost)
- **Volumes**: Data persistence mounts
- **Networks**: `pasta` (plain) or `pasta:--map-host-loopback,10.0.2.2` if the container needs to reach host services bound to `127.0.0.1`. See [`docs/DNS_ARCHITECTURE.md`](./DNS_ARCHITECTURE.md) and [`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md).

### Service Configuration

[Detailed configuration options, config files, and settings]

### Architecture

[Optional: Architecture diagram, container relationships, data flow, etc.]

## Usage

### Accessing the Service

- **Local Access**: http://localhost:[port]
- **Domain Access**: https://[service-name].aevion.lan
- **API Endpoints**: Available API endpoints (if applicable)

### Getting Started

1. Basic setup and configuration steps
2. Common usage patterns
3. Integration with other services

### Command Line Operations

```bash
# Service management
systemctl --user status [service-name]
systemctl --user restart [service-name]

# Container operations
podman logs [service-name]
podman exec -it [service-name] /bin/bash
```

## Integration

### With Other Services

- **Service 1**: How this integrates and why
- **NGINX Proxy**: Reverse proxy configuration for secure access

### API Integration

[Details about API usage, authentication, and external integrations]

## Backup & Recovery

### Important Data to Backup

- **Configuration**: [What config files/data to backup]
- **Data Volumes**: [Volume directories containing persistent data]
- **Databases**: [Database backup procedures if applicable]

### Backup Commands

```bash
# Example backup procedures
tar -czf [service-name]-backup-$(date +%Y%m%d).tar.gz [directories/volumes]
```

### Restore Commands

```bash
# Example restore procedures
tar -xzf [service-name]-backup-YYYYMMDD.tar.gz
systemctl --user restart [service-name]
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active [service-name]

# Container status
podman ps | grep [service-name]

# Web interface check
curl -I http://localhost:[port]
```

### Logs

```bash
# View recent logs
podman logs --tail 50 [service-name]

# Follow logs
podman logs -f [service-name]
```

### Common Issues

**Issue 1**
- Symptoms: [What you see when the problem occurs]
- Cause: [Why it happens]
- Solution: [How to fix it]

**Permission Issues (Rootless)**
- Symptoms: [Access denied errors, file permission problems]
- Cause: [Container running with different UID/GID than volume ownership]
- Solution: [Fix permission commands or reconfigure container user]

### Performance Tuning

[Service-specific performance optimization tips]

## Security

- **Container Security**: [Rootless mode, user permissions, etc.]
- **Network Security**: [Reverse proxy protection, access controls]
- **Data Protection**: [Encryption, backup security]

## System Resources

- **Memory**: Typical memory usage
- **CPU**: CPU requirements
- **Storage**: Storage requirements and growth
- **Network**: Network usage patterns

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull [image-name]
systemctl --user restart [service-name]
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Service-specific cleanup
```

## Notes

[Any additional important information, known issues, or special considerations]

---

*Last updated: [Date]*
*Deployed on: [hostname] (aevion.lan)*
