#!/usr/bin/env bash
# install-base.sh - 基础环境：supervisord、用户、/config、skel、rootfs、SSH
# 用法：install-base.sh [dropbear|openssh]   （默认 dropbear；jump 用 openssh）
set -euo pipefail

. "$(dirname "$0")/../common/lib.sh"

SSH_MODE="${1:-dropbear}"

echo "==> [dwc] install-base: distro=${DISTRO_ID} family=${DISTRO_FAMILY} ssh=${SSH_MODE}"

# 基础工具与 supervisord
case "$DISTRO_FAMILY" in
    alpine)
        install_pkgs bash shadow su-exec tzdata ca-certificates supervisord
        ;;
    debian)
        install_pkgs bash sudo tzdata ca-certificates supervisor openssh-client
        ;;
esac

# 时区默认 UTC，可用 TZ 环境变量覆盖
ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || true

# 用户、目录、skel
setup_users
setup_config_dir
install_skel

# SSH：常规镜像 dropbear，jump 用 openssh-server
case "$SSH_MODE" in
    openssh)
        install_pkgs openssh-server
        mkdir -p /run/sshd /etc/ssh
        echo "ALLOW_PASSWORD=${ALLOW_PASSWORD:-yes}" > /etc/dwc-ssh.env
        ;;
    *)
        case "$DISTRO_FAMILY" in
            alpine) install_pkgs dropbear ;;
            debian) install_pkgs dropbear-run ;;
        esac
        ;;
esac

# rootfs 覆盖安装（supervisor 配置、wrapper 脚本、dwc-if 等）
if [ -d /opt/dwc/rootfs ]; then
    cp -a /opt/dwc/rootfs/. /
    chmod +x /usr/local/bin/dwc-* 2>/dev/null || true
fi

# 确保 supervisor 主配置存在
mkdir -p /etc/supervisor/conf.d
if [ -f /etc/supervisord.conf ]; then
    : # 已存在，rootfs 提供
fi

cleanup_pkgs
echo "==> [dwc] install-base: done"
