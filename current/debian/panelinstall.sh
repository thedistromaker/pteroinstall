#!/bin/bash
# panelinstall.sh
echo "[IN] Making Pterodactyl panel dir..."
install -vdm755 /var/www/pterodactyl
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to create /var/www/pterodactyl. Check logs for more info. Code: $ret."
    exit 1
else
    echo "[OK] Made directory /var/www/pterodactyl."
fi
cd /var/www/pterodactyl
echo "[IN] Downloading panel..."
curl -Lo panel.tar.gz -# https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to download panel.tar.gz. Check logs for more info. Code: $ret."
    exit 1
else
    echo "[OK] Downloaded panel.tar.gz."
fi
echo "[IN] Extracting panel..."
tar -xzf panel.tar.gz
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to extract panel.tar.gz. Check logs for more info. Code: $ret."
    exit 1
else
    echo "[OK] Extracted panel.tar.gz."
fi
echo "[IN] Chmod'ding storage/* and bootstrap/cache/..."
chmod -R 755 storage/* bootstrap/cache/
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to chmod. Check logs for more info. Code: $ret."
    exit 1
else
    echo "[OK] Chmod'ded successfully."
fi
exit 0
