# Alpine FVC - QEMU Windows 10 Usage Guide

基于 dockur/windows 的生产级 Windows 10 虚拟化容器。

## 快速开始

### 1. 启动容器

```bash
docker run -it \
  --device=/dev/kvm \
  -v $(pwd)/storage:/storage \
  dwc/alpine-fvc:latest
```

### 2. 进入容器后启动 Windows 10

```bash
# 基础启动 (2 CPU, 4GB RAM)
$ win10

# 高性能启动 (6 CPU, 16GB RAM)
$ CPUS=6 MEMORY=16G win10

# 带数据盘启动
$ CPUS=6 MEMORY=16G DATA_DISK=/storage/data.img win10

# 带 Windows 10 安装 ISO 启动
$ win10 /storage/windows10.iso
```

### 3. 访问 Windows 10

启动后输出示例：
```
[*] Starting Windows 10 VM...
[*] CPUs: 6 | Memory: 16G
[*] VNC: :0 | WebSocket: :5700
[*] Monitor: localhost:7100 (telnet)
[*] Log: /run/shm/qemu.log
[*] PID: /run/shm/qemu.pid
```

访问方式：
- **VNC 客户端**: `localhost:5900` (需要本地 VNC 客户端)
- **WebSocket**: `localhost:5700` (浏览器，需要 WebSocket-to-VNC 代理)
- **Telnet Monitor**: `telnet localhost:7100` (QEMU 监控控制台)

## 详细配置

### 环境变量

在 `win10` 命令前设置：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CPUS` | 2 | CPU 核心数 |
| `MEMORY` | 4G | 内存大小（e.g., 4G, 8G, 16G） |
| `VNC_PORT` | 0 | VNC 端口偏移（实际端口 = 5900 + VNC_PORT） |
| `DISK` | /storage/windows.img | 主磁盘路径（自动创建 64GB） |
| `DATA_DISK` | /storage/data.img | 数据盘路径（可选，自动创建 256GB） |
| `UEFI_CODE` | /storage/windows.rom | UEFI 固件代码文件 |
| `UEFI_VARS` | /storage/windows.vars | UEFI 变量文件 |
| `ENABLE_TAP` | 0 | 启用 TAP 网络（0=User Mode, 1=TAP） |

### 使用示例

#### 示例 1: 安装 Windows 10

```bash
# 下载 Windows 10 ISO（需自行获取）
# 放到 storage/ 目录

# 启动 VM，带安装ISO
docker run -it --device=/dev/kvm -v $(pwd)/storage:/storage dwc/alpine-fvc:latest

# 容器内执行
win10 /storage/Windows10.iso
```

#### 示例 2: 多虚拟机配置

```bash
# 终端 1: VNC 端口 0，6核16GB
CPUS=6 MEMORY=16G VNC_PORT=0 win10 /storage/windows.iso

# 新终端，同一容器，创建新 QEMU 实例
docker exec -it <container> /bin/sh
CPUS=4 MEMORY=8G VNC_PORT=1 win10
```

#### 示例 3: 使用持久化数据盘

```bash
# 创建自定义大小的数据盘
docker exec -it <container> create-disk 1T /storage/backup.img raw

# 启动时挂载
CPUS=6 MEMORY=16G DATA_DISK=/storage/backup.img win10
```

## QEMU 配置详解

### CPU 优化

```
-nodefaults                              # 最小化默认设备
-cpu host,kvm=on,l3-cache=on,\
    +hypervisor,migratable=no            # 启用 L3 缓存，超线程，虚拟化扩展
-smp 6,sockets=1,dies=1,cores=6,\
    threads=1                            # 6 核心，单 socket，无超线程
```

### 内存和机器类型

```
-m 16G                                   # 16GB 内存
-machine type=q35,smm=off,graphics=off, # Q35 主板（PCIE 总线）
         vmport=off,dump-guest-core=off, # 禁用 VMPort，核心转储
         hpet=off,accel=kvm              # 禁用 HPET 计时器
```

### 存储优化

**主磁盘 (virtio-scsi + iothread)**:
```
-object iothread,id=io0
-drive file=windows.img,id=drive0,format=qcow2,\
       cache=none,aio=native,discard=on,detect-zeroes=on
