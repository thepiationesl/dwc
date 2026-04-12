import { NextRequest, NextResponse } from "next/server"
import { getVM } from "@/lib/vm/store"
import { qemuManager } from "@/lib/vm/qemu"

interface Params {
  params: Promise<{ id: string }>
}

// POST /api/vm/[id]/start - 启动 VM
export async function POST(_request: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const vm = await getVM(id)

    if (!vm) {
      return NextResponse.json(
        { success: false, error: "VM 不存在" },
        { status: 404 }
      )
    }

    if (qemuManager.isRunning(id)) {
      return NextResponse.json(
        { success: false, error: "VM 已在运行中" },
        { status: 400 }
      )
    }

    const result = await qemuManager.start(vm)

    if (!result.success) {
      return NextResponse.json(
        { success: false, error: result.error },
        { status: 500 }
      )
    }

    return NextResponse.json({
      success: true,
      data: {
        pid: result.pid,
        status: qemuManager.getStatus(id),
      },
    })
  } catch (err) {
    return NextResponse.json(
      { success: false, error: (err as Error).message },
      { status: 500 }
    )
  }
}
