import useSWR, { mutate } from "swr"
import type { VMConfig, VMStatus } from "@/types/vm"

interface VMWithStatus extends VMConfig {
  status: VMStatus
}

interface APIResponse<T> {
  success: boolean
  data?: T
  error?: string
}

const fetcher = async (url: string) => {
  const res = await fetch(url)
  const json = await res.json()
  if (!json.success) {
    throw new Error(json.error || "请求失败")
  }
  return json.data
}

export function useVMs() {
  const { data, error, isLoading } = useSWR<VMWithStatus[]>("/api/vm", fetcher, {
    refreshInterval: 2000, // 每 2 秒刷新状态
  })

  return {
    vms: data || [],
    isLoading,
    error: error?.message,
  }
}

export function useVM(id: string | null) {
  const { data, error, isLoading } = useSWR<VMWithStatus>(
    id ? `/api/vm/${id}` : null,
    fetcher,
    { refreshInterval: 1000 }
  )

  return {
    vm: data,
    isLoading,
    error: error?.message,
  }
}

export async function createVM(config: Partial<VMConfig>): Promise<VMConfig> {
  const res = await fetch("/api/vm", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(config),
  })
  const json: APIResponse<VMConfig> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "创建失败")
  }
  mutate("/api/vm")
  return json.data!
}

export async function updateVM(id: string, config: Partial<VMConfig>): Promise<VMConfig> {
  const res = await fetch(`/api/vm/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(config),
  })
  const json: APIResponse<VMConfig> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "更新失败")
  }
  mutate("/api/vm")
  mutate(`/api/vm/${id}`)
  return json.data!
}

export async function deleteVM(id: string): Promise<void> {
  const res = await fetch(`/api/vm/${id}`, {
    method: "DELETE",
  })
  const json: APIResponse<void> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "删除失败")
  }
  mutate("/api/vm")
}

export async function startVM(id: string): Promise<void> {
  const res = await fetch(`/api/vm/${id}/start`, {
    method: "POST",
  })
  const json: APIResponse<{ pid: number }> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "启动失败")
  }
  mutate("/api/vm")
  mutate(`/api/vm/${id}`)
}

export async function stopVM(id: string, force = false): Promise<void> {
  const res = await fetch(`/api/vm/${id}/stop?force=${force}`, {
    method: "POST",
  })
  const json: APIResponse<void> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "停止失败")
  }
  mutate("/api/vm")
  mutate(`/api/vm/${id}`)
}

export async function resetVM(id: string): Promise<void> {
  const res = await fetch(`/api/vm/${id}/reset`, {
    method: "POST",
  })
  const json: APIResponse<void> = await res.json()
  if (!json.success) {
    throw new Error(json.error || "重置失败")
  }
  mutate("/api/vm")
  mutate(`/api/vm/${id}`)
}
