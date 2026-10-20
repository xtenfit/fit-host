import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import {
  ArrowLeft,
  Calendar,
  Smartphone,
  ExternalLink,
} from "lucide-react";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import VersionBadge from "@/components/releases/VersionBadge";
import ReleaseNotes from "@/components/releases/ReleaseNotes";
import ReleaseAssetList from "@/components/releases/ReleaseAssetList";
import PlatformDownloadCard from "@/components/releases/PlatformDownloadCard";
import {
  getAllMobileReleases,
  getMobileReleaseBySlug,
} from "@/lib/github/releases";

interface ReleasePageProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  const releases = await getAllMobileReleases();
  return releases.map((r) => ({ slug: r.slug }));
}

export async function generateMetadata({ params }: ReleasePageProps): Promise<Metadata> {
  const { slug } = await params;
  const release = await getMobileReleaseBySlug(slug);
  if (!release) return { title: "Release Not Found | Fit Host" };

  return {
    title: `${release.version} — ${release.title} | Fit Host Release Notes`,
    description: release.notes.summary || release.title,
  };
}

export default async function ReleaseDetailPage({ params }: ReleasePageProps) {
  const { slug } = await params;
  const release = await getMobileReleaseBySlug(slug);

  if (!release) {
    notFound();
  }

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />
      <div className="pointer-events-none absolute top-[600px] -right-40 w-[600px] h-[600px] bg-brand-blue/10 blur-[160px] rounded-full" />

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        {/* Back link */}
        <div className="flex items-center justify-between">
          <Link
            href="/updates"
            className="inline-flex items-center gap-2 text-xs font-bold text-zinc-400 hover:text-brand-green transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Back to All Releases</span>
          </Link>

          {release.htmlUrl && (
            <a
              href={release.htmlUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 text-xs text-zinc-400 hover:text-white transition-colors"
            >
              <span>GitHub Release</span>
              <ExternalLink className="h-3.5 w-3.5" />
            </a>
          )}
        </div>

        {/* Release Header */}
        <div className="space-y-4 border-b border-brand-border/60 pb-8">
          <div className="flex flex-wrap items-center gap-3">
            <VersionBadge
              version={release.version}
              isPrerelease={release.isPrerelease}
              isFallback={release.isFallback}
            />
            <div className="flex items-center gap-1.5 text-xs text-zinc-400">
              <Calendar className="h-3.5 w-3.5 text-zinc-500" />
              <time dateTime={release.publishedAt}>{release.displayDate}</time>
            </div>
            <span className="text-[11px] font-semibold text-brand-green bg-brand-green/10 border border-brand-green/30 px-2 py-0.5 rounded-full">
              Mobile Application Build
            </span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight">
            {release.title}
          </h1>

          <p className="text-base sm:text-lg text-zinc-300 leading-relaxed">
            {release.notes.summary}
          </p>
        </div>

        {/* Structured Release Notes */}
        <ReleaseNotes notes={release.notes} />

        {/* Download Cards Section */}
        <div className="space-y-4 pt-4">
          <div className="text-xs font-bold uppercase tracking-wider text-zinc-400">
            Platform Availability for {release.version}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <PlatformDownloadCard
              platform="android"
              info={release.android}
              slug={release.slug}
            />
            <PlatformDownloadCard
              platform="ios"
              info={release.ios}
              slug={release.slug}
            />
          </div>
        </div>

        {/* Verified Release Assets */}
        {release.assets.length > 0 && (
          <div className="pt-4">
            <ReleaseAssetList
              assets={release.assets}
              sha256Checksum={release.android.sha256Checksum}
            />
          </div>
        )}

        {/* Platform Notes / Compatibility */}
        {release.android.minimumSupportedOs && (
          <div className="rounded-2xl border border-brand-border bg-brand-surface/60 p-5 flex items-center gap-3 text-xs text-zinc-400">
            <Smartphone className="h-5 w-5 text-brand-green shrink-0" />
            <p>
              <strong className="text-white">Compatibility: </strong>
              Requires {release.android.minimumSupportedOs} or {release.ios.minimumSupportedOs}.
            </p>
          </div>
        )}

        {/* CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
