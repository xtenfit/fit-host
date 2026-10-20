import Link from "next/link";
import { BookOpen, Clock, ArrowRight, CheckCircle2 } from "lucide-react";
import type { GuideArticle } from "@/lib/data/guides";

interface GuideCardProps {
  guide: GuideArticle;
}

export default function GuideCard({ guide }: GuideCardProps) {
  return (
    <article className="group relative rounded-2xl border border-brand-border bg-brand-surface p-6 hover:border-brand-green/40 transition-all shadow-lg hover:shadow-brand-green/5 flex flex-col justify-between">
      <div className="space-y-3">
        {/* Category & Read Time */}
        <div className="flex items-center justify-between text-xs">
          <span className="font-semibold px-2.5 py-0.5 rounded-md bg-brand-elevated text-brand-green border border-brand-green/20">
            {guide.category}
          </span>
          <span className="flex items-center gap-1 text-zinc-400">
            <Clock className="h-3 w-3 text-zinc-500" />
            {guide.readTime}
          </span>
        </div>

        {/* Title & Summary */}
        <div>
          <h3 className="text-lg font-bold text-white group-hover:text-brand-green transition-colors leading-snug">
            <Link href={`/guides/${guide.slug}`}>
              {guide.title}
            </Link>
          </h3>
          <p className="mt-2 text-xs sm:text-sm text-zinc-400 leading-relaxed line-clamp-2">
            {guide.summary}
          </p>
        </div>

        {/* Key Takeaways */}
        <div className="pt-2 space-y-1 border-t border-brand-border/60">
          <div className="text-[11px] font-bold uppercase tracking-wider text-zinc-500">Takeaway</div>
          <p className="text-xs text-zinc-300 flex items-start gap-1.5">
            <CheckCircle2 className="h-3.5 w-3.5 text-brand-green shrink-0 mt-0.5" />
            <span className="line-clamp-1">{guide.keyTakeaways[0]}</span>
          </p>
        </div>
      </div>

      {/* Read Guide Link */}
      <div className="pt-4 mt-4 border-t border-brand-border/60 flex items-center justify-between">
        <span className="text-[11px] text-zinc-500">{guide.steps.length} practical steps</span>
        <Link
          href={`/guides/${guide.slug}`}
          className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-green group-hover:text-brand-green-hover transition-colors"
        >
          <span>Read Guide</span>
          <ArrowRight className="h-3.5 w-3.5 group-hover:translate-x-1 transition-transform" />
        </Link>
      </div>
    </article>
  );
}
