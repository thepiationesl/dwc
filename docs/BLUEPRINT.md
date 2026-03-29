# DWC 项目蓝图

本文档描述 DWC 项目的整体架构、目录结构和技术规格。

## 项目概述

DWC (Docker Workstation Containers) 是一个基于 Docker 的工作站容器集合，提供以下功能：

- **开发环境** - Alpine Linux 开发环境，预装常用开发工具
- **桌面环境** - Debian/Kali 桌面，通过 noVNC 浏览器访问
- **虚拟化** - Windows 10/11 虚拟机，基于 QEMU+KVM
- **隐私工具** - Tor Browser + Pidgin 即时通讯

## 目录结构

```
dwc/
├── dev/                          # 开发环境镜像
│   ├── alpine/                   # Alpine 开发环境
│   │   └── Dockerfile
│   └── debian/                   # Debian 开发环境
│       └── Dockerfile
│
├── vm/                           # Windows 虚拟机镜像与脚本
│   ├── manual/
│   │   └── Dockerfile
│   ├── auto/
│   │   └── Dockerfile
│   ├── legacy/
│   │   └── Dockerfile
│   └── scripts/                  # 手动/自动/legacy 共享脚本
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
│   ├── QUICKSTART.md
│   └── API-REFERENCE.md
│
├── docker-compose.yml           # 容器编排
└── README.md
```

## 镜像规格

### 开发环境镜像

| 镜像 | 基础镜像 | 目标大小 | 用途 | 主要特性 |
|------|----------|----------|------|----------|
| `dwc/alpine-dev` | alpine:edge | <500MB | Alpine 开发环境 | Docker CLI, Node.js, Python, QEMU, Git |
| `dwc/windows` | alpine:edge | <350MB | Windows 虚拟机 | QEMU+KVM, VirtIO驱动, Samba共享 |

### 桌面环境镜像

| 镜像 | 基础镜像 | 用途 | 主要特性 |
|------|----------|------|----------|
| `dwc/debian-desktop` | debian:unstable-slim | Debian XFCE 桌面 | TigerVNC, noVNC, Chrome |
| `dwc/debian-audio` | debian:unstable-slim | 音频增强桌面 | PulseAudio, GStreamer, xrdp, NoMachine |
| `dwc/debian-asbru` | debian:bullseye-slim | asbru-cm 连接管理器 | SSH/RDP/VNC 连接管理 |
| `dwc/kali-desktop` | kalilinux/kali-rolling | Kali 安全桌面 | 安全工具, 音频支持, Zsh |

### 隐私工具镜像

| 镜像 | 基础镜像 | 用途 | 主要特性 |
|------|----------|------|----------|
| `dwc/privacy` | alpine:edge | 隐私桌面 | Tor Browser, Pidgin, OpenBox |

## 服务架构

### Docker Compose 服务定义

每个服务在 `docker-compose.yml` 中定义，包含以下配置：

```yaml
service-name:
  build:
    context: .
    dockerfile: path/to/Dockerfile
  image: dwc/image-name:latest
  container_name: dwc-service-name
  volumes:
    - ./data/service:/config
  ports:
    - "host:container"
  environment:
    - KEY=VALUE
  devices:
    - /dev/device:/dev/device
  cap_add:
    - CAPABILITY
  restart: unless-stopped
```

### 端口分配策略

为了避免端口冲突，采用以下分配策略：

| 服务类型 | noVNC端口 | VNC端口 | 音频端口 | 其他端口 |
|----------|-----------|---------|----------|----------|
| debian-desktop | 6080 | 5901 | - | - |
| debian-audio | 6180 | 6001 | 6181 | 3390(RDP), 4001(NM) |
| debian-asbru | 6280 | 6002 | - | - |
| kali-desktop | 6380 | 6003 | 6381 | 3391(RDP), 4002(NM) |
| privacy | 6480 | 6004 | - | - |
| windows | - | 5900 | - | 5700(WS), 7100(Mon), 3389(RDP), 445(SMB) |

## 用户配置

所有镜像使用统一的用户配置：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| 用户名 | qwe | 默认用户 |
| 密码 | toor | 默认密码 |
| UID | 1000 | 用户ID |
| GID | 1000 | 组ID |
| Home目录 | /config | 配置持久化目录 |
| Sudo权限 | 无密码 | 可直接执行 sudo 命令 |
| VNC密码 | 114514 | VNC 连接密码 |

## 镜像源配置

所有镜像使用统一的内部镜像源：

