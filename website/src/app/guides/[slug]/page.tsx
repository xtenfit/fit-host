import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import {
  ArrowLeft,
  Clock,
  Calendar,
  CheckCircle2,
  Lightbulb,
  ArrowRight,
  BookOpen,
} from "lucide-react";
import PhoneMockup from "@/components/marketing/PhoneMockup";
import GuideCard from "@/components/marketing/GuideCard";
import DownloadCTA from "@/components/marketing/DownloadCTA";
import { getAllGuides, getGuideBySlug } from "@/lib/data/guides";

interface GuidePageProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  const guides = getAllGuides();
  return guides.map((g) => ({ slug: g.slug }));
}

export async function generateMetadata({ params }: GuidePageProps): Promise<Metadata> {
  const { slug } = await params;
  const guide = getGuideBySlug(slug);
  if (!guide) return { title: "Guide Not Found" };

  return {
    title: `${guide.title} | Fit Host Guides`,
    description: guide.summary,
  };
}

export default async function GuideDetailPage({ params }: GuidePageProps) {
  const { slug } = await params;
  const guide = getGuideBySlug(slug);

  if (!guide) {
    notFound();
  }

  const relatedGuides = guide.relatedGuideSlugs
    .map((s) => getGuideBySlug(s))
    .filter((g): g is NonNullable<typeof g> => g !== undefined);

  return (
    <div className="relative overflow-hidden py-12 md:py-20">
      {/* Background radial glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 blur-[140px] rounded-full" />

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        {/* Back Link */}
        <Link
          href="/guides"
          className="inline-flex items-center gap-2 text-xs font-bold text-zinc-400 hover:text-brand-green transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to All Guides</span>
        </Link>

        {/* Guide Header */}
        <div className="space-y-4 border-b border-brand-border/60 pb-8">
          <div className="flex flex-wrap items-center justify-between gap-3 text-xs">
            <span className="font-semibold px-3 py-1 rounded-md bg-brand-elevated text-brand-green border border-brand-green/30">
              {guide.category}
            </span>
            <div className="flex items-center gap-4 text-zinc-400">
              <span className="flex items-center gap-1.5">
                <Clock className="h-3.5 w-3.5 text-zinc-500" />
                {guide.readTime}
              </span>
              <span className="flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5 text-zinc-500" />
                Updated {guide.updatedDate}
              </span>
            </div>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight">
            {guide.title}
          </h1>

          <p className="text-base sm:text-lg text-zinc-300 leading-relaxed">
            {guide.summary}
          </p>
        </div>

        {/* Optional Screenshot Showcase */}
        {guide.screenshot && (
          <div className="flex justify-center py-4">
            <PhoneMockup
              src={guide.screenshot}
              alt={`${guide.title} preview`}
              glowColor="green"
              caption={`Mobile interface reference for ${guide.title}`}
            />
          </div>
        )}

        {/* Key Takeaways Box */}
        <div className="rounded-2xl border border-brand-green/30 bg-brand-green/5 p-6 sm:p-8 space-y-3">
          <h2 className="text-sm font-bold uppercase tracking-wider text-brand-green">
            Key Takeaways
          </h2>
          <ul className="space-y-2 text-sm text-zinc-200">
            {guide.keyTakeaways.map((item, idx) => (
              <li key={idx} className="flex items-start gap-2.5">
                <CheckCircle2 className="h-4 w-4 text-brand-green shrink-0 mt-0.5" />
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Step-by-Step Instructions */}
        <div className="space-y-8">
          <h2 className="text-2xl font-bold text-white border-b border-brand-border/60 pb-3">
            Step-by-Step Instructions
          </h2>

          <div className="space-y-6">
            {guide.steps.map((step) => (
              <div
                key={step.stepNumber}
                className="rounded-2xl border border-brand-border bg-brand-surface p-6 sm:p-8 space-y-3"
              >
                <div className="flex items-center gap-3">
                  <span className="font-mono text-lg font-black text-brand-green bg-brand-green/10 px-2.5 py-0.5 rounded-lg border border-brand-green/30">
                    {String(step.stepNumber).padStart(2, "0")}
                  </span>
                  <h3 className="text-lg sm:text-xl font-bold text-white">
                    {step.title}
                  </h3>
                </div>

                <p className="text-sm sm:text-base text-zinc-300 leading-relaxed pl-1">
                  {step.description}
                </p>

                {step.tip && (
                  <div className="mt-3 flex items-start gap-2.5 rounded-xl bg-brand-elevated/70 border border-brand-border p-3.5 text-xs text-zinc-400">
                    <Lightbulb className="h-4 w-4 text-brand-green shrink-0 mt-0.5" />
                    <span>
                      <strong className="text-zinc-200">Pro Tip: </strong>
                      {step.tip}
                    </span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Related Guides */}
        {relatedGuides.length > 0 && (
          <div className="space-y-6 pt-6 border-t border-brand-border/60">
            <h2 className="text-xl font-bold text-white">Related Guides</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {relatedGuides.map((rel) => (
                <GuideCard key={rel.slug} guide={rel} />
              ))}
            </div>
          </div>
        )}

        {/* CTA */}
        <DownloadCTA variant="banner" />
      </div>
    </div>
  );
}
