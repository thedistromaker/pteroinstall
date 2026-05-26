#!/bin/bash
# checkall.sh
. /etc/os-release
DISTRO="${ID,,}"
VERSION="${VERSION_ID%%.*}"
[ -e ".basic.missing" ] && rm -rf -- .basic.missing
[ -e ".ext.missing" ] && rm -rf -- .ext.missing
[ -e ".phpfpm.missing" ] && rm -rf -- .phpfpm.missing
[ -e ".php.missing" ] && rm -rf -- .php.missing
commands=(
    php8.3
    mariadb-server
    nginx
    tar
    unzip
    git
    redis-server
    docker
    gpg
    lsb_release
    crontab
)
php_exts=(
    gd
    mysqli
    mbstring
    bcmath
    xml
    curl
    zip
)
PHP_BIN="php8.3"
PHP_FPM="php-fpm8.3"
echo ":: distro"
echo "$PRETTY_NAME"
echo
echo ":: basic"
for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        case "$cmd" in
            lsb_release)
                pr=lsb-release
                ;;
            docker)
                pr=docker.io
                ;;
            crontab)
                pr=anacron
                ;;
            *)
                pr=$cmd
                ;;
        esac
        echo "[OK] $pr"
    else
        case "$cmd" in
            lsb_release)
                pr=lsb-release
                ;;
            docker)
                pr=docker.io
                ;;
            crontab)
                pr=anacron
                ;;
            *)
                pr=$cmd
                ;;
        esac
        echo "[!!] $pr" | tee -a .basic.missing
    fi
done

echo
echo ":: php-extensions"
if ! command -v "$PHP_BIN" >/dev/null 2>&1; then
    echo "[!!] PHP missing"
    touch .ext.missing
    touch .php.missing
    tee .ext.missing > /dev/null << 'EOF'
[!!] php8.3-common
[!!] php8.3-cli
[!!] php8.3-gd
[!!] php8.3-mysql
[!!] php8.3-mbstring
[!!] php8.3-bcmath
[!!] php8.3-xml
[!!] php8.3-fpm
[!!] php8.3-curl
[!!] php8.3-zip
EOF
else
    for ext in "${php_exts[@]}"; do
        if "$PHP_BIN" -m | grep -qi "^$ext$"; then
            echo "[OK] php8.3-$ext"
        else
            echo "[!!] php8.3-$ext" | tee -a .ext.missing
        fi
    done
fi
echo
echo ":: php-fpm"
if command -v "$PHP_FPM" >/dev/null 2>&1; then
    echo "[OK] $PHP_FPM"
else
    echo "[!!] $PHP_FPM"
    touch .phpfpm.missing
fi
echo
echo ":: composer"
if command -v "composer" >/dev/null 2>&1; then
    echo "[OK] composer"
else
    echo "[!!] composer"
    touch .composer.missing
fi

if [ -e ".phpfpm.missing" ]; then
    PHPFPM=0 # No fpm
fi
if [ -e ".basic.missing" ]; then
    BASIC=0 # No basic tools
fi
if [ -e ".ext.missing" ]; then
    PHPEXT=0 # Not full php
fi
if [ -e ".php.missing" ]; then
    PHP=0 # No php
fi
if [ -e ".composer.missing" ]; then
    COMPOSER=0 # No composer
fi
export PHPFPM BASIC PHPEXT PHP COMPOSER # Set it for installer.
export VERSION # Set it for pkgsetup.sh.
exit 0
