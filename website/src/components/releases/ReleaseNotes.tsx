import React from "react";
import { Sparkles, Wrench, Bug, ShieldCheck, AlertTriangle, Info } from "lucide-react";
import type { StructuredReleaseNotes } from "@/lib/github/releases";

interface ReleaseNotesProps {
  notes: StructuredReleaseNotes;
  className?: string;
}

export default function ReleaseNotes({ notes, className = "" }: ReleaseNotesProps) {
  const { whatsNew, improvements, bugFixes, securityFixes, knownIssues, raw, hasStructuredSections } = notes;

  return (
    <div className={`space-y-6 ${className}`}>
      {/* What's New */}
      {whatsNew.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-brand-green">
            <Sparkles className="h-4 w-4 text-brand-green" />
            <h3>What&apos;s New & Features</h3>
          </div>
          <div className="rounded-2xl border border-brand-border bg-brand-surface/70 p-5 sm:p-6 backdrop-blur-sm">
            <ul className="space-y-2.5 text-sm sm:text-base text-zinc-200">
              {whatsNew.map((item, idx) => (
                <li key={idx} className="flex items-start gap-2.5">
                  <span className="h-1.5 w-1.5 rounded-full bg-brand-green mt-2 shrink-0" />
                  <span className="leading-relaxed">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      )}

      {/* Improvements */}
      {improvements.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-brand-blue">
            <Wrench className="h-4 w-4 text-brand-blue" />
            <h3>Improvements & Optimizations</h3>
          </div>
          <div className="rounded-2xl border border-brand-border bg-brand-surface/70 p-5 sm:p-6 backdrop-blur-sm">
            <ul className="space-y-2.5 text-sm sm:text-base text-zinc-200">
              {improvements.map((item, idx) => (
                <li key={idx} className="flex items-start gap-2.5">
                  <span className="h-1.5 w-1.5 rounded-full bg-brand-blue mt-2 shrink-0" />
                  <span className="leading-relaxed">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      )}

      {/* Bug Fixes */}
      {bugFixes.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-amber-400">
            <Bug className="h-4 w-4 text-amber-400" />
            <h3>Resolved Issues & Bug Fixes</h3>
          </div>
          <div className="rounded-2xl border border-brand-border bg-brand-surface/70 p-5 sm:p-6 backdrop-blur-sm">
            <ul className="space-y-2.5 text-sm sm:text-base text-zinc-200">
              {bugFixes.map((item, idx) => (
                <li key={idx} className="flex items-start gap-2.5">
                  <span className="h-1.5 w-1.5 rounded-full bg-amber-400 mt-2 shrink-0" />
                  <span className="leading-relaxed">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      )}

      {/* Security Fixes */}
      {securityFixes.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-emerald-400">
            <ShieldCheck className="h-4 w-4 text-emerald-400" />
            <h3>Security Fixes</h3>
          </div>
          <div className="rounded-2xl border border-emerald-950/60 bg-emerald-950/20 p-5 sm:p-6 backdrop-blur-sm">
            <ul className="space-y-2.5 text-sm sm:text-base text-emerald-100">
              {securityFixes.map((item, idx) => (
                <li key={idx} className="flex items-start gap-2.5">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 mt-2 shrink-0" />
                  <span className="leading-relaxed">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      )}

      {/* Known Issues */}
      {knownIssues.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-zinc-400">
            <AlertTriangle className="h-4 w-4 text-zinc-400" />
            <h3>Known Issues & Workarounds</h3>
          </div>
          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-5 text-xs sm:text-sm text-zinc-400 space-y-2">
            {knownIssues.map((item, idx) => (
              <p key={idx} className="leading-relaxed">
                • {item}
              </p>
            ))}
          </div>
        </section>
      )}

      {/* Unstructured Fallback (Safe sanitized rendering) */}
      {!hasStructuredSections && raw && (
        <div className="rounded-2xl border border-brand-border bg-brand-surface p-6 text-sm text-zinc-300 whitespace-pre-wrap leading-relaxed">
          {raw}
        </div>
      )}
    </div>
  );
}
