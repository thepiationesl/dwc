# CS50 Windows VM 指南

适用于哈佛大学 CS50 课程的 Windows 虚拟机容器。这是一个精简版本，专为 CS50 实验配置。

## 概述

CS50 Windows VM 是基于原始 DWC Windows VM 的精简版本，禁用了不必要的功能（如 Docker），同时保留了 KVM 虚拟化支持。

## 快速开始

### 前置要求

- Docker 已安装和运行
- KVM 支持（可选但推荐）
- 至少 50GB 自由磁盘空间
- 至少 12GB 内存（推荐 16GB+）

### 使用 Docker Compose

```yaml
version: "3.8"

services:
  cs50-windows:
    build:
      context: .
      dockerfile: cs50/vm/Dockerfile
    image: miko453/dwc:cs50-vm
    container_name: cs50-vm
    environment:
      VERSION: "10"              # Windows 10
      LANGUAGE: "English"        # 或 "Chinese"
      CPU_CORES: "4"
      RAM_SIZE: "8G"
      DISK_SIZE: "40G"
      KEYBOARD: "us"
      REGION: "US"
    devices:
      - /dev/kvm:/dev/kvm
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
    volumes:
      - ./cs50-storage:/storage
      - ./cs50-shared:/shared
    ports:
      - "5900:5900"              # VNC
      - "5700:5700"              # VNC WebSocket
      - "3389:3389"              # RDP (推荐)
    restart: unless-stopped
```

### 基本命令

```bash
# 下载 ISO 和设置
docker exec cs50-vm vm-setup

# 启动虚拟机
docker exec cs50-vm vm-start

# 停止虚拟机
docker exec cs50-vm vm-stop

# 查看状态
docker exec cs50-vm vm-status
```

## 连接方式

### 推荐：RDP（远程桌面）

使用 RDP 连接获得最佳性能和兼容性：

```bash
# Linux/Mac (使用 rdesktop)
rdesktop -u Administrator localhost:3389

# 或使用 RDP 客户端
# Windows: mstsc /v:localhost:3389
# macOS: 使用 Microsoft Remote Desktop (App Store)
# Linux: Remmina 或 rdesktop
```

### VNC（备选）

通过 WebSocket 使用 VNC：

```bash
# 直接 VNC
vnc://localhost:5900

# 或 WebSocket
http://localhost:5700
```

## 安装和配置

### 第一次安装

1. **运行容器并下载 ISO**
   ```bash
   docker-compose up -d cs50-windows
   docker exec cs50-vm vm-setup
   ```

2. **启动虚拟机**
   ```bash
   docker exec cs50-vm vm-start
   ```

3. **连接并安装 Windows**
   - 使用 RDP 连接到 `localhost:3389`
   - 默认用户：`Administrator`
   - 按照 Windows 安装向导完成安装

4. **安装完成后**
   - 虚拟机会自动保存状态
   - 下次启动会直接进入已安装的系统

### 预装软件清单

CS50 镜像不包含 Docker 等不必要的工具，但包含：

- QEMU 虚拟化
- VNC 和 RDP 支持
- Samba 文件共享
- VirtIO 驱动
- 基本的网络工具

您可以在 Windows 内部安装所需的开发工具。

## 文件共享

### Samba 共享

从虚拟机内部访问主机的共享文件：

```
// 虚拟机内 (Windows)
\\<host-ip>\shared
// 用户名: qwe
// 密码: toor
```

### 直接挂载

将文件复制到 `./cs50-shared` 目录：

```bash
# 主机命令
cp -r /path/to/files ./cs50-shared/

# 虚拟机内可以访问
Z:\shared\  (Samba 挂载)
```

## 性能优化

### 分配更多资源

编辑 `docker-compose.yml`：

```yaml
environment:
  CPU_CORES: "8"      # 增加到 8 核
  RAM_SIZE: "16G"     # 增加到 16GB
  DISK_SIZE: "80G"    # 增加磁盘到 80GB
```

### 启用虚拟化加速

确保 KVM 可用并已挂载：

```yaml
devices:
  - /dev/kvm:/dev/kvm
```

### 网络优化

使用 TAP 网络以获得更好的网络性能：

```yaml
devices:
  - /dev/net/tun:/dev/net/tun
cap_add:
  - NET_ADMIN
```

