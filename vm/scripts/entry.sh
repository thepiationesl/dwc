#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=/dev/null
. /run/helpers.sh
. /run/define.sh
. /run/network.sh
. /run/disk.sh
. /run/install.sh
. /run/samba.sh
. /run/power.sh

APP="Windows"
STORAGE="/storage"
QEMU_DIR="/run/shm"

trap - ERR

# Initialize
info "Starting DWC Windows VM (dockur/windows compatible)..."
info "Manual mode: $MANUAL"

# Parse version and language
parseVersion
parseLanguage

# Setup network (TAP mode)
configureNetwork

# Setup Samba share
configureSamba

# Handle manual mode
if [[ "$MANUAL" == [Yy1]* ]]; then
    info "========================================"
    info "  Manual Mode - Container is ready"
    info "========================================"
    info ""
    info "Available commands:"
    info "  vm-setup    - Download ISO and prepare installation"
    info "  vm-start    - Start QEMU virtual machine"
    info "  vm-stop     - Stop virtual machine gracefully"
    info "  vm-status   - Show VM status"
    info ""
    info "Configuration:"
    info "  VERSION=$VERSION"
    info "  CPU_CORES=$CPU_CORES"
    info "  RAM_SIZE=$RAM_SIZE"
    info "  DISK_SIZE=$DISK_SIZE"
    info "  LANGUAGE=$LANGUAGE"
    info ""
    info "Samba share: \\\\172.20.0.1\\shared"
    info ""
    
    # Keep container running
    exec tail -f /dev/null
fi

# Auto mode - continue with normal startup
info "Auto mode - starting installation/boot..."

# Start installation or boot existing
if ! startInstall; then
    info "Installation skipped, booting existing Windows..."
fi

# Run QEMU
runQemu

# Wait for QEMU
waitForQemu
