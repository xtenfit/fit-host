export type FeatureStatus = "available" | "partially_available" | "planned";

export interface FeatureItem {
  id: string;
  name: string;
  category: "Workout Tracking" | "Hydration & Nutrition" | "Data & Sync" | "Personalization" | "Hardware & Sensors";
  status: FeatureStatus;
  statusLabel: string;
  description: string;
  highlights: string[];
  screenshot?: string;
}

export const featuresData: FeatureItem[] = [
  {
    id: "workout-logging",
    name: "Interactive Workout Logging",
    category: "Workout Tracking",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Log full workout sessions with set-by-set weight, repetition tracking, rest timers, and volume summaries. Real-time metrics keep you focused under the bar.",
    highlights: [
      "Custom set and repetition entry with weight values (kg / lbs)",
      "Automated rest timer between sets with audio cue",
      "Volume, duration, and exercise completion calculation",
      "Saves instantly to local SQLite with zero network lag",
    ],
    screenshot: "/images/screenshots/workouts.png",
  },
  {
    id: "exercise-categories",
    name: "10 Categorized Workout Disciplines",
    category: "Workout Tracking",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Structured libraries covering Strength, Bodyweight, Cardio, HIIT, Cycling, Running, Mobility, Stretching, Meditation, and Yoga.",
    highlights: [
      "10 dedicated disciplines with curated movement catalogs",
      "Tailored tracking for endurance, strength, flexibility & mindfulness",
      "Support for compound barbell lifts, tempo pacing, and bodyweight progressions",
    ],
    screenshot: "/images/screenshots/home.png",
  },
  {
    id: "hydration-tracking",
    name: "Precision Hydration Tracking",
    category: "Hydration & Nutrition",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Monitor daily water intake with fast 1-tap presets (250ml cup, 500ml bottle, 750ml shaker). Visual circular completion rings keep you accountable throughout the day.",
    highlights: [
      "Dynamic circular hydration gauge with percentage completion",
      "Quick-add volume shortcuts (+250ml, +500ml, +750ml)",
      "Daily target customization in milliliters",
    ],
    screenshot: "/images/screenshots/diary.png",
  },
  {
    id: "macro-nutrition",
    name: "Macro Nutrition & Calorie Tracking",
    category: "Hydration & Nutrition",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Track daily calories, protein, carbohydrates, and healthy fats. High-contrast macro distribution bars clarify caloric intake against your personal goals.",
    highlights: [
      "Individual grams breakdown for protein, carbs, and fats",
      "Visual calorie budget gauge with surplus / deficit indication",
      "Categorized meal entries (Breakfast, Lunch, Dinner, Snacks)",
    ],
    screenshot: "/images/screenshots/nutrition.png",
  },
  {
    id: "offline-drift-sqlite",
    name: "100% Offline Local Drift Engine",
    category: "Data & Sync",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Never lose a workout in an underground gym or offline basement. All records write immediately to an embedded Drift SQLite database with sub-millisecond execution.",
    highlights: [
      "Zero network dependency during workout execution",
      "Encrypted device-level storage with fast schema migrations",
      "Background persistence queue with zero memory leaks",
    ],
    screenshot: "/images/screenshots/progress.png",
  },
  {
    id: "supabase-cloud-sync",
    name: "Supabase Cloud Synchronization",
    category: "Data & Sync",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Seamless two-way cloud synchronization to PostgreSQL. Multi-device access, automated conflict resolution, and strict Row Level Security (RLS) protection.",
    highlights: [
      "Row Level Security guarantees complete private access",
      "Auto-syncs pending offline records once connection returns",
      "Multi-device cloud restore upon signing in",
    ],
    screenshot: "/images/screenshots/home.png",
  },
  {
    id: "guest-mode",
    name: "Zero-Barrier Guest Mode",
    category: "Personalization",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Start logging instantly without registering an email or password. Upgrade to a permanent cloud account whenever you choose with seamless automatic data migration.",
    highlights: [
      "No sign-up or credit card required to test the full app",
      "Private local device storage",
      "1-click data merge when signing up later",
    ],
    screenshot: "/images/screenshots/home.png",
  },
  {
    id: "reminders-notifications",
    name: "Workout & Hydration Alarms",
    category: "Personalization",
    status: "available",
    statusLabel: "Available Now",
    description:
      "Configurable reminder notifications to build consistent daily training and hydration habits. Native sound selection with background lifecycle handling.",
    highlights: [
      "Custom reminder scheduling for morning, afternoon, or evening",
      "Selectable alarm melodies and subtle haptic vibrations",
      "Reliable background execution on Android and iOS",
    ],
    screenshot: "/images/screenshots/diary.png",
  },
  {
    id: "pedometer-steps",
    name: "Daily Step & Sensor Pacing",
    category: "Hardware & Sensors",
    status: "partially_available",
    statusLabel: "Partially Available",
    description:
      "Basic hardware step counting supported via local device sensors on selected Android models. Full background passive pedometer engine is currently being optimized for battery efficiency.",
    highlights: [
      "Hardware step counter integration via Android sensor API",
      "Active session step count calculation",
      "Battery-efficient background tracking under active refinement",
    ],
  },
  {
    id: "wearable-sync",
    name: "WearOS & Apple Watch Companion Apps",
    category: "Hardware & Sensors",
    status: "planned",
    statusLabel: "Planned",
    description:
      "Dedicated smartwatch companion experience to view upcoming sets, log reps directly from your wrist, and monitor heart rate during high-intensity intervals.",
    highlights: [
      "Wrist-based set logger and rest countdown display",
      "Real-time heart-rate zone visualization",
      "Offline sync directly between watch and mobile phone",
    ],
  },
  {
    id: "community-leaderboards",
    name: "Team & Community Leaderboards",
    category: "Personalization",
    status: "planned",
    statusLabel: "Planned",
    description:
      "Optional social workout challenges, club leaderboards, and shared training programs with friends while preserving complete control over personal privacy.",
    highlights: [
      "Private friend groups and gym training clubs",
      "Opt-in weekly workout volume challenges",
      "End-to-end privacy controls on shared logs",
    ],
  },
];

export function getFeaturesByStatus(status: FeatureStatus): FeatureItem[] {
  return featuresData.filter((f) => f.status === status);
}

export function getAllFeatures(): FeatureItem[] {
  return featuresData;
}
