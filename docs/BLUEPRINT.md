# DWC - Docker Workstation Containers

## 项目概述

基于 Alpine/Debian/Kali 构建的 Docker 工作站容器集合，支持开发环境、桌面环境和隐私工具。

## 目录结构

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
| dev/alpine.fvc | alpine:edge | <200MB | ash | QEMU Windows 10 |
| desktop/debian | debian:unstable-slim | - | bash | XFCE 桌面 |
| desktop/debian.audio | debian:unstable-slim | - | bash | 桌面 + 音频 |
| desktop/debian.asbru | debian:11 | - | bash | asbru-cm |
| desktop/kali | kalilinux/kali-rolling | - | zsh | 完整桌面 + 音频 |
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

# Alpine FVC (QEMU)
docker build -t dwc/alpine-fvc:latest -f dev/alpine/Dockerfile.fvc .

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
