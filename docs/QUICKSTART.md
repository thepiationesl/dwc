# 快速开始 - 5 分钟选镜像 + 上手

> 第一次用？按照这份指南 5 分钟选好镜像并跑起来。

## 我应该选哪个镜像？

### 📊 场景速查

```
我想要...                          →  选择这个镜像
├─ 日常办公、上网、编程              → desk（推荐） 或 lite（低配）
├─ 完整 Kali + 远程桌面              → full
├─ 音乐制作、视频处理、直播           → studio
├─ 远程终端（SSH 隧道、Asbru）       → asbru
├─ Python 开发环境                  → py
├─ 代码编辑（浏览器版 VSCode）       → code
├─ 安全浏览 onion 网站               → browser + tor
├─ SSH 端口转发、穿透低配网络        → jump
├─ 聊天通信（Pidgin/HexChat）       → chat
├─ 宿主 docker 容器构建              → build
└─ Tor 代理上网                      → tor
```

---

## 🎯 按需求详细对比

### **场景 1：日常工作站（最常见）**

**选择**：`desk`（推荐首选）

为什么：
- 基于 Kali，VNC 传输中文最稳定
- 预装 Chrome、Terminator、RealVNC Client
- 2024 年一直在用，最稳定
- 镜像约 700MB，中等配置

**替代方案**：
- 如果 VPS 配置超低（<512MB）→ 选 `lite`（Debian slim，500MB）
- 如果已经用 Kali 熟悉 → 选 `full`（完整版，含远程桌面）

**构建 & 运行**：
```bash
make build IMG=desk
make run IMG=desk

# 然后在浏览器打开
http://your-vps-ip:6080

# 或 SSH 进入
ssh qwe@your-vps-ip -p 2222
```

**默认凭证**：
```
VNC：密码 114514
SSH：qwe / toor
```

**配置 PUID/PGID**（让挂载卷权限与宿主一致）：
```bash
docker run -e PUID=$(id -u) -e PGID=$(id -g) -v /data/dwc:/config dwc:desk
```

---

### **场景 2：音乐制作、视频处理**

**选择**：`studio`

为什么：
- 预装 Synthesizer V Studio、OBS、VLC、ffmpeg
- **支持音频转发**（VNC 无法传音，但 xrdp-pulseaudio / NoMachine 可以）
- 镜像约 900MB

**重要**：使用 **xrdp** 或 **NoMachine** 才能听到声音！

```bash
make build IMG=studio
make run IMG=studio

# 用 RDP 客户端连接 your-vps-ip:3389（有声音）
# 或用 NoMachine 客户端连接 your-vps-ip:4000（有声音）
```

**默认凭证**：
```
xrdp/NoMachine：qwe / toor
VNC：密码 114514（无声音）
```

---

### **场景 3：代码编辑（Web 版，容器重置不丢数据）**

**选择**：`code`

为什么：
- VSCode 网页版（code-server），开浏览器即用
- `/config` 持久化，容器删了代码还在
- **支持 `HASHED_PASSWORD`（bcrypt hash），密码不进镜像 layer**
- 镜像约 450MB

```bash
make build IMG=code
make run IMG=code

# 浏览器打开
https://your-vps-ip:8443

# 默认密码 = toor；推荐用 HASHED_PASSWORD（构建时注入更安全）：
docker run -e HASHED_PASSWORD='$2a$10$...' dwc:code
```

---

### **场景 4：安全浏览 onion 网站**

**需要**：`browser` + `tor` 组合

为什么：
- `browser`：无头 chromium，隔离浏览器安全
- `tor`：Tor 代理，匿名上网 + 访问 .onion

```bash
# 分别构建 & 运行
make build IMG=browser
make run IMG=browser

make build IMG=tor
make run IMG=tor

# browser 容器通过环境变量连接 tor 的 SOCKS5
# 详见 TROUBLESHOOTING.md - Tor 配置
```

---

### **场景 5：SSH 隧道转发（低端口限制）**

**选择**：`jump`

为什么：
- 用 openssh-server（dropbear 不支持端口转发 `-L/-R`）
- 用来做 SSH 隧道中转、VPN 替代
- **支持 `/config/ssh/authorized_keys` 公钥登录**
- 镜像超轻量，仅 ~100MB

```bash
make build IMG=jump
make run IMG=jump

# 设置 SSH 隧道（比如转发本地 8080 到内网 192.168.1.100:8080）
ssh qwe@your-vps-ip -p 2222 -L 8080:192.168.1.100:8080 -N
```

**生产建议**：禁用密码登录，只用公钥：
```bash
# 宿主机生成密钥
ssh-keygen -t ed25519 -f ~/.ssh/dwc_jump_key

# 把公钥挂进容器
docker run -p 2222:2222 \
  -v ~/.ssh/dwc_jump_key.pub:/config/ssh/authorized_keys:ro \
  -e ALLOW_PASSWORD=no \
  dwc:jump

# 客户端密钥登录
ssh -i ~/.ssh/dwc_jump_key qwe@your-vps-ip -p 2222
```

