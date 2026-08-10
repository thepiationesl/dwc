#!/usr/bin/env bash
# install-remote.sh - 远程访问组件（仅 full/studio 使用）
# 用法：install-remote.sh <nomachine|xrdp|anydesk>
set -euo pipefail

. "$(dirname "$0")/../common/lib.sh"

COMPONENT="${1:-}"

echo "==> [dwc] install-remote: component=${COMPONENT}"

# 仅 Kali（debian 系）支持，且容器内需 X 会话
if [ "$DISTRO_FAMILY" != "debian" ]; then
    echo "!! [dwc] install-remote 仅支持 debian 系镜像"
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive

case "$COMPONENT" in
    nomachine)
        # 免费闭源，官方 .deb 直装（参考 kmille36/Docker-Kali-Desktop-NoMachine）
        install_pkgs wget
        ARCH="$(dpkg --print-architecture)"
        cd /tmp
        wget -q "https://download.nomachine.com/download/8.15/Linux/nomachine_8.15.2_${ARCH}.deb" -O nomachine.deb
        apt-get install -y ./nomachine.deb
        rm -f nomachine.deb
        echo "==> [dwc] NoMachine 端口 4000"
        ;;
    xrdp)
        install_pkgs xrdp xorgxrdp
        # 音频需要 xrdp-pulseaudio 模块（VNC 不能传声音）
        apt-get install -y pulseaudio-module-xrdp 2>/dev/null || true
        echo "==> [dwc] xrdp 端口 3389"
        ;;
    anydesk)
        # 容器内需 X 会话，社区方案少，注意坑
        install_pkgs wget
        wget -qO- https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add - 2>/dev/null || true
        echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk.list
        apt-get update -qq
        install_pkgs anydesk
        echo "==> [dwc] Anydesk 端口 7070"
        ;;
    *)
        echo "!! [dwc] 未知组件: ${COMPONENT}"
        exit 1
        ;;
esac

cleanup_pkgs
echo "==> [dwc] install-remote: done"
