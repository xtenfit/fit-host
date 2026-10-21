import { Resend } from 'resend';

export async function sendVerificationEmail({
  name,
  email,
  otp,
}: {
  name: string;
  email: string;
  otp: string;
}) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new Error('Missing RESEND_API_KEY');
  }

  const resend = new Resend(apiKey);
  const fromEmail = process.env.FROM_EMAIL || 'noreply@amitran.tech';

  const response = await resend.emails.send({
    from: fromEmail,
    to: email,
    subject: 'Verify your email address',
    html: `
      <div style="font-family:Arial,sans-serif;background:#f4f7fb;padding:24px;color:#111827;">
        <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:18px;border:1px solid #e5e7eb;overflow:hidden;">
          <div style="padding:24px 28px;background:linear-gradient(135deg,#111827,#1d4ed8);color:#fff;">
            <h2 style="margin:0;font-size:24px;">Verify your email</h2>
          </div>
          <div style="padding:28px;">
            <p style="margin:0 0 16px;font-size:16px;">Hello <strong>${name}</strong>,</p>
            <p style="margin:0 0 20px;line-height:1.7;font-size:15px;">
              Thanks for signing up with Amit Rana. We received a verification request for
              <strong>${email}</strong>.
            </p>
            <div style="margin:24px 0;background:#eff6ff;border:1px solid #bfdbfe;border-radius:12px;padding:18px;text-align:center;">
              <div style="font-size:12px;letter-spacing:2px;color:#1d4ed8;text-transform:uppercase;margin-bottom:8px;">Verification code</div>
              <div style="font-size:32px;font-weight:700;letter-spacing:8px;color:#111827;">${otp}</div>
            </div>
            <p style="margin:0;line-height:1.7;color:#374151;">
              Use this one-time code to confirm your email and continue securely.
            </p>
            <p style="margin:16px 0 0;line-height:1.7;color:#6b7280;font-size:13px;">
              If you did not request this, you can safely ignore it.
            </p>
          </div>
        </div>
      </div>
    `,
    text: `Hello ${name},\n\nYour verification code is: ${otp}\n\nUse this code to verify your email and continue securely.`,
  });

  return response;
}
