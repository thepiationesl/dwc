import { NextRequest, NextResponse } from "next/server"
import { getVM, updateVM, deleteVM } from "@/lib/vm/store"
import { qemuManager } from "@/lib/vm/qemu"

interface Params {
  params: Promise<{ id: string }>
}

// GET /api/vm/[id] - 获取单个 VM
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
      data: {
        ...vm,
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

// PUT /api/vm/[id] - 更新 VM 配置
export async function PUT(request: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    
    if (qemuManager.isRunning(id)) {
      return NextResponse.json(
        { success: false, error: "VM 运行中，无法修改配置" },
        { status: 400 }
      )
    }

    const body = await request.json()
    const vm = await updateVM(id, body)

    if (!vm) {
      return NextResponse.json(
        { success: false, error: "VM 不存在" },
        { status: 404 }
      )
    }

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

// DELETE /api/vm/[id] - 删除 VM
export async function DELETE(_request: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    
    if (qemuManager.isRunning(id)) {
      return NextResponse.json(
        { success: false, error: "请先停止 VM" },
        { status: 400 }
      )
    }

    const deleted = await deleteVM(id)

    if (!deleted) {
      return NextResponse.json(
        { success: false, error: "VM 不存在" },
        { status: 404 }
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
