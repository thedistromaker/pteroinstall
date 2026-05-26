#!/bin/bash
# installrepo.sh
. /etc/os-release
DISTRO="${ID,,}"
VERSION="${VERSION_ID%%.*}"
CODENAME="${VERSION_CODENAME}"
export VERSION CODENAME DISTRO
if ! command -v lsb_release > /dev/null 2>&1; then
    read -p "Compulsory packages: lsb-release gpg. Install? (Y/n): " yeno
    case $yeno in
            [Yy])
                apt install lsb-release gpg -y
                ret=$?
                if [ $ret -ne 0 ]; then
                    echo "[!!] apt install lsb-release -y failed: code $ret."
                    exit 1
                fi
                ;;
            [Nn])
                echo "Aborted."
                exit 1
                ;;
            *)
                echo "$yeno - not y/n."
                exit 1
                ;;
    esac
fi
if [ -z "$VERSION" ]; then
    echo "[!!] Debian $CODENAME is not suitable for setup."
    exit 1
fi
# Retest, if apt succeeded to install.
if command -v lsb_release > /dev/null 2>&1; then
    echo "[OK] lsb_release installed successfully and tested."
else
    echo "[!!] apt failed to install lsb_release. Is the package correct and working?"
    exit 1
fi
# Add php 8.3 repo.
echo "[IN] Adding Sury PHP repo for 8.3..."
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Unable to write repo."
    exit 1
fi
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Unable to write repo key."
    exit 1
fi
echo "[OK] Added Sury PHP repo and key."
case $VERSION in
    11|12)
        echo "[IN] Adding Redis repo for Debian 11/12..."
        curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        ret=$?
        if [ $ret -ne 0 ]; then
            echo "[!!] Unable to write repo."
            exit 1
        fi
        echo "[OK] Added Redis repo."
        echo "[IN] Signing Redis repo with key..."
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
        ret=$?
        if [ $ret -ne 0 ]; then
            echo "[!!] Unable to write repo key."
            exit 1
        fi
        echo "[OK] Signed Redis repo."
        echo "[IN] Running MariaDB repo setup for Debian 11/12..."
        curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash
        ret=$?
        if [ $ret -ne 0 ]; then
            echo "[!!] Unable to set up MariaDB repo."
            exit 1
        fi
        echo "[OK] MariaDB repo set up."
        ;;
    13)
        echo "[IN] Skipping redis and mariadb repo setup, as Debian 13 already has them in standard repos."
        ;;
    *)
        echo "[!!] Debian $VERSION ($CODENAME) is too new or too old."
        exit 1
        ;;
esac
# Update global package index
echo "[IN] Updating global package index..."
apt update
ret=$?
if [ $ret -ne 0 ]; then
    echo "[!!] Unable to update repo."
    exit 1
fi
echo "[OK] Updated global package index."
# setuprepo end.
exit 0
