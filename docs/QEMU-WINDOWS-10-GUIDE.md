# DWC Windows VM - dockur/windows Compatible

基于 Alpine 的 QEMU Windows 容器，完全兼容 dockur/windows 体验。
支持自动下载 ISO、VirtIO 驱动、Samba 共享、自动安装（可选）。

## Quick Start

```bash
# 1. 启动容器 (手动模式，容器保持运行)
docker run -it --rm --name windows \
  -e VERSION=10 \
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
  -p 445:445 \
  --device /dev/kvm \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --stop-timeout 60 \
  -v "./win:/storage" \
  -v "./smb:/shared" \
  dwc/windows

# 2. 另开终端，设置环境 (下载 ISO、驱动、创建磁盘)
docker exec -it windows vm-setup

# 3. 手动启动 QEMU
docker exec -it windows vm-start
```

## 自动模式 (dockur/windows 兼容)

```bash
# 设置 MANUAL=N 启用自动安装
docker run -it --rm --name windows \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  -e MANUAL=N \
  -e USERNAME=piation \
  -e PASSWORD=Aa112233 \
  # ... 其他参数同上
```

## Commands

| 命令 | 说明 |
|------|------|
| `vm-setup` | 下载 Windows ISO、VirtIO 驱动、创建磁盘 |
| `vm-start` | 启动 QEMU 虚拟机 |
| `vm-stop` | 优雅停止 QEMU (ACPI 关机信号) |
| `vm-status` | 显示 VM 状态、资源使用、日志 |

## Environment Variables

与 dockur/windows 完全兼容：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | `10` | Windows 版本 (10, 11, 7, 2019, 2022) |
| `LANGUAGE` | `en` | 语言 (Chinese, English, Japanese, Korean) |
| `CPU_CORES` | `2` | CPU 核心数 |
| `RAM_SIZE` | `4G` | 内存大小 |
| `DISK_SIZE` | `64G` | 磁盘大小 |
| `MANUAL` | `Y` | 手动模式 (Y=手动启动, N=自动启动+安装) |
| `USERNAME` | - | 自动安装用户名 |
| `PASSWORD` | - | 自动安装密码 |
| `VMX` | `N` | 嵌套虚拟化 |
| `HV` | `Y` | Hypervisor 标志 |
| `TPM` | `N` | TPM 2.0 |
| `SECBOOT` | `N` | Secure Boot |
| `ARGUMENTS` | - | 额外 QEMU CPU 参数 |
| `DEBUG` | `N` | 调试模式 |

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
| `/storage` | Windows 磁盘、ISO、固件文件 |
| `/shared` | Samba 共享目录 (Windows: `\\172.20.0.1\shared`) |

## Network (TAP)

默认使用 TAP 网络，需要：

```bash
--device /dev/net/tun \
--cap-add NET_ADMIN
```

网络配置：
- 子网: `172.20.0.0/24`
- 网关: `172.20.0.1`
- DHCP: `172.20.0.100-200`
- DNS: `8.8.8.8, 8.8.4.4`

如果 TAP 不可用，自动回退到 User 网络模式。

## File Sharing (Samba)

容器启动后 Samba 自动运行，Windows 中访问：

```
\\172.20.0.1\shared
```

## Custom ISO

手动放置 ISO 到 `/storage` 目录：

```bash
cp Windows10.iso ./win/custom.iso
# 或
cp Windows10.iso ./win/boot.iso
```

系统会自动检测并使用自定义 ISO。

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

在 Windows 中运行 WSL2、Docker、Hyper-V：

```bash
-e VMX=Y \
-e HV=N \
-e ARGUMENTS='-cpu host,-hypervisor,+vmx'
```

## vs dockur/windows

| 特性 | dockur/windows | DWC Windows |
|------|----------------|-------------|
| 启动方式 | 自动 | 手动 (默认) / 自动 (MANUAL=N) |
| 基础镜像 | Debian | Alpine |
| 镜像大小 | ~1GB | < 350MB |
| 自动安装 | 默认开启 | 默认关闭 |
| Sysprep | 支持 | 支持 |
| 脚本结构 | 模块化 | 模块化 (兼容) |

## Build

```bash
docker build -t dwc/windows -f dev/vm/Dockerfile .
```

## Troubleshooting

### KVM 不可用
```bash
ls -la /dev/kvm
modprobe kvm_intel  # Intel CPU
modprobe kvm_amd    # AMD CPU
```

### 查看详细状态
```bash
docker exec -it windows vm-status
```

### 查看 QEMU 日志
```bash
docker exec -it windows cat /run/shm/qemu.log
```
