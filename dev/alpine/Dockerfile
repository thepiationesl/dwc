# Alpine Dev - Full Development Environment
# Base: alpine:edge
# Target size: < 500MB

FROM alpine:edge

LABEL maintainer="DWC Project"
LABEL description="Alpine Linux development environment with Docker, Node.js, Python, QEMU"

# Environment
ENV LANG=C.UTF-8 \
    TZ=UTC \
    CONFIG_DIR=/config \
    USER_NAME=qwe \
    USER_UID=1000 \
    USER_GID=1000

# Configure Alpine mirrors
RUN echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine/edge/community" >> /etc/apk/repositories

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
    # Python
    python3 \
    py3-pip \
    # Node.js
    nodejs \
    npm \
    # Network tools
    openssh-client \
    # Build tools
    make \
    gnupg \
    # Docker CLI
    docker-cli \
    docker-cli-compose \
    # QEMU
    qemu-system-x86_64 \
    qemu-img \
    # noVNC dependencies
    novnc \
    py3-websockify \
    # Additional utilities
    ca-certificates \
    tzdata \
    shadow

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

# Copy entrypoint and scripts
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-permissions.sh

# Create config directory
RUN mkdir -p ${CONFIG_DIR} && \
    cp -a /etc/skel/. ${CONFIG_DIR}/ && \
    chown -R ${USER_NAME}:${USER_NAME} ${CONFIG_DIR}

# Cleanup
RUN rm -rf /var/cache/apk/* /tmp/* /root/.cache

# Volume for persistent data
VOLUME ["/config"]

# Working directory
WORKDIR ${CONFIG_DIR}

# Default user
USER ${USER_NAME}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
