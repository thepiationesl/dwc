#!/usr/bin/env bash
# Windows ISO download and installation

set -Eeuo pipefail

STORAGE=""
DISK_SIZE=""
VERSION=""
LANGUAGE=""
BOOT=""
CUSTOM=""

initInstallConfig() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "$SCRIPT_DIR/config.sh"
    . "$SCRIPT_DIR/define.sh"
    
    initConfig
    parseVersion
    parseLanguage
    
    STORAGE="${STORAGE:-$(getConfig STORAGE)}"
    DISK_SIZE="${DISK_SIZE:-$(getConfig DISK_SIZE)}"
    
    STORAGE="${STORAGE:-/storage}"
    DISK_SIZE="${DISK_SIZE:-64G}"
}

initInstallConfig

TMP="$STORAGE/tmp"

getDownloadUrl() {
    local version="$1"
    
    case "${version,,}" in
        "win10x64"|"win10")
            echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/dl/res/iso/10_20348_CN.iso"
            ;;
        "win11x64"|"win11")
            echo "https://software.download.prss.microsoft.com/dbazure/Win11_23H2_Chinese_Simplified_x64v2.iso"
            ;;
        "win10x64-enterprise-ltsc-eval")
            echo "https://software.download.prss.microsoft.com/dbazure/en-us_windows_10_enterprise_ltsc_2021_x64_dvd_d289cf96.iso"
            ;;
        *)
            echo ""
            ;;
    esac
}

downloadIso() {
    local url
    url=$(getDownloadUrl "$VERSION")
    
    if [ -z "$url" ]; then
        error "No download URL for version: $VERSION"
        error "Please provide a custom ISO in /storage/"
        return 1
    fi
    
    info "Downloading Windows ISO..."
    info "URL: $url"
    
    download "$url" "$BOOT" "Windows ISO" || {
        error "Download failed"
        return 1
    }
    
    setOwner "$BOOT"
    info "Download complete"
}

detectCustom() {
    CUSTOM=""
    
    local found
    found=$(find "$STORAGE" -maxdepth 1 -type f \( -iname "custom.iso" -o -iname "boot.iso" \) -print -quit 2>/dev/null)
    
    if [ -n "$found" ] && [ -f "$found" ]; then
        CUSTOM="$found"
        info "Found custom ISO: $CUSTOM"
    fi
}

skipInstall() {
    [ -f "$STORAGE/windows.boot" ] && hasDisk && return 0
    return 1
}

startInstall() {
    info "Checking installation..."
    
    detectCustom
    
    if [ -z "$CUSTOM" ]; then
        local lang
        lang=$(getLanguage "$LANGUAGE" "code")
        BOOT="$STORAGE/${VERSION}_${lang}.iso"
    else
        BOOT="$CUSTOM"
    fi
    
    if skipInstall; then
        info "Windows already installed"
        return 1
    fi
    
    rm -rf "$TMP"
    makeDir "$TMP"
    
    if [ ! -f "$BOOT" ] || [ ! -s "$BOOT" ]; then
        downloadIso
    fi
    
    createDisk "$STORAGE/windows.img" "$DISK_SIZE" "qcow2"
    
    setupEfi
    
    touch "$STORAGE/windows.boot"
    
    return 0
}

extractDrivers() {
    if [ -d "/var/drivers/virtio-win" ]; then
        info "VirtIO drivers ready"
        return 0
    fi
    
    if [ -f "/var/drivers/virtio-win.tar.xz" ]; then
        info "Extracting VirtIO drivers..."
        tar -xf /var/drivers/virtio-win.tar.xz -C /var/drivers
    fi
}

return 0 2>/dev/null || true