---

### **场景 6：宿主 Docker 构建（容器内编译）**

**选择**：`build`

为什么：
- 预装 docker cli，可以连宿主 docker daemon
- 避免在宿主装一堆编译工具搞脏环境
- 镜像约 200MB

```bash
make build IMG=build
make run IMG=build

# 进入容器
docker exec -it dwc_build bash

# 容器内可以用 docker 构建
docker build -t myapp:latest .
docker run myapp:latest
```

**注意**：需要挂载 docker socket
```bash
# Makefile 已配置，或手动：
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name dwc_build dwc:build
```

---

## 🚀 标准流程（5 步）

以 `desk` 为例：

### **步骤 1：克隆仓库**
```bash
git clone git@github.com:thepiationesl/dwc.git
cd dwc
```

### **步骤 2：构建镜像**
```bash
make build IMG=desk

# 首次构建需要 5-15 分钟（取决于网络和 CPU）
# 后续构建会用缓存，快很多
```

### **步骤 3：运行容器**
```bash
make run IMG=desk

# Makefile 会自动映射端口：
#   VNC:   5901（容器内，仅 localhost；noVNC 走 6080）
#   noVNC: 6080（浏览器访问）
#   SSH:   2222（dropbear）
```

### **步骤 4：访问桌面**

**方式 A - 浏览器（推荐新手）**
```
http://your-vps-ip:6080
密码：114514
```

**方式 B - SSH**
```bash
ssh qwe@your-vps-ip -p 2222
# 密码：toor
```

**方式 C - VNC 客户端（RealVNC / TigerVNC）**
```
地址：your-vps-ip:5901
密码：114514
```

> 注意：VNC 端口在 `dwc-xvnc` 里加了 `-localhost`，**VNC 直连会被拒绝**，需要先 SSH 端口转发或走 noVNC。

### **步骤 5：配置与扩展**

进入容器 shell：
```bash
docker exec -it dwc_desk bash

# 安装额外软件
apt update && apt install -y vim htop

# 修改 VNC 密码
vncpasswd

# 查看进程状态
supervisorctl -S /tmp/supervisord.sock status
```

---

## 📦 容器生命周期

### 启动容器
```bash
make run IMG=desk
```

### 停止容器
```bash
docker stop dwc_desk
```

### 重启容器
```bash
docker restart dwc_desk
```

### 删除容器（数据丢失）
```bash
docker rm dwc_desk
```

### 查看日志
```bash
docker logs dwc_desk
docker logs -f dwc_desk        # 实时跟踪
```

### 进入 shell
```bash
docker exec -it dwc_desk bash
```

---

## ⚙️ 常见配置修改

### 修改 VNC 密码

进入容器后：
```bash
vncpasswd          # 交互设置新密码
supervisorctl -S /tmp/supervisord.sock restart vnc
```

### 修改分辨率

```bash
docker exec dwc_desk bash -c 'export VNC_GEOMETRY=2560x1440; supervisorctl -S /tmp/supervisord.sock restart vnc'
```

或重新运行容器时指定：
```bash
docker run -e VNC_GEOMETRY=2560x1440 ...
```

### 启用/禁用 SSH

```bash
docker exec dwc_desk bash -c 'export ENABLE_SSH=true; supervisorctl -S /tmp/supervisord.sock start dropbear'
docker exec dwc_desk bash -c 'export ENABLE_SSH=false; supervisorctl -S /tmp/supervisord.sock stop dropbear'
```

详见 → [REFERENCE.md#环境变量完整参考](../docs/REFERENCE.md#环境变量完整参考)

---

## 🆘 遇到问题？

| 问题 | 排障步骤 |
|------|---------|
| 连不上 VNC | 检查防火墙 + 查看日志 `docker logs dwc_desk` |
| SSH 连接超时 | 确认 SSH 已启用 + 端口映射正确 |
| 镜像构建失败 | 检查网络 + 清理 docker 缓存 `docker system prune` |
| 容器内中文乱码 | 设置 `LANG=zh_CN.UTF-8` 环境变量 |

详见 → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📖 下一步

- 想深入了解架构？ → [ARCHITECTURE.md](ARCHITECTURE.md)
- 需要完整配置参考？ → [REFERENCE.md](REFERENCE.md)
- 生产环境部署？ → [REFERENCE.md#安全建议](REFERENCE.md#安全建议)

---

**提示**：大多数用户选 `desk` 或 `lite`，跑起来试试，有问题再查具体文档。祝用得舒服！🎉

---

**最后更新**：2026-09-04（与代码 4870d39 同步）
