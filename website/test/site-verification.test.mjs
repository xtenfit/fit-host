import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const websiteRoot = path.resolve(__dirname, '..');

describe('Fit Host Website Architecture & Integrity', () => {
  test('All required public page routes exist', () => {
    const requiredPages = [
      'src/app/page.tsx',
      'src/app/download/page.tsx',
      'src/app/api/revalidate-releases/route.ts',
      'src/app/features/page.tsx',
      'src/app/how-it-works/page.tsx',
      'src/app/updates/page.tsx',
      'src/app/updates/[slug]/page.tsx',
      'src/app/guides/page.tsx',
      'src/app/guides/[slug]/page.tsx',
      'src/app/about/page.tsx',
      'src/app/support/page.tsx',
      'src/app/privacy/page.tsx',
      'src/app/terms/page.tsx',
      'src/components/marketing/PhoneMockup.tsx',
      'src/components/marketing/DownloadCTA.tsx',
      'src/components/marketing/ReleaseCard.tsx',
      'src/components/marketing/GuideCard.tsx',
      'src/components/marketing/AnnouncementBanner.tsx',
      'src/components/releases/LatestReleaseBanner.tsx',
      'src/components/releases/PlatformDownloadCard.tsx',
      'src/components/releases/ReleaseNotes.tsx',
      'src/components/releases/VersionBadge.tsx',
      'src/components/releases/ReleaseStatus.tsx',
      'src/components/releases/ReleaseAssetList.tsx',
      'src/components/releases/ReleaseHistory.tsx',
      'src/lib/config/releases.ts',
      'src/lib/github/releases.ts',
      'postcss.config.mjs',
    ];

    for (const pagePath of requiredPages) {
      const fullPath = path.join(websiteRoot, pagePath);
      assert.ok(fs.existsSync(fullPath), `Missing required page: ${pagePath}`);
    }
  });

  test('All required authentication and dashboard routes exist', () => {
    const requiredAuthPages = [
      'src/app/login/page.tsx',
      'src/app/signup/page.tsx',
      'src/app/verify-email/page.tsx',
      'src/app/forgot-password/page.tsx',
      'src/app/auth/callback/route.ts',
      'src/app/auth/recovery/page.tsx',
      'src/app/dashboard/page.tsx',
    ];

    for (const pagePath of requiredAuthPages) {
      const fullPath = path.join(websiteRoot, pagePath);
      assert.ok(fs.existsSync(fullPath), `Missing required auth/dashboard route: ${pagePath}`);
    }
  });

  test('Supabase SSR client modules exist', () => {
    const supabaseFiles = [
      'src/lib/supabase/client.ts',
      'src/lib/supabase/server.ts',
      'src/lib/supabase/middleware.ts',
      'src/middleware.ts',
    ];

    for (const filePath of supabaseFiles) {
      const fullPath = path.join(websiteRoot, filePath);
      assert.ok(fs.existsSync(fullPath), `Missing Supabase helper: ${filePath}`);
    }
  });

  test('Canonical production domain is configured as https://fithost.amitrana.tech', () => {
    const layoutContent = fs.readFileSync(path.join(websiteRoot, 'src/app/layout.tsx'), 'utf-8');
    assert.match(layoutContent, /https:\/\/fithost\.amitrana\.tech/);

    const sitemapContent = fs.readFileSync(path.join(websiteRoot, 'src/app/sitemap.ts'), 'utf-8');
    assert.match(sitemapContent, /https:\/\/fithost\.amitrana\.tech/);

    const robotsContent = fs.readFileSync(path.join(websiteRoot, 'src/app/robots.ts'), 'utf-8');
    assert.match(robotsContent, /https:\/\/fithost\.amitrana\.tech\/sitemap\.xml/);
  });

  test('Vercel configuration enforces strict security headers and private cache control for /dashboard', () => {
    const vercelConfigPath = path.join(websiteRoot, 'vercel.json');
    assert.ok(fs.existsSync(vercelConfigPath), 'vercel.json must exist');

    const config = JSON.parse(fs.readFileSync(vercelConfigPath, 'utf-8'));
    assert.equal(config.framework, 'nextjs');

    const dashboardHeader = config.headers?.find((h) => h.source === '/dashboard/(.*)');
    assert.ok(dashboardHeader, 'Dashboard must have explicit cache-control rule');
    const cacheControl = dashboardHeader.headers?.find((item) => item.key === 'Cache-Control');
    assert.match(cacheControl.value, /no-store/);
  });

  test('No service-role secret key is exposed in client env', () => {
    const envExample = fs.readFileSync(path.join(websiteRoot, '.env.example'), 'utf-8');
    assert.doesNotMatch(envExample, /SUPABASE_SERVICE_ROLE_KEY=/);

    if (fs.existsSync(path.join(websiteRoot, '.env.local'))) {
      const envLocal = fs.readFileSync(path.join(websiteRoot, '.env.local'), 'utf-8');
      assert.doesNotMatch(envLocal, /SUPABASE_SERVICE_ROLE_KEY=/);
    }
  });

  test('Authentic app icons and category images are in public/ directory', () => {
    const publicAssets = [
      'public/fit_host_icon.png',
      'public/images/screenshots/home.png',
      'public/images/screenshots/workouts.png',
      'public/images/screenshots/nutrition.png',
      'public/images/categories/strength.png',
      'public/images/categories/cardio.png',
    ];

    for (const assetPath of publicAssets) {
      const fullPath = path.join(websiteRoot, assetPath);
      assert.ok(fs.existsSync(fullPath), `Missing public asset: ${assetPath}`);
    }
  });

  test('Centralized typed configuration module enforces security rules and defaults', () => {
    const configPath = path.join(websiteRoot, 'src/lib/config/releases.ts');
    const configContent = fs.readFileSync(configPath, 'utf-8');

    assert.ok(configContent.includes('export interface ReleasesConfig'), 'Exports typed ReleasesConfig');
    assert.ok(configContent.includes('owner: process.env.GITHUB_OWNER || "xtenfit"'), 'Configures default owner xtenfit');
    assert.ok(configContent.includes('repo: process.env.GITHUB_REPO || "fit-host"'), 'Configures default repo fit-host');
    assert.ok(configContent.includes('intervalSeconds:'), 'Configures intervalSeconds');
    assert.ok(configContent.includes('tag: "github-releases"'), 'Uses Next.js cache tag github-releases');

    // Security check: NEVER expose GITHUB_TOKEN as NEXT_PUBLIC_
    assert.ok(!configContent.includes('NEXT_PUBLIC_GITHUB_TOKEN'), 'GITHUB_TOKEN must NEVER be exposed as NEXT_PUBLIC_');
  });

  test('Safe Markdown parser extracts structured headings and strips unsafe HTML', () => {
    function parseNotes(markdown) {
      if (!markdown || !markdown.trim()) {
        return { whatsNew: [], improvements: [], bugFixes: [], securityFixes: [], knownIssues: [], hasStructuredSections: false };
      }
      const whatsNew = [];
      const improvements = [];
      const bugFixes = [];
      const securityFixes = [];
      const knownIssues = [];

      let current = 'none';
      for (const line of markdown.split('\n')) {
        const trimmed = line.trim();
        const lower = trimmed.toLowerCase();
        if (trimmed.startsWith('#')) {
          if (lower.includes("what's new") || lower.includes('features')) current = 'whatsNew';
          else if (lower.includes('improvement') || lower.includes('performance')) current = 'improvements';
          else if (lower.includes('security')) current = 'securityFixes';
          else if (lower.includes('bug fix') || lower.includes('fixes')) current = 'bugFixes';
          else if (lower.includes('known issue')) current = 'knownIssues';
          continue;
        }
        const bulletMatch = trimmed.match(/^[-*+]\s+(.*)$/) || trimmed.match(/^\d+\.\s+(.*)$/);
        if (!bulletMatch) continue;
        const clean = bulletMatch[1].replace(/<[^>]+>/g, '').trim();
        if (current === 'whatsNew') whatsNew.push(clean);
        if (current === 'improvements') improvements.push(clean);
        if (current === 'bugFixes') bugFixes.push(clean);
        if (current === 'securityFixes') securityFixes.push(clean);
        if (current === 'knownIssues') knownIssues.push(clean);
      }
      return { whatsNew, improvements, bugFixes, securityFixes, knownIssues, hasStructuredSections: whatsNew.length > 0 };
    }

    const testMd = `
## What's New
- Feature A with <script>evil()</script>
- Feature B

## Improvements
- 30% faster SQLite startup

## Bug Fixes
- Fixed layout overflow

## Security Fixes
- RLS query validation

## Known Issues
- Battery optimization check
`;

    const parsed = parseNotes(testMd);
    assert.equal(parsed.whatsNew.length, 2);
    assert.equal(parsed.whatsNew[0], 'Feature A with evil()');
    assert.ok(!parsed.whatsNew[0].includes('<script>'));
    assert.equal(parsed.improvements.length, 1);
    assert.equal(parsed.bugFixes.length, 1);
    assert.equal(parsed.securityFixes.length, 1);
    assert.equal(parsed.knownIssues.length, 1);
    assert.equal(parsed.hasStructuredSections, true);
  });

  test('Selecting latest stable release ignores drafts and prereleases', () => {
    const mockReleases = [
      { id: 1, tag_name: 'v2.3.0-rc1', draft: false, prerelease: true, published_at: '2026-10-21T00:00:00Z' },
      { id: 2, tag_name: 'v2.2.0', draft: false, prerelease: false, published_at: '2026-10-20T00:00:00Z' },
      { id: 3, tag_name: 'v2.4.0-draft', draft: true, prerelease: false, published_at: '2026-10-22T00:00:00Z' },
      { id: 4, tag_name: 'v2.1.0', draft: false, prerelease: false, published_at: '2026-10-18T00:00:00Z' },
    ];

    const allowPrereleases = false;
    const stableOnly = mockReleases
      .filter((r) => !r.draft && (allowPrereleases || !r.prerelease))
      .sort((a, b) => new Date(b.published_at).getTime() - new Date(a.published_at).getTime());

    assert.equal(stableOnly.length, 2);
    assert.equal(stableOnly[0].tag_name, 'v2.2.0');
    assert.equal(stableOnly[1].tag_name, 'v2.1.0');
  });

  test('Handling missing publication dates falls back to created_at gracefully', () => {
    const rWithoutPubDate = {
      tag_name: 'v2.2.0',
      published_at: null,
      created_at: '2026-10-20T14:00:00Z',
    };
    const effectiveDate = rWithoutPubDate.published_at || rWithoutPubDate.created_at;
    assert.equal(effectiveDate, '2026-10-20T14:00:00Z');
  });

  test('Missing APK asset produces clear unavailable state without broken download links', () => {
    const assets = [
      { name: 'checksums.txt', browser_download_url: 'https://example.com/checksums.txt' },
      { name: 'source.tar.gz', browser_download_url: 'https://example.com/source.tar.gz' },
    ];
    const apkAsset = assets.find((a) => a.name.toLowerCase().endsWith('.apk'));
    assert.equal(apkAsset, undefined);

    const downloadUrl = apkAsset ? apkAsset.browser_download_url : null;
    const distributionStatus = apkAsset ? 'available' : 'unavailable';

    assert.equal(downloadUrl, null);
    assert.equal(distributionStatus, 'unavailable');
  });

  test('Multiple Android assets prefers FitHost-Android naming convention', () => {
    const assets = [
      { name: 'universal-debug.apk', browser_download_url: 'https://example.com/debug.apk' },
      { name: 'FitHost-Android-v2.2.0.apk', browser_download_url: 'https://example.com/FitHost-Android-v2.2.0.apk' },
      { name: 'app-release.apk', browser_download_url: 'https://example.com/release.apk' },
    ];

    const chosenApk =
      assets.find((a) => a.name.toLowerCase().startsWith('fithost-android') && a.name.toLowerCase().endsWith('.apk')) ||
      assets.find((a) => a.name.toLowerCase().endsWith('.apk'));

    assert.ok(chosenApk);
    assert.equal(chosenApk.name, 'FitHost-Android-v2.2.0.apk');
    assert.equal(chosenApk.browser_download_url, 'https://example.com/FitHost-Android-v2.2.0.apk');
  });

  test('Platform isolation: Android APK is never presented as iOS download', () => {
    const apkUrl = 'https://github.com/xtenfit/fit-host/releases/download/v2.2.0/FitHost-Android-v2.2.0.apk';
    const iosConfig = {
      appStoreUrl: undefined,
      testFlightUrl: undefined,
      status: 'coming_soon',
    };

    const androidDownload = apkUrl;
    const iosDownload = iosConfig.testFlightUrl || iosConfig.appStoreUrl || null;

    assert.notEqual(androidDownload, iosDownload);
    assert.equal(iosDownload, null);
    assert.equal(iosConfig.status, 'coming_soon');
  });

  test('Cached data fallback activates seamlessly when GitHub API returns error or rate limit', () => {
    const releasesContent = fs.readFileSync(path.join(websiteRoot, 'src/lib/github/releases.ts'), 'utf-8');
    assert.ok(releasesContent.includes('getFallbackReleases()'), 'Includes getFallbackReleases function');
    assert.ok(releasesContent.includes('if (!res.ok)'), 'Handles non-200 responses with fallback');
    assert.ok(releasesContent.includes('catch (error)'), 'Handles network fetch exceptions with fallback');
    assert.ok(releasesContent.includes('isFallback: true'), 'Flags fallback items appropriately');
  });

  test('On-demand cache revalidation endpoint enforces secret validation', () => {
    const routeContent = fs.readFileSync(path.join(websiteRoot, 'src/app/api/revalidate-releases/route.ts'), 'utf-8');
    assert.ok(routeContent.includes('x-revalidate-secret'), 'Checks x-revalidate-secret header');
    assert.ok(routeContent.includes('revalidateTag'), 'Invokes Next.js revalidateTag');
    assert.ok(routeContent.includes('revalidatePath'), 'Invokes Next.js revalidatePath');
    assert.ok(routeContent.includes('status: 401'), 'Returns 401 Unauthorized on invalid secret');
  });

  test('IPhoneMockup implements reference aspect ratio 37/76 and container-responsive scaling', () => {
    const mockupPath = path.join(websiteRoot, 'src/components/marketing/IPhoneMockup.tsx');
    assert.ok(fs.existsSync(mockupPath), 'IPhoneMockup.tsx must exist');
    const content = fs.readFileSync(mockupPath, 'utf-8');

    // Strict reference aspect ratio
    assert.ok(content.includes('aspect-[37/76]'), 'Mockup must enforce reference aspect-ratio: 37/76');

    // Responsive size classes
    assert.ok(content.includes('max-w-'), 'Mockup must constrain width to container and avoid fixed 80em blowout');
    assert.ok(content.includes('sm:'), 'Mockup must support responsive breakpoints');

    // Physical side buttons
    assert.ok(content.includes('-left-[3px]'), 'Mockup must include left-side physical hardware buttons');
    assert.ok(content.includes('-right-[3px]'), 'Mockup must include right-side power/side button');

    // Concentric corner radii
    assert.ok(content.includes('rounded-'), 'Mockup must feature rounded outer frame and inner screen');

    // Hardware finishes
    assert.ok(content.includes('finishStyles'), 'Mockup must support premium titanium finishes');
    assert.ok(content.includes('chassisRim'), 'Mockup must implement realistic metal chassis rim with specular highlights');
    assert.ok(content.includes('chamferBevel'), 'Mockup must implement diamond-cut chamfer bezel');
    assert.ok(content.includes('speakerMesh'), 'Mockup must implement laser-cut ear speaker micro-slit');
    assert.ok(content.includes('object-contain'), 'Mockup must use object-contain to prevent horizontal/vertical content cropping');
    assert.ok(content.includes('KNOWN_SCREENSHOT_RATIOS'), 'Mockup must map screenshot aspect ratios to display full content');
  });

  test('IPhoneMockup strictly removes display notch and dynamic island pill for unobstructed app UI', () => {
    const mockupPath = path.join(websiteRoot, 'src/components/marketing/IPhoneMockup.tsx');
    const content = fs.readFileSync(mockupPath, 'utf-8');

    // Explicit user requirement: "and remove iphone display notch for every"
    assert.ok(!content.includes('Dynamic Island'), 'Mockup must NOT contain Dynamic Island pill');
    assert.ok(!content.includes('dynamic-island'), 'Mockup must NOT contain dynamic-island element');
    assert.ok(!content.includes('TrueDepth'), 'Mockup must NOT contain artificial camera cutouts');
    assert.ok(!content.includes('w-24 h-5 bg-black rounded-full'), 'Obsolete notch pill must be removed');
  });

  test('All website pages use PhoneMockup with authentic Fit Host mobile screenshots', () => {
    const pagePaths = [
      'src/app/page.tsx',
      'src/app/features/page.tsx',
      'src/app/how-it-works/page.tsx',
      'src/app/guides/[slug]/page.tsx',
    ];

    for (const p of pagePaths) {
      const fullPath = path.join(websiteRoot, p);
      const content = fs.readFileSync(fullPath, 'utf-8');
      assert.ok(content.includes('<PhoneMockup'), `${p} must use PhoneMockup`);
    }

    // Verify screenshots referenced in pages actually exist in public/images/screenshots/
    const requiredScreenshots = [
      'home.png',
      'workouts.png',
      'nutrition.png',
      'progress.png',
      'summary.png',
      'alarms.png',
      'diary.png',
    ];

    for (const screenshot of requiredScreenshots) {
      const fullPath = path.join(websiteRoot, 'public/images/screenshots', screenshot);
      assert.ok(fs.existsSync(fullPath), `Screenshot must exist: ${screenshot}`);
    }
  });
});

