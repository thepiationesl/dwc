// VM 配置
export interface VMConfig {
  id: string
  name: string
  createdAt: string

  // CPU 配置
  cpu: {
    cores: number
    model: string // "host" | "qemu64" | ...
  }

  // 内存 (MB)
  memory: number

  // 磁盘配置
  disk: {
    path: string       // 磁盘镜像路径
    size: string       // "32G", "64G"
    format: "qcow2" | "raw"
  }

  // ISO (可选)
  iso?: string

  // 显示
  display: {
    type: "vnc" | "spice" | "none"
    port?: number      // VNC: 5900+, SPICE: 5930+
    websocket?: number // noVNC websocket 端口
  }

  // 网络
  network: {
    type: "user" | "bridge" | "none"
    bridge?: string    // bridge 名称
    hostfwd?: PortForward[]
  }

  // 开关
  kvm: boolean
  uefi: boolean
  q35: boolean
  tpm: boolean

  // 额外参数
  extra?: string
}

// 端口转发
export interface PortForward {
  protocol: "tcp" | "udp"
  hostPort: number
  guestPort: number
}

// 运行状态
export interface VMStatus {
  running: boolean
  pid?: number
  uptime?: number // 秒
  error?: string
}

// 预设模板
export interface VMTemplate {
  id: string
  name: string
  description: string
  config: Partial<Omit<VMConfig, "id" | "createdAt">>
}

export const defaultTemplates: VMTemplate[] = [
  {
    id: "win11",
    name: "Windows 11",
    description: "Windows 11 推荐配置 (4C/8G, UEFI, Q35, TPM)",
    config: {
      cpu: { cores: 4, model: "host" },
      memory: 8192,
      disk: { path: "", size: "64G", format: "qcow2" },
      display: { type: "vnc", port: 5900 },
      network: {
        type: "user",
        hostfwd: [
          { protocol: "tcp", hostPort: 3389, guestPort: 3389 },
        ],
      },
      kvm: true,
      uefi: true,
      q35: true,
      tpm: true,
    },
  },
  {
    id: "win10",
    name: "Windows 10",
    description: "Windows 10 推荐配置 (2C/4G, Q35)",
    config: {
      cpu: { cores: 2, model: "host" },
      memory: 4096,
      disk: { path: "", size: "40G", format: "qcow2" },
      display: { type: "vnc", port: 5901 },
      network: {
        type: "user",
        hostfwd: [
          { protocol: "tcp", hostPort: 3390, guestPort: 3389 },
        ],
      },
      kvm: true,
      uefi: false,
      q35: true,
      tpm: false,
    },
  },
  {
    id: "linux",
    name: "Linux",
    description: "通用 Linux (2C/2G, SSH)",
    config: {
      cpu: { cores: 2, model: "host" },
      memory: 2048,
      disk: { path: "", size: "32G", format: "qcow2" },
      display: { type: "vnc", port: 5902 },
      network: {
        type: "user",
        hostfwd: [
          { protocol: "tcp", hostPort: 2222, guestPort: 22 },
        ],
      },
      kvm: true,
      uefi: false,
      q35: false,
      tpm: false,
    },
  },
  {
    id: "minimal",
    name: "极简",
    description: "最小配置 (1C/1G)",
    config: {
      cpu: { cores: 1, model: "host" },
      memory: 1024,
      disk: { path: "", size: "16G", format: "qcow2" },
      display: { type: "vnc", port: 5903 },
      network: { type: "user" },
      kvm: true,
      uefi: false,
      q35: false,
      tpm: false,
    },
  },
]

// 生成 QEMU 命令行 (返回 command 和 args 分离)
export function buildQemuCommand(config: VMConfig): { command: string; args: string[] } {
  const args: string[] = []

  // 名称
  args.push("-name", config.name)

  // KVM
  if (config.kvm) {
    args.push("-enable-kvm")
    args.push("-cpu", config.cpu.model)
  } else {
    args.push("-cpu", "qemu64")
  }

  // CPU
  args.push("-smp", config.cpu.cores.toString())

  // 内存
  args.push("-m", config.memory.toString())

  // 机器类型
  if (config.q35) {
    args.push("-machine", config.uefi ? "q35,smm=on" : "q35")
  }

  // UEFI
  if (config.uefi) {
    args.push("-bios", "/usr/share/OVMF/OVMF_CODE.fd")
  }

  // TPM (swtpm)
  if (config.tpm) {
    args.push("-chardev", "socket,id=chrtpm,path=/tmp/swtpm-sock")
    args.push("-tpmdev", "emulator,id=tpm0,chardev=chrtpm")
    args.push("-device", "tpm-tis,tpmdev=tpm0")
  }

  // 磁盘
  if (config.disk.path) {
    args.push("-drive", `file=${config.disk.path},format=${config.disk.format},if=virtio`)
  }

  // ISO
  if (config.iso) {
    args.push("-cdrom", config.iso)
    args.push("-boot", "d")
  }

  // 显示
  switch (config.display.type) {
    case "vnc":
      const vncDisplay = (config.display.port || 5900) - 5900
      let vncArg = `:${vncDisplay}`
      if (config.display.websocket) {
        vncArg += `,websocket=${config.display.websocket}`
      }
      args.push("-vnc", vncArg)
      break
    case "spice":
      args.push("-spice", `port=${config.display.port || 5930},disable-ticketing=on`)
      args.push("-device", "qxl-vga")
      break
    case "none":
      args.push("-display", "none")
      break
  }

  // 网络
  switch (config.network.type) {
    case "user":
      let netdev = "user,id=net0"
      if (config.network.hostfwd?.length) {
        const fwds = config.network.hostfwd.map(
          (f) => `hostfwd=${f.protocol}::${f.hostPort}-:${f.guestPort}`
        )
        netdev += "," + fwds.join(",")
      }
      args.push("-netdev", netdev)
      args.push("-device", "virtio-net-pci,netdev=net0")
      break
    case "bridge":
      args.push("-netdev", `bridge,id=net0,br=${config.network.bridge || "br0"}`)
      args.push("-device", "virtio-net-pci,netdev=net0")
      break
    case "none":
      args.push("-nic", "none")
      break
  }

  // 额外参数
  if (config.extra) {
    args.push(...config.extra.split(/\s+/).filter(Boolean))
  }

  return {
    command: "qemu-system-x86_64",
    args,
  }
}

// 生成可显示的命令字符串
export function formatQemuCommand(config: VMConfig): string {
  const { command, args } = buildQemuCommand(config)
  return `${command} \\\n  ${args.join(" \\\n  ")}`
}
