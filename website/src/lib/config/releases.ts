/**
 * Typed configuration module for Fit Host mobile app releases,
 * GitHub integration, download channels, and revalidation settings.
 */

export interface PlatformConfig {
  android: {
    name: string;
    assetPattern: RegExp;
    enabled: boolean;
    sideloadGuidance: string;
  };
  ios: {
    name: string;
    appStoreUrl?: string;
    testFlightUrl?: string;
    status: "available" | "coming_soon" | "testflight";
    label: string;
  };
}

export interface ReleasesConfig {
  github: {
    owner: string;
    repo: string;
    // Server-side only: NEVER expose to client bundle or NEXT_PUBLIC_
    token?: string;
    apiUrl: string;
  };
  siteUrl: string;
  revalidation: {
    intervalSeconds: number;
    tag: string;
    secret?: string;
  };
  platforms: PlatformConfig;
  allowPrereleases: boolean;
}

export const releasesConfig: ReleasesConfig = {
  github: {
    // Primary GitHub organization / username for Fit Host releases
    owner: process.env.GITHUB_OWNER || "xtenfit",
    // Public GitHub release repository
    repo: process.env.GITHUB_REPO || "fit-host",
    // Server-side token (optional for public releases, provides 5000 req/hr rate limit)
    token: process.env.GITHUB_TOKEN,
    apiUrl: "https://api.github.com",
  },
  siteUrl: process.env.NEXT_PUBLIC_SITE_URL || "https://fithost.amitrana.tech",
  revalidation: {
    // Default 10 minutes (600 seconds) time-based ISR revalidation
    intervalSeconds: parseInt(process.env.RELEASE_CACHE_REVALIDATION_SECONDS || "600", 10),
    tag: "github-releases",
    secret: process.env.REVALIDATION_SECRET,
  },
  platforms: {
    android: {
      name: "Android",
      assetPattern: /\.apk$/i,
      enabled: true,
      sideloadGuidance:
        'When installing directly on Android, tap the downloaded APK and allow "Install unknown apps" in your browser or file manager settings to complete installation.',
    },
    ios: {
      name: "iOS",
      appStoreUrl: process.env.NEXT_PUBLIC_IOS_APP_STORE_URL || undefined,
      testFlightUrl: process.env.NEXT_PUBLIC_IOS_TESTFLIGHT_URL || undefined,
      status: process.env.NEXT_PUBLIC_IOS_TESTFLIGHT_URL
        ? "testflight"
        : process.env.NEXT_PUBLIC_IOS_APP_STORE_URL
        ? "available"
        : "coming_soon",
      label: process.env.NEXT_PUBLIC_IOS_TESTFLIGHT_URL
        ? "Join TestFlight Beta"
        : process.env.NEXT_PUBLIC_IOS_APP_STORE_URL
        ? "Download on App Store"
        : "Coming Soon to App Store",
    },
  },
  allowPrereleases: process.env.ALLOW_PRERELEASES === "true",
};
