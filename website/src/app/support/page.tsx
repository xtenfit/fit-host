"use client";

import { useState } from "react";
import Link from "next/link";
import {
  Mail,
  KeyRound,
  CloudOff,
  UserCheck,
  Send,
  CheckCircle2,
  AlertCircle,
  ShieldCheck,
  MessageSquare,
  ArrowRight,
  BookOpen,
  HelpCircle,
} from "lucide-react";
import { siteConfig } from "@/lib/config/site";

function GithubIcon({ className = "h-5 w-5" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
      />
    </svg>
  );
}

const troubleshootingGuides = [
  {
    icon: KeyRound,
    title: "Email OTP & Password Recovery",
    desc: "When logging in or recovering your password, Supabase dispatches a 6-digit numeric verification token. Check your Spam folder if it does not arrive within 60 seconds.",
    link: "/guides/account-recovery",
  },
  {
    icon: UserCheck,
    title: "Google Sign-In & Mobile Callback",
    desc: "Google OAuth uses secure redirect callbacks. On mobile devices, authentication redirects back into Fit Host via the registered scheme (io.supabase.fithost://login-callback).",
    link: "/guides/getting-started",
  },
  {
    icon: CloudOff,
    title: "Offline Storage & Sync Troubleshooting",
    desc: "Workouts logged in airplane mode or basement gyms remain safely preserved in local SQLite storage. When Wi-Fi restores, swipe down on the home screen to trigger a manual sync.",
    link: "/guides/troubleshooting-sync",
  },
  {
    icon: ShieldCheck,
    title: "Migrating from Guest Mode",
    desc: "If you started as a guest, your records are safely kept in your local Drift database. When you register an account, your historical records automatically migrate to your cloud profile.",
    link: "/guides/guest-mode-vs-account",
  },
];

export default function SupportPage() {
  const [copied, setCopied] = useState(false);

  const handleCopyEmail = () => {
    navigator.clipboard.writeText(siteConfig.support.email);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-16">
      {/* Header */}
      <div className="text-center max-w-3xl mx-auto space-y-4">
        <span className="text-xs font-bold uppercase tracking-widest text-brand-green">
          Help & Support Center
        </span>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
          How Can We Help You?
        </h1>
        <p className="text-base sm:text-lg text-zinc-300 leading-relaxed">
          Find solutions for mobile authentication, offline synchronization, account recovery, and technical troubleshooting.
        </p>
      </div>

      {/* Troubleshooting Guides */}
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <BookOpen className="h-5 w-5 text-brand-green" />
            <span>Common Diagnostic Topics</span>
          </h2>
          <Link
            href="/guides"
            className="text-xs font-bold text-brand-green hover:text-brand-green-hover flex items-center gap-1"
          >
            <span>All Guides</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {troubleshootingGuides.map((g, idx) => {
            const Icon = g.icon;
            return (
              <div
                key={idx}
                className="rounded-2xl border border-brand-border bg-brand-surface p-6 space-y-3 hover:border-brand-green/30 transition-colors flex flex-col justify-between"
              >
                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-xl bg-brand-elevated border border-brand-border flex items-center justify-center text-brand-green">
                      <Icon className="h-5 w-5" />
                    </div>
                    <h3 className="text-base font-bold text-white">{g.title}</h3>
                  </div>
                  <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
                    {g.desc}
                  </p>
                </div>
                <div className="pt-3 border-t border-brand-border/60">
                  <Link
                    href={g.link}
                    className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-green hover:text-brand-green-hover"
                  >
                    <span>Read Step-by-Step Guide</span>
                    <ArrowRight className="h-3 w-3" />
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Contact Channels */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Email Support Box */}
        <div className="rounded-3xl border border-brand-border bg-brand-surface p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-brand-green/10 text-brand-green border border-brand-green/20">
              <Mail className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">Direct Email Support</h2>
              <p className="text-xs text-zinc-400">Response within 24-48 business hours</p>
            </div>
          </div>

          <p className="text-sm text-zinc-300 leading-relaxed">
            Need direct help with an account sync issue, bug report, or feature inquiry? Reach out to our engineering support desk directly.
          </p>

          <div className="p-4 rounded-xl bg-brand-elevated border border-brand-border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
            <div className="font-mono text-sm text-brand-green font-semibold break-all">
              {siteConfig.support.email}
            </div>
            <div className="flex items-center gap-2 w-full sm:w-auto">
              <button
                type="button"
                onClick={handleCopyEmail}
                className="w-full sm:w-auto px-4 py-2 rounded-lg bg-brand-surface hover:bg-zinc-800 border border-brand-border text-xs text-zinc-200 font-semibold transition-colors"
              >
                {copied ? "Copied!" : "Copy Email"}
              </button>
              <a
                href={`mailto:${siteConfig.support.email}?subject=Fit%20Host%20Support%20Inquiry`}
                className="w-full sm:w-auto px-4 py-2 rounded-lg bg-brand-green hover:bg-brand-green-hover text-xs text-black font-bold text-center transition-colors"
              >
                Send Email
              </a>
            </div>
          </div>
        </div>

        {/* GitHub & Bug Reports */}
        <div className="rounded-3xl border border-brand-border bg-brand-surface p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-brand-blue/20 text-brand-cyan border border-brand-blue/30">
              <GithubIcon className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">GitHub Issue Tracker</h2>
              <p className="text-xs text-zinc-400">Technical bug reports and feature requests</p>
            </div>
          </div>

          <p className="text-sm text-zinc-300 leading-relaxed">
            Found a bug in the Android or iOS mobile build? Submit reproducible logs or feedback directly on our open issue repository.
          </p>

          <div className="pt-2">
            <a
              href={siteConfig.support.githubUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-brand-elevated hover:bg-brand-elevated/80 border border-brand-border hover:border-brand-green/40 text-sm font-bold text-white transition-all"
            >
              <GithubIcon className="h-4 w-4" />
              <span>Open GitHub Repository</span>
              <ArrowRight className="h-4 w-4 text-zinc-400" />
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
