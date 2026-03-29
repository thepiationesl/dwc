#!/usr/bin/env bash
set -Eeuo pipefail

: "${QEMU_TIMEOUT:=110}"
: "${MON_PORT:=7100}"

QEMU_DIR="/run/shm"
QEMU_PID="$QEMU_DIR/qemu.pid"
QEMU_LOG="$QEMU_DIR/qemu.log"
QEMU_OUT="$QEMU_DIR/qemu.out"
QEMU_END="$QEMU_DIR/qemu.end"

# Initialize
mkdir -p "$QEMU_DIR"
rm -f "$QEMU_DIR"/qemu.* 2>/dev/null || true
touch "$QEMU_LOG"

# Build QEMU command
buildQemuCmd() {
    local cmd="qemu-system-x86_64 -nodefaults"
    
    # CPU
    local cpu_args="-cpu host,kvm=on,l3-cache=on,+hypervisor,migratable=no"
    [[ "${HV,,}" == [Nn]* ]] && cpu_args="-cpu host,kvm=on,l3-cache=on,-hypervisor,migratable=no"
    [[ "${VMX,,}" == [Yy1]* ]] && cpu_args="$cpu_args,+vmx"
    [ -n "${ARGUMENTS:-}" ] && cpu_args="${ARGUMENTS}"
    cmd="$cmd $cpu_args"
    
    # SMP
    cmd="$cmd -smp $CPU_CORES,sockets=1,dies=1,cores=$CPU_CORES,threads=1"
    
    # Memory
    cmd="$cmd -m $RAM_SIZE"
    
    # Machine
    cmd="$cmd -machine type=q35,smm=off,graphics=off,vmport=off,dump-guest-core=off,hpet=off,accel=kvm"
    cmd="$cmd -enable-kvm"
    cmd="$cmd -global kvm-pit.lost_tick_policy=discard"
    
    # Display (VNC with WebSocket)
    cmd="$cmd -display vnc=:0,websocket=5700"
    cmd="$cmd -vga virtio"
    
    # Monitor
    cmd="$cmd -monitor telnet:localhost:$MON_PORT,server,nowait,nodelay"
    cmd="$cmd -daemonize"
    cmd="$cmd -D $QEMU_LOG"
    cmd="$cmd -pidfile $QEMU_PID"
    cmd="$cmd -name windows,process=windows,debug-threads=on"
    
    # Serial and USB
    cmd="$cmd -serial pty"
    cmd="$cmd -device qemu-xhci,id=xhci,p2=7,p3=7"
    cmd="$cmd -device usb-tablet"
    
    # Network
    cmd="$cmd $(getNetworkArgs)"
    
    # Disks
    cmd="$cmd $(getDiskArgs)"
    
    # EFI firmware
    cmd="$cmd $(getEfiArgs)"
    
    # RTC
    cmd="$cmd -rtc base=localtime"
    cmd="$cmd -global ICH9-LPC.disable_s3=1"
    cmd="$cmd -global ICH9-LPC.disable_s4=1"
    
    # RNG
    cmd="$cmd -object rng-random,id=objrng0,filename=/dev/urandom"
    cmd="$cmd -device virtio-rng-pci,rng=objrng0,id=rng0,bus=pcie.0"
    
    # Boot ISO (if installing)
    if [ -n "${BOOT:-}" ] && [ -f "$BOOT" ]; then
        cmd="$cmd -cdrom $BOOT"
        cmd="$cmd -boot d"
    fi
    
    echo "$cmd"
}

# Run QEMU
runQemu() {
    info "Starting QEMU..."
    if [ ! -c /dev/kvm ]; then
        error "KVM device not available"
        error "This VM profile requires /dev/kvm and should be started only in a KVM-capable environment."
        return 1
    fi
    
    local cmd
    cmd=$(buildQemuCmd)
    
    if [[ "${DEBUG,,}" == [Yy1]* ]]; then
        info "QEMU command:"
        echo "$cmd" | tr ' ' '\n' | grep -v '^$'
    fi
    
    # Execute
    eval "$cmd" 2>"$QEMU_OUT" || {
        error "Failed to start QEMU"
        cat "$QEMU_OUT" >&2
        return 1
    }
    
    sleep 1
    
    if [ ! -f "$QEMU_PID" ]; then
        error "QEMU failed to start"
        cat "$QEMU_LOG" >&2
        return 1
    fi
    
    info "QEMU started (PID: $(cat "$QEMU_PID"))"
    info "VNC: :0 (port 5900)"
    info "WebSocket: :5700"
    info "Monitor: localhost:$MON_PORT"
}

# Wait for QEMU
waitForQemu() {
    local pid
    
    while true; do
        [ -f "$QEMU_END" ] && break
        
        if [ -f "$QEMU_PID" ]; then
            pid=$(<"$QEMU_PID")
            if ! isAlive "$pid"; then
                info "QEMU process ended"
                break
            fi
        fi
        
        sleep 5
    done
}

# Graceful shutdown
stopQemu() {
    info "Stopping QEMU..."
    
    touch "$QEMU_END"
    
    if [ ! -f "$QEMU_PID" ]; then
        warn "No QEMU PID file found"
        return 0
    fi
    
    local pid
    pid=$(<"$QEMU_PID")
    
    if ! isAlive "$pid"; then
        info "QEMU already stopped"
        return 0
    fi
    
    # Send ACPI shutdown
    echo 'system_powerdown' | nc -q 1 -w 1 localhost "$MON_PORT" 2>/dev/null || true
    
    local cnt=0
    while [ "$cnt" -lt "$QEMU_TIMEOUT" ]; do
        sleep 1
        cnt=$((cnt + 1))
        
        ! isAlive "$pid" && break
        [ ! -f "$QEMU_PID" ] && break
        
        info "Waiting for Windows shutdown... ($cnt/$QEMU_TIMEOUT)"
        echo 'system_powerdown' | nc -q 1 -w 1 localhost "$MON_PORT" 2>/dev/null || true
    done
    
    if isAlive "$pid"; then
        warn "Timeout, force killing QEMU..."
        kill -9 "$pid" 2>/dev/null || true
    fi
    
    # Cleanup
    closeNetwork
    stopSamba
    
    info "QEMU stopped"
}

# Signal handler
_graceful_shutdown() {
    local sig="$1"
    info "Received $sig, shutting down..."
    stopQemu
    exit 0
}

# Setup signal handlers
trap '_graceful_shutdown SIGTERM' SIGTERM
trap '_graceful_shutdown SIGINT' SIGINT
trap '_graceful_shutdown SIGHUP' SIGHUP

return 0
