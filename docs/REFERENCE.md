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
| VNC | `114514`（读写） | 所有桌面型容器；可设 `VNC_PASSWORD_RO` 给只读旁观 |
| xrdp | `qwe:toor` | full / studio |
| NoMachine | `qwe:toor` | full / studio |
| Anydesk | 动态令牌 | full / studio（启动后日志查看） |
| code-server | `${CODE_PASSWORD}` 或 `${HASHED_PASSWORD}` | code 镜像（默认 `toor`，推荐用 hash） |

### Tor

| 端口 | 用途 | 说明 |
|------|------|------|
| 9050 | SOCKS5 代理 | 其他容器/本地客户端可连接 |
| 9051 | 控制端口 | 不暴露，容器内用 |
| 5353 | DNS 端口（防 DNS 泄漏） | 容器内供上游使用 |

---

## 🌐 端口映射速查

### 容器内端口（`EXPOSE`）与建议宿主映射

`Makefile::run` 默认的宿主映射：

| 镜像 | 服务 | 容器端口 | 建议宿主映射 | 协议 | 说明 |
|------|------|----------|-------------|------|------|
| **desk** | SSH | 2222 | 2222 | tcp | dropbear |
| **desk** | VNC | 5901 | 5901 | tcp | TigerVNC `Xvnc`（`-localhost` 强制） |
| **desk** | noVNC | 6080 | 6080 | http | 浏览器访问 VNC |
| **lite** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | Debian slim |
| **lite-ice** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | IceWM |
| **asbru** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | Debian 11 + asbru-cm |
| **py** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | Debian slim + Python |
| **full** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | |
| **full** | xrdp | 3389 | 3389 | tcp | RDP（音频走 pulseaudio） |
| **full** | NoMachine | 4000 | 4000 | tcp | NX 协议 |
| **full** | Anydesk | 7070 | 7070 | tcp | 动态 ID |
| **studio** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | |
| **studio** | xrdp | 3389 | 3389 | | |
| **studio** | NoMachine | 4000 | 4000 | | |
| **studio** | Anydesk | 7070 | 7070 | | |
| **browser** | SSH | 2222 | 2222 | | dropbear |
| **browser** | chromium CDP | 9222 | 9222 | http | Chrome DevTools Protocol（Selenium/调试） |
| **jump** | OpenSSH | 2222 | 2222 | tcp | 端口转发 + 密钥登录 |
| **jump** | OpenSSH（标准） | 22 | 22 | | 标准 SSH，可选 |
| **chat** | SSH / VNC / noVNC | 2222 / 5901 / 6080 | 同 | | Pidgin + HexChat + IceWM |
| **code** | SSH | 2222 | 2222 | | dropbear |
| **code** | code-server | 8443 | 8443 | https | 自签证书，浏览器需信任 |
| **build** | SSH | 2222 | 2222 | | dropbear |
| **build** | docker.sock | — | — | unix | 挂载宿主 `/var/run/docker.sock` |
| **tor** | SSH | 2222 | 2222 | | dropbear |
| **tor** | SOCKS5 | 9050 | 9050 | | Tor 客户端代理 |
| **tor** | Tor Control | 9051 | 9051 | | 容器内默认 |
| **tor** | DNS | 5353 | 5353 | udp | 防 DNS 泄漏 |

> ⚠️ **VNC 端口默认 `-localhost` 绑定**（`dwc-xvnc`）：外部直连不可达，必须经本机 `noVNC` 走 websocket。noVNC 端口 6080 对外可暴露。

### 快速参考：常用入口

```bash
# VNC 网页访问（所有桌面型）
http://your-vps-ip:6080

# SSH 访问（所有镜像）
ssh qwe@your-vps-ip -p 2222

# RDP 客户端（full/studio）
your-vps-ip:3389

# NoMachine 客户端（full/studio）
your-vps-ip:4000

# VSCode 网页（code）
https://your-vps-ip:8443

# chromium DevTools（browser）
http://your-vps-ip:9222/json

# Tor SOCKS5 代理（tor）
your-vps-ip:9050
```

---

## 🎛️ 环境变量完整参考

