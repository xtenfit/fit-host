import Link from "next/link";
import Image from "next/image";
import {
  Dumbbell,
  Droplets,
  Utensils,
  Zap,
  WifiOff,
  Cloud,
  ArrowRight,
  Sparkles,
  CheckCircle2,
  Lock,
  Smartphone,
  ShieldCheck,
  ChevronRight,
  Activity,
  Layers,
  Database,
  RefreshCw,
  Award,
} from "lucide-react";
import PhoneMockup from "@/components/marketing/PhoneMockup";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import ReleaseCard from "@/components/marketing/ReleaseCard";
import GuideCard from "@/components/marketing/GuideCard";
import LatestReleaseBanner from "@/components/releases/LatestReleaseBanner";
import { getFeaturedGuides } from "@/lib/data/guides";
import { getLatestMobileRelease } from "@/lib/github/releases";
import { siteConfig } from "@/lib/config/site";

const workoutCategories = [
  { name: "Strength", icon: "/images/categories/strength.png", desc: "Compound barbell & dumbbell lifts" },
  { name: "Bodyweight", icon: "/images/categories/bodyweight.png", desc: "Calisthenics & core control" },
  { name: "Cardio", icon: "/images/categories/cardio.png", desc: "Aerobic conditioning & intervals" },
  { name: "HIIT", icon: "/images/categories/hiit.png", desc: "High intensity interval sets" },
  { name: "Cycling", icon: "/images/categories/cycling.png", desc: "RPM pacing & endurance watts" },
  { name: "Running", icon: "/images/categories/running.png", desc: "Pace, split times & distances" },
  { name: "Mobility", icon: "/images/categories/mobility.png", desc: "Joint range of motion & activation" },
  { name: "Stretching", icon: "/images/categories/stretching.png", desc: "Post-workout cooldown & flex" },
  { name: "Meditation", icon: "/images/categories/meditation.png", desc: "Mindfulness & breathwork sessions" },
  { name: "Yoga", icon: "/images/categories/yoga.png", desc: "Mobility, balance & recovery" },
];

const coreBenefits = [
  {
    icon: Database,
    title: "Fast Access with Local Caching",
    description:
      "Log full workouts anywhere, even with zero connectivity. An embedded Drift SQLite engine ensures instant interactions directly on your device.",
    badge: "Local Data Storage",
  },
  {
    icon: Cloud,
    title: "Secure Cloud Synchronization",
    description:
      "When connection returns, pending records sync automatically to PostgreSQL with Row Level Security (RLS) guaranteeing strict personal isolation.",
    badge: "Dual-Layer Cache",
  },
  {
    icon: Zap,
    title: "No-Barrier Guest Mode",
    description:
      "Download and begin tracking immediately without entering personal info. When ready, upgrade seamlessly to cloud backup without losing a single logged set.",
    badge: "Instant Onboarding",
  },
  {
    icon: Droplets,
    title: "Integrated Macro & Water Tracking",
    description:
      "A complete daily wellness suite. Balance hydration with 1-tap volume presets and log protein, carbohydrates, and fats alongside training volume.",
    badge: "Holistic Health",
  },
];

const faqs = [
  {
    q: "Is Fit Host a web application or a native mobile app?",
    a: "Fit Host is a native mobile application engineered with Flutter for Android and iOS. This website is the official product launch and update portal where you can find download links, version releases, setup guides, and support.",
  },
  {
    q: "Can I use Fit Host offline without an active internet connection?",
    a: "Yes. Fit Host stores all workouts, hydration logs, and settings in an embedded Drift SQLite database directly on your device. You can track workouts seamlessly without a cellular connection, and your account data synchronizes securely to cloud storage whenever network connectivity is available.",
  },
  {
    q: "Do I have to create an account to test or use Fit Host?",
    a: "No. Fit Host offers a complete Guest Mode with local data storage. You can log exercises, track water, and explore all workout categories immediately without creating an account or providing an email address. When you sign in or create an account, your saved guest records automatically migrate to your cloud account.",
  },
  {
    q: "How does cloud sync protect my personal health data?",
    a: "Cloud data is stored in PostgreSQL and governed by Supabase Row Level Security (RLS) policies. Only your verified authentication token can read or modify your data. Service-role privileges are never exposed to clients, and your workout data is never monetized or shared.",
  },
  {
    q: "Where can I download Fit Host today?",
    a: "You can download the verified Android Release APK directly from this website. Official Apple App Store and Google Play Store listings are currently in preparation.",
  },
];

