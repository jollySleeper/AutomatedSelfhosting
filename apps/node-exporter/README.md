# Node Exporter

Node Exporter is a Prometheus exporter that collects hardware and OS metrics exposed by *NIX kernels.

## Overview

Node Exporter exposes a wide variety of hardware and kernel-related metrics for Prometheus monitoring. It provides detailed system-level metrics including CPU usage, memory statistics, disk I/O, network statistics, and filesystem information.

## Features

- **System Metrics**: CPU, memory, disk, and network statistics
- **Hardware Monitoring**: Temperature sensors, fan speeds, voltage levels
- **Filesystem Metrics**: Disk usage, inode usage, mount points
- **Network Metrics**: Interface statistics, TCP/UDP connections
- **Process Metrics**: System process information
- **Prometheus Compatible**: Standard Prometheus exposition format
- **Configurable Collectors**: Enable/disable specific metric collectors
- **Low Resource Usage**: Minimal system impact

## Prerequisites

- **System Requirements**: Linux kernel with procfs and sysfs
- **Dependencies**: None (runs as container with host access)
- **Network**: HTTP port 9100 (metrics endpoint)
- **Storage**: Minimal (reads host system information)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/node-exporter
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/node-exporter
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Privileged root container for system access
- **UID/GID**: Root user (0:0) required for system monitoring
- **Volume Permissions**: Read-only access to host filesystem
- **Security Notes**: Host PID namespace and network access for comprehensive monitoring

### Configuration Files Modified

None - Node Exporter uses command-line arguments.

### Environment Variables

Node Exporter uses command-line arguments instead of environment variables.

## Configuration

### Container Details

- **Image**: `quay.io/prometheus/node-exporter:latest`
- **Ports**: Host network (port 9100 exposed)
- **Volumes**: `/:/host:ro,rslave` - Host filesystem access
- **Networks**: Host networking for metrics access
- **PID**: Host PID namespace for process monitoring

### Service Configuration

Node Exporter is configured for comprehensive system monitoring:
- **Root Filesystem Path**: /host for host system access
- **All Collectors Enabled**: Default configuration with all metrics
- **Host Network**: Direct access on port 9100
- **Host PID**: Process monitoring across host PID namespace

### Architecture

Node Exporter monitors the host system directly:

```
┌─────────────────┐
│   Prometheus    │
│   (Port 9090)   │
│                 │
│ scrape_configs: │
│   - targets:     │
│     ['10.0.2.2:9100']
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Node Exporter │    │   Host System     │
│   (Port 9100)   │◄──►│   Metrics         │
│   Container     │    │                  │
│   (Privileged)  │    │ • CPU Usage       │
└─────────────────┘    │ • Memory Stats    │
                       │ • Disk I/O        │
                       │ • Network I/O     │
                       │ • Filesystem      │
                       │ • Hardware        │
                       └──────────────────┘
```

#### Key Components
- **Metrics Collector**: Collects system and hardware metrics
- **Prometheus Exporter**: HTTP endpoint serving metrics
- **Host Access**: Direct access to host system information
- **Collector Modules**: Individual metric collection modules

## Usage

### Accessing the Service

- **Metrics Endpoint**: http://localhost:9100/metrics (Prometheus format)
- **No Web Interface**: Command-line access only

### Getting Started

1. **Metrics Collection**
   - Node Exporter starts automatically and begins collecting metrics
   - Access metrics at http://localhost:9100/metrics
   - Prometheus scrapes metrics automatically

2. **Available Metrics**
   - CPU usage and utilization
   - Memory and swap statistics
   - Disk I/O and filesystem usage
   - Network interface statistics
   - System load and uptime
   - Hardware sensors (temperature, etc.)

3. **Integration with Prometheus**
   - Automatically configured in Prometheus scrape targets
   - Metrics appear in Grafana dashboards
   - Used for system monitoring and alerting

### Command Line Operations

```bash
# Service management
podman ps | grep node-exporter
podman logs node-exporter

# Check metrics endpoint
curl http://localhost:9100/metrics | head -20

# Check available collectors
curl "http://localhost:9100/metrics" | grep -o "node_[a-zA-Z_]*" | sort | uniq
```

## Integration

### With Other Services

- **Prometheus**: Primary consumer of node metrics
- **Grafana**: Visualization of system metrics
- **Alertmanager**: Alerting on system conditions

### API Integration

Node Exporter provides metrics via HTTP endpoint:
- **Metrics Endpoint**: `/metrics` - Prometheus exposition format
- **Health Checks**: Basic HTTP health checks
- **Collector Information**: Available collectors and their status

## Backup & Recovery

### Important Data to Backup

No persistent data - Node Exporter is stateless and reads live system information.

### Backup Commands

```bash
# No persistent data to backup
```

### Restore Commands

```bash
# Restart service (no data to restore)
podman restart node-exporter
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep node-exporter

# Metrics endpoint check
curl -s http://localhost:9100/metrics | head -5

# Prometheus target status
curl "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.labels.job == "node-exporter")'
```

### Logs

```bash
# Container logs
podman logs node-exporter

# Recent errors
podman logs node-exporter | grep -i error
```

### Common Issues

**Metrics Not Available**
- Symptoms: No metrics returned from endpoint
- Cause: Host filesystem access issues or permissions
- Solution: Check container privileges and volume mounts

**Container Access Issues**
- Symptoms: Cannot access host system information
- Cause: Insufficient privileges or namespace issues
- Solution: Verify privileged mode and host access

**Network Access Issues**
- Symptoms: Prometheus cannot scrape metrics
- Cause: Network configuration or firewall blocking
- Solution: Check network connectivity and firewall rules

### Performance Tuning

- **Collector Selection**: Disable unused collectors to reduce overhead
- **Scrape Intervals**: Adjust Prometheus scrape intervals appropriately
- **Resource Limits**: Monitor container resource usage

## Security

- **Container Security**: Privileged root container (required for system access)
- **Network Security**: Local access only (no external exposure)
- **Data Protection**: Read-only access to system information
- **Access Control**: No authentication (local network only)

## System Resources

- **Memory**: 20-50MB typical usage
- **CPU**: Low baseline usage, minimal system impact
- **Storage**: Minimal (reads host system information)
- **Network**: Minimal (local metrics serving)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull quay.io/prometheus/node-exporter:latest
podman restart node-exporter
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats node-exporter
```

## Notes

- **Host System Access**: Requires privileged access for comprehensive monitoring
- **Prometheus Standard**: Widely used exporter in Prometheus ecosystem
- **Hardware Metrics**: Includes temperature and sensor data where available
- **Filesystem Monitoring**: Monitors all mounted filesystems

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
