# REFS - 参考项目研究笔记

> 用途：dwc 各镜像脚本落笔前的参考对照清单，避免踩老版本 / 过时方案的坑。
> 更新日期：2026-09-04（与代码 4870d39 同步；PUID/PGID、fcitx5、chromium CDP 等 linuxserver 模式已落地）

## 〇、远程访问分级原则（重要）

**NoMachine / Anydesk / xrdp 只装进完整版 Kali 系列（full、studio）**，其余镜像仅 VNC/noVNC 或纯 Web 访问，保持轻量。

## 〇·二、已砍模块（不再调研）

- **proxy（v2raya）**：代理容器暂时砍掉，如需要代理服务单独想办法。
- **软件源换源机制**：不再内置 apt.sh 换源方案。

## 一、linuxserver 单应用容器（重点，已参考）

> 注意：参考的是 linuxserver 的**单应用容器**模式，不是 webtop 桌面项目。

| 项目 | 对应 dwc 镜像 | 说明 |
|------|--------------|------|
| linuxserver/docker-code-server | `code` | VS Code 网页版，`/config` 持久化 + PUID/PGID |
| linuxserver/docker-openvscode-server | `code` | openvscode-server 变体 |
| linuxserver/docker-chromium | `browser` | 无头/远程 chromium |
| linuxserver/docker-pidgin | `chat` | Pidgin 聊天 |
| (HexChat / tor 单应用) | `chat` / `tor` | 同类单应用容器思路 |

**linuxserver 通用模式（已实现部分）**：

- PUID/PGID 用户映射 ✅（`lib.sh::setup_users`，默认 1000）
- `/config` 持久化 ✅
- s6-overlay 作为 init ❌（dwc 用 supervisord；REFS.md §〇 已记录此设计取舍）
- 环境变量开关功能（ENABLE_*） ✅
- 容器为单一应用服务 + DOCKER_MODS 扩展 ❌（dwc 故意"重"镜像，独立 per-image 配置）

## 二、核心参考（直接学习实现）

### 1. infrastlabs/docker-headless（重点，已参考）

- 仓库：https://github.com/infrastlabs/docker-headless （71 stars，2024-11 停更）
- 定位：多桌面远程工作站（XRDP + noVNC + PulseAudio），Ubuntu/Mint/Debian/Alpine/openSUSE 多发行版 tag
- **架构设计值得抄**：
  - `slim > base > 各桌面` 的镜像分层（不违反「不复用镜像」原则，可照抄思路用 COPY 共享脚本）
  - 端口约定：noVNC 6080→10081、xrdp 3389→10089、sshd 22→10022
  - `VNC_OFFSET=10` 机制：xrdp 通过 `vncpasswd` 生成 `/etc/xrdp/vnc_pass`，VNC 显示号偏移
  - 输入法：ibus-rime（中文）/ fcitx-sogou，字体 ttf-wqy-microhei
  - init 三选：supervisor / systemd / perp
  - 环境变量：SSH_PASS、VNC_PASS、VNC_PASS_RO、VNC_SSL_ONLY、L、TZ
- **坑（版本老，别照抄）**：
  - 基础是 Ubuntu20.04 / Debian9，xrdp 0.9.16 太老
  - 提供 `docker-dind`，需要特权，与无特权设计冲突

### 2. hackerschoice/segfault（已参考）

- 仓库：https://github.com/hackerschoice/segfault （437 stars）
- 定位：服务器中心部署（SSC），给用户提供 root 容器（Kali 系）
- **值得学**：
  - `provision/` 自动化部署流程
  - `config/etc/sf/sf.conf` 集中配置 + 每服务器 `limits.conf` 覆写
  - Makefile 驱动整站构建（`make` 后 `sfbin/sf up`）
  - gsnc / encfsd / tor / wgvpn 等模块化目录
- 注：这是「服务器中心」，不是单容器镜像，学习其模块化与自动化结构即可

### 3. kmille36/Docker-Kali-Desktop-NoMachine（与 full/studio 场景最贴近）

- 仓库：https://github.com/kmille36/Docker-Kali-Desktop-NoMachine （27 stars，2023 停更）
- 定位：Kali XFCE4 + NoMachine + firefox/chrome
- **关键实现**：`nomachine-xfce4.sh` 脚本化构建，NoMachine 官网 .deb 下载安装，`USER`/`PASSWORD` 环境变量控制登录
- 同作者还有 Ubuntu 版：kmille36/Docker-Ubuntu-Desktop-NoMachine （120 stars）

### 4. linuxserver/docker-webtop（趋势参考，不直接采用）

- 仓库：https://github.com/linuxserver/docker-webtop （4.3k stars，2026 活跃）
- 定位：浏览器内完整桌面（XFCE/KDE/i3/MATE × 多发行版）
- **重要趋势**：已从 KasmVNC 迁移到 **Selkies**，默认 **Wayland**；但 x86_64 需 AVX2，低配 VPS 不适合，仅作趋势了解

## 三、远程访问方案横向对比

