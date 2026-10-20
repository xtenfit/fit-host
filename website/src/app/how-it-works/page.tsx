import type { Metadata } from "next";
import Link from "next/link";
import {
  Download,
  UserCheck,
  Sliders,
  Dumbbell,
  LineChart,
  Cloud,
  CheckCircle2,
  ArrowRight,
  Sparkles,
  Smartphone,
  ShieldCheck,
} from "lucide-react";
import PhoneMockup from "@/components/marketing/PhoneMockup";
import DownloadCTA from "@/components/marketing/DownloadCTA";

export const metadata: Metadata = {
  title: "How It Works — The Fit Host Mobile Workflow",
  description:
    "A visual, step-by-step walkthrough explaining how to install, use guest mode, log workouts, track nutrition, and synchronize data in the Fit Host mobile application.",
};

const tutorialSteps = [
  {
    step: "01",
    title: "Install and Open Fit Host",
    category: "Installation",
    summary:
      "Download the verified Android Release APK or install through your platform app store. Fit Host boots up instantly without bloat or telemetry delays.",
    points: [
      "Lightweight mobile build engineered with Flutter 3.24+",
      "Native dark mode interface with #0A0F0D deep black background",
      "Immediate device initialization of the local Drift SQLite database",
    ],
    screenshot: "/images/screenshots/home.png",
    screenshotCaption: "Fit Host launches immediately to the welcoming home screen.",
  },
  {
    step: "02",
    title: "Continue as Guest or Sign Up",
    category: "Onboarding",
    summary:
      "Start logging instantly with complete privacy in Guest Mode. Or create a permanent cloud profile with Email OTP or Google OAuth for multi-device sync.",
    points: [
      "Guest Mode: Zero personal credentials required to start",
      "Cloud Account: Protected by PostgreSQL Row Level Security (RLS)",
      "Seamless migration: Guest logs merge automatically when you register later",
    ],
    screenshot: "/images/screenshots/diary.png",
    screenshotCaption: "Choose guest mode for instant testing or sign up for continuous backup.",
  },
  {
    step: "03",
    title: "Configure Profile & Daily Targets",
    category: "Personalization",
    summary:
      "Customize your baseline hydration target (e.g. 2,500ml), daily caloric ceiling, macro ratios, and workout reminder sound alarms.",
    points: [
      "Set fluid intake in milliliters with automatic daily reset",
      "Macro allocation for protein, carbohydrates, and healthy fats",
      "Configurable reminder intervals to keep your habits consistent",
    ],
    screenshot: "/images/screenshots/alarms.png",
    screenshotCaption: "Dial in your personal hydration targets and daily reminder alarms.",
  },
  {
    step: "04",
    title: "Track Workouts, Sets & Exercises",
    category: "Active Training",
    summary:
      "Pick from 10 categorized disciplines. Enter resistance weight, log repetitions, check off completed sets, and rest with the built-in countdown timer.",
    points: [
      "10 structured categories: Strength, Bodyweight, Cardio, HIIT, Cycling, Running, Mobility, Stretching, Meditation, Yoga",
      "Interactive rest timer with audio cue and subtle haptics",
      "Immediate sub-millisecond writes directly to device storage",
    ],
    screenshot: "/images/screenshots/workouts.png",
    screenshotCaption: "Set-by-set resistance and repetition logging during active workouts.",
  },
  {
    step: "05",
    title: "Review Workout Session Summary",
    category: "Session Analysis",
    summary:
      "Upon completion, review total workout duration, aggregate tonnage moved, and exercise breakdown before saving to your persistent timeline.",
    points: [
      "Instant exercise-by-exercise volume and repetition breakdown",
      "Total elapsed training duration and set completion tally",
      "Immediate persistence to local Drift SQLite and background cloud push",
    ],
    screenshot: "/images/screenshots/summary.png",
    screenshotCaption: "Review workout completion summary, volume progressions, and personal milestones.",
  },
  {
    step: "06",
    title: "Local Data Storage & Cloud Sync",
    category: "Data Architecture",
    summary:
      "Fit Host uses a dual-layer data architecture: local Drift SQLite executes all operations without waiting for network; Supabase synchronizes changes in the background.",
    points: [
      "Your data stays available on your device even without cellular signal",
      "Background sync queue pushes pending changes once network returns",
      "PostgreSQL RLS ensures total isolation between user accounts",
    ],
    screenshot: "/images/screenshots/progress.png",
    screenshotCaption: "Local Drift storage coupled with background Supabase cloud synchronization.",
  },
];

