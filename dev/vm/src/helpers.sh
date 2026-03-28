#!/usr/bin/env bash
set -Eeuo pipefail

# Logging helpers
info() { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
error() { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }

# HTML output for web interfaces (compatibility)
html() { :; }

# Check if process is alive
isAlive() {
    local pid="$1"
    [ -d "/proc/$pid" ]
}

# Kill process by PID
pKill() {
    local pid="$1"
    { kill -15 "$pid" 2>/dev/null || true; }
}

# Find and kill by name
fKill() {
    local name="$1"
    pkill -f "$name" 2>/dev/null || true
}

# Check if disk exists
hasDisk() {
    [ -f "$STORAGE/windows.img" ] || [ -f "$STORAGE/data.img" ]
}

# Create directory with proper permissions
makeDir() {
    local dir="$1"
    mkdir -p "$dir" 2>/dev/null
}

# Set ownership (for persistent storage)
setOwner() {
    local path="$1"
    chown -R 1000:1000 "$path" 2>/dev/null || true
    return 0
}

# Format bytes to human readable
formatBytes() {
    local bytes="$1"
    if (( bytes >= 1073741824 )); then
        echo "$(( bytes / 1073741824 )) GB"
    elif (( bytes >= 1048576 )); then
        echo "$(( bytes / 1048576 )) MB"
    else
        echo "$(( bytes / 1024 )) KB"
    fi
}

# Convert size string (e.g., "64G") to bytes
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

# Download file with progress
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
    
    return 0
}

# Extract drivers
extractDrivers() {
    local src="/var/drivers.txz"
    local dest="/var/drivers"
    
    if [ ! -d "$dest/virtio-win" ]; then
        info "Extracting VirtIO drivers..."
        mkdir -p "$dest"
        tar -xf "$src" -C "$dest" 2>/dev/null || {
            xz -d -c "$src" | tar -xf - -C "$dest"
        }
    fi
}

return 0
