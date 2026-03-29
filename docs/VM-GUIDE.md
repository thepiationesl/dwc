# DWC Windows VM 容器

Windows 虚拟机容器，提供两种安装模式：手动安装和自动安装。支持在 Docker 中运行 Windows 系统，使用 QEMU 虚拟化技术。

## 功能特性

- **两种安装模式**
  - 手动安装：用户手动下载 Windows ISO 并安装
  - 自动安装：使用 Sysprep 自动安装 Windows
- **完整的 Windows 支持** - Windows 10/11 Pro/Enterprise
- **远程访问** - VNC、RDP、WebSocket
- **文件共享** - Samba 共享目录
- **虚拟化加速** - KVM 支持（需要 `/dev/kvm` 设备）
- **轻量级基础镜像** - 基于 Debian，支持 Docker-outside-of-Docker

## 快速开始

### 前置要求

- Docker 已安装
- KVM 支持（推荐但可选）：`--device=/dev/kvm`
- TAP 网络（可选）：`--device=/dev/net/tun --cap-add NET_ADMIN`
- 足够的磁盘空间（至少 100GB）
- 足够的内存（推荐 16GB+）

### 手动安装模式

#### 方式1：使用 Docker Compose

```yaml
# docker-compose.yml
version: "3.8"

services:
  windows-manual:
    build:
      context: .
      dockerfile: vm/manual/Dockerfile
    image: miko453/dwc:windows-manual
    container_name: dwc-windows
    environment:
      VERSION: "10"                    # Windows version: 10 or 11
      LANGUAGE: "Chinese"              # CN/EN
      CPU_CORES: "6"
      RAM_SIZE: "16G"
      DISK_SIZE: "120G"
      MANUALLY: "Y"
    devices:
      - /dev/kvm:/dev/kvm
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
    volumes:
      - ./data/windows:/storage        # VM 磁盘存储
      - ./data/shared:/shared          # 共享目录
    ports:
      - "5900:5900"    # VNC
      - "5700:5700"    # VNC WebSocket
      - "7100:7100"    # QEMU Monitor
      - "3389:3389"    # RDP
      - "445:445"      # Samba
    stop_grace_period: 60s
    restart: unless-stopped
```

#### 方式2：使用 Docker 命令

```bash
# 构建镜像
docker build -t miko453/dwc:windows-manual -f vm/manual/Dockerfile .

# 运行容器（手动安装）
docker run -d --name dwc-windows \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  -e CPU_CORES=6 \
  -e RAM_SIZE=16G \
  -e DISK_SIZE=120G \
  -p 5900:5900 \
  -p 5700:5700 \
  -p 7100:7100 \
  -p 3389:3389 \
  -p 445:445 \
  -v ./data/windows:/storage \
  -v ./data/shared:/shared \
  miko453/dwc:windows-manual
```

#### 安装步骤

```bash
# 1. 进入容器
docker exec -it dwc-windows bash

# 2. 下载 ISO 和驱动
vm-setup

# 3. 创建虚拟磁盘
# （vm-setup 已自动完成）

# 4. 启动 QEMU 虚拟机
vm-start

# 5. 通过 VNC 或 RDP 连接并安装 Windows
# VNC: http://localhost:5900 or localhost:5700 (WebSocket)
# RDP: localhost:3389

# 6. 停止虚拟机
vm-stop

# 7. 查看状态
vm-status
```

### 自动安装模式

#### 基本配置

```yaml
version: "3.8"

services:
  windows-auto:
    build:
      context: .
      dockerfile: vm/auto/Dockerfile
    image: miko453/dwc:windows-auto
    container_name: dwc-windows-auto
    environment:
      VERSION: "10"
      LANGUAGE: "Chinese"
      CPU_CORES: "6"
      RAM_SIZE: "16G"
      DISK_SIZE: "120G"
      MANUAL: "N"              # 自动启动
    devices:
      - /dev/kvm:/dev/kvm
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
    volumes:
      - ./data/windows-auto:/storage
      - ./data/shared:/shared
      - ./sysprep:/sysprep     # Sysprep 文件
    ports:
      - "5900:5900"
      - "5700:5700"
      - "7100:7100"
      - "3389:3389"
      - "445:445"
    restart: unless-stopped
```

#### Sysprep 文件说明

需要将以下文件放入 `./sysprep` 目录：

