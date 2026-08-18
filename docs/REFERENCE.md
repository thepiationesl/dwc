# 参考手册 - 配置速查表

> 运维工程师 & 高级用户的速查表：端口、密码、环境变量、命令一站式。

---

## 🔑 默认凭证

### SSH / 桌面登录

| 用户 | 密码 | 权限 | 用途 |
|------|------|------|------|
| `qwe` | `toor` | sudoer | 日常使用（推荐） |
| `root` | `toor` | root | 系统管理 |

### VNC / 远程桌面

| 方案 | 密码/令牌 | 说明 |
|------|----------|------|
| VNC | `114514` | 所有桌面型容器 |
| xrdp | `qwe:toor` | full / studio 仅用户名密码 |
| NoMachine | `qwe:toor` | full / studio 仅用户名密码 |
| Anydesk | 动态令牌 | full / studio（需启动后查看） |
| code-server | 查 logs | `docker logs dwc_code \| grep token` |

### Tor

| 端口 | 用途 | 说明 |
|------|------|------|
| 9050 | SOCKS5 代理 | 其他容器/本地客户端可连接 |
| 9051 | 控制端口 | 不暴露，容器内用 |

---

## 🌐 端口映射速查

### 所有镜像的默认端口映射

| 镜像 | 服务 | 容器端口 | 宿主端口 | 说明 |
|------|------|----------|----------|------|
| **desk** | VNC | 5999 | 5999 | TigerVNC |
| **desk** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **desk** | SSH | 22 | 10022 | Dropbear |
| **full** | VNC | 5999 | 5999 | TigerVNC |
| **full** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **full** | SSH | 22 | 10022 | Dropbear |
| **full** | xrdp | 3389 | 10089 | RDP 协议 |
| **full** | NoMachine | 4000 | 4000 | NoMachine NX |
| **full** | Anydesk | 7070 | 7070 | Anydesk（动态） |
| **lite** | VNC | 5999 | 5999 | TigerVNC |
| **lite** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **lite** | SSH | 22 | 10022 | Dropbear |
| **lite-ice** | VNC | 5999 | 5999 | Xvfb + x11vnc |
| **lite-ice** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **lite-ice** | SSH | 22 | 10022 | Dropbear |
| **asbru** | VNC | 5999 | 5999 | Tightvnc（Debian 11） |
| **asbru** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **asbru** | SSH | 22 | 10022 | Dropbear |
| **studio** | VNC | 5999 | 5999 | TigerVNC + 音频 |
| **studio** | noVNC | 6080 | 6080 | 浏览器 VNC（无音频） |
| **studio** | SSH | 22 | 10022 | Dropbear |
| **studio** | xrdp | 3389 | 10089 | RDP + xrdp-pulseaudio |
| **studio** | NoMachine | 4000 | 4000 | NoMachine NX + 音频 |
| **studio** | Anydesk | 7070 | 7070 | Anydesk（动态） |
| **py** | VNC | 5999 | 5999 | TigerVNC |
| **py** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **py** | SSH | 22 | 10022 | Dropbear |
| **browser** | SSH | 22 | 10022 | Dropbear（无桌面） |
| **jump** | SSH | 22 | 10022 | OpenSSH（支持端口转发） |
| **chat** | VNC | 5999 | 5999 | Xvfb + x11vnc |
| **chat** | noVNC | 6080 | 6080 | 浏览器 VNC |
| **chat** | SSH | 22 | 10022 | Dropbear |
| **code** | code-server | 8443 | 8443 | HTTPS |
| **code** | SSH | 22 | 10022 | Dropbear |
| **build** | SSH | 22 | 10022 | Dropbear |
| **build** | Docker Socket | — | — | `/var/run/docker.sock`（挂载） |
| **tor** | SOCKS5 | 9050 | 9050 | Tor 代理 |
| **tor** | SSH | 22 | 10022 | Dropbear |

### 快速参考：常用端口

```bash
# VNC 网页访问（所有桌面型）
http://your-vps-ip:6080

# SSH 访问（所有镜像）
ssh qwe@your-vps-ip -p 10022

# RDP 客户端（full/studio）
your-vps-ip:10089

# NoMachine 客户端（full/studio）
your-vps-ip:4000

# VSCode 网页（code）
https://your-vps-ip:8443

# Tor SOCKS5 代理
your-vps-ip:9050
```

