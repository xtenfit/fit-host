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
  const fromEmail = process.env.FROM_EMAIL || 'noreply@amitrana.tech';

  const response = await resend.emails.send({
    from: fromEmail,
    to: email,
    subject: `Verify your Fit Host account (Code: ${otp})`,
    html: `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verify your Fit Host account</title>
      </head>
      <body style="margin: 0; padding: 0; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #E5E7EB;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0B0D11; min-height: 100vh;">
          <tr>
            <td align="center" style="padding: 32px 16px;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
                <!-- Header with Fit Host Logo -->
                <tr>
                  <td align="center" style="padding: 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
                    <a href="https://fithost.amitrana.tech" target="_blank" style="text-decoration: none;">
                      <table border="0" cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="padding-right: 14px; vertical-align: middle;">
                            <img src="https://fithost.amitrana.tech/fit_host_icon.png" width="44" height="44" alt="Fit Host" style="width: 44px; height: 44px; display: block; border: 0; outline: none; background: transparent;" />
                          </td>
                          <td style="vertical-align: middle;">
                            <span style="font-size: 22px; font-weight: 800; color: #FFFFFF; display: block; line-height: 24px; letter-spacing: -0.5px;">FIT HOST</span>
                            <span style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Performance Engine</span>
                          </td>
                        </tr>
                      </table>
                    </a>
                  </td>
                </tr>
                <!-- Body -->
                <tr>
                  <td style="padding: 36px 32px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
                    <h1 style="margin: 0 0 16px; font-size: 24px; font-weight: 800; color: #FFFFFF;">Verify Your Account</h1>
                    <p style="margin: 0 0 16px;">Hello <strong style="color: #FFFFFF;">${name}</strong>,</p>
                    <p style="margin: 0 0 20px; color: #9CA3AF; font-size: 14px;">
                      Welcome to Fit Host! We received a signup verification request for <strong style="color: #FFFFFF;">${email}</strong>. Enter the 6-digit security code below to complete your registration:
                    </p>
                    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
                      <tr>
                        <td align="center" style="background-color: #0B0D11; border: 1px solid #00E676; border-radius: 12px; padding: 22px 16px;">
                          <div style="font-size: 11px; font-weight: 700; letter-spacing: 2px; color: #00E676; text-transform: uppercase; margin-bottom: 6px;">
                            One-Time Security Verification Code
                          </div>
                          <div style="font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; font-family: monospace;">
                            ${otp}
                          </div>
                          <div style="font-size: 12px; color: #9CA3AF; margin-top: 6px;">
                            Valid for 10 minutes &bull; Do not share this code with anyone
                          </div>
                        </td>
                      </tr>
                    </table>
                    <p style="margin: 20px 0 0; font-size: 13px; color: #6B7280;">
                      If you did not request this verification code, you can safely ignore this email.
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding: 24px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px;">
                    <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">fithost.amitrana.tech</a> &bull;
                    <a href="https://fithost.amitrana.tech/support" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">Support</a> &bull;
                    <a href="https://fithost.amitrana.tech/privacy" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">Privacy</a>
                    <div style="margin-top: 8px; color: #4B5563; font-size: 11px;">
                      &copy; 2026 Fit Host &bull; High-Performance Fitness Ecosystem
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
      </html>
    `,
    text: `Hello ${name},\n\nYour Fit Host verification code is: ${otp}\n\nUse this code to verify your account. It expires in 10 minutes.\n\nhttps://fithost.amitrana.tech`,
  });

  return response;
}
