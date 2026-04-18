# Open WebUI

Open WebUI is a self-hosted web interface for interacting with Large Language Models (LLMs). It provides a user-friendly chat interface with advanced features like document ingestion, conversation management, and integration with vector databases for Retrieval-Augmented Generation (RAG).

## Features

- **Web-based Chat Interface**: Clean, responsive UI for LLM interactions
- **Document Processing**: Upload and process documents for context-aware conversations
- **Vector Database Integration**: Connect to Qdrant for semantic search and RAG
- **Model Management**: Support for multiple LLM providers (OpenAI, Ollama, etc.)
- **Conversation History**: Persistent chat history and conversation management
- **User Authentication**: Built-in user management and authentication
- **API Access**: RESTful API for programmatic access

## Configuration

### Environment Variables
- **Port**: Runs on port 8888 internally (proxied through NGINX)
- **Data Volume**: `/app/backend/data` - stores user data, conversations, and configurations

### Vector Database Integration
Open WebUI can integrate with Qdrant for enhanced RAG capabilities:
- **Semantic Search**: Find relevant documents based on meaning, not just keywords
- **Document Chunking**: Automatically splits documents into manageable chunks
- **Embedding Storage**: Stores vector embeddings for efficient retrieval

## Usage

### Starting the Service
```bash
cd /home/legion/selfhost/apps/open-webui
./podman-setup.sh start
```

### Accessing the Interface
- **Local**: http://localhost:8888
- **Domain**: https://open-webui.aevion.lan (via NGINX reverse proxy)

### Basic Usage
1. Access the web interface
2. Configure your LLM provider (Ollama, OpenAI API, etc.)
3. Start chatting with your models
4. Upload documents for enhanced context (optional)

## Integration with Qdrant

When Qdrant is available, Open WebUI can:
- Store document embeddings for semantic search
- Provide context-aware responses using relevant document chunks
- Enable "chat with your documents" functionality

**Note**: Qdrant integration requires additional configuration in Open WebUI settings.

## System Requirements

- **Memory**: Minimum 2GB RAM recommended
- **Storage**: Variable based on conversation history and uploaded documents
- **Network**: Requires internet access for LLM API calls (if using external providers)

## Backup Considerations

Important data to backup:
- `/app/backend/data` volume containing:
  - User accounts and settings
  - Conversation history
  - Uploaded documents
  - Model configurations

## Troubleshooting

### Common Issues
- **Port conflicts**: Ensure port 8888 is available
- **Memory issues**: Monitor RAM usage during document processing
- **LLM connectivity**: Verify API keys and network connectivity for external LLM providers

### Logs
Check container logs for debugging:
```bash
podman logs open-webui
```

## Security Notes

- Default installation includes basic authentication
- Consider additional security measures for production use
- Regularly update the container image for security patches
