# tor - Tor 匿名上网容器
# Tor 客户端 + 代理，支持 .onion 访问，防 DNS 泄漏，高匿名上网
FROM alpine:latest

LABEL org.dwc.image="tor" \
      org.dwc.role="functional" \
      org.dwc.desc="Tor 匿名上网（SOCKS5 代理 + DNS）"

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh tor \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=false \
    ENABLE_TOR=true \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config"]

# ssh 2222 / Tor SOCKS5 9050 / Tor Control 9051 / Tor DNS 5353
EXPOSE 2222 9050 9051 5353

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
