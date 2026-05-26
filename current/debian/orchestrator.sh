#!/bin/bash
ftinstall() {
mkdir scripts
curl -Lo scripts/checkall.sh -# https://raw.githubusercontent.com/thedistromaker/pteroinstall/script/current/debian/checkall.sh
curl -Lo scripts/installrepo.sh -# https://raw.githubusercontent.com/thedistromaker/pteroinstall/script/current/debian/installrepo.sh
curl -Lo scripts/installer.sh -# https://raw.githubusercontent.com/thedistromaker/pteroinstall/script/current/debian/installpkg.sh
curl -Lo scripts/panelinstall.sh -# https://raw.githubusercontent.com/thedistromaker/pteroinstall/script/current/debian/panelinstall.sh
curl -Lo scripts/configptero.sh -# https://raw.githubusercontent.com/thedistromaker/pteroinstall/script/current/debian/configptero.sh
chmod +x scripts/*
./scripts/checkall.sh || { echo "Failed to check all packages."; exit 0; } 
./scripts/installrepo.sh || { echo "Failed to install repos."; exit 0; } 
./scripts/installer.sh || { echo "Failed to run installer."; exit 0; }
./scripts/panelinstall.sh || { echo "Failed to install panel."; exit 0; }
./scripts/configptero.sh || { echo "Failed to configure ptero."; exit 0; }
echo ":: Finished setup. Download the orchestrator with pteroinstall's Orchestrator-Standalone script, and run orchestrator.sh wings-install on the Wings machines."
}

ftwings() {
echo "[IN] Enabling Docker..."
systemctl enable --now docker
echo "[IN] Downloading and Configuring Wings..."
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
tee /etc/systemd/system/wings.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
}

case $1 in
    panel-install)
        ftinstall
        ;;
    wings-install)
        ftwings
        ;;
    *)
        echo "$0 panel-install|wings-install"
        exit 1
        ;;
esac

