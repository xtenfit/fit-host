export interface GuideStep {
  stepNumber: number;
  title: string;
  description: string;
  tip?: string;
}

export interface GuideArticle {
  slug: string;
  title: string;
  summary: string;
  category: "Getting Started" | "Workouts" | "Nutrition & Water" | "Sync & Security" | "Troubleshooting";
  updatedDate: string;
  readTime: string;
  featured?: boolean;
  screenshot?: string;
  steps: GuideStep[];
  keyTakeaways: string[];
  relatedGuideSlugs: string[];
}

export const guidesData: GuideArticle[] = [
  {
    slug: "getting-started",
    title: "Getting Started with Fit Host",
    summary:
      "A complete walkthrough of installing Fit Host, setting up your profile, and logging your first session either as a guest or with a cloud account.",
    category: "Getting Started",
    updatedDate: "October 19, 2026",
    readTime: "4 min read",
    featured: true,
    screenshot: "/images/screenshots/home.png",
    steps: [
      {
        stepNumber: 1,
        title: "Install and Open the App",
        description:
          "Launch Fit Host on your Android or iOS device. The app opens immediately into a clean, dark-mode welcoming interface.",
      },
      {
        stepNumber: 2,
        title: "Choose Guest Mode or Sign Up",
        description:
          "You can tap 'Continue as Guest' to start logging instantly without entering any personal info. Or tap 'Create Account' using your email or Google OAuth to enable continuous cloud backup.",
        tip: "Guest data stays securely on your phone. You can always create an account later and merge your history.",
      },
      {
        stepNumber: 3,
        title: "Configure Your Fitness Goals",
        description:
          "Set your target daily hydration (e.g. 2,500ml), daily calorie goal, and preferred workout reminder schedule.",
      },
      {
        stepNumber: 4,
        title: "Explore the Home Dashboard",
        description:
          "Your Home tab displays today's workout prompt, hydration progress circle, recent activity feed, and quick-action shortcuts.",
      },
    ],
    keyTakeaways: [
      "No account required to start tracking.",
      "All logs save locally to your device first.",
      "Cloud backup can be activated at any time.",
    ],
    relatedGuideSlugs: ["guest-mode-vs-account", "logging-workouts"],
  },
  {
    slug: "guest-mode-vs-account",
    title: "Guest Mode vs. Cloud Account: Which Should You Choose?",
    summary:
      "Understand the differences between local-only guest storage and Supabase cloud synchronization, and how account linking seamlessly preserves your history.",
    category: "Getting Started",
    updatedDate: "October 18, 2026",
    readTime: "3 min read",
    featured: false,
    screenshot: "/images/screenshots/home.png",
    steps: [
      {
        stepNumber: 1,
        title: "Understanding Guest Mode",
        description:
          "Guest mode writes directly to the embedded Drift SQLite database on your device. It requires zero network connectivity and zero credentials. However, if you uninstall the app or clear device storage, local data cannot be restored.",
      },
      {
        stepNumber: 2,
        title: "Understanding Cloud Accounts",
        description:
          "When you register with email/password or Google OAuth, Fit Host assigns you an authenticated Supabase UUID protected by PostgreSQL Row Level Security (RLS). All workouts, hydration logs, and profile metrics are backed up to the cloud in real-time.",
      },
      {
        stepNumber: 3,
        title: "Upgrading from Guest to Cloud Account",
        description:
          "If you start as a guest and decide to sign up later, Fit Host automatically checks your local Drift database and migrates all existing records to your new cloud account so you never lose a set.",
      },
    ],
    keyTakeaways: [
      "Guest mode is 100% private and offline-contained.",
      "Cloud accounts provide multi-device sync and disaster recovery.",
      "Automatic data migration guarantees zero data loss upon upgrading.",
    ],
    relatedGuideSlugs: ["getting-started", "cloud-sync-architecture"],
  },
  {
    slug: "logging-workouts",
    title: "How to Log Workouts and Exercise Sets",
    summary:
      "Master the Fit Host workout logger: choose disciplines, track sets with weights and reps, use the built-in rest timer, and save detailed workout summaries.",
    category: "Workouts",
    updatedDate: "October 17, 2026",
    readTime: "5 min read",
    featured: true,
    screenshot: "/images/screenshots/workouts.png",
    steps: [
      {
        stepNumber: 1,
        title: "Navigate to the Workouts Tab",
        description:
          "Tap 'Workouts' from the bottom navigation bar. You will see 10 categorized disciplines including Strength, Cardio, HIIT, Bodyweight, Arms, Chest, Back, Legs, Abs, and Yoga.",
      },
      {
        stepNumber: 2,
        title: "Select an Exercise Discipline",
        description:
          "Choose the muscle group or workout type. Browse pre-configured exercises or create a custom exercise entry.",
      },
      {
        stepNumber: 3,
        title: "Log Sets, Reps, and Weight",
        description:
          "Enter your resistance weight (in kg or lbs) and repetitions completed. Tap the checkmark to complete each set. The built-in rest timer starts automatically.",
      },
      {
        stepNumber: 4,
        title: "Complete and Review Your Summary",
        description:
          "When finished, tap 'Complete Workout'. A detailed summary screen calculates total volume, workout duration, and personal best milestones.",
      },
    ],
    keyTakeaways: [
      "10 dedicated disciplines with rich exercise categorization.",
      "Real-time set and volume calculation.",
      "Local device saving ensures your session is never lost mid-workout.",
    ],
    relatedGuideSlugs: ["getting-started", "cloud-sync-architecture"],
  },
  {
    slug: "tracking-hydration",
    title: "Tracking Daily Hydration and Water Goals",
    summary:
      "Learn how to set daily fluid targets, log water intake with quick-add volume presets, and track consistency over time.",
    category: "Nutrition & Water",
    updatedDate: "October 16, 2026",
    readTime: "3 min read",
    featured: false,
    screenshot: "/images/screenshots/diary.png",
    steps: [
      {
        stepNumber: 1,
        title: "Set Your Daily Fluid Target",
        description:
          "Open your Profile settings to specify your baseline hydration target based on your weight and activity level (e.g. 2,500ml - 3,500ml).",
      },
      {
        stepNumber: 2,
        title: "Log Intake with One Tap",
        description:
          "Use the fast-action hydration buttons on the Home or Diary screens (+250ml cup, +500ml bottle, +750ml shaker) to log fluid intake instantly.",
      },
      {
        stepNumber: 3,
        title: "Monitor Your Ring Completion",
        description:
          "The interactive hydration circle dynamically fills as you drink throughout the day, giving you an immediate visual cue of your progress.",
      },
    ],
    keyTakeaways: [
      "Fast 1-tap presets reduce friction.",
      "Visual circular gauge shows percentage completion.",
      "Hydration entries save locally and sync when connected.",
    ],
    relatedGuideSlugs: ["tracking-nutrition", "getting-started"],
  },
  {
    slug: "tracking-nutrition",
    title: "Macro Nutrition: Protein, Carbs, Fats & Calories",
    summary:
      "Understand the Fit Host nutrition logging interface, monitor macronutrient distribution, and balance daily caloric intake against your fitness targets.",
    category: "Nutrition & Water",
    updatedDate: "October 16, 2026",
    readTime: "4 min read",
    featured: false,
    screenshot: "/images/screenshots/nutrition.png",
    steps: [
      {
        stepNumber: 1,
        title: "Open the Nutrition Screen",
        description:
          "Access Nutrition from the Diary or Home quick links. The screen displays your daily calorie budget alongside macro breakdown bars.",
      },
      {
        stepNumber: 2,
        title: "Log Meals and Snacks",
        description:
          "Enter meals by category (Breakfast, Lunch, Dinner, Snacks) with accurate caloric content and grams of protein, carbohydrates, and fats.",
      },
      {
        stepNumber: 3,
        title: "Track Your Macro Proportions",
        description:
          "Review the high-contrast macro distribution gauges to ensure you are meeting your protein requirements for muscle recovery and energy.",
      },
    ],
    keyTakeaways: [
      "Separate tracking for protein, carbs, fats, and total calories.",
      "Clear visual indicators for surplus, maintenance, or deficit.",
      "Data persists offline with instant local validation.",
    ],
    relatedGuideSlugs: ["tracking-hydration", "getting-started"],
  },
  {
    slug: "cloud-sync-architecture",
    title: "Understanding Cloud Synchronization and Local Drift Cache",
    summary:
      "A deep dive into how Fit Host manages two-way synchronization: zero latency writes to Drift SQLite, automatic background sync to Supabase, and conflict resolution.",
    category: "Sync & Security",
    updatedDate: "October 18, 2026",
    readTime: "5 min read",
    featured: true,
    screenshot: "/images/screenshots/progress.png",
    steps: [
      {
        stepNumber: 1,
        title: "Immediate Local Drift Persistence",
        description:
          "Every action you take in the app—logging a set, recording water, updating settings—is written immediately to your phone's embedded SQLite database. This ensures zero network latency and seamless offline usage.",
      },
      {
        stepNumber: 2,
        title: "Intelligent Network Detection",
        description:
          "A background listener monitors active internet connectivity. When online, Fit Host immediately queues any uncommitted local updates for cloud transmission.",
      },
      {
        stepNumber: 3,
        title: "Row Level Security (RLS) in PostgreSQL",
        description:
          "Your data is transmitted over TLS to your Supabase PostgreSQL backend. Strict Row Level Security policies guarantee that only your verified auth token can read, write, or modify records belonging to your account.",
      },
      {
        stepNumber: 4,
        title: "Automatic Conflict Resolution",
        description:
          "If you make changes on multiple devices while offline, Fit Host uses timestamp-based resolution (last-write-wins with millisecond accuracy) to prevent data corruption.",
      },
    ],
    keyTakeaways: [
      "Zero-latency local writes even in airplane mode.",
      "PostgreSQL RLS ensures total privacy and isolation.",
      "Automatic background queue synchronizes when connection returns.",
    ],
    relatedGuideSlugs: ["troubleshooting-sync", "guest-mode-vs-account"],
  },
  {
    slug: "troubleshooting-sync",
    title: "Troubleshooting Sync and Offline Connectivity",
    summary:
      "Step-by-step diagnostic checklist to verify internet access, resolve sync delays, force a manual sync, and ensure your local records are protected.",
    category: "Troubleshooting",
    updatedDate: "October 19, 2026",
    readTime: "4 min read",
    featured: false,
    screenshot: "/images/screenshots/progress.png",
    steps: [
      {
        stepNumber: 1,
        title: "Check Device Network Connectivity",
        description:
          "Ensure your phone is not in Airplane Mode and has an active Wi-Fi or cellular data connection. Open a web browser to confirm active connectivity.",
      },
      {
        stepNumber: 2,
        title: "Verify Your Authentication State",
        description:
          "If you are using Guest Mode, your data is stored locally and does not sync to the cloud. Go to Profile to check if you are signed in. If your session expired, sign in again to resume synchronization.",
      },
      {
        stepNumber: 3,
        title: "Perform a Pull-to-Refresh",
        description:
          "On the Home or Diary screen, swipe down to trigger an immediate manual synchronization pass. The app will fetch the latest remote records and push pending local changes.",
      },
      {
        stepNumber: 4,
        title: "Check Battery Optimization Restrictions",
        description:
          "On some Android devices, strict battery saver modes can restrict background sync. Ensure Fit Host has background activity permissions enabled in your device system settings.",
      },
    ],
    keyTakeaways: [
      "Guest mode does not sync to cloud—create an account to enable backup.",
      "Swipe down to force a manual sync pass at any time.",
      "Data is never deleted locally if a cloud sync attempt fails.",
    ],
    relatedGuideSlugs: ["cloud-sync-architecture", "account-recovery"],
  },
  {
    slug: "account-recovery",
    title: "Account Recovery, Password Reset & Email OTP",
    summary:
      "How to regain access to your Fit Host cloud account using password recovery or 6-digit email verification codes.",
    category: "Sync & Security",
    updatedDate: "October 18, 2026",
    readTime: "3 min read",
    featured: false,
    screenshot: "/images/screenshots/home.png",
    steps: [
      {
        stepNumber: 1,
        title: "Select 'Forgot Password' on Sign In Screen",
        description:
          "From the login screen in the app or on the website, tap 'Forgot password' and enter the email address linked to your account.",
      },
      {
        stepNumber: 2,
        title: "Check Your Email for the 6-Digit OTP",
        description:
          "Supabase sends a secure 6-digit verification code to your email inbox. The code expires in 15 minutes for your security.",
      },
      {
        stepNumber: 3,
        title: "Enter the Verification Code",
        description:
          "Type the 6-digit code into the verification screen. Once confirmed, you can set a new strong password.",
      },
      {
        stepNumber: 4,
        title: "Restore Access and Sync",
        description:
          "Log in with your new password. All of your historical workouts, hydration, and nutrition data will automatically download to your device.",
      },
    ],
    keyTakeaways: [
      "Fast 6-digit email OTP verification.",
      "No complex magic link redirections required.",
      "Restores full cloud workout history instantly.",
    ],
    relatedGuideSlugs: ["troubleshooting-sync", "getting-started"],
  },
];

export function getAllGuides(): GuideArticle[] {
  return guidesData;
}

export function getFeaturedGuides(): GuideArticle[] {
  return guidesData.filter((g) => g.featured);
}

export function getGuideBySlug(slug: string): GuideArticle | undefined {
  return guidesData.find((g) => g.slug === slug);
}

export function getGuidesByCategory(category: string): GuideArticle[] {
  return guidesData.filter((g) => g.category === category);
}
