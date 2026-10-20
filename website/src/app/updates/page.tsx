import type { Metadata } from "next";
import Link from "next/link";
import { Sparkles, AlertCircle, ExternalLink } from "lucide-react";
import ReleaseHistory from "@/components/releases/ReleaseHistory";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import { getAllMobileReleases } from "@/lib/github/releases";
import { releasesConfig } from "@/lib/config/releases";

export const metadata: Metadata = {
  title: "What's New — Fit Host Release Notes & Updates",
  description:
    "Explore official product updates, mobile releases, technical improvements, and bug fixes for the Fit Host fitness application. Powered by GitHub Releases.",
};

export default async function UpdatesPage() {
  const releases = await getAllMobileReleases();

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background radial glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />
      <div className="pointer-events-none absolute top-[700px] -left-40 w-[600px] h-[600px] bg-brand-blue/10 blur-[160px] rounded-full" />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12 sm:space-y-16">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-brand-green/30 bg-brand-green/10 text-brand-green text-xs font-semibold tracking-wide">
            <Sparkles className="h-3.5 w-3.5" />
            <span>OFFICIAL PRODUCT CHANGELOG</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white">
            What&apos;s New in Fit Host
          </h1>

          <p className="text-base sm:text-xl text-zinc-300 leading-relaxed">
            Track our continuous mobile engineering progress. Review verified release notes, technical improvements, and architectural milestones directly synchronized from GitHub Releases.
          </p>
        </div>

        {/* Releases Stream */}
        <ReleaseHistory releases={releases} />

        {/* Publishing Disclaimer */}
        <div className="rounded-2xl border border-brand-border bg-brand-surface/60 p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-zinc-400">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-zinc-500 shrink-0 mt-0.5" />
            <p className="leading-relaxed">
              All release updates published here correspond directly to verified git tags, Flutter builds, and Supabase migrations from repository{" "}
              <span className="font-mono text-zinc-300">
                {releasesConfig.github.owner}/{releasesConfig.github.repo}
              </span>
              . Draft notes and experimental features are withheld until verified in production builds.
            </p>
          </div>

          <a
            href={`https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-brand-border bg-brand-surface text-zinc-300 hover:text-white shrink-0 font-medium"
          >
            <span>GitHub Releases</span>
            <ExternalLink className="h-3.5 w-3.5" />
          </a>
        </div>

        {/* CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
