# build - Docker CLI 构建容器
# 构建要连宿主 docker，避免宿主环境变脏；带 docker cli 的独立容器
FROM debian:stable-slim

LABEL org.dwc.image="build" \
      org.dwc.role="functional" \
      org.dwc.desc="Docker CLI 构建容器（连宿主 docker）"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh build \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=false \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

# 宿主 docker.sock 挂载点
VOLUME ["/var/run/docker.sock"]

EXPOSE 2222

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
