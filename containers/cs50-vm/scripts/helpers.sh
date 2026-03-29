#!/usr/bin/env bash
# Helper functions for VM scripts

set -Eeuo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Process management
isAlive() {
    local pid="$1"
    [ -d "/proc/$pid" ]
}

pKill() {
    local pid="$1"
    kill -15 "$pid" 2>/dev/null || true
}

fKill() {
    local name="$1"
    pkill -f "$name" 2>/dev/null || true
}

# File operations
makeDir() {
    mkdir -p "$1" 2>/dev/null
}

setOwner() {
    chown -R 1000:1000 "$1" 2>/dev/null || true
}

# Check if disk exists
hasDisk() {
    [ -f "${STORAGE:-/storage}/windows.img" ] || [ -f "${STORAGE:-/storage}/data.img" ]
}

# Format bytes
formatBytes() {
    local bytes="$1"
    if (( bytes >= 1073741824 )); then
        echo "$(( bytes / 1073741824 ))G"
    elif (( bytes >= 1048576 )); then
        echo "$(( bytes / 1048576 ))M"
    else
        echo "$(( bytes / 1024 ))K"
    fi
}

# Convert size string to bytes
toBytes() {
    local size="$1"
    local num="${size%[GgMmKk]*}"
    local unit="${size##*[0-9]}"
    
    case "${unit^^}" in
        G) echo $(( num * 1073741824 )) ;;
        M) echo $(( num * 1048576 )) ;;
        K) echo $(( num * 1024 )) ;;
        *) echo "$num" ;;
    esac
}

# Download with progress
download() {
    local url="$1"
    local dest="$2"
    local name="${3:-file}"
    
    info "Downloading $name..."
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$dest" "$url" || return 1
    elif command -v curl &>/dev/null; then
        curl -# -L -o "$dest" "$url" || return 1
    else
        error "No download tool available"
        return 1
    fi
}

return 0 2>/dev/null || true
