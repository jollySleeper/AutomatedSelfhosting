# cAdvisor

cAdvisor (Container Advisor) is a running daemon that collects, aggregates, processes, and exports information about running containers.

## Overview

cAdvisor provides container users an understanding of the resource usage and performance characteristics of their running containers. It is a daemon that collects, aggregates, processes, and exports information about running containers, specifically designed for the Kubernetes/Docker environments.

## Features

- **Container Metrics**: Collects CPU, memory, network, and disk usage statistics
- **Real-time Monitoring**: Live container resource usage monitoring
- **Prometheus Integration**: Exports metrics in Prometheus format
- **Docker Support**: Native Docker container monitoring
- **Filesystem Monitoring**: Container filesystem usage tracking
- **Network Statistics**: Container network I/O monitoring
- **Hardware Metrics**: Host system resource monitoring
- **Web Interface**: Built-in web UI for metrics visualization

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, Linux kernel with cgroups
- **Dependencies**: Docker/Podman socket access, privileged container access
- **Network**: HTTP port 9091 (web UI and metrics)
- **Storage**: Minimal (metrics data is ephemeral)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/cadvisor
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/cadvisor
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Privileged root container for system access
- **UID/GID**: Root user (0:0) required for system monitoring
- **Volume Permissions**: Read-only access to system directories and Podman socket
- **Security Notes**: Privileged mode required for comprehensive system monitoring

### Configuration Files Modified

None - cAdvisor uses command-line arguments for configuration.

### Environment Variables

cAdvisor uses command-line arguments instead of environment variables.

## Configuration

### Container Details

- **Image**: `gcr.io/cadvisor/cadvisor:v0.50.0`
- **Ports**: Internal 8080 → External 9091 (web UI and metrics)
- **Volumes**:
  - `/:/rootfs:ro` - Root filesystem access
  - `/sys:/sys:ro` - System information
  - `/dev/disk/:/dev/disk:ro` - Disk device information
  - `/run/user/1001/podman:/var/run/podman:ro` - Podman socket
  - `~/.local/share/containers/:/var/lib/containers:ro` - Container storage
- **Devices**: `/dev/kmsg` - Kernel message buffer
- **Networks**: Host networking for socket access

### Service Configuration

cAdvisor is configured for comprehensive container monitoring:
- **Podman Integration**: Direct access to Podman socket for container data
- **System Monitoring**: Host system resource monitoring
- **Metrics Export**: Prometheus-compatible metrics endpoint
- **Web Interface**: Built-in UI for real-time monitoring

### Architecture

cAdvisor monitors containers through direct system access:

```
┌─────────────────┐
│   cAdvisor Web  │
│   Interface     │
│   Port 9091     │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   cAdvisor      │
│   Container     │
│   (Privileged)  │
└─────────────────┘
         │
    ┌────┼────┐
    │         │
┌───▼──┐ ┌────▼────┐
│ Podman│ │ System  │
│ Socket│ │ Metrics │
│       │ │         │
│ /var/ │ │ /sys    │
│ run/  │ │ /proc   │
│ podman│ │         │
└───────┘ └─────────┘
```

#### Key Components
- **Metrics Collector**: Collects container and system metrics
- **Web Interface**: Real-time metrics visualization
- **Prometheus Exporter**: Metrics export for monitoring systems
- **Container Integration**: Direct Podman/Docker integration

## Usage

### Accessing the Service

- **Web Interface**: http://localhost:9091 (metrics dashboard)
- **Metrics Endpoint**: http://localhost:9091/metrics (Prometheus format)

### Getting Started

1. **View Metrics**
   - Access the web interface at http://localhost:9091
   - Browse running containers and their resource usage
   - View historical metrics and trends

2. **Container Monitoring**
   - Monitor CPU, memory, and network usage per container
   - Track disk I/O and filesystem usage
   - View container lifecycle events

3. **System Monitoring**
   - Host system resource utilization
   - Container runtime statistics
   - Network interface monitoring

### Command Line Operations

```bash
# Service management
podman ps | grep cadvisor
podman logs cadvisor

# Metrics access
curl http://localhost:9091/metrics

# Container inspection
podman exec -it cadvisor /bin/sh
```

## Integration

### With Other Services

- **Prometheus**: Primary metrics collection target
- **Grafana**: Dashboard visualization for cAdvisor metrics
- **Monitoring Stack**: Part of container monitoring infrastructure

### API Integration

cAdvisor provides:
- **Prometheus Metrics**: Standard Prometheus exposition format
- **REST API**: Container and system metrics via HTTP
- **Web Interface**: Real-time metrics visualization

## Backup & Recovery

### Important Data to Backup

cAdvisor is stateless - no persistent data to backup. Metrics are ephemeral.

### Backup Commands

```bash
# No persistent data to backup
```

### Restore Commands

```bash
# Restart service (no data to restore)
podman restart cadvisor
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep cadvisor

# Web interface check
curl -I http://localhost:9091

# Metrics endpoint check
curl -s http://localhost:9091/metrics | head -10
```

### Logs

```bash
# Container logs
podman logs cadvisor

# Recent errors
podman logs cadvisor | grep -i error
```

### Common Issues

**Socket Access Issues**
- Symptoms: No container metrics or socket connection errors
- Cause: Podman socket permissions or path issues
- Solution: Verify socket path and container user permissions

**Privileged Access Issues**
- Symptoms: Missing system metrics or device access errors
- Cause: Insufficient privileges for system monitoring
- Solution: Ensure privileged mode and device access

**Metrics Collection Issues**
- Symptoms: Empty metrics or missing container data
- Cause: Container runtime issues or socket problems
- Solution: Check Podman socket and container runtime

### Performance Tuning

- **Collection Interval**: Adjust housekeeping interval for data granularity
- **Resource Limits**: Monitor container resource usage
- **Retention**: Consider external storage for long-term metrics

## Security

- **Container Security**: Privileged root container for system access
- **Network Security**: Local access only (no external exposure)
- **Data Protection**: Ephemeral metrics data
- **Socket Security**: Podman socket access for container monitoring

## System Resources

- **Memory**: 100-300MB depending on number of containers
- **CPU**: Low baseline, variable during metric collection
- **Storage**: Minimal (no persistent storage)
- **Network**: Minimal (local metrics access)

## Maintenance

### Updates

```bash
# Check for updates
podman pull gcr.io/cadvisor/cadvisor:v0.50.0

# Restart with new image
podman restart cadvisor
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats cadvisor
```

## Notes

- **Container Runtime Integration**: Direct integration with Podman/Docker
- **System-level Monitoring**: Requires privileged access for comprehensive metrics
- **Prometheus Compatible**: Standard metrics export for monitoring systems
- **Real-time Data**: Focus on current and recent container performance

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
