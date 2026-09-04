# 容器统一环境变量（rootfs 覆盖 /etc/profile.d）
export LANG=${LANG:-en_US.UTF-8}
export TZ=${TZ:-UTC}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# VNC 默认参数（可用 docker update --env 覆盖）
export VNC_PASSWORD=${VNC_PASSWORD:-114514}
export VNC_GEOMETRY=${VNC_GEOMETRY:-1920x1200x24}
export VNC_PORT=${VNC_PORT:-5901}
export NOVNC_PORT=${NOVNC_PORT:-6080}

# SSH 默认参数
export ENABLE_SSH=${ENABLE_SSH:-true}
export SSH_PORT=${SSH_PORT:-2222}
export ALLOW_PASSWORD=${ALLOW_PASSWORD:-yes}

# 服务开关（按镜像是否安装自动生效；dwc-if 仅当命令存在且开关为 true 时启动）
export ENABLE_VNC=${ENABLE_VNC:-false}
export ENABLE_NOMACHINE=${ENABLE_NOMACHINE:-true}
export ENABLE_XRDP=${ENABLE_XRDP:-true}
export ENABLE_ANYDESK=${ENABLE_ANYDESK:-true}
export ENABLE_CODE=${ENABLE_CODE:-true}
export ENABLE_TOR=${ENABLE_TOR:-true}
export ENABLE_CHROMIUM=${ENABLE_CHROMIUM:-true}
