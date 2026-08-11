# dwc - 无特权云工作站蓝图

## 一、项目概述

### 1.1 定位与背景
- **定位**：无特权云工作站完整解决方案
- **缘起**：一台高性能 VPS，把桌面跑在服务器上，随处远程访问，同时直连国外
- **现状**：蓝图阶段，所有镜像均为规划（代码仅示意，无需构建验证）
- **宿主机适配**：基于 Alpine / Debian slim / Kali 精简构建，支持 IPv6-only 网络，适配极低配 VPS（1c1g10g）

### 1.2 核心设计原则
- **本集群不支持复用镜像**：每个容器独立构建，不 FROM 其他自定义镜像（也因此砍掉 base）
- **无特权运行**：所有容器支持非特权运行（fallback），常规容器统一使用 dropbear 作为轻量 SSH 服务；**jump 端口转发容器使用 openssh-server**（dropbear 不支持端口转发）
- **数据持久化**：统一挂载 `/config` 目录
- **用户管理**：普通用户 `qwe:toor`（sudo）+ root `root:toor`，默认密码 root/toor、qwe/toor
- **安装机制**：外部 `scripts/install-*.sh` 脚本，Dockerfile 仅负责基础环境
- **桌面统一**：日用桌面型统一 XFCE4，功能型统一 IceWM
- **本地化**：默认英文环境，确保中文字体正常显示（Kali 桌面为中文主力，VNC 传输中文最稳定）
- **远程访问策略**：VNC/noVNC 全桌面型标配；**NoMachine / Anydesk / xrdp 仅装进完整版 Kali 系列（full、studio）**，其余镜像保持轻量

### 1.3 命名规范（功能直白型）
简短英文单词，直述用途：

- **桌面型**：desk、full、lite、lite-ice、asbru、studio、py
- **功能型**：browser、jump、chat、code、build、vm、tor
- **已砍**：base、console、proxy

### 1.4 镜像风格参考
- **桌面型 / 单应用功能型**：借鉴 linuxserver.io 单应用容器模式（PUID/PGID 用户映射、`/config` 持久化、s6 或 supervisord init）
- **Kali 桌面**：借鉴 kmille36 的 NoMachine + Kali 做法、hackerschoice/segfault 的模块化结构
- **单应用参考**：vscode（linuxserver/docker-code-server）、无头 chromium（linuxserver/docker-chromium）、pidgin（linuxserver/docker-pidgin）、tor、HexChat

---

## 二、镜像清单（14 个）

### 2.1 桌面型（7 个）

| 镜像 | 基底 | 用途 | 远程访问 |
|------|------|------|----------|
| `desk` | Kali | 中文桌面主力（起点镜像） | VNC / noVNC |
| `full` | Kali | 完整版（无音乐，朋友定制） | VNC / noVNC + **NoMachine + Anydesk + xrdp** |
| `lite` | Debian slim | 极低配桌面（xfce4） | VNC / noVNC |
| `lite-ice` | Debian slim | 极低配桌面（icewm） | VNC / noVNC |
| `asbru` | Debian 11 slim | asbru-cm 专用 | VNC / noVNC |
| `studio` | Kali | 音乐工作站 | VNC / noVNC + **NoMachine + Anydesk + xrdp + 音频** |
| `py` | Debian slim | Python 环境 | VNC / noVNC |

#### desk（Kali 精简桌面）
- 精简 Kali：xfce4 相关组件 + Kali 主题 + Chrome + Terminator + RealVNC Client（`--no-install-recommends` 最小化安装），后补回 gnome 解压缩与任务管理器
- 选择 Kali 的原因：Kali 的 VNC 传输中文最稳定；自用版保持纯 VNC
- 中文支持：ttf-wqy-microhei / noto CJK + ibus-rime

#### full（Kali 完整版，无音乐）
- 朋友定制版：Kali 完整桌面但不带音乐软件
- 唯一"重"镜像：预装 NoMachine / Anydesk / xrdp / Google Chrome

