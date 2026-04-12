// QEMU VM 配置类型 - 最小化设计
export type VMStatus = "running" | "stopped" | "starting" | "error"

// QEMU 启动配置
export interface QemuConfig {
  // 基础配置
  name: string
  cpu: number
  memory: number // MB
  
  // 磁盘配置
  diskPath: string      // 磁盘镜像路径 (qcow2/raw)
  diskSize?: string     // 创建新磁盘时的大小 如 "64G"
  cdrom?: string        // ISO 路径
  
  // 显示配置  
  display: "vnc" | "spice" | "none"
  vncPort?: number      // VNC 端口 (5900+)
  
  // 网络配置
  network: "user" | "bridge" | "none"
  hostfwd?: string      // 端口转发 如 "tcp::3389-:3389"
  
  // 高级选项
  enableKVM?: boolean   // 启用 KVM 加速
  machine?: string      // 机器类型 如 "q35"
  bios?: "seabios" | "uefi"
  extraArgs?: string    // 额外 QEMU 参数
}

// 运行中的 VM 实例
export interface VMInstance {
  id: string
  config: QemuConfig
  status: VMStatus
  pid?: number
  vncPort?: number
  startTime?: number
  error?: string
}

// 预设模板
export interface VMTemplate {
  id: string
  name: string
  description: string
  config: Partial<QemuConfig>
}

// 默认预设
export const defaultTemplates: VMTemplate[] = [
  {
    id: "win11",
    name: "Windows 11",
    description: "Windows 11 推荐配置",
    config: {
      cpu: 4,
      memory: 8192,
      display: "vnc",
      network: "user",
      enableKVM: true,
      machine: "q35",
      bios: "uefi",
      hostfwd: "tcp::3389-:3389,tcp::5900-:5900",
    },
  },
  {
    id: "win10",
    name: "Windows 10",
    description: "Windows 10 推荐配置",
    config: {
      cpu: 2,
      memory: 4096,
      display: "vnc",
      network: "user",
      enableKVM: true,
      machine: "q35",
      hostfwd: "tcp::3389-:3389",
    },
  },
  {
    id: "linux",
    name: "Linux",
    description: "通用 Linux 配置",
    config: {
      cpu: 2,
      memory: 2048,
      display: "vnc",
      network: "user",
      enableKVM: true,
      hostfwd: "tcp::2222-:22",
    },
  },
  {
    id: "minimal",
    name: "极简",
    description: "最小资源占用",
    config: {
      cpu: 1,
      memory: 1024,
      display: "vnc",
      network: "user",
      enableKVM: true,
    },
  },
]

// 生成 QEMU 命令行
export function generateQemuCommand(config: QemuConfig): string {
  const args: string[] = ["qemu-system-x86_64"]
  
  // CPU
  args.push(`-smp ${config.cpu}`)
  if (config.enableKVM) {
    args.push("-enable-kvm")
    args.push("-cpu host")
  }
  
  // 内存
  args.push(`-m ${config.memory}`)
  
  // 机器类型
  if (config.machine) {
    args.push(`-machine ${config.machine}`)
  }
  
  // BIOS
  if (config.bios === "uefi") {
    args.push("-bios /usr/share/OVMF/OVMF_CODE.fd")
  }
  
  // 磁盘
  args.push(`-drive file=${config.diskPath},format=qcow2,if=virtio`)
  
  // CD-ROM
  if (config.cdrom) {
    args.push(`-cdrom ${config.cdrom}`)
    args.push("-boot d")
  }
  
  // 显示
  if (config.display === "vnc") {
    const port = config.vncPort ?? 0
    args.push(`-vnc :${port}`)
  } else if (config.display === "spice") {
    args.push("-spice port=5930,disable-ticketing=on")
  } else {
    args.push("-display none")
  }
  
  // 网络
  if (config.network === "user") {
    let netdev = "-netdev user,id=net0"
    if (config.hostfwd) {
      netdev += `,${config.hostfwd.split(",").map(p => `hostfwd=${p}`).join(",")}`
    }
    args.push(netdev)
    args.push("-device virtio-net-pci,netdev=net0")
  } else if (config.network === "bridge") {
    args.push("-netdev bridge,id=net0,br=br0")
    args.push("-device virtio-net-pci,netdev=net0")
  }
  
  // 额外参数
  if (config.extraArgs) {
    args.push(config.extraArgs)
  }
  
  return args.join(" \\\n  ")
}
