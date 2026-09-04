# 故障排除与常见问题

> 遇到问题？查这份指南快速定位和解决。

---

## 🚨 快速诊断流程

### 第一步：确认容器运行状态

```bash
docker ps -a

# 输出应该显示：
# CONTAINER ID   IMAGE      STATUS
# abc123         dwc:desk   Up X minutes
```

| 状态 | 说明 | 解决方案 |
|------|------|---------|
| `Up X minutes` | ✓ 容器正常运行 | 跳到步骤 2 |
| `Exited (1)` | ✗ 容器异常退出 | 查日志：`docker logs dwc_desk` |
| `不在列表中` | ✗ 容器不存在 | 重新运行：`make run IMG=desk` |

### 第二步：查看容器日志

```bash
docker logs dwc_desk          # 查看启动日志
docker logs -f dwc_desk       # 实时跟踪日志
docker logs --tail 50 dwc_desk  # 查看最后 50 行
```

### 第三步：进入容器诊断

```bash
docker exec -it dwc_desk bash

# 容器内常用诊断命令
supervisorctl -S /run/supervisor.sock status    # 查看进程
ps aux                                            # 查看所有进程
netstat -tlnp                                     # 查看监听端口
env | grep ENABLE                                 # 查看功能开关
cat /var/log/supervisor/supervisord.log           # supervisord 日志
```

---

## 🔴 常见问题速查

### 问题 1：VNC 连不上（黑屏 / 超时）

#### 症状
- 打开 `http://your-vps-ip:6080` 显示连接超时或连接被拒绝
- RealVNC 客户端无法连接

#### 快速检查

```bash
# 1. 容器是否运行？
docker ps | grep dwc_desk

# 2. 容器内 VNC 是否启动？
docker exec dwc_desk supervisorctl -S /run/supervisor.sock status | grep vnc

# 3. VNC 进程是否监听 5901 端口？
docker exec dwc_desk netstat -tlnp | grep 5901

# 4. 防火墙是否开放 6080 端口？
sudo ufw status
sudo iptables -L -n | grep 6080
```

#### 解决方案

**情况 A：容器未运行**
```bash
make run IMG=desk
```

**情况 B：VNC 进程未启动**
```bash
# 检查 ENABLE_VNC 是否设置
docker exec dwc_desk bash -c 'echo $ENABLE_VNC'

# 手动启动 VNC
docker exec dwc_desk supervisorctl -S /run/supervisor.sock start vnc

# 查看为什么启不了
docker exec dwc_desk supervisorctl -S /run/supervisor.sock tail vnc stderr
```

**情况 C：防火墙阻止**
```bash
# UFW（Ubuntu 默认）
sudo ufw allow 6080/tcp

# iptables（CentOS / 自定义）
sudo iptables -A INPUT -p tcp --dport 6080 -j ACCEPT
sudo iptables-save

# 或者允许所有端口（测试用，生产不建议）
sudo iptables -P INPUT ACCEPT
```

**情况 D：VNC 密码错误**
```bash
# 默认密码是 114514，如果改过需要查看
docker exec dwc_desk vncpasswd  # 修改
docker exec dwc_desk supervisorctl -S /run/supervisor.sock restart vnc
```

#### 终极诊断

```bash
# 查看完整 VNC 启动日志
docker exec dwc_desk cat /var/log/supervisor/vnc.log

# 从宿主 ssh 进容器再测试 VNC
ssh qwe@your-vps-ip -p 2222
vncviewer localhost:99 -passwd /path/to/vnc_pass
```

---

### 问题 2：SSH 连接超时或拒绝

#### 症状
```
ssh: connect to host your-vps-ip port 2222: Connection refused
ssh: connect to host your-vps-ip port 2222: Connection timed out
```

#### 快速检查

```bash
# 1. 容器运行？
docker ps | grep dwc_desk

# 2. SSH 进程启动？
docker exec dwc_desk supervisorctl -S /run/supervisor.sock status | grep dropbear

# 3. SSH 端口监听？
docker exec dwc_desk netstat -tlnp | grep 22

# 4. 宿主防火墙允许？
sudo ufw status | grep 2222
```

#### 解决方案

**情况 A：容器未运行**
```bash
make run IMG=desk
```

