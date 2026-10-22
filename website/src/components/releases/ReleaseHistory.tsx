import React from "react";
import Link from "next/link";
import { Calendar, ArrowRight, Download, ExternalLink, Sparkles, CheckCircle2, Clock } from "lucide-react";
import type { MobileRelease } from "@/lib/github/releases";
import VersionBadge from "./VersionBadge";
import ReleaseStatusBadge from "./ReleaseStatus";

interface ReleaseHistoryProps {
  releases: MobileRelease[];
  className?: string;
}

export default function ReleaseHistory({ releases, className = "" }: ReleaseHistoryProps) {
  if (!releases || releases.length === 0) {
    return (
      <div className={`p-8 rounded-2xl border border-brand-border bg-brand-surface text-center text-sm text-zinc-400 ${className}`}>
        No published releases recorded yet.
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {releases.map((rel, idx) => {
        const isLatest = idx === 0;
        const hasApk = Boolean(rel.android.downloadUrl && rel.android.distributionStatus === "available");

        return (
          <article
            key={rel.id}
            className={`relative rounded-3xl border ${
              isLatest
                ? "border-brand-green/40 bg-gradient-to-b from-brand-surface via-brand-surface to-brand-elevated"
                : "border-brand-border bg-brand-surface"
            } p-6 sm:p-8 hover:border-brand-green/30 transition-all shadow-xl`}
          >
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-brand-border/60 pb-5">
              <div className="flex flex-wrap items-center gap-2.5">
                <VersionBadge
                  version={rel.version}
                  isLatest={isLatest}
                  isPrerelease={rel.isPrerelease}
                  isFallback={rel.isFallback}
                />
                <div className="flex items-center gap-1.5 text-xs text-zinc-400">
                  <Calendar className="h-3.5 w-3.5 text-zinc-500" />
                  <time dateTime={rel.publishedAt}>{rel.displayDate}</time>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <ReleaseStatusBadge status={rel.android.distributionStatus} platform="android" />
              </div>
            </div>

            {/* Content */}
            <div className="pt-5 space-y-4">
              <h3 className="text-xl sm:text-2xl font-black text-white tracking-tight">
                <Link
                  href={`/updates/${rel.slug}`}
                  className="hover:text-brand-green transition-colors"
                >
                  {rel.title}
                </Link>
              </h3>

              <p className="text-sm sm:text-base text-zinc-300 leading-relaxed">
                {rel.notes.summary}
              </p>

              {/* Highlights Preview */}
              {rel.notes.whatsNew.length > 0 && (
                <div className="rounded-xl border border-brand-border/60 bg-black/30 p-4">
                  <div className="text-xs font-bold uppercase tracking-wider text-brand-green flex items-center gap-1.5 mb-2">
                    <Sparkles className="h-3.5 w-3.5" />
                    <span>Key Updates</span>
                  </div>
                  <ul className="space-y-1.5 text-xs sm:text-sm text-zinc-300">
                    {rel.notes.whatsNew.slice(0, 3).map((feat, i) => (
                      <li key={i} className="flex items-start gap-2">
                        <CheckCircle2 className="h-3.5 w-3.5 text-brand-green shrink-0 mt-0.5" />
                        <span className="line-clamp-1">{feat}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Actions Footer */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-3 border-t border-brand-border/40 text-xs">
                <div className="flex items-center gap-4">
                  <Link
                    href={`/updates/${rel.slug}`}
                    className="inline-flex items-center gap-1 font-bold text-brand-green hover:text-brand-green-hover transition-colors"
                  >
                    <span>Read Full Release Notes</span>
                    <ArrowRight className="h-3 w-3" />
                  </Link>

                  {rel.htmlUrl && (
                    <a
                      href={rel.htmlUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-zinc-400 hover:text-white transition-colors"
                    >
                      <span>GitHub Release</span>
                      <ExternalLink className="h-3 w-3" />
                    </a>
                  )}
                </div>

                {hasApk ? (
                  <a
                    href={rel.android.downloadUrl!}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 text-xs font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-md shadow-brand-green/20 transition-all hover:scale-[1.02] self-start sm:self-auto"
                  >
                    <Download className="h-3.5 w-3.5" />
                    <span>Download APK {rel.android.assetSize ? `(${rel.android.assetSize})` : ""}</span>
                  </a>
                ) : (
                  <div className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-brand-green bg-brand-green/10 rounded-xl border border-brand-green/30 self-start sm:self-auto select-none">
                    <Clock className="h-3.5 w-3.5 text-brand-green" />
                    <span>APK: Release Soon</span>
                  </div>
                )}
              </div>
            </div>
          </article>
        );
      })}
    </div>
  );
}
