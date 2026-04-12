"use client"

import { useParams } from "next/navigation"
import { ArrowLeft, Maximize2 } from "lucide-react"
import Link from "next/link"

export default function ConsolePage() {
  const params = useParams()
  const vmId = params.id as string

  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* 工具栏 */}
      <header className="flex items-center justify-between border-b border-border px-4 py-2">
        <div className="flex items-center gap-3">
          <Link
            href="/vm"
            className="rounded p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
          </Link>
          <span className="text-sm font-medium text-foreground">
            控制台 - {vmId}
          </span>
        </div>
        <button
          onClick={() => document.documentElement.requestFullscreen?.()}
          className="rounded p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
        >
          <Maximize2 className="h-4 w-4" />
        </button>
      </header>

      {/* VNC/noVNC 嵌入区域 */}
      <main className="flex flex-1 items-center justify-center bg-black">
        <div className="text-center">
          <p className="mb-4 text-muted-foreground">
            在此嵌入 noVNC 或其他远程桌面客户端
          </p>
          <div className="rounded bg-muted/20 p-4 font-mono text-sm text-muted-foreground">
            {/* 实际使用时替换为 noVNC iframe 或 WebRTC 连接 */}
            <p>连接地址: localhost:8006</p>
            <p className="mt-2">
              dockur/windows 默认暴露 8006 端口用于 VNC 访问
            </p>
          </div>
          <div className="mt-6 text-xs text-muted-foreground">
            <p>推荐方案:</p>
            <ul className="mt-2 space-y-1">
              <li>• noVNC (Web VNC)</li>
              <li>• Apache Guacamole</li>
              <li>• 直接 RDP 客户端</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  )
}