**情况 B：SSH 进程未启动**
```bash
# 检查 ENABLE_SSH
docker exec dwc_desk bash -c 'echo $ENABLE_SSH'

# 如果是 false，改为 true 并重启
docker exec dwc_desk bash -c 'export ENABLE_SSH=true && \
  supervisorctl -S /run/supervisor.sock start dropbear'
```

**情况 C：密码错误**
```bash
# 默认密码 qwe/toor 或 root/toor
# 如果改过需要重设（需进容器）
docker exec -it dwc_desk bash
passwd qwe    # 改 qwe 用户密码
exit

# 重新 SSH 连接
ssh qwe@your-vps-ip -p 2222
```

**情况 D：防火墙阻止**
```bash
sudo ufw allow 2222/tcp
# 或
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
```

**情况 E：dropbear 不支持的认证方式**

Dropbear 不支持 ECDSA 密钥，改用 RSA 或 ED25519：
```bash
# 本地生成 ED25519 密钥
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# 或 RSA
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# 指定密钥连接
ssh -i ~/.ssh/id_ed25519 qwe@your-vps-ip -p 2222
```

---

### 问题 3：容器启动后立即退出

#### 症状
```
docker ps -a 显示 Exited (1) 或 Exited (139)
make run 后立即返回，没有容器运行
```

#### 快速检查

```bash
# 查看退出原因
docker logs dwc_desk

# 常见信息
# "command not found"      → 镜像构建不完整
# "segmentation fault"     → 进程崩溃
# "supervisord error"      → 配置文件错误
```

#### 解决方案

**情况 A：镜像构建失败（部分文件缺失）**
```bash
# 重新构建
make clean IMG=desk
make build IMG=desk

# 检查构建输出是否有 ERROR
```

**情况 B：supervisord 配置错误**
```bash
# 检查配置文件
docker run -it --rm -v /sec/root/wks/dwc/rootfs:/rootfs \
  debian:12 cat /rootfs/etc/supervisor/supervisord.conf

# 或进正常镜像检查
docker exec dwc_desk cat /etc/supervisor/supervisord.conf | head -50
```

**情况 C：网络或权限问题**
```bash
# 尝试以交互式启动诊断
docker run -it --rm dwc:desk /bin/bash

# 手动启动 supervisord
supervisord -c /etc/supervisor/supervisord.conf -n  # -n 前台运行
```

---

### 问题 4：中文显示乱码

#### 症状
- 桌面菜单显示 `??`
- 文件名乱码
- 中文字体显示为方块

#### 快速检查

```bash
# 查看当前语言环境
docker exec dwc_desk echo $LANG

# 应该是 zh_CN.UTF-8 或 en_US.UTF-8
```

#### 解决方案

**情况 A：LANG 未设置为中文**
```bash
# 重新运行容器时指定中文
docker run -e LANG=zh_CN.UTF-8 -e TZ=Asia/Shanghai dwc:desk

# 或修改现有容器
docker update --env LANG=zh_CN.UTF-8 dwc_desk
docker restart dwc_desk
```

**情况 B：容器内缺中文字体**

仅限 lite / lite-ice（Debian slim），Kali 和 code 已预装：
```bash
docker exec dwc_desk bash -c \
  'apt update && apt install -y ttf-wqy-microhei'
```

**情况 C：VNC 客户端编码问题**

RealVNC 客户端设置：
```
菜单 → Options → Encoding → UTF-8
```

---

### 问题 5：镜像构建失败

#### 症状
```
make build IMG=desk
# 输出：ERROR [stage-name X/Y] ...
```

#### 常见原因与解决

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `E: Unable to locate package` | 源超时或不可用 | 重试 or 检查网络 |
| `Permission denied` | 文件权限问题 | `sudo chmod +x scripts/*.sh` |
| `COPY failed: file not found` | 文件路径错误 | 检查 Dockerfile 的 COPY 路径 |
| `command not found` | 依赖未安装 | 检查 install script |
| `Docker daemon not running` | Docker 服务未启 | `sudo systemctl start docker` |

#### 诊断步骤

```bash
# 1. 清理 docker 缓存
docker system prune -a

# 2. 重新构建，显示详细输出
docker build --progress=plain -f images/desk/Dockerfile . 2>&1 | tee build.log

# 3. 搜索 ERROR 关键行
grep -i error build.log

# 4. 查看构建上下文是否正确
ls -la rootfs/
ls -la scripts/
```

---

### 问题 6：磁盘空间满

