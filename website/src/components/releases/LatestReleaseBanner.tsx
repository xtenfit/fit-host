import React from "react";
import Link from "next/link";
import { Sparkles, ArrowRight, Download, Calendar, Smartphone, Apple, Clock } from "lucide-react";
import type { MobileRelease } from "@/lib/github/releases";
import VersionBadge from "./VersionBadge";

interface LatestReleaseBannerProps {
  release: MobileRelease;
  className?: string;
}

export default function LatestReleaseBanner({ release, className = "" }: LatestReleaseBannerProps) {
  const hasAndroidApk = Boolean(release.android.downloadUrl && release.android.distributionStatus === "available");
  const hasIos = Boolean(release.ios.downloadUrl && release.ios.distributionStatus !== "coming_soon");

  return (
    <div
      className={`relative overflow-hidden rounded-3xl border border-brand-green/30 bg-gradient-to-r from-brand-surface via-brand-surface/90 to-brand-elevated p-6 sm:p-8 shadow-2xl backdrop-blur-xl ${className}`}
    >
      {/* Ambient neon radial aura */}
      <div className="pointer-events-none absolute -right-20 -top-20 h-56 w-56 rounded-full bg-brand-green/15 blur-3xl" />

      <div className="relative z-10 flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
        {/* Left: Metadata & summary */}
        <div className="space-y-3 max-w-3xl">
          <div className="flex flex-wrap items-center gap-2.5">
            <VersionBadge
              version={release.version}
              isLatest={true}
              isFallback={release.isFallback}
            />
            <div className="flex items-center gap-1.5 text-xs text-zinc-400">
              <Calendar className="h-3.5 w-3.5 text-zinc-500" />
              <time dateTime={release.publishedAt}>{release.displayDate}</time>
            </div>
            <span className="text-[11px] font-semibold text-brand-green bg-brand-green/10 border border-brand-green/30 px-2 py-0.5 rounded-full">
              Verified Mobile Release
            </span>
          </div>

          <h3 className="text-xl sm:text-2xl font-black text-white tracking-tight">
            {release.title}
          </h3>

          <p className="text-sm sm:text-base text-zinc-300 leading-relaxed line-clamp-2">
            {release.notes.summary || "Latest production build of the Fit Host mobile engine with enhanced performance and local caching."}
          </p>

          <div className="flex items-center gap-4 pt-1 text-xs">
            <Link
              href={`/updates/${release.slug}`}
              className="inline-flex items-center gap-1 font-bold text-brand-green hover:text-brand-green-hover transition-colors"
            >
              <span>Read Full Release Notes &amp; Changelog</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>

        {/* Right: Platform Actions */}
        <div className="flex flex-col sm:flex-row lg:flex-col xl:flex-row items-stretch sm:items-center gap-3 shrink-0 w-full sm:w-auto">
          {hasAndroidApk ? (
            <a
              href={release.android.downloadUrl!}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-5 py-3 text-sm font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-lg shadow-brand-green/20 hover:shadow-brand-green/35 transition-all hover:scale-[1.02]"
            >
              <Download className="h-4 w-4" />
              <span>Download Android APK</span>
              {release.android.assetSize && (
                <span className="text-[11px] font-mono bg-black/20 px-2 py-0.5 rounded">
                  {release.android.assetSize}
                </span>
              )}
            </a>
          ) : (
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
              <div className="inline-flex items-center justify-center gap-2 px-4 py-3 text-xs font-semibold text-brand-green bg-brand-green/10 rounded-xl border border-brand-green/30 select-none">
                <Clock className="h-4 w-4 text-brand-green" />
                <span>Android APK: Release Soon</span>
              </div>
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-1.5 px-4 py-3 text-xs font-semibold text-zinc-300 hover:text-white bg-brand-surface hover:bg-brand-elevated rounded-xl border border-brand-border transition-all"
              >
                <span>Release Status</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          )}

          {hasIos ? (
            <a
              href={release.ios.downloadUrl!}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-4 py-3 text-xs font-semibold text-white bg-brand-elevated hover:bg-brand-surface rounded-xl border border-brand-border transition-all"
            >
              <Apple className="h-4 w-4 text-brand-blue" />
              <span>TestFlight iOS</span>
            </a>
          ) : (
            <div className="inline-flex items-center justify-center gap-2 px-4 py-3 text-xs font-medium text-zinc-400 bg-brand-surface/80 rounded-xl border border-brand-border/60 select-none">
              <Apple className="h-4 w-4 text-zinc-500" />
              <span>iOS: Coming Soon</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
