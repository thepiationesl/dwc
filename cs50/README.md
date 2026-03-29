# DWC CS50 分支 - 哈佛计算机科学入门课程

CS50 教育版分支，为哈佛大学计算机科学入门 (CS50) 课程优化的轻量级容器镜像集合。

## 📂 目录结构

```
cs50/
├── vm/                  # CS50 专用 Windows VM 镜像
│   └── Dockerfile
└── README.md           # 本文件
```

## ✨ 特性

- **轻量级** - 精简版 Debian，镜像 < 500MB
- **优化资源** - 默认配置：4 核 CPU、8GB 内存、40GB 磁盘
- **英语优先** - 默认语言：English，支持其他语言
- **学生友好** - 移除不必要的工具，保留核心功能
- **KVM 支持** - 虚拟化加速，流畅运行

## 🚀 快速开始

### 前置要求

- Docker 和 Docker Compose
- KVM 支持（推荐，可选）
- 至少 50GB 自由磁盘空间
- 至少 8GB 内存（推荐 16GB+）

### 启动 CS50 Windows VM

```bash
# 方式1：使用 Docker Compose
docker-compose up -d cs50-windows

# 方式2：手动运行
docker run -d --name cs50-vm \
  --device=/dev/kvm \
  -e LANGUAGE=English \
  -e CPU_CORES=4 \
  -e RAM_SIZE=8G \
  -e DISK_SIZE=40G \
  -p 5903:5900 \
  -p 3392:3389 \
  -v ./cs50-storage:/storage \
  -v ./cs50-shared:/shared \
  miko453/dwc:cs50-vm
```

### 首次使用

```bash
# 1. 进入容器
docker exec -it cs50-vm bash

# 2. 下载 ISO 和设置
vm-setup

# 3. 启动虚拟机
vm-start

# 4. 通过 RDP 连接
# 使用 RDP 客户端连接到 localhost:3392
# 或访问 VNC: localhost:5903
```

## 🎓 与完整版的区别

| 功能 | CS50 版 | 完整版 |
|------|---------|--------|
| 基础镜像 | Debian slim | Debian slim |
| 镜像大小 | < 500MB | < 600MB |
| Docker 支持 | ❌ | ✅ |
| 自动安装 | ❌ | ✅ |
| 自定义参数 | 基础 | 完整 |
| 语言 | EN/CN | 完整 |
| 推荐用途 | CS50 课程 | 通用开发 |

## 📊 默认配置

| 配置项 | 值 |
|--------|-----|
| Windows 版本 | Windows 10 |
| 语言 | English |
| CPU 核心数 | 4 |
| 内存大小 | 8GB |
| 磁盘大小 | 40GB |
| 键盘布局 | US |
| 地区 | US |
| 安装模式 | 手动 |

## 🔧 自定义配置

### 增加资源

编辑 docker-compose.yml：

```yaml
environment:
  CPU_CORES: "8"      # 增加 CPU
  RAM_SIZE: "16G"     # 增加内存
  DISK_SIZE: "80G"    # 增加磁盘
```

### 更改语言

```yaml
environment:
  LANGUAGE: "Chinese"  # 改为中文
```

### 更改键盘布局

```yaml
environment:
  KEYBOARD: "de"      # 德文键盘
  REGION: "DE"        # 德国
```

## 📞 常见问题

### Q: CS50 VM 和完整版有什么区别？

**A**: CS50 版本是针对哈佛 CS50 课程优化的精简版本。它：
- 移除了不必要的工具（如 Docker）
- 减少了镜像大小
- 使用了针对学生的优化配置

### Q: 如何扩展 CS50 版本？

**A**: 可以在虚拟机内部手动安装所需的额外工具，就像在任何 Windows 系统中一样。

### Q: CS50 VM 是否持久化？

**A**: 是的。虚拟机状态保存在 `cs50-storage` 目录中。删除容器不会丢失数据。

### Q: 如何重置虚拟机？

**A**: 
```bash
# 删除虚拟机存储
rm -rf cs50-storage/disk.qcow2

# 重新初始化
docker exec cs50-vm vm-setup
docker exec cs50-vm vm-start
```

### Q: 虚拟机太慢怎么办？

**A**: 
1. 启用 KVM：`--device=/dev/kvm`
2. 增加 CPU 和内存配置
3. 在 Windows 中禁用不必要的启动项

### Q: 如何从 CS50 VM 访问主机文件？

**A**: 使用 Samba 共享：
- 主机创建 `cs50-shared` 目录
- 从虚拟机访问：`\\container_ip\shared`
- 用户：qwe / 密码：toor

## 📚 相关文档

完整的 CS50 VM 使用指南：

- [docs/CS50-VM-GUIDE.md](../docs/CS50-VM-GUIDE.md) - 详细使用指南
- [docs/VM-GUIDE.md](../docs/VM-GUIDE.md) - 通用 VM 指南
- [docs/QUICKSTART.md](../docs/QUICKSTART.md) - 快速开始

## 🔗 CS50 资源

- [CS50 官方网站](https://cs50.harvard.edu)
- [CS50 GitHub](https://github.com/cs50)
- [CS50 讨论](https://discuss.cs50.net)

## 💡 建议

1. **充足的磁盘空间** - 确保至少 100GB 自由空间
2. **稳定的网络** - 首次运行需要下载 ISO
3. **启用虚拟化** - 在 BIOS 中启用 VT-x/AMD-V
4. **定期备份** - 重要工作定期复制 `cs50-storage`

## 🐛 故障排除

### VM 无法启动

```bash
# 检查日志
docker logs cs50-vm

# 检查 KVM可用性
docker exec cs50-vm ls -la /dev/kvm

# 手动测试
docker exec -it cs50-vm vm-setup
docker exec -it cs50-vm vm-status
```

### 无法连接 RDP

```bash
# 检查端口
docker ps | grep cs50-vm

# 验证容器运行
docker exec cs50-vm vm-status
```

### 虚拟磁盘满

```bash
# 增加磁盘大小
docker-compose stop cs50-windows

# 修改 docker-compose.yml 中的 DISK_SIZE

docker-compose up -d cs50-windows
docker exec cs50-vm vm-setup
```

## 📝 系统要求

| 要求 | 最低 | 推荐 |
|------|------|------|
| CPU | 4 核 | 8 核 |
| RAM | 8GB | 16GB |
| 磁盘 | 50GB | 100GB |
| 虚拟化 | 可选 | 必需 |

## 📄 许可证

基于 [dockur/windows](https://github.com/dockur/windows)，继承其许可证。

---

**开始学习**: [https://cs50.harvard.edu](https://cs50.harvard.edu)

**获取帮助**: 查看 [docs/CS50-VM-GUIDE.md](../docs/CS50-VM-GUIDE.md) 或在 CS50 官方论坛提问
