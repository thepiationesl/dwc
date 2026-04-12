"use client"

import { useState } from "react"
import type { QemuConfig } from "@/types/vm"
import { generateQemuCommand } from "@/types/vm"
import { X, Copy, Check } from "lucide-react"

interface CommandPreviewProps {
  config: QemuConfig
  onClose: () => void
}

export function CommandPreview({ config, onClose }: CommandPreviewProps) {
  const [copied, setCopied] = useState(false)
  const command = generateQemuCommand(config)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(command.replace(/\\\n\s*/g, " "))
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-2xl rounded-lg border border-border bg-card shadow-xl">
        {/* 标题栏 */}
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h3 className="font-semibold text-foreground">QEMU 启动命令</h3>
          <button
            onClick={onClose}
            className="rounded p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="p-4">
          {/* 命令预览 */}
          <div className="relative">
            <pre className="overflow-x-auto rounded-md bg-neutral-900 p-4 text-sm text-green-400 font-mono">
              {command}
            </pre>
            <button
              onClick={handleCopy}
              className="absolute right-2 top-2 rounded p-1.5 text-neutral-400 hover:bg-neutral-800 hover:text-neutral-200"
              title="复制命令"
            >
              {copied ? (
                <Check className="h-4 w-4 text-green-500" />
              ) : (
                <Copy className="h-4 w-4" />
              )}
            </button>
          </div>

          {/* 说明 */}
          <div className="mt-4 rounded-md bg-muted p-3 text-sm text-muted-foreground">
            <p className="font-medium text-foreground mb-1">使用说明</p>
            <ul className="list-disc list-inside space-y-1 text-xs">
              <li>确保已安装 qemu-system-x86_64</li>
              <li>KVM 加速需要 CPU 支持并启用虚拟化</li>
              <li>UEFI 需要安装 OVMF 固件包</li>
              <li>VNC 端口 :0 对应 5900，:1 对应 5901，以此类推</li>
            </ul>
          </div>
        </div>

        {/* 底部按钮 */}
        <div className="flex justify-end gap-2 border-t border-border px-4 py-3">
          <button
            onClick={handleCopy}
            className="flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            {copied ? (
              <>
                <Check className="h-4 w-4" />
                已复制
              </>
            ) : (
              <>
                <Copy className="h-4 w-4" />
                复制命令
              </>
            )}
          </button>
          <button
            onClick={onClose}
            className="rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted"
          >
            关闭
          </button>
        </div>
      </div>
    </div>
  )
}