export default async function HomePage() {
  const latestRelease = await getLatestMobileRelease();
  const featuredGuides = getFeaturedGuides();

  return (
    <div className="relative overflow-hidden">
      {/* Background radial ambient glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1100px] h-[550px] bg-brand-green/10 blur-[140px] rounded-full" />
      <div className="pointer-events-none absolute top-[750px] -left-60 w-[600px] h-[600px] bg-brand-blue/10 blur-[160px] rounded-full" />

      {/* 1. HERO SECTION */}
      <section className="relative pt-12 pb-20 md:pt-20 md:pb-32 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          {/* Left Column: Product Value Proposition */}
          <div className="lg:col-span-7 space-y-6 text-center lg:text-left">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
              <Sparkles className="h-3.5 w-3.5" />
              <span>THE MOBILE FITNESS ENGINE • {latestRelease.version}</span>
            </div>

            <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-white leading-[1.08]">
              Train Harder. <br />
              Log Faster. <br />
              <span className="text-gradient-green">Command Your Progress.</span>
            </h1>

            <p className="text-base sm:text-xl text-zinc-300 leading-relaxed max-w-2xl mx-auto lg:mx-0">
              Fit Host is the high-velocity mobile fitness app for Android and iOS. Log heavy sets, monitor daily hydration, track macro nutrition, and synchronize seamlessly across devices—all with fast access, local data storage, and seamless cloud synchronization.
            </p>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4 pt-2">
              <Link
                href="/download"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-8 py-4 text-base font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-xl shadow-brand-green/25 hover:shadow-brand-green/40 transition-all duration-200 hover:scale-[1.02]"
              >
                <span>Download Fit Host</span>
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/features"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 text-base font-semibold text-white bg-brand-surface hover:bg-brand-elevated rounded-xl border border-brand-border hover:border-brand-green/40 transition-all duration-200"
              >
                <span>Explore Features</span>
              </Link>
            </div>

            {/* Trust Badges */}
            <div className="pt-4 flex flex-wrap items-center justify-center lg:justify-start gap-5 text-xs text-zinc-400">
              <span className="inline-flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-brand-green" /> Local Data Storage
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-brand-green" /> Drift SQLite Engine
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-brand-green" /> No Account Required
              </span>
            </div>
          </div>

          {/* Right Column: Hero Mobile Phone Mockup */}
          <div className="lg:col-span-5 flex justify-center">
            <PhoneMockup
              src="/images/screenshots/home.png"
              alt="Fit Host Mobile Home Screen with Workout Quick Actions"
              priority={true}
              glowColor="green"
              caption="Fit Host mobile home screen with today's workout prompt and live hydration gauge."
              badge="v2.1.0 Android & iOS"
            />
          </div>
        </div>
      </section>

      {/* 2. CORE BENEFITS GRID */}
      <section className="relative py-16 md:py-24 border-y border-brand-border/60 bg-brand-surface/40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto space-y-3 mb-16">
            <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Engineered for Performance</div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Why Serious Athletes Choose Fit Host
            </h2>
            <p className="text-sm sm:text-base text-zinc-400">
              Traditional fitness apps freeze without internet and lock basic logs behind paywalls. Fit Host gives you pure, uninterrupted speed.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {coreBenefits.map((benefit, idx) => {
              const Icon = benefit.icon;
              return (
                <div
                  key={idx}
                  className="rounded-2xl border border-brand-border bg-brand-surface p-6 hover:border-brand-green/40 transition-all flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="p-3 rounded-xl bg-brand-green/10 text-brand-green border border-brand-green/20">
                        <Icon className="h-6 w-6" />
                      </div>
                      <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-brand-elevated text-zinc-400 border border-brand-border">
                        {benefit.badge}
                      </span>
                    </div>
                    <h3 className="text-lg font-bold text-white">{benefit.title}</h3>
                    <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                      {benefit.description}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* 3. VISUAL FEATURE SHOWCASE WITH GENUINE PHONE MOCKUPS */}
      <section className="py-20 md:py-32 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center max-w-2xl mx-auto space-y-3 mb-20">
          <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Visual Showcase</div>
          <h2 className="text-3xl sm:text-5xl font-black text-white tracking-tight">
            See Fit Host in Action
          </h2>
          <p className="text-sm sm:text-base text-zinc-400">
            Real Flutter mobile interfaces captured directly from device execution. Zero mockups, zero distortion.
          </p>
        </div>

        {/* Feature 1: Workout Logger */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-28">
          <div className="lg:col-span-5 order-2 lg:order-1 flex justify-center">
            <PhoneMockup
              src="/images/screenshots/workouts.png"
              alt="Fit Host Workout Logger Screen"
              glowColor="green"
              caption="Detailed set-by-set logging with exercise selection and rest timer."
            />
          </div>
          <div className="lg:col-span-7 order-1 lg:order-2 space-y-6">
            <span className="text-xs font-mono font-bold text-brand-green uppercase tracking-wider bg-brand-green/10 px-3 py-1 rounded-full border border-brand-green/30">
              Feature 01 • Active Training
            </span>
            <h3 className="text-3xl sm:text-4xl font-extrabold text-white">
              Log Every Rep, Weight, and Set Without Friction
            </h3>
            <p className="text-base text-zinc-300 leading-relaxed">
              Open any of the 10 categorized disciplines and jump right into your training. Track weights in kilograms or pounds, check off completed sets with one tap, and rely on the automatic rest countdown to maintain workout intensity.
            </p>
            <ul className="space-y-3 pt-2 text-sm text-zinc-300">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Automatic set volume and total exercise tonnage aggregation.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Audio cues and gentle haptics on rest timer expiration.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Immediate persistence to local SQLite—never lose a set if battery drops.</span>
              </li>
            </ul>
            <div className="pt-2">
              <Link
                href="/guides/logging-workouts"
                className="inline-flex items-center gap-2 text-sm font-bold text-brand-green hover:text-brand-green-hover"
              >
                <span>Read the Workout Logging Guide</span>
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>

        {/* Feature 2: Nutrition & Hydration */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-28">
          <div className="lg:col-span-7 space-y-6">
            <span className="text-xs font-mono font-bold text-brand-blue uppercase tracking-wider bg-brand-blue/20 text-brand-cyan px-3 py-1 rounded-full border border-brand-blue/40">
              Feature 02 • Daily Recovery
            </span>
            <h3 className="text-3xl sm:text-4xl font-extrabold text-white">
              Master Your Macro Balance & Water Intake
            </h3>
            <p className="text-base text-zinc-300 leading-relaxed">
              Exercise is only half the battle. Fit Host equips you with high-contrast macro breakdown bars for protein, carbohydrates, and fats, plus quick 1-tap hydration buttons so you stay properly fueled and hydrated.
            </p>
            <ul className="space-y-3 pt-2 text-sm text-zinc-300">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Instant 250ml, 500ml, and 750ml quick-add hydration buttons.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Visual circular progress rings showing daily percentage achieved.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Calorie target gauges with surplus / deficit indicators.</span>
              </li>
            </ul>
            <div className="pt-2">
              <Link
                href="/guides/tracking-nutrition"
                className="inline-flex items-center gap-2 text-sm font-bold text-brand-green hover:text-brand-green-hover"
              >
                <span>Explore Nutrition & Hydration Guides</span>
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
          <div className="lg:col-span-5 flex justify-center">
            <PhoneMockup
              src="/images/screenshots/nutrition.png"
              alt="Fit Host Macro Nutrition Screen"
              glowColor="blue"
              caption="High-contrast macronutrient balance and daily calorie budget."
            />
          </div>
        </div>

        {/* Feature 3: Progress & History */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          <div className="lg:col-span-5 order-2 lg:order-1 flex justify-center">
            <PhoneMockup
              src="/images/screenshots/progress.png"
              alt="Fit Host Progress Analytics Screen"
              glowColor="green"
              caption="Historical training logs with daily volume charts and consistency streaks."
            />
          </div>
          <div className="lg:col-span-7 order-1 lg:order-2 space-y-6">
            <span className="text-xs font-mono font-bold text-brand-green uppercase tracking-wider bg-brand-green/10 px-3 py-1 rounded-full border border-brand-green/30">
              Feature 03 • Analytics
            </span>
            <h3 className="text-3xl sm:text-4xl font-extrabold text-white">
              Inspect Trends. Celebrate Personal Bests.
            </h3>
            <p className="text-base text-zinc-300 leading-relaxed">
              Review your training journey with chronological workout timelines and weekly volume distributions. Every set logged in the app feeds into accurate performance curves so you can break plateaus.
            </p>
            <ul className="space-y-3 pt-2 text-sm text-zinc-300">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Multi-day training streaks and total sessions completed.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Volume trends by individual muscle groups and movement types.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
                <span>Multi-device synchronization restores full history across phones.</span>
              </li>
            </ul>
            <div className="pt-2">
              <Link
                href="/guides/cloud-sync-architecture"
                className="inline-flex items-center gap-2 text-sm font-bold text-brand-green hover:text-brand-green-hover"
              >
                <span>Learn How Cloud Sync Powers History</span>
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* 4. WORKOUT DISCIPLINES GRID */}
      <section className="py-16 md:py-24 border-t border-brand-border/60 bg-brand-surface/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto space-y-3 mb-16">
            <div className="text-xs font-bold uppercase tracking-wider text-brand-green">10 Core Disciplines</div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Built for Every Training Style
            </h2>
            <p className="text-sm sm:text-base text-zinc-400">
              Whether you are hitting heavy squats, chasing a 5K running goal, or practicing mobility, Fit Host supports your methodology.
            </p>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {workoutCategories.map((cat, idx) => (
              <div
                key={idx}
                className="group relative rounded-2xl border border-brand-border bg-brand-surface p-4 hover:border-brand-green/40 transition-all text-center flex flex-col items-center justify-between"
              >
                <div className="relative h-16 w-16 mb-3 rounded-xl overflow-hidden bg-brand-elevated border border-brand-border/60 p-2 group-hover:scale-105 transition-transform">
                  <Image
                    src={cat.icon}
                    alt={cat.name}
                    width={64}
                    height={64}
                    className="object-contain"
                    unoptimized
                  />
                </div>
                <h3 className="text-sm font-bold text-white group-hover:text-brand-green transition-colors">
                  {cat.name}
                </h3>
                <p className="mt-1 text-[11px] text-zinc-400 leading-tight">
                  {cat.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 5. GETTING STARTED TUTORIAL (4 STEPS) */}
      <section className="py-20 md:py-28 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center max-w-2xl mx-auto space-y-3 mb-16">
          <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Quick Start</div>
          <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
            How to Get Started in 4 Easy Steps
          </h2>
          <p className="text-sm sm:text-base text-zinc-400">
            From installation to logging your first workout, here is the exact mobile workflow.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            {
              step: "01",
              title: "Install Fit Host",
              desc: "Download the verified Android APK or install from the app store when available.",
            },
            {
              step: "02",
              title: "Choose Guest or Account",
              desc: "Test immediately in Guest Mode or register with email OTP / Google OAuth for cloud backup.",
            },
            {
              step: "03",
              title: "Log Your Workout",
              desc: "Select your discipline, enter weights and reps, and use the rest timer between sets.",
            },
            {
              step: "04",
              title: "Review & Sync",
              desc: "Saved instantly to Drift SQLite. Synchronizes automatically to PostgreSQL when online.",
            },
          ].map((item, idx) => (
            <div
              key={idx}
              className="relative rounded-2xl border border-brand-border bg-brand-surface p-6 flex flex-col justify-between"
            >
              <div>
                <span className="font-mono text-2xl font-black text-brand-green/80">
                  {item.step}
                </span>
                <h3 className="mt-3 text-lg font-bold text-white">{item.title}</h3>
                <p className="mt-2 text-xs sm:text-sm text-zinc-400 leading-relaxed">
                  {item.desc}
                </p>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-10 text-center">
          <Link
            href="/how-it-works"
            className="inline-flex items-center gap-2 text-sm font-bold text-brand-green hover:text-brand-green-hover"
          >
            <span>View Full Step-by-Step Mobile Tutorial</span>
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </section>

      {/* 6. LATEST RELEASE ANNOUNCEMENT */}
      {latestRelease && (
        <section className="py-16 md:py-20 border-t border-brand-border/60 bg-brand-surface/40">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-8">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Latest Release</div>
                <h2 className="text-2xl sm:text-3xl font-black text-white">What&apos;s New in Fit Host</h2>
              </div>
              <Link
                href="/updates"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-green hover:text-brand-green-hover"
              >
                <span>View Full Changelog</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>

            <LatestReleaseBanner release={latestRelease} />
          </div>
        </section>
      )}

      {/* 7. FEATURED GUIDES */}
      <section className="py-20 md:py-28 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-12">
          <div>
            <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Knowledge Base</div>
            <h2 className="text-2xl sm:text-3xl font-black text-white">Educational Guides & Tutorials</h2>
            <p className="mt-1 text-sm text-zinc-400">
              Step-by-step guides explaining how to use Fit Host features effectively.
            </p>
          </div>
          <Link
            href="/guides"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-green hover:text-brand-green-hover"
          >
            <span>All 8 Guides</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {featuredGuides.map((guide) => (
            <GuideCard key={guide.slug} guide={guide} />
          ))}
        </div>
      </section>

      {/* 8. DOWNLOAD CTA SECTION WITH STORE LINKS */}
      <section id="download" className="py-16 md:py-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto scroll-mt-20">
        <DownloadCTA variant="banner" />
      </section>

      {/* 9. FAQS */}
      <section className="py-16 md:py-24 border-t border-brand-border/60 bg-brand-surface/20">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center space-y-3 mb-16">
            <div className="text-xs font-bold uppercase tracking-wider text-brand-green">Got Questions?</div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Frequently Asked Questions
            </h2>
            <p className="text-sm text-zinc-400">
              Clear answers regarding mobile installation, guest mode with local data storage, privacy, and account synchronization.
            </p>
          </div>

          <div className="space-y-4">
            {faqs.map((faq, idx) => (
              <div
                key={idx}
                className="rounded-2xl border border-brand-border bg-brand-surface p-6 space-y-2 hover:border-brand-green/30 transition-colors"
              >
                <h3 className="text-base sm:text-lg font-bold text-white flex items-center gap-2">
                  <span className="text-brand-green font-mono text-sm">Q:</span>
                  {faq.q}
                </h3>
                <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed pl-6">
                  {faq.a}
                </p>
              </div>
            ))}
          </div>

          <div className="mt-12 text-center text-xs text-zinc-500">
            Need further assistance? Visit our{" "}
            <Link href="/support" className="text-brand-green font-semibold hover:underline">
              Support Center
            </Link>{" "}
            or email us at{" "}
            <a href={`mailto:${siteConfig.support.email}`} className="text-brand-green font-mono hover:underline">
              {siteConfig.support.email}
            </a>
            .
          </div>
        </div>
      </section>
    </div>
  );
}
