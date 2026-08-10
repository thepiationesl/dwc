# full - Kali 完整版（无音乐，朋友定制）
# 唯一"重"镜像：VNC/noVNC + NoMachine + Anydesk + xrdp + Chrome
FROM kalilinux/kali-rolling

LABEL org.dwc.image="full" \
      org.dwc.role="desktop" \
      org.dwc.desc="Kali 完整桌面，无音乐，含 NoMachine/Anydesk/xrdp"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/
COPY skel/ /opt/dwc/skel/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-desktop.sh xfce4 \
    && /opt/dwc/scripts/install/install-remote.sh nomachine \
    && /opt/dwc/scripts/install/install-remote.sh anydesk \
    && /opt/dwc/scripts/install/install-remote.sh xrdp \
    && /opt/dwc/scripts/install/install-apps.sh chrome terminator \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs /opt/dwc/skel

# 全远程访问默认开启
ENV ENABLE_VNC=true \
    VNC_PASSWORD=114514 \
    VNC_GEOMETRY=1920x1200x24 \
    ENABLE_NOMACHINE=true \
    NOMACHINE_USER=qwe \
    NOMACHINE_PASSWORD=toor \
    ENABLE_ANYDESK=true \
    ENABLE_XRDP=true \
    ENABLE_SSH=true \
    SSH_PORT=2222

VOLUME ["/config", "/workspace"]

# VNC 5901 / noVNC 6080 / xrdp 3389 / NoMachine 4000 / Anydesk 7070 / ssh 2222
EXPOSE 2222 5901 6080 3389 4000 7070

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
