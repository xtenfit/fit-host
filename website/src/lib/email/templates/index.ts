import { EmailTemplate } from '../types';
import { wrapInFitHostEmailLayout } from '../renderer';

// Helper to generate button markup
function buttonHtml(label: string, url: string): string {
  return `
    <table border="0" cellpadding="0" cellspacing="0" style="margin: 28px 0 24px 0;">
      <tr>
        <td align="center" style="border-radius: 10px; background-color: #00E676;">
          <a href="${url}" target="_blank" class="btn-cta" style="display: inline-block; padding: 14px 32px; font-size: 15px; font-weight: 800; color: #000000; text-decoration: none; border-radius: 10px; letter-spacing: 0.5px; text-transform: uppercase;">
            ${label}
          </a>
        </td>
      </tr>
    </table>
  `;
}

// Helper to generate 6-digit OTP code badge
function otpBoxHtml(tokenVar: string = '{{otp_code}}', ttlVar: string = '10 minutes'): string {
  return `
    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
      <tr>
        <td align="center" style="background-color: #0B0D11; border: 1px solid #00E676; border-radius: 12px; padding: 24px 16px;">
          <div style="font-size: 11px; font-weight: 700; letter-spacing: 2px; color: #00E676; text-transform: uppercase; margin-bottom: 8px;">
            One-Time Security Verification Code
          </div>
          <div style="font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; font-family: 'Courier New', Courier, monospace; margin: 6px 0;">
            ${tokenVar}
          </div>
          <div style="font-size: 12px; color: #9CA3AF; margin-top: 8px;">
            Valid for ${ttlVar} &bull; Do not share this code with anyone
          </div>
        </td>
      </tr>
    </table>
  `;
}

// Helper to generate metrics cards
function metricsGridHtml(items: { label: string; value: string; change?: string }[]): string {
  return `
    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
      <tr>
        ${items
          .map(
            (item) => `
          <td style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 10px; padding: 16px; text-align: center; width: ${Math.floor(
            100 / items.length
          )}%;">
            <div style="font-size: 11px; text-transform: uppercase; color: #9CA3AF; letter-spacing: 1px; margin-bottom: 6px;">${item.label}</div>
            <div style="font-size: 24px; font-weight: 800; color: #00E676;">${item.value}</div>
            ${item.change ? `<div style="font-size: 11px; color: #10B981; margin-top: 4px;">${item.change}</div>` : ''}
          </td>
        `
          )
          .join('')}
      </tr>
    </table>
  `;
}

const NOW = '2026-10-21T00:00:00.000Z';

