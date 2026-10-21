import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { emailStore } from '@/lib/email/store';
import { EmailTemplate } from '@/lib/email/types';

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  const { searchParams } = new URL(request.url);
  const category = searchParams.get('category');
  const search = searchParams.get('search')?.toLowerCase();

  let templates = await emailStore.getTemplates();

  if (category && category !== 'all') {
    templates = templates.filter((t) => t.category === category);
  }

  if (search) {
    templates = templates.filter(
      (t) =>
        t.name.toLowerCase().includes(search) ||
        t.subject.toLowerCase().includes(search) ||
        t.id.toLowerCase().includes(search)
    );
  }

  return NextResponse.json({ templates, count: templates.length });
}

export async function POST(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  try {
    const body = await request.json();
    const { action } = body;

    // Action 1: Duplicate template
    if (action === 'duplicate') {
      const { sourceId, newId, newName } = body;
      if (!sourceId || !newId || !newName) {
        return NextResponse.json({ error: 'Missing required fields for duplicate' }, { status: 400 });
      }

      const duplicated = await emailStore.duplicateTemplate(sourceId, newId, newName);
      if (!duplicated) {
        return NextResponse.json({ error: 'Source template not found' }, { status: 404 });
      }

      return NextResponse.json({ template: duplicated, message: 'Template duplicated successfully' });
    }

    // Action 2: Save / Update template
    const templateData = body.template as EmailTemplate;
    if (!templateData || !templateData.id || !templateData.name || !templateData.subject) {
      return NextResponse.json({ error: 'Invalid template structure' }, { status: 400 });
    }

    const saved = await emailStore.saveTemplate(templateData);
    return NextResponse.json({ template: saved, message: 'Template saved successfully' });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to process template request' },
      { status: 500 }
    );
  }
}
