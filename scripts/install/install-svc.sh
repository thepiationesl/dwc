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
        # 锁版本：从 GitHub release 拉固定版本 tarball，避免每次构建拿到最新版（不可复现）
        # 升级策略：改 CODE_VERSION env 重新构建即可
        if [ "$DISTRO_FAMILY" = "debian" ]; then
            export DEBIAN_FRONTEND=noninteractive
            install_pkgs curl tar
            CODE_VERSION="${CODE_VERSION:-4.103.0}"
            ARCH="$(dpkg --print-architecture)"
            case "$ARCH" in
                amd64) CODE_ARCH="x86_64" ;;
                arm64) CODE_ARCH="arm64" ;;
                *)     CODE_ARCH="x86_64" ;;
            esac
            mkdir -p /usr/local/code-server
            if curl -fsSL \
                "https://github.com/coder/code-server/releases/download/v${CODE_VERSION}/code-server-${CODE_VERSION}-linux-${CODE_ARCH}.tar.gz" \
                -o /tmp/code-server.tar.gz 2>/dev/null; then
                tar -xzf /tmp/code-server.tar.gz -C /usr/local/code-server --strip-components=1
                ln -sf /usr/local/code-server/bin/code-server /usr/local/bin/code-server
                rm -f /tmp/code-server.tar.gz
            else
                echo "!! [dwc] code-server ${CODE_VERSION} 下载失败，回退到 install.sh"
                curl -fsSL https://code-server.dev/install.sh | sh 2>/dev/null || \
                    echo "!! [dwc] code-server 安装失败，请检查网络"
            fi
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
