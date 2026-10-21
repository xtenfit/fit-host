import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { sendEmail, isValidEmail } from '@/lib/email/resend';
import { renderTemplate } from '@/lib/email/renderer';

export async function POST(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  try {
    const body = await request.json();
    const { to, templateId, subject, html, text, variables } = body;

    if (!to || !isValidEmail(to)) {
      return NextResponse.json({ error: 'A valid recipient email address is required' }, { status: 400 });
    }

    if (!subject || !html) {
      return NextResponse.json({ error: 'Subject and HTML body are required' }, { status: 400 });
    }

    // Default preview test variables for interpolation
    const mergedVariables: Record<string, string | number> = {
      first_name: 'Test Athlete',
      email: to,
      otp_code: '728194',
      verification_url: `https://fithost.amitrana.tech/verify-email?email=${encodeURIComponent(to)}`,
      reset_url: `https://fithost.amitrana.tech/auth/recovery`,
      routine_name: 'Push Hypertrophy',
      exercise_name: 'Incline Dumbbell Press',
      weight_value: '36 kg',
      pr_gain: '2 kg',
      streak_days: 14,
      total_volume: '42,100',
      water_ml: 3200,
      calories_remaining: 520,
      protein_remaining: 45,
      current_water_ml: 2200,
      target_water_ml: 3000,
      workouts_completed: 6,
      volume_growth: 12,
      prs_count: 3,
      ticket_id: 'FH-TEST-99',
      ticket_subject: 'Test email from Fit Host Email Studio',
      agent_message: 'This is a test notification rendered by the Fit Host Email Studio engine.',
      site_url: 'https://fithost.amitrana.tech',
      support_url: 'https://fithost.amitrana.tech/support',
      release_version: 'v2.1.0',
      ...(variables || {}),
    };

    const renderedSubject = renderTemplate(subject, mergedVariables);
    const renderedHtml = renderTemplate(html, mergedVariables);
    const renderedText = text ? renderTemplate(text, mergedVariables) : undefined;

    const result = await sendEmail({
      to,
      subject: renderedSubject,
      html: renderedHtml,
      text: renderedText,
      templateId,
      isTest: true,
    });

    if (!result.success) {
      return NextResponse.json({ error: result.error || 'Failed to send test email' }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      messageId: result.messageId,
      recipient: to,
      message: `Test email dispatched successfully to ${to}`,
    });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Error processing test email send' },
      { status: 500 }
    );
  }
}
