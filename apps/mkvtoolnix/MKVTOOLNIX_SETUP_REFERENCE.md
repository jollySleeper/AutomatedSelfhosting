# MKVToolNix Setup Reference Guide

This document provides a comprehensive reference for setting up MKVToolNix as a self-hosted service with systemd-switch integration. Use this as a template for installing other applications.

## 📋 Table of Contents

- [Phase 1: Initial App Setup](#-phase-1-initial-app-setup)
- [Phase 2: Documentation](#-phase-2-documentation)
- [Phase 3: SystemD Switch Integration](#-phase-3-systemd-switch-integration)
- [Phase 4: Deployment & Testing](#-phase-4-deployment--testing)
- [Phase 5: Script & Rules Refinement](#-phase-5-script--rules-refinement)
- [Phase 6: Final Testing & Verification](#-phase-6-final-testing--verification)
- [Quick Reference for New Apps](#-quick-reference-for-new-apps)

---

## 🎯 Phase 1: Initial App Setup

### 1. Create App Directory Structure

```bash
cd ~/selfhost/apps/
mkdir -p mkvtoolnix/environments
```

### 2. Create Core Files

#### `mkvtoolnix.container` (Quadlet systemd service file)

```ini
[Unit]
Description=MKVToolNix - Matroska file manipulation GUI
Documentation=https://github.com/jlesage/docker-mkvtoolnix

[Container]
AutoUpdate=registry
ContainerName=mkvtoolnix
EnvironmentFile=%h/selfhost/apps/mkvtoolnix/environments/local.env
Image=docker.io/jlesage/mkvtoolnix:latest
PublishPort=5800:5800
Volume=%h/selfhost/apps/mkvtoolnix/volumes/config:/config
Volume=%h/media:/storage

[Service]
# Restart=always  # Disabled for on-demand usage - uncomment to restore auto-restart

[Install]
WantedBy=default.target
```

#### `environments/local.env` (Environment variables)

```bash
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
DARK_MODE=1
```

#### `podman-setup.sh` (Installation script)

```bash
#!/bin/bash

source ../../scripts/common.sh

NAME="mkvtoolnix"
IMAGE_SOURCE="docker.io/jlesage/$NAME:latest"
PORT="5800"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --replace \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p $PORT:5800 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media":/storage \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
```

---

## 🎯 Phase 2: Documentation

### Create Comprehensive README.md

Include the following sections:

- **Overview**: App purpose and features
- **Prerequisites**: System requirements
- **Installation**: Quick deploy + manual steps
- **Configuration**: Environment variables table
- **Usage**: Accessing service + command line operations
- **Integration**: How it works with other services
- **Backup & Recovery**: Data backup procedures
- **Monitoring**: Health checks and troubleshooting
- **Security**: Container security considerations
- **Maintenance**: Updates and cleanup

---

## 🎯 Phase 3: SystemD Switch Integration

### Add to ALLOWED_SERVICES

Edit `apps/systemd-switch/environments/local.env`:

```bash
ALLOWED_SERVICES=calibre,firefox,mkvtoolnix
```

### Deploy SystemD Switch Updates

```bash
# Copy updated config to server
scp apps/systemd-switch/environments/local.env legion@aevion:~/local.env

# Update server config and restart service
ssh legion@aevion "cp ~/local.env ~/selfhost/apps/systemd-switch/environments/local.env && systemctl --user restart systemd-switch"
```

---

## 🎯 Phase 4: Deployment & Testing

### Deploy to Server

```bash
# Copy all files to server
scp apps/mkvtoolnix/podman-setup.sh legion@aevion:~/selfhost/apps/mkvtoolnix/
scp apps/mkvtoolnix/environments/local.env legion@aevion:~/selfhost/apps/mkvtoolnix/environments/
scp apps/mkvtoolnix/mkvtoolnix.container legion@aevion:~/selfhost/apps/mkvtoolnix/

# Run setup script
ssh legion@aevion "cd ~/selfhost/apps/mkvtoolnix && ./podman-setup.sh"
```

### Verification Steps

```bash
# Check systemd service
ssh legion@aevion "systemctl --user status mkvtoolnix.service --no-pager"

# Check systemd-switch interface
ssh legion@aevion "curl -s -u admin:password http://127.0.0.1:8081/ | grep mkvtoolnix"

# Verify environment variables
ssh legion@aevion "podman exec mkvtoolnix env | grep -E '(DISPLAY_WIDTH|DARK_MODE)'"
```

---

## 🎯 Phase 5: Script & Rules Refinement

### Updated Project Rules

#### Deployment Guidelines
- **Script-Based Deployment (Required)**: Always modify `podman-setup.sh` scripts and run them - quadlet files are auto-generated
- **Scripts Generate Quadlets**: Running `podman-setup.sh` automatically creates/updates `.container` quadlet files
- **Quadlet Files Are Generated**: Never edit `.container` files directly - they are output from scripts

#### Contribution Guidelines
- **Script-Driven Development**: Edit `podman-setup.sh` scripts - they generate quadlet files automatically
- **Quadlets Are Generated**: Never create/edit `.container` files manually - run scripts to generate them
- **Scripts Handle Everything**: `podman-setup.sh` manages container creation, quadlet generation, and systemd setup

#### Service Structure Requirements
```
apps/new-service/
├── *.container              # AUTO-GENERATED: Podman quadlet (don't edit directly)
├── podman-setup.sh         # Service installation script (edit this)
├── environments/
│   ├── sample.env          # Template environment variables
│   └── local.env           # Local configuration (gitignored)
├── configs/                # Service-specific configurations
└── README.md               # Setup and usage documentation
```

**Important**: Edit `podman-setup.sh` and run it to generate `.container` files automatically.

### Script Best Practices

- ✅ **Environment-driven**: Use `--env-file` instead of hardcoded `-e` flags
- ✅ **Quadlet generation**: Scripts generate systemd services automatically
- ✅ **Clean separation**: Scripts handle everything, quadlets are output
- ✅ **On-demand restart**: Disable `Restart=always` for systemd-switch compatibility

---

## 🎯 Phase 6: Final Testing & Verification

### Complete Workflow Test

1. **SystemD Switch**: Start/stop service via web interface ✅
2. **Service Persistence**: Manual stop = stays stopped ✅
3. **Environment Loading**: Variables properly loaded from files ✅
4. **Documentation**: All procedures documented ✅

---

## 🚀 Quick Reference for New Apps

### Essential Files to Create

1. **`app-name.container`** (with commented restart for on-demand)
2. **`environments/local.env`** (environment variables)
3. **`podman-setup.sh`** (with `--env-file` flag)
4. **`README.md`** (comprehensive documentation)

### Key Commands

```bash
# Deploy app
cd ~/selfhost/apps/app-name && ./podman-setup.sh

# Add to systemd-switch
echo "app-name" >> apps/systemd-switch/environments/local.env

# Deploy systemd-switch updates
scp apps/systemd-switch/environments/local.env server:~/local.env
ssh server "cp ~/local.env ~/selfhost/apps/systemd-switch/environments/local.env && systemctl --user restart systemd-switch"
```

### Success Criteria

- ✅ Service appears in SystemD Switch
- ✅ Start/stop controls work properly
- ✅ No unwanted auto-restarts
- ✅ Environment variables loaded correctly
- ✅ Documentation complete and accurate

---

## 📝 Notes

- **Script-First Philosophy**: Always edit scripts, run them to generate quadlets
- **On-Demand Services**: Comment out `Restart=always` for systemd-switch compatibility
- **Environment Variables**: Use `--env-file` instead of individual `-e` flags
- **Documentation**: Comprehensive README.md is essential for maintenance
- **Testing**: Always test locally before server deployment

This process ensures **consistent, maintainable, and well-documented** app deployments!

---

*Last updated: November 8, 2025*
*Reference for: MKVToolNix setup with systemd-switch integration*
