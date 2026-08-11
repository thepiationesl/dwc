#!/usr/bin/env bash
# install-svc.sh - 服务型功能镜像安装
# 用法：install-svc.sh <browser|chat|code|build|tor>
set -euo pipefail

. "$(dirname "$0")/../common/lib.sh"

SVC="${1:-}"

echo "==> [dwc] install-svc: ${SVC} distro=${DISTRO_ID}"

case "$SVC" in
    browser)
        # 无头 chromium 浏览器隔离（参考 linuxserver/docker-chromium）
        if [ "$DISTRO_FAMILY" = "alpine" ]; then
            install_pkgs chromium chromium-chromedriver xvfb dbus
        else
            install_pkgs chromium chromium-driver
        fi
        ;;
    chat)
        # Pidgin + HexChat（参考 linuxserver/docker-pidgin）
        case "$DISTRO_FAMILY" in
            alpine) install_pkgs pidgin hexchat ;;
            *)      install_pkgs pidgin hexchat ;;
        esac
        ;;
    code)
        # vscode 网页版（参考 linuxserver/docker-code-server），浏览器访问
        if [ "$DISTRO_FAMILY" = "debian" ]; then
            export DEBIAN_FRONTEND=noninteractive
            install_pkgs curl tar
            mkdir -p /usr/local/code-server
            curl -fsSL https://code-server.dev/install.sh | sh 2>/dev/null || \
                echo "!! [dwc] code-server 安装失败，请检查网络"
        fi
        ;;
    build)
        # Docker CLI 构建容器：连宿主 docker，宿主环境保持干净
        case "$DISTRO_FAMILY" in
            alpine) install_pkgs docker-cli docker-compose ;;
            *)      install_pkgs docker.io docker-compose-v2 2>/dev/null || true ;;
        esac
        ;;
    tor)
        # Tor 匿名上网：客户端 + 代理，支持 .onion
        case "$DISTRO_FAMILY" in
            alpine)
                install_pkgs tor obfs4proxy
                ;;
            *)
                install_pkgs tor torsocks obfs4proxy
                ;;
        esac
        ;;
    *)
        echo "!! [dwc] 未知服务: $SVC"
        exit 1
        ;;
esac

cleanup_pkgs
echo "==> [dwc] install-svc: done"
