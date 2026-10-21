import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { emailStore } from '@/lib/email/store';

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  const { searchParams } = new URL(request.url);
  const limit = parseInt(searchParams.get('limit') || '100', 10);
  const filter = searchParams.get('type');

  let events = await emailStore.getDeliveryEvents(limit);

  if (filter && filter !== 'all') {
    events = events.filter((e) => e.event_type === filter);
  }

  return NextResponse.json({ events, count: events.length });
}
