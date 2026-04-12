"use client"

import { useState } from "react"
import type { VMConfig, PortForward } from "@/types/vm"
import { defaultTemplates } from "@/types/vm"
import { X, Plus, Trash2 } from "lucide-react"

type VMFormData = Omit<VMConfig, "id" | "createdAt">

interface CreateVMDialogProps {
  onClose: () => void
  onCreate: (config: VMFormData) => void
}

export function CreateVMDialog({ onClose, onCreate }: CreateVMDialogProps) {
  const [step, setStep] = useState<"template" | "config">("template")
  const [config, setConfig] = useState<VMFormData>({
    name: "",
    cpu: { cores: 2, model: "host" },
    memory: 4096,
    disk: { path: "", size: "32G", format: "qcow2" },
    display: { type: "vnc", port: 5900 },
    network: { type: "user", hostfwd: [] },
    kvm: true,
    uefi: false,
    q35: false,
    tpm: false,
  })

  const handleTemplateSelect = (templateId: string) => {
    const template = defaultTemplates.find((t) => t.id === templateId)
    if (template) {
      setConfig((prev) => ({
        ...prev,
        ...template.config,
        name: template.name,
        cpu: { ...prev.cpu, ...template.config.cpu },
        disk: { ...prev.disk, ...template.config.disk },
        display: { ...prev.display, ...template.config.display },
        network: { ...prev.network, ...template.config.network },
      }))
      setStep("config")
    }
  }

  const handleSubmit = () => {
    if (!config.name.trim() || !config.disk.path.trim()) {
      return
    }
    onCreate(config)
  }

  const addPortForward = () => {
    setConfig((prev) => ({
      ...prev,
      network: {
        ...prev.network,
        hostfwd: [
          ...(prev.network.hostfwd || []),
          { protocol: "tcp", hostPort: 3389, guestPort: 3389 },
        ],
      },
    }))
  }

  const removePortForward = (index: number) => {
    setConfig((prev) => ({
      ...prev,
      network: {
        ...prev.network,
        hostfwd: prev.network.hostfwd?.filter((_, i) => i !== index),
      },
    }))
  }

  const updatePortForward = (index: number, field: keyof PortForward, value: string | number) => {
    setConfig((prev) => ({
      ...prev,
      network: {
        ...prev.network,
        hostfwd: prev.network.hostfwd?.map((fwd, i) =>
          i === index ? { ...fwd, [field]: value } : fwd
        ),
      },
    }))
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-lg max-h-[90vh] overflow-hidden rounded-lg border border-border bg-card shadow-xl flex flex-col">
        {/* 标题栏 */}
        <div className="flex items-center justify-between border-b border-border px-4 py-3 shrink-0">
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

        <div className="p-4 overflow-y-auto flex-1">
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
                    <p>{template.config.cpu?.cores} CPU</p>
                    <p>
                      {(template.config.memory ?? 0) >= 1024
                        ? `${(template.config.memory ?? 0) / 1024}G`
                        : `${template.config.memory ?? 0}M`}{" "}
                      RAM
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

              {/* CPU */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    CPU 核心
                  </label>
                  <select
                    value={config.cpu.cores}
                    onChange={(e) =>
                      setConfig((p) => ({
                        ...p,
                        cpu: { ...p.cpu, cores: Number(e.target.value) },
                      }))
                    }
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    {[1, 2, 4, 8, 16].map((n) => (
                      <option key={n} value={n}>
                        {n} 核
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    内存
                  </label>
                  <select
                    value={config.memory}
                    onChange={(e) =>
                      setConfig((p) => ({ ...p, memory: Number(e.target.value) }))
                    }
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

              {/* 磁盘 */}
              <div className="grid grid-cols-3 gap-4">
                <div className="col-span-2">
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    磁盘镜像路径 <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={config.disk.path}
                    onChange={(e) =>
                      setConfig((p) => ({
                        ...p,
                        disk: { ...p.disk, path: e.target.value },
                      }))
                    }
                    placeholder="/path/to/disk.qcow2"
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    大小
                  </label>
                  <select
                    value={config.disk.size}
                    onChange={(e) =>
                      setConfig((p) => ({
                        ...p,
                        disk: { ...p.disk, size: e.target.value },
                      }))
                    }
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    {["16G", "32G", "64G", "128G", "256G"].map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* ISO */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  ISO 镜像 (可选)
                </label>
                <input
                  type="text"
                  value={config.iso ?? ""}
                  onChange={(e) =>
                    setConfig((p) => ({ ...p, iso: e.target.value || undefined }))
                  }
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
                    value={config.display.type}
                    onChange={(e) =>
                      setConfig((p) => ({
                        ...p,
                        display: {
                          ...p.display,
                          type: e.target.value as "vnc" | "spice" | "none",
                        },
                      }))
                    }
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                  >
                    <option value="vnc">VNC</option>
                    <option value="spice">SPICE</option>
                    <option value="none">无</option>
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-foreground">
                    VNC 端口
                  </label>
                  <input
                    type="number"
                    value={config.display.port || 5900}
                    onChange={(e) =>
                      setConfig((p) => ({
                        ...p,
                        display: { ...p.display, port: Number(e.target.value) },
                      }))
                    }
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground focus:border-primary focus:outline-none"
                  />
                </div>
              </div>

              {/* 网络模式 */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  网络模式
                </label>
                <select
                  value={config.network.type}
                  onChange={(e) =>
                    setConfig((p) => ({
                      ...p,
                      network: {
                        ...p.network,
                        type: e.target.value as "user" | "bridge" | "none",
                      },
                    }))
                  }
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:border-primary focus:outline-none"
                >
                  <option value="user">NAT (用户模式)</option>
                  <option value="bridge">桥接</option>
                  <option value="none">无网络</option>
                </select>
              </div>

              {/* 端口转发 */}
              {config.network.type === "user" && (
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-medium text-foreground">
                      端口转发
                    </label>
                    <button
                      type="button"
                      onClick={addPortForward}
                      className="flex items-center gap-1 text-xs text-primary hover:underline"
                    >
                      <Plus className="h-3 w-3" />
                      添加
                    </button>
                  </div>
                  <div className="space-y-2">
                    {config.network.hostfwd?.map((fwd, i) => (
                      <div key={i} className="flex items-center gap-2">
                        <select
                          value={fwd.protocol}
                          onChange={(e) =>
                            updatePortForward(i, "protocol", e.target.value)
                          }
                          className="rounded-md border border-input bg-background px-2 py-1.5 text-sm text-foreground focus:border-primary focus:outline-none"
                        >
                          <option value="tcp">TCP</option>
                          <option value="udp">UDP</option>
                        </select>
                        <input
                          type="number"
                          value={fwd.hostPort}
                          onChange={(e) =>
                            updatePortForward(i, "hostPort", Number(e.target.value))
                          }
                          placeholder="主机端口"
                          className="w-20 rounded-md border border-input bg-background px-2 py-1.5 text-sm font-mono text-foreground focus:border-primary focus:outline-none"
                        />
                        <span className="text-muted-foreground">:</span>
                        <input
                          type="number"
                          value={fwd.guestPort}
                          onChange={(e) =>
                            updatePortForward(i, "guestPort", Number(e.target.value))
                          }
                          placeholder="客户端口"
                          className="w-20 rounded-md border border-input bg-background px-2 py-1.5 text-sm font-mono text-foreground focus:border-primary focus:outline-none"
                        />
                        <button
                          type="button"
                          onClick={() => removePortForward(i)}
                          className="p-1 text-muted-foreground hover:text-red-500"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                    {(!config.network.hostfwd || config.network.hostfwd.length === 0) && (
                      <p className="text-xs text-muted-foreground">暂无端口转发规则</p>
                    )}
                  </div>
                </div>
              )}

              {/* 高级选项 */}
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.kvm}
                    onChange={(e) =>
                      setConfig((p) => ({ ...p, kvm: e.target.checked }))
                    }
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">启用 KVM 加速</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.uefi}
                    onChange={(e) =>
                      setConfig((p) => ({ ...p, uefi: e.target.checked }))
                    }
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">使用 UEFI</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.q35}
                    onChange={(e) =>
                      setConfig((p) => ({ ...p, q35: e.target.checked }))
                    }
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">Q35 芯片组</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={config.tpm}
                    onChange={(e) =>
                      setConfig((p) => ({ ...p, tpm: e.target.checked }))
                    }
                    className="rounded border-input"
                  />
                  <span className="text-sm text-foreground">TPM 2.0 (需要 swtpm)</span>
                </label>
              </div>

              {/* 额外参数 */}
              <div>
                <label className="mb-1 block text-sm font-medium text-foreground">
                  额外 QEMU 参数
                </label>
                <input
                  type="text"
                  value={config.extra ?? ""}
                  onChange={(e) =>
                    setConfig((p) => ({ ...p, extra: e.target.value || undefined }))
                  }
                  placeholder="-device usb-tablet"
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
                />
              </div>
            </div>
          )}
        </div>

        {/* 底部按钮 */}
        <div className="flex justify-end gap-2 border-t border-border px-4 py-3 shrink-0">
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
              disabled={!config.name.trim() || !config.disk.path.trim()}
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
