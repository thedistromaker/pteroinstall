#!/bin/bash
# configptero.sh

cd /var/www/pterodactyl
echo "[IN] Starting MariaDB setup..."
read -s -p "[IN] Enter your Pterodactyl user password (remember this!): " DB_PASS
mariadb -u root <<EOF > /dev/null 2>&1
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to set up MariaDB."
    exit 1
else
    echo "[OK] Set up MariaDB properly."
fi
echo "[IN] Copying example .env to .env..."
cp .env.example .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to set up .env."
    exit 1
else
    echo "[OK] Copied .env."
fi
echo "[IN] Starting Composer install..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader > /dev/null 2>&1
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to set up Composer."
    exit 1
else
    echo "[OK] Set up and installed Composer."
fi
echo "[IN] Running Artisan key gen..."
php artisan key:generate --force 
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to generate app key."
    exit 1
else
    echo "[OK] Generated app key."
fi
echo "[IN] Running Artisan env setup..."
sed -i "s/^DB_HOST=.*/DB_HOST=127.0.0.1/" .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to configure Artisan env [1/5]."
    exit 1
else
    echo "[OK] Configured [1/5]."
fi
sed -i "s/^DB_PORT=.*/DB_PORT=3306/" .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to configure Artisan env [2/5]."
    exit 1
else
    echo "[OK] Configured [2/5]."
fi
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=panel/" .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to configure Artisan env [3/5]."
    exit 1
else
    echo "[OK] Configured [3/5]."
fi
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to configure Artisan env [4/5]."
    exit 1
else
    echo "[OK] Configured [4/5]."
fi
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" .env
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to configure Artisan env [5/5]."
    exit 1
else
    echo "[OK] Configured [5/5]."
fi
echo "[IN] Adding aux configs..."
read -p "[CFG] What APP_URL should be set (eg localhost, 192.168.1.x, https://example.com, yourdomain, etc): " APPURL
TIMEZONE=$(readlink -f /etc/localtime | sed 's|.*/zoneinfo/||')
echo "[IN] Verifying config:"
echo "[CFG] URL=$APP_URL"
echo "[CFG] Timezone: $TIMEZONE"
echo "[CFG] Cache Driver: redis"
echo "[CFG] Session Driver: redis"
echo "[CFG] Queue Connection: redis"
sed -i "s|^APP_URL=.*|APP_URL=$APPURL|" .env
sed -i "s|^APP_TIMEZONE=.*|APP_TIMEZONE=Europe/London|" .env
sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env
echo "[IN] Seeding Artisan env..."
php artisan migrate --seed --force
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to seed new Artisan env variables."
    exit 1
else
    echo "[OK] Seeded Artisan env."
fi
echo "[IN] Checking and writing crontab..."
CRON_LINE='* * * * * www-data /usr/bin/php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1'
grep -Fxq "$CRON_LINE" /etc/crontab || echo "$CRON_LINE" >> /etc/crontab
echo "[OK] Written to crontab."
echo "[IN] Writing systemd pteroq service file..."
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to write pteroq.service at /etc/systemd/system/pteroq.service."
    exit 1
else
    echo "[OK] Wrote pteroq.service."
fi
echo "[IN] Enabling redis-server..."
systemctl enable --now redis-server
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to start redis-server."
    exit 1
else
    echo "[OK] Started redis-server."
fi
echo "[IN] Enabling pteroq..."
systemctl enable --now pteroq
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to start pteroq."
    exit 1
else
    echo "[OK] Started pteroq."
fi
echo "[IN] Clearing old nginx defaults..."
[ -e /etc/nginx/sites-enabled/default ] && rm -fr /etc/nginx/sites-enabled/default
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to delete old config from /etc/nginx/sites-enabled/default."
    exit 1
else
    echo "[OK] Deleted old config."
fi
echo "[IN] Writing nginx config..."
cat <<EOF > /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name $APPURL;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \\.php$ {
        fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;

        fastcgi_param PHP_VALUE "upload_max_filesize=100M \\n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;

        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;

        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\\.ht {
        deny all;
    }
}
EOF
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to write new config to /etc/nginx/sites-available/pteroadctyl.conf."
    exit 1
else
    echo "[OK] Deleted old config."
fi
echo "[IN] Writing symlink to pterodactyl.conf..."
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to write symlink to /etc/nginx/sites-enabled/pteroadctyl.conf."
    exit 1
else
    echo "[OK] Symlinked config."
fi
echo "[IN] Restarting nginx..."
systemctl restart nginx
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Failed to restart nginx"
    echo "[NT] Logs:"
    journalctl -xeu nginx.service
    systemctl status nginx
    exit 1
else
    echo "[OK] Restarted nginx."
fi
exit 0
