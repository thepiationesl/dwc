"use client"

import { useState } from "react"
import { VMSidebar } from "@/components/vm/vm-sidebar"
import { VMPanel } from "@/components/vm/vm-panel"
import { CreateVMDialog } from "@/components/vm/create-vm-dialog"
import { CommandPreview } from "@/components/vm/command-preview"
import type { VMInstance, QemuConfig } from "@/types/vm"
import { Plus } from "lucide-react"

export default function VMPage() {
  const [vms, setVMs] = useState<VMInstance[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [previewConfig, setPreviewConfig] = useState<QemuConfig | null>(null)

  const selectedVM = vms.find((vm) => vm.id === selectedId) ?? null

  // 创建新 VM
  const handleCreate = (config: QemuConfig) => {
    const newVM: VMInstance = {
      id: `vm-${Date.now()}`,
      config,
      status: "stopped",
    }
    setVMs((prev) => [...prev, newVM])
    setSelectedId(newVM.id)
    setShowCreate(false)
  }

  // 启动 VM (模拟)
  const handleStart = (id: string) => {
    setVMs((prev) =>
      prev.map((vm) =>
        vm.id === id
          ? { ...vm, status: "starting", startTime: Date.now() }
          : vm
      )
    )
    // 模拟启动延迟
    setTimeout(() => {
      setVMs((prev) =>
        prev.map((vm) =>
          vm.id === id
            ? { ...vm, status: "running", vncPort: 5900 + Math.floor(Math.random() * 100) }
            : vm
        )
      )
    }, 1500)
  }

  // 停止 VM
  const handleStop = (id: string) => {
    setVMs((prev) =>
      prev.map((vm) =>
        vm.id === id ? { ...vm, status: "stopped", pid: undefined } : vm
      )
    )
  }

  // 删除 VM
  const handleDelete = (id: string) => {
    setVMs((prev) => prev.filter((vm) => vm.id !== id))
    if (selectedId === id) {
      setSelectedId(null)
    }
  }

  // 复制配置
  const handleDuplicate = (id: string) => {
    const vm = vms.find((v) => v.id === id)
    if (vm) {
      const newVM: VMInstance = {
        id: `vm-${Date.now()}`,
        config: { ...vm.config, name: `${vm.config.name} (副本)` },
        status: "stopped",
      }
      setVMs((prev) => [...prev, newVM])
    }
  }

  return (
    <div className="flex h-screen bg-background">
      {/* 左侧边栏 - VM 列表 */}
      <VMSidebar
        vms={vms}
        selectedId={selectedId}
        onSelect={setSelectedId}
        onStart={handleStart}
        onStop={handleStop}
      />

      {/* 主内容区 */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* 顶部工具栏 */}
        <header className="flex items-center justify-between border-b border-border px-4 py-2">
          <div>
            <h1 className="text-lg font-semibold text-foreground">QEMU Launcher</h1>
            <p className="text-xs text-muted-foreground">
              极简 Web QEMU 启动器
            </p>
          </div>
          <button
            onClick={() => setShowCreate(true)}
            className="flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            <Plus className="h-4 w-4" />
            新建虚拟机
          </button>
        </header>

        {/* 内容区 */}
        <div className="flex-1 overflow-auto p-4">
          {selectedVM ? (
            <VMPanel
              vm={selectedVM}
              onStart={() => handleStart(selectedVM.id)}
              onStop={() => handleStop(selectedVM.id)}
              onDelete={() => handleDelete(selectedVM.id)}
              onDuplicate={() => handleDuplicate(selectedVM.id)}
              onPreviewCommand={() => setPreviewConfig(selectedVM.config)}
            />
          ) : (
            <div className="flex h-full items-center justify-center">
              <div className="text-center">
                <p className="text-muted-foreground">
                  {vms.length === 0
                    ? "暂无虚拟机，点击「新建虚拟机」开始"
                    : "选择一个虚拟机查看详情"}
                </p>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* 创建 VM 对话框 */}
      {showCreate && (
        <CreateVMDialog
          onClose={() => setShowCreate(false)}
          onCreate={handleCreate}
        />
      )}

      {/* 命令预览 */}
      {previewConfig && (
        <CommandPreview
          config={previewConfig}
          onClose={() => setPreviewConfig(null)}
        />
      )}
    </div>
  )
}