#### 症状
```
docker ps 能运行，但执行命令提示 "No space left on device"
docker logs 显示不了
```

#### 快速检查

```bash
# 查看磁盘占用
df -h

# 查看 docker 占用
docker system df

# 查看具体镜像大小
docker images --format "table {{.Repository}}\t{{.Size}}"
```

#### 解决方案

```bash
# 1. 删除不用的容器
docker container prune -f

# 2. 删除不用的镜像
docker image prune -a -f

# 3. 删除不用的卷
docker volume prune -f

# 4. 深度清理（谨慎！）
docker system prune -a --volumes

# 5. 如果还是满，手动删除大镜像
docker rmi dwc:full  # 删除 full 镜像（~1200MB）

# 6. 最后一招：清理 docker 日志
sudo journalctl --vacuum=500M  # 仅保留 500MB 日志
sudo find /var/lib/docker -name "*.log" -delete
```

---

### 问题 7：音频无法传输（studio）

#### 症状
- 用 VNC 听不到声音
- 用 xrdp 听不到声音
- OBS / Synthesizer V 没有声音输出

#### 原因与方案

| 连接方式 | 音频支持 | 解决方案 |
|---------|---------|---------|
| VNC / noVNC | ✗ 不支持 | 改用 xrdp 或 NoMachine |
| xrdp | ✓ 有声音 | 确保 xrdp-pulseaudio 已安装 |
| NoMachine | ✓ 有声音 | 客户端设置音频为启用 |
| Anydesk | ✓ 有声音 | 同上 |

#### 排障步骤

**如果用 xrdp 还是没声音**：

```bash
# 1. 检查 xrdp-pulseaudio 是否安装
docker exec dwc_studio dpkg -l | grep xrdp

# 输出应该包含 xrdp-pulseaudio

# 2. 检查 PulseAudio 是否运行
docker exec dwc_studio ps aux | grep pulseaudio

# 3. 检查音频输出设备
docker exec dwc_studio pactl list sinks

# 4. 重启音频服务
docker exec dwc_studio supervisorctl -S /run/supervisor.sock restart pulseaudio

# 5. xrdp 客户端检查
# Windows RDP 客户端 → Options → Local Resources → Audio recording
# 确保勾选 "Connect audio from this computer"
```

---

### 问题 8：Tor 无法连接或访问 onion 失败

#### 症状
```
curl -x socks5://your-vps-ip:9050 https://www.example.onion
# curl: (7) SOCKS5 connect failed
```

#### 快速检查

```bash
# 1. Tor 容器运行？
docker ps | grep dwc_tor

# 2. Tor 进程启动？
docker exec dwc_tor supervisorctl -S /run/supervisor.sock status

# 3. SOCKS5 端口监听？
docker exec dwc_tor netstat -tlnp | grep 9050

# 4. Tor 是否已连接到网络？
docker logs dwc_tor | grep -i "bootstrapped"
```

#### 解决方案

**情况 A：Tor 未完全初始化**

Tor 首次启动需要 30-60 秒连接网络：
```bash
# 等待初始化
sleep 60

# 重试连接
curl -x socks5://your-vps-ip:9050 https://www.example.onion
```

**情况 B：Tor 配置错误或网络问题**
```bash
# 查看 Tor 日志
docker logs dwc_tor

# 重启 Tor
docker exec dwc_tor supervisorctl -S /run/supervisor.sock restart tor

# 查看 Tor 启动日志
docker exec dwc_tor tail -50 /var/log/tor/notices.log
```

**情况 C：本地无法连接 VPS 的 SOCKS5**

防火墙未开放 9050：
```bash
sudo ufw allow 9050/tcp

# 或允许特定 IP 的 9050 端口
sudo ufw allow from 192.168.1.0/24 to any port 9050
```

**情况 D：.onion 网站访问超时**

可能是网站离线或网络延迟，正常现象，Tor 连接较慢。可尝试：
```bash
# 增加超时
curl --max-time 60 -x socks5://your-vps-ip:9050 https://www.example.onion

# 或在浏览器里设置 SOCKS5 代理后直接访问
```

---

### 问题 9：VSCode Web（code 镜像）无法访问

#### 症状
```
https://your-vps-ip:8443 无法访问或显示 ERR_SSL_VERSION_OR_CIPHER_MISMATCH
```

#### 快速检查

