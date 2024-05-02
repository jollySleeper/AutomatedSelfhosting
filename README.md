# Automated Selfhosting
Selfhosting made easy.

## SystemD Service
Service for Running all the apps/containers on system boot.
All the containers in `apps` folder will start on startup.

### Enabling Service
Just run this command to enable a userspace SystemD service.
```bash
./selfhost/scripts/systemd/enable_service.sh
```

### Running Service
Once Enabled the SystemD Service will automatically start on system's boot.
To manually run the service script check `selfhost/scripts/systemd/service.sh`
