import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import {
  ShieldCheck,
  Zap,
  Database,
  Code2,
  CheckCircle2,
  ArrowRight,
} from "lucide-react";

export const metadata: Metadata = {
  title: "About Fit Host — Mission, Architecture & Core Philosophy",
  description:
    "Learn about Fit Host: a fast fitness tracking platform with secure cloud sync, engineered for high-performance training without ads, bloat, or connectivity bottlenecks.",
};

const principles = [
  {
    title: "Fast Access with Local Caching",
    desc: "Gym basements and outdoor tracks shouldn't break your workout log. Fit Host stores data locally on your device for immediate responsiveness, syncing to the cloud asynchronously.",
    icon: Database,
  },
  {
    title: "Zero Exploitative Monetization",
    desc: "We don't sell your biometric health logs or clutter your training flow with intrusive banner ads and paywalled timers.",
    icon: ShieldCheck,
  },
  {
    title: "Instant Performance & 60fps UX",
    desc: "Engineered with Flutter for native mobile fluidity and Next.js for server-rendered web speed. Every interaction feels instantaneous.",
    icon: Zap,
  },
  {
    title: "Data Sovereignty",
    desc: "Your data belongs to you. We leverage Supabase PostgreSQL with strict Row Level Security (RLS) policies, ensuring only you can access your personal metrics.",
    icon: Code2,
  },
];

export default function AboutPage() {
  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-20">
      {/* Header */}
      <div className="text-center max-w-3xl mx-auto space-y-4">
        <span className="text-xs font-bold uppercase tracking-widest text-brand-green">
          Our Mission & Philosophy
        </span>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
          Built for Athletes Who Demand Reliability
        </h1>
        <p className="text-base sm:text-lg text-zinc-300 leading-relaxed">
          Fit Host was designed to solve a simple yet widespread frustration: fitness apps that crash, freeze, or fail when gym cellular reception drops.
        </p>
      </div>

      {/* Origin & Architecture Story */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        <div className="space-y-6">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-white">
            Frustrated by Sluggish, Cloud-Dependent Workout Apps
          </h2>
          <p className="text-zinc-300 text-sm leading-relaxed">
            Most modern fitness applications are essentially web wrappers that require constant server handshakes for every button press. When you walk into a concrete gym basement or an underground weight room, their interfaces hang on spinners and your logged sets are lost.
          </p>
          <p className="text-zinc-300 text-sm leading-relaxed">
            Fit Host was engineered with an inverted paradigm: <strong>local-first execution with transparent cloud sync</strong>. When you log a bench press set, it writes immediately to an embedded Drift SQLite database on your device in under 5 milliseconds. No network latency, no lost records. When you step outside or reconnect to Wi-Fi, the changes automatically replicate to Supabase.
          </p>

          <div className="p-4 rounded-xl bg-brand-surface border border-brand-border space-y-2">
            <h4 className="text-xs font-bold uppercase tracking-wider text-brand-green">
              Technical Stack Highlights
            </h4>
            <div className="grid grid-cols-2 gap-2 text-xs text-zinc-300">
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" /> Flutter 3.x Native Engine
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" /> Embedded Drift SQLite
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" /> Supabase PostgreSQL & RLS
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" /> Next.js App Router (Web)
              </span>
            </div>
          </div>
        </div>

        {/* Mockup card */}
        <div className="relative mx-auto max-w-md w-full">
          <div className="glass-panel p-6 rounded-2xl border border-brand-green/20 space-y-4 neon-glow">
            <div className="flex items-center gap-3 pb-4 border-b border-brand-border">
              <div className="relative h-12 w-12 rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
                <Image
                  src="/fit_host_icon.png"
                  alt="Fit Host Emblem"
                  width={48}
                  height={48}
                  className="object-cover"
                />
              </div>
              <div>
                <h3 className="text-base font-bold text-white">Fit Host Architecture</h3>
                <p className="text-xs text-brand-green font-mono">fithost.amitrana.tech</p>
              </div>
            </div>

            <div className="space-y-3 text-xs text-zinc-300">
              <div className="p-3 rounded-lg bg-brand-elevated border border-brand-border">
                <span className="text-zinc-500 uppercase font-mono text-[10px] block">Principle 1</span>
                <span className="text-white font-semibold">Zero forced registration to log workouts</span>
              </div>
              <div className="p-3 rounded-lg bg-brand-elevated border border-brand-border">
                <span className="text-zinc-500 uppercase font-mono text-[10px] block">Principle 2</span>
                <span className="text-white font-semibold">Decoupled local & cloud state for total resilience</span>
              </div>
              <div className="p-3 rounded-lg bg-brand-elevated border border-brand-border">
                <span className="text-zinc-500 uppercase font-mono text-[10px] block">Principle 3</span>
                <span className="text-white font-semibold">Strict data encryption & zero third-party brokers</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Core Principles Grid */}
      <div className="space-y-8">
        <div className="text-center max-w-2xl mx-auto">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-white">
            Our Guiding Engineering Standards
          </h2>
          <p className="text-zinc-400 text-sm mt-2">
            Every architectural decision is measured against training flow and data integrity.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {principles.map((p, i) => {
            const Icon = p.icon;
            return (
              <div
                key={i}
                className="glass-panel p-6 rounded-2xl border border-brand-border hover:border-brand-green/30 transition-colors space-y-3"
              >
                <div className="h-10 w-10 rounded-xl bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="text-lg font-bold text-white">{p.title}</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">{p.desc}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Intended Audience & Call to Action */}
      <div className="glass-panel p-8 rounded-2xl border border-brand-border text-center space-y-6 max-w-3xl mx-auto">
        <h3 className="text-2xl font-bold text-white">Who Is Fit Host For?</h3>
        <p className="text-sm text-zinc-300 leading-relaxed">
          Fit Host is tailored for strength athletes, bodybuilders, calisthenics practitioners, endurance runners, and anyone serious about tracking their physical output without friction, advertisements, or cloud dependencies.
        </p>
        <div className="pt-2">
          <Link
            href="/#download"
            className="inline-flex items-center gap-2 px-8 py-3 rounded-xl bg-brand-green text-black font-bold text-sm shadow-md hover:bg-brand-green-hover transition-colors"
          >
            Download the Mobile App
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}
