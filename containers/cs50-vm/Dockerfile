# CS50 Windows VM - Minimal for GitHub Codespaces
# Base: debian:unstable-slim
# Target size: < 1.5GB (with VirtIO drivers)
# Compatible with dockur/windows interface

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Windows VM - CS50 Codespaces optimized"
LABEL version="2.0.0"

ARG TARGETARCH=amd64

# Environment - CS50 compatible
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    # VM Configuration
    VERSION="10" \
    MANUAL="Y" \
    LANGUAGE="Chinese" \
    CPU_CORES="4" \
    RAM_SIZE="8G" \
    DISK_SIZE="64G" \
    # dockur/windows compatible
    KEYBOARD="" \
    REGION="" \
    USERNAME="" \
    PASSWORD="" \
    BOOT_MODE="" \
    DISK_TYPE="" \
    TPM="N" \
    SECBOOT="N" \
    DEBUG="N" \
    # Paths
    HOME=/workspaces \
    STORAGE=/storage

# Configure Debian mirrors (IPv6)
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/mirrors/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list

# Install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    bash \
    tini \
    sudo \
    curl \
    wget \
    git \
    jq \
    acl \
    procps \
    # Node.js (required for VSCode extensions)
    nodejs \
    npm \
    # Archive tools
    xz-utils \
    p7zip-full \
    cabextract \
    wimtools \
    genisoimage \
    libarchive-tools \
    # Disk tools
    dosfstools \
    mtools \
    # QEMU core only
    qemu-system-x86 \
    qemu-utils \
    ovmf \
    # Network
    netcat-openbsd \
    iproute2 \
    iptables \
    dnsmasq \
    # Samba share
    samba \
    samba-common-bin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure npm mirror
RUN npm config set registry http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm

# Create directories
RUN mkdir -p /run /storage /shared /var/drivers /workspaces /opt/cs50/bin /opt/vm && \
    chmod 755 /run /storage /shared /var/drivers /workspaces

# Download VirtIO drivers
RUN cd /var/drivers && \
    curl -fsSL -o virtio-win.tar.xz \
    "https://github.com/qemus/virtiso-whql/releases/download/v1.9.49-0/virtio-win-1.9.49.tar.xz" && \
    tar -xf virtio-win.tar.xz && \
    rm -f virtio-win.tar.xz

# Copy VM scripts
COPY scripts/ /opt/vm/
RUN chmod +x /opt/vm/*.sh /opt/vm/vm-* 2>/dev/null || true && \
    ln -sf /opt/vm/vm-setup /usr/local/bin/vm-setup && \
    ln -sf /opt/vm/vm-start /usr/local/bin/vm-start && \
    ln -sf /opt/vm/vm-stop /usr/local/bin/vm-stop && \
    ln -sf /opt/vm/vm-status /usr/local/bin/vm-status

# CS50 scripts removed (directory not present)

# Configure bash for login shell
RUN echo '\nshopt -q login_shell || exec bash --login -i' >> /etc/bash.bashrc

# Version marker
RUN echo "2.0.0-cs50" > /run/version

# Volumes
VOLUME ["/storage", "/shared", "/workspaces"]

# Ports: VNC, WebSocket, RDP, SMB
EXPOSE 5900 5700 3389 445

# Working directory
WORKDIR /workspaces

# Entry: tini -> bash (manual mode default)
ENTRYPOINT ["/usr/bin/tini", "-s", "--"]
CMD ["/bin/bash", "--login"]
