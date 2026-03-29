# CS50 Windows VM - Optimized for Harvard CS50 Course
# Base: debian:unstable-slim
# Tailored for CS50 virtual machine labs
# Removed: Docker, unnecessary tools
# Kept: KVM support, network tools, code editors
# Target size: < 500MB (image only)

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Windows VM container - CS50 optimized version"
LABEL version="1.0.0-cs50"

ARG TARGETARCH=amd64

# Environment - optimized for CS50
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    VERSION="10" \
    MANUAL="Y" \
    LANGUAGE="English" \
    CPU_CORES="4" \
    RAM_SIZE="8G" \
    DISK_SIZE="40G" \
    KEYBOARD="us" \
    REGION="US"

# Configure Debian mirrors
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    apt-get update

# Install dependencies (minimal, no Docker)
RUN apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    git \
    htop \
    jq \
    nodejs \
    npm \
    acl \
    dwarfdump \
    xz-utils \
    p7zip-full \
    cabextract \
    wimtools \
    dosfstools \
    mtools \
    genisoimage \
    libxml2-utils \
    qemu-system-x86 \
    qemu-img \
    qemu-system-modules-usb \
    ovmf \
    swtpm \
    netcat-openbsd \
    samba \
    samba-common-tools \
    libarchive-tools \
    tini \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install VS Code dependencies (if needed for extensions in the future)
RUN mkdir -p /opt/cs50/extensions /opt/cs50/bin

# Create directories
RUN mkdir -p /run /storage /shared /var/drivers /tmp/qemu && \
    chmod 755 /run /storage /shared /var/drivers /tmp/qemu

# Copy VM scripts
COPY --chmod=755 vm/scripts/ /run/
COPY cs50/vm/etc /etc
COPY cs50/vm/opt /opt

RUN chmod a+rx /opt/cs50/bin/* && \
    echo "\nshopt -q login_shell || exec bash --login -i" >> /etc/bash.bashrc

# Download VirtIO drivers
RUN cd /var/drivers && \
    curl -fsSL -o virtio-win.tar.xz "https://github.com/qemus/virtiso-whql/releases/download/v1.9.49-0/virtio-win-1.9.49.tar.xz" && \
    tar -xf virtio-win.tar.xz && \
    rm -f virtio-win.tar.xz || true

# Create version marker
RUN echo "1.0.0-cs50" > /run/version

# Volumes and ports
VOLUME ["/storage", "/shared"]
EXPOSE 5000 5900 5700 7100 8080 8082 8787 3389 445

# Entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
