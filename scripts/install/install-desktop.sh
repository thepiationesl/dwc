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
        # 中文字体 + 输入法 + locales（Kali 桌面主力中文体验）
        install_pkgs fonts-noto-cjk fonts-wqy-microhei fonts-wqy-zenhei \
            fcitx5 fcitx5-rime fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
            locales 2>/dev/null || true
        # 生成 zh_CN locale（幂等：locale-gen 会跳过已存在的）
        if command -v locale-gen >/dev/null 2>&1; then
            sed -i 's/^# *zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
            sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
            locale-gen zh_CN.UTF-8 en_US.UTF-8 2>/dev/null || true
        fi
        # 若 LANG 已经设置为 zh_CN，则全局切到中文
        case "${LANG:-}" in
            zh_CN*)
                update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 2>/dev/null || true
                ;;
        esac
        ;;
esac

# noVNC 提供浏览器访问
if [ -d /usr/share/novnc ]; then
    echo "==> [dwc] noVNC 已安装于 /usr/share/novnc"
fi

cleanup_pkgs
echo "==> [dwc] install-desktop: done"
