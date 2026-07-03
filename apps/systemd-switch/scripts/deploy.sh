#!/bin/bash
set -e

SERVER="legion@aevion"

echo "🚀 Deploying Service Control Panel to $SERVER using official install script..."

# Copy our custom configurations to server
echo "📁 Copying custom configuration files..."
scp environments/local.env "$SERVER:~/"
scp systemd/systemd-switch.service "$SERVER:~/.config/systemd/user/systemd-switch.service"
scp nginx/sites/systemd-switch.conf "$SERVER:~/systemd-switch.conf"

# Run the official install script directly on the server
echo "⬇️ Running official SysDwitch install script on server..."
ssh "$SERVER" "
    # Run the official install script from the repository
    curl -s https://raw.githubusercontent.com/jollySleeper/SysDwitch/main/scripts/install.sh | bash

    # Override with our pre-built binary (skip Go compilation)
    curl -L -o ~/selfhost/apps/systemd-switch/sysdwitch https://github.com/jollySleeper/SysDwitch/releases/latest/download/sysdwitch-linux-amd64
    chmod +x ~/selfhost/apps/systemd-switch/sysdwitch

    # Override with our custom configurations
    cp ~/local.env ~/selfhost/apps/systemd-switch/configs/environments/local.env 2>/dev/null || true

    # Setup nginx with our custom config
    sudo cp ~/systemd-switch.conf /etc/nginx/sites-available/systemd-switch.conf
    sudo ln -sf /etc/nginx/sites-available/systemd-switch.conf /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx

    # Reload and start our custom service
    systemctl --user daemon-reload
    systemctl --user enable systemd-switch
    systemctl --user start systemd-switch
"

echo "✅ Deployment complete!"
echo ""
echo "🔐 Admin credentials: ADMIN_USER / ADMIN_PASS from environments/local.env"
echo "🌐 Access at: http://sysdwitch.aevion.lan:1080"
echo "📊 Check status: systemctl --user status systemd-switch"
