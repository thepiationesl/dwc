import { NextRequest, NextResponse } from "next/server"
import { getVM } from "@/lib/vm/store"
import { qemuManager } from "@/lib/vm/qemu"

interface Params {
  params: Promise<{ id: string }>
}

// POST /api/vm/[id]/stop - 停止 VM
export async function POST(request: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const vm = await getVM(id)

    if (!vm) {
      return NextResponse.json(
        { success: false, error: "VM 不存在" },
        { status: 404 }
      )
    }

    if (!qemuManager.isRunning(id)) {
      return NextResponse.json(
        { success: false, error: "VM 未运行" },
        { status: 400 }
      )
    }

    const { searchParams } = new URL(request.url)
    const force = searchParams.get("force") === "true"

    const result = await qemuManager.stop(id, force)

    if (!result.success) {
      return NextResponse.json(
        { success: false, error: result.error },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true })
  } catch (err) {
    return NextResponse.json(
      { success: false, error: (err as Error).message },
      { status: 500 }
    )
  }
}
