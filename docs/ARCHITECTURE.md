# 架构与设计 - 完整蓝图

> 开发者和架构师必读：设计原则、技术规范、镜像详情、演进历史。

---

## 一、项目概述

### 1.1 定位与背景

**定位**：无特权云工作站完整解决方案

**缘起**：
- 一台高性能 VPS，把桌面跑在服务器上，随处远程访问，同时直连国外
- 基于 Alpine / Debian slim / Kali 精简构建，支持 IPv6-only 网络
- 适配极低配 VPS（1c1g10g），成熟稳定，已落地 13 个镜像

**核心价值**：
- 每个容器独立构建，单职责，互不依赖
- 无特权运行，安全隔离
- 支持动态功能开关，灵活配置

---

## 二、核心设计原则

### 2.1 架构设计

| 原则 | 说明 | 影响 |
|------|------|------|
| **单职责** | 每个镜像只做一件事 | 不复用镜像，无 base 层 |
| **独立构建** | Dockerfile 完全独立 | 易于维护、版本管理 |
| **无特权** | 所有容器支持非特权运行 | 更安全、cloud-ready |
| **持久化** | 统一 `/config` 挂载点 | 容器重置不丢数据 |
| **进程隔离** | supervisord 多进程管理 | 轻量级、可热启停 |

### 2.2 用户与权限

```
用户体系：
├─ qwe:1000 (PUID:PGID=1000:1000)  ← 日常使用（sudoer）
└─ root:0                          ← 系统管理（仅容器内）

登录凭证（生产需改！）：
├─ SSH/desktop：qwe/toor 或 root/toor
├─ VNC：密码 114514
├─ xrdp/NoMachine：用户名密码
└─ code-server：token（查 logs）
```

### 2.3 数据持久化策略

```
/config/
├─ .ssh/              ← SSH 密钥（容器重置保留）
├─ .vnc/              ← VNC 配置（密码、证书）
├─ .config/           ← 用户配置文件
├─ workspace/         ← 工作目录（代码、文档）
└─ ...                ← 应用数据
```

**优势**：
- 容器删了数据还在
- 快速恢复：重新 run 后 mount 同一 `/config` 即可
- 易于备份：`docker cp dwc_desk:/config /backup`

### 2.4 进程管理模式

| 镜像类型 | Init 系统 | 说明 |
|----------|----------|------|
| 桌面型 + 功能型 | supervisord | 轻量级多进程管理（无特权友好） |
| Alpine 轻量型 | supervisord | 同上 |
| Kali / Debian | supervisord | 同上 |

**supervisord 的角色**：
- 管理 VNC、SSH、xrdp、NoMachine 等多个进程
- 支持 `ENABLE_*` 环境变量动态启停
- 进程崩溃自动重启
- 支持 `supervisorctl` 交互式控制

---

## 三、技术规范

### 3.1 Dockerfile 编写规范

#### 通用结构（参考样板）

```dockerfile
FROM debian:12-slim

# 1. 基础环境
RUN apt update && apt install -y --no-install-recommends \
    supervisor dropbear-bin curl wget \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# 2. 创建用户
RUN useradd -m -s /bin/bash -u 1000 qwe && \
    echo "qwe:toor" | chpasswd && \
    usermod -aG sudo qwe && \
    echo "root:toor" | chpasswd

# 3. COPY 脚本与配置
COPY rootfs/ /
COPY scripts/install-desktop.sh /tmp/
RUN bash /tmp/install-desktop.sh && rm /tmp/install-desktop.sh

# 4. 初始化目录
RUN mkdir -p /config && chown qwe:qwe /config

# 5. 启动
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
```

#### 关键规范

- **最小化安装**：`--no-install-recommends` 减少镜像大小
- **RUN 链式**：合并命令减少层级
- **清理缓存**：`rm -rf /var/lib/apt/lists/* /var/cache/apt/*`
- **COPY 顺序**：脚本 → 配置 → 应用（便于缓存利用）
- **用户映射**：`PUID:PGID` 恒为 `1000:1000`

### 3.2 环境变量与功能开关

#### 全局环境变量

```bash
# /etc/profile.d/dwc-env.sh 自动加载
export LANG=${LANG:-en_US.UTF-8}
export TZ=${TZ:-UTC}
export DEBUG=${DEBUG:-0}
export PUID=${PUID:-1000}
export PGID=${PGID:-1000}
```

#### 服务开关机制

