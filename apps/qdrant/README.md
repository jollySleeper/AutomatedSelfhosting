# Qdrant

Qdrant is a high-performance vector database designed for storing and searching vector embeddings. It's optimized for semantic search, recommendation systems, and Retrieval-Augmented Generation (RAG) applications, providing efficient similarity search with various distance metrics.

## Overview

Qdrant is a vector similarity search engine that provides a production-ready service with a convenient API to store, search, and manage points (vectors) with an additional payload. It's designed to work with any type of data that can be represented as dense vectors, making it ideal for AI/ML applications requiring fast similarity search.

## Features

- **Vector Search**: Efficient similarity search using Cosine, Euclidean, and Dot product metrics
- **High Performance**: Optimized for low-latency vector operations with HNSW indexing
- **Scalability**: Horizontal scaling with sharding and replication support
- **RESTful API**: Simple HTTP API for all operations, plus gRPC support
- **Multiple Data Types**: Support for dense and sparse vectors
- **Payload Storage**: Store additional metadata with vectors
- **Real-time Updates**: Support for real-time vector updates and deletes
- **Backup/Restore**: Built-in backup and restore functionality
- **Filtering**: Complex filtering support for payload-based queries
- **Web Dashboard**: Built-in web interface for management and exploration

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, recommended 2GB+ for production use
- **Dependencies**: None (standalone vector database)
- **Network**: HTTP port 6333 (REST API), gRPC port 6334
- **Storage**: Variable based on vector count and dimensions (current: ~4.6MB)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/qdrant
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/qdrant
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: User namespace mapping for file access
- **Volume Permissions**: Data persistence in container volumes
- **Security Notes**: Local access only, no authentication by default

### Configuration Files Modified

None - Qdrant uses default configuration.

### Environment Variables

None - Qdrant uses default configuration.

## Configuration

### Container Details

- **Image**: `docker.io/qdrant/qdrant:latest`
- **Ports**:
  - 6333:6333 (HTTP REST API)
  - 6334:6334 (gRPC API)
- **Volumes**: Data persistence in container storage
- **Networks**: Host networking for direct API access

### Service Configuration

Qdrant is configured for standalone vector database operation:
- **Web Dashboard**: Built-in management interface
- **HNSW Indexing**: High-performance vector indexing
- **Real-time Operations**: Support for live updates and queries
- **Data Persistence**: Automatic data persistence and recovery

### Architecture

Qdrant provides efficient vector similarity search:

```
┌─────────────────┐    ┌──────────────────┐
│   Applications  │    │   Qdrant Vector  │
│   (AI/ML)       │    │   Database       │
│                 │◄──►│   (Ports 6333/4) │
│ • Open WebUI    │    ├──────────────────┤
│ • RAG Systems   │    │ Collections      │
│ • Search Apps   │    │ • Vectors        │
│                 │    │ • Payloads       │
└─────────────────┘    │ • Indexes        │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   HNSW Index     │
                       │   (Similarity    │
                       │   Search)        │
                       └──────────────────┘
```

#### Key Components
- **Vector Engine**: Core similarity search with multiple distance metrics
- **HNSW Index**: Hierarchical Navigable Small World for fast approximate search
- **Collection Manager**: Organize vectors into named collections
- **Payload Storage**: Metadata storage alongside vectors

## Usage

### Accessing the Service

- **REST API**: http://localhost:6333 (HTTP API)
- **gRPC API**: localhost:6334 (gRPC interface)
- **Web Dashboard**: http://localhost:6333/dashboard (built-in management UI)

### Getting Started

1. **Check Service Health**
   ```bash
   curl http://localhost:6333/health
   ```

2. **Access Dashboard**
   - Open http://localhost:6333/dashboard in your browser
   - View collections and manage vectors through web interface

3. **Basic API Operations**
   ```bash
   # List collections
   curl http://localhost:6333/collections

   # Create a collection
   curl -X PUT http://localhost:6333/collections/my-collection \
     -H "Content-Type: application/json" \
     -d '{
       "vectors": {
         "size": 768,
         "distance": "Cosine"
       }
     }'

   # Add vectors with payload
   curl -X PUT http://localhost:6333/collections/my-collection/points \
     -H "Content-Type: application/json" \
     -d '{
       "points": [{
         "id": 1,
         "vector": [0.1, 0.2, 0.3],
         "payload": {"text": "example document"}
       }]
     }'

   # Search similar vectors
   curl -X POST http://localhost:6333/collections/my-collection/points/search \
     -H "Content-Type: application/json" \
     -d '{
       "vector": [0.1, 0.2, 0.3],
       "limit": 10
     }'
   ```

