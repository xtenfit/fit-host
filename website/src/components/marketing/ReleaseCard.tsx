import Link from "next/link";
import { Sparkles, ArrowRight, CheckCircle2, Calendar, Download } from "lucide-react";
import type { ReleaseUpdate } from "@/lib/data/updates";
import type { MobileRelease } from "@/lib/github/releases";

interface ReleaseCardProps {
  release: ReleaseUpdate | MobileRelease;
  isLatest?: boolean;
}

export default function ReleaseCard({ release, isLatest = false }: ReleaseCardProps) {
  // Support both ReleaseUpdate and MobileRelease
  const isMobileRelease = "notes" in release;
  const version = release.version;
  const title = release.title;
  const slug = release.slug;
  const releaseDate = isMobileRelease ? (release as MobileRelease).displayDate : (release as ReleaseUpdate).releaseDate;
  const summary = isMobileRelease ? (release as MobileRelease).notes.summary : (release as ReleaseUpdate).summary;
  const newFeatures = isMobileRelease ? (release as MobileRelease).notes.whatsNew : (release as ReleaseUpdate).newFeatures;
  const improvementsCount = isMobileRelease ? (release as MobileRelease).notes.improvements.length : (release as ReleaseUpdate).improvements.length;
  const bugFixesCount = isMobileRelease ? (release as MobileRelease).notes.bugFixes.length : (release as ReleaseUpdate).bugFixes.length;
  const downloadUrl = isMobileRelease ? (release as MobileRelease).android?.downloadUrl : null;
  const assetSize = isMobileRelease ? (release as MobileRelease).android?.assetSize : null;

  return (
    <article className="group relative rounded-2xl border border-brand-border bg-brand-surface p-6 sm:p-8 hover:border-brand-green/40 transition-all shadow-lg hover:shadow-brand-green/5 flex flex-col justify-between">
      {/* Top Meta */}
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <span className="font-mono text-xs font-bold px-3 py-1 rounded-full bg-brand-green/10 text-brand-green border border-brand-green/30">
              {version}
            </span>
            {isLatest && (
              <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-0.5 rounded-full bg-brand-blue/20 text-brand-cyan border border-brand-blue/40">
                <Sparkles className="h-3 w-3" />
                Latest Release
              </span>
            )}
          </div>
          <div className="flex items-center gap-1.5 text-xs text-zinc-400">
            <Calendar className="h-3.5 w-3.5 text-zinc-500" />
            <time dateTime={releaseDate}>{releaseDate}</time>
          </div>
        </div>

        {/* Title & Summary */}
        <div>
          <h3 className="text-xl sm:text-2xl font-bold text-white group-hover:text-brand-green transition-colors">
            <Link href={`/updates/${slug}`}>
              {title}
            </Link>
          </h3>
          <p className="mt-2 text-sm text-zinc-300 leading-relaxed">
            {summary}
          </p>
        </div>

        {/* Highlights List */}
        {newFeatures && newFeatures.length > 0 && (
          <div className="pt-2 space-y-2 border-t border-brand-border/60">
            <div className="text-xs font-bold uppercase tracking-wider text-zinc-400">Key Highlights</div>
            <ul className="space-y-1.5 text-xs text-zinc-300">
              {newFeatures.slice(0, 3).map((feat, idx) => (
                <li key={idx} className="flex items-start gap-2">
                  <CheckCircle2 className="h-3.5 w-3.5 text-brand-green shrink-0 mt-0.5" />
                  <span className="line-clamp-1">{feat}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {/* Footer Link & APK CTA */}
      <div className="pt-6 mt-6 border-t border-brand-border/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <span className="text-xs text-zinc-500">
          {improvementsCount} improvements • {bugFixesCount} fixes
        </span>
        <div className="flex items-center gap-3">
          {downloadUrl && (
            <a
              href={downloadUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-lg transition-colors"
            >
              <Download className="h-3.5 w-3.5" />
              <span>APK {assetSize ? `(${assetSize})` : ""}</span>
            </a>
          )}
          <Link
            href={`/updates/${slug}`}
            className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-green group-hover:text-brand-green-hover transition-colors"
          >
            <span>Read Release Notes</span>
            <ArrowRight className="h-3.5 w-3.5 group-hover:translate-x-1 transition-transform" />
          </Link>
        </div>
      </div>
    </article>
  );
}
