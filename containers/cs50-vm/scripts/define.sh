#!/usr/bin/env bash
# Version and language definitions
# Supports: Config file, Environment variables, CLI arguments

set -Eeuo pipefail

VERSION=""
LANGUAGE=""
CPU_CORES=""
RAM_SIZE=""
DISK_SIZE=""
STORAGE=""
MANUAL=""

loadConfig() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "$SCRIPT_DIR/config.sh"
    
    initConfig
    
    VERSION="$(getConfig VERSION)"
    LANGUAGE="$(getConfig LANGUAGE)"
    CPU_CORES="$(getConfig CPU_CORES)"
    RAM_SIZE="$(getConfig RAM_SIZE)"
    DISK_SIZE="$(getConfig DISK_SIZE)"
    STORAGE="$(getConfig STORAGE)"
    MANUAL="$(getConfig MANUAL)"
}

declare -A VERSIONS=(
    ["10"]="Windows 10"
    ["win10"]="Windows 10"
    ["win10x64"]="Windows 10"
    ["11"]="Windows 11"
    ["win11"]="Windows 11"
    ["win11x64"]="Windows 11"
    ["ltsc"]="Windows 10 LTSC"
)

declare -A LANGUAGES=(
    ["Chinese"]="zh-CN"
    ["English"]="en-US"
    ["Japanese"]="ja-JP"
    ["Korean"]="ko-KR"
    ["German"]="de-DE"
    ["French"]="fr-FR"
)

parseVersion() {
    local ver="${VERSION,,}"
    
    case "$ver" in
        "10"|"win10"|"win10x64")
            VERSION="win10x64"
            ;;
        "11"|"win11"|"win11x64")
            VERSION="win11x64"
            ;;
        "ltsc"|"enterprise")
            VERSION="win10x64-enterprise-ltsc-eval"
            ;;
        *)
            VERSION="win10x64"
            ;;
    esac
    
    export VERSION
}

printVersion() {
    local ver="$1"
    echo "${VERSIONS[$ver]:-Windows 10}"
}

parseLanguage() {
    local lang="${LANGUAGE}"
    
    case "${lang,,}" in
        "chinese"|"cn"|"zh"|"zh-cn")
            LANGUAGE="Chinese"
            ;;
        "english"|"en"|"us"|"en-us")
            LANGUAGE="English"
            ;;
        "japanese"|"ja"|"jp")
            LANGUAGE="Japanese"
            ;;
        *)
            LANGUAGE="Chinese"
            ;;
    esac
    
    export LANGUAGE
}

getLanguage() {
    local lang="$1"
    local type="${2:-code}"
    
    case "$type" in
        "code")
            echo "${LANGUAGES[$lang]:-zh-CN}"
            ;;
        "culture")
            echo "${LANGUAGES[$lang]:-zh-CN}"
            ;;
        "name")
            echo "$lang"
            ;;
    esac
}

return 0 2>/dev/null || true