---

## 🎛️ 环境变量完整参考

### 全局环境变量（所有镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LANG` | `en_US.UTF-8` | 语言环境（改 `zh_CN.UTF-8` 用中文） |
| `TZ` | `UTC` | 时区（改 `Asia/Shanghai` 用上海时间） |
| `DEBUG` | `0` | 调试模式（1=开启详细日志） |
| `PUID` | `1000` | 用户 ID（权限映射） |
| `PGID` | `1000` | 用户组 ID（权限映射） |

### SSH 相关（所有镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_SSH` | `true` | 启用 SSH 服务 |
| `SSH_PORT` | `22` | SSH 监听端口（容器内） |
| `ALLOW_PASSWORD` | `true` | 允许密码认证 |

### VNC 相关（桌面型 + chat）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_VNC` | `true` | 启用 VNC 服务 |
| `VNC_GEOMETRY` | `1920x1200` | VNC 分辨率（宽x高） |
| `VNC_DEPTH` | `24` | 颜色深度（8/16/24） |
| `VNC_PASSWORD` | `114514` | VNC 连接密码 |

### xrdp 相关（full/studio）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_XRDP` | `true` | 启用 xrdp 服务 |
| `XRDP_PORT` | `3389` | xrdp 监听端口（容器内） |
| `XRDP_PASSWORD` | `toor` | xrdp 用户密码 |

### NoMachine 相关（full/studio 仅）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_NOMACHINE` | `true` | 启用 NoMachine |
| `NOMACHINE_USER` | `qwe` | NoMachine 用户名 |
| `NOMACHINE_PASSWORD` | `toor` | NoMachine 密码 |

### Anydesk 相关（full/studio 仅）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_ANYDESK` | `true` | 启用 Anydesk |
| `ANYDESK_PASSWORD` | 动态 | Anydesk 密码（启动后动态生成） |

### Tor 相关（tor 镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TOR_SOCKS_PORT` | `9050` | SOCKS5 代理端口 |
| `TOR_CONTROL_PORT` | `9051` | Tor 控制端口 |
| `TOR_BRIDGE` | 空 | 网桥配置（若需翻墙） |

### code-server 相关（code 镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_CODE` | `true` | 启用 code-server |
| `CODE_PORT` | `8443` | code-server 端口 |
| `CODE_PASSWORD` | 自动生成 | 访问密码（查 logs） |

### 修改环境变量的方法

**方法 A：重新运行容器时指定**
```bash
docker run -e LANG=zh_CN.UTF-8 -e TZ=Asia/Shanghai ... dwc:desk
```

**方法 B：修改现有容器**
```bash
docker exec dwc_desk bash -c 'export LANG=zh_CN.UTF-8 && supervisorctl -S /tmp/supervisord.sock restart all'
```

**方法 C：动态更新（容器外）**
```bash
docker update --env-file <(echo 'LANG=zh_CN.UTF-8') dwc_desk
docker restart dwc_desk
```

---

## 🛠️ 常用命令

### 构建 & 运行

```bash
# 列出所有镜像
make list

# 构建单个镜像
make build IMG=desk

# 构建全部 13 个镜像
make build

# 运行单个容器
make run IMG=desk

# 删除镜像
make clean IMG=desk
```

### Docker 基本操作

```bash
# 查看容器状态
docker ps -a

# 查看容器日志（实时跟踪）
docker logs -f dwc_desk

# 进入容器 shell
docker exec -it dwc_desk bash

# 停止容器
docker stop dwc_desk

# 启动容器
docker start dwc_desk

# 重启容器
docker restart dwc_desk

# 删除容器
docker rm dwc_desk

# 删除镜像
docker rmi dwc:desk
```

### 容器内的服务管理

```bash
# 查看所有进程状态
supervisorctl -S /tmp/supervisord.sock status

# 启动/停止/重启单个服务
supervisorctl -S /tmp/supervisord.sock start vnc
supervisorctl -S /tmp/supervisord.sock stop ssh
supervisorctl -S /tmp/supervisord.sock restart all

# 进入 supervisorctl 交互模式
supervisorctl -S /tmp/supervisord.sock

# 重新加载配置文件
supervisorctl -S /tmp/supervisord.sock reread
supervisorctl -S /tmp/supervisord.sock update
```

