"use client"

import type { VMConfig, VMStatus } from "@/types/vm"
import { Monitor, Play, Square, Loader2 } from "lucide-react"

interface VMWithStatus extends VMConfig {
  status: VMStatus
}

interface VMSidebarProps {
  vms: VMWithStatus[]
  selectedId: string | null
  onSelect: (id: string) => void
  onStart: (id: string) => void
  onStop: (id: string) => void
  loading?: Record<string, boolean>
}

export function VMSidebar({
  vms,
  selectedId,
  onSelect,
  onStart,
  onStop,
  loading = {},
}: VMSidebarProps) {
  const runningCount = vms.filter((v) => v.status.running).length

  return (
    <aside className="w-64 border-r border-border bg-card flex flex-col">
      {/* 标题 */}
      <div className="border-b border-border px-4 py-3">
        <div className="flex items-center gap-2">
          <Monitor className="h-5 w-5 text-primary" />
          <span className="font-semibold text-foreground">虚拟机</span>
          <span className="ml-auto text-xs text-muted-foreground">
            {runningCount}/{vms.length}
          </span>
        </div>
      </div>

      {/* VM 列表 */}
      <div className="flex-1 overflow-auto">
        {vms.length === 0 ? (
          <div className="p-4 text-center text-sm text-muted-foreground">
            暂无虚拟机
          </div>
        ) : (
          <ul className="divide-y divide-border">
            {vms.map((vm) => {
              const isLoading = loading[vm.id]
              return (
                <li
                  key={vm.id}
                  onClick={() => onSelect(vm.id)}
                  className={`cursor-pointer px-3 py-2 transition-colors hover:bg-muted/50 ${
                    selectedId === vm.id ? "bg-muted" : ""
                  }`}
                >
                  <div className="flex items-center gap-2">
                    {/* 状态指示 */}
                    <span
                      className={`h-2 w-2 shrink-0 rounded-full ${
                        isLoading
                          ? "bg-yellow-500 animate-pulse"
                          : vm.status.running
                          ? "bg-green-500"
                          : "bg-neutral-400"
                      }`}
                    />
                    {/* 名称 */}
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">
                        {vm.name}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {vm.cpu.cores}C /{" "}
                        {vm.memory >= 1024
                          ? `${vm.memory / 1024}G`
                          : `${vm.memory}M`}
                      </p>
                    </div>
                    {/* 快捷操作 */}
                    <div
                      className="flex shrink-0"
                      onClick={(e) => e.stopPropagation()}
                    >
                      {isLoading ? (
                        <span className="p-1">
                          <Loader2 className="h-3.5 w-3.5 animate-spin text-muted-foreground" />
                        </span>
                      ) : !vm.status.running ? (
                        <button
                          onClick={() => onStart(vm.id)}
                          className="rounded p-1 text-green-500 hover:bg-green-500/10"
                          title="启动"
                        >
                          <Play className="h-3.5 w-3.5" />
                        </button>
                      ) : (
                        <button
                          onClick={() => onStop(vm.id)}
                          className="rounded p-1 text-red-500 hover:bg-red-500/10"
                          title="停止"
                        >
                          <Square className="h-3.5 w-3.5" />
                        </button>
                      )}
                    </div>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </div>

      {/* 底部信息 */}
      <div className="border-t border-border px-4 py-2">
        <p className="text-xs text-muted-foreground">QEMU Launcher v0.1</p>
      </div>
    </aside>
  )
}
