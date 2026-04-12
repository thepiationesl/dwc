"use client"

import type { VM } from "@/types/vm"
import { Play, Square, RotateCcw, Terminal } from "lucide-react"

interface VMControlsProps {
  vm: VM | null
  onAction: (vmId: string, action: "start" | "stop" | "restart") => void
}

export function VMControls({ vm, onAction }: VMControlsProps) {
  if (!vm) {
    return null
  }

  const isRunning = vm.status === "running"

  return (
    <div className="rounded-lg border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-medium text-foreground">控制面板</h3>
      <div className="grid grid-cols-2 gap-2">
        {isRunning ? (
          <>
            <button
              onClick={() => onAction(vm.id, "stop")}
              className="flex items-center justify-center gap-2 rounded-md bg-red-500/10 px-3 py-2 text-sm font-medium text-red-500 transition-colors hover:bg-red-500/20"
            >
              <Square className="h-4 w-4" />
              停止
            </button>
            <button
              onClick={() => onAction(vm.id, "restart")}
              className="flex items-center justify-center gap-2 rounded-md bg-yellow-500/10 px-3 py-2 text-sm font-medium text-yellow-500 transition-colors hover:bg-yellow-500/20"
            >
              <RotateCcw className="h-4 w-4" />
              重启
            </button>
            <button
              className="col-span-2 flex items-center justify-center gap-2 rounded-md bg-primary/10 px-3 py-2 text-sm font-medium text-primary transition-colors hover:bg-primary/20"
              onClick={() => {
                // 打开 VNC/RDP 连接
                window.open(`/vm/${vm.id}/console`, "_blank")
              }}
            >
              <Terminal className="h-4 w-4" />
              控制台
            </button>
          </>
        ) : (
          <button
            onClick={() => onAction(vm.id, "start")}
            className="col-span-2 flex items-center justify-center gap-2 rounded-md bg-green-500/10 px-3 py-2 text-sm font-medium text-green-500 transition-colors hover:bg-green-500/20"
          >
            <Play className="h-4 w-4" />
            启动
          </button>
        )}
      </div>

      {/* Docker 命令提示 - 针对 dockur 用户 */}
      <div className="mt-4 rounded bg-muted p-2">
        <p className="mb-1 text-xs text-muted-foreground">Docker 命令</p>
        <code className="block overflow-x-auto whitespace-pre text-xs text-foreground">
          docker run -d \{"\n"}
          {"  "}--name {vm.id} \{"\n"}
          {"  "}-e RAM_SIZE=&quot;{vm.memory >= 1024 ? `${vm.memory / 1024}G` : `${vm.memory}M`}&quot; \{"\n"}
          {"  "}-e CPU_CORES=&quot;{vm.cpu}&quot; \{"\n"}
          {"  "}-e DISK_SIZE=&quot;{vm.disk}&quot; \{"\n"}
          {"  "}-p 8006:8006 \{"\n"}
          {"  "}-v /mnt/win:/storage \{"\n"}
          {"  "}{vm.image}:{vm.tag || "latest"}
        </code>
      </div>
    </div>
  )
}
