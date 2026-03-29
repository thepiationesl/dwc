# DWC Windows 虚拟机使用指南

本文档详细说明 DWC Windows 虚拟机的配置、使用和故障排除。

## 概述

DWC Windows 虚拟机基于 Alpine Linux 和 QEMU，提供完整的 Windows 10/11 虚拟化环境。该容器完全兼容 dockur/windows，但采用更轻量级的 Alpine 基础镜像。

### 主要特性

- **轻量级** - 基于 Alpine Linux，镜像大小 <350MB
- **兼容性** - 完全兼容 dockur/windows 环境变量和接口
- **灵活性** - 支持手动和自动两种安装模式
- **高性能** - 支持 KVM 硬件加速和嵌套虚拟化
- **易用性** - 提供完整的管理命令和状态监控

## 快速开始

### 手动模式（推荐）

手动模式允许您完全控制 Windows 的安装过程：

```bash
# 1. 启动容器
docker run -d --name dwc-vm \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -p 5900:5900 \
  -p 5700:5700 \
  -p 7100:7100 \
  -p 3389:3389 \
  -p 3389:3389/udp \
  -p 445:445 \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  -e VMX=Y \
  -e HV=N \
  -e DISK_SIZE=45G \
  -e CPU_CORES=6 \
  -e RAM_SIZE=16G \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  -v "$(pwd)/data/win:/storage" \
  -v "$(pwd)/data/smb:/shared" \
  dwc/windows:latest

# 2. 下载 ISO 和创建磁盘
docker exec -it dwc-vm vm-setup

# 3. 启动虚拟机
docker exec -it dwc-vm vm-start

# 4. 查看状态
docker exec -it dwc-vm vm-status
```

### 自动模式

自动模式完全兼容 dockur/windows，自动下载 ISO 并安装 Windows：

```bash
docker run -d --name dwc-vm \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -p 5900:5900 \
  -p 3389:3389 \
  -p 445:445 \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  -e MANUAL=N \
  -e USERNAME=youruser \
  -e PASSWORD=yourpass \
  -e DISK_SIZE=64G \
  -e CPU_CORES=4 \
  -e RAM_SIZE=8G \
  -v "$(pwd)/data/win:/storage" \
  dwc/windows:latest
```

## 管理命令

容器提供了以下管理命令：

| 命令 | 说明 | 示例 |
|------|------|------|
| `vm-setup` | 下载 Windows ISO、VirtIO 驱动、创建磁盘 | `docker exec -it dwc-vm vm-setup` |
| `vm-start` | 启动 QEMU 虚拟机 | `docker exec -it dwc-vm vm-start` |
| `vm-stop` | 优雅停止 QEMU (ACPI 关机信号) | `docker exec -it dwc-vm vm-stop` |
| `vm-status` | 显示 VM 状态、资源使用、日志 | `docker exec -it dwc-vm vm-status` |

### 命令详情

#### vm-setup

下载必要的文件并创建虚拟磁盘：

```bash
# 完整设置
docker exec -it dwc-vm vm-setup

# 只下载 ISO
docker exec -it dwc-vm vm-setup --iso-only

# 只创建磁盘
docker exec -it dwc-vm vm-setup --disk-only
```

#### vm-start

启动虚拟机，支持多种选项：

```bash
# 正常启动
docker exec -it dwc-vm vm-start

# 启用调试模式
docker exec -it dwc-vm vm-start --debug

# 指定 ISO 文件
docker exec -it dwc-vm vm-start --iso /storage/custom.iso
```

## 环境变量

所有环境变量都与 dockur/windows 完全兼容：

### 基本配置

| 变量 | 默认值 | 说明 | 可选值 |
|------|--------|------|--------|
| `VERSION` | `10` | Windows 版本 | `10`, `11`, `7`, `2019`, `2022` |
| `LANGUAGE` | `en` | 语言 | `Chinese`, `English`, `Japanese`, `Korean` |
| `MANUAL` | `Y` | 手动/自动模式 | `Y`, `N` |
| `USERNAME` | - | 自动安装用户名 | 任意字符串 |
| `PASSWORD` | - | 自动安装密码 | 任意字符串 |

