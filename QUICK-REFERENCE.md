# DWC 快速参考 (Quick Reference)

## 核心命令

### CS50 VM (手动模式)

```bash
# 启动容器
docker-compose up -d cs50-vm

# 进入容器
docker-compose exec -it cs50-vm bash

# 准备ISO和磁盘
vm-setup

# 启动虚拟机
vm-start

# 停止虚拟机
vm-stop

# 查看状态
vm-status

# 查看日志
docker-compose logs cs50-vm
```

### 开发容器

```bash
# 启动
docker-compose up -d dev

# 进入
docker-compose exec -it dev bash

# 验证Python
docker-compose exec dev python3 --version

# 验证Node.js
docker-compose exec dev node --version

# 验证Docker
docker-compose exec dev docker --version
```

### 远程桌面

```bash
# 启动标准桌面
docker-compose up -d desktop

# 启动含音频桌面
docker-compose up -d desktop-audio

# 启动Kali
docker-compose up -d kali

# 访问: http://localhost:6080 (标准桌面)
# 访问: http://localhost:6180 (音频桌面)
# 访问: http://localhost:6280 (Kali)
```

## 环境变量

### CS50 VM常用

```bash
# 容器启动时设置
docker run -e VERSION=11 -e CPU_CORES=8 -e RAM_SIZE=16G ...

# Docker Compose中设置
services:
  cs50-vm:
    environment:
      VERSION: "10"
      CPU_CORES: "4"
      RAM_SIZE: "8G"
      DISK_SIZE: "64G"
      MANUAL: "Y"  # Y=手动, N=自动
```

### 可用变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VERSION | 10 | Windows版本 (10, 11, ltsc) |
| CPU_CORES | 4 | CPU核心数 |
| RAM_SIZE | 8G | 内存大小 |
| DISK_SIZE | 64G | 磁盘大小 |
| MANUAL | Y | 手动(Y)或自动(N) |
| LANGUAGE | Chinese | 系统语言 |

## 端口映射

| 服务 | 端口 | 说明 |
|------|------|------|
| VNC | 5900 | 远程桌面 (RFB) |
| VNC WebSocket | 5700 | 浏览器VNC |
| RDP | 3389 | Windows远程桌面 |
| SMB | 445 | 文件共享 |
| noVNC | 6080 | 网页访问 |
| Audio | 6081 | 音频流 |

## 目录结构

```
dwc/
├── containers/
│   ├── cs50-vm/          # Windows VM (精简版)
│   ├── dev/              # 开发环境
│   └── desktop/          # 桌面环境
├── docs/                 # 文档
│   ├── VM-MANUAL.md      # 手动安装
│   ├── VM-AUTO.md        # 自动安装
│   └── ARCHITECTURE.md   # 架构
├── novnc/                # VNC客户端
├── common/               # 共享脚本
└── docker-compose.yml    # 编排
```

## 常用路径

| 路径 | 说明 |
|------|------|
| /workspaces | 用户根目录 |
| /storage | VM存储 (ISO/磁盘) |
| /shared | Samba共享 |
| /config | 桌面配置 |

## 故障排除

### 容器无法启动

```bash
# 检查Docker
docker ps

# 查看日志
docker-compose logs <service>

# 重新构建
docker-compose build --no-cache <service>
```

### 网络问题

```bash
# 检查设备
ls -l /dev/kvm /dev/net/tun

# 检查能力
docker inspect <container> | grep "CapAdd"

# 重启networking
docker-compose restart
```

### 音频无声

```bash
# 容器内检查
docker exec <container> ps aux | grep audio

# 查看进程日志
docker logs <container> 2>&1 | grep -i audio
```

## 镜像源

### Debian
```
mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/mirrors/debian
```

### NPM
```
mirrors.7.b.0.5.0.7.4.0.1.0.0.2.ip6.arpa/language/npm
```

## 用户和密码

| 用户 | 密码 | 说明 |
|------|------|------|
| root | toor | 根用户 (CS50 VM) |
| dev | toor | 开发用户 |
| qwe | toor | 桌面用户 |

## 关键文件

| 文件 | 说明 |
|------|------|
| containers/cs50-vm/Dockerfile | VM镜像定义 |
| containers/cs50-vm/scripts/vm-setup | ISO准备脚本 |
| containers/cs50-vm/scripts/vm-start | 启动脚本 |
| novnc/app/audio.js | 音频模块 |
| novnc/app/ui.js | UI集成 |

## 常见任务

### 自定义Windows ISO

```bash
# 放置ISO到storage目录
cp my-windows.iso ./data/cs50-storage/custom.iso

# 启动容器
docker-compose up cs50-vm
```

### Samba共享文件

```bash
# Windows中访问
\\172.20.0.1\shared

# 主机中的位置
./data/cs50-shared/
```

### 查看VM大小

```bash
# 构建后查看
docker images dwc/cs50-vm

# 预期: <1.5GB
# 预期dev: <1.2GB
```

### 备份VM磁盘

```bash
# 停止容器
docker-compose stop cs50-vm

# 复制磁盘
cp ./data/cs50-storage/windows.qcow2 ./backup/

# 重启
docker-compose up cs50-vm
```

## 性能调优

### 增加内存和CPU

```yaml
environment:
  CPU_CORES: "8"      # 从4改为8
  RAM_SIZE: "16G"     # 从8G改为16G
```

### 增加磁盘大小

```yaml
environment:
  DISK_SIZE: "128G"   # 从64G改为128G
```

### 启用KVM加速

```bash
# 确保设备存在
ls -c /dev/kvm

# docker-compose.yml中
devices:
  - /dev/kvm:/dev/kvm

# 若无KVM，自动用TCG (较慢)
```

## 部署检查清单

- [ ] Docker和Docker Compose已安装
- [ ] 有足够磁盘空间 (50GB+)
- [ ] 网络连接正常
- [ ] IPv6或代理已配置
- [ ] KVM可用 (可选，有则更快)

## 文档导航

| 文档 | 用途 |
|------|------|
| README.md | 主文档和快速开始 |
| VM-MANUAL.md | 手动安装完整指南 |
| VM-AUTO.md | 自动部署配置 |
| ARCHITECTURE.md | 系统架构说明 |
| TECHNICAL-REVIEW.md | 代码审查详情 |
| VERIFICATION-CHECKLIST.md | 验证清单 |
| IMPLEMENTATION-SUMMARY.md | 实施总结 |

## 获得帮助

```bash
# 查看Docker日志
docker logs -f <container>

# 查看compose日志
docker-compose logs -f

# 进入容器调试
docker-compose exec -it <service> bash

# 重启所有服务
docker-compose restart

# 清理所有数据
docker-compose down -v
```

## 版本信息

- **项目版本**: 2.0.0
- **基础镜像**: debian:unstable-slim
- **Node.js**: LTS版本
- **Python**: 3.x
- **QEMU**: 7.x+
- **Docker Compose**: 3.8+

---

**快速参考** | [完整文档](docs/) | [GitHub](https://github.com/thepiationesl/dwc)
