import { NextResponse } from 'next/server';
import { verifyAdminAuthorization } from '@/lib/email/auth';
import { DEFAULT_EMAIL_FROM, DEFAULT_EMAIL_REPLY_TO, SENDING_DOMAIN } from '@/lib/email/resend';

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) {
    return NextResponse.json({ error: auth.reason || 'Unauthorized' }, { status: 403 });
  }

  const hasApiKey = Boolean(
    process.env.RESEND_API_KEY &&
      process.env.RESEND_API_KEY.trim() !== '' &&
      !process.env.RESEND_API_KEY.includes('your-resend-api-key')
  );

  const providerStatus = {
    provider: 'Resend',
    sdkVersion: '^6.34.1',
    status: hasApiKey ? 'active' : 'needs_api_key',
    hasApiKey,
    sendingDomain: SENDING_DOMAIN,
    senderIdentity: DEFAULT_EMAIL_FROM,
    replyTo: DEFAULT_EMAIL_REPLY_TO,
    rootDomain: 'amitrana.tech',
    dnsProvider: 'Cloudflare',
    requiredDnsRecords: [
      {
        type: 'TXT',
        name: 'noreply.amitrana.tech',
        value: 'v=spf1 include:resend.com ~all',
        purpose: 'SPF (Sender Policy Framework) authentication',
        status: 'required',
      },
      {
        type: 'TXT',
        name: 'resend._domainkey.noreply.amitrana.tech',
        value: 'Generated in Resend Dashboard (DKIM public key)',
        purpose: 'DKIM (DomainKeys Identified Mail) cryptographic signature',
        status: 'required',
      },
      {
        type: 'TXT',
        name: '_dmarc.noreply.amitrana.tech',
        value: 'v=DMARC1; p=none; rua=mailto:dmarc@amitrana.tech',
        purpose: 'DMARC alignment policy and deliverability reporting',
        status: 'recommended',
      },
      {
        type: 'MX',
        name: 'noreply.amitrana.tech',
        value: 'feedback-smtp.resend.com (Priority 10)',
        purpose: 'Inbound bounce and feedback loop routing',
        status: 'recommended',
      },
    ],
    supabaseSmtpConfig: {
      enabled: true,
      senderEmail: 'no-reply@noreply.amitrana.tech',
      senderName: 'Fit Host',
      host: 'smtp.resend.com',
      port: 465,
      encryption: 'SSL / TLS',
      user: 'resend',
      pass: '[RESEND_API_KEY]',
      notice: 'In Supabase Dashboard > Authentication > Email Settings, enable Custom SMTP and save these exact values.',
    },
  };

  return NextResponse.json(providerStatus);
}
