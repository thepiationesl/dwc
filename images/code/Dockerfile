# code - vscode 网页版（code-server）
# 参考 linuxserver/docker-code-server；容器重置数据不丢，浏览器访问
FROM debian:stable-slim

LABEL org.dwc.image="code" \
      org.dwc.role="functional" \
      org.dwc.desc="code-server vscode 网页版（浏览器访问）"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh code \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=false \
    ENABLE_CODE=true \
    CODE_PASSWORD=toor \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

# code-server 8443 / ssh 2222
EXPOSE 2222 8443

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
