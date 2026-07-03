# SystemD Switch (SysDwitch) Setup

This directory contains the configuration for deploying SysDwitch - a web-based control panel for managing systemd user services.

## Files Overview

- `environments/local.env` - Configuration with admin credentials and allowed services
- `systemd/service-control.service` - Systemd user service configuration
- `nginx/sites/service-control.conf` - Nginx reverse proxy configuration (HTTP on port 1080)
- `scripts/deploy.sh` - Deployment script to copy files to server and set up services

## Quick Setup

1. **Update Configuration**: Edit `environments/local.env` with your admin credentials
2. **Deploy**: Run `./scripts/deploy.sh` to deploy to the server
3. **Access**: Visit `http://sysdwitch.aevion.lan:1080` (or other configured domains)

## Configuration

### Environment Variables (local.env)
```bash
ADMIN_USER=admin                    # Admin username
ADMIN_PASS=secure_password_change_this  # Admin password (CHANGE THIS!)
ALLOWED_SERVICES=calibre,jellyfin,navidrome  # Comma-separated service names
HOST=127.0.0.1                     # Server bind address
PORT=8081                          # Server port
LOG_LEVEL=info                     # Logging level
```

### Security Notes
- The service uses HTTP Basic Authentication
- Only specified services in `ALLOWED_SERVICES` can be controlled
- No external HTTPS required (internal LAN access only)
- Authentication protects against unauthorized service management

## Usage

After deployment:
1. Visit `http://service-control.aevion.lan:1080`
2. Login with admin credentials
3. Click Start/Stop buttons to control services
4. Status updates automatically every 30 seconds

## Troubleshooting

### Service Won't Start
```bash
# Check service status
systemctl --user status service-control

# View logs
journalctl --user -u service-control -f
```

### Permission Issues
Ensure the user can run `systemctl --user` commands for the specified services.

### Nginx Issues
```bash
# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Binary Location

The SysDwitch binary should be placed at:
`~/selfhost/apps/systemd-switch/sysdwitch`

Download from: https://github.com/jollySleeper/SysDwitch/releases
