# =========================================================
# Dev Container - Debian (trixie-slim)
# =========================================================

FROM debian:trixie-slim

LABEL maintainer="DWC Project" \
      description="Debian dev env with Docker CLI, Node.js, Python" \
      version="2.1.0"

# =========================================================
# Environment
# =========================================================

ENV LANG=C.UTF-8 \
    TZ=UTC \
    HOME=/workspaces \
    CONFIG_DIR=/workspaces \
    USER_NAME=dev \
    NODE_OPTIONS="--max-old-space-size=512" \
    NPM_CONFIG_PREFIX=/workspaces/.local

# =========================================================
# System Setup + Packages
# =========================================================

RUN set -eux; \
    \
    # ---- APT source ----
    echo "deb http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian trixie main contrib non-free non-free-firmware" \
        > /etc/apt/sources.list; \
    \
    # ---- base deps ----
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dialog \
        gnupg; \
    \
    # ---- docker repo ----
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
    chmod a+r /etc/apt/keyrings/docker.gpg; \
    \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian trixie stable" \
        > /etc/apt/sources.list.d/docker.list; \
    \
    # ---- install packages ----
    apt-get update; \
    apt-get install -y --no-install-recommends \
        sudo \
        htop \
        vim \
        git \
        jq \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        openssh-client \
        iputils-ping \
        iproute2 \
        build-essential \
        locales \
        procps \
        docker-ce-cli \
        docker-compose-plugin; \
    \
    # ---- nodejs (separately, without recommends) ----
    apt-get install -y --no-install-recommends \
        nodejs \
        npm; \
    \
    # ---- cleanup ----
    rm -rf /var/lib/apt/lists/*

# =========================================================
# NPM (user-local)
# =========================================================

RUN set -eux; \
    npm config set registry \
        https://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm/; \
    npm config set prefix "${HOME}/.local"

# =========================================================
# Global PATH (for npm)
# =========================================================

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' \
    > /etc/profile.d/00-local-path.sh \
    && chmod +x /etc/profile.d/00-local-path.sh

# =========================================================
# Replace /etc/skel
# =========================================================

RUN rm -rf /etc/skel/*

COPY skel/ /etc/skel/

RUN chown -R root:root /etc/skel \
    && chmod -R 755 /etc/skel

# =========================================================
# User + Permissions
# =========================================================

RUN set -eux; \
    \
    useradd -m -s /bin/bash -d /workspaces ${USER_NAME}; \
    echo "${USER_NAME}:toor" | chpasswd; \
    echo "root:toor" | chpasswd; \
    \
    usermod -aG sudo ${USER_NAME}; \
    groupadd -f --system -g 800 docker; \
    usermod -aG docker ${USER_NAME}; \
    \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
        > /etc/sudoers.d/${USER_NAME}; \
    chmod 440 /etc/sudoers.d/${USER_NAME}

# =========================================================
# Runtime Scripts
# =========================================================

COPY common/entrypoint.sh      /usr/local/bin/entrypoint.sh
COPY common/fix-permissions.sh /usr/local/bin/fix-permissions.sh

RUN chmod +x \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/fix-permissions.sh

# =========================================================
# Runtime
# =========================================================

VOLUME ["/workspaces"]

WORKDIR /workspaces
USER ${USER_NAME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]