#### lite / lite-ice（Debian 极低配桌面）
- Kali 最简安装对部分设备仍太大，改 Debian slim 最简版
- lite 用 XFCE4，lite-ice 用 IceWM

#### asbru（Debian 11 + asbru-cm）
- asbru-cm 只能在 Debian 11 运行，单开容器

#### studio（Kali 音乐工作站）
- Synthesizer V Studio + OBS + VLC + ffmpeg + rosegarden
- 预装 NoMachine / Anydesk / xrdp，**音频走 xrdp-pulseaudio / NoMachine**（VNC 不能传声音）

#### py（Debian slim + Python）
- Debian 塞 Python 后正常安装 xfce 桌面

### 2.2 功能型（7 个）

| 镜像 | 基底 | 用途 | 远程访问 |
|------|------|------|----------|
| `browser` | Alpine | 无头 chromium 浏览器隔离 | 无桌面 |
| `jump` | Alpine | SSH 端口转发 | 无桌面 |
| `chat` | Alpine | pidgin + HexChat（icewm） | VNC / noVNC（轻量） |
| `code` | Debian slim | vscode 网页版 | 浏览器访问 |
| `build` | Debian slim | Docker CLI 构建 | 无桌面 |
| `vm` | Debian slim | QEMU 虚拟机（未实现，仅预装 qemu 二进制）| Web/串口 |
| `tor` | Alpine | Tor 匿名上网 | 无桌面 |

#### browser（浏览器隔离）
- 无头 chromium（参考 linuxserver/docker-chromium），上 onion 需确保安全，浏览器单独容器，防被黑影响其他服务

#### jump（SSH 端口转发）
- 部分环境只开一个端口，专门跑 **openssh-server** 做端口转发（dropbear 不支持端口转发，故用 openssh-server）
- 启用 `AllowTcpForwarding yes` 支持 `-L/-R` 隧道

#### chat（聊天通信）
- Pidgin + HexChat（参考 linuxserver/docker-pidgin），IceWM，轻量 VNC 可选

#### code（vscode 网页版）
- 容器重置数据不丢，参考 linuxserver/docker-code-server，浏览器访问

#### build（Docker CLI 构建）
- 构建要连宿主 docker，避免宿主环境变脏，带 docker cli 的独立容器

#### vm（QEMU 虚拟机，待实现）
- dockur/windows 不自由、不能随时改配置，做类 VMware 热插拔可改配置方案

#### tor（Tor 匿名上网）
- Tor 客户端 + 代理，支持 .onion 访问，防 DNS 泄漏，高匿名上网

### 2.3 已砍

| 镜像 | 原定位 | 砍因 |
|------|--------|------|
| `base` | Alpine 极简基础镜像 | 集群不复用镜像，无用 |
| `console` | WebConsole（Next.js）集群管理 | 控制台整体砍掉 |
| `proxy` | v2raya 代理容器 | 暂时不需要，代理服务后续单独想办法 |

---

## 三、技术规范

### 3.1 进程管理
- supervisord / s6 作为 init 进程，轻量级多进程管理（无特权容器不依赖 systemd）

### 3.2 功能开关控制（容器内）
- **环境变量注入**：`docker update --env` 动态修改容器环境变量
- **进程热重载**：应用监听环境变化（SIGHUP）实现配置热更新
- **Supervisor 控制**：`supervisorctl` 启停特定进程组

```bash
ENABLE_SSH=true
SSH_PORT=2222
supervisorctl start dropbear
supervisorctl stop dropbear
```

### 3.3 环境变量配置

| 类别 | 环境变量 |
|------|----------|
| 基础配置 | LANG, TZ, DEBUG |
| SSH 相关 | ENABLE_SSH, SSH_PORT, ALLOW_PASSWORD |
| VNC 相关 | ENABLE_VNC, VNC_GEOMETRY, VNC_DEPTH, VNC_PASSWORD |
| NoMachine 相关 | NOMACHINE_USER, NOMACHINE_PASSWORD（仅 full/studio） |
| 应用特定 | 各镜像自定义 |

