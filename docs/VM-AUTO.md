# Windows VM 自动安装指南

本文档说明如何配置自动安装模式，适用于 Docker Compose 和无人值守部署。

## Docker Compose 配置

```yaml
services:
  windows:
    image: dwc/cs50-vm
    container_name: windows-vm
    environment:
      MANUAL: "N"
      VERSION: "10"
      LANGUAGE: "Chinese"
      DISK_SIZE: "64G"
      RAM_SIZE: "8G"
      CPU_CORES: "4"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    volumes:
      - ./storage:/storage
      - ./shared:/shared
    ports:
      - "5900:5900"
      - "5700:5700"
      - "3389:3389"
      - "445:445"
    restart: unless-stopped
```

## 环境变量

### 基础配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MANUAL` | `Y` | 设为 `N` 启用自动模式 |
| `VERSION` | `10` | Windows 版本 |
| `LANGUAGE` | `Chinese` | 系统语言 |

### 硬件配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CPU_CORES` | `4` | CPU 核心数 |
| `RAM_SIZE` | `8G` | 内存大小 |
| `DISK_SIZE` | `64G` | 磁盘大小 |

### 用户配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `USERNAME` | - | Windows 用户名（自动安装时） |
| `PASSWORD` | - | Windows 密码（自动安装时） |

## 自动安装流程

当 `MANUAL=N` 时，容器启动后会自动：

1. 下载 Windows ISO（如果不存在）
2. 创建虚拟磁盘
3. 准备 VirtIO 驱动
4. 生成 autounattend.xml（无人值守安装）
5. 启动 QEMU

## 使用预下载的 ISO

为避免每次启动都下载 ISO，可以预先下载并挂载：

```yaml
volumes:
  - ./windows10.iso:/storage/win10x64_zh-CN.iso:ro
  - ./storage:/storage
```

## 持久化存储

安装完成后，Windows 数据存储在 `/storage/windows.img`。

确保使用持久化卷：

```yaml
volumes:
  - windows-storage:/storage

volumes:
  windows-storage:
```

## 健康检查

```yaml
healthcheck:
  test: ["CMD", "vm-status"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 多实例部署

运行多个 Windows 实例时，需要修改端口映射：

```yaml
services:
  windows1:
    # ...
    ports:
      - "5901:5900"
      - "5701:5700"
      - "3390:3389"

  windows2:
    # ...
    ports:
      - "5902:5900"
      - "5702:5700"
      - "3391:3389"
```

## 故障排除

### 查看日志

```bash
docker logs windows-vm
```

### 进入容器检查

```bash
docker exec -it windows-vm bash
vm-status
```

### 重新安装

删除现有安装标记：

```bash
docker exec -it windows-vm rm /storage/windows.boot
docker restart windows-vm
```
