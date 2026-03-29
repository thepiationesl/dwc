# DWC - Docker Workstation Containers

一组可组合的容器镜像集合，提供开发环境、Windows 虚拟机和远程桌面。

## 快速开始

### 基本要求

- Docker 和 Docker Compose
- 运行 VM 时建议启用 KVM
- 至少 50GB 自由磁盘空间（运行VM时）

### 常用命令

```bash
# 开发环境
docker-compose up -d dev

# Windows VM（手动模式）
docker-compose up -d cs50-vm

# 远程桌面
docker-compose up -d desktop
```

## 仓库结构

```
dwc/
├── .devcontainer/           # VS Code Dev Container 配置
│   ├── cs50-vm/             # CS50 VM Codespaces 配置
│   └── dev-debian/          # 开发容器 Codespaces 配置
├── containers/              # 容器镜像
│   ├── cs50-vm/             # CS50 Windows VM（精简版 <1.5GB）
│   ├── dev/                 # 开发环境（<1.2GB）
│   └── desktop/             # 远程桌面（Debian/Kali）
├── common/                  # 公共脚本
├── novnc/                   # noVNC（带音频支持）
├── skel/                    # 用户环境模板
├── docs/                    # 文档
│   ├── VM-MANUAL.md         # VM 手动安装指南
│   ├── VM-AUTO.md           # VM 自动安装指南
│   └── ARCHITECTURE.md      # 架构说明
└── docker-compose.yml       # 编排配置
```

## 服务概览

### CS50 VM

精简版 Windows 虚拟机，针对 GitHub Codespaces 优化：

```bash
# 启动容器
docker run -it --device=/dev/kvm --device=/dev/net/tun \
  --cap-add=NET_ADMIN -v ./storage:/storage dwc/cs50-vm

# 容器内执行
vm-setup    # 准备安装
vm-start    # 启动 VM
vm-stop     # 停止 VM
vm-status   # 查看状态
```

详见 [VM 手动安装指南](docs/VM-MANUAL.md) 和 [VM 自动安装指南](docs/VM-AUTO.md)。

### 开发容器

标准开发环境，包含 Docker CLI、Python、Node.js、QEMU：

```bash
docker-compose up -d dev
docker exec -it dev bash
```

### 远程桌面

XFCE4 桌面环境，支持 VNC 和 noVNC：

```bash
docker-compose up -d desktop
# 访问 http://localhost:6080
```

## 配置

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | `10` | Windows 版本 |
| `LANGUAGE` | `Chinese` | 系统语言 |
| `DISK_SIZE` | `64G` | 磁盘大小 |
| `RAM_SIZE` | `8G` | 内存大小 |
| `CPU_CORES` | `4` | CPU 核心数 |
| `MANUAL` | `Y` | 手动模式 |

### 镜像源

所有镜像使用以下源：
- Debian: `http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/mirrors/debian`
- NPM: `http://mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm`

### 目录约定

| 路径 | 说明 |
|------|------|
| `/workspaces` | 用户根目录 |
| `/storage` | VM 存储（磁盘、ISO） |
| `/shared` | Samba 共享目录 |

## GitHub Codespaces

在 Codespaces 中选择对应的 devcontainer 配置：

- **CS50 Windows VM** - `cs50-vm`
- **Dev Container** - `dev-debian`

## 默认配置

| 项目 | 值 |
|------|-----|
| 用户名 | `dev` / `qwe` |
| 密码 | `toor` |
| UID/GID | `1000/1000` |
| VNC 密码 | `114514` |

## 文档

- [VM 手动安装](docs/VM-MANUAL.md)
- [VM 自动安装](docs/VM-AUTO.md)
- [架构说明](docs/ARCHITECTURE.md)
- [QEMU 参考](docs/QEMU-WINDOWS-10-GUIDE.md)

## 相关资源

- [dockur/windows](https://github.com/dockur/windows) - 参考实现
- [cs50/codespace](https://github.com/cs50/codespace) - CS50 官方
- [noVNC](https://novnc.com/) - Web VNC 客户端
