# Kali Desktop - Full XFCE4 with Audio and Remote Desktop
# Base: kalilinux/kali-rolling
# Default shell: zsh

FROM kalilinux/kali-rolling

LABEL maintainer="DWC Project"
LABEL description="Kali Linux full desktop with noVNC audio support, Synthesizer V, and multiple remote desktop options"

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    CONFIG_DIR=/config \
    USER_NAME=qwe \
    USER_UID=1000 \
    USER_GID=1000 \
    DESKTOP_MODE=true \
    ENABLE_AUDIO=true \
    VNC_GEOMETRY=1920x1080 \
    VNC_DEPTH=24 \
    VNC_PASSWORD=114514 \
    AUDIO_PORT=6081

# Configure Kali mirrors
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Shell and basic tools (zsh as default)
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    git \
    dialog \
    vim \
    htop \
    openssh-client \
    iproute2 \
    iputils-ping \
    sudo \
    unzip \
    curl \
    wget \
    ca-certificates \
    gnupg \
    # D-Bus
    dbus-x11 \
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    # Kali specific
    kali-defaults \
    kali-desktop-base \
    kali-themes \
    # VNC
    tigervnc-standalone-server \
    tigervnc-tools \
    # noVNC
    novnc \
    python3-websockify \
    # Remote desktop suite
    xrdp \
    # Audio support
    pulseaudio \
    pulseaudio-utils \
    pavucontrol \
    # GStreamer for audio bridge
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-pulseaudio \
    # Node.js for audio WebSocket server
    nodejs \
    npm \
    # Media tools
    obs-studio \
    ffmpeg \
    rosegarden \
    # System info
    fastfetch \
    # Fonts
    fonts-noto-core \
    fonts-noto-cjk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install AnyDesk
RUN curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY | gpg --dearmor -o /usr/share/keyrings/anydesk.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list && \
    apt-get update && apt-get install -y anydesk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install NoMachine
RUN NOMACHINE_URL="https://download.nomachine.com/download/8.14/Linux/nomachine_8.14.2_1_amd64.deb" && \
    curl -fsSL -o /tmp/nomachine.deb "$NOMACHINE_URL" && \
    dpkg -i /tmp/nomachine.deb || apt-get install -f -y && \
    rm -f /tmp/nomachine.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Synthesizer V Studio
RUN mkdir -p /opt/synthesizer-v && \
    curl -fsSL -o /tmp/svstudio.zip "https://archive.org/download/synthesizer-v-studio-1-11-2/svstudio-basic-linux64.zip" && \
    unzip -q /tmp/svstudio.zip -d /opt/synthesizer-v && \
    rm -f /tmp/svstudio.zip && \
    # Create desktop shortcut
    mkdir -p /usr/share/applications && \
    cat > /usr/share/applications/synthesizer-v.desktop << 'EOF'
[Desktop Entry]
Name=Synthesizer V Studio
Comment=Vocal synthesis software
Exec=/opt/synthesizer-v/Synthesizer\ V\ Studio\ Basic
Icon=/opt/synthesizer-v/icon.png
Terminal=false
Type=Application
Categories=Audio;Music;
EOF

# Create user with zsh as default shell
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -u ${USER_UID} -g ${USER_GID} -d ${CONFIG_DIR} -s /bin/zsh -m ${USER_NAME} && \
    echo "${USER_NAME}:toor" | chpasswd && \
    echo "root:toor" | chpasswd

# Configure sudo
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 440 /etc/sudoers.d/${USER_NAME}

# Setup skel directory - copy Kali's default zsh config
RUN cp /etc/skel/.zshrc /etc/skel/.zshrc.bak 2>/dev/null || true
COPY skel/.bashrc /etc/skel/.bashrc
COPY skel/.profile /etc/skel/.profile

# Keep Kali's original .zshrc (just make sure it exists)
RUN test -f /etc/skel/.zshrc || cat > /etc/skel/.zshrc << 'EOF'
# Kali-style zsh configuration
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# Prompt
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Aliases
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# Editor
export EDITOR=vim
EOF

# VNC startup script with PulseAudio
RUN mkdir -p /etc/skel/.vnc && \
    cat > /etc/skel/.vnc/xstartup << 'EOF'
#!/bin/bash
# Start PulseAudio for audio support
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true

# Start XFCE4
startxfce4 &
EOF
chmod +x /etc/skel/.vnc/xstartup

# Copy entrypoint and scripts
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-permissions.sh

# Setup audio bridge
COPY common/audio-bridge /opt/audio-bridge/
RUN cd /opt/audio-bridge && npm install --production && \
    chmod +x /opt/audio-bridge/audio-bridge.sh

# Copy noVNC custom pages
COPY skel/novnc /usr/share/novnc/custom/

# Create config directory and initialize
RUN mkdir -p ${CONFIG_DIR} && \
    cp -a /etc/skel/. ${CONFIG_DIR}/ && \
    chown -R ${USER_NAME}:${USER_NAME} ${CONFIG_DIR}

# Expose ports
# 5901: VNC
# 6080: noVNC
# 6081: Audio WebSocket
# 3389: xrdp
# 4000: NoMachine
EXPOSE 5901 6080 6081 3389 4000

# Volume for persistent data
VOLUME ["/config"]

# Working directory
WORKDIR ${CONFIG_DIR}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
