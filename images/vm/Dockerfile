# vm - QEMU 虚拟机容器
# 当前仅预装 qemu 二进制；VM 启动 / Web 控制台（dockur 反向热插拔方案）尚未实现
FROM debian:stable-slim

LABEL org.dwc.image="vm" \
      org.dwc.role="functional" \
      org.dwc.desc="QEMU 虚拟机容器（仅预装 qemu，启动逻辑待实现）"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-svc.sh vm \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

ENV ENABLE_VNC=false \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

# ssh 2222（QEMU VNC 5900 / websockify 6080 待实现，未接 supervisord）
EXPOSE 2222

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
