import { promises as fs } from "fs"
import path from "path"
import type { VMConfig } from "@/types/vm"

// 数据存储目录
const DATA_DIR = process.env.VM_DATA_DIR || path.join(process.cwd(), ".vm-data")
const CONFIG_FILE = path.join(DATA_DIR, "vms.json")

interface VMStore {
  vms: Record<string, VMConfig>
}

async function ensureDataDir(): Promise<void> {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true })
  } catch {
    // 目录已存在
  }
}

async function readStore(): Promise<VMStore> {
  await ensureDataDir()
  try {
    const data = await fs.readFile(CONFIG_FILE, "utf-8")
    return JSON.parse(data)
  } catch {
    return { vms: {} }
  }
}

async function writeStore(store: VMStore): Promise<void> {
  await ensureDataDir()
  await fs.writeFile(CONFIG_FILE, JSON.stringify(store, null, 2))
}

export async function getAllVMs(): Promise<VMConfig[]> {
  const store = await readStore()
  return Object.values(store.vms)
}

export async function getVM(id: string): Promise<VMConfig | null> {
  const store = await readStore()
  return store.vms[id] || null
}

export async function createVM(config: Omit<VMConfig, "id" | "createdAt">): Promise<VMConfig> {
  const store = await readStore()
  const id = `vm-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
  const vm: VMConfig = {
    ...config,
    id,
    createdAt: new Date().toISOString(),
  }
  store.vms[id] = vm
  await writeStore(store)
  return vm
}

export async function updateVM(id: string, updates: Partial<VMConfig>): Promise<VMConfig | null> {
  const store = await readStore()
  if (!store.vms[id]) return null
  store.vms[id] = { ...store.vms[id], ...updates, id }
  await writeStore(store)
  return store.vms[id]
}

export async function deleteVM(id: string): Promise<boolean> {
  const store = await readStore()
  if (!store.vms[id]) return false
  delete store.vms[id]
  await writeStore(store)
  return true
}
