"use client"

import type { VMInstance } from "@/types/vm"
import { Monitor, Play, Square } from "lucide-react"

interface VMSidebarProps {
  vms: VMInstance[]
  selectedId: string | null
  onSelect: (id: string) => void
  onStart: (id: string) => void
  onStop: (id: string) => void
}

const statusColors: Record<string, string> = {
  running: "bg-green-500",
  stopped: "bg-neutral-400",
  starting: "bg-yellow-500 animate-pulse",
  error: "bg-red-500",
}

export function VMSidebar({
  vms,
  selectedId,
  onSelect,
  onStart,
  onStop,
}: VMSidebarProps) {
  return (
    <aside className="w-64 border-r border-border bg-card flex flex-col">
      {/* 标题 */}
      <div className="border-b border-border px-4 py-3">
        <div className="flex items-center gap-2">
          <Monitor className="h-5 w-5 text-primary" />
          <span className="font-semibold text-foreground">虚拟机</span>
          <span className="ml-auto text-xs text-muted-foreground">
            {vms.filter((v) => v.status === "running").length}/{vms.length}
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
            {vms.map((vm) => (
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
                    className={`h-2 w-2 shrink-0 rounded-full ${statusColors[vm.status]}`}
                  />
                  {/* 名称 */}
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-foreground">
                      {vm.config.name}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {vm.config.cpu}C / {vm.config.memory >= 1024 ? `${vm.config.memory / 1024}G` : `${vm.config.memory}M`}
                    </p>
                  </div>
                  {/* 快捷操作 */}
                  <div
                    className="flex shrink-0"
                    onClick={(e) => e.stopPropagation()}
                  >
                    {vm.status === "stopped" ? (
                      <button
                        onClick={() => onStart(vm.id)}
                        className="rounded p-1 text-green-500 hover:bg-green-500/10"
                        title="启动"
                      >
                        <Play className="h-3.5 w-3.5" />
                      </button>
                    ) : vm.status === "running" ? (
                      <button
                        onClick={() => onStop(vm.id)}
                        className="rounded p-1 text-red-500 hover:bg-red-500/10"
                        title="停止"
                      >
                        <Square className="h-3.5 w-3.5" />
                      </button>
                    ) : null}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* 底部信息 */}
      <div className="border-t border-border px-4 py-2">
        <p className="text-xs text-muted-foreground">
          QEMU Web Launcher v0.1
        </p>
      </div>
    </aside>
  )
}
