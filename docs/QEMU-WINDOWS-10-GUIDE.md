# DWC FVC - QEMU Windows Container Guide

基于 Alpine 的 QEMU Windows 10 容器，支持自动下载 ISO、VirtIO 驱动、Samba 共享。手动启动设计。

## Quick Start

```bash
# 1. 启动容器 (保持运行，不自动启动 QEMU)
docker run -it --rm --name windows \
  -e VERSION=win10x64 \
  -e LANGUAGE=Chinese \
  -e VMX=Y \
  -e HV=N \
  -e DISK_SIZE=45G \
  -e CPU_CORES=6 \
  -e RAM_SIZE=16G \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  -p 5900:5900 \
  -p 5700:5700 \
  -p 7100:7100 \
  -p 3389:3389 \
  -p 3389:3389/udp \
  --device /dev/kvm \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --stop-timeout 60 \
  -v "./win:/storage" \
  -v "./smb:/shared" \
  dwc/alpine-fvc

# 2. 另开终端，设置环境 (下载 ISO、驱动、创建磁盘)
docker exec -it windows fvc-setup

# 3. 手动启动 QEMU
docker exec -it windows fvc-start
```

## Commands

| 命令 | 说明 |
|------|------|
| `fvc` | 显示帮助和当前配置 |
| `fvc-setup` | 下载 Windows ISO、VirtIO 驱动、创建磁盘 |
| `fvc-start` | 启动 QEMU (手动触发) |
| `fvc-stop` | 优雅停止 QEMU (ACPI 关机) |
| `fvc-samba` | 启动 Samba 文件共享 |
| `fvc-status` | 显示 VM 状态 |

## Environment Variables

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | `win10x64` | Windows 版本 (win10x64, win11x64) |
| `LANGUAGE` | `Chinese` | 语言 (Chinese, English, Japanese, Korean) |
| `CPU_CORES` | `2` | CPU 核心数 |
| `RAM_SIZE` | `4G` | 内存大小 |
| `DISK_SIZE` | `64G` | 磁盘大小 |
| `VMX` | `N` | 嵌套虚拟化 (Y/N) |
| `HV` | `Y` | 暴露 Hypervisor 标志 (Y/N) |
| `KVM` | `Y` | KVM 加速 (Y/N) |
| `DHCP` | `Y` | TAP 网络 DHCP (Y/N) |
| `MAC` | 自动 | 虚拟网卡 MAC 地址 |
| `VNC_PORT` | `0` | VNC 端口偏移 |
| `ARGUMENTS` | - | 额外 QEMU 参数 |

## Ports

| 端口 | 用途 |
|------|------|
| `5900` | VNC |
| `5700` | VNC WebSocket |
| `7100` | QEMU Monitor (telnet) |
| `3389` | RDP (Windows 安装后) |
| `445` | Samba |

## Volumes

| 路径 | 用途 |
|------|------|
| `/storage` | Windows 磁盘、ISO、固件 |
| `/shared` | Samba 共享目录 |

## Network (TAP)

需要以下参数启用 TAP 网络：

```bash
--device /dev/net/tun \
--cap-add NET_ADMIN
```

TAP 网络配置：
- 子网: `172.20.0.0/24`
- 网关: `172.20.0.1`
- DHCP: `172.20.0.100-200`
- DNS: `8.8.8.8, 8.8.4.4`

如果 TAP 不可用，自动回退到 User 网络模式。

## File Sharing

### Samba (推荐)

```bash
# 容器内启动 Samba
docker exec -it windows fvc-samba

# Windows 中访问
\\172.20.0.1\shared
```

### 9P (VirtIO)

User 模式网络自动启用 9P 共享，需要在 Windows 中安装 VirtIO 9P 驱动。

## Manual ISO

如果自动下载失败，手动放置 ISO：

```bash
# Windows ISO
cp Windows10.iso ./win/

# VirtIO 驱动 (可选)
wget -O ./win/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

## QEMU Monitor

```bash
telnet localhost 7100

# 常用命令
info status       # 查看状态
info cpus         # CPU 信息
system_powerdown  # ACPI 关机
quit              # 强制退出
```

## Nested Virtualization

在 Windows 中运行 WSL2、Hyper-V：

```bash
-e VMX=Y \
-e HV=N \
-e ARGUMENTS='-cpu host,-hypervisor,+vmx'
```

## Troubleshooting

### KVM 不可用
```bash
ls -la /dev/kvm
modprobe kvm_intel  # Intel
modprobe kvm_amd    # AMD
```

### 网络不通
```bash
# 检查 TAP
ip addr show tap0
iptables -t nat -L

# 重新配置
docker exec -it windows bash
source /opt/fvc/network.sh
setup_tap_network
```

### 查看状态
```bash
docker exec -it windows fvc-status
```

## Build

```bash
docker build -t dwc/alpine-fvc -f dev/alpine/Dockerfile.fvc .
```

## vs dockur/windows

| 特性 | dockur/windows | DWC FVC |
|------|----------------|---------|
| 启动方式 | 自动 | 手动 (`fvc-start`) |
| 基础镜像 | Debian | Alpine |
| ISO 下载 | 自动 | 手动 (`fvc-setup`) |
| 自动安装 | 支持 | 不支持 |
| 镜像大小 | ~1GB | < 350MB |
