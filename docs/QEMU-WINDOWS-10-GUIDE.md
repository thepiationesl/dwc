# DWC QEMU Windows 10 Container Guide

基于 Alpine 的 QEMU Windows 10 容器，兼容 dockur/windows 风格的环境变量配置。

## Quick Start

```bash
# 基础启动 (2核心, 4GB内存, 64GB硬盘)
docker run -it --rm --name windows \
  -p 8006:8006 \
  -p 3389:3389 \
  --device /dev/kvm \
  -v "./win:/storage" \
  dwc/alpine-fvc

# 完整配置 (推荐，与 dockur/windows 相同习惯)
docker run -it --rm --name windows \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  -e VMX=Y \
  -e HV=N \
  -e DISK_SIZE=45G \
  -e CPU_CORES=6 \
  -e RAM_SIZE=16G \
  -e USERNAME=piation \
  -e PASSWORD=Aa112233 \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  -p 8006:8006 \
  -p 7070:7070 \
  -p 3389:3389 \
  -p 3389:3389/udp \
  --device /dev/kvm \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --stop-timeout 60 \
  -v "./win:/storage" \
  -v "./smb:/shared" \
  dwc/alpine-fvc
```

## Environment Variables

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | `10` | Windows 版本 (保留字段) |
| `LANGUAGE` | `Chinese` | 语言 (保留字段) |
| `CPU_CORES` | `2` | CPU 核心数 |
| `RAM_SIZE` | `4G` | 内存大小 |
| `DISK_SIZE` | `64G` | 磁盘大小 (首次创建时) |
| `USERNAME` | - | Windows 用户名 (保留字段) |
| `PASSWORD` | - | Windows 密码 (保留字段) |
| `VMX` | `N` | 启用嵌套虚拟化 (Intel VT-x) |
| `HV` | `Y` | 暴露 Hypervisor 标志 |
| `KVM` | `Y` | 启用 KVM 加速 |
| `DHCP` | `Y` | TAP 网络启用 DHCP |
| `ARGUMENTS` | - | 额外 QEMU 参数 |

## Ports

| 端口 | 用途 |
|------|------|
| `8006` | Web VNC (noVNC 界面) |
| `5900` | VNC |
| `5700` | VNC WebSocket |
| `7100` | QEMU Monitor (telnet) |
| `3389` | RDP (Windows 安装后可用) |

## Volumes

| 路径 | 用途 |
|------|------|
| `/storage` | Windows 磁盘、ISO、UEFI 固件 |
| `/shared` | SMB/9P 共享目录 (可在 Windows 中访问) |

## Network (TAP)

使用 `--device /dev/net/tun` 和 `--cap-add NET_ADMIN` 启用 TAP 网络：

```bash
docker run ... \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  ...
```

TAP 网络提供：
- 完整的网络功能
- DHCP 自动配置 (172.20.0.x)
- NAT 转发
- 更好的性能

如果 TAP 不可用，自动 Fallback 到 User 网络模式。

## Windows Installation

### 1. 准备 ISO

将 Windows 10 ISO 放入 `/storage` 目录：

```bash
mkdir -p ./win
cp windows10.iso ./win/
```

### 2. 启动容器

```bash
docker run -it --rm --name windows \
  -e CPU_CORES=4 \
  -e RAM_SIZE=8G \
  -e DISK_SIZE=60G \
  -p 8006:8006 \
  --device /dev/kvm \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -v "./win:/storage" \
  dwc/alpine-fvc
```

### 3. 访问 Web VNC

打开浏览器访问 `http://localhost:8006`，按照 Windows 安装向导操作。

### 4. 安装完成后

移除 ISO 文件或重启容器，Windows 将从磁盘启动。

## UEFI Boot

如需 UEFI 启动：

```bash
# 将 OVMF 固件放入 /storage
cp OVMF_CODE.fd ./win/
cp OVMF_VARS.fd ./win/
```

容器会自动检测并启用 UEFI。

## Nested Virtualization

在 Windows 中运行虚拟机 (如 WSL2, Hyper-V)：

```bash
docker run ... \
  -e VMX=Y \
  -e HV=N \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  ...
```

## SMB/9P Sharing

将文件共享到 Windows：

```bash
docker run ... \
  -v "./smb:/shared" \
  ...
```

Windows 中访问：
- 9P: 需要安装 VirtIO 9P 驱动
- SMB: 容器内自动启动 Samba 服务

## QEMU Monitor

通过 telnet 连接 QEMU 控制台：

```bash
telnet localhost 7100
```

常用命令：
- `info status` - 查看状态
- `info cpus` - CPU 信息
- `system_powerdown` - 优雅关机
- `quit` - 强制退出

## Build

```bash
docker build -t dwc/alpine-fvc -f dev/alpine/Dockerfile.fvc .
```
