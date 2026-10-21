# FIT HOST — SUPABASE AUTH BRANDED EMAIL TEMPLATES
**Domain:** `noreply.amitrana.tech`  
**Sender:** `Fit Host <no-reply@noreply.amitrana.tech>`  
**Brand Palette:** Dark Charcoal (`#0B0D11`, `#12151C`) & Electric Neon Green (`#00E676`)

---

## 1. Confirm Signup Template (Signup Verification & 6-Digit OTP)
In **Supabase Dashboard > Authentication > Email Templates > Confirm signup**:

**Subject:**
```
Verify your Fit Host account (Code: {{ .Token }})
```

**Body (HTML):**
```html
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
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden;">
          <tr>
            <td align="center" style="padding: 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding-right: 12px; vertical-align: middle;">
                    <div style="width: 40px; height: 40px; background-color: #00E676; border-radius: 10px; text-align: center; line-height: 40px; font-weight: 900; font-size: 20px; color: #000000;">⚡</div>
                  </td>
                  <td style="vertical-align: middle;">
                    <span style="font-size: 22px; font-weight: 800; color: #FFFFFF; display: block; line-height: 24px;">FIT HOST</span>
                    <span style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Performance Engine</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding: 36px 32px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
              <h1 style="margin: 0 0 16px; font-size: 24px; font-weight: 800; color: #FFFFFF;">Verify Your Account</h1>
              <p style="margin: 0 0 16px;">Welcome to Fit Host! We received a signup request for <strong style="color: #FFFFFF;">{{ .Email }}</strong>.</p>
              <p style="margin: 0 0 20px; color: #9CA3AF; font-size: 14px;">Enter the 6-digit verification code below in your app, or click the direct verification button:</p>
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="background-color: #0B0D11; border: 1px solid #00E676; border-radius: 12px; padding: 20px 16px;">
                    <div style="font-size: 11px; font-weight: 700; letter-spacing: 2px; color: #00E676; text-transform: uppercase; margin-bottom: 6px;">One-Time Verification Code</div>
                    <div style="font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; font-family: monospace;">{{ .Token }}</div>
                    <div style="font-size: 12px; color: #9CA3AF; margin-top: 6px;">Valid for 10 minutes</div>
                  </td>
                </tr>
              </table>
              <table border="0" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="border-radius: 10px; background-color: #00E676;">
                    <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 14px 32px; font-size: 15px; font-weight: 800; color: #000000; text-decoration: none; border-radius: 10px;">Confirm Email Address</a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0; font-size: 13px; color: #6B7280;">If you did not create a Fit Host account, please disregard this email.</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 24px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px;">
              <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">fithost.amitrana.tech</a> &bull;
              <a href="https://fithost.amitrana.tech/support" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">Support</a> &bull;
              <a href="https://fithost.amitrana.tech/privacy" style="color: #9CA3AF; text-decoration: none; margin: 0 8px;">Privacy</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 2. Magic Link / OTP Login Template
In **Supabase Dashboard > Authentication > Email Templates > Magic Link**:

**Subject:**
```
Your Fit Host 6-digit security code: {{ .Token }}
```

**Body (HTML):**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fit Host Login Code</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #E5E7EB;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0B0D11; min-height: 100vh;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden;">
          <tr>
            <td align="center" style="padding: 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding-right: 12px; vertical-align: middle;">
                    <div style="width: 40px; height: 40px; background-color: #00E676; border-radius: 10px; text-align: center; line-height: 40px; font-weight: 900; font-size: 20px; color: #000000;">⚡</div>
                  </td>
                  <td style="vertical-align: middle;">
                    <span style="font-size: 22px; font-weight: 800; color: #FFFFFF; display: block; line-height: 24px;">FIT HOST</span>
                    <span style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Authentication</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding: 36px 32px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
              <h1 style="margin: 0 0 16px; font-size: 24px; font-weight: 800; color: #FFFFFF;">One-Time Sign-In Code</h1>
              <p style="margin: 0 0 16px;">Here is your 6-digit authentication code to access your Fit Host athlete account:</p>
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="background-color: #0B0D11; border: 1px solid #00E676; border-radius: 12px; padding: 20px 16px;">
                    <div style="font-size: 11px; font-weight: 700; letter-spacing: 2px; color: #00E676; text-transform: uppercase; margin-bottom: 6px;">Single-Use Code</div>
                    <div style="font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; font-family: monospace;">{{ .Token }}</div>
                    <div style="font-size: 12px; color: #9CA3AF; margin-top: 6px;">Expires in 10 minutes</div>
                  </td>
                </tr>
              </table>
              <table border="0" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="border-radius: 10px; background-color: #00E676;">
                    <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 14px 32px; font-size: 15px; font-weight: 800; color: #000000; text-decoration: none; border-radius: 10px;">Sign In Instantly</a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0; font-size: 13px; color: #6B7280;">Never share this code with anyone. Fit Host staff will never ask for your code.</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 24px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px;">
              &copy; 2026 Fit Host &bull; <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none;">fithost.amitrana.tech</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 3. Reset Password Template
In **Supabase Dashboard > Authentication > Email Templates > Reset password**:

**Subject:**
```
Reset your Fit Host account password
```

**Body (HTML):**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset your Fit Host password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #E5E7EB;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0B0D11; min-height: 100vh;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden;">
          <tr>
            <td align="center" style="padding: 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding-right: 12px; vertical-align: middle;">
                    <div style="width: 40px; height: 40px; background-color: #00E676; border-radius: 10px; text-align: center; line-height: 40px; font-weight: 900; font-size: 20px; color: #000000;">⚡</div>
                  </td>
                  <td style="vertical-align: middle;">
                    <span style="font-size: 22px; font-weight: 800; color: #FFFFFF; display: block; line-height: 24px;">FIT HOST</span>
                    <span style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Security</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding: 36px 32px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
              <h1 style="margin: 0 0 16px; font-size: 24px; font-weight: 800; color: #FFFFFF;">Password Reset Request</h1>
              <p style="margin: 0 0 16px;">We received a request to reset the password for your Fit Host account associated with <strong style="color: #FFFFFF;">{{ .Email }}</strong>.</p>
              <table border="0" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="border-radius: 10px; background-color: #00E676;">
                    <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 14px 32px; font-size: 15px; font-weight: 800; color: #000000; text-decoration: none; border-radius: 10px;">Reset Password</a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0; font-size: 13px; color: #9CA3AF;">This link is single-use and valid for 60 minutes. If you did not make this request, you can safely disregard this email; your account remains secure.</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 24px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px;">
              &copy; 2026 Fit Host &bull; <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none;">fithost.amitrana.tech</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 4. Change Email Address Template
In **Supabase Dashboard > Authentication > Email Templates > Change email address**:

**Subject:**
```
Confirm your new Fit Host email address
```

**Body (HTML):**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Confirm new email address</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #E5E7EB;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0B0D11; min-height: 100vh;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #12151C; border-radius: 16px; border: 1px solid #222734; overflow: hidden;">
          <tr>
            <td align="center" style="padding: 32px; background: linear-gradient(180deg, rgba(0, 230, 118, 0.08) 0%, rgba(18, 21, 28, 0) 100%); border-bottom: 1px solid #1F2430;">
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding-right: 12px; vertical-align: middle;">
                    <div style="width: 40px; height: 40px; background-color: #00E676; border-radius: 10px; text-align: center; line-height: 40px; font-weight: 900; font-size: 20px; color: #000000;">⚡</div>
                  </td>
                  <td style="vertical-align: middle;">
                    <span style="font-size: 22px; font-weight: 800; color: #FFFFFF; display: block; line-height: 24px;">FIT HOST</span>
                    <span style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; color: #00E676; text-transform: uppercase;">Account Security</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding: 36px 32px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
              <h1 style="margin: 0 0 16px; font-size: 24px; font-weight: 800; color: #FFFFFF;">Confirm Email Change</h1>
              <p style="margin: 0 0 16px;">You requested to update your Fit Host account email address. Click the button below to confirm this change:</p>
              <table border="0" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
                <tr>
                  <td align="center" style="border-radius: 10px; background-color: #00E676;">
                    <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 14px 32px; font-size: 15px; font-weight: 800; color: #000000; text-decoration: none; border-radius: 10px;">Confirm New Email</a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0; font-size: 13px; color: #9CA3AF;">If you did not request this update, contact our support team immediately at <a href="mailto:support@amitrana.tech" style="color: #00E676;">support@amitrana.tech</a>.</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 24px 32px; background-color: #0A0C10; border-top: 1px solid #1A1F2B; text-align: center; color: #6B7280; font-size: 12px;">
              &copy; 2026 Fit Host &bull; <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none;">fithost.amitrana.tech</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```
