# HISTORY - 项目演进与命名记录

## 一、缘起

- 当时有一台高性能 VPS，想要一个桌面跑在服务器上，随时远程访问，还能直接访问国外
- 使用中发现 segfault 的 guest 服务传输中文有问题，唯独 Kali 的 VNC 传输中文最稳定，因此特意用 Kali 做桌面主力

## 二、演进时间线

1. **desk**：Kali 精简桌面（起点镜像）。`--no-install-recommends` 最小化安装，只装 xfce4 相关组件 + Kali 主题，随后装 Google Chrome、Terminator 终端、RealVNC Client，然后就没别的了。用了一阵子，后来加回 gnome 解压缩和任务管理器
2. **studio**：想玩音乐。Synthesizer V Studio 要装一大堆东西，且 VNC 不能传声音，于是做了音乐工作站版本：synthv + obs + vlc + ffmpeg + anydesk + xrdp + nomachine（不用 Ubuntu，太费硬盘）
3. **lite**：发现 Kali 最简化安装对某些设备还是太大，于是做了 Debian 最简版
4. **full**：朋友想要 Kali 完整版但不带音乐软件，所以一起做了
5. **code**：浏览器里写代码，容器重置数据全丢，专门做了 vscode 容器
6. **browser**：要上 onion 需确保安全，所以做了浏览器隔离专用容器
7. **jump**：部分环境只能开一个端口出去，专门搞了一个容器跑 openssh 做端口转发
8. **build**：构建要连宿主 docker，但那样宿主环境特别脏、编译这个项目很麻烦，所以做了带 docker cli 的容器
9. **py**：一个特别神人的环境，只能 Debian Python 塞进去然后正常安装 xfce 桌面
10. **asbru**：神人软件 asbru-cm 只能在 Debian 11 上跑，又单开了容器
11. **vm**：想开虚拟机，dockur/windows 那个不自由、不能随时改配置，想做一个像 VMware 那样可以热插拔改配置的东西
12. **chat**：专门装 Pidgin 聊天的容器，装的是 icewm

## 三、桌面风格约定

- 日用桌面型统一 XFCE4
- 功能型（chat 等）统一 IceWM

## 四、命名变更记录（旧 → 新）

### 桌面型

| 新名 | 旧名 |
|------|------|
| `desk` | kali-rolling-xfce4 |
| `full` | kali-full-xfce4 |
| `lite` | debian-unstable-xfce4 |
| `lite-ice` | debian-unstable-icewm |
| `asbru` | debian11-xfce4-tightvnc |
| `studio` | media-synthv-studio |
| `py` | deepnote-py313 |

### 功能型

| 新名 | 旧名 |
|------|------|
| `browser` | alpine-chromium |
| `jump` | （新增）openssh 端口转发容器 |
| `chat` | alpine-privacy-comm（Pidgin/HexChat，合并） |
| `code` | alpine-devcontainer |
| `build` | alpine-builder |
| `vm` | alpine-qemu-tools |
| `tor` | alpine-tor-browser |

### 已砍

| 新名 | 旧名 | 砍因 |
|------|------|------|
| `base` | alpine-base | 集群不复用镜像，无用 |
| `console` | web-console-nextjs | 控制台整体砍掉 |
| `proxy` | alpine-v2raya-lite | 暂时不需要，代理服务后续单独想办法 |

## 五、原则变更

- **不支持复用镜像**：每个容器独立构建，不 FROM 其他自定义镜像（因此砍掉 base）
- 控制台 WebConsole（功能开关式集群管理）取消，功能开关改由容器内环境变量 + supervisorctl 实现
- **远程访问分级**：VNC/noVNC 全桌面型标配；NoMachine / Anydesk / xrdp 仅装进完整版 Kali 系列（full、studio），其余镜像保持轻量
- **风格参考澄清**：linuxserver 参考的是其**单应用容器**（code-server、无头 chromium、pidgin、HexChat 等），不是 webtop 桌面项目
- **换源与代理容器砍掉**：软件源换源机制与 proxy（v2raya）容器移除，不再内置；如需要代理服务单独想办法

## 六、参考项目索引

详见 `refs/REFS.md`。核心：

- **infrastlabs/docker-headless**：多桌面 XRDP/noVNC/PulseAudio 架构参考（版本老，只学思路不抄实现）
- **hackerschoice/segfault**：Kali 容器模块化/自动化结构参考
- **kmille36/Docker-Kali-Desktop-NoMachine**：Kali + NoMachine 实现参考（full/studio 用）
- **linuxserver 单应用容器**：code-server / chromium / pidgin 等（code/browser/chat 用）
