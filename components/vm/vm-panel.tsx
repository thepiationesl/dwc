"use client"

import type { VMInstance } from "@/types/vm"
import {
  Play,
  Square,
  Copy,
  Trash2,
  Terminal,
  Cpu,
  HardDrive,
  Network,
  Monitor,
} from "lucide-react"

interface VMPanelProps {
  vm: VMInstance
  onStart: () => void
  onStop: () => void
  onDelete: () => void
  onDuplicate: () => void
  onPreviewCommand: () => void
}

export function VMPanel({
  vm,
  onStart,
  onStop,
  onDelete,
  onDuplicate,
  onPreviewCommand,
}: VMPanelProps) {
  const { config, status } = vm
  const isRunning = status === "running"
  const isStarting = status === "starting"

  return (
    <div className="space-y-4">
      {/* 顶部操作栏 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-foreground">{config.name}</h2>
          <p className="text-sm text-muted-foreground">
            {isRunning ? (
              <span className="text-green-500">运行中</span>
            ) : isStarting ? (
              <span className="text-yellow-500">启动中...</span>
            ) : status === "error" ? (
              <span className="text-red-500">错误</span>
            ) : (
              <span>已停止</span>
            )}
            {vm.vncPort && isRunning && (
              <span className="ml-2 text-muted-foreground">
                VNC ::{vm.vncPort}
              </span>
            )}
          </p>
        </div>

        <div className="flex gap-2">
          {status === "stopped" ? (
            <button
              onClick={onStart}
              className="flex items-center gap-1.5 rounded-md bg-green-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-green-700"
            >
              <Play className="h-4 w-4" />
              启动
            </button>
          ) : isRunning ? (
            <button
              onClick={onStop}
              className="flex items-center gap-1.5 rounded-md bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-700"
            >
              <Square className="h-4 w-4" />
              停止
            </button>
          ) : null}

          <button
            onClick={onPreviewCommand}
            className="flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted"
          >
            <Terminal className="h-4 w-4" />
            查看命令
          </button>

          <button
            onClick={onDuplicate}
            className="rounded-md border border-border p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
            title="复制"
          >
            <Copy className="h-4 w-4" />
          </button>

          <button
            onClick={onDelete}
            disabled={isRunning}
            className="rounded-md border border-border p-1.5 text-muted-foreground hover:bg-red-500/10 hover:text-red-500 disabled:cursor-not-allowed disabled:opacity-50"
            title="删除"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* 配置信息 */}
      <div className="grid gap-4 md:grid-cols-2">
        {/* 计算资源 */}
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-3 flex items-center gap-2 text-sm font-medium text-foreground">
            <Cpu className="h-4 w-4 text-primary" />
            计算资源
          </div>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-muted-foreground">CPU</dt>
              <dd className="font-mono text-foreground">{config.cpu} 核</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">内存</dt>
              <dd className="font-mono text-foreground">
                {config.memory >= 1024 ? `${config.memory / 1024} GB` : `${config.memory} MB`}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">KVM 加速</dt>
              <dd className="text-foreground">{config.enableKVM ? "已启用" : "未启用"}</dd>
            </div>
            {config.machine && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">机器类型</dt>
                <dd className="font-mono text-foreground">{config.machine}</dd>
              </div>
            )}
          </dl>
        </div>

        {/* 存储 */}
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-3 flex items-center gap-2 text-sm font-medium text-foreground">
            <HardDrive className="h-4 w-4 text-primary" />
            存储
          </div>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-muted-foreground">磁盘</dt>
              <dd className="truncate font-mono text-foreground max-w-[200px]" title={config.diskPath}>
                {config.diskPath}
              </dd>
            </div>
            {config.diskSize && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">大小</dt>
                <dd className="font-mono text-foreground">{config.diskSize}</dd>
              </div>
            )}
            {config.cdrom && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">ISO</dt>
                <dd className="truncate font-mono text-foreground max-w-[200px]" title={config.cdrom}>
                  {config.cdrom.split("/").pop()}
                </dd>
              </div>
            )}
            <div className="flex justify-between">
              <dt className="text-muted-foreground">BIOS</dt>
              <dd className="text-foreground">{config.bios === "uefi" ? "UEFI" : "SeaBIOS"}</dd>
            </div>
          </dl>
        </div>

        {/* 显示 */}
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-3 flex items-center gap-2 text-sm font-medium text-foreground">
            <Monitor className="h-4 w-4 text-primary" />
            显示
          </div>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-muted-foreground">类型</dt>
              <dd className="font-mono text-foreground uppercase">{config.display}</dd>
            </div>
            {config.display === "vnc" && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">VNC 端口</dt>
                <dd className="font-mono text-foreground">
                  :{config.vncPort ?? 0} (5900+)
                </dd>
              </div>
            )}
          </dl>
        </div>

        {/* 网络 */}
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-3 flex items-center gap-2 text-sm font-medium text-foreground">
            <Network className="h-4 w-4 text-primary" />
            网络
          </div>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-muted-foreground">模式</dt>
              <dd className="text-foreground">
                {config.network === "user" ? "NAT (用户模式)" : 
                 config.network === "bridge" ? "桥接" : "无网络"}
              </dd>
            </div>
            {config.hostfwd && (
              <div>
                <dt className="text-muted-foreground mb-1">端口转发</dt>
                <dd className="font-mono text-xs text-foreground bg-muted rounded px-2 py-1">
                  {config.hostfwd}
                </dd>
              </div>
            )}
          </dl>
        </div>
      </div>

      {/* 额外参数 */}
      {config.extraArgs && (
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-2 text-sm font-medium text-foreground">额外参数</div>
          <pre className="text-xs font-mono text-muted-foreground bg-muted rounded p-2 overflow-x-auto">
            {config.extraArgs}
          </pre>
        </div>
      )}
    </div>
  )
}
