"use client"

import type { VMConfig, VMStatus } from "@/types/vm"
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
  RotateCcw,
  Loader2,
  Clock,
} from "lucide-react"

interface VMWithStatus extends VMConfig {
  status: VMStatus
}

interface VMPanelProps {
  vm: VMWithStatus
  onStart: () => void
  onStop: () => void
  onReset: () => void
  onDelete: () => void
  onDuplicate: () => void
  onPreviewCommand: () => void
  loading?: boolean
}

function formatUptime(seconds: number): string {
  if (seconds < 60) return `${seconds}s`
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return `${h}h ${m}m`
}

export function VMPanel({
  vm,
  onStart,
  onStop,
  onReset,
  onDelete,
  onDuplicate,
  onPreviewCommand,
  loading = false,
}: VMPanelProps) {
  const isRunning = vm.status.running

  return (
    <div className="space-y-4">
      {/* 顶部操作栏 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-foreground">{vm.name}</h2>
          <p className="flex items-center gap-2 text-sm text-muted-foreground">
            {loading ? (
              <span className="flex items-center gap-1 text-yellow-500">
                <Loader2 className="h-3 w-3 animate-spin" />
                处理中...
              </span>
            ) : isRunning ? (
              <>
                <span className="text-green-500">运行中</span>
                {vm.status.pid && (
                  <span className="text-xs">PID: {vm.status.pid}</span>
                )}
                {vm.status.uptime !== undefined && (
                  <span className="flex items-center gap-1 text-xs">
                    <Clock className="h-3 w-3" />
                    {formatUptime(vm.status.uptime)}
                  </span>
                )}
              </>
            ) : (
              <span>已停止</span>
            )}
            {vm.display.type === "vnc" && isRunning && (
              <span className="text-xs">
                VNC :{(vm.display.port || 5900) - 5900}
              </span>
            )}
          </p>
        </div>

        <div className="flex gap-2">
          {!isRunning ? (
            <button
              onClick={onStart}
              disabled={loading}
              className="flex items-center gap-1.5 rounded-md bg-green-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
            >
              <Play className="h-4 w-4" />
              启动
            </button>
          ) : (
            <>
              <button
                onClick={onStop}
                disabled={loading}
                className="flex items-center gap-1.5 rounded-md bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
              >
                <Square className="h-4 w-4" />
                停止
              </button>
              <button
                onClick={onReset}
                disabled={loading}
                className="flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted disabled:opacity-50"
              >
                <RotateCcw className="h-4 w-4" />
                重启
              </button>
            </>
          )}

          <button
            onClick={onPreviewCommand}
            className="flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-sm font-medium text-foreground hover:bg-muted"
          >
            <Terminal className="h-4 w-4" />
            命令
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
            disabled={isRunning || loading}
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
              <dd className="font-mono text-foreground">{vm.cpu.cores} 核</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">CPU 模型</dt>
              <dd className="font-mono text-foreground">{vm.cpu.model}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">内存</dt>
              <dd className="font-mono text-foreground">
                {vm.memory >= 1024 ? `${vm.memory / 1024} GB` : `${vm.memory} MB`}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">KVM</dt>
              <dd className="text-foreground">{vm.kvm ? "启用" : "禁用"}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">机型</dt>
              <dd className="font-mono text-foreground">
                {vm.q35 ? "Q35" : "i440FX"}
              </dd>
            </div>
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
              <dd
                className="truncate font-mono text-foreground max-w-[200px]"
                title={vm.disk.path}
              >
                {vm.disk.path || "(未设置)"}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">大小</dt>
              <dd className="font-mono text-foreground">{vm.disk.size}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">格式</dt>
              <dd className="font-mono text-foreground uppercase">
                {vm.disk.format}
              </dd>
            </div>
            {vm.iso && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">ISO</dt>
                <dd
                  className="truncate font-mono text-foreground max-w-[200px]"
                  title={vm.iso}
                >
                  {vm.iso.split("/").pop()}
                </dd>
              </div>
            )}
            <div className="flex justify-between">
              <dt className="text-muted-foreground">BIOS</dt>
              <dd className="text-foreground">{vm.uefi ? "UEFI" : "SeaBIOS"}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">TPM</dt>
              <dd className="text-foreground">{vm.tpm ? "启用" : "禁用"}</dd>
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
              <dd className="font-mono text-foreground uppercase">
                {vm.display.type}
              </dd>
            </div>
            {vm.display.type === "vnc" && (
              <>
                <div className="flex justify-between">
                  <dt className="text-muted-foreground">端口</dt>
                  <dd className="font-mono text-foreground">
                    {vm.display.port || 5900}
                  </dd>
                </div>
                {vm.display.websocket && (
                  <div className="flex justify-between">
                    <dt className="text-muted-foreground">WebSocket</dt>
                    <dd className="font-mono text-foreground">
                      {vm.display.websocket}
                    </dd>
                  </div>
                )}
              </>
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
                {vm.network.type === "user"
                  ? "NAT"
                  : vm.network.type === "bridge"
                  ? "桥接"
                  : "无网络"}
              </dd>
            </div>
            {vm.network.type === "bridge" && vm.network.bridge && (
              <div className="flex justify-between">
                <dt className="text-muted-foreground">网桥</dt>
                <dd className="font-mono text-foreground">{vm.network.bridge}</dd>
              </div>
            )}
            {vm.network.hostfwd && vm.network.hostfwd.length > 0 && (
              <div>
                <dt className="text-muted-foreground mb-1">端口转发</dt>
                <dd className="space-y-1">
                  {vm.network.hostfwd.map((fwd, i) => (
                    <div
                      key={i}
                      className="font-mono text-xs text-foreground bg-muted rounded px-2 py-1"
                    >
                      {fwd.protocol}:{fwd.hostPort} → {fwd.guestPort}
                    </div>
                  ))}
                </dd>
              </div>
            )}
          </dl>
        </div>
      </div>

      {/* 额外参数 */}
      {vm.extra && (
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="mb-2 text-sm font-medium text-foreground">额外参数</div>
          <pre className="text-xs font-mono text-muted-foreground bg-muted rounded p-2 overflow-x-auto">
            {vm.extra}
          </pre>
        </div>
      )}
    </div>
  )
}
