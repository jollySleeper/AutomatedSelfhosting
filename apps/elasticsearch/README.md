# Elasticsearch

Elasticsearch is a distributed, RESTful search and analytics engine capable of addressing a growing number of use cases. It centrally stores your data for lightning-fast search, fine-tuned relevancy, and powerful analytics.

## Overview

Elasticsearch is a search engine based on the Lucene library. It provides a distributed, multitenant-capable full-text search engine with an HTTP web interface and schema-free JSON documents. Elasticsearch is developed alongside a data collection and log-parsing engine called Logstash, and an analytics and visualization platform called Kibana.

## Features

- **Full-Text Search**: Powerful full-text search capabilities with relevancy scoring
- **Real-time Analytics**: Near real-time search and analytics on structured and unstructured data
- **Distributed Architecture**: Horizontally scalable distributed system
- **RESTful API**: Complete REST API for data operations
- **Schema-free JSON**: Flexible document storage without predefined schemas
- **Multi-tenancy**: Support for multiple indexes and data isolation
- **Aggregations**: Advanced analytics and data aggregation capabilities
- **Geo-spatial Search**: Location-based search and filtering
- **Security Features**: Authentication, authorization, and encryption (disabled in this setup)

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern CPU
- **Dependencies**: Java runtime (included in container)
- **Network**: HTTP port 9200 (API), TCP port 9300 (cluster communication)
- **Storage**: Variable based on data volume (configured for in-memory only)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/elasticsearch
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/elasticsearch
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Root container (Elasticsearch requires root for JVM operations)
- **UID/GID**: Root user (0:0) required for Elasticsearch daemon
- **Volume Permissions**: No persistent volumes (in-memory configuration)
- **Security Notes**: Security features disabled for simplified deployment

### Configuration Files Modified

None - Elasticsearch uses environment variables for configuration.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| xpack.security.enabled | Enable security features | false | Yes |
| discovery.type | Cluster discovery mode | single-node | Yes |

## Configuration

### Container Details

- **Image**: `docker.io/library/elasticsearch:8.10.4`
- **Ports**:
  - 9200:9200 (HTTP API)
  - 9300:9300 (Cluster communication)
- **Volumes**: None (stateless, data stored in memory)
- **Memory**: 2GB limit configured
- **Networks**: Host networking for API access

### Service Configuration

Elasticsearch is configured for single-node development/testing:
- **Single Node**: No clustering, suitable for development
- **Security Disabled**: Simplified setup without authentication
- **Memory Limited**: 2GB RAM allocation for resource control
- **In-Memory Storage**: Data not persisted (lost on restart)

### Architecture

Elasticsearch runs as a single-node instance:

```
┌─────────────────┐
│   Applications  │
│   (Clients)     │
│                 │
│ • Logstash      │
│ • Kibana        │
│ • Custom Apps   │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Elasticsearch │    │   REST API       │
│   Single Node   │    │   (Port 9200)    │
│   Container     │    │                  │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   In-Memory     │
│   Data Storage  │
│   (No Persistence│
└─────────────────┘
```

#### Key Components
- **REST API**: HTTP interface for data operations and search
- **Lucene Engine**: Core search and indexing engine
- **Cluster Manager**: Node coordination and management
- **Index Manager**: Data indexing and storage management

## Usage

### Accessing the Service

- **REST API**: http://localhost:9200 (Elasticsearch API)
- **Cluster API**: http://localhost:9300 (internal cluster communication)

### Getting Started

1. **Check Cluster Health**
   ```bash
   curl -X GET "localhost:9200/_cluster/health?pretty"
   ```

2. **Create Index**
   ```bash
   curl -X PUT "localhost:9200/my-index"
   ```

3. **Index Document**
   ```bash
   curl -X POST "localhost:9200/my-index/_doc" \
        -H 'Content-Type: application/json' \
        -d '{"message": "Hello World"}'
   ```

4. **Search Documents**
   ```bash
   curl -X GET "localhost:9200/my-index/_search?q=message:Hello"
   ```

### Command Line Operations

```bash
# Service management
podman ps | grep elasticsearch
podman logs elasticsearch

# Container operations
podman exec -it elasticsearch /bin/bash

# Elasticsearch operations
curl -X GET "localhost:9200/_cat/indices"
curl -X GET "localhost:9200/_cluster/health"
```

## Integration

### With Other Services

- **Kibana**: Visualization and dashboard interface
- **Logstash**: Data collection and processing pipeline
- **Filebeat**: Lightweight log shipper
- **Application Clients**: Direct API integration

### API Integration

Elasticsearch provides comprehensive REST APIs for:
- **Document Operations**: CRUD operations on documents
- **Search Operations**: Full-text search and filtering
- **Index Management**: Create, delete, and manage indexes
- **Cluster Management**: Monitor cluster health and statistics
- **Aggregation Framework**: Advanced analytics and aggregations

## Backup & Recovery

### Important Data to Backup

Data is stored in-memory only in this configuration - no persistent data to backup.

### Backup Commands

```bash
# No persistent data to backup
# For persistent setup, backup data directory
```

### Restore Commands

```bash
# Restart service (no data to restore)
podman restart elasticsearch
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep elasticsearch

# Cluster health
curl -X GET "localhost:9200/_cluster/health?pretty"

# Node information
curl -X GET "localhost:9200/_nodes/_local"
```

### Logs

```bash
# Container logs
podman logs elasticsearch

# Elasticsearch logs (inside container)
podman exec elasticsearch tail -f /usr/share/elasticsearch/logs/elasticsearch.log
```

### Common Issues

**Memory Issues**
- Symptoms: Container killed due to OOM
- Cause: Insufficient memory allocation for data/indexing
- Solution: Increase container memory limits

**Port Conflicts**
- Symptoms: Container fails to start
- Cause: Ports 9200 or 9300 already in use
- Solution: Check port availability or change port mappings

**Indexing Failures**
- Symptoms: Documents not indexed or search failures
- Cause: Memory limits or resource constraints
- Solution: Monitor resource usage and adjust limits

### Performance Tuning

- **Memory Allocation**: Adjust JVM heap size for optimal performance
- **Index Settings**: Configure index settings for specific use cases
- **Query Optimization**: Optimize queries and use appropriate analyzers
- **Resource Limits**: Monitor and adjust container resource limits

## Security

- **Container Security**: Root container (required for Elasticsearch)
- **Network Security**: Local access only (no external exposure)
- **Data Protection**: No authentication (development setup)
- **API Security**: REST API accessible without authentication

## System Resources

- **Memory**: 2GB allocated (configurable)
- **CPU**: Variable based on indexing and search operations
- **Storage**: Minimal (in-memory storage)
- **Network**: Variable based on API usage and data operations

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/library/elasticsearch:8.10.4
podman restart elasticsearch
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear indexes (if needed)
curl -X DELETE "localhost:9200/_all"
```

## Notes

- **Single Node**: Configured for single-node operation (not clustered)
- **Security Disabled**: No authentication or encryption (development setup)
- **In-Memory**: Data not persisted (lost on restart)
- **Development Focus**: Suitable for testing and development, not production

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
