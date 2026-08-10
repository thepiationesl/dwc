# browser - 无头 chromium 浏览器隔离容器
# 参考 linuxserver/docker-chromium；上 onion 需确保安全，独立容器防被黑
FROM alpine:latest

LABEL org.dwc.image="browser" \
      org.dwc.role="functional" \
      org.dwc.desc="无头 chromium 浏览器隔离容器"

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh browser \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=false \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

EXPOSE 2222

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