```bash
# Alpine 镜像源
http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/alpine

# Debian 镜像源
http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/debian

# Kali 镜像源
http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/system/kali

# Windows ISO 镜像源
http://7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/dl/res/iso/
```

## 构建配置

### 构建命令

```bash
# 构建所有镜像
docker-compose build

# 构建单个镜像
docker build -t dwc/alpine-dev:latest -f dev/alpine/Dockerfile .
docker build -t dwc/windows:latest -f vm/legacy/Dockerfile .
docker build -t dwc/debian-desktop:latest -f desktop/debian/Dockerfile .
docker build -t dwc/debian-audio:latest -f desktop/debian/Dockerfile.audio .
docker build -t dwc/debian-asbru:latest -f desktop/debian/Dockerfile.asbru .
docker build -t dwc/kali-desktop:latest -f desktop/kali/Dockerfile .
docker build -t dwc/privacy:latest -f privacy/alpine/Dockerfile .
```

### 构建参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| BASE_IMAGE | - | 基础镜像名称 |
| USERNAME | qwe | 默认用户名 |
| USER_UID | 1000 | 用户UID |
| USER_GID | 1000 | 用户GID |

## 持久化策略

所有服务使用 Docker 卷进行数据持久化：

```yaml
volumes:
  - ./data/service-name:/config
```

持久化内容包括：

- **用户配置** - `.bashrc`, `.profile`, 应用配置
- **桌面设置** - 窗口管理器配置, 壁纸, 快捷键
- **应用数据** - 浏览器书签, 编辑器设置
- **Windows 虚拟机** - 磁盘镜像, ISO 文件, 配置

## 技术栈

### 容器技术

- **Docker** - 容器运行时
- **Docker Compose** - 多容器编排
- **Alpine Linux** - 轻量级基础镜像
- **Debian** - 稳定桌面环境基础
- **Kali Linux** - 安全工具集合

### 桌面技术

- **XFCE4** - 轻量级桌面环境
- **OpenBox** - 窗口管理器
- **TigerVNC** - VNC 服务器
- **noVNC** - 浏览器 VNC 客户端
- **PulseAudio** - 音频服务器
- **GStreamer** - 多媒体框架

### 虚拟化技术

- **QEMU** - 处理器模拟器
- **KVM** - 内核虚拟机
- **VirtIO** - 半虚拟化驱动
- **Samba** - Windows 文件共享

### 开发工具

- **Node.js** - JavaScript 运行时
- **Python** - 编程语言
- **Docker CLI** - 容器管理工具
- **Git** - 版本控制系统

## 部署模式

### 开发模式

```bash
# 使用 docker-compose 开发
docker-compose up -d

# 查看日志
docker-compose logs -f service-name

# 重建并重启
docker-compose up -d --build service-name
```

### 生产模式

```bash
# 使用预构建镜像
docker pull dwc/image-name:latest

# 运行容器
docker run -d --name container-name dwc/image-name:latest

# 使用持久化卷
docker run -d -v /data/service:/config dwc/image-name:latest
```

## 安全考虑

### 网络安全

- **端口最小化** - 只暴露必要的端口
- **防火墙规则** - 限制访问来源
- **SSL/TLS** - 生产环境使用 HTTPS

### 容器安全

- **非 root 用户** - 容器内以普通用户运行
- **权限限制** - 使用最小必要权限
- **镜像扫描** - 定期检查漏洞

### 数据安全

- **卷加密** - 敏感数据加密存储
- **备份策略** - 定期备份配置和数据
- **访问控制** - 限制卷挂载权限

## 扩展性

### 添加新镜像

1. 在相应目录创建 Dockerfile
2. 添加到 docker-compose.yml
3. 更新文档和端口分配
4. 添加构建和运行脚本

### 自定义配置

1. 修改 `skel/` 目录中的配置模板
2. 更新 `common/entrypoint.sh` 中的初始化逻辑
3. 添加环境变量支持
4. 更新文档说明

## 维护和监控

### 日志管理

```bash
# 查看容器日志
docker logs container-name

# 查看服务日志
docker-compose logs service-name

# 实时监控日志
docker logs -f container-name
```

### 健康检查

```bash
# 检查容器状态
docker ps

# 检查服务状态
docker-compose ps

# 查看资源使用
docker stats
```

### 备份和恢复

```bash
# 备份配置目录
tar -czf backup.tar.gz ./data/

# 恢复配置
tar -xzf backup.tar.gz -C ./
```
