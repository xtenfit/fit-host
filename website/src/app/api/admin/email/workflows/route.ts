import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { emailStore } from '@/lib/email/store';

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  const workflows = await emailStore.getWorkflows();
  return NextResponse.json({ workflows });
}

export async function PATCH(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  try {
    const body = await request.json();
    const { id, is_enabled } = body;

    if (!id || typeof is_enabled !== 'boolean') {
      return NextResponse.json({ error: 'Workflow ID and is_enabled boolean are required' }, { status: 400 });
    }

    const updated = await emailStore.updateWorkflow(id, { is_enabled });
    if (!updated) {
      return NextResponse.json({ error: 'Workflow not found' }, { status: 404 });
    }

    return NextResponse.json({ workflow: updated, message: `Workflow status updated to ${is_enabled ? 'enabled' : 'paused'}` });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to update workflow' },
      { status: 500 }
    );
  }
}