## 常见问题

### Q: 如何备份虚拟机磁盘？

```bash
# 复制整个存储目录
cp -r cs50-storage cs50-storage-backup

# 或压缩备份
tar -czf cs50-vm-backup.tar.gz cs50-storage/
```

### Q: 虚拟机太慢，如何提速？

1. 分配更多 CPU 核心和内存
2. 在 Windows 中禁用不必要的启动项
3. 确保 KVM 已启用（`--device=/dev/kvm`）

### Q: 如何重置虚拟机？

```bash
# 删除存储目录中的虚拟磁盘
rm cs50-storage/disk.qcow2

# 重新运行 vm-setup 和 vm-start
docker exec cs50-vm rm -rf /storage/disk.qcow2
docker exec cs50-vm vm-setup
docker exec cs50-vm vm-start
```

### Q: 支持哪些 Windows 版本？

CS50 镜像支持：
- Windows 10
- 可以通过修改 `VERSION` 环境变量支持 Windows 11

### Q: 容器启动失败，怎么办？

检查日志：

```bash
docker logs cs50-vm

# 进入容器调试
docker exec -it cs50-vm bash
vm-status
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | 10 | Windows 版本 |
| `LANGUAGE` | English | 语言：English 或 Chinese |
| `CPU_CORES` | 4 | CPU 核心数 |
| `RAM_SIZE` | 8G | 内存大小 |
| `DISK_SIZE` | 40G | 磁盘大小 |
| `KEYBOARD` | us | 键盘布局 |
| `REGION` | US | 地区设置 |
| `MANUAL` | Y | 手动安装模式 |

## 停止和删除

### 正确的停止方式

```bash
# 优雅停止容器（等待 60 秒）
docker-compose down

# 或使用命令
docker exec cs50-vm vm-stop
docker stop cs50-vm
```

### 完全清理

```bash
# 删除容器和所有数据
docker-compose down -v
rm -rf cs50-storage cs50-shared
```

## 故障排除

### 连接问题

```bash
# 检查容器是否运行
docker ps | grep cs50

# 查看容器日志
docker logs -f cs50-vm

# 进入容器并检查网络
docker exec cs50-vm ifconfig
docker exec cs50-vm netstat -tuln
```

### 性能问题

```bash
# 查看资源使用
docker stats cs50-vm

# 查看 QEMU 进程
docker exec cs50-vm ps aux | grep qemu

# 检查磁盘 I/O
docker exec cs50-vm iostat
```

### 虚拟机不启动

```bash
# 检查 KVM 可用性
docker exec cs50-vm ls -la /dev/kvm

# 查看虚拟机日志
docker exec cs50-vm cat /storage/qemu.log
```

## 高级用法

### 自定义 Windows 配置

在虚拟机启动后，可以自定义：

1. 用户账户
2. 网络设置
3. 安装额外软件
4. 配置开发环境

### 保存虚拟机快照

```bash
# 基于当前状态创建备份
cp -r cs50-storage cs50-storage-snapshot-$(date +%Y%m%d)
```

### 在多个主机间传输

```bash
# 压缩虚拟机映像
tar -czf cs50-vm.tar.gz cs50-storage/

# 复制到另一个主机
scp cs50-vm.tar.gz user@host:/path/to/

# 在另一个主机解压
tar -xzf cs50-vm.tar.gz
```

## 与标准 DWC Windows VM 的区别

| 功能 | CS50 版本 | 完整版本 |
|------|-----------|---------|
| 基础镜像 | Debian slim | Debian slim |
| Docker | ❌ 移除 | ✅ 包含 |
| QEMU 虚拟化 | ✅ | ✅ |
| KVM 支持 | ✅ | ✅ |
| Samba 共享 | ✅ | ✅ |
| 自动安装模式 | ❌ 不支持 | ✅ 支持 |
| 自定义参数 | 基础 | 完整 |
| 镜像大小 | < 500MB | < 600MB |

## 许可证

基于 [dockur/windows](https://github.com/dockur/windows)，适配 DWC 项目。

## 相关链接

- [DWC 主项目](../)
- [VM 完整指南](../docs/VM-GUIDE.md)
- [CS50 课程](https://cs50.harvard.edu)
- [QEMU 文档](https://www.qemu.org/docs/)
