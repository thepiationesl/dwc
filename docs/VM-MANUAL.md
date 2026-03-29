# Windows VM 手动安装指南

本文档说明如何在容器中手动安装和运行 Windows 虚拟机。

## 快速开始

### 1. 启动容器

```bash
docker run -it --rm \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add=NET_ADMIN \
  -v ./storage:/storage \
  -v ./shared:/shared \
  -p 5900:5900 \
  -p 5700:5700 \
  -p 3389:3389 \
  dwc/cs50-vm
```

### 2. 准备安装

进入容器后执行：

```bash
vm-setup
```

此命令将：
- 下载 Windows ISO（如未提供自定义ISO）
- 创建虚拟磁盘
- 初始化 UEFI 固件

### 3. 启动虚拟机

```bash
vm-start
```

### 4. 访问虚拟机

| 方式 | 地址 |
|------|------|
| VNC | `localhost:5900` |
| VNC WebSocket | `localhost:5700` |
| RDP | `localhost:3389` （安装完成后）|
| Samba | `\\172.20.0.1\shared` |

## 配置选项

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | `10` | Windows 版本：10, 11, ltsc |
| `LANGUAGE` | `Chinese` | 系统语言 |
| `DISK_SIZE` | `64G` | 虚拟磁盘大小 |
| `RAM_SIZE` | `8G` | 内存大小 |
| `CPU_CORES` | `4` | CPU 核心数 |
| `MANUAL` | `Y` | 手动模式 |

### 使用自定义 ISO

将 ISO 文件放入 `/storage` 目录并命名为 `custom.iso` 或 `boot.iso`：

```bash
docker run -it \
  -v ./my-windows.iso:/storage/custom.iso:ro \
  -v ./storage:/storage \
  dwc/cs50-vm
```

## 命令参考

| 命令 | 说明 |
|------|------|
| `vm-setup` | 下载 ISO，创建磁盘，准备安装 |
| `vm-start` | 启动虚拟机 |
| `vm-start -d` | 后台启动虚拟机 |
| `vm-stop` | 优雅停止虚拟机 |
| `vm-status` | 查看虚拟机状态 |

## Samba 共享

启动后，可通过 Samba 在 Windows 和主机间共享文件：

- Windows 路径：`\\172.20.0.1\shared`
- 主机路径：`/shared`（容器内）

## GitHub Codespaces

在 Codespaces 中使用时，选择 `CS50 Windows VM` 配置。

容器启动后会自动执行：
1. `postCreateCommand` - 初始化环境
2. `postStartCommand` - 显示状态信息

然后手动执行 `vm-setup` 和 `vm-start`。

## 故障排除

### KVM 不可用

如果没有 KVM 加速，VM 将使用 TCG 模式运行（较慢）：

```
[WARN] KVM not available, using TCG (slower)
```

### 网络问题

确保传递了正确的设备和权限：

```bash
--device=/dev/net/tun --cap-add=NET_ADMIN
```

### 磁盘空间不足

检查 `/storage` 目录的可用空间，Windows 安装通常需要 30GB+。