```
sysprep/
├── install.iso              # Windows 安装 ISO（可选，如不提供则自动下载）
├── autounattend.xml         # 自动安装配置文件
├── post-install.ps1         # 安装后脚本（可选）
└── drivers/                 # 驱动程序目录（可选）
    ├── chipset/
    ├── nic/
    └── storage/
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | 10 | Windows 版本：10（Windows 10）或 11（Windows 11） |
| `LANGUAGE` | Chinese | 语言：Chinese（中文）或 English（英文）或其他 |
| `CPU_CORES` | 2 | CPU 核心数 |
| `RAM_SIZE` | 4G | 内存大小（支持 K/M/G 单位） |
| `DISK_SIZE` | 64G | 磁盘大小 |
| `MANUAL` | Y（Manual），N（Auto） | 安装模式 |
| `KEYBOARD` | | 键盘布局（可选） |
| `REGION` | | 地区代码（可选） |
| `USERNAME` | | Windows 用户名（可选） |
| `PASSWORD` | | Windows 密码（可选） |
| `HV` | N | 启用 Hyper-V：Y/N |
| `VMX` | N | 启用 VMX：Y/N |
| `TPM` | N | 启用 TPM 2.0：Y/N |
| `SECBOOT` | N | 启用安全启动：Y/N |

## 远程访问

### VNC 访问

- **直接 VNC**：`vnc://localhost:5900`
- **WebSocket VNC**：`http://localhost:5700`
- **VNC 客户端**：
  ```bash
  vncviewer localhost:5900
  ```

### RDP 访问

```bash
# Linux
rdesktop -u Administrator localhost:3389

# macOS
open "rdp://username@localhost:3389"

# Windows
mstsc /v:localhost:3389
```

### 浏览器访问

使用 noVNC 通过浏览器访问：

```bash
# 启动 noVNC
python3 -m websockify --web=/path/to/novnc 6080 localhost:5900

# 浏览器访问
http://localhost:6080/vnc.html
```

## 文件共享

### Samba 共享

容器内部署了 Samba 服务，可实现主机和虚拟机间的文件共享。

- **共享目录**：`/storage/shared` 映射到主机 `/data/shared`
- **访问地址**：`\\<container-ip>\shared`
- **用户**：qwe / 密码：toor

### 直接文件操作

```bash
# 从主机复制文件到虚拟机存储
cp -r /some/files ./data/windows/

# 从容器访问
docker exec dwc-windows ls /storage/
```

## 常见配置

### 网络配置

#### 桥接网络（推荐）

```yaml
networks:
  external:
    driver: bridge

services:
  windows:
    networks:
      - external
```

#### TAP 网络

```yaml
services:
  windows:
    devices:
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
```

### 显示配置

```yaml
environment:
  VGA: "qxl"           # 使用 QXL 显卡（更好的性能）
  USB: "usb-host"      # 启用 USB 重定向
  ARGUMENTS: "-cpu host,-hypervisor,+vmx"  # QEMU 参数
```

### 存储配置

```yaml
environment:
  DISK_SIZE: "200G"    # 大磁盘
  DISK_TYPE: "virtio"  # 使用 VirtIO 磁盘
  DISK_CACHE: "writeback"  # 缓存策略
```

## 连接问题排查

### 连接超时

确保容器正常运行：
```bash
docker logs dwc-windows
docker exec dwc-windows vm-status
```

### 性能问题

调整资源配置：
```yaml
environment:
  CPU_CORES: "8"      # 增加 CPU
  RAM_SIZE: "32G"     # 增加内存
```

### 网络问题

检查网络配置：
```bash
docker exec dwc-windows ip addr show
docker exec dwc-windows arp -a
```

## 高级用法

### 使用 TAP 网络

如需完整的网络隔离，可使用 TAP 接口（需要 root 权限或 sudoers 配置）：

```bash
# 创建 TAP 接口
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up
sudo ip addr add 10.0.0.1/24 dev tap0

# 运行容器（使用 --privileged 或特定权限）
docker run --privileged \
  --device=/dev/net/tun \
  -e MANUAL=N \
  miko453/dwc:windows-manual
```

### 自定义启动参数

```yaml
environment:
  ARGUMENTS: "-m 16G -smp 8,cores=4 -cpu host -machine q35"
```

### 监控虚拟机

```bash
# 查看 QEMU 进程
docker exec dwc-windows ps aux | grep qemu

# 进入 QEMU Monitor
nc localhost 7100

# 监控资源使用
docker stats dwc-windows
```

## 故障排除

| 问题 | 解决方案 |
|------|--------|
| VM 不启动 | 检查 `/dev/kvm` 权限，确保 KVM 可用 |
| 网络不连通 | 配置 TAP 接口或使用桥接网络 |
| 性能缓慢 | 增加 CPU 核心数和内存，启用 virtio 驱动 |
| 连接断开 | 检查防火墙规则，保证端口开放 |
| 磁盘满 | 增加 `DISK_SIZE` 重新创建虚拟磁盘 |

## 许可证

基于 [dockur/windows](https://github.com/dockur/windows) 以及 DWC 项目许可证。

## 相关文档

- [快速开始指南](QUICKSTART.md)
- [项目架构](ARCHITECTURE.md)
- [文档索引](INDEX.md)
