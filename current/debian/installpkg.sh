#!/bin/bash
# installer.sh

if [ -n $PHP ]; then
    echo "[IN] Installing php..."
    ap install -y php8.3 > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "[!!] Failed to install php8.3. Check logs for more info. Code: $ret."
        exit 1
    else
        echo "[OK] Installed php8.3."
    fi
fi
if [ -n $BASIC ]; then
    echo "[IN] Installing basic commands..."
    cat .basic.missing | cut -c 6- | xargs ap install -y > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "[!!] Failed to install basic commands. Check logs for more info. Code: $ret."
        exit 1
    else
        echo "[OK] Installed basic commands."
    fi
fi
if [ -n $PHPEXT ]; then
    echo "[IN] Installing PHP extensions..."
    cat .ext.missing | cut -c 6- | xargs ap install -y > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "[!!] Failed to install PHP extensions. Check logs for more info. Code: $ret."
        exit 1
    else
        echo "[OK] Installed PHP extensions."
    fi
fi
if [ -n $PHPFPM ]; then
    echo "[IN] Installing php-fpm..."
    ap install -y php8.3-fpm > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "[!!] Failed to install php-fpm. Check logs for more info. Code: $ret."
        exit 1
    else
        echo "[OK] Installed php-fpm."
    fi
fi
if [ -n $COMPOSER ]; then
    echo "[IN] Downloading PHP Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer  > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "[!!] Failed to install Composer. Check logs for more info. Code: $ret."
        exit 1
    else
        echo "[OK] Installed Composer."
    fi
fi
exit 0
