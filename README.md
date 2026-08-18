# dwc - 无特权云工作站容器集群

一台 VPS 把桌面跑在服务器上，随处远程访问，直连国外。13 个容器，每个独立构建、单用途、互不依赖。

## 🚀 30 秒快速开始

```bash
git clone git@github.com:thepiationesl/dwc.git
cd dwc

make list              # 列出全部 13 个镜像
make build IMG=desk    # 构建单个镜像（缺省构建全部）
make run   IMG=desk    # 运行（自动映射端口）
make clean IMG=desk    # 删除镜像
```

构建上下文为仓库根：`docker build -f images/<img>/Dockerfile .`

## 📖 文档导航

- **新手？** → [QUICKSTART.md](docs/QUICKSTART.md) - 镜像选择 + 5 分钟上手
- **要查参数？** → [REFERENCE.md](docs/REFERENCE.md) - 端口、密码、环境变量速查
- **想深入了解？** → [ARCHITECTURE.md](docs/ARCHITECTURE.md) - 设计原则、技术规范、镜像详情
- **遇到问题？** → [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - 常见问题 & 排障指南
- **看参考项目？** → [refs/REFS.md](refs/REFS.md) - 外部参考研究笔记

## 🎯 13 个镜像一览

### 桌面型（7 个）- 图形界面工作站

| 镜像 | 基底 | 特色 | 远程访问 |
|------|------|------|----------|
| **desk** | Kali | 中文桌面主力 | VNC / noVNC |
| **full** | Kali | 完整版 + 音视频 | VNC + xrdp + NoMachine + Anydesk |
| **lite** | Debian slim | 极低配（XFCE） | VNC / noVNC |
| **lite-ice** | Debian slim | 极低配（IceWM） | VNC / noVNC |
| **asbru** | Debian 11 slim | asbru-cm 远程终端 | VNC / noVNC |
| **studio** | Kali | 音乐工作站 + 音频 | VNC + xrdp + NoMachine + Anydesk |
| **py** | Debian slim | Python 开发环境 | VNC / noVNC |

### 功能型（6 个）- 专用服务容器

| 镜像 | 基底 | 用途 | 远程访问 |
|------|------|------|----------|
| **browser** | Alpine | 无头 chromium + 隔离 | SSH 远程 |
| **jump** | Alpine | SSH 端口转发 | SSH 远程 |
| **chat** | Alpine | Pidgin + HexChat | VNC / noVNC |
| **code** | Debian slim | VSCode 网页版 | 浏览器（8443） |
| **build** | Debian slim | Docker 构建 | SSH 远程 |
| **tor** | Alpine | Tor 匿名上网 | SOCKS5（9050） |

## 📁 目录结构

```
dwc/
├── Makefile                     # 构建/运行入口
├── images/<name>/Dockerfile     # 每个镜像的独立 Dockerfile
├── rootfs/                      # 覆盖进镜像的文件
│   ├── etc/profile.d/           # dwc-env.sh 环境变量
│   ├── etc/supervisor/          # supervisord 配置
│   └── usr/local/bin/dwc-*      # 服务 wrapper 脚本
├── scripts/                     # 构建期安装脚本
├── skel/                        # 用户 home 骨架
├── docs/                        # 📄 重构后的文档集
│   ├── QUICKSTART.md            # 新手指南
│   ├── REFERENCE.md             # 速查表
│   ├── ARCHITECTURE.md          # 设计蓝图
│   └── TROUBLESHOOTING.md       # 问题排除
├── refs/                        # 外部参考
│   └── REFS.md                  # 参考项目研究
└── README.md                    # 本文件
```

## 🔑 核心设计（快速版）

- **无特权运行**：所有容器都可以无特权运行（安全）
- **单职责**：每个镜像独立构建，互不依赖
- **数据持久化**：统一挂载 `/config` 目录
- **默认用户**：`qwe:toor`（sudo）+ `root:toor`
- **进程管理**：supervisord 多进程管理
- **环境控制**：`ENABLE_*` 环境变量控制功能开关

更多设计细节 → [ARCHITECTURE.md](docs/ARCHITECTURE.md#核心设计原则)

## 💡 常见场景

| 需求 | 选择镜像 | 参考文档 |
|------|---------|---------|
| 日常办公、上网、编程 | **desk** 或 **lite** | [QUICKSTART](docs/QUICKSTART.md) |
| 音乐制作、视频剪辑 | **studio** | [ARCHITECTURE - studio](docs/ARCHITECTURE.md#studio-kali-音乐工作站) |
| 代码编辑（Web 版） | **code** | [QUICKSTART](docs/QUICKSTART.md#code-vscode-网页版) |
| 上 onion 网站安全浏览 | **browser** + **tor** | [TROUBLESHOOTING - Tor 配置](docs/TROUBLESHOOTING.md) |
| SSH 隧道转发 | **jump** | [REFERENCE - 端口映射](docs/REFERENCE.md#端口映射速查) |
| 宿主 docker 构建 | **build** | [ARCHITECTURE - build](docs/ARCHITECTURE.md#build-docker-cli-构建) |

## ⚡ 快速命令参考

```bash
# 构建
make build IMG=desk              # 构建 desk 镜像
make build                       # 构建全部 13 个镜像

# 运行
make run IMG=desk                # 运行 desk 容器
docker exec -it dwc_desk bash    # 进入容器 shell

# 查看
make list                        # 列出所有镜像
docker ps -a                     # 查看运行中的容器

# 维护
make clean IMG=desk              # 删除 desk 镜像
docker logs dwc_desk             # 查看容器日志
supervisorctl -S /tmp/supervisord.sock status  # 查看进程状态
```

完整命令 → [REFERENCE.md#常用命令](docs/REFERENCE.md#常用命令)

## 🔐 默认凭证（改为强密码！）

```
SSH / VNC / 桌面登录：
  用户：qwe       密码：toor
  用户：root      密码：toor

VNC 服务密码：114514
```

⚠️ **生产环境必须更改这些默认密码**

详见 → [REFERENCE.md#默认凭证](docs/REFERENCE.md#默认凭证)

## 🤝 贡献与反馈

- 发现 bug？ → 提 Issue
- 有优化建议？ → 提 PR
- 想要新镜像？ → 讨论后开发

---

**最后更新**：2026-08-11 | **文档版本**：v2.0（完整重构）
