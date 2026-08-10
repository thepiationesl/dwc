# lite - Debian 极低配桌面（xfce4）
# 适配 1c1g10g 低配 VPS
FROM debian:stable-slim

LABEL org.dwc.image="lite" \
      org.dwc.role="desktop" \
      org.dwc.desc="Debian 极低配桌面（xfce4），VNC/noVNC"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-desktop.sh xfce4 \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=true \
    VNC_PASSWORD=114514 \
    VNC_GEOMETRY=1920x1200x24 \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

EXPOSE 2222 5901 6080

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
