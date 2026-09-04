# studio - Kali 音乐工作站
# Synthesizer V Studio + OBS + VLC + ffmpeg + rosegarden
# 音频走 xrdp-pulseaudio / NoMachine（VNC 不能传声音）
FROM kalilinux/kali-rolling

LABEL org.dwc.image="studio" \
      org.dwc.role="desktop" \
      org.dwc.desc="Kali 音乐工作站，音频走 xrdp-pulseaudio/NoMachine"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 TZ=UTC

COPY scripts/ /opt/dwc/scripts/
COPY rootfs/ /opt/dwc/rootfs/

RUN chmod +x /opt/dwc/scripts/install/*.sh \
    && /opt/dwc/scripts/install/install-base.sh dropbear \
    && /opt/dwc/scripts/install/install-desktop.sh xfce4 \
    && /opt/dwc/scripts/install/install-apps.sh studio obs vlc ffmpeg rosegarden \
    && /opt/dwc/scripts/install/install-remote.sh nomachine \
    && /opt/dwc/scripts/install/install-remote.sh anydesk \
    && /opt/dwc/scripts/install/install-remote.sh xrdp \
    && rm -rf /opt/dwc/scripts /opt/dwc/rootfs

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

EXPOSE 2222 5901 6080 3389 4000 7070

ENTRYPOINT ["/usr/local/bin/dwc-entrypoint"]
