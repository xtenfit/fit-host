import type { Metadata } from "next";
import Link from "next/link";
import {
  CheckCircle2,
  Clock,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Smartphone,
  Cpu,
  Layers,
  Flame,
} from "lucide-react";
import PhoneMockup from "@/components/marketing/PhoneMockup";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import { getAllFeatures, FeatureStatus } from "@/lib/data/features";

export const metadata: Metadata = {
  title: "Features — Workouts, Hydration, Nutrition & Secure Sync",
  description:
    "Explore Fit Host's verified mobile features: fast fitness tracking with secure cloud sync, hydration tracking, macro nutrition management, and guest mode with local data storage.",
};

export default function FeaturesPage() {
  const allFeatures = getAllFeatures();
  const availableFeatures = allFeatures.filter((f) => f.status === "available");
  const partialFeatures = allFeatures.filter((f) => f.status === "partially_available");
  const plannedFeatures = allFeatures.filter((f) => f.status === "planned");

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16 sm:space-y-24">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
            <Sparkles className="h-3.5 w-3.5" />
            <span>AUTHENTIC PRODUCT CAPABILITIES</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white">
            Engineered for Pure Performance.
          </h1>

          <p className="text-base sm:text-xl text-zinc-300 leading-relaxed">
            Fit Host is built for speed, offline autonomy, and privacy. Every feature listed here is verified against our Flutter codebase and classified with complete transparency.
          </p>

          {/* Status Legend Pills */}
          <div className="pt-4 flex flex-wrap items-center justify-center gap-4 text-xs font-semibold">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-brand-green/10 text-brand-green border border-brand-green/30">
              <span className="w-2 h-2 rounded-full bg-brand-green animate-pulse" />
              Available Now ({availableFeatures.length})
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/30">
              <span className="w-2 h-2 rounded-full bg-amber-400" />
              Partially Available ({partialFeatures.length})
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-brand-blue/20 text-brand-cyan border border-brand-blue/30">
              <span className="w-2 h-2 rounded-full bg-brand-blue" />
              Planned ({plannedFeatures.length})
            </span>
          </div>
        </div>

        {/* SECTION 1: AVAILABLE NOW (DETAILED SHOWCASES) */}
        <div className="space-y-16">
          <div className="border-b border-brand-border/60 pb-4">
            <h2 className="text-2xl sm:text-3xl font-black text-white flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-brand-green" />
              Available Now in Fit Host v2.1.0
            </h2>
            <p className="mt-1 text-sm text-zinc-400">
              Fully implemented features running natively on Android and iOS devices.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {availableFeatures.map((feature) => (
              <div
                key={feature.id}
                className="rounded-3xl border border-brand-border bg-brand-surface p-6 sm:p-8 flex flex-col justify-between hover:border-brand-green/40 transition-all shadow-xl overflow-hidden"
              >
                <div className="space-y-4">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-xs font-semibold px-2.5 py-0.5 rounded-md bg-brand-elevated text-zinc-400 border border-brand-border">
                      {feature.category}
                    </span>
                    <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-brand-green/10 text-brand-green border border-brand-green/30">
                      {feature.statusLabel}
                    </span>
                  </div>

                  <h3 className="text-xl sm:text-2xl font-bold text-white">
                    {feature.name}
                  </h3>

                  <p className="text-sm text-zinc-300 leading-relaxed">
                    {feature.description}
                  </p>

                  <ul className="space-y-2 pt-2 border-t border-brand-border/60 text-xs sm:text-sm text-zinc-300">
                    {feature.highlights.map((h, i) => (
                      <li key={i} className="flex items-start gap-2">
                        <CheckCircle2 className="h-4 w-4 text-brand-green shrink-0 mt-0.5" />
                        <span>{h}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {feature.screenshot && (
                  <div className="pt-6 mt-6 border-t border-brand-border/60 flex justify-center w-full overflow-hidden">
                    <PhoneMockup
                      src={feature.screenshot}
                      alt={`${feature.name} Mobile Screenshot`}
                      glowColor="none"
                      size="sm"
                    />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* SECTION 2: PARTIALLY AVAILABLE */}
        <div className="space-y-8 pt-8">
          <div className="border-b border-brand-border/60 pb-4">
            <h2 className="text-2xl sm:text-3xl font-black text-white flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-amber-400" />
              Partially Available / In Active Refinement
            </h2>
            <p className="mt-1 text-sm text-zinc-400">
              Features functioning with hardware-specific limitations or currently undergoing background optimization.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {partialFeatures.map((feature) => (
              <div
                key={feature.id}
                className="rounded-3xl border border-amber-500/20 bg-brand-surface p-6 sm:p-8 space-y-4"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-semibold px-2.5 py-0.5 rounded-md bg-brand-elevated text-zinc-400 border border-brand-border">
                    {feature.category}
                  </span>
                  <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/30">
                    {feature.statusLabel}
                  </span>
                </div>

                <h3 className="text-xl sm:text-2xl font-bold text-white">
                  {feature.name}
                </h3>

                <p className="text-sm text-zinc-300 leading-relaxed">
                  {feature.description}
                </p>

                <ul className="space-y-2 pt-2 border-t border-brand-border/60 text-xs sm:text-sm text-zinc-300">
                  {feature.highlights.map((h, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <Clock className="h-4 w-4 text-amber-400 shrink-0 mt-0.5" />
                      <span>{h}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>

        {/* SECTION 3: PLANNED ROADMAP */}
        <div className="space-y-8 pt-8">
          <div className="border-b border-brand-border/60 pb-4">
            <h2 className="text-2xl sm:text-3xl font-black text-white flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-brand-blue" />
              Planned & On Roadmap
            </h2>
            <p className="mt-1 text-sm text-zinc-400">
              Upcoming enhancements scheduled for upcoming minor and major releases.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {plannedFeatures.map((feature) => (
              <div
                key={feature.id}
                className="rounded-3xl border border-brand-border bg-brand-surface/60 p-6 sm:p-8 space-y-4"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-semibold px-2.5 py-0.5 rounded-md bg-brand-elevated text-zinc-400 border border-brand-border">
                    {feature.category}
                  </span>
                  <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-brand-blue/20 text-brand-cyan border border-brand-blue/30">
                    {feature.statusLabel}
                  </span>
                </div>

                <h3 className="text-xl sm:text-2xl font-bold text-white">
                  {feature.name}
                </h3>

                <p className="text-sm text-zinc-300 leading-relaxed">
                  {feature.description}
                </p>

                <ul className="space-y-2 pt-2 border-t border-brand-border/60 text-xs sm:text-sm text-zinc-300">
                  {feature.highlights.map((h, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <Sparkles className="h-4 w-4 text-brand-cyan shrink-0 mt-0.5" />
                      <span>{h}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>

        {/* SECTION 4: DOWNLOAD CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
