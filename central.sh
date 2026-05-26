#!/bin/bash
# main.sh
if [ $EUID -ne 0 ]; then
    echo "[!!] This script must be run as root to continue."
    exit 1
fi
. /etc/os-release
DISTRO="${ID,,}"
VERSION="${VERSION_ID%%.*}"
CODENAME="${VERSION_CODENAME}"
export VERSION CODENAME DISTRO
case $1 in
    -F)
        echo "[!!] -F is not enough to override. Please use -FF."
        exit 1
        ;;
    -FF)
        read -p "[WW] -FF forces unstable installs (eg Fedora 43). Do you wish to continue?" yeno
        case $yeno in
            [Yy])
                echo "Continuing..."
                ;;
            [Nn])
                echo "Aborted."
                exit 0
                ;;
            *)
                echo "$yeno - not y/n."
                exit 1
                ;;
        esac
        ;;
esac
[ -e "tr.sh" ] && rm -rf -- tr.sh
[ -e "main.sh" ] && rm -rf -- main.sh
case $DISTRO in
    debian)
        if command -v curl; then
            curl -LOJ -# https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/debian/orchestrator.sh # Main support.
            ret=$?
            if [ $ret -ne 0 ]; then
                echo "[!!] Failed to download https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/debian/orchestrator.sh as orchestrator.sh."
                exit 1
            fi
            mv orchestrator.sh tr.sh
        else
            echo "[!!] Install curl to continue."
            exit 1
        fi
        ;;
    centos)
        if command -v curl; then
            curl -LOJ -# https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/centos7/orchestrator.sh # We will stop supporting updates for this soon.
            ret=$?
            if [ $ret -ne 0 ]; then
                echo "[!!] Failed to download https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/centos7/orchestrator.sh as orchestrator.sh."
                exit 1
            fi
            mv orchestrator.sh tr.sh
        else
            echo "[!!] Install curl to continue."
            exit 1
        fi
        ;;
    rocky|rhel)
        case $VERSION in
            8)
                ver=8
                ;;
            9)
                ver=9
                ;;
            10)
                ver=10 # EXPERIMENTAL: EL10 may not work.
                ;;
            *)
                echo "[!!] Version $VERSION is too new or is nonexistent."
                exit 1
                ;;
        esac
        if command -v curl; then
            curl -LOJ -# https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/el/$ver/orchestrator.sh # Alt support (slow updates).
            ret=$?
            if [ $ret -ne 0 ]; then
                echo "[!!] Failed to download https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/el/$ver/orchestrator.sh as orchestrator.sh."
                exit 1
            fi
            mv orchestrator.sh tr.sh
        else
            echo "[!!] Install curl to continue."
            exit 1
        fi
        ;;
    fedora)
        case $VERSION in
            40)
                ver=40
                ;;
            41)
                ver=41
                ;;
            42)
                ver=42 # EXPERIMENTAL: FS42 may not work.
                ;;
            43)
                if [ "$FORCEFULINSTALL" -eq 1 ]; then
                    echo "[WW] Version 43 is too new for a stable Pterodactyl install. Continuing as per your wishes..."
                else
                    echo "[!!] Version 43 is too new for a stable Pterodactyl install. To continue, pass -FF to forcefully use FS43."
                    exit 1
                fi
                ver=43
                ;;
            44)
                echo "[!!] Version 44 is too new for any packages, and is not tested. Please use FS43 or FS42."
                echo "[NT] You cannot override this message, there is no orchestrator for FS44. Please use FS43 or switch to Development fetch, where there is NO STABILITY GUARANTEE."
                exit 1
                ;;
            *)
                echo "[!!] Version $VERSION is too new or is nonexistent."
                exit 1
                ;;
        esac
        if command -v curl; then
            curl -LOJ -# https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/centos7/orchestrator.sh # Alt support (slow updates).
            ret=$?
            if [ $ret -ne 0 ]; then
                echo "[!!] Failed to download https://cdn.jsdelivr.net/gh/thedistromaker/pteroinstall@script/current/fedora/$ver/orchestrator.sh as orchestrator.sh."
                exit 1
            fi
            mv orchestrator.sh tr.sh
        else
            echo "[!!] Install curl to continue."
            exit 1
        fi
        ;;
esac
# pre-exec
rm -- "$0"
mv tr.sh main.sh
chmod +x main.sh
# exec
exec ./main.sh panel-install
