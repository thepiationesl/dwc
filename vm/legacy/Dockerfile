# DWC Windows VM (Legacy) - Based on dockur/windows
# Manual mode by default, set MANUAL=N to auto-start
# Target size: < 350MB

FROM alpine:edge

ARG TARGETARCH=amd64

# Mirror source
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    htop \
    jq \
    yq \
    xz \
    p7zip \
    cabextract \
    wimlib \
    dosfstools \
    mtools \
    libarchive \
    libxml2-utils \
    docker-cli \
    qemu-system-x86_64 \
    qemu-img \
    qemu-hw-usb-host \
    ovmf \
    swtpm \
    tini \
    netcat-openbsd \
    samba \
    samba-common-tools \
    && rm -rf /var/cache/apk/*

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

# Create directories
RUN mkdir -p /run /storage /shared /var/drivers /tmp/qemu

# Copy shared VM scripts
COPY scripts/ /run/
RUN chmod -R 755 /run/*

# Download VirtIO drivers (pre-packaged)
ADD https://github.com/qemus/virtiso-whql/releases/download/v1.9.49-0/virtio-win-1.9.49.tar.xz /var/drivers.txz

# Version marker
ARG VERSION_ARG="1.0.0"
RUN echo "$VERSION_ARG" > /run/version

# Volumes and ports
VOLUME /storage
VOLUME /shared
EXPOSE 5900 5700 7100 3389 445

# Environment variables (dockur/windows compatible)
ENV VERSION="10" \
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

# Entry point - manual mode keeps container running
ENTRYPOINT ["/sbin/tini", "-s", "/run/entry.sh"]