export default function HowItWorksPage() {
  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16 sm:space-y-24">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
            <Sparkles className="h-3.5 w-3.5" />
            <span>STEP-BY-STEP MOBILE TUTORIAL</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white">
            How Fit Host Works.
          </h1>

          <p className="text-base sm:text-xl text-zinc-300 leading-relaxed">
            Fit Host is an offline-capable mobile application. Here is a clear visual walkthrough of the real app flow from first download to cloud backup.
          </p>
        </div>

        {/* STEP-BY-STEP SECTIONS */}
        <div className="space-y-20">
          {tutorialSteps.map((item, idx) => {
            const isEven = idx % 2 === 1;
            return (
              <div
                key={item.step}
                className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center rounded-3xl border border-brand-border bg-brand-surface/70 p-6 sm:p-10 lg:p-12 shadow-xl"
              >
                {/* Text Content */}
                <div className={`lg:col-span-7 space-y-5 ${isEven ? "lg:order-2" : "lg:order-1"}`}>
                  <div className="flex items-center gap-3">
                    <span className="font-mono text-2xl sm:text-3xl font-black text-brand-green bg-brand-green/10 px-3 py-1 rounded-xl border border-brand-green/30">
                      STEP {item.step}
                    </span>
                    <span className="text-xs font-semibold px-3 py-1 rounded-md bg-brand-elevated text-zinc-400 border border-brand-border">
                      {item.category}
                    </span>
                  </div>

                  <h2 className="text-2xl sm:text-3xl font-bold text-white">
                    {item.title}
                  </h2>

                  <p className="text-sm sm:text-base text-zinc-300 leading-relaxed">
                    {item.summary}
                  </p>

                  <div className="pt-2 border-t border-brand-border/60">
                    <ul className="space-y-2 text-xs sm:text-sm text-zinc-300">
                      {item.points.map((pt, pIdx) => (
                        <li key={pIdx} className="flex items-start gap-2.5">
                          <CheckCircle2 className="h-4 w-4 text-brand-green shrink-0 mt-0.5" />
                          <span>{pt}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                {/* Mobile Mockup Preview */}
                <div className={`lg:col-span-5 flex justify-center ${isEven ? "lg:order-1" : "lg:order-2"}`}>
                  <PhoneMockup
                    src={item.screenshot}
                    alt={item.title}
                    glowColor={idx === 3 || idx === 0 ? "green" : "blue"}
                    caption={item.screenshotCaption}
                  />
                </div>
              </div>
            );
          })}
        </div>

        {/* SECTION: ARCHITECTURAL HIGHLIGHT (DRIFT + SUPABASE) */}
        <div className="rounded-3xl border border-brand-green/30 bg-gradient-to-br from-brand-surface via-brand-surface to-brand-elevated p-8 sm:p-12 shadow-2xl space-y-6">
          <div className="text-xs font-mono font-bold text-brand-green uppercase tracking-wider">
            Architecture Blueprint
          </div>
          <h2 className="text-2xl sm:text-4xl font-black text-white">
            Dual-Layer Resilience: Drift SQLite + Supabase PostgreSQL
          </h2>
          <p className="text-sm sm:text-base text-zinc-300 leading-relaxed max-w-3xl">
            Most fitness apps fail as soon as you step into an underground training facility with weak cellular reception. Fit Host solves this fundamentally:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
            <div className="rounded-2xl border border-brand-border bg-brand-elevated/60 p-5 space-y-2">
              <div className="text-xs font-bold text-brand-green uppercase font-mono">Layer 1: Local Device</div>
              <h3 className="text-base font-bold text-white">Drift SQLite Database</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Reads and writes complete in less than 2 milliseconds directly on your phone storage. Zero waiting, zero spinners.
              </p>
            </div>
            <div className="rounded-2xl border border-brand-border bg-brand-elevated/60 p-5 space-y-2">
              <div className="text-xs font-bold text-brand-blue uppercase font-mono">Layer 2: Connectivity</div>
              <h3 className="text-base font-bold text-white">Background Sync Queue</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                An intelligent network state manager monitors connectivity and queues offline logs with timestamp conflict resolution.
              </p>
            </div>
            <div className="rounded-2xl border border-brand-border bg-brand-elevated/60 p-5 space-y-2">
              <div className="text-xs font-bold text-brand-cyan uppercase font-mono">Layer 3: Cloud</div>
              <h3 className="text-base font-bold text-white">Supabase PostgreSQL + RLS</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Stores historical backups in PostgreSQL with strict Row Level Security ensuring only you can access your private logs.
              </p>
            </div>
          </div>
        </div>

        {/* CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
