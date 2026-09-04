# 演进记录与命名历史

> 项目从无到有的过程，以及镜像名称的演变。

---

## 一、项目缘起

**背景**：一台高性能 VPS，需要一个桌面跑在服务器上，随时随地远程访问，同时能直接访问国外。

**关键发现**：在使用各类容器方案时，发现 Kali 的 VNC 传输中文最稳定，因此特意用 Kali 作为桌面主力。

---

## 二、镜像演进时间线

### 第 1 阶段：起点（desk）
- **时间**：项目初期
- **镜像**：`desk`（Kali 精简桌面）
- **原因**：日常工作、上网、编程的基础需求
- **方案**：Kali rolling + XFCE4 + Chrome + Terminator + RealVNC Client
- **特点**：`--no-install-recommends` 最小化安装

### 第 2 阶段：音乐工作站（studio）
- **时间**：+3 个月
- **镜像**：`studio`（Kali 音乐工作站）
- **原因**：需要做音乐制作，Synthesizer V Studio 需要一堆依赖，且 VNC 无法传声音
- **方案**：Kali + synthesizer v + obs + vlc + ffmpeg + xrdp-pulseaudio（音频方案）
- **亮点**：解决了远程桌面音频问题（xrdp-pulseaudio / NoMachine）

### 第 3 阶段：低配适配（lite / lite-ice）
- **时间**：+6 个月
- **镜像**：`lite`（XFCE4）、`lite-ice`（IceWM）
- **原因**：发现 Kali 最小化安装对某些低配设备仍太大
- **方案**：改用 Debian slim 做基础，lite 用 XFCE4，lite-ice 用 IceWM
- **效果**：镜像大小从 700MB 降到 500MB 以下

### 第 4 阶段：完整版（full）
- **时间**：+9 个月
- **镜像**：`full`（Kali 完整版，无音乐）
- **原因**：朋友需要 Kali 完整工具集 + 多种远程桌面方案
- **方案**：Kali rolling（无 studio 音乐软件）+ NoMachine + xrdp + Anydesk
- **定位**："重"镜像，功能最全

### 第 5 阶段：代码编辑（code）
- **时间**：+12 个月
- **镜像**：`code`（VSCode 网页版）
- **原因**：浏览器编辑代码，但容器重置后代码全丢，需要持久化
- **方案**：code-server + `/config` 持久化 + HTTPS 8443
- **创新**：容器可以删了，代码还在

### 第 6 阶段：安全隔离（browser）
- **时间**：+15 个月
- **镜像**：`browser`（无头 chromium）
- **原因**：需要上 onion 网站，必须确保浏览器隔离安全
- **方案**：无头 chromium + 可选 X11 转发或 VNC
- **参考**：linuxserver/docker-chromium

### 第 7 阶段：端口转发（jump）
- **时间**：+18 个月
- **镜像**：`jump`（SSH 端口转发）
- **原因**：部分环境只能开一个端口出去，需要 SSH 隧道中转
- **方案**：OpenSSH server（dropbear 不支持端口转发 `-L/-R`）
- **用途**：VPN 替代、内网穿透

### 第 8 阶段：容器内编译（build）
- **时间**：+21 个月
- **镜像**：`build`（Docker CLI 构建）
- **原因**：构建要连宿主 docker，但宿主环境会变脏，特别是编译这个项目很麻烦
- **方案**：Debian slim + docker cli + 挂载 `/var/run/docker.sock`
- **好处**：容器内编译，宿主环境保持干净

### 第 9 阶段：Python 环境（py）
- **时间**：+24 个月
- **镜像**：`py`（Debian slim + Python）
- **原因**：某个特殊环境只能用 Python，需要 Debian + xfce4 桌面
- **方案**：Debian slim + Python 3.13 + pip + virtualenv + XFCE4

### 第 10 阶段：特殊需求（asbru）
- **时间**：+27 个月
- **镜像**：`asbru`（Debian 11 + asbru-cm）
- **原因**：某个神人软件 asbru-cm 只能在 Debian 11 运行
- **方案**：单独开一个 Debian 11 slim 容器 + asbru-cm
- **特点**：用 Tightvnc（Debian 11 原生）

### 第 11 阶段：聊天隔离（chat）
- **时间**：+30 个月
- **镜像**：`chat`（Pidgin + HexChat）
- **原因**：聊天应用单独隔离，防止被黑影响其他服务
- **方案**：Alpine + Pidgin + HexChat + IceWM
- **参考**：linuxserver/docker-pidgin

