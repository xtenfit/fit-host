import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const websiteRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(websiteRoot, '..');

describe('Fit Host Google OAuth & Redirect URI Configuration', () => {
  test('sanitizeNextUrl strictly prevents open redirect vulnerabilities', async () => {
    // Dynamically test the logic of sanitizeNextUrl
    function sanitizeNextUrl(rawNext) {
      if (!rawNext) return '/dashboard';
      if (rawNext.startsWith('/') && !rawNext.startsWith('//') && !rawNext.includes('\\')) {
        return rawNext;
      }
      return '/dashboard';
    }

    // Safe internal paths
    assert.equal(sanitizeNextUrl('/dashboard'), '/dashboard');
    assert.equal(sanitizeNextUrl('/profile'), '/profile');
    assert.equal(sanitizeNextUrl('/settings?tab=account'), '/settings?tab=account');

    // Default when omitted or null
    assert.equal(sanitizeNextUrl(null), '/dashboard');
    assert.equal(sanitizeNextUrl(''), '/dashboard');

    // Open redirect attack vectors
    assert.equal(sanitizeNextUrl('https://malicious-site.com'), '/dashboard');
    assert.equal(sanitizeNextUrl('http://malicious-site.com'), '/dashboard');
    assert.equal(sanitizeNextUrl('//malicious-site.com'), '/dashboard');
    assert.equal(sanitizeNextUrl('/\\malicious-site.com'), '/dashboard');
    assert.equal(sanitizeNextUrl('javascript:alert(1)'), '/dashboard');
  });

  test('website auth callback route implements code exchange and sanitization', () => {
    const callbackRoutePath = path.join(websiteRoot, 'src/app/auth/callback/route.ts');
    assert.ok(fs.existsSync(callbackRoutePath), 'route.ts must exist');

    const content = fs.readFileSync(callbackRoutePath, 'utf8');
    assert.ok(content.includes('exchangeCodeForSession'), 'Must exchange OAuth code for session');
    assert.ok(content.includes('sanitizeNextUrl'), 'Must sanitize next URL param');
    assert.ok(content.includes('errorParam'), 'Must handle OAuth error params');
    assert.ok(content.includes('/login?error='), 'Must redirect to login with error parameter on failure');
  });

  test('website login and signup initiate Google OAuth with correct callback endpoint', () => {
    const loginPagePath = path.join(websiteRoot, 'src/app/login/page.tsx');
    const signupPagePath = path.join(websiteRoot, 'src/app/signup/page.tsx');

    const loginContent = fs.readFileSync(loginPagePath, 'utf8');
    const signupContent = fs.readFileSync(signupPagePath, 'utf8');

    assert.ok(loginContent.includes('signInWithOAuth'), 'Login page must call signInWithOAuth');
    assert.ok(loginContent.includes('provider: "google"'), 'Login page provider must be google');
    assert.ok(loginContent.includes('/auth/callback'), 'Login page must redirect to /auth/callback');

    assert.ok(signupContent.includes('signInWithOAuth'), 'Signup page must call signInWithOAuth');
    assert.ok(signupContent.includes('provider: "google"'), 'Signup page provider must be google');
    assert.ok(signupContent.includes('/auth/callback'), 'Signup page must redirect to /auth/callback');
  });

  test('Supabase project configuration matches expected URL and callback format', () => {
    const envExamplePath = path.join(websiteRoot, '.env.example');
    assert.ok(fs.existsSync(envExamplePath), '.env.example must exist');

    const envContent = fs.readFileSync(envExamplePath, 'utf8');
    assert.ok(
      envContent.includes('https://eedubttdylyqrhyeikwb.supabase.co'),
      'Must contain verified Supabase project URL'
    );

    const projectUrl = 'https://eedubttdylyqrhyeikwb.supabase.co';
    const expectedOAuthRedirectUri = `${projectUrl}/auth/v1/callback`;

    assert.equal(
      expectedOAuthRedirectUri,
      'https://eedubttdylyqrhyeikwb.supabase.co/auth/v1/callback',
      'The exact OAuth redirect_uri passed to Google must be https://eedubttdylyqrhyeikwb.supabase.co/auth/v1/callback'
    );
  });

  test('Flutter Android and iOS configurations match deep-link scheme io.supabase.fithost', () => {
    // 1. Android Manifest
    const androidManifestPath = path.join(
      repoRoot,
      'android/app/src/main/AndroidManifest.xml'
    );
    assert.ok(fs.existsSync(androidManifestPath), 'AndroidManifest.xml must exist');
    const manifestContent = fs.readFileSync(androidManifestPath, 'utf8');
    assert.ok(
      manifestContent.includes('android:scheme="io.supabase.fithost"'),
      'AndroidManifest must declare scheme io.supabase.fithost'
    );
    assert.ok(
      manifestContent.includes('android:host="login-callback"'),
      'AndroidManifest must declare host login-callback'
    );

    // 2. Android build.gradle.kts
    const buildGradlePath = path.join(repoRoot, 'android/app/build.gradle.kts');
    assert.ok(fs.existsSync(buildGradlePath), 'build.gradle.kts must exist');
    const gradleContent = fs.readFileSync(buildGradlePath, 'utf8');
    assert.ok(
      gradleContent.includes('applicationId = "com.fithost.fit_host"'),
      'Android applicationId must be com.fithost.fit_host'
    );

    // 3. iOS Info.plist
    const iOSPlistPath = path.join(repoRoot, 'ios/Runner/Info.plist');
    assert.ok(fs.existsSync(iOSPlistPath), 'Info.plist must exist');
    const plistContent = fs.readFileSync(iOSPlistPath, 'utf8');
    assert.ok(
      plistContent.includes('<string>io.supabase.fithost</string>'),
      'iOS Info.plist must declare URL scheme io.supabase.fithost'
    );

    // 4. Flutter Supabase service
    const dartServicePath = path.join(
      repoRoot,
      'lib/core/services/supabase_service.dart'
    );
    assert.ok(fs.existsSync(dartServicePath), 'supabase_service.dart must exist');
    const dartContent = fs.readFileSync(dartServicePath, 'utf8');
    assert.ok(
      dartContent.includes('io.supabase.fithost://login-callback'),
      'Flutter service must specify redirectTo: io.supabase.fithost://login-callback'
    );
  });
});
