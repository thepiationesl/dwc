#!/bin/bash
# Fix permissions script for /config directory
# Can be run manually if permissions get messed up

CONFIG_DIR="${CONFIG_DIR:-/config}"
USER_NAME="${USER_NAME:-qwe}"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Config directory does not exist: $CONFIG_DIR"
    exit 1
fi

if ! id "$USER_NAME" &>/dev/null; then
    echo "User does not exist: $USER_NAME"
    exit 1
fi

echo "Fixing permissions for $CONFIG_DIR..."

# Set ownership
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR"

# Set directory permissions
find "$CONFIG_DIR" -type d -exec chmod 755 {} \;

# Set file permissions
find "$CONFIG_DIR" -type f -exec chmod 644 {} \;

# Fix SSH permissions
if [ -d "$CONFIG_DIR/.ssh" ]; then
    chmod 700 "$CONFIG_DIR/.ssh"
    chmod 600 "$CONFIG_DIR/.ssh"/* 2>/dev/null || true
    chmod 644 "$CONFIG_DIR/.ssh"/*.pub 2>/dev/null || true
fi

# Fix VNC permissions
if [ -d "$CONFIG_DIR/.vnc" ]; then
    chmod 700 "$CONFIG_DIR/.vnc"
    chmod 600 "$CONFIG_DIR/.vnc/passwd" 2>/dev/null || true
fi

# Fix executable scripts
find "$CONFIG_DIR" -name "*.sh" -exec chmod 755 {} \;

echo "Permissions fixed successfully"
