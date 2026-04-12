import { spawn, ChildProcess } from "child_process"
import { EventEmitter } from "events"
import type { VMConfig, VMStatus } from "@/types/vm"
import { buildQemuCommand } from "@/types/vm"

interface VMProcess {
  process: ChildProcess
  config: VMConfig
  startedAt: Date
  pid: number
}

class QemuManager extends EventEmitter {
  private processes: Map<string, VMProcess> = new Map()
  private static instance: QemuManager

  static getInstance(): QemuManager {
    if (!QemuManager.instance) {
      QemuManager.instance = new QemuManager()
    }
    return QemuManager.instance
  }

  async start(config: VMConfig): Promise<{ success: boolean; error?: string; pid?: number }> {
    if (this.processes.has(config.id)) {
      return { success: false, error: "VM 已在运行中" }
    }

    const { command, args } = buildQemuCommand(config)

    try {
      const proc = spawn(command, args, {
        detached: false,
        stdio: ["ignore", "pipe", "pipe"],
      })

      if (!proc.pid) {
        return { success: false, error: "无法启动 QEMU 进程" }
      }

      const vmProcess: VMProcess = {
        process: proc,
        config,
        startedAt: new Date(),
        pid: proc.pid,
      }

      this.processes.set(config.id, vmProcess)

      proc.on("exit", (code, signal) => {
        this.processes.delete(config.id)
        this.emit("vm:stopped", { id: config.id, code, signal })
      })

      proc.on("error", (err) => {
        this.processes.delete(config.id)
        this.emit("vm:error", { id: config.id, error: err.message })
      })

      // 收集输出日志
      proc.stdout?.on("data", (data) => {
        this.emit("vm:stdout", { id: config.id, data: data.toString() })
      })

      proc.stderr?.on("data", (data) => {
        this.emit("vm:stderr", { id: config.id, data: data.toString() })
      })

      this.emit("vm:started", { id: config.id, pid: proc.pid })

      return { success: true, pid: proc.pid }
    } catch (err) {
      return { success: false, error: (err as Error).message }
    }
  }

  async stop(id: string, force = false): Promise<{ success: boolean; error?: string }> {
    const vmProcess = this.processes.get(id)
    if (!vmProcess) {
      return { success: false, error: "VM 未运行" }
    }

    try {
      if (force) {
        vmProcess.process.kill("SIGKILL")
      } else {
        // 先尝试优雅关机 (通过 QEMU monitor 发送 system_powerdown)
        // 这里简化处理，直接 SIGTERM
        vmProcess.process.kill("SIGTERM")
        
        // 等待 10 秒后强制杀死
        setTimeout(() => {
          if (this.processes.has(id)) {
            vmProcess.process.kill("SIGKILL")
          }
        }, 10000)
      }

      return { success: true }
    } catch (err) {
      return { success: false, error: (err as Error).message }
    }
  }

  async reset(id: string): Promise<{ success: boolean; error?: string }> {
    const vmProcess = this.processes.get(id)
    if (!vmProcess) {
      return { success: false, error: "VM 未运行" }
    }

    // 停止后重新启动
    await this.stop(id, true)
    
    // 等待进程完全退出
    await new Promise(resolve => setTimeout(resolve, 500))
    
    return this.start(vmProcess.config)
  }

  getStatus(id: string): VMStatus {
    const vmProcess = this.processes.get(id)
    if (!vmProcess) {
      return {
        running: false,
      }
    }

    return {
      running: true,
      pid: vmProcess.pid,
      uptime: Math.floor((Date.now() - vmProcess.startedAt.getTime()) / 1000),
    }
  }

  getAllStatus(): Record<string, VMStatus> {
    const result: Record<string, VMStatus> = {}
    for (const [id] of this.processes) {
      result[id] = this.getStatus(id)
    }
    return result
  }

  isRunning(id: string): boolean {
    return this.processes.has(id)
  }

  getRunningCount(): number {
    return this.processes.size
  }
}

export const qemuManager = QemuManager.getInstance()
