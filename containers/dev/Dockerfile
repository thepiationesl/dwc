# Dev Container - Standard Development Environment
# Base: debian:unstable-slim
# Target size: < 1.2GB

FROM debian:unstable-slim

LABEL maintainer="DWC Project"
LABEL description="Debian development environment with Docker, Node.js, Python, QEMU"
LABEL version="2.0.0"

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    HOME=/workspaces \
    CONFIG_DIR=/workspaces \
    USER_NAME=dev \
    USER_UID=1000 \
    USER_GID=1000 \
    NODE_OPTIONS="--max-old-space-size=512"

# Configure Debian mirrors (IPv6)
RUN echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/mirrors/debian unstable main contrib non-free non-free-firmware" > /etc/apt/sources.list

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Shell and tools
    bash \
    sudo \
    htop \
    vim-tiny \
    curl \
    wget \
    git \
    jq \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Node.js
    nodejs \
    npm \
    # Network
    openssh-client \
    iputils-ping \
    iproute2 \
    # Build tools
    build-essential \
    ca-certificates \
    gnupg \
    # Docker CLI
    docker.io \
    docker-compose \
    # QEMU
    qemu-system-x86 \
    qemu-utils \
    # Utilities
    tzdata \
    locales \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure npm mirror
RUN npm config set registry http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm

# Create user
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -d /workspaces -u ${USER_UID} -g ${USER_NAME} -m -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:toor" | chpasswd && \
    echo "root:toor" | chpasswd

# Configure sudo - allow TAP device operations
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 440 /etc/sudoers.d/${USER_NAME} && \
    usermod -aG docker ${USER_NAME}

# Setup shell configuration
COPY skel/.bashrc /etc/skel/.bashrc
COPY skel/.profile /etc/skel/.profile

# Copy scripts
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-permissions.sh

# Create workspaces directory
RUN mkdir -p /workspaces && \
    cp -a /etc/skel/. /workspaces/ && \
    chown -R ${USER_NAME}:${USER_NAME} /workspaces && \
    chmod 755 /workspaces

# Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

# Volume
VOLUME ["/workspaces"]

# Working directory
WORKDIR /workspaces

# User
USER ${USER_NAME}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
