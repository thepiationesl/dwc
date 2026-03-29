# DWC - Docker Workstation Containers

一组可组合的容器镜像集合，提供开发环境、Windows 虚拟机、远程桌面和隐私工作站。

## ⚡ 快速开始

### 基本要求

- Docker 和 Docker Compose
- 运行 VM 时建议启用 KVM
- 至少 50GB 自由磁盘空间（运行VM时）

### 常用命令

```bash
# 推荐开发环境
docker-compose up -d debian-dev

# Windows VM（手动安装）
docker-compose up -d windows-manual

# Windows VM（自动安装）
docker-compose up -d windows-auto

# CS50 教学 VM
docker-compose up -d cs50-windows

# 远程桌面（Debian 或 Kali）
docker-compose up -d debian-audio
docker-compose up -d kali-desktop

# 隐私工作站
docker-compose up -d privacy
```

## 📦 服务概览

### 开发环境

| 服务 | 说明 |
|------|------|
| `debian-dev` | 推荐的 Debian 开发环境，内置 Docker、Python、Node.js |
| `alpine-dev` | 兼容旧版本的 Alpine 轻量开发环境 |

### 虚拟机

| 服务 | 说明 |
|------|------|
| `windows-manual` | Windows 10 VM，手动安装模式 |
| `windows-auto` | Windows 10 VM，基于 Sysprep 自动安装 |
| `windows` | 旧版兼容 VM（使用旧版镜像） |
| `cs50-windows` | Windows 10 VM，CS50 教学场景优化 |

### 远程桌面

| 服务 | 说明 |
|------|------|
| `debian-desktop` | Debian XFCE 桌面，基础配置 |
| `debian-audio` | Debian 桌面，支持音频和多种远程连接 |
| `debian-asbru` | Debian 桌面，集成 Asbru SSH 管理工具 |
| `kali-desktop` | Kali Linux 桌面，渗透测试工具集 |

### 专用工作站

| 服务 | 说明 |
|------|------|
| `privacy` | Tor + Pidgin 隐私工作站 |

## 📁 仓库结构

```
dwc/
├── .devcontainer/           # VS Code Dev Container 配置
├── common/                  # 公共脚本和工具
├── cs50/                    # CS50 专用镜像和配置
├── desktop/                 # 桌面环境镜像（Debian/Kali）
├── dev/                     # 开发环境镜像
├── docs/                    # 完整文档
├── novnc/                   # noVNC Web VNC 客户端
├── privacy/                 # 隐私工作站镜像
├── skel/                    # 用户环境模板
├── vm/                      # Windows VM 核心镜像和脚本
├── docker-compose.yml       # 统一编排配置文件
└── README.md                # 本文件
```

## 📖 文档导航

### 入门指南

- **[快速开始](docs/QUICKSTART.md)** - 最快部署方案
- **[文档索引](docs/INDEX.md)** - 按场景查找文档

### 核心文档

- **[架构说明](docs/ARCHITECTURE.md)** - 系统设计和目录职责
- **[项目蓝图](docs/BLUEPRINT.md)** - 设计约束和功能说明

### 专题指南

- **[虚拟机指南](docs/VM-GUIDE.md)** - Windows VM 部署和使用
- **[CS50 指南](docs/CS50-VM-GUIDE.md)** - 教学场景配置
- **[QEMU 高级参考](docs/QEMU-WINDOWS-10-GUIDE.md)** - 历史记录和高级调优
- **[Codespaces 配置](docs/CODESPACES-DEV-VM-CS50.md)** - 云开发环境

### 子目录说明

- **[vm/ 详情](vm/README.md)** - Windows VM 镜像详解
- **[cs50/ 详情](cs50/README.md)** - CS50 镜像详解

## 🔧 常见任务

### 构建镜像

```bash
# 构建全部镜像
docker-compose build

# 构建特定镜像
docker-compose build debian-dev
docker-compose build windows-manual
docker-compose build cs50-windows
```

### 查看日志

```bash
# 查看特定容器日志
docker-compose logs -f debian-dev

# 进入容器
docker exec -it debian-dev bash
```

### 停止和清理

```bash
# 停止所有服务
docker-compose down

# 清理未使用的镜像和卷
docker system prune -a --volumes
```

## 🔑 默认配置

| 项目 | 值 |
|------|-----|
| 用户名 | `qwe` |
| 密码 | `toor` |
| UID/GID | `1000/1000` |
| 主目录 | `/config` |
| VNC 密码 | `114514` |

## 🆘 故障排查

| 问题 | 解决方案 |
|------|----------|
| 容器无法启动 | 查看 [快速开始](docs/QUICKSTART.md) |
| VM 连接失败 | 查看 [虚拟机指南](docs/VM-GUIDE.md) |
| CS50 特定问题 | 查看 [CS50 指南](docs/CS50-VM-GUIDE.md) |

## 📚 相关资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [noVNC 项目](https://novnc.com/)
- [QEMU 文档](https://www.qemu.org/)
- [dockur/windows](https://github.com/dockur/windows)
- [Harvard CS50](https://cs50.harvard.edu)