-device virtio-scsi-pci,id=scsi0,iothread=io0
-device scsi-hd,drive=drive0,bus=scsi0.0,bootindex=1
```

优点：
- QCOW2 格式：快速、稀疏、支持快照
- virtio-scsi：比 SATA 快 3-5 倍
- iothread：异步 I/O，提高吞吐量
- cache=none：避免缓冲区，数据一致性
- discard/detect-zeroes：优化存储使用

### 网络

**User Mode (默认)**:
```
-netdev user,id=hostnet0
-device virtio-net-pci,id=net0,netdev=hostnet0
```
优点：无需配置，即插即用。缺点：性能略低，NAT 模式。

**TAP Mode (可选)**:
```
-netdev tap,id=hostnet0,ifname=qemu,script=no,downscript=no
-device virtio-net-pci,id=net0,netdev=hostnet0
```
优点：高性能，直接网络访问。缺点：需要主机配置 TAP 接口。

### VNC 和 WebSocket

```
-display vnc=:0,websocket=5700          # VNC :0 (端口 5900)，WebSocket 5700
-vga virtio                              # VirtIO GPU（比 std 快）
```

### 监控和日志

```
-monitor telnet:localhost:7100,server    # Telnet 远程监控
-daemonize                               # 后台运行
-D /run/shm/qemu.log                    # 日志文件
-pidfile /run/shm/qemu.pid              # PID 文件
```

### UEFI 固件

```
-drive file=windows.rom,if=pflash,unit=0,\
       format=raw,readonly=on            # 固件代码（只读）
-drive file=windows.vars,if=pflash,\
       unit=1,format=raw                 # 固件变量（可写）
```

## 故障排查

### 查看 QEMU 日志

```bash
# 容器内
tail -f /run/shm/qemu.log
```

### 连接 QEMU 监控控制台

```bash
# 容器内
telnet localhost:7100

# 查看 VM 状态
(qemu) info status
(qemu) info block

# 暂停 VM
(qemu) stop

# 恢复 VM
(qemu) cont

# 退出
(qemu) quit
```

### CPU 性能检查

```bash
# 确保 KVM 可用
ls -la /dev/kvm

# 检查 CPU 功能
grep -E '^flags' /proc/cpuinfo | head -1
```

应该包含：`vmx` (Intel) 或 `svm` (AMD)

### 网络问题

```bash
# 容器内检查网络
ip addr
ping 8.8.8.8

# 主机检查转发端口
netstat -tlnp | grep qemu
```

## 性能优化建议

1. **使用 KVM**：`--device=/dev/kvm` (必须)
2. **分配足够资源**：至少 2 核 4GB，推荐 6 核 16GB
3. **使用 QCOW2 + virtio-scsi**：标准配置已优化
4. **禁用不必要的设备**：`-nodefaults` 已启用
5. **I/O 优化**：`cache=none,aio=native` 配置了异步 I/O
6. **内存合并**：可选 `-machine memory-backend-file=mem,size=16G,share=on`

## 常见问题

**Q: 启动时提示缺少固件文件？**  
A: 运行 `setup-uefi` 查看说明。Windows.rom 和 windows.vars 需要用户提供，可从 EDK2 项目下载。

**Q: 虚拟机很慢？**  
A: 检查 KVM 是否启用（/dev/kvm），确保分配足够 CPU 和内存。

**Q: 如何停止 QEMU？**  
A: 在监控控制台输入 `quit`，或 `kill $(cat /run/shm/qemu.pid)`。

**Q: 能否扩展磁盘？**  
A: QCOW2 自动扩展。如需扩展已有镜像：`qemu-img resize disk.qcow2 +50G`。

**Q: Windows 10 激活问题？**  
A: 此配置支持 KMS 激活或使用试用版（180 天）。

## 相关文件

- `/usr/local/bin/win10` - 启动脚本
- `/usr/local/bin/create-disk` - 磁盘创建工具
- `/usr/local/bin/setup-uefi` - UEFI 固件检查
- `/storage/` - 持久化存储目录

## 参考

- [QEMU 官方文档](https://wiki.qemu.org)
- [KVM 配置优化](https://wiki.qemu.org/Documentation/PerformanceTuning)
- [dockur/windows](https://github.com/dockur/windows) - 参考项目