```bash
# 1. code 容器运行？
docker ps | grep dwc_code

# 2. code-server 进程启动？
docker exec dwc_code supervisorctl -S /run/supervisor.sock status

# 3. 8443 端口监听？
docker exec dwc_code netstat -tlnp | grep 8443
```

#### 解决方案

**情况 A：容器未运行**
```bash
make run IMG=code
```

**情况 B：首次访问需要密码**
```bash
# 查看初始密码
docker logs dwc_code | grep -i "password\|token"

# 输出例如：
# [2024-08-11 12:34:56.789] info  code-server 4.x.x
# [2024-08-11 12:34:56.789] info  Built with Node.js 20.x.x
# [2024-08-11 12:34:56.789] info  password 1234567890abcdef
```

**情况 C：SSL 证书错误**

code-server 使用自签证书，浏览器会警告：
```
点击 Advanced → Proceed to your-vps-ip:8443（不安全）
```

或用命令行跳过证书检查：
```bash
curl -k https://your-vps-ip:8443
```

**情况 D：防火墙阻止**
```bash
sudo ufw allow 8443/tcp
```

---

### 问题 10：容器内时间不对

#### 症状
```
docker exec dwc_desk date
# 输出时间与宿主相差很大
```

#### 原因与方案

容器默认用 UTC 时区，需要改 TZ 环境变量：

```bash
# 重新运行容器时指定时区
docker run -e TZ=Asia/Shanghai dwc:desk

# 或修改现有容器
docker update --env TZ=Asia/Shanghai dwc_desk
docker restart dwc_desk

# 验证
docker exec dwc_desk date
docker exec dwc_desk echo $TZ
```

**常用时区**：
- `Asia/Shanghai` - 中国
- `America/New_York` - 美国东部
- `Europe/London` - 伦敦
- `UTC` - 协调世界时

---

## 💡 高级诊断

### 进入容器完全诊断

```bash
docker exec -it dwc_desk bash

# 容器内诊断命令
whoami                                           # 当前用户
id                                               # 用户 ID/组 ID
df -h                                            # 磁盘
free -h                                          # 内存
ps aux                                           # 所有进程
netstat -tlnp                                    # 监听端口
env | sort                                       # 环境变量
cat /var/log/supervisor/supervisord.log          # supervisord 日志
supervisorctl -S /run/supervisor.sock status    # 进程状态
```

### Docker 宿主诊断

```bash
# 查看容器网络
docker inspect dwc_desk | grep -A 20 NetworkSettings

# 查看容器资源使用
docker stats dwc_desk

# 查看容器完整信息
docker inspect dwc_desk

# 查看容器启动命令
docker inspect dwc_desk | grep "Cmd" -A 5
```

### 日志聚合分析

```bash
# 导出完整日志到文件
docker logs dwc_desk > desk.log 2>&1

# 搜索错误
grep -i "error\|failed\|exception" desk.log

# 统计 supervisord 重启次数
grep "spawned" /var/log/supervisor/supervisord.log | wc -l
```

---

## 📞 还是解决不了？

### 收集诊断信息

提交 Issue 时，请提供：

```bash
# 1. docker 版本
docker --version

# 2. 镜像信息
docker images | grep dwc

# 3. 容器状态
docker ps -a | grep dwc_desk

# 4. 完整日志
docker logs dwc_desk > logs.txt 2>&1

# 5. 容器内诊断
docker exec dwc_desk bash -c 'supervisorctl -S /run/supervisor.sock status' >> logs.txt

# 6. 宿主网络配置
netstat -tlnp | grep -E "6080|2222|3389" >> logs.txt
```

### 常见解决路径

```
问题描述 → 查看本文快速检查
  ↓
  如果步骤失败 → 看解决方案
  ↓
  如果还失败 → 看高级诊断
  ↓
  如果还是不行 → 收集诊断信息 → 提 Issue
```

---

