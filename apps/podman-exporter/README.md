# Podman Exporter

Podman Exporter is a Prometheus exporter that collects metrics from Podman containers and exposes them in Prometheus format.

## Overview

Podman Exporter monitors Podman container runtime and provides detailed metrics about container status, resource usage, and performance. It integrates with Prometheus to provide comprehensive container monitoring alongside system metrics.

## Features

- **Container Metrics**: CPU, memory, network, and block I/O statistics
- **Container Status**: Running, stopped, paused container counts
- **Podman Runtime**: Podman daemon and runtime metrics
- **Image Metrics**: Container image information and usage
- **Volume Metrics**: Named volume usage and statistics
- **Network Metrics**: Container network interface statistics
- **Prometheus Compatible**: Standard Prometheus exposition format
- **Real-time Updates**: Live container metric collection

## Prerequisites

- **System Requirements**: Podman runtime installed and running
- **Dependencies**: Access to Podman socket and user session
- **Network**: HTTP port 9882 (metrics endpoint)
- **Storage**: Minimal (reads container runtime information)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/podman-exporter
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/podman-exporter
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with user namespace mapping
- **UID/GID**: nobody user (65534) with keep-id mapping
- **Volume Permissions**: Access to Podman socket
- **Security Notes**: User namespace isolation with socket access

### Configuration Files Modified

None - Podman Exporter uses environment variables and socket access.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| CONTAINER_HOST | Podman socket URL | unix:///run/podman/podman.sock | Yes |

## Configuration

### Container Details

- **Image**: `quay.io/navidys/prometheus-podman-exporter:v1.10.1`
- **Ports**: Internal 9882 → External 9882 (localhost)
- **Volumes**: Podman socket for container access
- **Networks**: plain pasta (scraped by Prometheus via published port; reads Podman socket via mounted volume, not network)

### Service Configuration

Podman Exporter is configured for comprehensive container monitoring:
- **Podman Socket**: Direct access to Podman runtime
- **User Session**: Access to user Podman session
- **Keep-ID Mapping**: User namespace compatibility
- **Security Labels**: Disabled for socket access

### Architecture

Podman Exporter monitors containers through the Podman socket:

```
┌─────────────────┐
│   Prometheus    │
│   (Port 9090)   │
│                 │
│ scrape_configs: │
│   - targets:     │
│     ['10.0.2.2:9882']
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│ Podman Exporter │    │   Podman Socket  │
│   (Port 9882)   │◄──►│   /run/podman/   │
│   Container     │    │   podman.sock    │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Container     │
│   Runtime       │
│                 │
│ • Container     │
│   Stats         │
│ • Image Info    │
│ • Volume Stats  │
│ • Network I/O   │
└─────────────────┘
```

#### Key Components
- **Metrics Collector**: Collects Podman container metrics
- **Podman Socket**: Direct communication with Podman daemon
- **Prometheus Exporter**: HTTP endpoint serving metrics
- **Container Integration**: Real-time container monitoring

## Usage

### Accessing the Service

- **Metrics Endpoint**: http://localhost:9882/metrics (Prometheus format)
- **No Web Interface**: Command-line access only

### Getting Started

1. **Metrics Collection**
   - Podman Exporter starts automatically and collects metrics
   - Access metrics at http://localhost:9882/metrics
   - Prometheus scrapes metrics automatically

2. **Available Metrics**
   - Container CPU and memory usage
   - Network I/O statistics
   - Block I/O statistics
   - Container status and counts
   - Image and volume information

3. **Integration with Prometheus**
   - Automatically configured in Prometheus scrape targets
   - Metrics appear in Grafana dashboards
   - Used for container monitoring and alerting

### Command Line Operations

```bash
# Service management
podman ps | grep podman-exporter
podman logs podman-exporter

# Check metrics endpoint
curl http://localhost:9882/metrics | head -20

# Check available metrics
curl "http://localhost:9882/metrics" | grep -o "podman_[a-zA-Z_]*" | sort | uniq
```

## Integration

### With Other Services

- **Prometheus**: Primary consumer of Podman metrics
- **Grafana**: Visualization of container metrics
- **cAdvisor**: Complements with additional container metrics
- **Podman**: Direct integration with container runtime

### API Integration

Podman Exporter provides metrics via HTTP endpoint:
- **Metrics Endpoint**: `/metrics` - Prometheus exposition format
- **Health Checks**: Basic HTTP health checks

## Backup & Recovery

### Important Data to Backup

No persistent data - Podman Exporter is stateless and reads live container information.

### Backup Commands

```bash
# No persistent data to backup
```

### Restore Commands

```bash
# Restart service (no data to restore)
podman restart podman-exporter
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep podman-exporter

# Metrics endpoint check
curl -s http://localhost:9882/metrics | head -5

# Prometheus target status
curl "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.labels.job == "podman-exporter")'
```

### Logs

```bash
# Container logs
podman logs podman-exporter

# Recent errors
podman logs podman-exporter | grep -i error
```

### Common Issues

**Socket Access Issues**
- Symptoms: No metrics or socket connection errors
- Cause: Podman socket permissions or path issues
- Solution: Verify socket path and user permissions

**Container Access Issues**
- Symptoms: Missing container metrics
- Cause: User namespace or socket access problems
- Solution: Check user namespace configuration

**Metrics Collection Issues**
- Symptoms: Empty metrics or missing container data
- Cause: Podman daemon issues or socket problems
- Solution: Verify Podman daemon status and socket access

### Performance Tuning

- **Collection Interval**: Adjust Prometheus scrape intervals
- **Resource Limits**: Monitor container resource usage
- **Metrics Filtering**: Focus on relevant container metrics

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (no external exposure)
- **Socket Security**: Podman socket access for container monitoring
- **User Namespace**: Isolated user environment

## System Resources

- **Memory**: 20-50MB typical usage
- **CPU**: Low baseline usage, minimal system impact
- **Storage**: Minimal (reads container runtime information)
- **Network**: Minimal (local metrics serving)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull quay.io/navidys/prometheus-podman-exporter:v1.10.1
podman restart podman-exporter
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats podman-exporter
```

## Notes

- **Podman Specific**: Designed specifically for Podman container runtime
- **User Session**: Access to user Podman session for comprehensive monitoring
- **Prometheus Integration**: Standard exporter in Prometheus ecosystem
- **Real-time Metrics**: Live container performance monitoring

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
