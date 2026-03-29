# DWC Windows VM - Automatic Installation Mode
# Base: debian:unstable-slim
# Automatically installs Windows using Sysprep
# Compatible with dockur/windows interface
# Target size: < 700MB (image only, plus Windows ISO)

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Windows VM container - Automatic installation mode"
LABEL version="1.0.0"

ARG TARGETARCH=amd64

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    VERSION="10" \
    MANUAL="N" \
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
    jq \
    yq \
    xz-utils \
    p7zip-full \
    cabextract \
    wimtools \
    dosfstools \
    mtools \
    genisoimage \
    libxml2-utils \
    qemu-system-x86 \
    qemu-utils \
    ovmf \
    swtpm \
    netcat-openbsd \
    samba \
    samba-common-bin \
    libarchive-tools \
    tini \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create directories
RUN mkdir -p /run /storage /shared /var/drivers /tmp/qemu /sysprep && \
    chmod 755 /run /storage /shared /var/drivers /tmp/qemu /sysprep

# Copy VM scripts
COPY scripts/ /run/
RUN chmod -R 755 /run/*

# Copy Sysprep files (user should mount these if needed)
RUN echo "Note: Mount Sysprep files to /sysprep for automatic installation"

# Download VirtIO drivers
RUN cd /var/drivers && \
    curl -fsSL -o virtio-win.tar.xz "https://github.com/qemus/virtiso-whql/releases/download/v1.9.49-0/virtio-win-1.9.49.tar.xz" && \
    tar -xf virtio-win.tar.xz && \
    rm -f virtio-win.tar.xz || true

# Clean up QEMU firmware (keep only Windows 10 essentials)
RUN cd /usr/share/qemu && \
    rm -rf \
        palcode-* \
        s390-* \
        slof* \
        openbios-* \
        opensbi-* \
        u-boot* \
        qemu-nsis.bmp \
        edk2-arm* \
        edk2-aarch64* \
        bamboo.dtb \
        canyonlands.dtb \
        hppa-firmware.img \
        npcm7xx_bootrom.bin \
        petalogix-*.dtb \
        *ppc* \
        *sparc* \
        skiboot.lid \
        trace-events-all \
    2>/dev/null || true

# Create version marker
RUN echo "1.0.0-auto" > /run/version

# Volumes and ports
VOLUME ["/storage", "/shared", "/sysprep"]
EXPOSE 5900 5700 7100 3389 445

# Entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]