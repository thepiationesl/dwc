#!/usr/bin/env bash
set -Eeuo pipefail

# Default values
: "${KEY:=""}"
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${EDITION:=""}"
: "${MANUAL:="Y"}"
: "${REMOVE:=""}"
: "${VERSION:="10"}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:="en"}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"

MIRRORS=4
PLATFORM="x64"
BOOT_MODE="${BOOT_MODE:-windows}"
MACHINE="${MACHINE:-q35}"

# Parse VERSION to standard format
parseVersion() {
    if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
        VERSION="${VERSION:1:-1}"
    fi

    VERSION=$(expr "$VERSION" : "^\ *\(.*[^ ]\)\ *$")
    [ -z "$VERSION" ] && VERSION="win10x64"

    case "${VERSION,,}" in
        "11" | "11p" | "win11" | "pro11" | "win11p" | "windows11" | "windows 11" )
            VERSION="win11x64" ;;
        "11e" | "win11e" )
            VERSION="win11x64-enterprise-eval" ;;
        "11l" | "11ltsc" | "ltsc11" )
            VERSION="win11x64-enterprise-ltsc-eval"
            [ -z "$DETECTED" ] && DETECTED="win11x64-ltsc" ;;
        "10" | "10p" | "win10" | "pro10" | "win10p" | "windows10" | "windows 10" )
            VERSION="win10x64" ;;
        "10e" | "win10e" )
            VERSION="win10x64-enterprise-eval" ;;
        "10l" | "10ltsc" | "ltsc10" )
            VERSION="win10x64-enterprise-ltsc-eval"
            [ -z "$DETECTED" ] && DETECTED="win10x64-ltsc" ;;
        "8" | "81" | "8.1" | "win8" | "win81" )
            VERSION="win81x64" ;;
        "7" | "win7" | "windows7" )
            VERSION="win7x64"
            [ -z "$DETECTED" ] && DETECTED="win7x64-ultimate" ;;
        "2022" | "win2022" | "server2022" )
            VERSION="win2022-eval" ;;
        "2019" | "win2019" | "server2019" )
            VERSION="win2019-eval" ;;
    esac

    return 0
}

# Get language info
getLanguage() {
    local id="$1"
    local ret="$2"
    local lang="" desc="" short="" culture=""

    case "${id,,}" in
        "en" | "en-"* )
            short="en"; lang="English"; desc="English"; culture="en-US" ;;
        "zh" | "zh-"* | "cn" | "cn-"* | "chinese" )
            short="cn"; lang="Chinese (Simplified)"; desc="Chinese"; culture="zh-CN" ;;
        "tw" | "zh-tw" )
            short="tw"; lang="Chinese (Traditional)"; desc="Chinese TW"; culture="zh-TW" ;;
        "ja" | "ja-"* | "jp" | "japanese" )
            short="ja"; lang="Japanese"; desc="Japanese"; culture="ja-JP" ;;
        "ko" | "ko-"* | "kr" | "korean" )
            short="ko"; lang="Korean"; desc="Korean"; culture="ko-KR" ;;
        "de" | "de-"* | "german" )
            short="de"; lang="German"; desc="German"; culture="de-DE" ;;
        "fr" | "fr-"* | "french" )
            short="fr"; lang="French"; desc="French"; culture="fr-FR" ;;
        "es" | "es-"* | "spanish" )
            short="es"; lang="Spanish"; desc="Spanish"; culture="es-ES" ;;
        "ru" | "ru-"* | "russian" )
            short="ru"; lang="Russian"; desc="Russian"; culture="ru-RU" ;;
        "pt" | "pt-"* | "portuguese" )
            short="pt"; lang="Portuguese"; desc="Portuguese"; culture="pt-BR" ;;
        "it" | "it-"* | "italian" )
            short="it"; lang="Italian"; desc="Italian"; culture="it-IT" ;;
        * )
            short="en"; lang="English"; desc="English"; culture="en-US" ;;
    esac

    case "${ret,,}" in
        "desc" ) echo "$desc" ;;
        "name" ) echo "$lang" ;;
        "code" ) echo "$short" ;;
        "culture" ) echo "$culture" ;;
        *) echo "$desc" ;;
    esac
}

# Parse LANGUAGE
parseLanguage() {
    LANGUAGE="${LANGUAGE//_/-}"
    [ -z "$LANGUAGE" ] && LANGUAGE="en"

    case "${LANGUAGE,,}" in
        "chinese" | "cn" ) LANGUAGE="zh" ;;
        "english" ) LANGUAGE="en" ;;
        "japanese" ) LANGUAGE="ja" ;;
        "korean" ) LANGUAGE="ko" ;;
        "german" | "deutsch" ) LANGUAGE="de" ;;
        "french" | "français" ) LANGUAGE="fr" ;;
        "spanish" | "español" ) LANGUAGE="es" ;;
        "russian" | "русский" ) LANGUAGE="ru" ;;
    esac
}

# Print version name
printVersion() {
    local id="$1"
    local desc=""

    case "${id,,}" in
        "win7"* ) desc="Windows 7" ;;
        "win8"* ) desc="Windows 8" ;;
        "win10"* ) desc="Windows 10" ;;
        "win11"* ) desc="Windows 11" ;;
        "win2019"* ) desc="Windows Server 2019" ;;
        "win2022"* ) desc="Windows Server 2022" ;;
        * ) desc="Windows" ;;
    esac

    echo "$desc"
}

return 0
