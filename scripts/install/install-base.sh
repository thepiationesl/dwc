#!/bin/sh
# install-base.sh - 基础环境：supervisord、用户、/config、skel、rootfs、SSH
# 用法：install-base.sh [dropbear|openssh]   （默认 dropbear；jump 用 openssh）
# /bin/sh 兼容：调用者必须确保 bash 已装（本文件依赖 $(...) 和 set -e）
# 我们先装 bash 再 . lib.sh
set -eu

# 先把 bash 装好：后续 install-*.sh 都靠 bash
if command -v bash >/dev/null 2>&1; then
    :
else
    case "$(. /etc/os-release 2>/dev/null && echo "${ID:-}")" in
        alpine)
            apk add --no-cache bash >/dev/null 2>&1 || true
            ;;
        debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq >/dev/null 2>&1 || true
            apt-get install -y --no-install-recommends bash >/dev/null 2>&1 || true
            ;;
    esac
fi

. "$(dirname "$0")/../common/lib.sh"

SSH_MODE="${1:-dropbear}"

echo "==> [dwc] install-base: distro=${DISTRO_ID} family=${DISTRO_FAMILY} ssh=${SSH_MODE}"

# 基础工具与 supervisord
case "$DISTRO_FAMILY" in
    alpine)
        # Alpine 3.24 包名为 supervisor（历史上叫 supervisord）；兼容旧名自动 fallback
        apk add --no-cache bash shadow su-exec tzdata ca-certificates supervisor 2>/dev/null || \
            apk add --no-cache bash shadow su-exec tzdata ca-certificates supervisord
        ;;
    debian)
        install_pkgs bash sudo tzdata ca-certificates supervisor openssh-client
        ;;
esac

# 时区默认 UTC，可用 TZ 环境变量覆盖
ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || true

# 用户、目录
setup_users
setup_config_dir

# SSH：常规镜像 dropbear，jump 用 openssh-server
case "$SSH_MODE" in
    openssh)
        install_pkgs openssh-server
        mkdir -p /run/sshd /etc/ssh
        echo "ALLOW_PASSWORD=${ALLOW_PASSWORD:-yes}" > /etc/dwc-ssh.env
        ;;
    *)
        # Debian/Kali：dropbear；不同 distro 包名略有差异，兼容 fallback
        case "$DISTRO_FAMILY" in
            alpine) install_pkgs dropbear ;;
            *)      apt-get install -y --no-install-recommends dropbear 2>/dev/null || \
                       apt-get install -y --no-install-recommends dropbear-run 2>/dev/null || true ;;
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
