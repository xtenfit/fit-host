import Link from "next/link";
import { Sparkles, ArrowRight } from "lucide-react";
import { getLatestMobileRelease } from "@/lib/github/releases";

export default async function AnnouncementBanner() {
  const latest = await getLatestMobileRelease();
  if (!latest) return null;

  return (
    <div className="relative border-b border-brand-green/20 bg-brand-surface/90 px-4 py-2.5 backdrop-blur-md">
      <div className="mx-auto flex max-w-7xl items-center justify-between text-xs sm:text-sm">
        <div className="flex items-center gap-2 overflow-hidden">
          <span className="flex items-center gap-1 font-bold text-brand-green uppercase tracking-wider text-[11px] bg-brand-green/10 px-2 py-0.5 rounded-full border border-brand-green/30 shrink-0">
            <Sparkles className="h-3 w-3" />
            {latest.version} Released
          </span>
          <span className="truncate text-zinc-300">
            <strong className="text-white hidden sm:inline">{latest.title}</strong> — Production build is available for download.
          </span>
        </div>
        <div className="flex items-center gap-3 shrink-0 ml-3">
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
            <span>Release Notes</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>
      </div>
    </div>
  );
}
