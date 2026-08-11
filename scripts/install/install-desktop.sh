#!/usr/bin/env bash
# install-desktop.sh - 桌面环境（桌面型镜像共用）
# 用法：install-desktop.sh <xfce4|icewm>
set -euo pipefail

. "$(dirname "$0")/../common/lib.sh"

WM="${1:-xfce4}"

# 读取 Debian 具体大版本，Debian 11 用 tightvncserver（无 tigervnc-standalone-server 适配包）
DEBIAN_VER=""
if [ "$DISTRO_FAMILY" = "debian" ]; then
    DEBIAN_VER="$(. /etc/os-release 2>/dev/null; echo "${VERSION_ID:-}")"
fi

echo "==> [dwc] install-desktop: wm=${WM} distro=${DISTRO_ID} ver=${DEBIAN_VER}"

case "$DISTRO_FAMILY" in
    alpine)
        # Alpine 轻量桌面（功能型容器如 chat 使用）
        # Alpine 无可靠 tigervnc 服务端包，回退 Xvfb + x11vnc
        install_pkgs xvfb x11vnc xvfb-run
        case "$WM" in
            icewm) install_pkgs icewm xterm ;;
            *)     install_pkgs xfce4 xfce4-terminal ;;
        esac
        ;;
    debian)
        # Debian / Kali 桌面（Kali 使用 kali-tweaks 设置中文）
        # 用 TigerVNC 的 Xvnc 作为 X 服务 + VNC 服务（一体化，取代 Xvfb+x11vnc）
        export DEBIAN_FRONTEND=noninteractive
        if [ "$DEBIAN_VER" = "11" ]; then
            # Debian 11：tightvncserver（提供 Xvnc + vncpasswd）
            install_pkgs tightvncserver novnc websockify x11-utils dbus-x11
        else
            # Debian 12+ / Kali：tigervnc-standalone-server + tigervnc-tools
            install_pkgs tigervnc-standalone-server tigervnc-tools novnc websockify x11-utils dbus-x11
        fi
        case "$WM" in
            icewm)
                install_pkgs icewm xterm
                ;;
            *)
                install_pkgs xfce4 xfce4-terminal thunar
                ;;
        esac
        # 中文字体（Kali 桌面主力）
        install_pkgs fonts-noto-cjk fonts-wqy-microhei 2>/dev/null || true
        ;;
esac

# noVNC 提供浏览器访问
if [ -d /usr/share/novnc ]; then
    echo "==> [dwc] noVNC 已安装于 /usr/share/novnc"
fi

cleanup_pkgs
echo "==> [dwc] install-desktop: done"
