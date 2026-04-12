"use client"

import { useState } from "react"
import type { QemuConfig } from "@/types/vm"
import { defaultTemplates } from "@/types/vm"
import { X } from "lucide-react"

interface CreateVMDialogProps {
  onClose: () => void
  onCreate: (config: QemuConfig) => void
}

export function CreateVMDialog({ onClose, onCreate }: CreateVMDialogProps) {
  const [step, setStep] = useState<"template" | "config">("template")
  const [config, setConfig] = useState<QemuConfig>({
    name: "",
    cpu: 2,
    memory: 4096,
    diskPath: "",
    display: "vnc",
    network: "user",
    enableKVM: true,
  })

  const handleTemplateSelect = (templateId: string) => {
    const template = defaultTemplates.find((t) => t.id === templateId)
    if (template) {
      setConfig((prev) => ({
        ...prev,
        ...template.config,
        name: template.name,
      }))
      setStep("config")
    }
  }

  const handleSubmit = () => {
    if (!config.name.trim() || !config.diskPath.trim()) {
      return
    }
    onCreate(config)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-lg rounded-lg border border-border bg-card shadow-xl">
        {/* 标题栏 */}
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h3 className="font-semibold text-foreground">
            {step === "template" ? "选择模板" : "配置虚拟机"}
          </h3>
          <button
            onClick={onClose}
            className="rounded p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="p-4">
          {step === "template" ? (
            /* 模板选择 */
            <div className="grid gap-2">
              {defaultTemplates.map((template) => (
                <button
                  key={template.id}
                  onClick={() => handleTemplateSelect(template.id)}
                  className="flex items-center justify-between rounded-md border border-border p-3 text-left transition-colors hover:bg-muted"
                >
                  <div>
                    <p className="font-medium text-foreground">{template.name}</p>
                    <p className="text-sm text-muted-foreground">
                      {template.description}
                    </p>
                  </div>
                  <div className="text-right text-xs text-muted-foreground">
                    <p>{template.config.cpu} CPU</p>
                    <p>
                      {(template.config.memory ?? 0) >= 1024
                        ? `${(template.config.memory ?? 0) / 1024}G`
                        : `${template.config.memory ?? 0}M`} RAM
                    </p>
                  </div>
                </button>
              ))}
              <button
                onClick={() => setStep("config")}
                className="rounded-md border border-dashed border-border p-3 text-center text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              >
                自定义配置
              </button>
            </div>
          ) : (
            /* 配置表单 */
            <div className="space-y-4">
              {/* 名称 */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  名称 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={config.name}
                  onChange={(e) => setConfig((p) => ({ ...p, name: e.target.value }))}
                  placeholder="如: Windows 11"
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                />
              </div>

              {/* CPU 和内存 */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    CPU 核心
                  </label>
                  <select
                    value={config.cpu}
                    onChange={(e) => setConfig((p) => ({ ...p, cpu: Number(e.target.value) }))}
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    {[1, 2, 4, 8, 16].map((n) => (
                      <option key={n} value={n}>{n} 核</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    内存
                  </label>
                  <select
                    value={config.memory}
                    onChange={(e) => setConfig((p) => ({ ...p, memory: Number(e.target.value) }))}
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    {[1024, 2048, 4096, 8192, 16384, 32768].map((m) => (
                      <option key={m} value={m}>
                        {m >= 1024 ? `${m / 1024} GB` : `${m} MB`}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* 磁盘路径 */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  磁盘镜像路径 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={config.diskPath}
                  onChange={(e) => setConfig((p) => ({ ...p, diskPath: e.target.value }))}
                  placeholder="/path/to/disk.qcow2"
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                />
              </div>

              {/* ISO */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  ISO 镜像 (可选)
                </label>
                <input
                  type="text"
                  value={config.cdrom ?? ""}
                  onChange={(e) => setConfig((p) => ({ ...p, cdrom: e.target.value || undefined }))}
                  placeholder="/path/to/install.iso"
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                />
              </div>

              {/* 显示和网络 */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    显示
                  </label>
                  <select
                    value={config.display}
                    onChange={(e) => setConfig((p) => ({ ...p, display: e.target.value as QemuConfig["display"] }))}
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    <option value="vnc">VNC</option>
                    <option value="spice">SPICE</option>
                    <option value="none">无</option>
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    网络
                  </label>
                  <select
                    value={config.network}
                    onChange={(e) => setConfig((p) => ({ ...p, network: e.target.value as QemuConfig["network"] }))}
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    <option value="user">NAT (用户模式)</option>
                    <option value="bridge">桥接</option>
                    <option value="none">无网络</option>
                  </select>
                </div>
              </div>

              {/* 端口转发 */}
              {config.network === "user" && (
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    端口转发
                  </label>
                  <input
                    type="text"
                    value={config.hostfwd ?? ""}
                    onChange={(e) => setConfig((p) => ({ ...p, hostfwd: e.target.value || undefined }))}
                    placeholder="tcp::3389-:3389,tcp::22-:22"
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                  />
                  <p className="mt-1 text-xs text-muted-foreground">
                    格式: tcp::主机端口-:客户端口
                  </p>
                </div>
              )}

              {/* 高级选项 */}
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.enableKVM}
                    onChange={(e) => setConfig((p) => ({ ...p, enableKVM: e.target.checked }))}
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">启用 KVM 加速</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.bios === "uefi"}
                    onChange={(e) => setConfig((p) => ({ ...p, bios: e.target.checked ? "uefi" : "seabios" }))}
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">使用 UEFI</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.machine === "q35"}
                    onChange={(e) => setConfig((p) => ({ ...p, machine: e.target.checked ? "q35" : undefined }))}
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">Q35 芯片组</span>
                </label>
              </div>

              {/* 额外参数 */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  额外 QEMU 参数
                </label>
                <input
                  type="text"
                  value={config.extraArgs ?? ""}
                  onChange={(e) => setConfig((p) => ({ ...p, extraArgs: e.target.value || undefined }))}
                  placeholder="-device usb-tablet"
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                />
              </div>
            </div>
          )}
        </div>

        {/* 底部按钮 */}
        <div className="flex justify-end gap-2 border-t border-border px-4 py-3">
          {step === "config" && (
            <button
              onClick={() => setStep("template")}
              className="rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted"
            >
              返回
            </button>
          )}
          <button
            onClick={onClose}
            className="rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted"
          >
            取消
          </button>
          {step === "config" && (
            <button
              onClick={handleSubmit}
              disabled={!config.name.trim() || !config.diskPath.trim()}
              className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
            >
              创建
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
