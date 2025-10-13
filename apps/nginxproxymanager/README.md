# Nginx Proxy Manager

Nginx Proxy Manager is a web-based interface for easily managing nginx reverse proxy configurations, SSL certificates, and proxy hosts.

## Overview

Nginx Proxy Manager provides a user-friendly web interface for managing nginx reverse proxy configurations without manually editing configuration files. It supports SSL certificate management, proxy host configuration, access lists, and custom nginx configurations through a modern web interface.

## Features

- **Web-based Management**: Modern web interface for nginx configuration
- **SSL Certificate Management**: Automatic Let's Encrypt SSL certificate generation
- **Proxy Host Configuration**: Easy setup of reverse proxy hosts
- **Access Control**: IP-based access lists and authentication
- **Custom Locations**: Advanced proxy location configuration
- **Real-time Configuration**: Live nginx configuration updates
- **Backup/Restore**: Configuration backup and restore capabilities
- **Docker Integration**: Optimized for containerized environments
- **Multiple Proxy Methods**: Support for HTTP, HTTPS, TCP, and UDP proxies

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: Ports 80, 443 (HTTP/HTTPS), port 8000 (web UI)
- **Storage**: ~100MB for configuration and certificates

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/nginxproxymanager
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/nginxproxymanager
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Root container (privileged for network access)
- **UID/GID**: Root user (0:0) required for nginx and certificate management
- **Volume Permissions**: Root access to configuration and certificate directories
- **Security Notes**: Privileged mode required for network binding and certificate management

### Configuration Files Modified

None - NPM manages its own nginx configuration internally.

### Environment Variables

NPM uses default configuration with no environment variables in this setup.

## Configuration

### Container Details

- **Image**: `docker.io/jc21/nginx-proxy-manager:latest`
- **Ports**:
  - 80:80 (HTTP traffic)
  - 443:443 (HTTPS traffic)
  - 8000:81 (Web dashboard)
- **Volumes**:
  - `volumes/data:/data` - Application data and database
  - `volumes/letsencrypt:/etc/letsencrypt` - SSL certificates
- **Networks**: pasta networking with gateway mapping

### Service Configuration

NPM runs with privileged networking:
- **Web Dashboard**: Port 8000 for management interface
- **HTTP/HTTPS Proxy**: Ports 80/443 for proxied traffic
- **SSL Management**: Let's Encrypt integration for certificates
- **Database**: SQLite for configuration storage

### Architecture

NPM provides a complete reverse proxy management solution:

```
┌─────────────────┐
│   User Browser  │
│                 │
│ management UI   │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   NPM Dashboard │    │   Nginx Proxy    │
│   (Port 8000)   │    │   Manager        │
│   Web Interface │    │   Container      │
└─────────────────┘    └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   SQLite DB      │
         │              │   Configuration  │
         │              │   /data          │
         │              └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Proxied Apps  │◄──►│   SSL Certs      │
│   Ports 80/443  │    │   Let's Encrypt  │
│                 │    │   /etc/letsencrypt│
└─────────────────┘    └──────────────────┘
```

#### Key Components
- **Web Dashboard**: Management interface for configuration
- **Nginx Engine**: Underlying nginx reverse proxy
- **SSL Manager**: Let's Encrypt certificate automation
- **Database**: SQLite for storing configuration data

## Usage

### Accessing the Service

- **Web Dashboard**: http://localhost:8000 (management interface)
- **Proxied Services**: Ports 80/443 for configured proxy hosts

### Getting Started

1. **Initial Setup**
   - Access the web dashboard at http://localhost:8000
   - Create admin account with username/email and password
   - Default credentials: admin@example.com / changeme

2. **Configure Proxy Hosts**
   - Add proxy hosts for your applications
   - Configure domain names and forwarding rules
   - Set up SSL certificates

3. **SSL Certificate Management**
   - Enable Let's Encrypt for automatic certificates
   - Configure DNS challenge validation
   - Monitor certificate renewal

### Command Line Operations

```bash
# Service management
podman ps | grep nginxproxymanager
podman logs nginxproxymanager

# Container operations
podman exec -it nginxproxymanager /bin/bash

# Database access (SQLite)
podman exec nginxproxymanager sqlite3 /data/database.sqlite
```

## Integration

### With Other Services

- **SSL Certificates**: Provides certificates for other services
- **Reverse Proxy**: Alternative to manual nginx configuration
- **Application Management**: Centralized proxy management

### API Integration

NPM provides a REST API for:
- **Host Management**: Create and manage proxy hosts
- **Certificate Management**: SSL certificate operations
- **Access Control**: Manage access lists and authentication
- **Configuration**: Programmatic configuration management

## Backup & Recovery

### Important Data to Backup

- **Database**: `volumes/data/` - Contains all configuration and certificates
- **SSL Certificates**: `volumes/letsencrypt/` - Let's Encrypt certificates
- **Nginx Config**: Generated nginx configuration files

### Backup Commands

```bash
# Full backup including certificates
tar -czf npm-backup-$(date +%Y%m%d).tar.gz volumes/

# Database backup
podman exec nginxproxymanager sqlite3 /data/database.sqlite .dump > npm-db-backup.sql
```

### Restore Commands

```bash
# Restore from backup
tar -xzf npm-backup-YYYYMMDD.tar.gz

# Database restore
podman exec -i nginxproxymanager sqlite3 /data/database.sqlite < npm-db-backup.sql

# Restart service
podman restart nginxproxymanager
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep nginxproxymanager

# Web interface check
curl -I http://localhost:8000

# Nginx status
podman exec nginxproxymanager nginx -t
```

### Logs

```bash
# Container logs
podman logs nginxproxymanager

# Nginx error logs
podman exec nginxproxymanager tail -f /var/log/nginx/error.log

# Application logs
podman exec nginxproxymanager tail -f /data/logs/*.log
```

### Common Issues

**Port Conflicts**
- Symptoms: Container fails to start with port binding errors
- Cause: Ports 80, 443, or 8000 already in use
- Solution: Check for conflicting services and free ports

**SSL Certificate Issues**
- Symptoms: HTTPS not working or certificate errors
- Cause: DNS validation failures or rate limiting
- Solution: Verify DNS configuration and Let's Encrypt limits

**Database Corruption**
- Symptoms: Configuration lost or interface not loading
- Cause: Improper shutdown or disk issues
- Solution: Restore from backup or recreate database

### Performance Tuning

- **Memory Limits**: Increase container memory for large configurations
- **SSL Performance**: Consider SSL session caching
- **Worker Processes**: Adjust nginx worker processes
- **Rate Limiting**: Configure request rate limiting

## Security

- **Container Security**: Root container (required for network binding)
- **Network Security**: Direct port exposure (consider firewall rules)
- **SSL Security**: Automatic certificate management
- **Access Control**: Web interface authentication required

## System Resources

- **Memory**: 256-512MB depending on configuration complexity
- **CPU**: Low baseline usage, spikes during certificate generation
- **Storage**: ~100MB for database and certificates
- **Network**: Minimal (primarily proxy traffic)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/jc21/nginx-proxy-manager:latest
podman restart nginxproxymanager
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clean expired certificates
podman exec nginxproxymanager find /etc/letsencrypt -name "*.pem" -mtime +90 -delete
```

## Notes

- **Alternative to Manual Config**: Provides web interface alternative to manual nginx configuration
- **SSL Automation**: Automatic certificate management with Let's Encrypt
- **Container Networking**: Uses pasta networking for host network access
- **Database Storage**: SQLite for simple, self-contained configuration

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
