#!/bin/bash
# DWC Universal Entrypoint Script
# Handles user initialization, config directory setup, and service startup

set -e

# Configuration
CONFIG_DIR="${CONFIG_DIR:-/config}"
SKEL_DIR="${SKEL_DIR:-/etc/skel}"
USER_NAME="${USER_NAME:-qwe}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize config directory from skel if empty
init_config() {
    if [ -d "$CONFIG_DIR" ]; then
        # Check if config directory is empty (no hidden files either)
        if [ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
            log_info "Initializing config directory from skel..."
            if [ -d "$SKEL_DIR" ]; then
                cp -a "$SKEL_DIR"/. "$CONFIG_DIR"/
                log_info "Config directory initialized successfully"
            else
                log_warn "Skel directory not found: $SKEL_DIR"
            fi
        else
            log_info "Config directory already initialized"
        fi
    else
        log_warn "Config directory does not exist: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
        if [ -d "$SKEL_DIR" ]; then
            cp -a "$SKEL_DIR"/. "$CONFIG_DIR"/
        fi
    fi
}

# Fix ownership and permissions
fix_permissions() {
    log_info "Fixing permissions for $CONFIG_DIR..."
    
    if id "$USER_NAME" &>/dev/null; then
        chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
        chmod 700 "$CONFIG_DIR" 2>/dev/null || true
        
        # Fix SSH directory if exists
        if [ -d "$CONFIG_DIR/.ssh" ]; then
            chmod 700 "$CONFIG_DIR/.ssh"
            chmod 600 "$CONFIG_DIR/.ssh"/* 2>/dev/null || true
        fi
        
        log_info "Permissions fixed"
    else
        log_warn "User $USER_NAME does not exist, skipping permission fix"
    fi
}

# Create user if not exists
create_user() {
    if ! id "$USER_NAME" &>/dev/null; then
        log_info "Creating user $USER_NAME..."
        
        # Alpine uses adduser, Debian/Kali uses useradd
        if command -v adduser &>/dev/null && [ -f /etc/alpine-release ]; then
            adduser -D -u "$USER_UID" -h "$CONFIG_DIR" -s /bin/bash "$USER_NAME" 2>/dev/null || true
        else
            groupadd -g "$USER_GID" "$USER_NAME" 2>/dev/null || true
            useradd -u "$USER_UID" -g "$USER_GID" -d "$CONFIG_DIR" -s /bin/bash -m "$USER_NAME" 2>/dev/null || true
        fi
        
        # Set password
        echo "$USER_NAME:toor" | chpasswd 2>/dev/null || true
        
        # Configure sudo
        if [ -d /etc/sudoers.d ]; then
            echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER_NAME"
            chmod 440 "/etc/sudoers.d/$USER_NAME"
        fi
        
        log_info "User $USER_NAME created"
    fi
}

# Start VNC server (for desktop images)
start_vnc() {
    if command -v vncserver &>/dev/null && [ "${ENABLE_VNC:-true}" = "true" ]; then
        log_info "Starting VNC server..."
        
        VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
        VNC_DEPTH="${VNC_DEPTH:-24}"
        
        # Set VNC password
        mkdir -p "$CONFIG_DIR/.vnc"
        echo "${VNC_PASSWORD:-114514}" | vncpasswd -f > "$CONFIG_DIR/.vnc/passwd"
        chmod 600 "$CONFIG_DIR/.vnc/passwd"
        chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/.vnc"
        
        # Start VNC as user
        su - "$USER_NAME" -c "vncserver -localhost no -geometry $VNC_GEOMETRY -depth $VNC_DEPTH :1" || true
        
        log_info "VNC server started on display :1"
    fi
}

# Start noVNC (for desktop images)
start_novnc() {
    if [ -d /usr/share/novnc ] && [ "${ENABLE_NOVNC:-true}" = "true" ]; then
        log_info "Starting noVNC..."
        
        NOVNC_PORT="${NOVNC_PORT:-6080}"
        
        /usr/share/novnc/utils/novnc_proxy \
            --vnc localhost:5901 \
            --listen "$NOVNC_PORT" \
            --web /usr/share/novnc/custom &
        
        log_info "noVNC started on port $NOVNC_PORT"
    fi
}

# Start audio bridge (for audio-enabled images)
start_audio() {
    if [ -f /opt/audio-bridge/audio-bridge.sh ] && [ "${ENABLE_AUDIO:-true}" = "true" ]; then
        log_info "Starting audio bridge..."
        
        # Start PulseAudio
        pulseaudio --check || pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
        
        # Start audio bridge
        /opt/audio-bridge/audio-bridge.sh &
        
        log_info "Audio bridge started"
    fi
}

# Main execution
main() {
    log_info "DWC Container Starting..."
    
    # Initialize
    create_user
    init_config
    fix_permissions
    
    # Start services based on image type
    if [ "${DESKTOP_MODE:-false}" = "true" ]; then
        start_vnc
        start_novnc
        start_audio
    fi
    
    log_info "Initialization complete"
    
    # Execute CMD or keep container running
    if [ $# -gt 0 ]; then
        exec "$@"
    else
        # Keep container running
        exec tail -f /dev/null
    fi
}

main "$@"
