#!/usr/bin/env bash
# Network configuration for VM

set -Eeuo pipefail

VM_NET_TAP="${VM_NET_TAP:-N}"
VM_NET_DEV="${VM_NET_DEV:-tap0}"
VM_NET_IP="${VM_NET_IP:-172.20.0.1}"
VM_NET_MASK="${VM_NET_MASK:-255.255.255.0}"
VM_NET_DHCP_START="${VM_NET_DHCP_START:-172.20.0.100}"
VM_NET_DHCP_END="${VM_NET_DHCP_END:-172.20.0.200}"

# Configure TAP network
configureNetwork() {
    # Check if TAP device exists
    if [ ! -c /dev/net/tun ]; then
        warn "TUN device not available, using user-mode networking"
        VM_NET_TAP="N"
        return 0
    fi
    
    # Check capabilities
    if ! ip tuntap add mode tap name "$VM_NET_DEV" 2>/dev/null; then
        warn "Cannot create TAP device, using user-mode networking"
        VM_NET_TAP="N"
        return 0
    fi
    
    info "Configuring TAP network..."
    
    # Configure TAP interface
    ip link set "$VM_NET_DEV" up
    ip addr add "$VM_NET_IP/24" dev "$VM_NET_DEV" 2>/dev/null || true
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
    
    # Setup NAT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
    iptables -A FORWARD -i "$VM_NET_DEV" -o eth0 -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -i eth0 -o "$VM_NET_DEV" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    
    # Start DHCP server
    startDhcp
    
    VM_NET_TAP="Y"
    export VM_NET_TAP VM_NET_DEV
    
    info "TAP network configured: $VM_NET_DEV ($VM_NET_IP)"
}

# Start DHCP server
startDhcp() {
    local conf="/tmp/dnsmasq.conf"
    
    cat > "$conf" << EOF
interface=$VM_NET_DEV
dhcp-range=$VM_NET_DHCP_START,$VM_NET_DHCP_END,12h
dhcp-option=3,$VM_NET_IP
dhcp-option=6,8.8.8.8,8.8.4.4
EOF
    
    dnsmasq -C "$conf" 2>/dev/null || warn "Failed to start DHCP"
}

# Get network args for QEMU
getNetworkArgs() {
    if [[ "$VM_NET_TAP" == [Yy1]* ]]; then
        echo "-netdev tap,id=net0,ifname=$VM_NET_DEV,script=no,downscript=no -device virtio-net-pci,netdev=net0"
    else
        # User-mode networking
        echo "-netdev user,id=net0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5900-:5900 -device virtio-net-pci,netdev=net0"
    fi
}

return 0 2>/dev/null || true
