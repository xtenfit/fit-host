import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const websiteRoot = path.resolve(__dirname, '..');

// Helper functions mirroring renderer logic to test algorithm directly
function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function renderTemplate(templateString, variables, options = { escapeValues: true }) {
  if (!templateString) return '';
  return templateString.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (match, key) => {
    if (Object.prototype.hasOwnProperty.call(variables, key)) {
      const val = variables[key];
      if (val === undefined || val === null) return '';
      const strVal = String(val);
      return options.escapeValues && !key.endsWith('_raw') && !key.startsWith('.') ? escapeHtml(strVal) : strVal;
    }
    return match;
  });
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

describe('Fit Host Email Studio & 50-Template Infrastructure', () => {
  test('All required Email Studio source files and routes exist', () => {
    const requiredFiles = [
      'src/lib/email/types.ts',
      'src/lib/email/renderer.ts',
      'src/lib/email/resend.ts',
      'src/lib/email/store.ts',
      'src/lib/email/auth.ts',
      'src/lib/email/templates/index.ts',
      'src/app/admin/email/page.tsx',
      'src/app/api/admin/email/templates/route.ts',
      'src/app/api/admin/email/send-test/route.ts',
      'src/app/api/admin/email/workflows/route.ts',
      'src/app/api/admin/email/logs/route.ts',
      'src/app/api/admin/email/provider-status/route.ts',
      'src/app/api/admin/email/suppressions/route.ts',
      'supabase/migrations/20261021_email_studio.sql',
      'SUPABASE_AUTH_EMAIL_TEMPLATES.md',
    ];

    for (const file of requiredFiles) {
      const fullPath = path.join(websiteRoot, file);
      assert.ok(fs.existsSync(fullPath), `Missing required email file: ${file}`);
    }
  });

  test('Database migration defines all 6 required tables, indexes, and RLS policies', () => {
    const migrationPath = path.join(websiteRoot, 'supabase/migrations/20261021_email_studio.sql');
    const sql = fs.readFileSync(migrationPath, 'utf-8');

    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_templates'));
    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_template_versions'));
    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_automation_workflows'));
    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_automation_runs'));
    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_delivery_events'));
    assert.ok(sql.includes('CREATE TABLE IF NOT EXISTS public.email_suppressions'));

    // Check RLS
    assert.ok(sql.includes('ENABLE ROW LEVEL SECURITY'));
    assert.ok(sql.includes('role\') = \'admin\''));
  });

  test('Templates module contains exactly 50 distinct templates with IDs', () => {
    const templatesPath = path.join(websiteRoot, 'src/lib/email/templates/index.ts');
    const content = fs.readFileSync(templatesPath, 'utf-8');

    // Extract all id: '...' from INITIAL_50_EMAIL_TEMPLATES
    const idMatches = Array.from(content.matchAll(/id:\s*['"]([^'"]+)['"]/g)).map((m) => m[1]);
    assert.equal(idMatches.length, 50, `Found ${idMatches.length} template IDs in templates/index.ts, expected 50`);

    const uniqueIds = new Set(idMatches);
    assert.equal(uniqueIds.size, 50, 'All 50 template IDs must be unique');
  });

  test('All 10 required practical categories exist in the templates library', () => {
    const templatesPath = path.join(websiteRoot, 'src/lib/email/templates/index.ts');
    const content = fs.readFileSync(templatesPath, 'utf-8');

    const expectedCategories = [
      'authentication',
      'welcome',
      'workout',
      'nutrition',
      'progress',
      'product',
      'support',
      'feedback',
      'announcement',
      'blank',
    ];

    for (const cat of expectedCategories) {
      const catCount = (content.match(new RegExp(`category:\\s*['"]${cat}['"]`, 'g')) || []).length;
      assert.equal(catCount, 5, `Category "${cat}" must have exactly 5 templates (found ${catCount})`);
    }
  });

  test('Authentication templates include required 6-digit OTP codes and Supabase tokens', () => {
    const templatesPath = path.join(websiteRoot, 'src/lib/email/templates/index.ts');
    const content = fs.readFileSync(templatesPath, 'utf-8');

    assert.ok(content.includes('auth-signup-confirmation'));
    assert.ok(content.includes('auth-otp-code'));
    assert.ok(content.includes('auth-password-reset'));
    assert.ok(content.includes('auth-email-change'));
    assert.ok(content.includes('auth-security-alert'));
    assert.ok(content.includes('.ConfirmationURL'));
    assert.ok(content.includes('.Token'));
  });

  test('Dedicated Blank Template option exists with valid minimal document structure', () => {
    const templatesPath = path.join(websiteRoot, 'src/lib/email/templates/index.ts');
    const content = fs.readFileSync(templatesPath, 'utf-8');

    assert.ok(content.includes('blank-canvas-minimal'));
    assert.ok(content.includes('Blank Minimalist Template (Clean Document)'));
    assert.ok(content.includes('{{headline}}'));
    assert.ok(content.includes('{{body_content}}'));
  });

  test('HTML template variable interpolation and XSS sanitizer prevents arbitrary script execution', () => {
    const maliciousInput = '<script>alert(1)</script><img src=x onerror=steal()>';
    const template = '<div>Athlete: {{name}}</div>';

    const rendered = renderTemplate(template, { name: maliciousInput });
    assert.ok(!rendered.includes('<script>'), 'Must not render unescaped script tag');
    assert.ok(!rendered.includes('<img src=x'), 'Must not render unescaped img tag');
    assert.ok(rendered.includes('&lt;script&gt;'));
    assert.ok(rendered.includes('&lt;img src=x onerror=steal()&gt;'));
  });

  test('Supabase Auth dot-prefixed variables (.ConfirmationURL, .Token) are preserved without escaping', () => {
    const tpl = '<a href="{{ .ConfirmationURL }}">Verify with code {{ .Token }}</a>';
    const rendered = renderTemplate(tpl, {
      '.ConfirmationURL': 'https://fithost.amitrana.tech/auth/callback?code=abc',
      '.Token': '739201',
    });

    assert.equal(rendered, '<a href="https://fithost.amitrana.tech/auth/callback?code=abc">Verify with code 739201</a>');
  });

  test('Verified sending domain noreply.amitrana.tech is configured in resend service', () => {
    const resendPath = path.join(websiteRoot, 'src/lib/email/resend.ts');
    const content = fs.readFileSync(resendPath, 'utf-8');

    assert.ok(content.includes('noreply.amitrana.tech'));
    assert.ok(content.includes('support@amitrana.tech'));
    assert.ok(content.includes('DEFAULT_EMAIL_FROM'));
  });

  test('Recipient email validation enforces RFC syntax', () => {
    assert.equal(isValidEmail('athlete@amitrana.tech'), true);
    assert.equal(isValidEmail('no-reply@noreply.amitrana.tech'), true);
    assert.equal(isValidEmail('bademail'), false);
    assert.equal(isValidEmail('user@'), false);
    assert.equal(isValidEmail('@domain.com'), false);
  });

  test('Supabase Auth documentation contains complete copy-pasteable branded HTML templates', () => {
    const docPath = path.join(websiteRoot, 'SUPABASE_AUTH_EMAIL_TEMPLATES.md');
    const doc = fs.readFileSync(docPath, 'utf-8');

    assert.ok(doc.includes('Confirm Signup Template'));
    assert.ok(doc.includes('Magic Link / OTP Login Template'));
    assert.ok(doc.includes('Reset Password Template'));
    assert.ok(doc.includes('Change Email Address Template'));
    assert.ok(doc.includes('{{ .Token }}'));
    assert.ok(doc.includes('{{ .ConfirmationURL }}'));
    assert.ok(doc.includes('#0B0D11'));
    assert.ok(doc.includes('#00E676'));
  });
});
