# DWC 文档索引

按真实目录和当前文件整理的文档导航。

## 推荐阅读顺序

1. [../README.md](../README.md)
2. [QUICKSTART.md](QUICKSTART.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)

## 按场景查阅

| 场景 | 文档 |
|------|------|
| 初次部署 | [QUICKSTART.md](QUICKSTART.md) |
| 了解仓库结构 | [ARCHITECTURE.md](ARCHITECTURE.md) / [BLUEPRINT.md](BLUEPRINT.md) |
| Windows VM | [VM-GUIDE.md](VM-GUIDE.md) |
| CS50 VM | [CS50-VM-GUIDE.md](CS50-VM-GUIDE.md) |
| 历史兼容和高级参考 | [QEMU-WINDOWS-10-GUIDE.md](QEMU-WINDOWS-10-GUIDE.md) |
| `vm/` 子目录 | [../vm/README.md](../vm/README.md) |
| `cs50/` 子目录 | [../cs50/README.md](../cs50/README.md) |

## 当前目录结构

```text
dwc/
├── common/
├── cs50/
├── desktop/
├── dev/
├── docs/
├── novnc/
├── privacy/
├── skel/
├── vm/
├── docker-compose.yml
└── README.md
```

## 服务与入口

| 服务 | 说明 | 主要文档 |
|------|------|----------|
| `debian-dev` | 推荐开发环境 | [../README.md](../README.md) |
| `alpine-dev` | 兼容旧环境 | [../README.md](../README.md) |
| `windows-manual` | 手动安装 VM | [VM-GUIDE.md](VM-GUIDE.md) |
| `windows-auto` | 自动安装 VM | [VM-GUIDE.md](VM-GUIDE.md) |
| `windows` | 旧版兼容 VM | [QEMU-WINDOWS-10-GUIDE.md](QEMU-WINDOWS-10-GUIDE.md) |
| `cs50-windows` | CS50 场景 VM | [CS50-VM-GUIDE.md](CS50-VM-GUIDE.md) |
| `debian-desktop` | Debian 桌面 | [../README.md](../README.md) |
| `debian-audio` | 音频桌面 | [../README.md](../README.md) |
| `debian-asbru` | SSH 管理桌面 | [../README.md](../README.md) |
| `kali-desktop` | Kali 桌面 | [../README.md](../README.md) |
| `privacy` | 隐私桌面 | [../README.md](../README.md) |

## 维护说明

- 文档新增后，先更新本页和 [README.md](README.md)
- 已废弃或一次性说明不要继续堆到仓库根目录
- 子目录独有说明优先放在对应子目录的 `README.md`
