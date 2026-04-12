import { NextRequest, NextResponse } from "next/server"
import { getAllVMs, createVM } from "@/lib/vm/store"
import { qemuManager } from "@/lib/vm/qemu"
import type { VMConfig } from "@/types/vm"

// GET /api/vm - 获取所有 VM
export async function GET() {
  try {
    const vms = await getAllVMs()
    const statuses = qemuManager.getAllStatus()

    const vmsWithStatus = vms.map(vm => ({
      ...vm,
      status: statuses[vm.id] || { running: false },
    }))

    return NextResponse.json({
      success: true,
      data: vmsWithStatus,
    })
  } catch (err) {
    return NextResponse.json(
      { success: false, error: (err as Error).message },
      { status: 500 }
    )
  }
}

// POST /api/vm - 创建新 VM
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // 验证必需字段
    if (!body.name) {
      return NextResponse.json(
        { success: false, error: "缺少 VM 名称" },
        { status: 400 }
      )
    }

    const config: Omit<VMConfig, "id" | "createdAt"> = {
      name: body.name,
      cpu: {
        cores: body.cpu?.cores || 2,
        model: body.cpu?.model || "host",
      },
      memory: body.memory || 2048,
      disk: body.disk || {
        path: "",
        size: "32G",
        format: "qcow2",
      },
      iso: body.iso,
      display: body.display || {
        type: "vnc",
        port: 5900,
      },
      network: body.network || {
        type: "user",
      },
      kvm: body.kvm !== false,
      uefi: body.uefi || false,
      q35: body.q35 || false,
      tpm: body.tpm || false,
      extra: body.extra,
    }

    const vm = await createVM(config)

    return NextResponse.json({
      success: true,
      data: vm,
    })
  } catch (err) {
    return NextResponse.json(
      { success: false, error: (err as Error).message },
      { status: 500 }
    )
  }
}