### Command Line Operations

```bash
# Service management
podman ps | grep qdrant
podman logs qdrant

# Container operations
podman exec -it qdrant /bin/bash
```

## Integration

### With Other Services

- **Open WebUI**: RAG functionality for document-based chat
- **AI Applications**: Vector storage for semantic search and recommendations
- **LLM Services**: Context retrieval for Retrieval-Augmented Generation
- **Embedding Models**: Store and search text/image embeddings

### API Integration

Qdrant provides comprehensive APIs for vector operations:
- **REST API**: Full HTTP interface for all operations
- **gRPC API**: High-performance binary protocol
- **Client Libraries**: Official SDKs for Python, JavaScript, Rust, Go
- **Bulk Operations**: Batch vector insertion and updates

#### Open WebUI Integration

Qdrant integrates with Open WebUI for RAG functionality:
- **Document Storage**: Embeddings of uploaded documents
- **Semantic Search**: Context retrieval for LLM responses
- **Workspace Collections**: Organized vector storage per workspace
- **Real-time Updates**: Live document indexing and updates

To configure integration:
1. Start both Qdrant and Open WebUI services
2. Configure Open WebUI to connect to Qdrant at `http://qdrant:6333`
3. Upload documents to populate the vector database

## Backup & Recovery

### Important Data to Backup

- **Collections**: Vector data and associated payloads
- **Indexes**: HNSW indexes for fast similarity search
- **Configuration**: Collection settings and metadata
- **Snapshots**: Point-in-time backups for disaster recovery

### Backup Commands

```bash
# Create collection snapshot
curl -X POST http://localhost:6333/collections/my-collection/snapshots/my-snapshot

# List available snapshots
curl http://localhost:6333/collections/my-collection/snapshots

# Download snapshot (if remote storage configured)
curl http://localhost:6333/collections/my-collection/snapshots/my-snapshot
```

### Restore Commands

```bash
# Restore from snapshot
curl -X POST http://localhost:6333/collections/my-collection/snapshots/my-snapshot/restore

# Full collection restore
curl -X PUT http://localhost:6333/collections/my-collection \
  -H "Content-Type: application/json" \
  -d @snapshot_data.json
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service health
curl http://localhost:6333/health

# Collection info
curl http://localhost:6333/collections/my-collection

# Cluster status (if in cluster mode)
curl http://localhost:6333/cluster
```

### Logs

```bash
# Container logs
podman logs qdrant

# Recent errors
podman logs qdrant | grep -i error

# Follow logs
podman logs -f qdrant
```

### Common Issues

**High Memory Usage**
- Symptoms: Container using excessive RAM
- Cause: Large datasets or high `ef_construct` values
- Solution: Reduce indexing parameters, enable memory mapping

**Slow Search Performance**
- Symptoms: Queries taking too long
- Cause: Low `ef` parameter or disk I/O bottlenecks
- Solution: Increase `ef` parameter, optimize storage

**Connection Issues**
- Symptoms: API calls failing
- Cause: Port conflicts or network issues
- Solution: Check port availability, verify networking

**Vector Dimension Mismatches**
- Symptoms: Insertion failures with dimension errors
- Cause: Inconsistent vector sizes in collection
- Solution: Verify vector dimensions match collection configuration

### Performance Tuning

- **Memory Configuration**: Adjust `memmap_threshold` for large datasets
- **Indexing Parameters**: Tune M, ef_construct, ef for performance vs accuracy
- **Storage Optimization**: Use SSD storage for better I/O performance
- **Batch Operations**: Use bulk APIs for efficient data operations

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (no external exposure by default)
- **API Security**: No authentication enabled (consider for production)
- **Data Protection**: Vector data stored locally, backup security

## System Resources

- **Memory**: 512MB-4GB depending on dataset size and operations
- **CPU**: Benefits from multiple cores for parallel processing
- **Storage**: Variable based on vector count and dimensions (current: ~4.6MB)
- **Network**: Low usage (API calls and data transfer only)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/qdrant/qdrant:latest
podman restart qdrant
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Monitor disk usage
podman exec qdrant du -sh /qdrant/storage
```

## Notes

- **Vector Database**: Specialized for AI/ML similarity search operations
- **HNSW Indexing**: High-performance approximate nearest neighbor search
- **Open WebUI Integration**: Powers RAG functionality for document chat
- **Collection-based**: Organize vectors into logical collections
- **Real-time Operations**: Support for live updates and queries

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
