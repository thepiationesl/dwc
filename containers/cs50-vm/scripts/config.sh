#!/usr/bin/env bash
# Config parser - Supports file, environment variables, and CLI arguments
# Priority: CLI args > Environment > Config file > Defaults
# Config file location: relative to script directory

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${HOME}/vm/vm.conf}"

declare -A VM_CONFIG=(
    [VERSION]="10"
    [LANGUAGE]="Chinese"
    [CPU_CORES]="4"
    [RAM_SIZE]="8G"
    [DISK_SIZE]="64G"
    [STORAGE]="/storage"
    [MANUAL]="Y"
    [VM_NET_TAP]="N"
    [VM_NET_DEV]="tap0"
    [VM_NET_IP]="172.20.0.1"
    [VM_NET_MASK]="255.255.255.0"
    [VM_NET_DHCP_START]="172.20.0.100"
    [VM_NET_DHCP_END]="172.20.0.200"
)

loadConfigFile() {
    if [ -f "$CONFIG_FILE" ]; then
        while IFS='=' read -r key value; do
            key=$(echo "$key" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -n "$key" ] && [ -n "$value" ] && [ "${key:0:1}" != "#" ] && \
                VM_CONFIG[$key]="$value"
        done < "$CONFIG_FILE"
    fi
}

loadEnvVars() {
    for key in "${!VM_CONFIG[@]}"; do
        local env_var="${key}"
        local env_val="${!env_var:-}"
        [ -n "$env_val" ] && VM_CONFIG[$key]="$env_val"
    done
}

parseArgs() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--version)
                VM_CONFIG[VERSION]="${2:-}"
                shift 2
                ;;
            -l|--language)
                VM_CONFIG[LANGUAGE]="${2:-}"
                shift 2
                ;;
            -c|--cpu)
                VM_CONFIG[CPU_CORES]="${2:-}"
                shift 2
                ;;
            -r|--ram)
                VM_CONFIG[RAM_SIZE]="${2:-}"
                shift 2
                ;;
            -d|--disk)
                VM_CONFIG[DISK_SIZE]="${2:-}"
                shift 2
                ;;
            -s|--storage)
                VM_CONFIG[STORAGE]="${2:-}"
                shift 2
                ;;
            -C|--config)
                CONFIG_FILE="${2:-}"
                shift 2
                ;;
            -h|--help)
                showHelp
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

showHelp() {
    cat << EOF
Usage: vm-setup [OPTIONS]
       vm-start [OPTIONS]
       vm-status [OPTIONS]

Options:
  -v, --version VERSION    Windows version (10, 11, ltsc)
  -l, --language LANG      Language (Chinese, English, Japanese)
  -c, --cpu CORES          CPU cores (default: 4)
  -r, --ram SIZE           RAM size (default: 8G)
  -d, --disk SIZE          Disk size (default: 64G)
  -s, --storage PATH       Storage directory (default: /storage)
  -C, --config FILE        Config file (default: ~/vm/vm.conf)

Config file format (~/vm/vm.conf):
  VERSION=10
  LANGUAGE=Chinese
  CPU_CORES=4
  RAM_SIZE=8G
  DISK_SIZE=64G
  STORAGE=/storage

Priority: CLI args > Environment > Config file > Defaults
EOF
}

getConfig() {
    local key="$1"
    echo "${VM_CONFIG[$key]:-}"
}

initConfig() {
    loadConfigFile
    loadEnvVars
}

return 0 2>/dev/null || true
