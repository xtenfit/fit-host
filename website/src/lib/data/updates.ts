export interface ReleaseUpdate {
  slug: string;
  version: string;
  title: string;
  releaseDate: string;
  summary: string;
  status: "published" | "draft";
  categories: ("Features" | "Improvements" | "Fixes" | "Architecture")[];
  newFeatures: string[];
  improvements: string[];
  bugFixes: string[];
  knownIssues: string[];
  platformNotes: string;
}

export const releasesData: ReleaseUpdate[] = [
  {
    slug: "v1-3-0-animated-onboarding-exercise-gifs",
    version: "v1.3.0",
    title: "Premium Animated Onboarding Wizard, 1,324+ Exercise GIFs & Anatomical Targeting",
    releaseDate: "October 21, 2026",
    summary:
      "A flagship experience upgrade featuring a 20-step animated setup wizard with interactive 3D athlete models, personalized plan reveal, and an integrated exercise dataset containing 1,324+ exercises with looping GIF demonstrations and anatomical muscle targeting.",
    status: "published",
    categories: ["Features", "Improvements", "Architecture"],
    newFeatures: [
      "Animated 20-Step Setup Wizard: High-precision edge-to-edge onboarding featuring interactive male and female fitness model selection with electric-cyan ambient glow and perspective peek-in transitions.",
      "Personalized Fitness Plan Reveal: Dynamic 2x2 stat matrix (Daily Time, Experience Level, Focus Area, Equipment) based on real user answers with custom coach badge and tailored macro caloric targets.",
      "Universal Exercise GIF Visual Engine: 1,324+ exercises equipped with real-time looping animated GIF form guides, 180x180 thumbnails, and wger anatomical muscle map overlays.",
      "Multi-Mode Exercise Media Visualizer: Fast list thumbnails, 220px animated looping player with play/pause controls, and full-screen pinch-to-zoom interactive viewer.",
      "Comprehensive Body Composition & Circumference Logging: Track chest, waist, hips, arms, thighs, calves, neck, and shoulders with imperial and metric ruler inputs.",
      "Advanced Nutrition & Meal Timing Calibration: Configurable meal frequency schedules, hydration reminder pacing, and quiet hours.",
    ],
    improvements: [
      "Zero AGPL license contamination: Clean multi-source exercise catalog with open Creative Commons and MIT datasets.",
      "Sub-millisecond Drift SQLite persistence with seamless offline-to-cloud synchronization.",
      "Optimized CanvasKit and Skia rendering pipeline for fluid 60fps animations across all mobile screen sizes.",
      "Rest timer audio and vibration cues enhanced for active workout set execution.",
    ],
    bugFixes: [
      "Fixed step navigation state retention when skipping optional circumference measurements.",
      "Prevented duplicate submission race conditions during final onboarding plan activation.",
      "Resolved thumbnail image caching issue in active workout header on low-bandwidth connections.",
    ],
    knownIssues: [
      "Full-screen pinch-to-zoom requires multi-touch gestures supported on modern mobile browsers and native devices.",
    ],
    platformNotes:
      "Built for Android 8.0+ (API 26+) and iOS 14.0+. Release APK v1.3.0+3 compiled with tree-shaken icons and ProGuard optimization.",
  },
  {
    slug: "v2-1-0-online-first-cloud-sync",
    version: "v2.1.0",
    title: "Online-First Cloud Sync, Google OAuth & Realtime Drift Cache",
    releaseDate: "October 18, 2026",
    summary:
      "A landmark release introducing two-way Supabase cloud synchronization, Google One-Tap/OAuth authentication, 6-digit email OTP login, and a dual-layer local Drift cache for complete offline performance.",
    status: "published",
    categories: ["Features", "Architecture", "Improvements"],
    newFeatures: [
      "Dual-layer data architecture: Fast local Drift SQLite reads with instant Supabase cloud synchronization when online.",
      "Google One-Tap and OAuth login with seamless native callback support (io.supabase.fithost://login-callback).",
      "Email OTP 6-digit verification code workflow for passwordless account confirmation.",
      "Biometric app lock support with local device keychain integration.",
      "Guest-to-Authenticated account migration: Workouts logged as guest merge into your permanent cloud account upon sign-in.",
    ],
    improvements: [
      "Optimized memory footprint when loading 30-day workout history charts.",
      "Improved visual rendering on AMOLED displays with pure #0A0F0D deep black background.",
      "Enhanced network connectivity listener with exponential backoff on reconnection.",
      "Refined typography and button touch targets across all mobile viewports.",
    ],
    bugFixes: [
      "Resolved RenderFlex overflow in Alarm and Reminder sound selection screen.",
      "Fixed overlapping text in Nutrition macro breakdown on smaller Android screens.",
      "Corrected workout completion summary to accurately aggregate multiple exercises and sets.",
      "Prevented race condition in local SQLite cache when switching between guest and authenticated modes.",
    ],
    knownIssues: [
      "Pedometer step count on some Samsung devices requires disabling battery optimization for continuous background tracking.",
    ],
    platformNotes:
      "Requires Android 8.0+ (API level 26) or iOS 14.0+. Supabase project migration v2 applied.",
  },
  {
    slug: "v2-0-0-complete-fitness-engine-redesign",
    version: "v2.0.0",
    title: "Fit Host 2.0: The Complete Fitness Engine Redesign",
    releaseDate: "September 12, 2026",
    summary:
      "A complete visual and architectural overhaul featuring high-contrast neon green branding, 10 categorized workout disciplines, custom exercise set logging, and macro nutrition tracking.",
    status: "published",
    categories: ["Features", "Improvements"],
    newFeatures: [
      "Brand redesign featuring #39FF88 neon green and sleek dark editorial aesthetic.",
      "10 comprehensive workout categories: Strength, Cardio, HIIT, Bodyweight, Chest, Back, Arms, Legs, Abs, and Yoga.",
      "Interactive workout logger with active timer, set-by-set weight/rep entry, and rest countdown.",
      "Hydration logging with quick-add volume presets (250ml, 500ml, 750ml).",
      "Macro nutrition tracker for daily calories, protein, carbohydrates, and healthy fats.",
    ],
    improvements: [
      "60 FPS smooth transitions using Flutter Impeller rendering backend on iOS and Vulkan on Android.",
      "Added haptic feedback on workout completion and set logging.",
      "Restructured Riverpod state management for zero-latency screen transitions.",
    ],
    bugFixes: [
      "Fixed incorrect date filtering on diary view across different timezones.",
      "Corrected calculation error in weekly volume aggregation.",
    ],
    knownIssues: [
      "Cloud sync requires an internet connection; offline queue will synchronize on next active session.",
    ],
    platformNotes: "Compatible with Android and iOS. Built with Flutter 3.24+.",
  },
  {
    slug: "v1-9-0-offline-foundation-guest-mode",
    version: "v1.9.0",
    title: "Fast Local Drift SQLite Engine & Guest Mode",
    releaseDate: "August 20, 2026",
    summary:
      "Introduced zero-barrier onboarding with Guest Mode and an embedded Drift SQLite database allowing instant local usage without an account.",
    status: "published",
    categories: ["Features", "Architecture"],
    newFeatures: [
      "Guest Mode: Use the full workout logger immediately without creating an account.",
      "Embedded Drift SQLite database engine for local persistence.",
      "Custom notification reminder service for daily workouts and hydration prompts.",
    ],
    improvements: [
      "Reduced cold start launch time to under 800 milliseconds.",
      "Zero network requests required during active workout sessions.",
    ],
    bugFixes: [
      "Fixed notification icon tinting on Android 13+ themed icons.",
    ],
    knownIssues: [
      "Guest mode data is saved only on the local device until account creation.",
    ],
    platformNotes: "Initial release of the new local database schema v1.",
  },
];

export function getAllPublishedReleases(): ReleaseUpdate[] {
  return releasesData.filter((r) => r.status === "published");
}

export function getLatestRelease(): ReleaseUpdate {
  return getAllPublishedReleases()[0];
}

export function getReleaseBySlug(slug: string): ReleaseUpdate | undefined {
  return releasesData.find((r) => r.slug === slug && r.status === "published");
}
