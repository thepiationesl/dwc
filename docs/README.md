# DWC (Docker Workstation Containers)

**版本**: 2.0.0  
**状态**: 草案 (Draft)

---

## 项目简介

DWC 是一个基于容器技术的多服务开发环境项目，提供 Windows 虚拟机、开发容器和桌面环境的统一解决方案。

### 核心特性

- **轻量化** - 基于 Alpine/Debian slim，镜像体积小
- **模块化** - 每个服务独立运行，通过 Docker Compose 编排
- **兼容性** - 支持本地部署和 GitHub Codespaces
- **可扩展** - 支持自定义 ISO、插件和配置

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 1.29+
- KVM 支持 (可选)

### 启动服务

```bash
# 启动所有服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f cs50-vm
```

### 访问服务

| 服务 | 端口 | 访问方式 |
|------|------|----------|
| CS50 VM | 5900/5700 | VNC 客户端 / 浏览器 |
| Desktop | 6080 | http://localhost:6080 |
| Desktop Audio | 6180 | http://localhost:6180 |
| Kali | 6280 | http://localhost:6280 |

## 服务概览

### CS50 Windows VM

基于 QEMU 的精简 Windows 虚拟机 (<1.5GB)。

```bash
# 启动
docker-compose up -d cs50-vm

# 进入容器
docker-compose exec -it cs50-vm bash

# 准备安装
vm-setup

# 启动虚拟机
vm-start
```

**环境变量**:

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VERSION | 10 | Windows 版本 (10, 11, ltsc) |
| MANUAL | Y | Y=手动, N=自动 |
| CPU_CORES | 4 | CPU 核心数 |
| RAM_SIZE | 8G | 内存大小 |
| DISK_SIZE | 64G | 磁盘大小 |

### 开发容器

通用开发环境 (<1.2GB)，支持 Python、Node.js、Docker CLI。

```bash
docker-compose up -d dev
docker-compose exec -it dev bash
```

### 桌面环境

| 类型 | 端口 | 说明 |
|------|------|------|
| desktop | 6080 | 标准 Debian XFCE |
| desktop-audio | 6180 | 带音频支持 |
| kali | 6280 | Kali Linux 安全工具 |

```bash
docker-compose up -d desktop
# 访问: http://localhost:6080
```

## 目录结构

```
dwc/
├── containers/
│   ├── cs50-vm/          # Windows 虚拟机 (<1.5GB)
│   ├── dev/              # 开发环境 (<1.2GB)
│   └── desktop/          # 桌面环境
├── common/               # 共享脚本
├── novnc/                # VNC 客户端 (含音频)
├── docs/                 # 文档
│   └── DRAFT.md          # 正式文档草案
├── docker-compose.yml    # 服务编排
└── .devcontainer/        # Codespaces 配置
```

## 配置参考

### 镜像源

所有容器使用统一镜像源 (IPv6):

- Debian: `mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/mirrors/debian`
- NPM: `mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm`

### 端口映射

| 服务 | 端口 | 用途 |
|------|------|------|
| VNC | 5900 | 远程桌面 |
| VNC WebSocket | 5700 | 浏览器 VNC |
| RDP | 3389 | Windows 远程桌面 |
| SMB | 445 | 文件共享 |
| noVNC | 6080/6180/6280 | 网页访问 |

### 用户和密码

| 用户 | 密码 | 说明 |
|------|------|------|
| root | toor | 管理员 |
| qwe | toor | 桌面用户 |
| dev | toor | 开发用户 |

## 文档导航

- [DRAFT.md](DRAFT.md) - 正式文档草案 (完整合并版)

## GitHub Codespaces

支持在 GitHub Codespaces 中使用。

1. 创建新的 Codespace
2. 选择容器配置 (CS50 VM 或 Dev)
3. 等待容器启动
4. 手动执行 `vm-setup` 和 `vm-start`

## 故障排除

### KVM 不可用

```
[WARN] KVM not available, using TCG (slower)
```

正常降级到 TCG 模式，性能较低但可工作。

### 网络问题

```bash
# 检查设备
ls -l /dev/kvm /dev/net/tun

# 查看日志
docker-compose logs <service>
```

### 音频无声

1. 检查浏览器音频权限
2. 点击页面音频按钮启用
3. 调整音量滑块

## 技术栈

| 类别 | 技术 |
|------|------|
| 容器 | Docker, Docker Compose |
| 基础 | Alpine Linux, Debian slim |
| 桌面 | XFCE4, TigerVNC, noVNC |
| 音频 | PulseAudio, GStreamer |
| 虚拟化 | QEMU, KVM |
| 开发 | Python 3, Node.js |

## 许可

MIT License

---

**最后更新**: 2026-03-29