### 资源配置

| 变量 | 默认值 | 说明 | 推荐值 |
|------|--------|------|--------|
| `CPU_CORES` | `2` | CPU 核心数 | 2-8 |
| `RAM_SIZE` | `4G` | 内存大小 | 4G-16G |
| `DISK_SIZE` | `64G` | 磁盘大小 | 32G-256G |

### 高级配置

| 变量 | 默认值 | 说明 | 可选值 |
|------|--------|------|--------|
| `VMX` | `N` | 嵌套虚拟化 | `Y`, `N` |
| `HV` | `Y` | Hypervisor 标志 | `Y`, `N` |
| `TPM` | `N` | TPM 2.0 支持 | `Y`, `N` |
| `SECBOOT` | `N` | Secure Boot | `Y`, `N` |
| `ARGUMENTS` | - | 额外 QEMU 参数 | QEMU 参数字符串 |
| `DEBUG` | `N` | 调试模式 | `Y`, `N` |

### Windows 版本支持

支持以下 Windows 版本：

| 版本 | 环境变量值 | 说明 |
|------|-----------|------|
| Windows 10 Pro | `VERSION=10` 或 `VERSION=10pro` | 标准专业版 |
| Windows 10 Pro Workstation | `VERSION=10prows` 或 `VERSION=10pro-workstation` | 工作站版 |
| Windows 10 Enterprise LTSC | `VERSION=10l` 或 `VERSION=ltsc10` | 长期服务版 |
| Windows 11 Pro | `VERSION=11` 或 `VERSION=11pro` | Windows 11 专业版 |
| Windows 11 Enterprise | `VERSION=11e` 或 `VERSION=11enterprise` | Windows 11 企业版 |
| Windows Server 2019 | `VERSION=2019` | 服务器版 |
| Windows Server 2022 | `VERSION=2022` | 服务器版 |

## 端口配置

容器暴露以下端口：

| 端口 | 协议 | 用途 | 说明 |
|------|------|------|------|
| `5900` | TCP | VNC | 图形界面访问 |
| `5700` | TCP | VNC WebSocket | 浏览器 VNC 访问 |
| `7100` | TCP | QEMU Monitor | telnet 连接，用于高级控制 |
| `3389` | TCP/UDP | RDP | 远程桌面协议 |
| `445` | TCP | Samba | Windows 文件共享 |

### 端口映射示例

```bash
# 标准端口映射
-p 5900:5900 \
-p 5700:5700 \
-p 7100:7100 \
-p 3389:3389 \
-p 445:445

# 自定义端口映射
-p 5901:5900 \
-p 5701:5700 \
-p 7101:7100 \
-p 3390:3389 \
-p 446:445
```

## 存储配置

### 卷挂载

| 容器路径 | 主机路径 | 用途 |
|----------|----------|------|
| `/storage` | `./data/win` | Windows 磁盘、ISO 文件、固件 |
| `/shared` | `./data/smb` | Samba 共享目录 |

### 存储结构

```
/storage/
├── boot.iso          # Windows 安装 ISO
├── custom.iso        # 自定义 ISO (可选)
├── windows.img       # Windows 磁盘镜像
├── driver.iso        # VirtIO 驱动 ISO
└── firmware/         # UEFI 固件文件
    ├── OVMF_CODE.fd
    └── OVMF_VARS.fd
```

## 网络配置

### TAP 网络模式（推荐）

TAP 模式提供更好的网络性能，需要特殊权限：

```bash
--device /dev/net/tun \
--cap-add NET_ADMIN
```

网络配置：
- **子网**: `172.20.0.0/24`
- **网关**: `172.20.0.1`
- **DHCP**: `172.20.0.100-200`
- **DNS**: `8.8.8.8, 8.8.4.4`

### User 网络模式

如果 TAP 不可用，自动回退到 User 网络模式：
- 性能较低
- 无需特殊权限
- 端口转发支持有限

## 文件共享

### Samba 共享

