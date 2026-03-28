# DWC - Docker Workstation Containers

基于 Alpine/Debian/Kali 构建的 Docker 工作站容器集合，支持开发环境、桌面远程访问和隐私工具。

## 功能特性

- 🖥️ **多种桌面环境** - XFCE、Kali、OpenBox，通过 noVNC 浏览器访问
- 🔊 **音频支持** - 浏览器端实时音频播放（WebSocket + PulseAudio）
- 🔒 **隐私工具** - 集成 Tor Browser 和 Pidgin 即时通讯
- 🖥️ **Windows 虚拟机** - 基于 QEMU 运行 Windows 10/11
- ⚡ **轻量级** - 基于 Alpine/Debian-slim，最小化镜像体积
- 🔧 **开发环境** - 预装 Docker CLI、Node.js、Python、QEMU 等工具

## 快速开始

### 使用 Docker Compose

```bash
# 启动所有服务
docker-compose up -d

# 启动指定服务
docker-compose up -d debian-desktop
docker-compose up -d debian-audio
docker-compose up -d kali-desktop
docker-compose up -d alpine-dev
docker-compose up -d windows
docker-compose up -d privacy
```

### 手动运行

```bash
# Debian 桌面
docker run -d --name dwc-debian \
  -p 6080:6080 \
  -v ./data/debian:/config \
  dwc/debian-desktop:latest

# 带音频的桌面
docker run -d --name dwc-debian-audio \
  -p 6080:6080 \
  -p 6081:6081 \
  -p 3389:3389 \
  -v ./data/debian-audio:/config \
  dwc/debian-audio:latest

# Kali 桌面
docker run -d --name dwc-kali \
  -p 6080:6080 \
  -p 6081:6081 \
  -v ./data/kali:/config \
  dwc/kali-desktop:latest

# 开发环境
docker run -d --name dwc-alpine-dev \
  -v ./data/alpine-dev:/config \
  -v /var/run/docker.sock:/var/run/docker.sock \
  dwc/alpine-dev:latest

# Windows 虚拟机
docker run -d --name dwc-windows \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -p 5900:5900 \
  -p 3389:3389 \
  -p 445:445 \
  -v ./data/win:/storage \
  dwc/windows:latest
```

## 服务与端口

| 服务 | 端口 | 说明 |
|------|------|------|
| debian-desktop | 6080 | noVNC |
| debian-audio | 6080, 6081, 3389, 4000 | noVNC, 音频, RDP, NoMachine |
| kali-desktop | 6080, 6081, 3389, 4000 | noVNC, 音频, RDP, NoMachine |
| debian-asbru | 6080 | noVNC + asbru-cm |
| privacy | 6080 | noVNC |
| windows | 5900, 3389, 445 | VNC, RDP, Samba |
| alpine-dev | - | 无 GUI |

## 默认配置

| 项目 | 值 |
|------|-----|
| 用户名 | qwe |
| 密码 | toor |
| UID/GID | 1000 |
| 配置目录 | /config |
| VNC 密码 | 114514 |

## noVNC 音频使用

在浏览器中打开桌面后：

1. 点击右上角的「音频」按钮启用音频
2. 使用滑块调节音量
3. 点击「全屏」按钮进入全屏模式
4. 快捷键：`Alt+M` 静音、`Alt+↑/↓` 调节音量、`F11` 全屏

## Windows 虚拟机

### 手动模式（默认）

```bash
# 1. 启动容器
docker run -d --name dwc-windows \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -p 5900:5900 \
  -v ./win:/storage \
  dwc/windows:latest

# 2. 下载 ISO 和创建磁盘
docker exec -it dwc-windows vm-setup

# 3. 启动虚拟机
docker exec -it dwc-windows vm-start
```

### 支持的版本

- Windows 10 (Pro, Pro Workstation, Enterprise, LTSC)
- Windows 11 (Pro, Enterprise)
- Windows Server 2019/2022

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VERSION | 10 | Windows 版本 |
| LANGUAGE | Chinese | 语言 |
| CPU_CORES | 2 | CPU 核心数 |
| RAM_SIZE | 4G | 内存大小 |
| DISK_SIZE | 64G | 磁盘大小 |
| MANUAL | Y | 手动/自动模式 |

### 嵌套虚拟化

```bash
docker run -d --name dwc-windows \
  -e VMX=Y \
  -e HV=N \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  # ... 其他参数
```

## 构建镜像

```bash
# 构建所有镜像
docker-compose build

# 构建单个镜像
docker build -t dwc/debian-desktop:latest -f desktop/debian/Dockerfile .
docker build -t dwc/debian-audio:latest -f desktop/debian/Dockerfile.audio .
docker build -t dwc/kali-desktop:latest -f desktop/kali/Dockerfile .
docker build -t dwc/alpine-dev:latest -f dev/alpine/Dockerfile .
docker build -t dwc/windows:latest -f dev/vm/Dockerfile .
docker build -t dwc/privacy:latest -f privacy/alpine/Dockerfile .
```

## 目录结构

```
dwc/
├── dev/                     # 开发环境
│   ├── alpine/             # Alpine 开发环境
│   └── vm/                 # Windows 虚拟机
├── desktop/                 # 桌面环境
│   ├── debian/             # Debian 桌面
│   └── kali/               # Kali 桌面
├── privacy/                # 隐私工具
│   └── alpine/
├── novnc/                  # noVNC 自定义文件
├── skel/                   # 用户配置模板
├── common/                 # 通用脚本
│   ├── entrypoint.sh       # 容器入口
│   ├── fix-permissions.sh  # 权限修复
│   └── audio-bridge/       # 音频桥接
├── docs/                   # 文档
├── docker-compose.yml      # 容器编排
└── README.md
```

## 隐私工具

包含 Tor Browser 和 Pidgin，提供隐私保护的上网和通讯环境。

```bash
docker run -d --name dwc-privacy \
  -p 6080:6080 \
  -v ./data/privacy:/config \
  dwc/privacy:latest
```

## 技术细节

### 音频架构

```
PulseAudio (容器内)
    ↓
GStreamer (PCM 编码)
    ↓
WebSocket Server (Node.js)
    ↓
Browser (Web Audio API)
```

### 网络

- 桌面容器：VNC + noVNC (WebSocket)
- Windows：QEMU + TAP 网络 + Samba
- 隐私：Tor 代理

### 持久化

所有配置和数据存储在 `/config` 目录，通过 Docker 卷持久化。

## 故障排除

### 无法访问 noVNC

```bash
# 检查容器状态
docker ps

# 检查日志
docker logs dwc-debian-desktop

# 检查 VNC 是否启动
docker exec dwc-debian-desktop ps aux | grep vnc
```

### 音频不工作

```bash
# 检查 PulseAudio
docker exec dwc-debian-audio pulseaudio --check

# 检查音频端口
docker exec dwc-debian-audio netstat -tlnp | grep 6081
```

### Windows VM 问题

```bash
# 查看 VM 状态
docker exec dwc-windows vm-status

# 查看 QEMU 日志
docker exec dwc-windows cat /run/shm/qemu.log
```

## License

MIT License
