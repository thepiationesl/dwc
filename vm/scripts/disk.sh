#!/usr/bin/env bash
set -Eeuo pipefail

: "${DISK_SIZE:="64G"}"
: "${DISK_TYPE:="scsi"}"
: "${DISK_FLAGS:=""}"
: "${DISK_CACHE:="none"}"
: "${ALLOCATE:=""}"

DISK_FILE="$STORAGE/windows.img"
DATA_FILE="$STORAGE/data.img"

# Create disk image
createDisk() {
    local file="$1"
    local size="$2"
    local format="${3:-qcow2}"
    
    if [ -f "$file" ]; then
        info "Disk already exists: $file"
        return 0
    fi
    
    info "Creating disk: $file ($size)"
    
    local opts=""
    if [[ "$format" == "qcow2" ]]; then
        opts="-o preallocation=off,lazy_refcounts=on"
        [[ "${ALLOCATE,,}" == [Yy1]* ]] && opts="-o preallocation=full"
    fi
    
    qemu-img create -f "$format" $opts "$file" "$size" || {
        error "Failed to create disk: $file"
        return 1
    }
    
    setOwner "$file"
    info "Disk created: $file"
    return 0
}

# Get disk arguments for QEMU
getDiskArgs() {
    local args=""
    local idx=0
    
    # Main disk
    if [ -f "$DISK_FILE" ]; then
        case "${DISK_TYPE,,}" in
            "scsi" | "virtio-scsi" )
                args="$args -object iothread,id=io$idx"
                args="$args -drive file=$DISK_FILE,id=drive$idx,format=qcow2,cache=$DISK_CACHE,aio=native,discard=on,detect-zeroes=on,if=none"
                args="$args -device virtio-scsi-pci,id=scsi$idx,bus=pcie.0,iothread=io$idx"
                args="$args -device scsi-hd,drive=drive$idx,bus=scsi$idx.0,rotation_rate=1,bootindex=1"
                ;;
            "virtio" )
                args="$args -drive file=$DISK_FILE,id=drive$idx,format=qcow2,cache=$DISK_CACHE,aio=native,if=virtio,bootindex=1"
                ;;
            "ide" )
                args="$args -drive file=$DISK_FILE,id=drive$idx,format=qcow2,cache=$DISK_CACHE,if=ide,bootindex=1"
                ;;
        esac
        idx=$((idx + 1))
    fi
    
    # Data disk
    if [ -f "$DATA_FILE" ]; then
        args="$args -object iothread,id=io$idx"
        args="$args -drive file=$DATA_FILE,id=data$idx,format=raw,cache=$DISK_CACHE,aio=native,discard=on,detect-zeroes=on,if=none"
        args="$args -device virtio-scsi-pci,id=scsi$idx,bus=pcie.0,iothread=io$idx"
        args="$args -device scsi-hd,drive=data$idx,bus=scsi$idx.0,rotation_rate=1,bootindex=3"
    fi
    
    echo "$args"
}

# Setup EFI firmware
setupEfi() {
    local code="$STORAGE/windows.rom"
    local vars="$STORAGE/windows.vars"
    
    # Copy OVMF firmware if not exists
    if [ ! -f "$code" ]; then
        if [ -f "/usr/share/OVMF/OVMF_CODE.fd" ]; then
            cp "/usr/share/OVMF/OVMF_CODE.fd" "$code"
            setOwner "$code"
        elif [ -f "/usr/share/qemu/edk2-x86_64-code.fd" ]; then
            cp "/usr/share/qemu/edk2-x86_64-code.fd" "$code"
            setOwner "$code"
        fi
    fi
    
    if [ ! -f "$vars" ]; then
        if [ -f "/usr/share/OVMF/OVMF_VARS.fd" ]; then
            cp "/usr/share/OVMF/OVMF_VARS.fd" "$vars"
            setOwner "$vars"
        elif [ -f "/usr/share/qemu/edk2-i386-vars.fd" ]; then
            cp "/usr/share/qemu/edk2-i386-vars.fd" "$vars"
            setOwner "$vars"
        fi
    fi
}

# Get EFI arguments
getEfiArgs() {
    local code="$STORAGE/windows.rom"
    local vars="$STORAGE/windows.vars"
    local args=""
    
    if [ -f "$code" ] && [ -f "$vars" ]; then
        args="-drive file=$code,if=pflash,unit=0,format=raw,readonly=on"
        args="$args -drive file=$vars,if=pflash,unit=1,format=raw"
    fi
    
    echo "$args"
}

return 0
