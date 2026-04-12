import type { VM } from "@/types/vm"
import { Monitor, Cpu, HardDrive, MemoryStick } from "lucide-react"

interface VMStatusProps {
  vm: VM | null
}

const statusMap: Record<string, { label: string; color: string }> = {
  running: { label: "运行中", color: "text-green-500" },
  stopped: { label: "已停止", color: "text-muted-foreground" },
  paused: { label: "已暂停", color: "text-yellow-500" },
  error: { label: "错误", color: "text-red-500" },
}

export function VMStatus({ vm }: VMStatusProps) {
  if (!vm) {
    return (
      <div className="rounded-lg border border-border bg-card p-4">
        <p className="text-sm text-muted-foreground">选择一个虚拟机查看详情</p>
      </div>
    )
  }

  const status = statusMap[vm.status] || statusMap.stopped

  return (
    <div className="rounded-lg border border-border bg-card p-4">
      <div className="mb-3 flex items-center justify-between">
        <h3 className="font-medium text-foreground">{vm.name}</h3>
        <span className={`text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </div>
      <div className="space-y-2 text-sm">
        <div className="flex items-center gap-2 text-muted-foreground">
          <Monitor className="h-4 w-4" />
          <span>镜像: {vm.image}:{vm.tag || "latest"}</span>
        </div>
        <div className="flex items-center gap-2 text-muted-foreground">
          <Cpu className="h-4 w-4" />
          <span>CPU: {vm.cpu} 核</span>
        </div>
        <div className="flex items-center gap-2 text-muted-foreground">
          <MemoryStick className="h-4 w-4" />
          <span>内存: {vm.memory >= 1024 ? `${vm.memory / 1024}G` : `${vm.memory}M`}</span>
        </div>
        <div className="flex items-center gap-2 text-muted-foreground">
          <HardDrive className="h-4 w-4" />
          <span>磁盘: {vm.disk}</span>
        </div>
        {vm.ip && (
          <div className="mt-2 rounded bg-muted px-2 py-1 font-mono text-xs">
            {vm.ip}:{vm.port || 3389}
          </div>
        )}
      </div>
    </div>
  )
}
