export interface SiteConfig {
  name: string;
  domain: string;
  url: string;
  tagline: string;
  description: string;
  version: string;
  releaseDate: string;
  storeLinks: {
    appStore: {
      available: boolean;
      url: string | null;
      label: string;
    };
    googlePlay: {
      available: boolean;
      url: string | null;
      label: string;
    };
    directApk: {
      available: boolean;
      url: string;
      label: string;
      fileSize: string;
    };
  };
  support: {
    email: string;
    discordUrl?: string;
    githubUrl: string;
  };
  auth: {
    mobileCallback: string;
  };
}

export const siteConfig: SiteConfig = {
  name: "Fit Host",
  domain: "fithost.amitrana.tech",
  url: "https://fithost.amitrana.tech",
  tagline: "The High-Performance Mobile Fitness & Wellness Engine",
  description:
    "Fit Host is a fast, offline-capable fitness and wellness mobile app for iOS and Android. Log workouts, track hydration, manage macro nutrition, and synchronize your progress seamlessly across devices.",
  version: "v2.1.0",
  releaseDate: "October 2026",
  storeLinks: {
    appStore: {
      available: false,
      url: null,
      label: "Coming Soon to App Store",
    },
    googlePlay: {
      available: false,
      url: null,
      label: "Coming Soon to Google Play",
    },
    directApk: {
      available: true,
      url: "https://github.com/amitrana-tech/fit-host/releases/tag/v2.1.0",
      label: "Download Android Release APK",
      fileSize: "44.2 MB",
    },
  },
  support: {
    email: "support@amitrana.tech",
    githubUrl: "https://github.com/amitrana-tech/fit-host",
  },
  auth: {
    mobileCallback: "io.supabase.fithost://login-callback",
  },
};
