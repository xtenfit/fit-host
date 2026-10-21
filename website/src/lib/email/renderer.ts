/**
 * Fit Host HTML Email Renderer & Sanitizer
 * Implements high-contrast, client-compatible dark mode email layout (#0B0D11, #00E676).
 */

export function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function renderTemplate(
  templateString: string,
  variables: Record<string, string | number | undefined | null>,
  options: { escapeValues?: boolean } = { escapeValues: true }
): string {
  if (!templateString) return '';

  return templateString.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (match, key) => {
    // Check if key exists in variables
    if (Object.prototype.hasOwnProperty.call(variables, key)) {
      const val = variables[key];
      if (val === undefined || val === null) return '';
      const strVal = String(val);
      // Don't escape if key looks like an explicit HTML block or escapeValues is false
      return options.escapeValues && !key.endsWith('_raw') && !key.startsWith('.') ? escapeHtml(strVal) : strVal;
    }
    // Return original match if not supplied (e.g. Supabase {{ .ConfirmationURL }})
    return match;
  });
}

export function stripHtmlToText(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<br\s*[\/]?>/gi, '\n')
    .replace(/<\/p>/gi, '\n\n')
    .replace(/<\/div>/gi, '\n')
    .replace(/<\/h[1-6]>/gi, '\n\n')
    .replace(/<li[^>]*>/gi, '• ')
    .replace(/<\/li>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\n\s+\n/g, '\n\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

export interface EmailLayoutOptions {
  preheader?: string;
  title?: string;
  siteUrl?: string;
  supportEmail?: string;
  showUnsubscribe?: boolean;
  unsubscribeUrl?: string;
}

/**
 * Wraps content in the official Fit Host branded email template shell.
 * Bulletproof HTML table-based layout compatible with Gmail, Apple Mail, Outlook, iOS, Android.
 */
export function wrapInFitHostEmailLayout(
  contentHtml: string,
  options: EmailLayoutOptions = {}
): string {
  const siteUrl = options.siteUrl || 'https://fithost.amitrana.tech';
  const supportEmail = options.supportEmail || 'support@amitrana.tech';
  const preheader = options.preheader || 'Fit Host - High-Performance Fitness Hub';
  const showUnsubscribe = options.showUnsubscribe ?? true;
  const unsubscribeUrl = options.unsubscribeUrl || `${siteUrl}/support?topic=notifications`;

  return `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="x-apple-disable-message-reformatting" />
  <meta name="color-scheme" content="dark only" />
  <meta name="supported-color-schemes" content="dark only" />
  <title>${escapeHtml(options.title || 'Fit Host')}</title>
  <style type="text/css">
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
      .hero-title { font-size: 22px !important; line-height: 28px !important; }
      .btn-cta { width: 100% !important; text-align: center !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #0B0D11; color: #E5E7EB; -webkit-font-smoothing: antialiased;">
  <!-- Preheader preview text (hidden) -->
  <div style="display: none; font-size: 1px; color: #0B0D11; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;">
    ${escapeHtml(preheader)}
  </div>

  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0B0D11; min-height: 100vh;">
    <tr>
      <td align="center" style="padding: 32px 16px 48px 16px;">
        <!-- Email Container -->
        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="email-container" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
          
          <!-- Brand Header -->
          <tr>
            <td align="center" style="padding: 32px 32px 24px 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
              <a href="${siteUrl}" target="_blank" style="text-decoration: none; display: inline-flex; align-items: center;">
                <table border="0" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="vertical-align: middle; padding-right: 12px;">
                      <!-- Fit Host Hex Logo / Badge -->
                      <div style="width: 40px; height: 40px; background-color: #00E676; border-radius: 10px; text-align: center; line-height: 40px; font-weight: 900; font-size: 20px; color: #000000;">
                        ⚡
                      </div>
                    </td>
                    <td style="vertical-align: middle;">
                      <span style="font-size: 22px; font-weight: 800; letter-spacing: -0.5px; color: #FFFFFF; display: block; line-height: 24px;">FIT HOST</span>
                      <span style="font-size: 11px; font-weight: 600; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Performance Engine</span>
                    </td>
                  </tr>
                </table>
              </a>
            </td>
          </tr>

          <!-- Main Body Content -->
          <tr>
            <td class="mobile-padding" style="padding: 36px 36px 32px 36px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
              ${contentHtml}
            </td>
          </tr>

          <!-- Security & Help Banner -->
          <tr>
            <td class="mobile-padding" style="padding: 0 36px 28px 36px;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0D1016; border-radius: 10px; border: 1px solid #1E2330;">
                <tr>
                  <td style="padding: 16px 20px;">
                    <table border="0" cellpadding="0" cellspacing="0" width="100%">
                      <tr>
                        <td style="width: 24px; vertical-align: top; padding-right: 12px; font-size: 18px;">
                          🛡️
                        </td>
                        <td style="font-size: 12px; color: #9CA3AF; line-height: 1.5;">
                          <strong style="color: #FFFFFF;">Security Notice:</strong> Fit Host will never ask for your password via email. If you did not request this email, please contact our security team at <a href="mailto:${supportEmail}" style="color: #00E676; text-decoration: none;">${supportEmail}</a>.
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Brand Footer -->
          <tr>
            <td style="padding: 28px 32px 32px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px; line-height: 1.6;">
              <p style="margin: 0 0 12px 0;">
                <a href="${siteUrl}" target="_blank" style="color: #9CA3AF; text-decoration: none; margin: 0 10px; font-weight: 500;">Website</a> &bull;
                <a href="${siteUrl}/support" target="_blank" style="color: #9CA3AF; text-decoration: none; margin: 0 10px; font-weight: 500;">Support</a> &bull;
                <a href="${siteUrl}/privacy" target="_blank" style="color: #9CA3AF; text-decoration: none; margin: 0 10px; font-weight: 500;">Privacy Policy</a> &bull;
                <a href="${siteUrl}/terms" target="_blank" style="color: #9CA3AF; text-decoration: none; margin: 0 10px; font-weight: 500;">Terms</a>
              </p>
              <p style="margin: 0 0 8px 0; color: #4B5563;">
                Fit Host &bull; Built for athletes who demand accuracy and offline resilience.
              </p>
              <p style="margin: 0; color: #374151; font-size: 11px;">
                &copy; 2026 Fit Host &bull; Amit Rana Tech. All rights reserved.
                ${showUnsubscribe ? `<br/><a href="${unsubscribeUrl}" style="color: #6B7280; text-decoration: underline; margin-top: 6px; display: inline-block;">Manage email preferences or unsubscribe</a>` : ''}
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