```bash
# supervisord 配置示例
[program:vnc]
command=/usr/local/bin/dwc-if ENABLE_VNC /usr/bin/vncserver ...
autorestart=true

# dwc-if 脚本逻辑
#!/bin/bash
ENABLE_VAR=$1
if [ "$ENABLE_VAR" = "true" ] || [ "$ENABLE_VAR" = "1" ]; then
    shift
    exec "$@"  # 执行服务
else
    sleep infinity  # 禁用则永久休眠
fi
```

**工作流**：
1. 环境变量注入（docker run -e / docker update --env）
2. supervisord 启动时读取
3. dwc-if wrapper 检查 ENABLE_* 决定是否启动
4. 可以通过 supervisorctl 动态启停

### 3.3 Shell 环境统一

#### 模板机制（skel/）

```
skel/
├─ .bashrc       ← 通用 bash 配置
├─ .profile      ← 通用 shell 初始化
└─ README        ← 说明
```

**应用方式**：
```dockerfile
RUN cp -r /etc/skel/* /home/qwe/
RUN chown -R qwe:qwe /home/qwe
```

**例外**：Kali 保留原生 shell 配置（已集成 zsh + 主题）

### 3.4 安装脚本复用（scripts/）

```
scripts/
├─ common/
│   └─ lib.sh              ← 通用函数库
├─ install-desktop.sh      ← xfce4 桌面
├─ install-icewm.sh        ← icewm 桌面
├─ install-vnc.sh          ← VNC 服务
├─ install-ssh.sh          ← SSH 服务
├─ install-xrdp.sh         ← xrdp 服务
└─ ...
```

**原则**：
- 脚本可被多个 Dockerfile COPY 调用
- 脚本内容幂等（重复运行结果一致）
- 脚本完成后自删（减少镜像大小）

---

## 四、镜像详情（13 个）

### 4.1 桌面型（7 个）

#### desk（Kali 精简桌面）- ⭐ 推荐首选

**用途**：日常工作、上网、编程

**基底**：Kali rolling

**预装软件**：
- 桌面：XFCE4 + Kali 主题
- 浏览器：Google Chrome
- 终端：Terminator
- 工具：RealVNC Client、GNOME 解压缩、任务管理器
- 中文：ttf-wqy-microhei + ibus-rime

**远程访问**：
- VNC/noVNC（6080）← 中文最稳定
- SSH（10022）

**镜像大小**：~700MB

**使用建议**：
- 首次用户从这个开始
- 已经过一年以上生产验证
- 稳定性最高

#### full（Kali 完整版，无音乐）

**用途**：完整 Kali 环境 + 多种远程桌面

**基底**：Kali rolling

**与 desk 的区别**：
- 包含完整 Kali 工具集
- 没有音乐软件（Synthesizer V 等）
- 预装 NoMachine、xrdp、Anydesk

**远程访问**：
- VNC/noVNC（6080）
- xrdp（10089）← RDP 客户端，有声音（需 xrdp-pulseaudio）
- NoMachine（4000）← 有声音
- Anydesk（7070）← 动态端口
- SSH（10022）

**镜像大小**：~1200MB

**使用场景**：
- 朋友定制版，Kali 完整但不要音乐工作站
- 需要多种远程桌面方案

#### lite（Debian slim 极低配桌面 - XFCE）

**用途**：低配 VPS 日常工作

**基底**：Debian 12 slim

**特点**：
- 最小化 Kali 对部分设备仍太大，改用 Debian
- XFCE4 + 必要工具
- 无 Kali 主题，原生 Debian 风格

**远程访问**：
- VNC/noVNC（6080）
- SSH（10022）

**镜像大小**：~500MB

#### lite-ice（Debian slim 极低配桌面 - IceWM）

**用途**：超低配 VPS，或偏好极简 WM

**基底**：Debian 12 slim

**特点**：
- IceWM 窗口管理器，比 XFCE4 更轻
- 内存占用极低（<100MB）

**远程访问**：
- VNC/noVNC（6080）（Xvfb + x11vnc）
- SSH（10022）

**镜像大小**：~480MB

#### asbru（Debian 11 + asbru-cm）

**用途**：asbru-cm 远程终端管理工具

**基底**：Debian 11 slim（asbru-cm 只能在 Debian 11）

**特点**：
- XFCE4 桌面
- asbru-cm 预装（SSH 终端管理）
- Tightvnc（Debian 11 原生）

**远程访问**：
- VNC/noVNC（6080）
- SSH（10022）

**镜像大小**：~520MB

#### studio（Kali 音乐工作站）

**用途**：音乐制作、视频处理、直播

**基底**：Kali rolling

