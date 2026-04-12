export type VMStatus = "running" | "stopped" | "paused" | "error"

export interface VM {
  id: string
  name: string
  status: VMStatus
  cpu: number
  memory: number // MB
  disk: string
  image: string
  tag?: string
  ip?: string
  port?: number
}