### 第 12 阶段：匿名上网（tor）
- **时间**：+33 个月
- **镜像**：`tor`（Tor 代理）
- **原因**：需要高匿名上网、访问 .onion，防 DNS 泄漏
- **方案**：Tor 客户端 + SOCKS5 代理（9050）
- **组合**：与 browser 容器组合使用

---

## 三、命名变更记录

### 桌面型镜像

| 当前名 | 旧名 | 变更原因 |
|--------|------|---------|
| `desk` | `kali-rolling-xfce4` | 简化名称，直述用途 |
| `full` | `kali-full-xfce4` | 同上 |
| `lite` | `debian-unstable-xfce4` | 同上 |
| `lite-ice` | `debian-unstable-icewm` | 同上 |
| `asbru` | `debian11-xfce4-tightvnc` | 同上 |
| `studio` | `media-synthv-studio` | 同上 |
| `py` | `deepnote-py313` | 同上 |

### 功能型镜像

| 当前名 | 旧名 | 变更原因 |
|--------|------|---------|
| `browser` | `alpine-chromium` | 简化名称 |
| `jump` | N/A（新增） | 新镜像 |
| `chat` | `alpine-privacy-comm` | 简化名称 |
| `code` | `alpine-devcontainer` | 简化名称 |
| `build` | `alpine-builder` | 简化名称 |
| `tor` | `alpine-tor-browser` | 简化名称 |

### 已砍镜像

| 名称 | 旧名 | 砍掉原因 |
|------|------|---------|
| `base` | `alpine-base` | 集群不复用镜像，无用 |
| `console` | `web-console-nextjs` | WebConsole 整体砍掉，改用环境变量 + supervisorctl |
| `proxy` | `alpine-v2raya-lite` | 暂时不需要，代理服务后续单独想办法 |

---

## 四、关键设计决策

### 决策 1：不复用镜像（no base layer）

**决定**：每个 Dockerfile 独立，不 FROM 其他自定义镜像

**代价**：代码重复（rootfs/ 和 scripts/ 会被多个 Dockerfile COPY）

**收益**：
- 每个镜像可独立版本管理
- 修改一个镜像不影响其他
- 构建依赖清晰
- 易于删除/替换镜像

**初期决策**：曾有 `base` 镜像（alpine-base），后来砍掉了

### 决策 2：无特权运行

**决定**：所有容器都必须支持 `--cap-drop=ALL` 非特权运行

**实现**：
- 用 dropbear 轻量 SSH 替代 sshd
- 用 supervisord 替代 systemd init
- 数据持久化到 `/config` 而非依赖宿主权限

**好处**：
- 更安全（隔离 + 沙箱）
- Cloud-ready（Kubernetes 友好）
- 可多租户部署

### 决策 3：砍掉 WebConsole

**原因**：
- WebConsole（Next.js Web 管理面板）过于复杂
- 维护成本高，功能开关改用环境变量 + supervisorctl 实现

**新方案**：
- `ENABLE_*` 环境变量控制功能开关
- `supervisorctl` 交互式管理进程
- 简单、轻量、易维护

### 决策 4：远程访问分级

**原则**：
- **VNC/noVNC**：所有桌面型标配（轻量、浏览器访问）
- **xrdp/NoMachine/Anydesk**：仅装进 full/studio（完整版）

**原因**：
- 保持其他镜像轻量化
- 复杂远程访问需求统一到 full/studio
- 不浪费低配 VPS 的资源

### 决策 5：换源与代理砍掉

**原因**：
- 软件源换源 + 代理服务维护复杂
- 不是 dwc 的核心功能
- 需要代理时应该单独部署

**新方向**：
- 如需代理，单独部署 v2raya / clash 容器
- dwc 集群专注于工作站本身

---

## 五、参考项目演进

### 核心参考

| 项目 | 参考内容 | 应用 |
|------|---------|------|
| **linuxserver 单应用容器** | PUID/PGID 用户映射、`/config` 持久化、s6/supervisord init | code / browser / chat 等 |
| **infrastlabs/docker-headless** | 多桌面 xrdp/noVNC/PulseAudio 架构 | studio 音频方案 |
| **hackerschoice/segfault** | Kali 容器模块化结构、Makefile 驱动构建 | 脚本复用、构建流程 |
| **kmille36/Docker-Kali-Desktop-NoMachine** | Kali + NoMachine 实现 | full/studio 远程访问 |

### 不采用的原因