**预装软件**：
- 音乐：Synthesizer V Studio、rosegarden
- 视频：OBS、VLC、ffmpeg
- 中文：同 desk
- 远程访问：xrdp + xrdp-pulseaudio、NoMachine、Anydesk

**音频方案**：
- VNC：无声音（VNC 协议不支持音频）
- xrdp + xrdp-pulseaudio：有声音 ✓
- NoMachine：有声音 ✓
- Anydesk：有声音 ✓

**远程访问**：
- VNC/noVNC（6080，无声音）
- xrdp（10089，**有声音**）← 推荐用于音乐工作
- NoMachine（4000，**有声音**）
- Anydesk（7070，**有声音**）
- SSH（10022）

**镜像大小**：~900MB

**使用建议**：
- 做音乐/视频必须用 xrdp 或 NoMachine，VNC 听不到声音
- xrdp 需要 Windows RDP 客户端
- NoMachine 需要 NoMachine 客户端（免费）

#### py（Debian slim + Python）

**用途**：Python 开发、数据科学

**基底**：Debian 12 slim

**特点**：
- XFCE4 桌面
- Python 3.13 + pip + virtualenv
- Jupyter Notebook（可选）

**远程访问**：
- VNC/noVNC（6080）
- SSH（10022）

**镜像大小**：~600MB

### 4.2 功能型（6 个）

#### browser（无头 chromium 浏览器隔离）

**用途**：安全浏览，特别是 onion 网站

**基底**：Alpine

**特点**：
- 无桌面（无头 chromium）
- 隔离浏览器环境，防被黑影响其他服务
- 可与 tor 容器组合，访问 .onion

**远程访问**：
- SSH（10022）
- 需要 X11 转发或 VNC：`ssh -X ...` 打开图形应用

**镜像大小**：~150MB

**使用例**：
```bash
# 设置 Tor 代理
docker run -e TOR_SOCKS_HOST=dwc_tor -e TOR_SOCKS_PORT=9050 dwc:browser
```

#### jump（SSH 端口转发）

**用途**：SSH 隧道中转、VPN 替代、端口转发

**基底**：Alpine

**特点**：
- OpenSSH server（dropbear 不支持端口转发 `-L/-R`）
- 无桌面
- 启用 `AllowTcpForwarding yes`

**远程访问**：
- SSH（10022，支持 `-L/-R/-D` 端口转发）

**镜像大小**：~50MB（最轻量）

**使用例**：
```bash
# 本地 8080 转发到内网 192.168.1.100:8080
ssh qwe@your-vps-ip -p 10022 -L 8080:192.168.1.100:8080 -N

# 反向转发：宿主 8888 暴露到本地
ssh qwe@your-vps-ip -p 10022 -R 8888:localhost:8888 -N
```

#### chat（Pidgin + HexChat 聊天）

**用途**：聊天通信工具

**基底**：Alpine

**特点**：
- Pidgin（多账号聊天客户端）
- HexChat（IRC 客户端）
- IceWM 轻量窗口管理器
- 轻量 VNC 可选

**远程访问**：
- VNC/noVNC（6080）
- SSH（10022）

**镜像大小**：~150MB

#### code（VSCode 网页版）

**用途**：浏览器内代码编辑，容器重置不丢代码

**基底**：Debian 12 slim

**特点**：
- code-server（VSCode Web 版）
- HTTPS 8443
- `/config` 持久化，容器删了代码还在
- SSH（可选）

**远程访问**：
- HTTPS（8443，浏览器访问）
- SSH（10022）

**镜像大小**：~400MB

**使用例**：
```bash
make run IMG=code
# 浏览器打开 https://your-vps-ip:8443
# 首次访问查看 token：docker logs dwc_code | grep token
```

#### build（Docker CLI 构建）

**用途**：容器内编译、构建镜像，避免宿主环境变脏

**基底**：Debian 12 slim

**特点**：
- 预装 docker cli
- 可连接宿主 docker daemon（挂载 socket）
- 支持构建、推送镜像等操作
- 无图形界面

**远程访问**：
- SSH（10022）
- Docker socket（`/var/run/docker.sock` 挂载）

**镜像大小**：~200MB

**使用例**：
```bash
# Makefile 已配置自动挂载
make run IMG=build
docker exec -it dwc_build bash

# 容器内使用 docker
docker build -t myapp:latest .
docker push myapp:latest
```

#### tor（Tor 匿名上网）

**用途**：Tor 代理，高匿名访问 onion 网站

**基底**：Alpine

**特点**：
- Tor 客户端
- SOCKS5 代理（9050）
- 防 DNS 泄漏
- 支持网桥配置（翻墙）

