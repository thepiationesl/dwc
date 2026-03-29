#!/usr/bin/env bash
set -Eeuo pipefail

SAMBA_DIR="/shared"
SAMBA_CONF="/etc/samba/smb.conf"

# Configure Samba
configureSamba() {
    [ ! -d "$SAMBA_DIR" ] && return 0
    
    info "Configuring Samba share..."
    
    # Create Samba config
    cat > "$SAMBA_CONF" << EOF
[global]
    workgroup = WORKGROUP
    server string = DWC Windows VM
    security = user
    map to guest = Bad User
    guest account = nobody
    log file = /var/log/samba/%m.log
    max log size = 50
    dns proxy = no
    socket options = TCP_NODELAY IPTOS_LOWDELAY
    min protocol = SMB2
    server min protocol = SMB2

[shared]
    path = $SAMBA_DIR
    browseable = yes
    writable = yes
    guest ok = yes
    public = yes
    force user = root
    force group = root
    create mask = 0777
    directory mask = 0777
EOF

    # Ensure shared directory exists and has correct permissions
    mkdir -p "$SAMBA_DIR"
    chmod 777 "$SAMBA_DIR"
    
    # Create required directories
    mkdir -p /var/log/samba
    mkdir -p /var/run/samba
    
    info "Samba configured: \\\\172.20.0.1\\shared"
}

# Start Samba services
startSamba() {
    info "Starting Samba services..."
    
    # Start nmbd (NetBIOS)
    nmbd -D 2>/dev/null || warn "Failed to start nmbd"
    
    # Start smbd (SMB)
    smbd -D 2>/dev/null || warn "Failed to start smbd"
    
    info "Samba services started"
}

# Stop Samba
stopSamba() {
    pkill -f smbd 2>/dev/null || true
    pkill -f nmbd 2>/dev/null || true
}

return 0
