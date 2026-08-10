# desk - Kali 精简桌面（中文桌面主力，起点镜像）
# 纯 VNC/noVNC，轻量远程访问
FROM kalilinux/kali-rolling

LABEL org.dwc.image="desk" \
      org.dwc.role="desktop" \
      org.dwc.desc="Kali 精简桌面，中文桌面主力（VNC/noVNC）"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

# 复制构建资产（安装脚本 / rootfs / skel）
COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

# 构建：基础 + 桌面 + 应用 + VNC（RUN 链式减少层级）
RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-desktop.sh xfce4 \
    && /opt/dwc/scripts/install/install-apps.sh chrome terminator vncviewer \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

# 默认参数（VNC 密码 114514，分辨率 1920x1200x24）
ENV ENABLE_VNC=true \
    VNC_PASSWORD=114514 \
    VNC_GEOMETRY=1920x1200x24 \
    ENABLE_SSH=true \
    SSH_PORT=2222

# 工作目录持久化
VOLUME ["/config", "/workspace"]

EXPOSE 2222 5901 6080

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