**远程访问**：
- SOCKS5（9050，其他容器/本地客户端可连）
- SSH（10022）
- 控制端口（9051，仅容器内）

**镜像大小**：~200MB

**使用例**：
```bash
# 与 browser 组合，安全访问 onion
make run IMG=tor
make run IMG=browser

docker exec dwc_browser bash -c \
  'export HTTP_PROXY=socks5://dwc_tor:9050; \
   chromium https://www.example.onion'
```

---

## 五、构建与部署

### 5.1 Makefile 工作流

```makefile
# Makefile 核心逻辑
list:                    # 列出所有镜像
build IMG=<name>:        # 构建
run IMG=<name>:          # 运行（自动映射端口）
clean IMG=<name>:        # 删除镜像

# 构建上下文始终为仓库根
docker build -f images/<IMG>/Dockerfile .
```

### 5.2 构建优化

| 优化项 | 做法 | 效果 |
|--------|------|------|
| 多层缓存 | RUN 链式、按稳定性排序 | 快速增量构建 |
| 镜像大小 | `--no-install-recommends`、清理缓存 | 减少 30-50% |
| 安全扫描 | Dockerfile 最佳实践 | 减少漏洞 |

### 5.3 部署建议

**开发环境**：
```bash
make build IMG=desk
make run IMG=desk
# 修改代码后重新 build & run
```

**生产环境**：
```bash
# 一次性构建所有镜像
make build

# 使用 docker-compose 或 systemd 管理
# 配置防火墙、监控告警、日志聚合

# 定期更新（月度或季度）
git pull
make clean
make build
docker-compose restart
```

---

## 六、演进历史（精简版）

见 `docs/HISTORY.md` 或下面的时间线。

### 主要迭代

| 时间 | 镜像 | 原因 |
|------|------|------|
| 初期 | desk | 日常工作需要，Kali VNC 中文稳定 |
| +3m | studio | 音乐工作需要，加音频支持 |
| +6m | lite | Kali 对某些设备太大，改 Debian |
| +9m | full | 朋友需要完整 Kali + 多远程桌面 |
| +12m | code | 代码编辑需要持久化 |
| +15m | browser | onion 安全隔离需要 |
| +18m | jump | 部分网络限制，需端口转发 |
| +21m | build | 容器内构建需要 |
| +24m | py | Python 开发环境 |
| +27m | asbru | asbru-cm 只能 Debian 11 |
| +30m | chat | 聊天通信隔离 |
| +33m | tor | Tor 匿名代理 |

### 关键决策

1. **不复用镜像**：每个 Dockerfile 独立，虽然代码重复，但便于维护与版本管理
2. **弃用 base 镜像**：初期有 alpine-base，后来砍掉，每个镜像自处理
3. **砍掉 console**：WebConsole 管理复杂，改用环境变量 + supervisorctl
4. **砍掉 proxy（v2raya）**：暂时不需要，代理服务后续单独想办法
5. **远程访问分级**：NoMachine/Anydesk/xrdp 仅装进完整版（full/studio），其余轻量

---

## 七、技术债与未来方向

### 7.1 已知限制

| 限制 | 原因 | 可能方案 |
|------|------|---------|
| Kali 镜像较大 | 默认安装较多工具 | 精简 Kali 源或改用其他发行版 |
| VNC 音频 | VNC 协议不支持 | xrdp-pulseaudio / NoMachine（已实现） |
| Anydesk 不稳定 | 需 systemd 类会话 | 考虑 RustDesk 替代 |
| 弱密码监听公网 | 生产安全隐患 | 必须改默认密码 + 防火墙限制 |

### 7.2 未来改进

- [ ] Kubernetes 适配（Helm chart）
- [ ] 镜像签名与二进制分发
- [ ] 更细粒度的权限控制
- [ ] 监控 & 告警集成（Prometheus）
- [ ] 日志聚合（ELK）
- [ ] 更多桌面环境选项（GNOME / KDE）

---

## 八、参考与引用

- **linuxserver 单应用容器**：code-server / chromium / pidgin（参考了 PUID/PGID + `/config` 模式）
- **infrastlabs/docker-headless**：多桌面 xrdp/noVNC/音频架构（仅学思路，版本太老）
- **hackerschoice/segfault**：Kali 容器模块化结构（参考脚本复用思路）
- **kmille36/Docker-Kali-Desktop-NoMachine**：Kali + NoMachine 实现（直接参考）

详见 → `refs/REFS.md`

---

**最后更新**：2026-08-11 | **版本**：v2.0