## 🔍 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Supervisord 文档](http://supervisord.org/)
- [TigerVNC 文档](https://tigervnc.org/)
- [code-server 文档](https://coder.com/docs/code-server)
- [Tor 文档](https://www.torproject.org/)

---

**最后更新**：2026-09-04（与代码 4870d39 同步） | **版本**：v2.1

---

## 🔧 新增排障（2026-09-04 同步）

### 问题 11：supervisord 程序状态显示 FATAL 但服务可用

#### 症状
```
supervisorctl status
dropbear                         FATAL     Exited too quickly (process log may have details)
openssh                          FATAL     Exited too quickly
chromium                         FATAL     Exited too quickly
...
```

但实际上 `netstat -tln` 显示端口在监听，`ssh qwe@...` 能登。

#### 原因
老版本 `dwc-if` 在禁用时 `sleep infinity`，新版改为立即 `exit 0`。
supervisord conf 用 `autorestart=unexpected` 区分"禁用"和"真的崩了"——但旧的镜像构建可能还有 cache，或 supervisord 看到非预期码尝试 3 次失败后状态卡 FATAL。

#### 解决
1. **不要紧**：程序实际上**在跑**（exit 0 后另一个 supervisor 实例接管，或真实服务进程已起）。验证端口是否监听即可。
2. 想要 supervisord 状态干净，重建镜像：`make clean IMG=<img> && make build IMG=<img>`。

### 问题 12：中文输入法失效（desk/full/studio）

#### 症状
桌面打开后按 Ctrl+Space 没反应，`fcitx5` 进程没在。

#### 快速检查
```bash
docker exec dwc_desk bash -c 'which fcitx5 && fcitx5 --version'
# 应返回 5.x.x

docker exec dwc_desk bash -c 'ps aux | grep fcitx5'
# xstartup 启动后应看到 fcitx5 -d

docker exec dwc_desk bash -c 'fcitx5-remote'  # 桌面内用
```

#### 原因
`dwc-xstartup` 会自动启动 fcitx5 -d（如果装了）。如果没启动，说明：
1. 镜像构建时 `fcitx5` 包没装上（看 `install-desktop.sh` 的 Debian 分支）
2. /home/qwe 没写权限（fcitx5 配置写不进去）

#### 解决
```bash
# 进入容器手动启动
docker exec -it dwc_desk bash
fcitx5 -d
export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx
startxfce4
```

### 问题 13：jump 镜像公钥登录失败

#### 症状
```
Permission denied (publickey)
```

#### 快速检查
```bash
docker exec dwc_jump ls -la /home/qwe/.ssh/
# 应有 authorized_keys，owner qwe:qwe

docker exec dwc_jump cat /etc/ssh/sshd_config | grep -E '^(PubkeyAuth|AuthorizedKeys)'
# PubkeyAuthentication yes
# AuthorizedKeysFile /home/qwe/.ssh/authorized_keys

docker exec dwc_jump cat /home/qwe/.ssh/authorized_keys
# 应有你的公钥
```

#### 常见原因
1. **公钥文件没挂进容器**：检查 `docker run -v /path/to/authorized_keys:/config/ssh/authorized_keys`
2. **权限不对**：`authorized_keys` 应是 `600` + `qwe:qwe`，`dwc-openssh` 启动时会自动设
3. **宿主 mount 把 /config/ssh 当目录而非文件**：用 `:ro` 后缀挂载文件
4. **sshd_config 没启用 PubkeyAuthentication**：看上面检查，YOLO 修复后默认已启用

#### 解决
```bash
# 1. 确认公钥文件存在
ls -la /path/to/your/authorized_keys

# 2. 重新挂载
docker rm -f dwc_jump
docker run -d --name dwc_jump \
  -v /path/to/your/authorized_keys:/config/ssh/authorized_keys:ro \
  -p 2222:2222 dwc:jump

# 3. 容器内手动验证公钥到位
docker exec dwc_jump bash -c 'ls -la /home/qwe/.ssh/'

# 4. 客户端用详细模式连接
ssh -vvv -i ~/.ssh/your_key qwe@your-vps-ip -p 2222
```

### 问题 14：PUID/PGID 配错，挂载卷被改成 root

#### 症状
```bash
ls -la /data/dwc_config/
# drwxr-xr-x  root  root  ...
# 不是预期的 uid=1000
```

#### 原因
未设 `PUID`/`PGID`，容器内 qwe 用户的 UID 是镜像内默认 1000；宿主 mount 进 `/config` 后，文件是宿主 UID 拥有的，容器内 qwe 没权限。

#### 解决
```bash
# 启动时设 PUID/PGID 对齐宿主
docker run -e PUID=$(id -u) -e PGID=$(id -g) -v /data/dwc_config:/config dwc:desk

# chown 回宿主
docker exec dwc_desk bash -c 'chown -R qwe:qwe /config'

# 之后保持 PUID/PGID 启动即可
```

如有问题，欢迎提 Issue！
