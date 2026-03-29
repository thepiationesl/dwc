#!/usr/bin/env bash
# Samba share configuration

set -Eeuo pipefail

SHARE_DIR="${SHARE_DIR:-/shared}"
SAMBA_CONF="/etc/samba/smb.conf"

# Configure Samba
configureSamba() {
    makeDir "$SHARE_DIR"
    chmod 777 "$SHARE_DIR"
    
    cat > "$SAMBA_CONF" << EOF
[global]
    workgroup = WORKGROUP
    server string = DWC VM Share
    security = user
    map to guest = Bad User
    guest account = nobody
    log file = /var/log/samba/log.%m
    max log size = 50
    dns proxy = no

[shared]
    path = $SHARE_DIR
    browseable = yes
    read only = no
    guest ok = yes
    create mask = 0777
    directory mask = 0777
    force user = nobody
    force group = nogroup
EOF
    
    info "Samba configured: \\\\${VM_NET_IP:-172.20.0.1}\\shared"
}

# Start Samba
startSamba() {
    if ! command -v smbd &>/dev/null; then
        warn "Samba not installed"
        return 0
    fi
    
    configureSamba
    
    # Start services
    smbd -D 2>/dev/null || warn "Failed to start smbd"
    nmbd -D 2>/dev/null || true
    
    info "Samba started"
}

# Stop Samba
stopSamba() {
    fKill "smbd"
    fKill "nmbd"
}

return 0 2>/dev/null || true
