# asbru - Debian 11 + asbru-cm 远程终端
# asbru-cm 只能在 Debian 11 运行，单开容器
FROM debian:11-slim

LABEL org.dwc.image="asbru" \
      org.dwc.role="desktop" \
      org.dwc.desc="asbru-cm 远程连接管理终端（Debian 11）"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-desktop.sh xfce4 \
    && /opt/dwc/scripts/install/install-apps.sh asbru \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs

ENV ENABLE_VNC=true \
    VNC_PASSWORD=114514 \
    VNC_GEOMETRY=1920x1200x24 \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

EXPOSE 2222 5901 6080

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
