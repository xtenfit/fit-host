# Fit Host Mobile App — GitHub Release & Continuous Delivery Workflow

This guide details the release engineering process for compiling, signing, testing, and publishing new Fit Host mobile releases to GitHub Releases. The Next.js website at `https://fithost.amitrana.tech` automatically detects published GitHub Releases, refreshes its version and release notes, and serves verified APK download assets without manual website updates or deployments.

---

## 1. Release Architecture & Principles

1. **GitHub as Source of Truth**: All stable releases, version numbers, publication dates, changelogs, and binary APK assets originate directly from GitHub Releases.
2. **Server-Side Next.js ISR**: The website fetches release metadata on the server using Next.js time-based revalidation (10 minutes) and on-demand webhook invalidation (`/api/revalidate-releases`).
3. **High Availability Fallback**: If the GitHub API experiences temporary rate limits or outages, the website seamlessly serves cached release history without displaying blank screens or broken links.
4. **Platform Isolation**: Android direct APK sideloading and iOS App Store/TestFlight links are strictly separated. Android APKs are never shown as iOS downloads.

---

## 2. Versioning and Tag Policy

Fit Host strictly adheres to [Semantic Versioning 2.0.0](https://semver.org/):

- **Format**: `vMAJOR.MINOR.PATCH` (e.g. `v2.2.0`, `v2.2.1`)
- **Git Tags**: Must match `vX.Y.Z` exactly.
- **Flutter pubspec.yaml**:
  ```yaml
  version: 2.2.0+3 # <semver>+<buildNumber>
  ```
- **Android APK Naming Convention**:
  ```text
  FitHost-Android-v2.2.0.apk
  ```

---

## 3. Step-by-Step Release Workflow

### Step 1: Update Application Version
Update `pubspec.yaml` and `VERSION` in the project root:
```bash
# In pubspec.yaml
version: 2.2.0+3
```

### Step 2: Build the Production Android Release APK
Execute a clean Flutter release build:
```bash
flutter clean
flutter pub get
flutter build apk --release
```
The output file is located at:
`build/app/outputs/flutter-apk/app-release.apk`

Rename the binary to match the official naming convention:
```bash
cp build/app/outputs/flutter-apk/app-release.apk FitHost-Android-v2.2.0.apk
```

### Step 3: Compute Verified SHA-256 Checksum
Generate the cryptographic SHA-256 hash to allow users to verify download integrity:
```bash
shasum -a 256 FitHost-Android-v2.2.0.apk > FitHost-Android-v2.2.0.apk.sha256
cat FitHost-Android-v2.2.0.apk.sha256
```

### Step 4: Test Artifact on Target Devices
Before publishing:
- Install on physical Android 8.0+ and 14.0+ devices:
  ```bash
  adb install -r FitHost-Android-v2.2.0.apk
  ```
- Verify Guest Mode, Drift SQLite database tables, and Supabase cloud sync authentication.

### Step 5: Draft Structured Release Notes
The website automatically parses structured markdown headings. Format your release notes following this exact schema:

```markdown
## What's New
- Dual-layer Drift SQLite and Supabase cloud synchronization.
- New high-contrast AMOLED dark theme with #C6FF00 neon accents.
- Fast guest mode with zero-friction onboarding.

## Improvements
- 40% reduction in database cold-boot query latency.
- Optimized 30-day workout volume chart memory consumption.

## Bug Fixes
- Resolved sound selection layout overflow on smaller Android screens.
- Fixed hydration reminder notification scheduling across device reboots.

## Known Issues
- Battery optimization on some Samsung devices may limit background step tracking.

SHA-256: 3c8e41bf985025a1e2f901a09d3b8417c8cf15d181057e75f1a5bb49cfd7d59a
```

### Step 6: Publish GitHub Release
1. Go to your GitHub repository: `https://github.com/xtenfit/fit-host/releases/new`
2. Select or create tag: `v2.2.0`.
3. Set Release title: `Fit Host v2.2.0 — <Short Title>`
4. Paste the structured release notes into the description.
5. Attach the release assets:
   - `FitHost-Android-v2.2.0.apk`
   - `FitHost-Android-v2.2.0.apk.sha256`
6. Ensure **"Set as a pre-release"** and **"Set as a draft"** are UNCHECKED for production stable releases.
7. Click **Publish release**.

---

## 4. Automatic Update Verification

1. **Instant Revalidation via GitHub Actions**:
   - The included workflow `.github/workflows/revalidate_website_release.yml` triggers upon release publication.
   - It makes an authenticated call to `https://fithost.amitrana.tech/api/revalidate-releases` with the `REVALIDATION_SECRET`.
2. **Periodic ISR Fallback**:
   - Even without GitHub Actions, Vercel refreshes cached release data every 10 minutes (`RELEASE_CACHE_REVALIDATION_SECONDS=600`).
3. **Verification Checklist**:
   - [ ] Visit `https://fithost.amitrana.tech/` $\to$ Verify latest release banner shows `v2.2.0` and publication date.
   - [ ] Visit `https://fithost.amitrana.tech/download` $\to$ Verify Android card shows `v2.2.0`, correct file size in MB, and working download link.
   - [ ] Visit `https://fithost.amitrana.tech/updates` $\to$ Verify `v2.2.0` appears at top of changelog.
   - [ ] Click download link $\to$ Verify APK downloads directly from GitHub's CDN (`github.com/.../releases/download/...`).