> **所有环境变量都在 `dwc-entrypoint`/`dwc-env.sh`/`dwc-*` 启动脚本里读取。**
> 命名空间：全局（`LANG`/`TZ`/`PUID`/`PGID`）+ 服务开关（`ENABLE_*`）+ 服务参数（`VNC_*`/`SSH_*`/...）。

### 用户与时区（所有镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PUID` | `1000` | qwe 用户的 UID（**linuxserver 标准，挂卷后用户 ID 一致不写坏宿主目录**） |
| `PGID` | `1000` | qwe 用户的 GID |
| `LANG` | `en_US.UTF-8` | 主语言。桌面型镜像已生成 `zh_CN.UTF-8` locale，改 `LANG=zh_CN.UTF-8` 切换中文 |
| `LC_ALL` | `en_US.UTF-8` | 同上 |
| `TZ` | `UTC` | 时区。改 `Asia/Shanghai` 用上海时间 |
| `DEBUG` | `0` | 调试模式（1=详细日志） |

### SSH（dropbear：`desk`/`full`/`studio`/`lite`/`lite-ice`/`asbru`/`py`/`browser`/`chat`/`code`/`build`/`tor`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_SSH` | `true` | 启用 dropbear |
| `SSH_PORT` | `2222` | dropbear 监听端口（容器内） |

### OpenSSH（jump 镜像专用）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_SSH` | `true` | 启用 openssh-server |
| `SSH_PORT` | `2222` | 监听端口 |
| `ALLOW_PASSWORD` | `yes` | 是否允许密码登录（生产建议改 `no` 并用公钥） |
| `PERMIT_ROOT` | `yes` | 是否允许 root 登录（生产建议改 `no`） |

####公钥登录（jump 镜像）

把宿主机的公钥写到 `/config/ssh/authorized_keys` 即可自动注入到 `qwe` 用户家目录的 `/home/qwe/.ssh/authorized_keys`：

```bash
# 宿主端
docker run -p 2222:2222 \
  -v $HOME/.ssh/id_ed25519.pub:/config/ssh/authorized_keys:ro \
  dwc:jump

# 客户端
ssh -i ~/.ssh/id_ed25519 qwe@your-vps-ip -p 2222
```

### VNC（`desk`/`full`/`studio`/`lite`/`lite-ice`/`asbru`/`py`/`chat`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_VNC` | `true`（桌面型）/ `false`（功能型） | 启用 VNC |
| `VNC_PASSWORD` | `114514` | 读写密码 |
| `VNC_PASSWORD_RO` | 空 | **只读旁观密码**（`-rfbauthro`）；旁观者用此密码只看不操作 |
| `VNC_PORT` | `5901` | 容器内 VNC 端口（被 noVNC 走 localhost） |
| `VNC_GEOMETRY` | `1920x1200x24` | 分辨率（WxHxDepth） |
| `VNC_DEPTH` | `24` | 颜色深度覆盖 |
| `VNC_OFFSET` | `0` | **多容器同台机器时显示号偏移**（`:$((1+VNC_OFFSET))`），搭配宿主页口映射一起错开 |
| `NOVNC_PORT` | `6080` | noVNC 端口 |

### xrdp（`full`/`studio）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_XRDP` | `true` | 启用 xrdp |
| `XRDP_PORT` | `3389` | 监听端口（容器内） |

### NoMachine（`full`/`studio`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_NOMACHINE` | `true` | 启用 NoMachine |
| `NOMACHINE_USER` | `qwe` | NoMachine 登录用户名 |
| `NOMACHINE_PASSWORD` | `toor` | NoMachine 登录密码 |

### Anydesk（`full`/`studio`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_ANYDESK` | `true` | 启用 Anydesk |

### code-server（`code` 镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_CODE` | `true` | 启用 code-server |
| `CODE_PORT` | `8443` | code-server 监听端口 |
| `CODE_PASSWORD` | `toor` | 明文密码（**镜像 layer 会暴露，不推荐生产**） |
| `HASHED_PASSWORD` | 空 | **bcrypt hash，推荐**；`code-server --hashed-password` 接收。`HASHED_PASSWORD` 优先 |
| `CODE_AUTH` | `password` | 鉴权模式：`password` / `none` |
| `CODE_VERSION` | `4.103.0` | 构建期安装版本（锁定，避免每次拉最新版） |

