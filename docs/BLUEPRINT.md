# DWC - Docker Workstation Containers

## 项目概述

基于 Alpine/Debian/Kali 构建的 Docker 工作站容器集合，支持开发环境、桌面环境和隐私工具。

## 目录结构

```
dwc/
├── dev/                          # 开发环境镜像
│   ├── alpine/                   # Alpine 开发环境
│   │   └── Dockerfile
│   └── vm/                       # Windows 虚拟机 (QEMU)
│       ├── Dockerfile
│       └── src/                  # 脚本和配置
│
├── desktop/                      # 桌面环境镜像
│   ├── debian/
│   │   ├── Dockerfile           # Debian XFCE + VNC
│   │   ├── Dockerfile.audio     # Debian + 音频 + 多远程桌面
│   │   └── Dockerfile.asbru    # Debian + asbru-cm
│   └── kali/
│       └── Dockerfile            # Kali 完整桌面 + 音频
│
├── privacy/                      # 隐私工具镜像
│   └── alpine/
│       └── Dockerfile           # Alpine + OpenBox + Tor Browser + Pidgin
│
├── novnc/                        # noVNC 自定义文件
│   ├── index.html               # 自定义入口页面 (中文)
│   ├── audio-client.js          # 音频客户端
│   ├── vnc.html                 # noVNC 主页面
│   └── vnc_lite.html            # noVNC 轻量版
│
├── skel/                        # 用户配置模板
│   ├── .bashrc
│   ├── .profile
│   └── .vnc/
│
├── common/                      # 通用脚本
│   ├── entrypoint.sh            # 容器入口
│   ├── fix-permissions.sh       # 权限修复
│   └── audio-bridge/            # 音频桥接服务
│       ├── audio-bridge.sh
│       ├── server.js
│       └── package.json
│
├── docs/                        # 文档
│   ├── BLUEPRINT.md
│   └── QEMU-WINDOWS-10-GUIDE.md
│
├── docker-compose.yml           # 容器编排
└── README.md
```
dwc/
├── dev/                          # 开发环境镜像
│   └── alpine/
│       ├── Dockerfile           # Alpine 完整开发环境
│       └── Dockerfile.fvc       # Alpine QEMU 精简版 (Windows 10 兼容)
│
├── desktop/                      # 桌面环境镜像
│   ├── debian/
│   │   ├── Dockerfile           # Debian XFCE + VNC
│   │   ├── Dockerfile.audio     # Debian + 音频 + 多远程桌面
│   │   └── Dockerfile.asbru     # Debian 11 + asbru-cm
│   └── kali/
│       └── Dockerfile           # Kali 完整桌面 + 音频
│
├── privacy/                      # 隐私工具镜像
│   └── alpine/
│       └── Dockerfile           # Alpine + OpenBox + Tor Browser + Pidgin
│
├── skel/                         # 用户配置模板
│   ├── .bashrc
│   ├── .profile
│   └── novnc/                   # noVNC 音频魔改
│       ├── audio-client.js
│       └── index.html
│
├── common/                       # 通用脚本
│   ├── entrypoint.sh
│   ├── fix-permissions.sh
│   └── audio-bridge/            # 音频桥接服务
│       ├── audio-bridge.sh
│       └── server.js
│
└── docs/
    └── BLUEPRINT.md
```

## 镜像规格

| 镜像 | 基础 | 目标大小 | Shell | 用途 |
|------|------|----------|-------|------|
| dev/alpine | alpine:edge | <500MB | bash | 完整开发环境 |
| dev/vm | alpine:edge | <350MB | bash | QEMU Windows 10/11 |
| desktop/debian | debian:unstable-slim | - | bash | XFCE 桌面 |
| desktop/debian.audio | debian:unstable-slim | - | bash | 桌面 + 音频 + RDP |
| desktop/debian.asbru | debian:unstable-slim | - | bash | 桌面 + asbru-cm |
| desktop/kali | debian:unstable-slim | - | bash | Kali 桌面 + 音频 + RDP |
| privacy/alpine | alpine:edge | - | bash | Tor + Pidgin |

## 用户配置

| 项目 | 值 |
|------|-----|
| 用户名 | qwe |
| 密码 | toor |
| UID/GID | 1000/1000 |
| Home目录 | /config |
| Sudo | 无密码 |

## 统一换源

```
Alpine:  http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine
Debian:  http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian
Kali:    http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/kali
```

## 构建命令

```bash
# Alpine Dev
docker build -t dwc/alpine-dev:latest -f dev/alpine/Dockerfile .

# Windows VM
docker build -t dwc/windows:latest -f dev/vm/Dockerfile .

# Debian Desktop
docker build -t dwc/debian-desktop:latest -f desktop/debian/Dockerfile .

# Debian Audio
docker build -t dwc/debian-audio:latest -f desktop/debian/Dockerfile.audio .

# Debian Asbru
docker build -t dwc/debian-asbru:latest -f desktop/debian/Dockerfile.asbru .

# Kali Desktop
docker build -t dwc/kali-desktop:latest -f desktop/kali/Dockerfile .

# Privacy
docker build -t dwc/privacy:latest -f privacy/alpine/Dockerfile .
```

## 运行示例

```bash
# 开发环境
docker run -d --name dev \
  -v ./config:/config \
  dwc/alpine-dev:latest

# QEMU (Windows 10)
docker run -d --name qemu \
  --device=/dev/kvm \
  -v ./storage:/storage \
  dwc/alpine-fvc:latest

# 桌面环境
docker run -d --name desktop \
  -p 6080:6080 \
  -p 6081:6081 \
  -v ./config:/config \
  dwc/kali-desktop:latest
```

## noVNC 音频支持

Kali 和 Debian Audio 镜像支持通过浏览器播放音频：
- VNC 视频: 端口 6080
- 音频流: 端口 6081
- 使用 PulseAudio + GStreamer + WebSocket 转发 PCM 数据

## Windows 版本支持

支持以下 Windows 版本：

| 版本 | 环境变量值 |
|------|-----------|
| Windows 10 Pro | `VERSION=10` 或 `VERSION=10pro` |
| Windows 10 Pro Workstation | `VERSION=10prows` 或 `VERSION=10pro-workstation` |
| Windows 10 Enterprise LTSC | `VERSION=10l` 或 `VERSION=ltsc10` |
| Windows 11 Pro | `VERSION=11` 或 `VERSION=11pro` |
| Windows Server 2019 | `VERSION=2019` |
| Windows Server 2022 | `VERSION=2022` |

## 内部镜像源

```
Alpine:  http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine
Debian:  http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian
Windows: http://7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/dl/res/iso/
```
