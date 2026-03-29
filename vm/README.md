# DWC Windows VM Containers

Windows 虚拟机容器集合，支持手动安装、自动安装和 legacy 兼容模式。

## 📂 目录结构

```
vm/
├── manual/              # 手动安装模式 Dockerfile
├── auto/                # 自动安装模式 Dockerfile
├── legacy/              # 旧版兼容 Dockerfile
├── scripts/             # VM 启动脚本
│   ├── entry.sh         # 入口脚本
│   ├── define.sh        # 定义和配置
│   ├── disk.sh          # 磁盘管理
│   ├── install.sh       # 安装脚本
│   ├── network.sh       # 网络配置
│   ├── power.sh         # 电源管理
│   ├── samba.sh         # Samba 共享
│   ├── helpers.sh       # 辅助函数
│   ├── vm-setup         # 设置命令
│   ├── vm-start         # 启动命令
│   ├── vm-stop          # 停止命令
│   └── vm-status        # 状态查询命令
└── README.md            # 本文件
```

## 🚀 快速开始

### Manual（手动安装）

推荐用于需要完全控制安装过程的用户。

```bash
# 1. 启动容器
docker-compose up -d windows-manual

# 2. 设置和下载 ISO
docker exec -it dwc-windows-manual vm-setup

# 3. 启动虚拟机
docker exec -it dwc-windows-manual vm-start

# 4. 通过 RDP 或 VNC 连接并手动安装 Windows
# RDP: localhost:3389
# VNC: localhost:5900

# 5. 停止虚拟机
docker exec -it dwc-windows-manual vm-stop
```

### Auto（自动安装）

用于需要自动化部署的环境。需要 Sysprep 文件。

```bash
# 1. 准备 Sysprep 文件
# 将 autounattend.xml 放到 ./sysprep/ 目录

# 2. 运行自动安装版本
docker-compose up -d windows-auto

# 虚拟机会自动启动并进行安装
```

## 📝 环境变量

manual / auto / legacy 都支持相同的环境变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VERSION` | 10 | Windows 版本：10 或 11 |
| `LANGUAGE` | Chinese | 语言：Chinese 或 English |
| `CPU_CORES` | 2 | CPU 核心数 |
| `RAM_SIZE` | 4G | 内存大小 |
| `DISK_SIZE` | 64G | 磁盘大小 |
| `KEYBOARD` | | 键盘布局（留空自动检测） |
| `REGION` | | 地区代码（留空自动检测） |
| `MANUAL` | Y（Manual），N（Auto） | 安装模式 |

更多变量见 `scripts/define.sh`。

## 🛠️ 可用命令

进入容器后可用的命令：

```bash
# 下载 ISO 和驱动，创建虚拟磁盘
vm-setup

# 启动 QEMU 虚拟机
vm-start

# 优雅停止虚拟机
vm-stop

# 查看虚拟机状态
vm-status

# 进入容器
docker exec -it dwc-windows-manual bash
```

## 🔗 相关文档

完整的使用指南请查看：

- [docs/VM-GUIDE.md](../docs/VM-GUIDE.md) - Windows VM 完整指南
- [docs/CS50-VM-GUIDE.md](../docs/CS50-VM-GUIDE.md) - CS50 教育版指南
- [docs/QEMU-WINDOWS-10-GUIDE.md](../docs/QEMU-WINDOWS-10-GUIDE.md) - QEMU 高级说明

## 📐 网络配置

### TAP 网络

对于完整的网络支持，需要 TAP 接口：

```bash
# 创建 TAP 接口
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up
sudo ip addr add 10.0.0.1/24 dev tap0
```

### 桥接网络

简化配置，使用桥接网络：

```yaml
environment:
  ARGUMENTS: "-net bridge,br=docker0"
```

## 🔧 文件共享

Samba 共享配置：

- 服务器：容器 IP
- 共享名称：`shared`
- 用户：qwe
- 密码：toor
- 映射目录：Docker 中的 `/shared` 挂载点

## 🎯 使用场景

1. **手动安装** - 用于学习和自定义安装过程
2. **自动化部署** - 用于生产环境的快速部署
3. **CI/CD 集成** - 用于测试 Windows 应用
4. **开发环境** - 用于 Windows 软件开发

## 🐛 常见问题

**Q: 如何备份虚拟机？**
A: 复制 `/storage` 目录或使用 `qemu-img` 备份虚拟磁盘

**Q: 需要增加磁盘空间怎么办？**
A: 修改 `DISK_SIZE` 环境变量并重新运行 `vm-setup`

**Q: 性能太慢？**
A: 
- 增加 `CPU_CORES` 和 `RAM_SIZE`
- 确保 KVM 已启用
- 使用 VirtIO 驱动

**Q: 无法连接网络？**
A: 检查 TAP 或桥接网络配置，查看 `vm-status` 输出

## 📄 许可证

基于 [dockur/windows](https://github.com/dockur/windows) 项目，继承其许可证。

---

详细信息见 [docs/VM-GUIDE.md](../docs/VM-GUIDE.md)