### VNC 密码管理

```bash
# 进入容器
docker exec -it dwc_desk bash

# 设置新 VNC 密码（交互式）
vncpasswd

# 重启 VNC 服务
supervisorctl -S /tmp/supervisord.sock restart vnc
```

### SSH 密钥登录（可选，更安全）

```bash
# 在容器内生成 SSH 密钥对
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# 查看公钥，复制到宿主 ~/.ssh/authorized_keys
cat ~/.ssh/id_ed25519.pub

# 宿主端测试无密码登录
ssh -i /path/to/private/key qwe@your-vps-ip -p 10022
```

### 容器持久化与数据管理

```bash
# 挂载 /config 目录（运行时指定）
docker run -v /data/dwc_config:/config dwc:desk

# 查看容器挂载情况
docker inspect dwc_desk | grep Mounts -A 10

# 备份 /config 数据
docker cp dwc_desk:/config ./backup_config

# 恢复 /config 数据
docker cp ./backup_config dwc_desk:/config
```

---

## 📊 镜像大小参考

| 镜像 | 约大小 | 备注 |
|------|--------|------|
| desk | ~700MB | 生产常用 |
| full | ~1200MB | 功能最全 |
| lite | ~500MB | 低配优选 |
| lite-ice | ~480MB | 最小化 |
| asbru | ~520MB | Debian 11 |
| studio | ~900MB | 含音乐软件 |
| py | ~600MB | Python 环境 |
| browser | ~150MB | 无头浏览器 |
| jump | ~50MB | 最轻量 |
| chat | ~150MB | 通信工具 |
| code | ~400MB | VSCode 网页 |
| build | ~200MB | Docker CLI |
| tor | ~200MB | Tor 客户端 |

---

## 🔒 安全建议

### 生产环境必做

- [ ] **改默认密码**：`qwe/toor` 和 `root/toor`，以及 VNC 密码 `114514`
- [ ] **启用 SSH 密钥登录**，禁用密码认证（设置 `ALLOW_PASSWORD=false`）
- [ ] **限制端口暴露**：只向特定 IP 开放，用防火墙规则
- [ ] **定期备份**：`/config` 目录定期备份
- [ ] **监控日志**：定期检查 `docker logs`，配置日志轮转
- [ ] **更新镜像**：定期重新构建镜像，获取最新安全补丁

### 网络隔离

```bash
# 创建专用 docker 网络
docker network create dwc-network

# 容器只在内部网络通信
docker run --network dwc-network ...

# 外界只能访问特定端口，通过防火墙控制
iptables -A INPUT -p tcp --dport 6080 -j ACCEPT
iptables -A INPUT -p tcp --dport 10022 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
```

### 定期清理

```bash
# 清理未使用的镜像 & 容器 & 卷
docker system prune -a

# 查看磁盘占用
docker system df
```

---

## 📈 性能调优

### CPU & 内存限制

```bash
# 限制容器使用 1 个 CPU 核心，512MB 内存
docker run --cpus=1 --memory=512m dwc:desk
```

### VNC 分辨率与颜色深度

| 分辨率 | 内存占用 | 建议场景 |
|--------|---------|---------|
| 1920x1200 | ~50MB | 标准桌面 |
| 2560x1440 | ~80MB | 高分屏 |
| 1280x720 | ~30MB | 低配 VPS |
| 1024x768 | ~20MB | 极低配 VPS |

---

## 🆘 快速故障排除

| 问题 | 快速检查 | 解决方案 |
|------|---------|---------|
| 连不上 VNC | `docker logs dwc_desk \| grep vnc` | 检查防火墙 + 重启 VNC |
| SSH 连接超时 | `docker ps` 查看容器状态 | 容器未运行则 `make run IMG=desk` |
| 中文显示乱码 | `echo $LANG` | 设置 `LANG=zh_CN.UTF-8` |
| 容器退出 | `docker logs dwc_desk` | 查看错误日志，通常是进程崩溃 |
| 磁盘满 | `df -h` | 清理 docker 镜像 `docker system prune -a` |

完整排障 → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**最后更新**：2026-08-11
