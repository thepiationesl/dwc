# chat - Pidgin + HexChat 聊天容器（IceWM 轻量桌面）
# 参考 linuxserver/docker-pidgin；VNC/noVNC 轻量可选
FROM alpine:3.24

LABEL org.dwc.image="chat" \
      org.dwc.role="functional" \
      org.dwc.desc="Pidgin + HexChat 聊天（IceWM + VNC/noVNC）"

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh chat \
    && /opt/dwc/scripts/install/install-desktop.sh icewm \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs

ENV ENABLE_VNC=true \
    VNC_PASSWORD=114514 \
    VNC_GEOMETRY=1920x1200x24 \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

EXPOSE 2222 5901 6080

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
