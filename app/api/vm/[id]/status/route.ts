import { NextRequest, NextResponse } from "next/server"
import { getVM } from "@/lib/vm/store"
import { qemuManager } from "@/lib/vm/qemu"

interface Params {
  params: Promise<{ id: string }>
}

// GET /api/vm/[id]/status - 获取 VM 状态
export async function GET(_request: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const vm = await getVM(id)

    if (!vm) {
      return NextResponse.json(
        { success: false, error: "VM 不存在" },
        { status: 404 }
      )
    }

    return NextResponse.json({
      success: true,
      data: qemuManager.getStatus(id),
    })
  } catch (err) {
    return NextResponse.json(
      { success: false, error: (err as Error).message },
      { status: 500 }
    )
  }
}
