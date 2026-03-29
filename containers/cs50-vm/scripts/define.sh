#!/usr/bin/env bash
# Version and language definitions

set -Eeuo pipefail

# Default values
VERSION="${VERSION:-10}"
LANGUAGE="${LANGUAGE:-Chinese}"
CPU_CORES="${CPU_CORES:-4}"
RAM_SIZE="${RAM_SIZE:-8G}"
DISK_SIZE="${DISK_SIZE:-64G}"

# Version mappings
declare -A VERSIONS=(
    ["10"]="Windows 10"
    ["win10"]="Windows 10"
    ["win10x64"]="Windows 10"
    ["11"]="Windows 11"
    ["win11"]="Windows 11"
    ["win11x64"]="Windows 11"
    ["ltsc"]="Windows 10 LTSC"
)

# Language mappings
declare -A LANGUAGES=(
    ["Chinese"]="zh-CN"
    ["English"]="en-US"
    ["Japanese"]="ja-JP"
    ["Korean"]="ko-KR"
    ["German"]="de-DE"
    ["French"]="fr-FR"
)

# Parse version
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

# Get version display name
printVersion() {
    local ver="$1"
    echo "${VERSIONS[$ver]:-Windows 10}"
}

# Parse language
parseLanguage() {
    local lang="${LANGUAGE}"
    
    # Map common names
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

# Get language code
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