容器启动后 Samba 自动运行，在 Windows 中访问：

```
\\172.20.0.1\shared
```

### 共享目录配置

```bash
# 主机目录
./data/smb/

# Windows 访问
网络 -> 映射网络驱动器 -> \\172.20.0.1\shared
```

## 自定义 ISO

### 使用自定义 ISO

将 ISO 文件放置到 `/storage` 目录：

```bash
# 复制 ISO 文件
cp Windows10.iso ./data/win/custom.iso
# 或
cp Windows10.iso ./data/win/boot.iso

# 启动容器时会自动检测
docker exec -it dwc-vm vm-start
```

### ISO 文件优先级

系统按以下顺序查找 ISO：
1. `/storage/custom.iso`
2. `/storage/boot.iso`
3. 自动下载的 ISO

## QEMU Monitor

### 连接 QEMU Monitor

```bash
# 使用 telnet 连接
telnet localhost 7100

# 或使用 docker exec
docker exec -it dwc-vm telnet localhost 7100
```

### 常用命令

| 命令 | 说明 |
|------|------|
| `info status` | 查看虚拟机状态 |
| `info cpus` | 查看 CPU 信息 |
| `info network` | 查看网络信息 |
| `info block` | 查看块设备信息 |
| `system_powerdown` | ACPI 关机信号 |
| `system_reset` | 重启虚拟机 |
| `quit` | 强制退出 QEMU |
| `savevm <name>` | 保存快照 |
| `loadvm <name>` | 加载快照 |

## 嵌套虚拟化

### 启用嵌套虚拟化

在 Windows 中运行 WSL2、Docker、Hyper-V：

```bash
-e VMX=Y \
-e HV=N \
-e ARGUMENTS='-cpu host,-hypervisor,+vmx'
```

### 嵌套虚拟化配置

```bash
docker run -d --name dwc-vm \
  --device=/dev/kvm \
  -e VMX=Y \
  -e HV=N \
  -e CPU_CORES=4 \
  -e RAM_SIZE=8G \
  -e ARGUMENTS='-cpu host,-hypervisor,+vmx' \
  dwc/windows:latest
```

## 与 dockur/windows 比较

| 特性 | dockur/windows | DWC Windows |
|------|----------------|-------------|
| **基础镜像** | Debian | Alpine |
| **镜像大小** | ~1GB | < 350MB |
| **启动方式** | 自动 | 手动 (默认) / 自动 (MANUAL=N) |
| **自动安装** | 默认开启 | 默认关闭 |
| **资源占用** | 较高 | 较低 |
| **启动速度** | 较快 | 较慢 (首次下载 ISO) |
| **配置复杂度** | 简单 | 中等 |
| **自定义能力** | 有限 | 高度可定制 |

## 故障排除

### KVM 不可用

```bash
# 检查 KVM 支持
ls -la /dev/kvm

# 加载 KVM 模块
sudo modprobe kvm_intel  # Intel CPU
sudo modprobe kvm_amd    # AMD CPU

# 检查 KVM 权限
sudo chmod 666 /dev/kvm
```

### 查看详细状态

```bash
# 查看 VM 状态
docker exec -it dwc-vm vm-status

# 查看 QEMU 进程
docker exec -it dwc-vm ps aux | grep qemu

# 查看资源使用
docker exec -it dwc-vm top
```

### 查看日志

```bash
# 查看 QEMU 日志
docker exec -it dwc-vm cat /run/shm/qemu.log

# 查看容器日志
docker logs dwc-vm

# 实时跟踪日志
docker logs -f dwc-vm
```

### 网络问题

```bash
# 检查网络配置
docker exec -it dwc-vm ip addr

# 检查 TAP 设备
docker exec -it dwc-vm ls -la /dev/net/tun

# 重启网络
docker exec -it dwc-vm vm-stop
docker exec -it dwc-vm vm-start
```

### 磁盘空间不足

```bash
# 查看磁盘使用
docker exec -it dwc-vm df -h

# 清理临时文件
docker exec -it dwc-vm vm-cleanup

# 扩展磁盘 (需要重建)
# 修改 DISK_SIZE 环境变量并重建容器
```

