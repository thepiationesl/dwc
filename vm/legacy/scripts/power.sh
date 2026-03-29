#!/usr/bin/env bash
# QEMU power management

set -Eeuo pipefail

QEMU_DIR="/run/shm"
QEMU_PID="$QEMU_DIR/qemu.pid"
QEMU_MON="$QEMU_DIR/qemu.sock"
QEMU_LOG="$QEMU_DIR/qemu.log"

CPU_CORES=""
RAM_SIZE=""
STORAGE=""

initPowerConfig() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "$SCRIPT_DIR/config.sh"
    
    initConfig
    
    CPU_CORES="${CPU_CORES:-$(getConfig CPU_CORES)}"
    RAM_SIZE="${RAM_SIZE:-$(getConfig RAM_SIZE)}"
    STORAGE="${STORAGE:-$(getConfig STORAGE)}"
    
    CPU_CORES="${CPU_CORES:-4}"
    RAM_SIZE="${RAM_SIZE:-8G}"
    STORAGE="${STORAGE:-/storage}"
}

initPowerConfig

runQemu() {
    local disk="${STORAGE}/windows.img"
    local efi="${STORAGE}/windows.rom"
    local iso="$BOOT"
    
    makeDir "$QEMU_DIR"
    
    local cmd=(
        qemu-system-x86_64
        -name "Windows VM"
        -machine q35,accel=kvm:tcg
        -cpu host,+hypervisor
        -smp "${CPU_CORES}"
        -m "${RAM_SIZE}"
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd
        -drive if=pflash,format=raw,file="$efi"
        -drive file="$disk",format=qcow2,if=virtio,cache=writeback
        -vnc :0,websocket=5700
        -vga virtio
        -usb -device usb-tablet
        -monitor unix:"$QEMU_MON",server,nowait
        -pidfile "$QEMU_PID"
        -daemonize
    )
    
    if [ -n "$iso" ] && [ -f "$iso" ]; then
        cmd+=(-cdrom "$iso" -boot d)
    fi
    
    local netargs
    netargs=$(getNetworkArgs)
    read -ra NET_CMD <<< "$netargs"
    cmd+=("${NET_CMD[@]}")
    
    if [ -c /dev/kvm ]; then
        info "KVM acceleration enabled"
    else
        warn "KVM not available, using TCG (slower)"
        cmd[4]="q35,accel=tcg"
        cmd[6]="qemu64"
    fi
    
    info "Starting QEMU..."
    "${cmd[@]}" > "$QEMU_LOG" 2>&1 || {
        error "Failed to start QEMU"
        cat "$QEMU_LOG" >&2
        return 1
    }
    
    sleep 1
    
    if [ -f "$QEMU_PID" ] && isAlive "$(<"$QEMU_PID")"; then
        info "QEMU started (PID: $(<"$QEMU_PID"))"
        return 0
    else
        error "QEMU failed to start"
        return 1
    fi
}

waitForQemu() {
    if [ ! -f "$QEMU_PID" ]; then
        return 1
    fi
    
    local pid
    pid=$(<"$QEMU_PID")
    
    info "Waiting for QEMU (PID: $pid)..."
    
    while isAlive "$pid"; do
        sleep 5
    done
    
    info "QEMU exited"
}

stopQemu() {
    if [ ! -f "$QEMU_PID" ]; then
        warn "QEMU not running"
        return 0
    fi
    
    local pid
    pid=$(<"$QEMU_PID")
    
    if ! isAlive "$pid"; then
        rm -f "$QEMU_PID"
        return 0
    fi
    
    info "Sending ACPI shutdown..."
    
    if [ -S "$QEMU_MON" ]; then
        echo "system_powerdown" | nc -U "$QEMU_MON" 2>/dev/null || true
    fi
    
    local timeout=60
    while isAlive "$pid" && (( timeout > 0 )); do
        sleep 1
        (( timeout-- ))
    done
    
    if isAlive "$pid"; then
        warn "Graceful shutdown failed, forcing..."
        pKill "$pid"
        sleep 2
        kill -9 "$pid" 2>/dev/null || true
    fi
    
    rm -f "$QEMU_PID"
    info "QEMU stopped"
}

getQemuStatus() {
    if [ -f "$QEMU_PID" ]; then
        local pid
        pid=$(<"$QEMU_PID")
        if isAlive "$pid"; then
            echo "Running (PID: $pid)"
            return 0
        fi
    fi
    echo "Stopped"
    return 1
}

return 0 2>/dev/null || true
