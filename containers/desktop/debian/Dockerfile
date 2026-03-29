# Debian Desktop - XFCE4 with VNC
# Base: debian:unstable-slim

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Debian XFCE4 desktop with VNC and noVNC"

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    CONFIG_DIR=/config \
    USER_NAME=qwe \
    USER_UID=1000 \
    USER_GID=1000 \
    DESKTOP_MODE=true \
    VNC_GEOMETRY=1920x1080 \
    VNC_DEPTH=24 \
    VNC_PASSWORD=114514

# Configure Debian mirrors
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Basic tools
    dialog \
    vim \
    git \
    htop \
    openssh-client \
    iproute2 \
    iputils-ping \
    sudo \
    unzip \
    curl \
    wget \
    ca-certificates \
    # D-Bus
    dbus-x11 \
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    # VNC
    tigervnc-standalone-server \
    tigervnc-tools \
    # noVNC
    novnc \
    python3-websockify \
    # Archive manager
    file-roller \
    # Terminal
    terminator \
    # Fonts
    fonts-noto-core \
    fonts-noto-cjk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Google Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install RealVNC Viewer (download deb)
RUN curl -fsSL -o /tmp/realvnc-viewer.deb "https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-7.6.1-Linux-x64.deb" && \
    dpkg -i /tmp/realvnc-viewer.deb || apt-get install -f -y && \
    rm -f /tmp/realvnc-viewer.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create user
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -u ${USER_UID} -g ${USER_GID} -d ${CONFIG_DIR} -s /bin/bash -m ${USER_NAME} && \
    echo "${USER_NAME}:toor" | chpasswd && \
    echo "root:toor" | chpasswd

# Configure sudo
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 440 /etc/sudoers.d/${USER_NAME}

# Setup skel directory
COPY skel/.bashrc /etc/skel/.bashrc
COPY skel/.profile /etc/skel/.profile

# VNC startup script
RUN mkdir -p /etc/skel/.vnc && \
    echo '#!/bin/bash\nstartxfce4 &' > /etc/skel/.vnc/xstartup && \
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

# Expose ports
EXPOSE 5901 6080

# Volume for persistent data
VOLUME ["/config"]

# Working directory
WORKDIR ${CONFIG_DIR}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
