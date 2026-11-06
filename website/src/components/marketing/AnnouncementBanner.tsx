import Link from "next/link";
import { Sparkles, ArrowRight } from "lucide-react";
import { getLatestMobileRelease } from "@/lib/github/releases";
import { getActiveAnnouncement } from "@/lib/content/public";

export default async function AnnouncementBanner() {
  const managed = await getActiveAnnouncement();
  const latest = await getLatestMobileRelease();
  if (managed) {
    return (
      <aside
        aria-label="Site announcement"
        className="relative border-b px-3.5 py-2 sm:px-4 sm:py-2.5 transition-colors"
        style={{ backgroundColor: managed.background_color, color: managed.text_color, borderColor: `${managed.accent_color}55` }}
      >
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 text-xs sm:text-sm">
          <div className="flex min-w-0 items-center gap-2 overflow-hidden">
            <span
              className="flex shrink-0 items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider"
              style={{ color: managed.accent_color, borderColor: `${managed.accent_color}55`, backgroundColor: `${managed.accent_color}1a` }}
            >
              <Sparkles className="h-3 w-3" />
              {managed.label}
            </span>
            <span className="truncate">
              <strong className="hidden sm:inline font-semibold">{managed.headline}</strong>
              <span className="sm:hidden">{managed.message}</span>
              <span className="hidden sm:inline"> — {managed.message}</span>
            </span>
          </div>
          <div className="flex shrink-0 items-center gap-2.5 sm:gap-3 text-xs">
            {managed.primary_label && managed.primary_url && (
              <a href={managed.primary_url} className="hidden font-bold sm:inline hover:underline" style={{ color: managed.accent_color }}>
                {managed.primary_label}
              </a>
            )}
            {managed.secondary_label && managed.secondary_url && (
              <a href={managed.secondary_url} className="font-bold inline-flex items-center gap-1 hover:underline" style={{ color: managed.accent_color }}>
                <span>{managed.secondary_label}</span>
                <ArrowRight className="h-3 w-3" />
              </a>
            )}
          </div>
        </div>
      </aside>
    );
  }
  if (!latest) return null;

  return (
    <aside
      aria-label="Release update banner"
      className="relative border-b border-brand-green/20 bg-brand-surface/90 px-3.5 py-2 sm:px-4 sm:py-2.5 backdrop-blur-md"
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between text-xs sm:text-sm">
        <div className="flex items-center gap-2 overflow-hidden min-w-0">
          <span className="flex items-center gap-1 font-bold text-brand-green uppercase tracking-wider text-[11px] bg-brand-green/10 px-2 py-0.5 rounded-full border border-brand-green/30 shrink-0">
            <Sparkles className="h-3 w-3" />
            {latest.version} Live
          </span>
          <span className="truncate text-zinc-300">
            <strong className="text-white hidden sm:inline">{latest.title}</strong>
            <span className="hidden sm:inline"> — </span>
            <span>Verified mobile build available.</span>
          </span>
        </div>
        <div className="flex items-center gap-2.5 sm:gap-3 shrink-0 ml-2">
          <Link
            href="/download"
            className="hidden md:inline-flex items-center gap-1 font-bold text-xs text-white hover:text-brand-green transition-colors"
          >
            <span>Download</span>
          </Link>
          <Link
            href={`/updates/${latest.slug}`}
            className="inline-flex items-center gap-1 font-bold text-brand-green hover:text-brand-green-hover text-xs"
          >
            <span>Notes</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>
      </div>
    </aside>
  );
}
