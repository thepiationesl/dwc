# GitHub Codespaces Demo 配置（dev / vm / cs50）

本仓库已提供以下 demo Dev Containers 配置：

- `.devcontainer/dev-debian/devcontainer.json`
- `.devcontainer/dev-vm/devcontainer.json`
- `.devcontainer/vm-manual/devcontainer.json`
- `.devcontainer/vm-auto/devcontainer.json`
- `.devcontainer/cs50-vm/devcontainer.json`

## 说明

- 这些配置都面向 GitHub Codespaces。
- `dev-vm`、`vm-manual`、`vm-auto` 不再在 devcontainer 中预置 VM 运行参数，保持由脚本手动传参。
- VM 启动脚本现在会在缺少 `/dev/kvm` 时直接拒绝启动，而不是自动降级。
- `cs50-vm` 保留了 CS50 默认环境变量，并增加了 `/storage`、`/shared` 持久化挂载。
- `cs50-vm` 保留了 CS50 默认环境变量，并支持从 VS Code Marketplace 自动安装 CS50 官方 extensions（ddb50, lab50, markdown50, presentation mode 等）。

## 建议使用顺序

1. 开发环境优先使用 `dev-debian`。
2. 需要验证 VM 脚本逻辑时使用 `dev-vm`。
3. 需要完整 VM 镜像行为时使用 `vm-manual` / `vm-auto`。
4. 教学场景使用 `cs50-vm`。

## VM 基本命令

```bash
vm-setup
vm-start
vm-status
vm-stop
```
