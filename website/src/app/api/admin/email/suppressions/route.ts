import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { emailStore } from '@/lib/email/store';
import { isValidEmail } from '@/lib/email/resend';

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  const suppressions = await emailStore.getSuppressions();
  return NextResponse.json({ suppressions, count: suppressions.length });
}

export async function POST(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  try {
    const { email } = await request.json();
    if (!email || !isValidEmail(email)) {
      return NextResponse.json({ error: 'Valid email is required' }, { status: 400 });
    }

    await emailStore.addSuppression(email);
    return NextResponse.json({ message: `Email ${email} added to suppression list` });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to add suppression' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  try {
    const { email } = await request.json();
    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    await emailStore.removeSuppression(email);
    return NextResponse.json({ message: `Email ${email} removed from suppression list` });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to remove suppression' },
      { status: 500 }
    );
  }
}
