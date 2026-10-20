import type { Metadata } from "next";
import Link from "next/link";
import { BookOpen, Sparkles, Clock, ArrowRight, CheckCircle2 } from "lucide-react";
import GuideCard from "@/components/marketing/GuideCard";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import { getAllGuides, GuideArticle } from "@/lib/data/guides";

export const metadata: Metadata = {
  title: "Guides & Tutorials — Master Fit Host Mobile Features",
  description:
    "Explore in-depth setup tutorials and educational guides for Fit Host: workout logging, guest mode, macro tracking, cloud synchronization, and troubleshooting.",
};

const categories = [
  "All",
  "Getting Started",
  "Workouts",
  "Nutrition & Water",
  "Sync & Security",
  "Troubleshooting",
];

export default function GuidesPage() {
  const allGuides = getAllGuides();

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background radial glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12 sm:space-y-16">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
            <BookOpen className="h-3.5 w-3.5" />
            <span>KNOWLEDGE BASE & DOCUMENTATION</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white">
            Fit Host Guides & Tutorials
          </h1>

          <p className="text-base sm:text-xl text-zinc-300 leading-relaxed">
            Practical, step-by-step documentation for every capability of the Fit Host mobile application. Learn how to log routines, configure macro splits, and manage cloud backup.
          </p>
        </div>

        {/* Guides Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
          {allGuides.map((guide) => (
            <GuideCard key={guide.slug} guide={guide} />
          ))}
        </div>

        {/* Troubleshooting Callout */}
        <div className="rounded-3xl border border-brand-border bg-brand-surface p-8 sm:p-10 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="space-y-2 text-center md:text-left">
            <h3 className="text-xl font-bold text-white">
              Experiencing Connectivity or Sync Issues?
            </h3>
            <p className="text-xs sm:text-sm text-zinc-400 max-w-xl">
              Check out our dedicated sync diagnostic checklist to inspect network permissions, trigger manual refreshes, and verify local SQLite storage.
            </p>
          </div>
          <Link
            href="/guides/troubleshooting-sync"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-brand-elevated hover:bg-brand-elevated/80 border border-brand-green/40 text-brand-green font-bold text-sm transition-colors shrink-0"
          >
            <span>Troubleshooting Guide</span>
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>

        {/* CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
