# Alpine Privacy - OpenBox + Tor Browser + Pidgin
# Base: alpine:edge
# Privacy-focused lightweight desktop

FROM alpine:edge

LABEL maintainer="DWC Project"
LABEL description="Alpine Linux privacy desktop with OpenBox, Tor Browser, and Pidgin"

# Environment
ENV LANG=C.UTF-8 \
    TZ=UTC \
    CONFIG_DIR=/config \
    USER_NAME=qwe \
    USER_UID=1000 \
    USER_GID=1000 \
    DESKTOP_MODE=true \
    VNC_GEOMETRY=1920x1080 \
    VNC_DEPTH=24 \
    VNC_PASSWORD=114514

# Configure Alpine mirrors
RUN echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine/edge/testing" >> /etc/apk/repositories

# Install packages
RUN apk add --no-cache \
    # Shell and basic tools
    bash \
    sudo \
    htop \
    vim \
    curl \
    wget \
    git \
    # X11 and desktop
    xorg-server \
    xf86-video-vesa \
    xf86-input-evdev \
    xf86-input-libinput \
    dbus \
    dbus-x11 \
    # OpenBox window manager
    openbox \
    obconf \
    tint2 \
    feh \
    # Terminal
    xterm \
    # VNC
    tigervnc \
    # noVNC
    novnc \
    py3-websockify \
    # Privacy tools
    tor \
    pidgin \
    pidgin-otr \
    # File manager
    pcmanfm \
    # Fonts
    font-noto \
    font-noto-cjk \
    # Other utilities
    ca-certificates \
    tzdata \
    shadow \
    xdg-utils

# Download and install Tor Browser
RUN TOR_VERSION="13.5.7" && \
    TOR_ARCH="linux-x86_64" && \
    curl -fsSL -o /tmp/tor-browser.tar.xz \
        "https://www.torproject.org/dist/torbrowser/${TOR_VERSION}/tor-browser-${TOR_ARCH}-${TOR_VERSION}.tar.xz" && \
    mkdir -p /opt && \
    tar -xJf /tmp/tor-browser.tar.xz -C /opt && \
    mv /opt/tor-browser /opt/tor-browser-bundle && \
    rm -f /tmp/tor-browser.tar.xz && \
    # Create symlink
    ln -sf /opt/tor-browser-bundle/Browser/start-tor-browser /usr/local/bin/tor-browser && \
    # Create desktop entry
    mkdir -p /usr/share/applications && \
    cat > /usr/share/applications/tor-browser.desktop << 'EOF'
[Desktop Entry]
Name=Tor Browser
Comment=Anonymous web browsing
Exec=/opt/tor-browser-bundle/Browser/start-tor-browser --detach
Icon=/opt/tor-browser-bundle/Browser/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

# Create user
RUN addgroup -g ${USER_GID} ${USER_NAME} && \
    adduser -D -u ${USER_UID} -G ${USER_NAME} -h ${CONFIG_DIR} -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:toor" | chpasswd && \
    echo "root:toor" | chpasswd

# Configure sudo
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 440 /etc/sudoers.d/${USER_NAME}

# Setup skel directory
COPY skel/.bashrc /etc/skel/.bashrc
COPY skel/.profile /etc/skel/.profile

# OpenBox configuration
RUN mkdir -p /etc/skel/.config/openbox && \
    cat > /etc/skel/.config/openbox/autostart << 'EOF'
# Set wallpaper (dark background)
feh --bg-fill /usr/share/backgrounds/privacy-bg.png 2>/dev/null || xsetroot -solid "#1a1a2e" &

# Start panel
tint2 &

# Start system tray applets
# (none by default for privacy)
EOF

# OpenBox menu
RUN cat > /etc/skel/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="Privacy Desktop">
  <item label="Tor Browser">
    <action name="Execute"><execute>/opt/tor-browser-bundle/Browser/start-tor-browser --detach</execute></action>
  </item>
  <item label="Pidgin">
    <action name="Execute"><execute>pidgin</execute></action>
  </item>
  <separator />
  <item label="Terminal">
    <action name="Execute"><execute>xterm</execute></action>
  </item>
  <item label="File Manager">
    <action name="Execute"><execute>pcmanfm</execute></action>
  </item>
  <separator />
  <menu id="settings-menu" label="Settings">
    <item label="OpenBox Config">
      <action name="Execute"><execute>obconf</execute></action>
    </item>
  </menu>
  <separator />
  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>
</openbox_menu>
EOF

# Tint2 panel configuration
RUN mkdir -p /etc/skel/.config/tint2 && \
    cat > /etc/skel/.config/tint2/tint2rc << 'EOF'
# Tint2 config for privacy desktop
panel_items = LTSC
panel_size = 100% 32
panel_position = bottom center horizontal
panel_background_id = 1

# Backgrounds
rounded = 0
border_width = 0
background_color = #1a1a2e 100
border_color = #0f3460 100

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 4 2 4

# Launcher
launcher_padding = 4 2 4
launcher_icon_size = 24
launcher_item_app = /usr/share/applications/tor-browser.desktop
launcher_item_app = /usr/share/applications/pidgin.desktop

# Clock
time1_format = %H:%M
time2_format = %Y-%m-%d
clock_font = Noto Sans 10
clock_font_color = #ffffff 100
EOF

# VNC startup script
RUN mkdir -p /etc/skel/.vnc && \
    cat > /etc/skel/.vnc/xstartup << 'EOF'
#!/bin/bash
# Start D-Bus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

# Start OpenBox
openbox-session &
EOF
chmod +x /etc/skel/.vnc/xstartup

# Copy entrypoint and scripts
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-permissions.sh

# Copy noVNC custom pages
COPY novnc /usr/share/novnc/custom/

# Create config directory and initialize
RUN mkdir -p ${CONFIG_DIR} && \
    cp -a /etc/skel/. ${CONFIG_DIR}/ && \
    chown -R ${USER_NAME}:${USER_NAME} ${CONFIG_DIR}

# Fix Tor Browser permissions
RUN chown -R ${USER_NAME}:${USER_NAME} /opt/tor-browser-bundle

# Cleanup
RUN rm -rf /var/cache/apk/* /tmp/* /root/.cache

# Expose ports
EXPOSE 5901 6080

# Volume for persistent data
VOLUME ["/config"]

# Working directory
WORKDIR ${CONFIG_DIR}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