| 项目 | 原因 |
|------|------|
| linuxserver/docker-webtop | 依赖 Selkies + Wayland，低配 VPS 不适合（需 AVX2 CPU） |
| dockur/ 虚拟化系列 | 不自由、配置不可热改，vm 已单开仓库重做 |
| docker-dind | 需要特权，与无特权设计冲突 |

---

## 六、重要时刻

### 💡 关键改进

- **2024-11**：参考研究完成（REFS.md），架构定型
- **2024-12**：13 个镜像全部落地并验证
- **2025-08**：文档完整重构（README → QUICKSTART / REFERENCE / ARCHITECTURE / TROUBLESHOOTING）

### 🎯 未来方向

- [ ] Kubernetes 适配（Helm chart）
- [ ] 镜像签名与二进制分发
- [ ] 监控 & 告警集成（Prometheus）
- [ ] 日志聚合（ELK Stack）
- [ ] 更多桌面环境（GNOME / KDE）
- [ ] RustDesk 替代 Anydesk

---

## 七、致谢

感谢以下项目启发与参考：

- **linuxserver.io** - 单应用容器最佳实践
- **infrastlabs/docker-headless** - 多桌面远程访问方案
- **hackerschoice/segfault** - Kali 容器设计思想
- **kmille36** - NoMachine 集成实现
- 以及所有开源社区的贡献者

---

**项目启始**：~2023 年初 | **稳定版本**：2024-12 | **文档重构**：2026-08-11 | **最近迭代**：2026-09-04（YOLO mode 修复与功能补全，commit 4870d39）

---

## 八、最近迭代（2026-09-04 — YOLO 修复与补全）

commit：`4870d39`（SSH 签名，author `thepiationesl`）

#### 修复的真 bug

- Alpine 镜像 build 失败：原 `#!/usr/bin/env bash` 在 alpine ash 下因 bash 未装退出 127。改为 `lib.sh` + `install-base.sh` 用 `/bin/sh`，自装 bash
- Alpine 3.24 包名变更：`supervisord` 不存在，改 `supervisor` 加 fallback
- Kali 包名：`dropbear-run` 不存在，改 `dropbear` 加 fallback
- VNC 不启：`dwc-xvnc` 用了部分 TigerVNC 版本不支持的 `-dontdisconnect`，移除
- dropbear/openssh 2222 端口冲突：`dwc-dropbear` 检测 sshd 存在则跳过；`dropbear.conf` + `openssh.conf` 改 `autorestart=unexpected` 防止 skip 时变 FATAL
- NoMachine 占位 bug：用 `nxserver --daemon` 替代 `tail -f nxserver.log`

#### 功能补全

- **PUID/PGID 支持**：`lib.sh::setup_users` 接 `PUID`/`PGID` env（linuxserver 标准）
- **Kali 中文桌面真的"中文"**：fonts-not-in-cjk + wqy + fcitx5 + rime + chinese-addons + `locale-gen zh_CN.UTF-8` + en_US.UTF-8
- **fcitx5 autostart**：`dwc-xstartup` 检测后启动 fcitx5 daemon + 设 GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS
- **VNC 多客户端 + view-only 旁观密码 + 多容器显示号偏移**：`VNC_PASSWORD_RO` + `-alwaysshared` + `VNC_OFFSET`
- **chromium 镜像带 CDP**：`dwc-chromium` + `chromium.conf` + EXPOSE 9222
- **jump 镜像公钥登录**：`/config/ssh/authorized_keys` 自动注入 qwe 家目录
- **code-server HASHED_PASSWORD + 锁版本 4.103.0**：替换 `curl install.sh` 拉最新版
- **alpine 锁版本 `alpine:3.24`**：防止 `:latest` 漂移

#### 清理

- 删除 `skel/`（13 Dockerfile 去除 `COPY skel/` + `install-base.sh` 去除 `install_skel` 函数）
- 13 Dockerfile 注释同步更新

#### 验证

- `docker build dwc-jump:test` 通过；`docker run` + 同网络容器 SSH 登录成功（`qwe/toor`）
- `docker build --no-cache dwc-desk:test` 通过（Kali + xfce4 + chrome + fcitx5）
- 端到端 SSH 测试：qwe 用户登录、PUID/PGID=1000、sudo 组、Kali banner、`fcitx5 --version=5.1.21`、`locale -a` 显示 `zh_CN.utf8`/`en_US.utf8`
- VNC 5901 / noVNC 6080 / SSH 2222 三端口监听中