## 构建和定制

### 构建镜像

```bash
# 构建 DWC Windows 镜像
docker build -t dwc/windows:latest -f vm/legacy/Dockerfile .

# 构建并推送
docker build -t dwc/windows:latest -f vm/legacy/Dockerfile .
docker push dwc/windows:latest
```

### 定制配置

1. **修改 Dockerfile** - 在 `vm/legacy/Dockerfile` 中添加自定义软件
2. **修改脚本** - 在 `vm/scripts/` 目录中修改管理脚本
3. **添加环境变量** - 在 `docker-compose.yml` 中添加新的配置选项
4. **自定义 ISO** - 使用自定义 Windows ISO 进行安装

### 脚本结构

```
vm/scripts/
├── entry.sh      # 主入口脚本
├── vm-setup      # 设置脚本
├── vm-start      # 启动脚本
├── vm-stop       # 停止脚本
├── vm-status     # 状态脚本
├── define.sh     # 配置定义
├── install.sh    # 安装逻辑
├── network.sh    # 网络配置
├── samba.sh      # Samba 配置
├── power.sh      # 电源管理
├── disk.sh       # 磁盘操作
└── helpers.sh    # 辅助函数
```

## 性能优化

### CPU 优化

```bash
# 使用主机 CPU 模型
-e ARGUMENTS='-cpu host'

# 启用嵌套虚拟化
-e ARGUMENTS='-cpu host,-hypervisor,+vmx'

# 分配足够 CPU 核心
-e CPU_CORES=4
```

### 内存优化

```bash
# 分配足够内存
-e RAM_SIZE=8G

# 启用大页内存
-e ARGUMENTS='-machine memory-backend=mem-backend-memfd'
```

### 磁盘优化

```bash
# 使用 virtio 磁盘驱动
-e ARGUMENTS='-device virtio-blk-pci'

# 预分配磁盘空间
-e DISK_PREALLOC=Y
```

## 安全考虑

### 网络安全

```bash
# 限制端口访问
-p 127.0.0.1:5900:5900
-p 127.0.0.1:3389:3389

# 使用防火墙限制访问
sudo ufw allow from 192.168.1.0/24 to any port 5900
```

### 容器安全

```bash
# 使用只读文件系统
--read-only

# 限制 capabilities
--cap-drop=ALL --cap-add=NET_ADMIN

# 使用非 root 用户
--user=1000:1000
```

## 备份和恢复

### 备份虚拟机

```bash
# 备份整个存储目录
tar -czf windows-backup.tar.gz ./data/win/

# 只备份磁盘镜像
cp ./data/win/windows.img ./backup/windows.img.$(date +%Y%m%d)
```

### 恢复虚拟机

```bash
# 恢复存储目录
tar -xzf windows-backup.tar.gz -C ./

# 恢复磁盘镜像
cp ./backup/windows.img.20240101 ./data/win/windows.img
```

## 高级用法

### 快照管理

```bash
# 保存快照
docker exec -it dwc-vm telnet localhost 7100
# 在 QEMU Monitor 中执行: savevm my-snapshot

# 加载快照
docker exec -it dwc-vm telnet localhost 7100
# 在 QEMU Monitor 中执行: loadvm my-snapshot
```

### 多实例运行

```bash
# 运行多个 Windows 实例
docker run -d --name dwc-vm1 -p 5900:5900 dwc/windows:latest
docker run -d --name dwc-vm2 -p 5901:5900 dwc/windows:latest
```

### 性能监控

```bash
# 监控资源使用
docker stats dwc-vm

# 查看 QEMU 性能
docker exec -it dwc-vm virsh domstats
```

## 获取帮助

如需进一步帮助，请查看：

1. [文档首页](README.md) - 文档入口
2. [Windows VM 指南](VM-GUIDE.md) - 当前 VM 使用说明
3. [快速开始指南](QUICKSTART.md) - 部署和常用命令
4. [GitHub Issues](https://github.com/anomalyco/opencode/issues) - 报告问题和功能请求
