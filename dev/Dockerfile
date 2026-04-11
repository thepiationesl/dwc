FROM debian:sid-slim

ENV LANG=C.UTF-8

RUN apt update -y && apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dialog \
    wget \
    gnupg \
    git \
    git-lfs \
    lsb-release \
    locales \
    sudo \
    procps \
    psmisc \
    rsync \
    supervisor \
    dialog \
    whiptail \
    apt \
    apt-utils \
    file \
    xxd \
    dos2unix \
    unzip \
    p7zip-full \
    xz-utils \
    lz4 \
    pv \
    vim \
    nano \
    bat \
    less \
    jq \
    fzf \
    ripgrep \
    tree \
    zoxide \
    tmux \
    iproute2 \
    net-tools \
    iputils-ping \
    dnsutils \
    whois \
    traceroute \
    mtr \
    openssh-client \
    openssh-sftp-server \
    socat \
    netcat-traditional \
    ntpsec-ntpdate \
    htop \
    lsof \
    strace \
    inotify-tools \
    bc \
    bsdmainutils \
    iftop \
    iotop \
    automake \
    binutils \
    bison \
    flex \
    gawk \
    patch \
    make \
    cmake \
    gcc \
    g++ \
    clang \
    gdb \
    musl \
    musl-tools \
    pkg-config \
    python3-pip \
    pipx \
    nodejs \
    npm \
    golang \
    rust-all \
    php \
    && pipx install uv \
    && rm -rf /var/lib/apt/lists/* 
    
ENV DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]

