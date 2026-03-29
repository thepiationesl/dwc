# Debian Dev - Lightweight Development Environment
# Base: debian:unstable-slim
# Target size: < 900MB
# Memory overhead: < 1.5GB when running

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Debian Linux lightweight development environment with Docker, Node.js, Python, QEMU - optimized for Codespaces"

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    CONFIG_DIR=/config \
    USER_NAME=qwe \
    USER_UID=1000 \
    USER_GID=1000 \
    NODE_OPTIONS="--max-old-space-size=512"

# Configure Debian mirrors for faster installation
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb-src http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian unstable main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    apt-get update

# Install packages - minimal but functional
RUN apt-get install -y --no-install-recommends \
    # Shell and basic tools
    bash \
    sudo \
    htop \
    vim-tiny \
    curl \
    wget \
    git \
    # Python (minimal)
    python3 \
    python3-pip \
    python3-minimal \
    # Node.js
    nodejs \
    npm \
    # Network tools
    openssh-client \
    iputils-ping \
    # Build tools (minimal)
    build-essential \
    ca-certificates \
    gnupg \
    # Docker CLI (for Docker outside of Docker)
    docker.io \
    docker-compose \
    # QEMU (minimal - only x86_64)
    qemu-system-x86 \
    qemu-img \
    # Additional utilities
    tzdata \
    locales \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure npm to use custom mirror
RUN npm config set registry http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm

# Create user group and user
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -d ${CONFIG_DIR} -u ${USER_UID} -g ${USER_NAME} -m -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:toor" | chpasswd && \
    echo "root:toor" | chpasswd

# Configure sudo - allow user to run docker without password
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 440 /etc/sudoers.d/${USER_NAME} && \
    usermod -aG docker ${USER_NAME}

# Setup shell configuration
COPY skel/.bashrc /etc/skel/.bashrc
COPY skel/.profile /etc/skel/.profile

# Copy entrypoint and scripts
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-permissions.sh

# Create config directory and copy skel files
RUN mkdir -p ${CONFIG_DIR} && \
    cp -a /etc/skel/. ${CONFIG_DIR}/ && \
    chown -R ${USER_NAME}:${USER_NAME} ${CONFIG_DIR} && \
    chmod 755 ${CONFIG_DIR}

# Optimize for minimal disk usage - remove unnecessary packages
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

# Volume for persistent data
VOLUME ["/config"]

# Working directory
WORKDIR ${CONFIG_DIR}

# Default user
USER ${USER_NAME}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
