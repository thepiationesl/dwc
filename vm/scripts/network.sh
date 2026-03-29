#!/usr/bin/env bash
set -Eeuo pipefail

: "${DHCP:="Y"}"
: "${MAC:=""}"

VM_NET_TAP="qemu"
VM_NET_IP="172.20.0.1"
VM_NET_MAC="${MAC:-02:4C:BB:C9:5B:42}"

# Configure TAP network
configureNetwork() {
    info "Configuring network..."

    # Check for /dev/net/tun
    if [ ! -c /dev/net/tun ]; then
        warn "TUN device not available, will use user-mode networking"
        return 0
    fi

    # Create TAP interface
    if ! ip link show "$VM_NET_TAP" &>/dev/null; then
        ip tuntap add dev "$VM_NET_TAP" mode tap 2>/dev/null || {
            warn "Failed to create TAP interface, will use user-mode networking"
            return 0
        }
    fi

    # Configure TAP interface
    ip addr flush dev "$VM_NET_TAP" 2>/dev/null || true
    ip addr add "$VM_NET_IP/24" dev "$VM_NET_TAP" 2>/dev/null || true
    ip link set dev "$VM_NET_TAP" up 2>/dev/null || true

    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true

    # Setup NAT (if iptables available)
    if command -v iptables &>/dev/null; then
        # Get default interface
        local iface
        iface=$(ip route | grep default | awk '{print $5}' | head -1)
        
        if [ -n "$iface" ]; then
            # MASQUERADE for NAT
            iptables -t nat -A POSTROUTING -o "$iface" -j MASQUERADE 2>/dev/null || true
            iptables -A FORWARD -i "$VM_NET_TAP" -o "$iface" -j ACCEPT 2>/dev/null || true
            iptables -A FORWARD -i "$iface" -o "$VM_NET_TAP" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
        fi
    fi

    # Start DHCP if enabled
    if [[ "${DHCP,,}" == [Yy1]* ]]; then
        startDhcp
    fi

    info "TAP network configured: $VM_NET_IP/24"
    return 0
}

# Start simple DHCP server using dnsmasq or busybox
startDhcp() {
    local dhcp_start="172.20.0.100"
    local dhcp_end="172.20.0.200"
    
    # Use dnsmasq if available
    if command -v dnsmasq &>/dev/null; then
        dnsmasq \
            --interface="$VM_NET_TAP" \
            --bind-interfaces \
            --dhcp-range="$dhcp_start,$dhcp_end,12h" \
            --dhcp-option=3,"$VM_NET_IP" \
            --dhcp-option=6,8.8.8.8,8.8.4.4 \
            --no-daemon \
            --log-queries \
            --log-dhcp \
            &>/dev/null &
        info "DHCP server started (dnsmasq)"
    else
        info "DHCP not available, VM will need static IP or user-mode networking"
    fi
}

# Get network config for QEMU
getNetworkArgs() {
    local args=""
    
    if [ -c /dev/net/tun ] && ip link show "$VM_NET_TAP" &>/dev/null; then
        # TAP networking
        args="-netdev tap,id=hostnet0,ifname=$VM_NET_TAP,script=no,downscript=no"
        args="$args -device virtio-net-pci,id=net0,netdev=hostnet0,mac=$VM_NET_MAC"
    else
        # User-mode networking (fallback)
        args="-netdev user,id=hostnet0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5985-:5985"
        args="$args -device virtio-net-pci,id=net0,netdev=hostnet0"
    fi
    
    echo "$args"
}

# Close network on shutdown
closeNetwork() {
    if ip link show "$VM_NET_TAP" &>/dev/null; then
        ip link set dev "$VM_NET_TAP" down 2>/dev/null || true
        ip tuntap del dev "$VM_NET_TAP" mode tap 2>/dev/null || true
    fi
    
    # Kill DHCP server
    pkill -f "dnsmasq.*$VM_NET_TAP" 2>/dev/null || true
}

return 0
