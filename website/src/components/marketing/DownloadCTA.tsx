"use client";

import Link from "next/link";
import { Download, Smartphone, Apple, CheckCircle2, AlertCircle, ArrowRight } from "lucide-react";
import { siteConfig } from "@/lib/config/site";

interface DownloadCTAProps {
  variant?: "hero" | "banner" | "compact";
  version?: string;
  releaseDate?: string;
  downloadUrl?: string;
  fileSize?: string;
  className?: string;
}

export default function DownloadCTA({
  variant = "banner",
  version: propVersion,
  releaseDate: propReleaseDate,
  downloadUrl: propDownloadUrl,
  fileSize: propFileSize,
  className = "",
}: DownloadCTAProps) {
  const { storeLinks, version: defaultVersion, releaseDate: defaultReleaseDate } = siteConfig;
  const currentVersion = propVersion || defaultVersion;
  const currentReleaseDate = propReleaseDate || defaultReleaseDate;
  const apkDownloadUrl = propDownloadUrl || storeLinks.directApk.url;
  const apkSize = propFileSize || storeLinks.directApk.fileSize;

  if (variant === "compact") {
    return (
      <div className={`flex flex-col sm:flex-row items-center gap-3 ${className}`}>
        <a
          href={apkDownloadUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3 text-sm font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-lg shadow-brand-green/20 transition-all"
        >
          <Download className="h-4 w-4" />
          <span>Download Release APK ({currentVersion})</span>
        </a>
        <div className="flex items-center gap-2">
          <Link
            href="/download"
            className="px-3 py-2 text-xs font-medium text-zinc-400 hover:text-white bg-brand-surface rounded-lg border border-brand-border transition-colors"
          >
            All Downloads →
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`relative overflow-hidden rounded-3xl border border-brand-border bg-gradient-to-br from-brand-surface via-brand-surface to-brand-elevated p-8 sm:p-12 shadow-2xl ${className}`}
    >
      {/* Background neon ambient aura */}
      <div className="pointer-events-none absolute -top-24 -right-24 h-64 w-64 rounded-full bg-brand-green/15 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-24 -left-24 h-64 w-64 rounded-full bg-brand-blue/15 blur-3xl" />

      <div className="relative z-10 max-w-3xl mx-auto text-center space-y-6">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
          <Smartphone className="h-3.5 w-3.5" />
          <span>CURRENT BUILD: {currentVersion} • {currentReleaseDate.toUpperCase()}</span>
        </div>

        <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight">
          Ready to Train Without Limits?
        </h2>

        <p className="text-base sm:text-lg text-zinc-300 max-w-2xl mx-auto leading-relaxed">
          Fit Host is a dedicated mobile application for iOS and Android. Experience sub-millisecond offline workout logging, accurate macro tracking, and two-way cloud sync.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-2">
          <Link
            href="/download"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-7 py-3.5 text-base font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-xl shadow-brand-green/25 hover:shadow-brand-green/40 transition-all hover:scale-[1.02]"
          >
            <Download className="h-5 w-5" />
            <span>Get Fit Host Mobile App</span>
            <ArrowRight className="h-4 w-4" />
          </Link>

          <a
            href={apkDownloadUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold text-white bg-brand-elevated hover:bg-brand-surface rounded-xl border border-brand-border hover:border-brand-green/40 transition-all"
          >
            <span>Direct Android APK</span>
            <span className="text-xs bg-black/30 text-brand-green px-2 py-0.5 rounded-md font-mono">
              {apkSize}
            </span>
          </a>

          {/* iOS App Store Status */}
          <div
            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-brand-elevated/80 border border-brand-border text-zinc-400 text-xs font-semibold cursor-not-allowed select-none"
            title="Official Apple App Store review in progress"
          >
            <Apple className="h-4 w-4 text-zinc-400" />
            <div className="text-left">
              <div className="text-[10px] uppercase text-zinc-500 font-bold leading-tight">App Store</div>
              <div className="text-zinc-300 font-medium leading-tight">Coming Soon</div>
            </div>
          </div>
        </div>

        {/* Trust Badges */}
        <div className="pt-4 flex flex-wrap items-center justify-center gap-6 text-xs text-zinc-400">
          <span className="inline-flex items-center gap-1.5">
            <CheckCircle2 className="h-4 w-4 text-brand-green" /> 100% Free to Use
          </span>
          <span className="inline-flex items-center gap-1.5">
            <CheckCircle2 className="h-4 w-4 text-brand-green" /> Offline Drift SQLite Storage
          </span>
          <span className="inline-flex items-center gap-1.5">
            <CheckCircle2 className="h-4 w-4 text-brand-green" /> Zero Forced Advertising
          </span>
        </div>

        {/* Store link disclaimer */}
        <div className="pt-2 flex items-center justify-center gap-2 text-[11px] text-zinc-500">
          <AlertCircle className="h-3 w-3 text-zinc-500 shrink-0" />
          <span>
            Official store listings are currently being prepared for App Store and Google Play. You can install the verified Android Release APK today.
          </span>
        </div>
      </div>
    </div>
  );
}
