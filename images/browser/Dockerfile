# browser - 无头 chromium 浏览器隔离容器
# 参考 linuxserver/docker-chromium；上 onion 需确保安全，独立容器防被黑
FROM alpine:3.24

LABEL org.dwc.image="browser" \
      org.dwc.role="functional" \
      org.dwc.desc="无头 chromium 浏览器隔离容器"

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh browser \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs

ENV ENABLE_VNC=false \
    ENABLE_CHROMIUM=true \
    CHROME_DEBUG_PORT=9222 \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

EXPOSE 2222 9222

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
