# DWC Windows VM - Manual Installation Mode
# Base: debian:unstable-slim
# Users must manually download and install Windows
# Compatible with dockur/windows interface
# Target size: < 600MB (image only)

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Windows VM container - Manual installation mode"
LABEL version="1.0.0"

ARG TARGETARCH=amd64

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    VERSION="10" \
    MANUAL="Y" \
    LANGUAGE="Chinese" \
    KEYBOARD="" \
    REGION="" \
    USERNAME="" \
    PASSWORD="" \
    DISK_SIZE="64G" \
    RAM_SIZE="4G" \
    CPU_CORES="2" \
    BOOT_MODE="" \
    MACHINE="" \
    ALLOCATE="" \
    DISK_TYPE="" \
    DISK_FLAGS="" \
    DISK_CACHE="" \
    VGA="" \
    USB="" \
    TPM="N" \
    SECBOOT="N" \
    REMOVE="" \
    VERIFY="" \
    DEBUG="N" \
    ARGUMENTS="" \
    HV="N" \
    VMX="N"

# Configure Debian mirrors
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    apt-get update

# Install dependencies
RUN apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    htop \
    jq \
    yq \
    xz-utils \
    p7zip-full \
    cabextract \
    wimtools \
    dosfstools \
    mtools \
    genisoimage \
    cdrkit \
    libxml2-utils \
    docker.io \
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

# Create directories
RUN mkdir -p /run /storage /shared /var/drivers /tmp/qemu && \
    chmod 755 /run /storage /shared /var/drivers /tmp/qemu

# Copy VM scripts
COPY --chmod=755 scripts/ /run/

# Download VirtIO drivers
RUN cd /var/drivers && \
    curl -fsSL -o virtio-win.tar.xz "https://github.com/qemus/virtiso-whql/releases/download/v1.9.49-0/virtio-win-1.9.49.tar.xz" && \
    tar -xf virtio-win.tar.xz && \
    rm -f virtio-win.tar.xz || true

# Create version marker
RUN echo "1.0.0-manual" > /run/version

# Volumes and ports
VOLUME ["/storage", "/shared"]
EXPOSE 5900 5700 7100 3389 445

# Entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