export const INITIAL_50_EMAIL_TEMPLATES: EmailTemplate[] = [
  // =========================================================================
  // CATEGORY 1: AUTHENTICATION AND ACCOUNT SECURITY (5)
  // =========================================================================
  {
    id: 'auth-signup-confirmation',
    name: 'Account Signup Confirmation',
    category: 'authentication',
    subject: 'Verify your Fit Host account (Code: {{otp_code}})',
    preheader: 'Welcome to Fit Host. Use this 6-digit code or link to verify your email.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">
        Verify Your Fit Host Account
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Welcome to Fit Host! We received a signup request for <strong style="color: #FFFFFF;">{{email}}</strong>.
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Enter the 6-digit code below in the Fit Host app, or click the direct verification button:
      </p>
      ${otpBoxHtml('{{otp_code}}', '10 minutes')}
      ${buttonHtml('Verify Email Address', '{{verification_url}}')}
      <p style="margin: 20px 0 0 0; font-size: 13px; color: #6B7280; line-height: 1.5;">
        Button not working? Copy and paste this URL into your browser:<br/>
        <a href="{{verification_url}}" style="color: #00E676; text-decoration: underline; word-break: break-all;">{{verification_url}}</a>
      </p>
    `,
      { preheader: 'Verify your Fit Host email address' }
    ),
    text_body: `Fit Host - Verify Your Account\n\nWelcome to Fit Host! Enter the 6-digit code below in the app or website:\n\nVerification Code: {{otp_code}}\n(Valid for 10 minutes)\n\nOr click here to verify:\n{{verification_url}}\n\nIf you did not sign up for Fit Host, you can safely ignore this email.`,
    fields: [
      { name: 'otp_code', label: '6-Digit Code', type: 'text', defaultValue: '839201' },
      { name: 'verification_url', label: 'Verification URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/verify-email?email={{email}}' },
      { name: 'email', label: 'Athlete Email', type: 'text', defaultValue: 'athlete@example.com' },
    ],
    variables: ['email', 'otp_code', 'verification_url', '.ConfirmationURL', '.Token'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'auth-otp-code',
    name: '6-Digit Security OTP Code',
    category: 'authentication',
    subject: 'Your 6-digit Fit Host login code: {{otp_code}}',
    preheader: 'Use this one-time code to authenticate securely with Fit Host.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">
        Authentication Code
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello <strong style="color: #FFFFFF;">{{first_name}}</strong>,
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Here is your single-use 6-digit verification code to sign in to your Fit Host account:
      </p>
      ${otpBoxHtml('{{otp_code}}', '10 minutes')}
      <p style="margin: 16px 0 0 0; color: #9CA3AF; font-size: 13px; line-height: 1.6;">
        For your security, never give this code to anyone. Fit Host representatives will never ask for your verification code.
      </p>
    `,
      { preheader: 'Your Fit Host 6-digit OTP' }
    ),
    text_body: `Fit Host Authentication Code\n\nHello {{first_name}},\n\nYour 6-digit verification code is:\n\n{{otp_code}}\n\nThis code expires in 10 minutes.\n\nNever share this code with anyone.`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'otp_code', label: '6-Digit OTP', type: 'text', defaultValue: '492018' },
    ],
    variables: ['first_name', 'otp_code', '.Token'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'auth-password-reset',
    name: 'Password Recovery Request',
    category: 'authentication',
    subject: 'Reset your Fit Host password',
    preheader: 'A password reset was requested for your Fit Host account.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">
        Password Reset Request
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello <strong style="color: #FFFFFF;">{{first_name}}</strong>,
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        We received a request to reset the password for your Fit Host account associated with <strong style="color: #FFFFFF;">{{email}}</strong>. Click the button below to choose a new password:
      </p>
      ${buttonHtml('Reset Password', '{{reset_url}}')}
      <p style="margin: 20px 0 0 0; font-size: 13px; color: #9CA3AF; line-height: 1.6;">
        This link is single-use and will expire in <strong style="color: #FFFFFF;">60 minutes</strong>. If you did not request this change, please ignore this email or review your security settings.
      </p>
    `,
      { preheader: 'Reset your Fit Host account password' }
    ),
    text_body: `Fit Host - Password Reset\n\nHello {{first_name}},\n\nA password reset was requested for your account ({{email}}). Follow this link to set a new password:\n\n{{reset_url}}\n\nThis link expires in 60 minutes. If you did not request this, you can safely ignore this message.`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'email', label: 'Email', type: 'text', defaultValue: 'athlete@example.com' },
      { name: 'reset_url', label: 'Reset URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/auth/recovery' },
    ],
    variables: ['first_name', 'email', 'reset_url', '.ConfirmationURL'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'auth-email-change',
    name: 'Email Change Confirmation',
    category: 'authentication',
    subject: 'Confirm your new Fit Host email address',
    preheader: 'Please confirm this new email address for your Fit Host account.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">
        Confirm Email Change
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        You requested to change your Fit Host account email to this address.
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Please confirm this update by clicking the button below:
      </p>
      ${buttonHtml('Confirm New Email', '{{confirmation_url}}')}
      <p style="margin: 20px 0 0 0; font-size: 13px; color: #9CA3AF; line-height: 1.6;">
        If you did not initiate this change, please contact our support team immediately at <a href="mailto:support@amitrana.tech" style="color: #00E676;">support@amitrana.tech</a>.
      </p>
    `,
      { preheader: 'Confirm your new email address' }
    ),
    text_body: `Fit Host - Confirm Email Change\n\nYou requested to change your Fit Host account email. Confirm your new address here:\n\n{{confirmation_url}}\n\nIf you did not request this change, contact support@amitrana.tech immediately.`,
    fields: [
      { name: 'confirmation_url', label: 'Confirmation URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/auth/callback' },
    ],
    variables: ['confirmation_url', '.ConfirmationURL', '.Token'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'auth-security-alert',
    name: 'Security Alert: New Sign-In Detected',
    category: 'authentication',
    subject: 'Security alert: New sign-in to Fit Host',
    preheader: 'A new sign-in was detected on your Fit Host account.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #EF4444; letter-spacing: -0.5px;">
        New Sign-In Detected
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello <strong style="color: #FFFFFF;">{{first_name}}</strong>, we noticed a new sign-in to your Fit Host account:
      </p>
      <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0D1016; border-radius: 10px; border: 1px solid #1E2330; margin: 20px 0;">
        <tr>
          <td style="padding: 16px 20px; font-size: 14px; line-height: 1.8; color: #D1D5DB;">
            <div><strong style="color: #9CA3AF;">Device:</strong> {{device_name}}</div>
            <div><strong style="color: #9CA3AF;">Location:</strong> {{location}}</div>
            <div><strong style="color: #9CA3AF;">Time:</strong> {{timestamp}}</div>
            <div><strong style="color: #9CA3AF;">IP Address:</strong> {{ip_address}}</div>
          </td>
        </tr>
      </table>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        If this was you, no action is needed. If you do not recognize this activity, please secure your account immediately:
      </p>
      ${buttonHtml('Secure My Account', '{{security_url}}')}
    `,
      { preheader: 'New sign-in detected on your account' }
    ),
    text_body: `Fit Host Security Alert\n\nHello {{first_name}},\n\nA new sign-in was detected on your Fit Host account:\n- Device: {{device_name}}\n- Location: {{location}}\n- Time: {{timestamp}}\n- IP: {{ip_address}}\n\nIf this was not you, secure your account immediately:\n{{security_url}}`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'device_name', label: 'Device', type: 'text', defaultValue: 'Chrome on macOS (Apple Silicon)' },
      { name: 'location', label: 'Location', type: 'text', defaultValue: 'San Francisco, CA, USA' },
      { name: 'timestamp', label: 'Time', type: 'text', defaultValue: 'October 21, 2026 10:45 UTC' },
      { name: 'ip_address', label: 'IP Address', type: 'text', defaultValue: '192.0.2.1' },
      { name: 'security_url', label: 'Security URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/dashboard' },
    ],
    variables: ['first_name', 'device_name', 'location', 'timestamp', 'ip_address', 'security_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 2: WELCOME AND ONBOARDING (5)
  // =========================================================================
  {
    id: 'welcome-intro',
    name: 'Welcome to Fit Host',
    category: 'welcome',
    subject: 'Welcome to Fit Host — Your High-Performance Fitness Hub',
    preheader: 'Engineered for athletes who demand accuracy, offline logging, and zero fluff.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 26px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">
        Welcome to Fit Host, {{first_name}}!
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        You just took the first step toward disciplined, data-driven fitness tracking. Fit Host is built from the ground up for speed, offline resilience, and deep performance analytics.
      </p>
      ${metricsGridHtml([
        { label: 'Sync Engine', value: '100% Offline' },
        { label: 'Macro Tracking', value: 'Instant' },
        { label: 'Privacy', value: 'Zero Ads' },
      ])}
      <p style="margin: 16px 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Jump into your web dashboard or mobile app to configure your daily macro targets and schedule your training split:
      </p>
      ${buttonHtml('Open Fit Host Dashboard', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Welcome to Fit Host — High-Performance Fitness Engine' }
    ),
    text_body: `Welcome to Fit Host, {{first_name}}!\n\nYou're all set to track workouts, monitor nutrition, and maintain consistency with zero distractions.\n\nOpen your dashboard:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name', 'site_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'welcome-quickstart',
    name: 'Quickstart Guide: 3 Steps to Success',
    category: 'welcome',
    subject: '3 steps to log your first workout on Fit Host',
    preheader: 'Quick tips to set up routines, weight increments, and target macros.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Quickstart: 3 Steps to Peak Consistency
      </h1>
      <p style="margin: 0 0 20px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Here is how to get the most out of Fit Host in your first 5 minutes:
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 20px; margin-bottom: 24px;">
        <div style="margin-bottom: 16px;">
          <strong style="color: #00E676; font-size: 16px;">1. Set Daily Nutrition Goals</strong>
          <p style="margin: 4px 0 0 0; color: #9CA3AF; font-size: 14px;">Define calories, protein, fats, and carbs tailored to your current phase (cut, lean bulk, or maintenance).</p>
        </div>
        <div style="margin-bottom: 16px;">
          <strong style="color: #00E676; font-size: 16px;">2. Pick or Build a Workout Template</strong>
          <p style="margin: 4px 0 0 0; color: #9CA3AF; font-size: 14px;">Select Push-Pull-Legs, Upper-Lower, or build your custom compound lift routines.</p>
        </div>
        <div>
          <strong style="color: #00E676; font-size: 16px;">3. Log Offline with 1 Tap</strong>
          <p style="margin: 4px 0 0 0; color: #9CA3AF; font-size: 14px;">In the gym with bad cellular reception? No problem. Fit Host queues and synchronizes all sets automatically.</p>
        </div>
      </div>
      ${buttonHtml('Start Quick Setup', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: '3 steps to log your first workout' }
    ),
    text_body: `Fit Host Quickstart\n\n1. Set Daily Nutrition Goals\n2. Pick or Build a Workout Template\n3. Log Offline with 1 Tap\n\nGet started now at https://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'welcome-features-tour',
    name: 'Fit Host Features Deep Dive',
    category: 'welcome',
    subject: 'Explore what makes Fit Host different',
    preheader: 'Dynamic timers, RPE calculation, and micro-nutrient analytics.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Precision Tools Built for Real Gains
      </h1>
      <p style="margin: 0 0 20px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hi {{first_name}}, unlike generic fitness apps that clutter your screen with ads, Fit Host is focused entirely on performance:
      </p>
      ${metricsGridHtml([
        { label: 'Workout Timer', value: 'Auto-Rest' },
        { label: 'Volume Analytics', value: 'Weekly PRs' },
        { label: 'Sync Speed', value: '<50ms' },
      ])}
      <p style="margin: 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Explore your comprehensive dashboard to see your historical trend lines and workout distribution.
      </p>
      ${buttonHtml('Explore Features', 'https://fithost.amitrana.tech/features')}
    `,
      { preheader: 'Precision tools built for real gains' }
    ),
    text_body: `Explore Fit Host Features\n\nAuto-rest timer, weekly volume analytics, and lightning fast offline sync.\n\nExplore at https://fithost.amitrana.tech/features`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'welcome-download-apps',
    name: 'Download Fit Host Mobile Apps',
    category: 'welcome',
    subject: 'Take Fit Host to the gym — Download the Mobile App',
    preheader: 'Download Android APK or join our TestFlight iOS beta.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Fit Host in Your Pocket
      </h1>
      <p style="margin: 0 0 20px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        The native Fit Host Flutter mobile app brings smooth 120Hz animations, haptic rest timers, and offline local-first SQLite persistence directly to your phone.
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
        <div style="font-size: 18px; font-weight: 800; color: #00E676; margin-bottom: 6px;">Android Release v2.1.0 Ready</div>
        <p style="margin: 0 0 16px 0; font-size: 13px; color: #9CA3AF;">Direct high-speed APK download with verified SHA-256 integrity.</p>
        <a href="https://fithost.amitrana.tech/download" style="display: inline-block; padding: 12px 24px; background: #00E676; color: #000; font-weight: 800; border-radius: 8px; text-decoration: none; font-size: 14px;">
          Download APK (44.2 MB)
        </a>
      </div>
    `,
      { preheader: 'Download Fit Host mobile apps' }
    ),
    text_body: `Fit Host Mobile Apps\n\nDownload the Android release APK or learn about iOS availability:\nhttps://fithost.amitrana.tech/download`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'welcome-profile-complete',
    name: 'Complete Athlete Profile',
    category: 'welcome',
    subject: 'Complete your athlete profile on Fit Host',
    preheader: 'Fine-tune your training age, target body weight, and hydration goals.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Final Step: Profile Calibration
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, your account is active, but calibrating your biometric metrics will ensure our progressive overload algorithms suggest optimal weight jumps.
      </p>
      ${buttonHtml('Calibrate Profile', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Complete your athlete profile' }
    ),
    text_body: `Complete your athlete profile\n\nCalibrate your biometrics and daily macro targets at:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 3: WORKOUT AND FITNESS ENGAGEMENT (5)
  // =========================================================================
  {
    id: 'workout-reminder',
    name: 'Daily Workout Session Reminder',
    category: 'workout',
    subject: 'Ready for today’s session? {{routine_name}}',
    preheader: 'Your scheduled training session is locked in for today.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Time to Train: {{routine_name}}
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, consistency is what separates goals from results. Your routine <strong style="color: #00E676;">{{routine_name}}</strong> is ready to log.
      </p>
      ${metricsGridHtml([
        { label: 'Planned Exercises', value: '{{exercise_count}}' },
        { label: 'Estimated Time', value: '{{estimated_duration}}' },
      ])}
      ${buttonHtml('Start Workout Session', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Workout reminder: {{routine_name}}' }
    ),
    text_body: `Fit Host Workout Reminder\n\nHey {{first_name}}, time for {{routine_name}} ({{exercise_count}} exercises, ~{{estimated_duration}}).\n\nStart now: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'routine_name', label: 'Routine Name', type: 'text', defaultValue: 'Push Hypertrophy' },
      { name: 'exercise_count', label: 'Exercise Count', type: 'text', defaultValue: '6 lifts' },
      { name: 'estimated_duration', label: 'Est. Duration', type: 'text', defaultValue: '55 min' },
    ],
    variables: ['first_name', 'routine_name', 'exercise_count', 'estimated_duration'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'workout-streak-milestone',
    name: 'Workout Streak Milestone Alert',
    category: 'workout',
    subject: '🔥 {{streak_days}}-Day Streak Unlocked! Unstoppable Momentum',
    preheader: 'You have logged workouts for {{streak_days}} consecutive days.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        🔥 {{streak_days}}-Day Streak Reached!
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Incredible dedication, {{first_name}}! You just logged your <strong style="color: #FFFFFF;">{{streak_days}}th consecutive day</strong> of focused training.
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 24px; text-align: center; margin: 20px 0;">
        <div style="font-size: 48px; font-weight: 900; color: #00E676; line-height: 1;">{{streak_days}}</div>
        <div style="font-size: 12px; letter-spacing: 2px; color: #9CA3AF; text-transform: uppercase; margin-top: 8px;">Days in a row</div>
      </div>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Keep the chain going. Protect your streak today.
      </p>
      ${buttonHtml('View Streak Analytics', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: '{{streak_days}}-day workout streak unlocked' }
    ),
    text_body: `Fit Host - {{streak_days}}-Day Streak!\n\nAwesome work {{first_name}}! You have completed workouts {{streak_days}} days in a row.\n\nView your streak:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'streak_days', label: 'Streak Days', type: 'number', defaultValue: '7' },
    ],
    variables: ['first_name', 'streak_days'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'workout-pr-celebration',
    name: 'Personal Record (PR) Celebration',
    category: 'workout',
    subject: '🏆 New Personal Record: {{exercise_name}} ({{weight_value}})',
    preheader: 'You hit a new PR on Fit Host today. Hard work pays off.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        🏆 New Personal Record!
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Congratulations {{first_name}}! You smashed your previous best in <strong style="color: #FFFFFF;">{{exercise_name}}</strong>:
      </p>
      ${metricsGridHtml([
        { label: 'Exercise', value: '{{exercise_name}}' },
        { label: 'New Max', value: '{{weight_value}}', change: '+{{pr_gain}}' },
      ])}
      ${buttonHtml('Share Achievement', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'New PR logged on {{exercise_name}}' }
    ),
    text_body: `New Personal Record!\n\nCongrats {{first_name}}! You hit {{weight_value}} on {{exercise_name}} (+{{pr_gain}} increase)!\n\nCheck your PR history:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'exercise_name', label: 'Exercise', type: 'text', defaultValue: 'Barbell Bench Press' },
      { name: 'weight_value', label: 'Weight', type: 'text', defaultValue: '100 kg' },
      { name: 'pr_gain', label: 'Gain', type: 'text', defaultValue: '5 kg' },
    ],
    variables: ['first_name', 'exercise_name', 'weight_value', 'pr_gain'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'workout-rest-day',
    name: 'Rest & Active Recovery Protocols',
    category: 'workout',
    subject: 'Rest day protocol: Recover smarter today',
    preheader: 'Muscle grows when you recover. Nutrition & mobility tips.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Scheduled Recovery Day
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, today is your scheduled recovery day. Growth occurs between sessions when protein synthesis and CNS recovery happen.
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 20px; margin: 20px 0; font-size: 14px; line-height: 1.7; color: #9CA3AF;">
        <div>&bull; <strong style="color: #FFFFFF;">Hydration:</strong> Aim for 3.5 liters of clean water.</div>
        <div>&bull; <strong style="color: #FFFFFF;">Protein Target:</strong> Maintain 1.6 - 2.2g per kg of lean mass.</div>
        <div>&bull; <strong style="color: #FFFFFF;">Light Mobility:</strong> 15-20 min of hip & thoracic spine flow.</div>
      </div>
      ${buttonHtml('Log Mobility Session', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Rest day recovery protocol' }
    ),
    text_body: `Rest Day Protocol\n\nHey {{first_name}}, today is recovery day. Maintain your hydration, hit your protein goals, and get 8 hours of sleep.\n\nOpen dashboard: https://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'workout-re-engagement',
    name: 'Workout Re-engagement (Miss You in the Gym)',
    category: 'workout',
    subject: 'Jump back in, {{first_name}} — your next PR is waiting',
    preheader: 'It has been {{days_inactive}} days since your last logged workout.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Time to Restart the Momentum
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, we noticed you haven't logged a session in <strong style="color: #00E676;">{{days_inactive}} days</strong>. One good workout is all it takes to reignite your consistency.
      </p>
      ${buttonHtml('Resume Training Now', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Jump back in and log today' }
    ),
    text_body: `Hey {{first_name}}, it has been {{days_inactive}} days since your last logged session on Fit Host. Get back on track today:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'days_inactive', label: 'Days Inactive', type: 'number', defaultValue: '5' },
    ],
    variables: ['first_name', 'days_inactive'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 4: HYDRATION AND NUTRITION REMINDERS (5)
  // =========================================================================
  {
    id: 'nutrition-daily-macro-check',
    name: 'Daily Macro Check: Protein & Calorie Goal Status',
    category: 'nutrition',
    subject: 'Daily macro check: {{protein_remaining}}g protein to hit target',
    preheader: 'Keep your nutrition locked in. Here is your current balance.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Daily Macro Breakdown
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, you are close to hitting your daily targets today:
      </p>
      ${metricsGridHtml([
        { label: 'Calories Left', value: '{{calories_remaining}} kcal' },
        { label: 'Protein Left', value: '{{protein_remaining}}g' },
      ])}
      ${buttonHtml('Log Meal in Fit Host', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Daily macro status check' }
    ),
    text_body: `Daily Macro Check\n\nHey {{first_name}}, you have {{calories_remaining}} kcal and {{protein_remaining}}g protein remaining for today.\n\nLog meal: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'calories_remaining', label: 'Calories Left', type: 'number', defaultValue: '450' },
      { name: 'protein_remaining', label: 'Protein Left', type: 'number', defaultValue: '35' },
    ],
    variables: ['first_name', 'calories_remaining', 'protein_remaining'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'nutrition-hydration-boost',
    name: 'Midday Hydration Boost',
    category: 'nutrition',
    subject: '💧 Time for a glass of water: Drink 500ml',
    preheader: 'Stay hydrated for optimal energy, muscular power, and cognitive focus.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        💧 Midday Hydration Check
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        A 2% drop in hydration can reduce muscular power output by up to 15%. Grab a fresh glass of water and hit your hydration mark!
      </p>
      ${metricsGridHtml([
        { label: 'Current Total', value: '{{current_water_ml}} ml' },
        { label: 'Daily Goal', value: '{{target_water_ml}} ml' },
      ])}
      ${buttonHtml('Quick Log 500ml Water', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Midday hydration boost' }
    ),
    text_body: `Midday Hydration Check\n\nCurrent: {{current_water_ml}} ml / Goal: {{target_water_ml}} ml.\n\nLog water: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'current_water_ml', label: 'Current Water (ml)', type: 'number', defaultValue: '1500' },
      { name: 'target_water_ml', label: 'Target Water (ml)', type: 'number', defaultValue: '3000' },
    ],
    variables: ['first_name', 'current_water_ml', 'target_water_ml'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'nutrition-meal-prep-sunday',
    name: 'Weekend Meal Prep & Macro Planning Blueprint',
    category: 'nutrition',
    subject: 'Sunday macro prep: Plan your week for zero excuses',
    preheader: 'Organize your weekly grocery checklist and protein targets in Fit Host.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Sunday Macro Prep Blueprint
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Athletes who plan their weekday meals succeed 3x more reliably than those who guess daily. Pre-plan your calorie and macro split in Fit Host.
      </p>
      ${buttonHtml('Configure Weekly Macro Split', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Sunday macro prep checklist' }
    ),
    text_body: `Sunday Macro Prep Blueprint\n\nPlan your weekly meals and nutrition targets in Fit Host:\nhttps://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'nutrition-water-intake-goal',
    name: 'Hydration Target Reached Notification',
    category: 'nutrition',
    subject: '🎯 Hydration target unlocked: {{target_water_ml}}ml crushed!',
    preheader: 'You hit your daily water goal. Excellent work staying hydrated.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        🎯 Hydration Goal Achieved!
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Great discipline, {{first_name}}! You just logged your target of <strong style="color: #00E676;">{{target_water_ml}} ml</strong> of water today.
      </p>
    `,
      { preheader: 'Hydration goal achieved' }
    ),
    text_body: `Hydration Goal Achieved!\n\nYou hit {{target_water_ml}} ml today. Keep up the great work!`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'target_water_ml', label: 'Target (ml)', type: 'number', defaultValue: '3000' },
    ],
    variables: ['first_name', 'target_water_ml'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'nutrition-calorie-deficit-surplus',
    name: 'Weekly Calorie Balance & Nutrient Breakdown',
    category: 'nutrition',
    subject: 'Your weekly nutrition review: {{weekly_calorie_avg}} kcal average',
    preheader: 'Review your average calorie and macro intake over the last 7 days.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Weekly Calorie & Nutrient Review
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Here is your 7-day nutritional summary:
      </p>
      ${metricsGridHtml([
        { label: 'Avg Calories', value: '{{weekly_calorie_avg}} kcal' },
        { label: 'Avg Protein', value: '{{weekly_protein_avg}}g' },
      ])}
      ${buttonHtml('Inspect Full Nutritional Log', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Weekly calorie and nutrition review' }
    ),
    text_body: `Weekly Nutrition Review\n\nDaily average: {{weekly_calorie_avg}} kcal, {{weekly_protein_avg}}g protein.\n\nView details: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'weekly_calorie_avg', label: 'Avg Calories', type: 'number', defaultValue: '2450' },
      { name: 'weekly_protein_avg', label: 'Avg Protein', type: 'number', defaultValue: '185' },
    ],
    variables: ['first_name', 'weekly_calorie_avg', 'weekly_protein_avg'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 5: PROGRESS REPORTS AND MILESTONES (5)
  // =========================================================================
  {
    id: 'progress-weekly-digest',
    name: 'Weekly Performance Digest & Volume',
    category: 'progress',
    subject: '📊 Your Fit Host Weekly Performance Report ({{total_volume}} kg logged)',
    preheader: 'Your 7-day summary: workouts completed, tonnage lifted, and consistency score.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Weekly Athlete Performance Digest
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Another week of disciplined effort in the books, {{first_name}}. Here is what you achieved over the last 7 days:
      </p>
      ${metricsGridHtml([
        { label: 'Workouts', value: '{{workouts_completed}}' },
        { label: 'Total Tonnage', value: '{{total_volume}} kg', change: '+{{volume_growth}}%' },
        { label: 'New PRs', value: '{{prs_count}}' },
      ])}
      ${buttonHtml('View Full Weekly Breakdown', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Your weekly fitness performance report' }
    ),
    text_body: `Fit Host Weekly Digest\n\nWorkouts: {{workouts_completed}}\nTotal Volume: {{total_volume}} kg (+{{volume_growth}}%)\nNew PRs: {{prs_count}}\n\nFull details: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'workouts_completed', label: 'Workouts', type: 'number', defaultValue: '5' },
      { name: 'total_volume', label: 'Volume (kg)', type: 'text', defaultValue: '34,250' },
      { name: 'volume_growth', label: 'Volume Growth %', type: 'number', defaultValue: '8' },
      { name: 'prs_count', label: 'PRs Count', type: 'number', defaultValue: '2' },
    ],
    variables: ['first_name', 'workouts_completed', 'total_volume', 'volume_growth', 'prs_count'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'progress-monthly-summary',
    name: 'Monthly Training Retrospective',
    category: 'progress',
    subject: '📈 Monthly Training Retrospective: {{total_hours}} hours logged',
    preheader: 'Look back at your last 30 days of workout data and personal records.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Monthly Retrospective: Last 30 Days
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        30 days of relentless execution. Here is your monthly cumulative summary:
      </p>
      ${metricsGridHtml([
        { label: 'Total Hours', value: '{{total_hours}} hrs' },
        { label: 'Total Sets', value: '{{total_sets}} sets' },
      ])}
      ${buttonHtml('View Monthly Analytics', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Monthly training retrospective' }
    ),
    text_body: `Monthly Training Retrospective\n\n{{total_hours}} hours and {{total_sets}} sets logged this month.\n\nView details: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'total_hours', label: 'Total Hours', type: 'number', defaultValue: '22' },
      { name: 'total_sets', label: 'Total Sets', type: 'number', defaultValue: '248' },
    ],
    variables: ['first_name', 'total_hours', 'total_sets'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'progress-weight-trend',
    name: 'Body Composition Trend Analysis',
    category: 'progress',
    subject: '⚖️ Weight trend update: Moving in the right direction',
    preheader: 'Your 30-day moving average weight and body composition curve.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Weight & Body Composition Trend
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, looking past daily water fluctuations, your 30-day moving average is right on track.
      </p>
      ${metricsGridHtml([
        { label: 'Current Avg', value: '{{current_weight}} kg' },
        { label: '30-Day Change', value: '{{weight_delta}} kg' },
      ])}
      ${buttonHtml('Open Trend Chart', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Weight trend update' }
    ),
    text_body: `Weight Trend Update\n\nCurrent 30-day average: {{current_weight}} kg ({{weight_delta}} kg change).\n\nCheck chart: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'current_weight', label: 'Current Weight', type: 'text', defaultValue: '78.4' },
      { name: 'weight_delta', label: 'Weight Delta', type: 'text', defaultValue: '-1.2' },
    ],
    variables: ['first_name', 'current_weight', 'weight_delta'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'progress-century-club',
    name: '100 Workouts Century Club Milestone',
    category: 'progress',
    subject: '🎖️ Welcome to the Century Club: 100 Workouts Logged!',
    preheader: 'Only top 5% of athletes reach this milestone. You made it.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        🎖️ The Century Club (100 Sessions)
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        100 individual gym sessions logged in Fit Host. That is not luck; that is pure discipline.
      </p>
      ${buttonHtml('Claim Your Century Badge', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: '100 workouts completed milestone' }
    ),
    text_body: `100 Workouts Completed!\n\nCongrats {{first_name}}, you are officially in the Century Club with 100 workouts logged in Fit Host.\n\nView profile: https://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'progress-annual-rewind',
    name: 'Annual Year in Review Fitness Legacy',
    category: 'progress',
    subject: '🎆 Your Fit Host Year in Review: Legacy of Gains',
    preheader: 'Every lift, every mile, and every macro logged this year.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Your Year in Review
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        What a year, {{first_name}}! Here is the summary of your annual fitness journey:
      </p>
      ${metricsGridHtml([
        { label: 'Workouts', value: '{{annual_workouts}}' },
        { label: 'Total Tonnage', value: '{{annual_tonnage}} tons' },
      ])}
      ${buttonHtml('View Interactive Year in Review', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Fit Host Year in Review' }
    ),
    text_body: `Fit Host Year in Review\n\n{{annual_workouts}} workouts logged and {{annual_tonnage}} tons lifted this year!\n\nView review: https://fithost.amitrana.tech/dashboard`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'annual_workouts', label: 'Annual Workouts', type: 'number', defaultValue: '184' },
      { name: 'annual_tonnage', label: 'Annual Tonnage', type: 'text', defaultValue: '1,420' },
    ],
    variables: ['first_name', 'annual_workouts', 'annual_tonnage'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 6: PRODUCT UPDATES AND RELEASE ANNOUNCEMENTS (5)
  // =========================================================================
  {
    id: 'product-release-v210',
    name: 'Fit Host v2.1.0 Release Announcement',
    category: 'product',
    subject: '🚀 Fit Host v2.1.0 Released: Offline Sync & High-Speed Timers',
    preheader: 'New updates: SQLite offline caching, custom RPE logging, and updated UI.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Fit Host v2.1.0 is Live
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        We just pushed Fit Host version 2.1.0 with major performance upgrades:
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 20px; margin: 20px 0; font-size: 14px; line-height: 1.7; color: #D1D5DB;">
        <div>&bull; <strong style="color: #00E676;">Zero-Lag Offline Sync:</strong> Full local SQLite persistence queues writes and syncs effortlessly.</div>
        <div>&bull; <strong style="color: #00E676;">Dynamic Workout Timers:</strong> High-contrast floating rest timers with haptic alerts.</div>
        <div>&bull; <strong style="color: #00E676;">Verified Release APK:</strong> Download directly from GitHub Releases with SHA-256 validation.</div>
      </div>
      ${buttonHtml('Read Release Notes & Download', 'https://fithost.amitrana.tech/updates')}
    `,
      { preheader: 'Fit Host v2.1.0 release notes' }
    ),
    text_body: `Fit Host v2.1.0 Released!\n\nNew in this release:\n- Zero-lag offline sync\n- Dynamic workout timers\n- Direct verified APK download\n\nRead more: https://fithost.amitrana.tech/updates`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'product-feature-spotlight',
    name: 'Feature Spotlight: Dynamic Rest Timers',
    category: 'product',
    subject: 'Spotlight: Smarter rest timers for maximum hypertrophy',
    preheader: 'How to use dynamic interval rest periods based on RPE.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Feature Spotlight: Dynamic Rest Timers
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Compound lifts need 2-3 minutes of ATP replenishment, while isolation work needs 60-90s. Fit Host automatically adjusts your countdown timers per exercise.
      </p>
      ${buttonHtml('Try Dynamic Timers', 'https://fithost.amitrana.tech/features')}
    `,
      { preheader: 'Feature spotlight: dynamic rest timers' }
    ),
    text_body: `Spotlight: Dynamic Rest Timers\n\nOptimize recovery between sets with automated exercise-aware rest countdowns.\n\nLearn more: https://fithost.amitrana.tech/features`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'product-maintenance-notice',
    name: 'Scheduled Maintenance Notice',
    category: 'product',
    subject: 'Notice: Scheduled database maintenance on {{maintenance_date}}',
    preheader: 'Fit Host database will undergo maintenance for ~15 minutes. Offline mode remains active.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #F59E0B;">
        Scheduled Platform Upgrade
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        To ensure lightning-fast query speeds as our user base grows, we will perform scheduled database index maintenance on <strong style="color: #FFFFFF;">{{maintenance_date}}</strong> at <strong style="color: #FFFFFF;">{{maintenance_time}}</strong>.
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 10px; padding: 16px; margin: 16px 0; color: #9CA3AF; font-size: 13px;">
        💡 <strong style="color: #FFFFFF;">No workout disruption:</strong> Mobile apps will continue logging offline locally and sync once the database resumes.
      </div>
    `,
      { preheader: 'Scheduled maintenance notice' }
    ),
    text_body: `Scheduled Maintenance Notice\n\nDate: {{maintenance_date}} at {{maintenance_time}}\nExpected window: ~15 minutes.\n\nYour mobile app will continue to record workouts offline without disruption.`,
    fields: [
      { name: 'maintenance_date', label: 'Date', type: 'text', defaultValue: 'Sunday, Oct 25, 2026' },
      { name: 'maintenance_time', label: 'Time', type: 'text', defaultValue: '03:00 - 03:15 UTC' },
    ],
    variables: ['maintenance_date', 'maintenance_time'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'product-beta-invitation',
    name: 'iOS TestFlight Beta Invitation',
    category: 'product',
    subject: 'Exclusive invitation: Test Fit Host on iOS TestFlight',
    preheader: 'Be among the first athletes to run Fit Host on iPhone and Apple Watch.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        You are Invited: iOS TestFlight Beta
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        We are expanding our private iOS beta testing group. Join TestFlight now to test the iOS build with native Apple HealthKit syncing:
      </p>
      ${buttonHtml('Join iOS TestFlight', '{{testflight_url}}')}
    `,
      { preheader: 'iOS TestFlight invitation' }
    ),
    text_body: `Join Fit Host iOS TestFlight Beta\n\nTest the new iOS build with HealthKit integration:\n{{testflight_url}}`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'testflight_url', label: 'TestFlight URL', type: 'url', defaultValue: 'https://testflight.apple.com/join/fithost' },
    ],
    variables: ['first_name', 'testflight_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'product-roadmap-update',
    name: 'Fit Host Roadmap Update (Garmin & Wearables)',
    category: 'product',
    subject: 'Fit Host Roadmap: Garmin Connect, Apple Health & Macro Barcode Scanner',
    preheader: 'Take a peek at what our engineering team is building for Q4 2026.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Product Roadmap: What’s Next
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Here is what is currently in active development at Fit Host:
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 12px; padding: 20px; margin: 20px 0; font-size: 14px; line-height: 1.7; color: #D1D5DB;">
        <div>&bull; <strong style="color: #00E676;">Wearable Heart Rate Sync:</strong> Live HR zones during lift intervals.</div>
        <div>&bull; <strong style="color: #00E676;">Barcode Food Scanner:</strong> Instant macro lookup with verified USDA database.</div>
        <div>&bull; <strong style="color: #00E676;">Garmin Connect Export:</strong> Push completed workout sets directly to Garmin.</div>
      </div>
      ${buttonHtml('Vote on Roadmap Features', 'https://fithost.amitrana.tech/support')}
    `,
      { preheader: 'Fit Host product roadmap' }
    ),
    text_body: `Fit Host Roadmap Update\n\nComing soon:\n- Wearable Heart Rate Sync\n- Barcode Food Scanner\n- Garmin Connect Export\n\nVote on features: https://fithost.amitrana.tech/support`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 7: SUPPORT AND SERVICE COMMUNICATIONS (5)
  // =========================================================================
  {
    id: 'support-ticket-received',
    name: 'Support Request Received Confirmation',
    category: 'support',
    subject: 'We received your request — Ticket #{{ticket_id}}',
    preheader: 'Our engineering support team has received your inquiry.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Support Request Received
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello {{first_name}}, thanks for reaching out. We have created ticket <strong style="color: #00E676;">#{{ticket_id}}</strong> for your inquiry:
      </p>
      <div style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 10px; padding: 16px; margin: 16px 0; font-size: 14px; color: #D1D5DB;">
        <strong style="color: #9CA3AF;">Subject:</strong> {{ticket_subject}}
      </div>
      <p style="margin: 16px 0 0 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        Our team reviews inquiries within 24 hours. You can reply directly to this email to add more details or logs.
      </p>
    `,
      { preheader: 'Support ticket #{{ticket_id}} received' }
    ),
    text_body: `Fit Host Support Ticket #{{ticket_id}}\n\nHello {{first_name}},\n\nWe received your request: "{{ticket_subject}}". Our team is reviewing it and will respond shortly.`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'ticket_id', label: 'Ticket ID', type: 'text', defaultValue: 'FH-8924' },
      { name: 'ticket_subject', label: 'Subject', type: 'text', defaultValue: 'Sync question on Android APK' },
    ],
    variables: ['first_name', 'ticket_id', 'ticket_subject'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'support-ticket-reply',
    name: 'Support Ticket Engineer Response',
    category: 'support',
    subject: 'Update on ticket #{{ticket_id}}: {{ticket_subject}}',
    preheader: 'A member of the Fit Host engineering support team has replied to your inquiry.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Support Ticket Update (#{{ticket_id}})
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello {{first_name}}, here is the latest response regarding your ticket:
      </p>
      <div style="background-color: #0D1016; border-left: 3px solid #00E676; border-radius: 4px; padding: 16px 20px; margin: 20px 0; font-size: 14px; color: #E5E7EB; line-height: 1.7;">
        {{agent_message}}
      </div>
      <p style="margin: 16px 0 0 0; color: #9CA3AF; font-size: 13px;">
        To send a reply, simply reply to this email.
      </p>
    `,
      { preheader: 'Support ticket update' }
    ),
    text_body: `Fit Host Support Ticket #{{ticket_id}}\n\nHello {{first_name}},\n\nUpdate:\n{{agent_message}}\n\nReply directly to this email to follow up.`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'ticket_id', label: 'Ticket ID', type: 'text', defaultValue: 'FH-8924' },
      { name: 'ticket_subject', label: 'Subject', type: 'text', defaultValue: 'Sync issue resolved' },
      { name: 'agent_message', label: 'Message', type: 'textarea', defaultValue: 'We have pushed a patch to resolve the offline queue conflict in v2.1.0.' },
    ],
    variables: ['first_name', 'ticket_id', 'ticket_subject', 'agent_message'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'support-ticket-resolved',
    name: 'Support Ticket Resolution Notice',
    category: 'support',
    subject: 'Ticket #{{ticket_id}} marked as resolved',
    preheader: 'Your inquiry has been resolved. Let us know if you need anything else.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Support Ticket Resolved
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Ticket <strong style="color: #FFFFFF;">#{{ticket_id}}</strong> has been resolved. If you have additional questions, replying will automatically reopen it.
      </p>
      ${buttonHtml('Rate Support Experience', 'https://fithost.amitrana.tech/support')}
    `,
      { preheader: 'Ticket #{{ticket_id}} resolved' }
    ),
    text_body: `Ticket #{{ticket_id}} has been marked resolved. If you need anything else, simply reply to this email.`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'ticket_id', label: 'Ticket ID', type: 'text', defaultValue: 'FH-8924' },
    ],
    variables: ['first_name', 'ticket_id'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'support-account-deletion',
    name: 'Account Deletion Request Notice',
    category: 'support',
    subject: 'Action required: Fit Host account deletion request',
    preheader: 'We received a request to permanently delete your Fit Host account.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #EF4444;">
        Account Deletion Request
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello {{first_name}}, a request was made to permanently delete your Fit Host athlete account and wipe all workout and nutrition records.
      </p>
      <div style="background-color: #0D1016; border: 1px solid #EF4444; border-radius: 10px; padding: 16px; margin: 16px 0; color: #FCA5A5; font-size: 13px; line-height: 1.6;">
        ⚠️ <strong style="color: #FFFFFF;">Permanent Action:</strong> Once confirmed, all routines, custom lifts, and body metrics cannot be recovered.
      </div>
      ${buttonHtml('Cancel Deletion Request', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Account deletion request' }
    ),
    text_body: `Account Deletion Request\n\nHello {{first_name}}, we received a request to permanently delete your Fit Host account. If you did not make this request, visit https://fithost.amitrana.tech/dashboard immediately to cancel it.`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'support-data-export',
    name: 'Athlete Data Export (ZIP / CSV)',
    category: 'support',
    subject: 'Your Fit Host performance data export is ready',
    preheader: 'Download your full training logs, body measurements, and nutrition history.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Your Data Export is Ready
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hello {{first_name}}, your requested data export has been compiled into an archive containing CSV files for all your workouts, routines, PR records, and macro logs.
      </p>
      ${buttonHtml('Download Data Archive', '{{download_url}}')}
      <p style="margin: 16px 0 0 0; color: #9CA3AF; font-size: 13px;">
        This download link is cryptographically signed and expires in 48 hours.
      </p>
    `,
      { preheader: 'Data export download ready' }
    ),
    text_body: `Fit Host Data Export\n\nHello {{first_name}}, your data export is ready. Download it here:\n{{download_url}}\n(Expires in 48 hours)`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'download_url', label: 'Download URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/dashboard' },
    ],
    variables: ['first_name', 'download_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 8: FEEDBACK AND SURVEYS (5)
  // =========================================================================
  {
    id: 'feedback-initial-experience',
    name: 'First Week Experience Feedback',
    category: 'feedback',
    subject: 'How is your first week on Fit Host going, {{first_name}}?',
    preheader: 'Tell our engineering team what you like and what we can improve.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        How Was Your First Week?
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, you have been using Fit Host for a week now. Did the app make logging workouts simpler and faster?
      </p>
      ${buttonHtml('Share 2-Minute Feedback', 'https://fithost.amitrana.tech/support?topic=feedback')}
    `,
      { preheader: 'How is your first week going?' }
    ),
    text_body: `How was your first week on Fit Host?\n\nTell us what you think: https://fithost.amitrana.tech/support?topic=feedback`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'feedback-feature-request',
    name: 'Feature Request & Ideas Submission',
    category: 'feedback',
    subject: 'Got an idea for Fit Host? Tell our developers',
    preheader: 'We build directly based on user requests from athletes like you.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        What Should We Build Next?
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        We read every single feature submission. If there is a lift variation, chart type, or wearable integration you want, let us know.
      </p>
      ${buttonHtml('Submit Feature Idea', 'https://fithost.amitrana.tech/support?topic=ideas')}
    `,
      { preheader: 'Submit your feature ideas' }
    ),
    text_body: `What should we build next on Fit Host?\n\nSubmit your ideas: https://fithost.amitrana.tech/support?topic=ideas`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'feedback-nps-survey',
    name: '1-Minute Athlete Satisfaction Survey (NPS)',
    category: 'feedback',
    subject: 'Quick 1-minute question for {{first_name}}',
    preheader: 'How likely are you to recommend Fit Host to a workout partner?',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Quick 1-Minute Athlete Survey
      </h1>
      <p style="margin: 0 0 20px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        On a scale of 1 to 10, how likely are you to recommend Fit Host to an athlete friend?
      </p>
      <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0;">
        <tr>
          ${[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            .map(
              (n) => `
            <td align="center" style="padding: 4px;">
              <a href="https://fithost.amitrana.tech/support?score=${n}" style="display: block; width: 34px; height: 34px; line-height: 34px; background-color: #0D1016; border: 1px solid #1E2330; border-radius: 6px; color: ${
                n >= 9 ? '#00E676' : '#FFFFFF'
              }; font-weight: 800; text-decoration: none; font-size: 14px;">${n}</a>
            </td>
          `
            )
            .join('')}
        </tr>
      </table>
    `,
      { preheader: 'Quick 1-minute athlete survey' }
    ),
    text_body: `How likely are you to recommend Fit Host? Take our 60-second survey at https://fithost.amitrana.tech/support`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'feedback-post-resolution',
    name: 'Support Experience Rating',
    category: 'feedback',
    subject: 'How did our support team do on ticket #{{ticket_id}}?',
    preheader: 'Your feedback directly helps us improve our customer service quality.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Rate Your Support Experience
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        We recently helped you with ticket <strong style="color: #FFFFFF;">#{{ticket_id}}</strong>. Was your issue resolved quickly and clearly?
      </p>
      ${buttonHtml('Rate Support (Good / Bad)', 'https://fithost.amitrana.tech/support')}
    `,
      { preheader: 'Rate your support experience' }
    ),
    text_body: `Rate your support experience on ticket #{{ticket_id}}:\nhttps://fithost.amitrana.tech/support`,
    fields: [
      { name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' },
      { name: 'ticket_id', label: 'Ticket ID', type: 'text', defaultValue: 'FH-8924' },
    ],
    variables: ['first_name', 'ticket_id'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'feedback-app-store-review',
    name: 'App Store / Play Store Review Request',
    category: 'feedback',
    subject: 'Enjoying your gains with Fit Host? Leave us a review',
    preheader: 'A quick 5-star rating helps other serious lifters discover Fit Host.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Enjoying Fit Host?
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Hey {{first_name}}, as an independent fitness engine, athlete reviews mean the world to us. If Fit Host has helped your consistency, leaving a review takes 30 seconds:
      </p>
      ${buttonHtml('Leave a Quick Review', 'https://fithost.amitrana.tech/download')}
    `,
      { preheader: 'Leave a quick review for Fit Host' }
    ),
    text_body: `Enjoying Fit Host? Leave us a review:\nhttps://fithost.amitrana.tech/download`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 9: GENERAL ANNOUNCEMENTS (5)
  // =========================================================================
  {
    id: 'announcement-community-challenge',
    name: 'Community Fitness Challenge Announcement',
    category: 'announcement',
    subject: '🏆 30-Day Fit Host Consistency Challenge Starts Monday!',
    preheader: 'Log 20 sessions in 30 days and earn the exclusive Gold Athlete badge.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        30-Day Consistency Challenge
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Join thousands of lifters worldwide in our upcoming 30-day challenge. Log 20 complete sessions before the end of the month to unlock the digital finisher badge.
      </p>
      ${buttonHtml('Join the Challenge', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Join the 30-day consistency challenge' }
    ),
    text_body: `30-Day Consistency Challenge starts Monday! Join at https://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'announcement-policy-update',
    name: 'Terms of Service & Privacy Policy Update',
    category: 'announcement',
    subject: 'Updates to our Terms of Service & Privacy Policy',
    preheader: 'Summary of improvements to our security, data isolation, and user controls.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Policy Updates Notice
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        We have updated our Terms of Service and Privacy Policy to clearly reflect our zero-third-party-ad policy and strict biometric encryption protocols.
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px;">
        Read the updated agreements anytime on our verified domains:
      </p>
      ${buttonHtml('Review Privacy Policy', 'https://fithost.amitrana.tech/privacy')}
    `,
      { preheader: 'Privacy and Terms update notice', showUnsubscribe: false }
    ),
    text_body: `Fit Host Policy Updates\n\nWe updated our Terms of Service and Privacy Policy. Review them at https://fithost.amitrana.tech/privacy`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'announcement-holiday-hours',
    name: 'Holiday Support Schedule & Keep Moving Tips',
    category: 'announcement',
    subject: 'Holiday schedule: Gyms close, but gains continue',
    preheader: 'Bodyweight maintenance workouts and holiday support hours.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Holiday Schedule & Training Tips
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Traveling or visiting family this holiday season? Fit Host includes zero-equipment bodyweight routines so you never have to break your habit.
      </p>
      ${buttonHtml('View Travel Workout Routines', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: 'Holiday training tips' }
    ),
    text_body: `Holiday Training Schedule\n\nAccess bodyweight hotel routines in Fit Host: https://fithost.amitrana.tech/dashboard`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'announcement-trainer-spotlight',
    name: 'Coach Spotlight: High-Intensity Interval Protocols',
    category: 'announcement',
    subject: 'Coach spotlight: The 4-minute tabata protocol for conditioning',
    preheader: 'Scientific cardio protocols to boost VO2 max without sacrificing muscle.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        Coach Spotlight: HIIT Protocols
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Learn how short 4-minute anaerobic intervals can dramatically improve cardiovascular endurance while preserving strength.
      </p>
      ${buttonHtml('Read Coaching Article', 'https://fithost.amitrana.tech/guides')}
    `,
      { preheader: 'Coach spotlight article' }
    ),
    text_body: `Coach Spotlight: HIIT Protocols\n\nRead the full article: https://fithost.amitrana.tech/guides`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'announcement-brand-refresh',
    name: 'Brand Refresh: Sleek Dark Mode & Neon Green',
    category: 'announcement',
    subject: 'The new Fit Host look: High-contrast Dark Mode & Neon Green',
    preheader: 'Designed for dark gym environments with maximum readability.',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #00E676;">
        Fit Host 2026 Brand Refresh
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Notice something new? We have updated our complete visual identity with deep charcoal (#0B0D11) and electric neon green accents (#00E676) for effortless viewing during intense sessions.
      </p>
      ${buttonHtml('Experience the New Design', 'https://fithost.amitrana.tech')}
    `,
      { preheader: 'Fit Host brand refresh' }
    ),
    text_body: `Fit Host Brand Refresh\n\nCheck out our updated website and apps at https://fithost.amitrana.tech`,
    fields: [{ name: 'first_name', label: 'First Name', type: 'text', defaultValue: 'Athlete' }],
    variables: ['first_name'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },

  // =========================================================================
  // CATEGORY 10: BLANK CUSTOM TEMPLATES / FOUNDATION LAYOUTS (5)
  // =========================================================================
  {
    id: 'blank-canvas-minimal',
    name: 'Blank Minimalist Template (Clean Document)',
    category: 'blank',
    subject: '{{subject}}',
    preheader: '{{preheader}}',
    html_body: `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{{subject}}</title>
</head>
<body style="margin:0;padding:24px;background:#0B0D11;color:#FFFFFF;font-family:sans-serif;">
  <div style="max-width:600px;margin:0 auto;background:#12151C;border:1px solid #222734;border-radius:12px;padding:32px;">
    <h1 style="color:#00E676;margin:0 0 16px;">{{headline}}</h1>
    <p style="color:#D1D5DB;line-height:1.6;">{{body_content}}</p>
  </div>
</body>
</html>`,
    text_body: `{{headline}}\n\n{{body_content}}`,
    fields: [
      { name: 'subject', label: 'Subject', type: 'text', defaultValue: 'Custom Notification' },
      { name: 'preheader', label: 'Preheader', type: 'text', defaultValue: 'Important message from Fit Host' },
      { name: 'headline', label: 'Headline', type: 'text', defaultValue: 'Custom Headline' },
      { name: 'body_content', label: 'Body Text', type: 'textarea', defaultValue: 'Enter your custom email content here.' },
    ],
    variables: ['subject', 'preheader', 'headline', 'body_content'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'blank-hero-cta',
    name: 'Foundation Layout: Dark Header, Body & Neon CTA',
    category: 'blank',
    subject: '{{subject}}',
    preheader: '{{preheader}}',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        {{headline}}
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        {{lead_paragraph}}
      </p>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        {{secondary_paragraph}}
      </p>
      ${buttonHtml('{{cta_label}}', '{{cta_url}}')}
    `,
      { preheader: '{{preheader}}' }
    ),
    text_body: `{{headline}}\n\n{{lead_paragraph}}\n\n{{secondary_paragraph}}\n\nAction: {{cta_url}}`,
    fields: [
      { name: 'subject', label: 'Subject', type: 'text', defaultValue: 'Announcement from Fit Host' },
      { name: 'preheader', label: 'Preheader', type: 'text', defaultValue: 'Check out the latest news' },
      { name: 'headline', label: 'Headline', type: 'text', defaultValue: 'Headline Text Here' },
      { name: 'lead_paragraph', label: 'Lead Paragraph', type: 'textarea', defaultValue: 'Write the primary message here.' },
      { name: 'secondary_paragraph', label: 'Secondary Paragraph', type: 'textarea', defaultValue: 'Write additional details here.' },
      { name: 'cta_label', label: 'Button Label', type: 'text', defaultValue: 'Learn More' },
      { name: 'cta_url', label: 'Button URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech' },
    ],
    variables: ['subject', 'preheader', 'headline', 'lead_paragraph', 'secondary_paragraph', 'cta_label', 'cta_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'blank-two-column-metrics',
    name: 'Foundation Layout: 2-Column Metrics Cards',
    category: 'blank',
    subject: '{{subject}}',
    preheader: '{{preheader}}',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        {{headline}}
      </h1>
      <p style="margin: 0 0 16px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        {{description}}
      </p>
      ${metricsGridHtml([
        { label: '{{metric_1_label}}', value: '{{metric_1_value}}' },
        { label: '{{metric_2_label}}', value: '{{metric_2_value}}' },
      ])}
      ${buttonHtml('{{cta_label}}', '{{cta_url}}')}
    `,
      { preheader: '{{preheader}}' }
    ),
    text_body: `{{headline}}\n\n{{description}}\n\n{{metric_1_label}}: {{metric_1_value}}\n{{metric_2_label}}: {{metric_2_value}}\n\nAction: {{cta_url}}`,
    fields: [
      { name: 'subject', label: 'Subject', type: 'text', defaultValue: 'Performance Metrics' },
      { name: 'preheader', label: 'Preheader', type: 'text', defaultValue: 'Your metrics overview' },
      { name: 'headline', label: 'Headline', type: 'text', defaultValue: 'Weekly Performance' },
      { name: 'description', label: 'Description', type: 'textarea', defaultValue: 'Summary of performance metrics.' },
      { name: 'metric_1_label', label: 'Metric 1 Label', type: 'text', defaultValue: 'Volume' },
      { name: 'metric_1_value', label: 'Metric 1 Value', type: 'text', defaultValue: '12,500 kg' },
      { name: 'metric_2_label', label: 'Metric 2 Label', type: 'text', defaultValue: 'Completion' },
      { name: 'metric_2_value', label: 'Metric 2 Value', type: 'text', defaultValue: '100%' },
      { name: 'cta_label', label: 'Button Label', type: 'text', defaultValue: 'View Analytics' },
      { name: 'cta_url', label: 'Button URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech/dashboard' },
    ],
    variables: ['subject', 'preheader', 'headline', 'description', 'metric_1_label', 'metric_1_value', 'metric_2_label', 'metric_2_value', 'cta_label', 'cta_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'blank-announcement-card',
    name: 'Foundation Layout: High-Priority Announcement Card',
    category: 'blank',
    subject: '{{subject}}',
    preheader: '{{preheader}}',
    html_body: wrapInFitHostEmailLayout(
      `
      <div style="background-color: #0D1016; border-left: 4px solid #00E676; border-radius: 8px; padding: 20px; margin-bottom: 24px;">
        <h2 style="margin: 0 0 10px 0; font-size: 20px; font-weight: 800; color: #FFFFFF;">{{alert_title}}</h2>
        <p style="margin: 0; color: #D1D5DB; font-size: 14px; line-height: 1.6;">{{alert_message}}</p>
      </div>
      <p style="margin: 0 0 20px 0; color: #9CA3AF; font-size: 14px; line-height: 1.6;">
        {{additional_instructions}}
      </p>
      ${buttonHtml('{{action_label}}', '{{action_url}}')}
    `,
      { preheader: '{{preheader}}' }
    ),
    text_body: `{{alert_title}}\n\n{{alert_message}}\n\n{{additional_instructions}}\n\nLink: {{action_url}}`,
    fields: [
      { name: 'subject', label: 'Subject', type: 'text', defaultValue: 'Important Notice' },
      { name: 'preheader', label: 'Preheader', type: 'text', defaultValue: 'Priority announcement' },
      { name: 'alert_title', label: 'Alert Title', type: 'text', defaultValue: 'System Notice' },
      { name: 'alert_message', label: 'Alert Message', type: 'textarea', defaultValue: 'Important operational message for all athletes.' },
      { name: 'additional_instructions', label: 'Instructions', type: 'textarea', defaultValue: 'Please follow the link below for more details.' },
      { name: 'action_label', label: 'Action Label', type: 'text', defaultValue: 'Check Status' },
      { name: 'action_url', label: 'Action URL', type: 'url', defaultValue: 'https://fithost.amitrana.tech' },
    ],
    variables: ['subject', 'preheader', 'alert_title', 'alert_message', 'additional_instructions', 'action_label', 'action_url'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'blank-transactional-receipt',
    name: 'Foundation Layout: Transactional Receipt & Table Data',
    category: 'blank',
    subject: '{{subject}}',
    preheader: '{{preheader}}',
    html_body: wrapInFitHostEmailLayout(
      `
      <h1 class="hero-title" style="margin: 0 0 16px 0; font-size: 24px; font-weight: 800; color: #FFFFFF;">
        {{receipt_title}}
      </h1>
      <p style="margin: 0 0 20px 0; color: #D1D5DB; font-size: 15px; line-height: 1.6;">
        Reference: <strong style="color: #00E676;">{{reference_number}}</strong> &bull; Date: {{transaction_date}}
      </p>
      <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0D1016; border: 1px solid #1E2330; border-radius: 10px; margin: 20px 0; overflow: hidden;">
        <tr style="border-bottom: 1px solid #1E2330; background-color: #151922;">
          <th align="left" style="padding: 12px 16px; color: #9CA3AF; font-size: 12px; text-transform: uppercase;">Item</th>
          <th align="right" style="padding: 12px 16px; color: #9CA3AF; font-size: 12px; text-transform: uppercase;">Amount</th>
        </tr>
        <tr>
          <td style="padding: 12px 16px; color: #FFFFFF; font-size: 14px;">{{item_name}}</td>
          <td align="right" style="padding: 12px 16px; color: #FFFFFF; font-size: 14px; font-weight: 700;">{{item_amount}}</td>
        </tr>
      </table>
      ${buttonHtml('View Invoices', 'https://fithost.amitrana.tech/dashboard')}
    `,
      { preheader: '{{preheader}}' }
    ),
    text_body: `{{receipt_title}}\n\nRef: {{reference_number}}\nDate: {{transaction_date}}\n{{item_name}}: {{item_amount}}`,
    fields: [
      { name: 'subject', label: 'Subject', type: 'text', defaultValue: 'Receipt for your transaction' },
      { name: 'preheader', label: 'Preheader', type: 'text', defaultValue: 'Your Fit Host receipt' },
      { name: 'receipt_title', label: 'Title', type: 'text', defaultValue: 'Confirmation Receipt' },
      { name: 'reference_number', label: 'Reference Number', type: 'text', defaultValue: 'FH-REC-4891' },
      { name: 'transaction_date', label: 'Date', type: 'text', defaultValue: 'October 21, 2026' },
      { name: 'item_name', label: 'Item Name', type: 'text', defaultValue: 'Athlete Pro Subscription' },
      { name: 'item_amount', label: 'Amount', type: 'text', defaultValue: '$0.00 (Free)' },
    ],
    variables: ['subject', 'preheader', 'receipt_title', 'reference_number', 'transaction_date', 'item_name', 'item_amount'],
    status: 'published',
    version: 1,
    created_at: NOW,
    updated_at: NOW,
  },
];

export function getTemplateById(id: string): EmailTemplate | undefined {
  return INITIAL_50_EMAIL_TEMPLATES.find((t) => t.id === id);
}

export function getTemplatesByCategory(category: string): EmailTemplate[] {
  return INITIAL_50_EMAIL_TEMPLATES.filter((t) => t.category === category);
}
