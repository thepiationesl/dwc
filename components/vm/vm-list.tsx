"use client"

import type { VM } from "@/types/vm"
import { Play, Square, RotateCcw } from "lucide-react"

interface VMListProps {
  vms: VM[]
  selectedVM: VM | null
  onSelect: (vm: VM) => void
  onAction: (vmId: string, action: "start" | "stop" | "restart") => void
}

export function VMList({ vms, selectedVM, onSelect, onAction }: VMListProps) {
  return (
    <div className="rounded-lg border border-border bg-card">
      <div className="border-b border-border px-4 py-2">
        <div className="grid grid-cols-[auto_1fr_80px_80px_100px_120px] gap-4 text-xs font-medium text-muted-foreground">
          <span className="w-2" />
          <span>名称</span>
          <span>CPU</span>
          <span>内存</span>
          <span>磁盘</span>
          <span>操作</span>
        </div>
      </div>
      <div className="divide-y divide-border">
        {vms.map((vm) => (
          <div
            key={vm.id}
            onClick={() => onSelect(vm)}
            className={`grid cursor-pointer grid-cols-[auto_1fr_80px_80px_100px_120px] items-center gap-4 px-4 py-3 transition-colors hover:bg-muted/50 ${
              selectedVM?.id === vm.id ? "bg-muted/70" : ""
            }`}
          >
            {/* 状态指示灯 */}
            <span
              className={`h-2 w-2 rounded-full ${
                vm.status === "running"
                  ? "bg-green-500"
                  : vm.status === "error"
                    ? "bg-red-500"
                    : "bg-muted-foreground/30"
              }`}
            />
            {/* 名称 */}
            <div>
              <p className="text-sm font-medium text-foreground">{vm.name}</p>
              <p className="text-xs text-muted-foreground">{vm.image}:{vm.tag}</p>
            </div>
            {/* CPU */}
            <span className="text-sm text-muted-foreground">{vm.cpu} 核</span>
            {/* 内存 */}
            <span className="text-sm text-muted-foreground">
              {vm.memory >= 1024 ? `${vm.memory / 1024}G` : `${vm.memory}M`}
            </span>
            {/* 磁盘 */}
            <span className="text-sm text-muted-foreground">{vm.disk}</span>
            {/* 操作按钮 */}
            <div className="flex gap-1">
              {vm.status === "stopped" ? (
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    onAction(vm.id, "start")
                  }}
                  className="rounded p-1.5 text-green-500 hover:bg-green-500/10"
                  title="启动"
                >
                  <Play className="h-4 w-4" />
                </button>
              ) : (
                <>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onAction(vm.id, "stop")
                    }}
                    className="rounded p-1.5 text-red-500 hover:bg-red-500/10"
                    title="停止"
                  >
                    <Square className="h-4 w-4" />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onAction(vm.id, "restart")
                    }}
                    className="rounded p-1.5 text-yellow-500 hover:bg-yellow-500/10"
                    title="重启"
                  >
                    <RotateCcw className="h-4 w-4" />
                  </button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>
      {vms.length === 0 && (
        <div className="px-4 py-8 text-center text-sm text-muted-foreground">
          暂无虚拟机
        </div>
      )}
    </div>
  )
}
