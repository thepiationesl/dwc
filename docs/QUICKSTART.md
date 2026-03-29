# DWC 快速开始指南

本文档提供 DWC 项目的详细部署和使用指南。

## 前置要求

### 系统要求

- **操作系统** - Linux (推荐 Ubuntu 20.04+)
- **内存** - 4GB+ RAM (推荐 8GB+)
- **存储** - 20GB+ 可用空间
- **网络** - 稳定的互联网连接

### 软件要求

- **Docker** - 20.10+
- **Docker Compose** - 1.29+
- **Git** - 2.0+

## 安装步骤

### 1. 安装 Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 或使用包管理器
sudo apt update
sudo apt install docker.io docker-compose-plugin
```

### 2. 克隆项目

```bash
git clone https://github.com/anomalyco/opencode.git
cd dwc
```

### 3. 创建数据目录

```bash
mkdir -p data/{alpine-dev,debian-desktop,debian-audio,debian-asbru,kali-desktop,privacy,win,smb}
```

## 快速部署

### 使用 Docker Compose

```bash
# 查看可用服务
docker-compose config --services

# 启动所有服务
docker-compose up -d

# 启动特定服务
docker-compose up -d debian-desktop
docker-compose up -d windows
docker-compose up -d kali-desktop
```

### 手动运行容器

```bash
# Alpine 开发环境
docker run -d --name dwc-alpine-dev \
  -v $(pwd)/data/alpine-dev:/config \
  -v /var/run/docker.sock:/var/run/docker.sock \
  dwc/alpine-dev:latest

# Debian 桌面
docker run -d --name dwc-debian-desktop \
  -p 6080:6080 -p 5901:5901 \
  -v $(pwd)/data/debian-desktop:/config \
  dwc/debian-desktop:latest

# Kali 桌面
docker run -d --name dwc-kali-desktop \
  -p 6380:6080 -p 6381:6081 -p 6003:5901 \
  -v $(pwd)/data/kali-desktop:/config \
  dwc/kali-desktop:latest
```

## 访问桌面环境

### 浏览器访问 (noVNC)

1. 打开浏览器访问 `http://localhost:6080`
2. 输入密码 `114514` (默认 VNC 密码)
3. 点击连接

### VNC 客户端访问

1. 下载并安装 VNC 客户端 (如 RealVNC Viewer)
2. 连接 `localhost:5901`
3. 输入密码 `114514`

### 音频桌面访问

对于支持音频的桌面环境：

1. 访问 noVNC 页面
2. 点击右上角「音频」按钮启用音频
3. 使用滑块调节音量

## Windows 虚拟机部署

### 手动模式（推荐）

```bash
# 1. 启动容器
docker run -d --name dwc-vm \
  --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN \
  -p 5900:5900 -p 5700:5700 -p 7100:7100 -p 3389:3389 -p 445:445 \
  -v $(pwd)/data/win:/storage -v $(pwd)/data/smb:/shared \
  dwc/windows:latest

# 2. 下载 ISO 和创建磁盘
docker exec -it dwc-vm vm-setup

# 3. 启动虚拟机
docker exec -it dwc-vm vm-start

# 4. 查看状态
docker exec -it dwc-vm vm-status
```

### 自动模式

```bash
# 启用自动安装
docker run -d --name dwc-vm \
  -e MANUAL=N \
  -e USERNAME=youruser \
  -e PASSWORD=yourpass \
  -e VERSION=10 \
  -e LANGUAGE=Chinese \
  --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN \
  -p 5900:5900 -p 3389:3389 -p 445:445 \
  -v $(pwd)/data/win:/storage \
  dwc/windows:latest
```

## 配置管理

### 环境变量

可以通过环境变量自定义配置：

```bash
docker run -d \
  -e USERNAME=myuser \
  -e PASSWORD=mypass \
  -e VNC_PASSWORD=myvncpass \
  dwc/debian-desktop:latest
```

### 数据持久化

所有配置和数据存储在 `/config` 目录：

```bash
# 备份配置
tar -czf config-backup.tar.gz ./data/

# 恢复配置
tar -xzf config-backup.tar.gz -C ./
```

## 服务管理

### 查看状态

```bash
# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看服务状态
docker-compose ps

# 查看资源使用
docker stats
```

### 日志查看

```bash
# 查看容器日志
docker logs dwc-debian-desktop

# 查看服务日志
docker-compose logs debian-desktop

# 实时跟踪日志
docker logs -f dwc-debian-desktop
```

### 重启和停止

```bash
# 重启容器
docker restart dwc-debian-desktop

# 停止容器
docker stop dwc-debian-desktop

# 停止并删除容器
docker rm -f dwc-debian-desktop

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

## 故障排除

### 常见问题

#### 无法访问 noVNC

```bash
# 检查容器状态
docker ps

# 查看日志
docker logs dwc-debian-desktop

# 检查 VNC 是否运行
docker exec dwc-debian-desktop ps aux | grep vnc

# 重启容器
docker restart dwc-debian-desktop
```

#### 音频不工作

```bash
# 检查 PulseAudio
docker exec dwc-debian-audio pulseaudio --check

# 检查音频端口
docker exec dwc-debian-audio netstat -tlnp | grep 6081

# 重启音频服务
docker exec dwc-debian-audio pulseaudio --kill
docker exec dwc-debian-audio pulseaudio --start
```

#### Windows 虚拟机问题

```bash
# 查看 VM 状态
docker exec dwc-vm vm-status

# 查看 QEMU 日志
docker exec dwc-vm cat /run/shm/qemu.log

# 检查 KVM 支持
ls -la /dev/kvm

# 重启虚拟机
docker exec dwc-vm vm-stop
docker exec dwc-vm vm-start
```

#### 权限问题

```bash
# 修复配置目录权限
docker exec dwc-debian-desktop /usr/local/bin/fix-permissions.sh

# 检查用户权限
docker exec dwc-debian-desktop id

# 重新创建容器
docker rm -f dwc-debian-desktop
docker run -d --name dwc-debian-desktop dwc/debian-desktop:latest
```

## 高级配置

### 自定义镜像

```bash
# 构建自定义镜像
docker build -t my-dwc-debian:latest -f desktop/debian/Dockerfile .

# 使用自定义镜像
docker run -d --name my-desktop my-dwc-debian:latest
```

### 网络配置

```bash
# 创建自定义网络
docker network create dwc-network

# 使用自定义网络
docker run -d --network dwc-network --name dwc-debian-desktop dwc/debian-desktop:latest
```

### 资源限制

```bash
# 限制 CPU 和内存
docker run -d \
  --cpus=2 \
  --memory=4G \
  --memory-swap=8G \
  --name dwc-debian-desktop \
  dwc/debian-desktop:latest
```

## 更新和维护

### 更新镜像

```bash
# 拉取最新镜像
docker pull dwc/debian-desktop:latest

# 重建所有镜像
docker-compose build --pull

# 重启服务
docker-compose up -d
```

### 清理资源

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的容器
docker container prune

# 清理未使用的卷
docker volume prune

# 清理构建缓存
docker builder prune
```

## 获取帮助

如果遇到问题，请查看：

1. [文档首页](README.md) - 详细的使用指南
2. [GitHub Issues](https://github.com/anomalyco/opencode/issues) - 报告问题和功能请求
3. [文档索引](INDEX.md) - 查找对应主题文档
