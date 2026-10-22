import type { Metadata } from "next";
import Link from "next/link";
import {
  Download,
  ShieldCheck,
  ExternalLink,
  FileCode,
} from "lucide-react";
import PlatformDownloadCard from "@/components/releases/PlatformDownloadCard";
import LatestReleaseBanner from "@/components/releases/LatestReleaseBanner";
import ReleaseAssetList from "@/components/releases/ReleaseAssetList";
import { getLatestMobileRelease } from "@/lib/github/releases";
import { releasesConfig } from "@/lib/config/releases";

export const metadata: Metadata = {
  title: "Download Fit Host Mobile App — Android APK & iOS Releases",
  description:
    "Download the latest official Fit Host mobile fitness and wellness application for Android and iOS. Verified releases, direct APK downloads, release notes, and install guides.",
};

export default async function DownloadPage() {
  const latestRelease = await getLatestMobileRelease();

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background ambient lighting */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1100px] h-[550px] bg-brand-green/10 blur-[140px] rounded-full" />
      <div className="pointer-events-none absolute top-[600px] -right-40 w-[600px] h-[600px] bg-brand-blue/10 blur-[160px] rounded-full" />

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12 sm:space-y-16">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
            <Download className="h-3.5 w-3.5" />
            <span>OFFICIAL MOBILE RELEASES • {latestRelease.version}</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white">
            Download Fit Host
          </h1>

          <p className="text-base sm:text-xl text-zinc-300 leading-relaxed">
            Choose your mobile platform below. Get the verified production APK for Android or check Apple iOS distribution status.
          </p>
        </div>

        {/* Latest Release Banner summary */}
        <LatestReleaseBanner release={latestRelease} />

        {/* Platform Downloads Grid */}
        <section className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              Platform Downloads
            </h2>
            <Link
              href="/updates"
              className="text-xs font-bold text-brand-green hover:text-brand-green-hover transition-colors"
            >
              All Releases History →
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <PlatformDownloadCard
              platform="android"
              info={latestRelease.android}
              slug={latestRelease.slug}
            />

            <PlatformDownloadCard
              platform="ios"
              info={latestRelease.ios}
              slug={latestRelease.slug}
            />
          </div>
        </section>

        {/* Verified Release Binary Assets */}
        <section className="rounded-3xl border border-brand-border bg-brand-surface/40 p-6 sm:p-8 backdrop-blur-sm space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-white">
                Published Build Artifacts ({latestRelease.version})
              </h3>
              <p className="text-xs text-zinc-400 mt-0.5">
                Direct binary files hosted on GitHub Releases for this version.
              </p>
            </div>

            {latestRelease.htmlUrl && (
              <a
                href={latestRelease.htmlUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-xs text-brand-green hover:text-brand-green-hover font-bold"
              >
                <span>View on GitHub</span>
                <ExternalLink className="h-3 w-3" />
              </a>
            )}
          </div>

          <ReleaseAssetList
            assets={latestRelease.assets}
            sha256Checksum={latestRelease.android.sha256Checksum}
          />
        </section>

        {/* Android Step-by-Step Sideload Installation Guide */}
        <section className="rounded-3xl border border-brand-border bg-gradient-to-b from-brand-surface to-brand-elevated/80 p-8 sm:p-10 space-y-8 shadow-xl">
          <div className="max-w-3xl space-y-2">
            <div className="text-xs font-bold uppercase tracking-wider text-brand-green">
              Installation Guide
            </div>
            <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              How to Install on Android
            </h2>
            <p className="text-sm text-zinc-400 leading-relaxed">
              Because this is a direct APK release from GitHub without Google Play Store intermediation, Android will protect your device by verifying user authorization. Follow these three quick steps:
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Step 1 */}
            <div className="rounded-2xl border border-brand-border/60 bg-brand-surface/80 p-6 space-y-3">
              <div className="h-8 w-8 rounded-xl bg-brand-green text-black font-black flex items-center justify-center text-sm shadow-md shadow-brand-green/20">
                1
              </div>
              <h3 className="text-base font-bold text-white">Download the Release APK</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Tap the <strong className="text-zinc-200">Download Android APK</strong> button above. When your mobile browser prompts &ldquo;File might be harmful&rdquo;, tap <strong className="text-zinc-200">Download anyway</strong>.
              </p>
            </div>

            {/* Step 2 */}
            <div className="rounded-2xl border border-brand-border/60 bg-brand-surface/80 p-6 space-y-3">
              <div className="h-8 w-8 rounded-xl bg-brand-green text-black font-black flex items-center justify-center text-sm shadow-md shadow-brand-green/20">
                2
              </div>
              <h3 className="text-base font-bold text-white">Allow Unknown App Source</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Open the downloaded file or notification. If Android says &ldquo;For your security, your phone is not allowed to install unknown apps&rdquo;, tap <strong className="text-zinc-200">Settings</strong> and toggle <strong className="text-zinc-200">Allow from this source</strong>.
              </p>
            </div>

            {/* Step 3 */}
            <div className="rounded-2xl border border-brand-border/60 bg-brand-surface/80 p-6 space-y-3">
              <div className="h-8 w-8 rounded-xl bg-brand-green text-black font-black flex items-center justify-center text-sm shadow-md shadow-brand-green/20">
                3
              </div>
              <h3 className="text-base font-bold text-white">Launch &amp; Start Training</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Tap <strong className="text-zinc-200">Install</strong>, then tap <strong className="text-zinc-200">Open</strong>. Fit Host will launch with full local Drift SQLite storage and guest mode ready immediately.
              </p>
            </div>
          </div>

          <div className="rounded-xl border border-brand-border bg-black/40 p-4 flex items-start gap-3 text-xs text-zinc-400">
            <ShieldCheck className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
            <div className="space-y-1">
              <span className="font-semibold text-zinc-200 block">
                Source Code &amp; Binary Integrity
              </span>
              <p className="leading-relaxed">
                Every release APK is compiled directly from the official Fit Host Flutter codebase and published transparently to GitHub Releases. The app contains zero tracker bloatware, zero adware, and strictly isolates your local database.
              </p>
            </div>
          </div>
        </section>

        {/* GitHub Releases Transparency Notice */}
        <div className="rounded-2xl border border-brand-border bg-brand-surface/60 p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-zinc-400">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-brand-surface border border-brand-border text-zinc-300">
              <FileCode className="h-5 w-5" />
            </div>
            <div>
              <div className="font-bold text-white">Continuous GitHub Delivery</div>
              <div className="text-zinc-400">
                Repository: <span className="font-mono text-zinc-300">{releasesConfig.github.owner}/{releasesConfig.github.repo}</span> • Cache revalidation every {Math.round(releasesConfig.revalidation.intervalSeconds / 60)} minutes.
              </div>
            </div>
          </div>

          <a
            href={`https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-brand-surface border border-brand-border text-zinc-300 hover:text-white hover:border-zinc-500 font-semibold transition-all shrink-0"
          >
            <span>GitHub Releases</span>
            <ExternalLink className="h-3.5 w-3.5" />
          </a>
        </div>
      </div>
    </div>
  );
}
