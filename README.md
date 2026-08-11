# dwc - 无特权云工作站容器集群

> 一台 VPS 把桌面跑在服务器上，随处远程访问，直连国外。每个容器独立构建、单用途，互不依赖。

## 快速开始

```bash
git clone git@github.com:thepiationesl/dwc.git
cd dwc

make list              # 列出全部 13 个镜像
make build IMG=desk    # 构建单个镜像（缺省构建全部）
make run   IMG=desk    # 运行（按镜像类型自动映射端口）
make clean IMG=desk    # 删除镜像
```

构建上下文为仓库根：`docker build -f images/<img>/Dockerfile .`，依赖 scripts/、rootfs/、skel/ 均被 COPY 进镜像。

## 目录结构

dwc/
├── Makefile                 # 构建/运行入口（按镜像映射端口）
├── images/<name>/Dockerfile # 每镜像独立 Dockerfile（单职责）
├── rootfs/                  # 覆盖进镜像的文件
│   ├── etc/profile.d/       # dwc-env.sh 统一环境变量 + ENABLE_* 开关
│   ├── etc/supervisor/      # supervisord 主配置 + conf.d/*.conf（所有镜像共用）
│   └── usr/local/bin/dwc-*  # 服务 wrapper 脚本（均带命令存在性守卫）
├── scripts/                 # 构建期安装脚本（install-*.sh + common/lib.sh）
├── skel/                    # 用户 home 骨架（/etc/skel）
├── docs/                    # BLUEPRINT.md（设计蓝图）、HISTORY.md（演进记录）
└── refs/                    # REFS.md（参考项目研究笔记）

## 镜像清单（13 个）

| 镜像 | 基底 | 类型 | 远程访问 |
|------|------|------|----------|
| desk | Kali | 桌面 | VNC / noVNC |
| full | Kali | 桌面 | VNC / noVNC + NoMachine + Anydesk + xrdp |
| lite | Debian slim | 桌面 | VNC / noVNC |
| lite-ice | Debian slim | 桌面 | VNC / noVNC (IceWM) |
| asbru | Debian 11 slim | 桌面 | VNC / noVNC |
| studio | Kali | 桌面 | VNC / noVNC + NoMachine + Anydesk + xrdp |
| py | Debian slim | 桌面 | VNC / noVNC |
| browser | Alpine | 功能 | SSH |
| jump | Alpine | 功能 | SSH (openssh 端口转发) |
| chat | Alpine | 功能 | VNC / noVNC (IceWM) |
| code | Debian slim | 功能 | code-server 8443 + SSH |
| build | Debian slim | 功能 | SSH (连宿主 docker) |
| tor | Alpine | 功能 | Tor SOCKS5 9050 + SSH |

## 设计原则

- 单容器单职责：每个镜像独立构建，不 FROM 其他自定义镜像（无 base 层）。
- 无特权运行：常规容器用 dropbear 轻量 SSH；`jump` 用 openssh-server（dropbear 不支持端口转发）。
- 数据持久化：统一挂载 `/config`；SSH/VNC host key 持久化到 `/config`，容器重置不丢。
- 用户：`qwe:toor`（sudo）+ `root:toor`。
- 服务开关：环境变量 `ENABLE_*`（`ENABLE_VNC`/`ENABLE_SSH`/`ENABLE_CODE`/`ENABLE_TOR`/…）由 `dwc-if` 控制 supervisord 子进程启停。
- VNC 服务端：Debian 12+ / Kali 用 TigerVNC（`tigervnc-standalone-server` + `tigervnc-tools`）；Debian 11 (asbru) 用 `tightvncserver`；Alpine 回退 Xvfb + x11vnc。

## 已知非阻断风险

- `dwc-xrdp` / `dwc-nomachine` / `dwc-anydesk` 在命令不支持 `--help` 或崩溃时可能触发 supervisord 重启（已有 `command -v` 守卫，未装则干净退出）。
- `tor` 镜像的 SocksPort/DNSPort/ControlPort 绑 `0.0.0.0`（独立匿名容器设计如此）。

详见 docs/BLUEPRINT.md（完整设计）与 docs/HISTORY.md（演进记录）。
