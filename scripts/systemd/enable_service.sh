#!/bin/bash

cd ~
mkdir -p .config/systemd/user
cd .config/systemd/user
# enables services on boot
loginctl enable-linger
echo "Disabling Old Service"
systemctl --user disable --now selfhost.service
echo "SymLinking The File"
ln -s ~/selfhost/selfhost.service .
echo "Starting The Service Now"
systemctl --user enable --now selfhost.service
echo "Sleeping 5s"
sleep 5
systemctl --user status selfhost.service