### Tor（`tor` 镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_TOR` | `true` | 启用 tor 守护 |
| `TOR_SOCKS_PORT` | `9050` | SOCKS5 代理端口 |
| `TOR_CONTROL_PORT` | `9051` | 控制端口（容器内） |
| `TOR_DNS_PORT` | `5353` | DNS 端口 |
| `TOR_BRIDGE` | 空 | 网桥配置（若需翻墙） |

### chromium（`browser` 镜像）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_CHROMIUM` | `true` | 启用 chromium（headless + remote-debugging） |
| `CHROME_DEBUG_PORT` | `9222` | Chrome DevTools Protocol 端口 |
| `CHROME_USER_DATA` | `/config/chromium` | 用户数据持久化目录 |
| `CHROME_URL` | `about:blank` | 启动时打开的 URL |
| `CHROME_ARGS` | 空 | 额外 chromium 参数 |

### 修改环境变量的方法

**方法 A：重新运行容器时指定**
```bash
docker run -e LANG=zh_CN.UTF-8 -e TZ=Asia/Shanghai -e VNC_PASSWORD=mysecret dwc:desk
```

**方法 B：修改现有容器（运行时修改 + 重启 supervisord）**
```bash
docker exec dwc_desk bash -c 'export LANG=zh_CN.UTF-8 && \
  supervisorctl -c /etc/supervisord.conf restart all'
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
make list                       # 列出所有 13 个镜像
make build IMG=desk             # 构建 desk 镜像
make build                      # 构建全部 13 个镜像
make run IMG=desk               # 运行 desk 容器（自动映射端口）
make clean IMG=desk             # 删除 desk 镜像
```

### Docker 基本操作

```bash
docker ps -a                    # 查看容器状态
docker logs -f dwc_desk         # 容器日志
docker exec -it dwc_desk bash   # 进容器 shell
docker stop dwc_desk            # 停止
docker start dwc_desk           # 启动
docker restart dwc_desk         # 重启
docker rm dwc_desk              # 删容器
docker rmi dwc:desk             # 删镜像
```

### 容器内服务管理（supervisord）

```bash
# 查看所有进程状态
supervisorctl -c /etc/supervisord.conf status

# 启停单个服务
supervisorctl -c /etc/supervisord.conf startxvnc
supervisorctl -c /etc/supervisord.conf stop dropbear
supervisorctl -c /etc/supervisord.conf restart all

# 重新加载配置
supervisorctl -c /etc/supervisord.conf reread
supervisorctl -c /etc/supervisord.conf update
```

> **日志路径**：`/config/logs/<program>.log` 与 `<program>.err.log`（持久化在 /config，不会丢）

### VNC 密码管理

```bash
docker exec -it dwc_desk bash
# 设置新密码：改环境变量 VNC_PASSWORD，重启容器
# 容器内交互式：
vncpasswd
supervisorctl -c /etc/supervisord.conf restart xvnc
```

### SSH 密钥登录（jump 镜像推荐）

```bash
# 宿主端：把公钥放到挂载目录
mkdir -p /data/dwc_jump_ssh
cp ~/.ssh/id_ed25519.pub /data/dwc_jump_ssh/authorized_keys

# 启动 jump 时挂载
docker run -p 2222:2222 -v /data/dwc_jump_ssh:/config/ssh dwc:jump

# 客户端（密钥登录，无需密码）
ssh -i ~/.ssh/id_ed25519 qwe@your-vps-ip -p 2222
```

### 容器持久化与数据管理

```bash
# 挂载 /config 目录（推荐）
docker run -v /data/dwc_config:/config -v /data/dwc_workspace:/workspace dwc:desk

# 查看挂载
docker inspect dwc_desk | grep Mounts -A 10

# 备份
docker cp dwc_desk:/config ./backup_config

# 恢复
docker cp ./backup_config/. dwc_desk:/config/
```

---

## 📊 镜像大小参考（构建后约值）

| 镜像 | 约大小 | 备注 |
|------|--------|------|
| jump | ~100MB | 最轻量 |
| browser | ~150MB | 无头 chromium |
| chat | ~150MB | Pidgin + HexChat |
| tor | ~150MB | Tor 客户端 |
| build | ~250MB | Docker CLI |
| code | ~450MB | code-server 4.103.0 |
| lite-ice | ~500MB | Debian slim + IceWM |
| lite | ~550MB | Debian slim + xfce4 |
| py | ~600MB | Debian + Python 3 |
| asbru | ~600MB | Debian 11 + asbru-cm |
| desk | ~2.6GB | Kali + xfce4 + Chrome + fcitx5 |
| studio | ~2.8GB | desk + 音乐软件 |
| full | ~2.8GB | desk + 完整远程 |

