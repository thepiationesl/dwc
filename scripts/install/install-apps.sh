#!/usr/bin/env bash
# install-apps.sh - 应用软件安装（各镜像按需传参调用）
# 用法：install-apps.sh chrome|terminator|vncviewer|python|asbru|studio|obs|vlc|ffmpeg|rosegarden
set -euo pipefail

. "$(dirname "$0")/../common/lib.sh"

install_app() {
    local app="$1"
    case "$app" in
        chrome)
            # Google Chrome（desk/full 桌面主力浏览器）
            if [ "$DISTRO_FAMILY" = "debian" ]; then
                export DEBIAN_FRONTEND=noninteractive
                install_pkgs wget
                wget -qO /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
                apt-get install -y /tmp/chrome.deb || \
                    { apt-get install -y -f && apt-get install -y /tmp/chrome.deb; }
                rm -f /tmp/chrome.deb
            else
                echo "!! [dwc] chrome 仅支持 debian 系"
            fi
            ;;
        terminator)
            install_pkgs terminator
            ;;
        vncviewer)
            # RealVNC Client（desk 参考）
            install_pkgs realvnc-vnc-viewer 2>/dev/null || \
                echo "!! [dwc] realvnc-vnc-viewer 包源未提供，跳过"
            ;;
        python)
            if [ "$DISTRO_FAMILY" = "debian" ]; then
                install_pkgs python3 python3-pip python3-venv python3-dev build-essential
            else
                install_pkgs python3 py3-pip
            fi
            ;;
        asbru)
            # asbru-cm 仅支持 Debian 11
            export DEBIAN_FRONTEND=noninteractive
            install_pkgs wget gpg
            wget -qO /tmp/asbru.gpg "https://packages.asbru-cm.net/asbru.gpg"
            gpg --no-default-keyring --keyring /usr/share/keyrings/asbru.gpg --import /tmp/asbru.gpg 2>/dev/null || true
            echo "deb [signed-by=/usr/share/keyrings/asbru.gpg] https://packages.asbru-cm.net/$(lsb_release -cs) $(lsb_release -cs) main" > /etc/apt/sources.list.d/asbru.list 2>/dev/null || true
            apt-get update -qq
            install_pkgs asbru-cm
            ;;
        studio)
            # Synthesizer V Studio（需要手动下载 license，此处仅装依赖）
            install_pkgs libqt5widgets5 libqt5svg5 libasound2
            ;;
        obs)
            install_pkgs obs-studio
            ;;
        vlc)
            install_pkgs vlc
            ;;
        ffmpeg)
            install_pkgs ffmpeg
            ;;
        rosegarden)
            install_pkgs rosegarden jackd1
            ;;
        qemu)
            install_pkgs qemu-system-x86 qemu-utils
            ;;
        docker-cli)
            # build 容器：仅客户端，连宿主 docker
            install_pkgs docker-cli 2>/dev/null || \
                install_pkgs docker.io 2>/dev/null || true
            ;;
        *)
            echo "!! [dwc] 未知应用: $app"
            exit 1
            ;;
    esac
}

for app in "$@"; do
    echo "==> [dwc] install-app: $app"
    install_app "$app"
done

cleanup_pkgs
echo "==> [dwc] install-apps: done"
