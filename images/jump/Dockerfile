# jump - SSH 端口转发容器（Alpine）
# 部分环境只开一个端口，专门跑 openssh-server 做端口转发
# 注意：dropbear 不支持端口转发，故用 openssh-server（AllowTcpForwarding yes）
FROM alpine:3.24

LABEL org.dwc.image="jump" \
      org.dwc.role="functional" \
      org.dwc.desc="SSH 端口转发容器（openssh-server）"

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh openssh \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs

ENV ENABLE_VNC=false \
    ENABLE_SSH=true \
    SSH_PORT=2222 \
    ALLOW_PASSWORD=yes

VOLUME ["/config"]

# SSH 22 标准端口（跳板机场景）或自定义 SSH_PORT
EXPOSE 22 2222

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