| 方案 | 音频 | 中文 | 代表项目 | 备注 |
|------|------|------|---------|------|
| **xrdp** | 需 pulseaudio 模块（xrdp-pulseaudio） | 中文字体需自行装 | infrastlabs、hectorm/docker-xubuntu、scottyhardy/docker-remote-desktop | 微软 RDP 客户端直连，低配友好 |
| **noVNC** | 需 websockify+broadcast | 同 xrdp | ConSol/docker-headless-vnc-container(2k stars)、accetto/ubuntu-vnc-xfce-g3(321)、x11vnc | 浏览器访问，零客户端 |
| **KasmVNC** | 较好 | - | linuxserver/docker-baseimage-kasmvnc(568)、gezp/docker-ubuntu-desktop(509) | 介于 VNC 与现代化之间 |
| **Selkies** | 好（WebCodecs） | - | linuxserver/webtop（现用） | 最新，需 HTTPS + 新 CPU |
| **NoMachine** | 好 | 好 | kmille36 系列、gezp 附带 | 客户端免费闭源，支持音频；容器内需装 .deb 并配置 NX 服务 |
| **Anydesk** | 一般 | 好 | Mgodoyd/Docker-GUI-ANYDESK-VNC、alireaza/anydesk | 容器内跑 Anydesk 需 X 会话 + systemd 类 init，社区方案少且质量参差 |
| **RustDesk** | 好 | 好 | Lanjelin/docker-remote-desktop、andrey15054/RustDeskDocker | 开源可自建服务端，可作 Anydesk 替代 |

## 四、各参考项目要点

### 桌面类

- **gezp/docker-ubuntu-desktop**（509 stars）：Ubuntu 桌面 + KasmVNC + NoMachine + NVIDIA GPU + VirtualGL，SSH/远程桌面访问，「像云 VM」
- **scottyhardy/docker-remote-desktop**（343 stars）：远程桌面 + **音频支持**，重点看它的 X 会话/声音处理
- **hectorm/docker-xubuntu**（99 stars）：Xfce + VirtualGL + xrdp + **xrdp-pulseaudio 模块**（音频关键）
- **mscrnt/ubuntu-desktop-docker**：Ubuntu24.04 XFCE，**systemd PID1**，VNC+xrdp+SSH，可选 NoMachine + NVIDIA，cgroup v2 无特权（与无特权要求一致）
- **ConSol/docker-headless-vnc-container**（2k stars）：headless VNC 经典方案，长期维护
- **accetto/ubuntu-vnc-xfce-g3**（321 stars）：持续更新到 2026，Ubuntu/Xfce VNC/noVNC
- **lonetis/kali-docker**（84 stars）、**lukaszlach/kali-desktop**（142 stars）：Kali 桌面 VNC 参考

### 开发/工具类（对照 code/build/jump）

- **linuxserver/docker-code-server**（2k stars）：VS Code 网页版，`/config` 持久化 + PUID/PGID
- **ConSol/docker-headless-vnc-container**：内含开发 flavours

### 虚拟化类（vm 已移出本仓库，单开仓库重做；以下为当时调研存档）

- **dockur/** 系列：QEMU/KVM 虚拟机容器（windows/macos/linux），不自由、配置不可热改 —— 正是想避开的
- 替代方向：QEMU + websockify 的 web 控制台，或 webvirtmgr-docker（老）

## 五、给 dwc 脚本的关键建议

1. **远程访问分级**：NoMachine / Anydesk / xrdp 只进 full/studio；其余桌面仅 VNC/noVNC
2. **xrdp 必须装 pulseaudio 模块**，否则没声音（对应 studio「VNC 不能传声音」痛点）—— 参考 hectorm/docker-xubuntu、scottyhardy/docker-remote-desktop
3. **Kali 中文显示**：装 ttf-wqy-microhei / noto CJK + ibus-rime/fcitx，参考 infrastlabs 做法
4. **NoMachine**：直接参考 kmille36 的 .deb 下载 + 服务配置方式，`USER`/`PASSWORD` 环境变量注入（仅 full/studio）
5. **Anydesk 在容器里最难**（依赖 systemd 类会话），社区没有高质量方案 —— 建议优先用 RustDesk/NoMachine 替代
6. **init**：无特权容器优先 supervisord（Kali 系）/ perp（Alpine 系）/ s6（linuxserver 系），systemd 需要特权
7. **版本红线**：不要抄 infrastlabs 的 xrdp 0.9.16；用各发行版仓库最新 xrdp（Debian12/Kali 自带 0.10+）
8. **避免照抄但值得参考的过时项目**：kmille36（2023）、infrastlabs（2024，基于 20.04）、hectorm（老）

## 六、待补调研（后续脚本落到哪个模块再深挖）

- [x] tor + 浏览器隔离：参考 browser 容器方案的网络安全细节（`browser` 镜像已支持 headless + remote-debugging；tor 走 SOCKS5 配合 HTTP_PROXY 使用）
- [x] ~~QEMU 热插拔方案~~：vm 已移出本仓库，单开仓库重做，调研随之迁移（见虚拟化类存档）
- [ ] rustdesk 自建服务端（如替代 Anydesk）：**待跟进**，社区方案（`andrey15054/RustDeskDocker`、`Lanjelin/docker-remote-desktop`）评估中