### 3.4 镜像构建优化
- RUN 链式命令减少层级
- apt 清理（删除缓存、自动安装推荐包）
- 移除不必要的文档和 man 手册
- `--no-install-recommends` 最小化安装

### 3.5 Shell 环境统一
- 所有镜像（Kali 除外）使用统一 `/etc/skel` 模板
- Kali 保留原生 shell 配置
- 仓库现有 `skel/.bashrc`、`skel/.profile` 即该机制模板基础
- 模板无外部依赖，Kali 以外所有 bash 默认加载

### 3.6 默认配置参数

| 配置项 | 默认值 |
|--------|--------|
| VNC 密码 | 114514 |
| VNC 分辨率 | 1920×1200×24 |
| Kali 默认 Shell | zsh |
| Kali 安全设置 | RA2_256 |
| xrdp 端口 | 3389 |
| NoMachine 端口 | 4000 |
| Anydesk 端口 | 7070 |

---

## 四、核心亮点

1. **无特权架构**：dropbear SSH + `/config` 持久化，安全容器环境；jump 端口转发容器改用 openssh-server
2. **极致轻量化**：全系最小化安装，适配 1c1g10g 低配 VPS
3. **中文桌面主力**：Kali VNC 传输中文最稳定，专为中文使用优化
4. **多媒体工作站**：Synthesizer V Studio + OBS + VLC + ffmpeg，走 xrdp-pulseaudio / NoMachine 传声音
5. **远程访问分级**：VNC 标配，NoMachine/Anydesk/xrdp 仅装进完整版 Kali 系列（full/studio），其余镜像保持轻量
6. **功能型 IceWM 统一**：聊天等轻量容器统一 IceWM
7. **匿名上网**：Tor 高匿名，支持 .onion 访问，适配 IPv6-only
8. **隔离安全**：浏览器、聊天均独立容器，防被黑影响其他服务
9. **构建隔离**：build 容器连宿主 docker，宿主环境保持干净
10. **环境一致性**：统一 skel，跨发行版一致（Kali 除外）

---

## 五、匿名上网方案（Tor）

### 5.1 tor 容器
- Tor 客户端 + 代理，自动路由，支持 .onion
- 隔离网络连接、防 DNS 泄漏、多层加密转发
- 配合 browser 容器（无头 chromium）确保访问安全

### 5.2 注意事项
- 遵守当地法律法规，合法使用 Tor 网络
- 定期更新 Tor 版本、妥善保管 onion 配置
- 配合防火墙规则增强安全性

---

## 六、远程访问方案矩阵

| 方案 | 适用镜像 | 说明 |
|------|----------|------|
| **VNC / noVNC** | 全部桌面型（desk/full/lite/lite-ice/asbru/studio/py）+ chat | 浏览器访问，零客户端，中文稳定 |
| **xrdp** | 仅 full、studio | 微软 RDP 客户端直连；studio 需装 xrdp-pulseaudio 模块传声音 |
| **NoMachine** | 仅 full、studio | 客户端免费闭源，音频好；kmille36 方案 |
| **Anydesk** | 仅 full、studio | 容器内需 X 会话，社区方案少，注意坑 |
| **WebUI** | code | 纯浏览器管理，无桌面 |

---

## 七、镜像尺寸汇总（粗估）

| 镜像 | 约大小 | 主要用途 |
|------|--------|---------|
| desk | ~700MB | 中文桌面主力 |
| full | ~1200MB | 完整桌面（无音乐，含远程桌面） |
| lite / lite-ice | ~500MB | 极低配桌面 |
| asbru | ~500MB | asbru-cm 远程终端 |
| studio | ~900MB | 音乐工作站 |
| py | ~600MB | Python 开发 |
| browser | ~150MB | 无头浏览器隔离 |
| jump | ~50MB | SSH 端口转发 |
| chat | ~150MB | 聊天通信 |
| code | ~400MB | vscode 网页版 |
| build | ~200MB | Docker 构建 |
| vm | ~300MB | QEMU 虚拟机（待实现）|
| tor | ~200MB | 匿名上网 |
