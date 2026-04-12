"use client"

import { useState } from "react"
import { VMList } from "@/components/vm/vm-list"
import { VMControls } from "@/components/vm/vm-controls"
import { VMStatus } from "@/components/vm/vm-status"
import type { VM } from "@/types/vm"

// 模拟初始VM数据 - 实际使用时可连接到你的PVE或dockur后端
const initialVMs: VM[] = [
  {
    id: "win11",
    name: "Windows 11",
    status: "stopped",
    cpu: 4,
    memory: 8192,
    disk: "64G",
    image: "dockurr/windows",
    tag: "win11",
  },
  {
    id: "win10",
    name: "Windows 10",
    status: "stopped",
    cpu: 2,
    memory: 4096,
    disk: "32G",
    image: "dockurr/windows",
    tag: "win10",
  },
]

export default function VMPage() {
  const [vms, setVMs] = useState<VM[]>(initialVMs)
  const [selectedVM, setSelectedVM] = useState<VM | null>(null)

  const handleAction = (vmId: string, action: "start" | "stop" | "restart") => {
    setVMs((prev) =>
      prev.map((vm) => {
        if (vm.id !== vmId) return vm
        switch (action) {
          case "start":
            return { ...vm, status: "running" }
          case "stop":
            return { ...vm, status: "stopped" }
          case "restart":
            return { ...vm, status: "running" }
          default:
            return vm
        }
      })
    )
  }

  return (
    <div className="min-h-screen bg-background p-4 md:p-6">
      <header className="mb-6">
        <h1 className="text-xl font-semibold text-foreground">VM Manager</h1>
        <p className="text-sm text-muted-foreground">极简虚拟机管理 · PVE / dockur 风格</p>
      </header>

      <div className="grid gap-4 md:grid-cols-[1fr_300px]">
        <VMList
          vms={vms}
          selectedVM={selectedVM}
          onSelect={setSelectedVM}
          onAction={handleAction}
        />
        <aside className="space-y-4">
          <VMStatus vm={selectedVM} />
          <VMControls vm={selectedVM} onAction={handleAction} />
        </aside>
      </div>
    </div>
  )
}
