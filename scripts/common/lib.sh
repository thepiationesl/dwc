#!/usr/bin/env bash
# lib.sh - 共享函数库（POSIX 兼容，Alpine ash / Debian bash / Kali bash 均可用）
# 被所有 install-*.sh 与 entrypoint 引用，无外部依赖

set -u

# ---------------------------------------------------------------
# 发行版检测
# ---------------------------------------------------------------
DISTRO_ID=""
if [ -r /etc/os-release ]; then
    DISTRO_ID=$(. /etc/os-release; echo "${ID:-}")
fi
[ -z "$DISTRO_ID" ] && [ -r /etc/alpine-release ] && DISTRO_ID="alpine"

DISTRO_FAMILY="other"
case "$DISTRO_ID" in
    alpine) DISTRO_FAMILY="alpine" ;;
    debian) DISTRO_FAMILY="debian" ;;
    kali)   DISTRO_FAMILY="debian" ;;   # Kali 基于 Debian
esac

# ---------------------------------------------------------------
# 包管理器封装
# ---------------------------------------------------------------
PKG_INSTALL=""
PKG_UPDATE=""
case "$DISTRO_FAMILY" in
    alpine)
        PKG_INSTALL="apk add --no-cache"
        PKG_UPDATE="apk update"
        ;;
    debian)
        PKG_INSTALL="apt-get install -y --no-install-recommends"
        PKG_UPDATE="apt-get update"
        ;;
esac

APT_UPDATED=0
install_pkgs() {
    # install_pkgs pkg1 pkg2 ...
    # 幂等：已安装的包会跳过；update 仅在首次调用时执行一次
    case "$DISTRO_FAMILY" in
        alpine)
            apk add --no-cache "$@"
            ;;
        debian)
            export DEBIAN_FRONTEND=noninteractive
            if [ "$APT_UPDATED" = "0" ]; then
                apt-get update -qq
                APT_UPDATED=1
            fi
            apt-get install -y --no-install-recommends "$@"
            ;;
    esac
}

cleanup_pkgs() {
    case "$DISTRO_FAMILY" in
        alpine)
            rm -rf /var/cache/apk/*
            ;;
        debian)
            apt-get autoremove -y --purge >/dev/null 2>&1 || true
            apt-get clean >/dev/null 2>&1 || true
            rm -rf /var/lib/apt/lists/*
            ;;
    esac
}

# ---------------------------------------------------------------
# 用户创建（qwe:toor / root:toor，与 skel 联动）
# ---------------------------------------------------------------
DEFAULT_USER="qwe"
DEFAULT_PASS="toor"

setup_users() {
    # 确保 qwe 用户存在，带 sudo 权限
    if [ "$DISTRO_FAMILY" = "alpine" ]; then
        addgroup -S qwe 2>/dev/null || true
        adduser -S -G qwe -s /bin/bash -h /home/qwe qwe 2>/dev/null || true
        echo "qwe:$DEFAULT_PASS" | chpasswd 2>/dev/null || true
        echo "root:$DEFAULT_PASS" | chpasswd 2>/dev/null || true
        # alpine 用 sudo 包（如已装）
        if command -v sudo >/dev/null 2>&1; then
            echo "qwe ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/qwe
            chmod 440 /etc/sudoers.d/qwe
        fi
    else
        id -u qwe >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo qwe 2>/dev/null || \
            useradd -m -s /bin/bash qwe
        echo "qwe:$DEFAULT_PASS" | chpasswd
        echo "root:$DEFAULT_PASS" | chpasswd
        echo "qwe ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/qwe
        chmod 440 /etc/sudoers.d/qwe
    fi
    # 复制 skel 到 qwe 家目录（幂等）
    if [ -d /etc/skel ] && [ -d /home/qwe ]; then
        cp -rn /etc/skel/. /home/qwe/ 2>/dev/null || true
        chown -R qwe:qwe /home/qwe 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------
# skel 安装：将项目 skel 目录复制到 /etc/skel
# 注：Kali 保留原生 shell 配置，不执行本函数
# ---------------------------------------------------------------
install_skel() {
    if [ -d /opt/dwc/skel ]; then
        mkdir -p /etc/skel
        cp -rn /opt/dwc/skel/. /etc/skel/ 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------
# /config 持久化目录
# ---------------------------------------------------------------
setup_config_dir() {
    mkdir -p /config
    chmod 755 /config
}