---

## 🔒 安全建议

### 生产环境必做

- [ ] **改默认密码**：`qwe/toor` 和 `root/toor`，以及 VNC 密码 `114514`
- [ ] **jump 镜像启用密钥登录，禁密码**：挂载 `authorized_keys`，设置 `ALLOW_PASSWORD=no`
- [ ] **code-server 用 `HASHED_PASSWORD`**：哈希密码不进镜像 layer
- [ ] **限制端口暴露**：只向特定 IP 开放，用防火墙规则；noVNC 走 Nginx/caddy 反向代理加 HTTPS
- [ ] **VNC 加 view-only 旁观密码**：设 `VNC_PASSWORD_RO=yourpassword`，旁观用这个
- [ ] **多容器同台**：用 `VNC_OFFSET` 错开显示号 + 宿主端口映射
- [ ] **PUID/PGID 配宿主 UID**：避免挂卷后宿主目录被改成 root
- [ ] **定期备份 `/config`**：所有用户数据 + 服务状态 + ssh host key 都在这里
- [ ] **定期 rebuild 镜像**：上游安全更新

### 网络隔离

```bash
# 创建专用 docker 网络
docker network create dwc-network
docker run --network dwc-network ...

# 防火墙只开必要端口
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT  # SSH
iptables -A INPUT -p tcp --dport 6080 -j ACCEPT  # noVNC
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT  # code-server
iptables -A INPUT -p tcp --dport 9050 -j ACCEPT  # Tor SOCKS
```

### 定期清理

```bash
docker system prune -a          # 清无用镜像/容器
docker system df                # 看磁盘占用
```

---

## 📈 性能调优

### CPU & 内存限制

```bash
docker run --cpus=1 --memory=512m dwc:desk
```

### VNC 分辨率与颜色深度

| 分辨率 | 内存占用 | 建议场景 |
|--------|---------|----------|
| 1920x1200x24 | ~50MB | 标准桌面 |
| 2560x1440x24 | ~80MB | 高分屏 |
| 1280x720x24 | ~30MB | 低配 VPS |
| 1024x768x16 | ~15MB | 极低配 VPS |

```bash
docker run -e VNC_GEOMETRY=1280x720x24 -e VNC_DEPTH=24 dwc:lite
```

---

## 🆘 快速故障排除

| 问题 | 快速检查 | 解决方案 |
|------|---------|---------|
| 连不上 VNC | `docker logs dwc_desk \| grep xvnc` | 检查防火墙 + 看 `/config/logs/xvnc.err.log` |
| noVNC 黑屏 | 检查 `vncpasswd` 是否生成 | 容器内 `ls -la /config/vnc/passwd` |
| SSH 连接超时 | `docker ps` | 容器未运行则 `make run IMG=desk` |
| SSH 密码错误 | `docker exec dwc_desk id qwe` | 看 qwe 是否存在；`chpasswd` 重置 |
| 中文显示乱码 | `echo $LANG` + `locale -a \| grep zh_CN` | 设 `LANG=zh_CN.UTF-8`，镜像已生成 locale |
| 中文输入法失效 | `which fcitx5`（仅 desk/full/studio/lite/lite-ice/asbru/py） | 检查 xdpyinfo 看 X 是否在；看 `xstartup` log |
| 容器退出 | `docker logs dwc_desk` | 看错误信息，多半是 supervisord 起不来 |
| 磁盘满 | `df -h` + `docker system df` | `docker system prune -a` |
| code-server 启动失败 | `docker logs dwc_code \| tail -30` | 镜像构建是否完整，看 install-svc.sh code 分支 |
| jump 镜像公钥登录失败 | `docker exec dwc_jump ls /home/qwe/.ssh/` | authorized_keys 是否到位；sshd_config 是否启用 PubkeyAuthentication |

完整排障 → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**最后更新**：2026-09-04（与代码 4870d39 同步）