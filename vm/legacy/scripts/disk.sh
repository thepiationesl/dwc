#!/usr/bin/env bash
# Disk management functions

set -Eeuo pipefail

STORAGE=""
DISK_SIZE=""

initDiskConfig() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "$SCRIPT_DIR/config.sh"
    
    initConfig
    
    STORAGE="${STORAGE:-$(getConfig STORAGE)}"
    DISK_SIZE="${DISK_SIZE:-$(getConfig DISK_SIZE)}"
    
    STORAGE="${STORAGE:-/storage}"
    DISK_SIZE="${DISK_SIZE:-64G}"
}

initDiskConfig

DISK_FILE="$STORAGE/windows.img"
EFI_FILE="$STORAGE/windows.rom"

createDisk() {
    local file="${1:-$DISK_FILE}"
    local size="${2:-$DISK_SIZE}"
    local format="${3:-qcow2}"
    
    if [ -f "$file" ]; then
        info "Disk already exists: $file"
        return 0
    fi
    
    info "Creating disk: $file ($size)"
    
    qemu-img create -f "$format" "$file" "$size" || {
        error "Failed to create disk"
        return 1
    }
    
    setOwner "$file"
    info "Disk created successfully"
}

setupEfi() {
    local src="/usr/share/OVMF/OVMF_VARS.fd"
    local dst="$EFI_FILE"
    
    if [ -f "$dst" ]; then
        return 0
    fi
    
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        setOwner "$dst"
        info "EFI vars initialized"
    else
        for alt in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/ovmf/OVMF_VARS.fd; do
            if [ -f "$alt" ]; then
                cp "$alt" "$dst"
                setOwner "$dst"
                info "EFI vars initialized from $alt"
                return 0
            fi
        done
        warn "OVMF not found, UEFI may not work"
    fi
}

getDiskInfo() {
    local file="${1:-$DISK_FILE}"
    
    if [ ! -f "$file" ]; then
        echo "Not found"
        return 1
    fi
    
    qemu-img info "$file" 2>/dev/null | grep -E "^(file format|virtual size|disk size)" || echo "Unknown"
}

resizeDisk() {
    local file="${1:-$DISK_FILE}"
    local size="$2"
    
    if [ ! -f "$file" ]; then
        error "Disk not found: $file"
        return 1
    fi
    
    info "Resizing disk to $size..."
    qemu-img resize "$file" "$size" || {
        error "Failed to resize disk"
        return 1
    }
    
    info "Disk resized successfully"
}

return 0 2>/dev/null || true
