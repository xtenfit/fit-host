"use client";

import { useEffect, useState } from "react";
import {
  Shield,
  Megaphone,
  Mail,
  Newspaper,
  Send,
  Radio,
  Layers,
  ArrowRight,
  Database,
  CheckCircle2,
  Clock,
  Sparkles,
} from "lucide-react";
import { INITIAL_50_EMAIL_TEMPLATES } from "@/lib/email/templates";

interface AdminHubOverviewProps {
  onSelectTab: (tab: "content" | "email") => void;
}

export default function AdminHubOverview({ onSelectTab }: AdminHubOverviewProps) {
  const [bannerCount, setBannerCount] = useState<number>(0);
  const [updateCount, setUpdateCount] = useState<number>(0);
  const [activeBanners, setActiveBanners] = useState<number>(0);
  const [emailStatus, setEmailStatus] = useState<string>("checking");
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    async function loadStats() {
      try {
        const [contentRes, statusRes] = await Promise.allSettled([
          fetch("/api/admin/content"),
          fetch("/api/admin/email/provider-status"),
        ]);

        if (contentRes.status === "fulfilled" && contentRes.value.ok) {
          const contentData = await contentRes.value.json();
          const announcements = contentData.announcements || [];
          const updates = contentData.updates || [];
          setBannerCount(announcements.length);
          setUpdateCount(updates.length);
          setActiveBanners(
            announcements.filter((a: { status: string }) => a.status === "published").length
          );
        }

        if (statusRes.status === "fulfilled" && statusRes.value.ok) {
          const statusData = await statusRes.value.json();
          setEmailStatus(statusData.status === "active" ? "active" : "configured");
        }
      } catch (err) {
        console.error("Failed to load admin overview metrics", err);
      } finally {
        setLoading(false);
      }
    }

    loadStats();
  }, []);

  return (
    <div className="space-y-8 text-white">
      {/* Top Banner / Welcome Hero */}
      <div className="relative overflow-hidden rounded-3xl border border-brand-border bg-gradient-to-br from-brand-surface via-black to-brand-surface p-6 sm:p-8">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2 max-w-2xl">
            <div className="flex items-center gap-2">
              <span className="flex h-2 w-2 rounded-full bg-brand-green animate-pulse" />
              <span className="text-xs font-bold uppercase tracking-wider text-brand-green">
                Unified Admin Hub &amp; Control Center
              </span>
              <span className="rounded-full bg-white/5 border border-white/10 px-2.5 py-0.5 text-[10px] font-bold text-zinc-400">
                Superadmin
              </span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Fit Host Management Portal
            </h1>
            <p className="text-sm text-zinc-400 leading-relaxed">
              Consolidated control center combining the Website CMS (promotions, announcement banners, product updates) and Email Studio (50 templates, workflows, live test dispatch, and deliverability monitoring).
            </p>
          </div>

          <div className="flex flex-wrap md:flex-col gap-2.5 shrink-0">
            <button
              onClick={() => onSelectTab("content")}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-brand-green px-4 py-2.5 text-xs font-bold text-black hover:opacity-90 transition-opacity"
            >
              <Megaphone className="h-3.5 w-3.5" />
              Manage Content CMS
            </button>
            <button
              onClick={() => onSelectTab("email")}
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-brand-border bg-brand-surface px-4 py-2.5 text-xs font-bold text-white hover:border-zinc-700 transition-colors"
            >
              <Mail className="h-3.5 w-3.5" />
              Open Email Studio
            </button>
          </div>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl bg-brand-surface border border-brand-border space-y-1">
          <div className="flex items-center justify-between text-zinc-400 text-xs">
            <span>Active Banners</span>
            <Megaphone className="h-4 w-4 text-brand-green" />
          </div>
          <p className="text-2xl sm:text-3xl font-black text-white">
            {loading ? "..." : activeBanners}
          </p>
          <p className="text-[11px] text-zinc-500">
            {bannerCount} total promotion banners
          </p>
        </div>

        <div className="p-5 rounded-2xl bg-brand-surface border border-brand-border space-y-1">
          <div className="flex items-center justify-between text-zinc-400 text-xs">
            <span>Product Updates</span>
            <Newspaper className="h-4 w-4 text-brand-blue" />
          </div>
          <p className="text-2xl sm:text-3xl font-black text-white">
            {loading ? "..." : updateCount}
          </p>
          <p className="text-[11px] text-zinc-500">
            Live changelog entries
          </p>
        </div>

        <div className="p-5 rounded-2xl bg-brand-surface border border-brand-border space-y-1">
          <div className="flex items-center justify-between text-zinc-400 text-xs">
            <span>Email Templates</span>
            <Layers className="h-4 w-4 text-brand-green" />
          </div>
          <p className="text-2xl sm:text-3xl font-black text-white">
            {INITIAL_50_EMAIL_TEMPLATES.length}
          </p>
          <p className="text-[11px] text-zinc-500">
            Across 10 distinct categories
          </p>
        </div>

        <div className="p-5 rounded-2xl bg-brand-surface border border-brand-border space-y-1">
          <div className="flex items-center justify-between text-zinc-400 text-xs">
            <span>Email Provider</span>
            <Radio className="h-4 w-4 text-brand-green" />
          </div>
          <p className="text-2xl sm:text-3xl font-black text-brand-green">
            Resend
          </p>
          <p className="text-[11px] text-zinc-500">
            noreply.amitrana.tech
          </p>
        </div>
      </div>

      {/* Two Pillars Section: CMS vs Email Studio */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Content CMS Pillar */}
        <div className="rounded-3xl border border-brand-border bg-brand-surface/60 p-6 sm:p-7 space-y-5">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-green/10 text-brand-green border border-brand-green/20">
                <Megaphone className="h-5 w-5" />
              </span>
              <div>
                <h3 className="text-lg font-black text-white">Website Content CMS</h3>
                <p className="text-xs text-zinc-400">Announcement bars, top banners, and release notes</p>
              </div>
            </div>
          </div>

          <p className="text-xs text-zinc-300 leading-relaxed">
            Manage real-time banners and announcements shown to website visitors. Schedule campaigns, customize button calls-to-action, configure hex colors, and publish version updates.
          </p>

          <div className="space-y-2 pt-2 border-t border-brand-border/60">
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                Live Banner Preview Engine
              </span>
              <span className="text-zinc-500 font-mono">Active</span>
            </div>
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                Scheduled Start/End Dates
              </span>
              <span className="text-zinc-500 font-mono">Active</span>
            </div>
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                GitHub Release Fallback
              </span>
              <span className="text-zinc-500 font-mono">Active</span>
            </div>
          </div>

          <button
            onClick={() => onSelectTab("content")}
            className="w-full inline-flex items-center justify-center gap-2 rounded-xl border border-brand-border bg-black/40 hover:bg-brand-green hover:text-black hover:border-brand-green p-3 text-xs font-bold text-white transition-all group"
          >
            Launch Content CMS Editor
            <ArrowRight className="h-3.5 w-3.5 group-hover:translate-x-1 transition-transform" />
          </button>
        </div>

        {/* Email Studio Pillar */}
        <div className="rounded-3xl border border-brand-border bg-brand-surface/60 p-6 sm:p-7 space-y-5">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-blue/10 text-brand-blue border border-brand-blue/20">
                <Mail className="h-5 w-5" />
              </span>
              <div>
                <h3 className="text-lg font-black text-white">Email Studio</h3>
                <p className="text-xs text-zinc-400">Templates, workflows, test dispatch, and logs</p>
              </div>
            </div>
          </div>

          <p className="text-xs text-zinc-300 leading-relaxed">
            Full-featured email platform with 50 pre-built HTML &amp; text templates, live responsive device preview, test email dispatching via Resend, automated triggers, delivery logs, and suppression list management.
          </p>

          <div className="space-y-2 pt-2 border-t border-brand-border/60">
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                50 Production Templates Ready
              </span>
              <span className="text-zinc-500 font-mono">Loaded</span>
            </div>
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                Live Responsive HTML/Text Previews
              </span>
              <span className="text-zinc-500 font-mono">Dark &amp; Light</span>
            </div>
            <div className="flex items-center justify-between text-xs py-1.5 text-zinc-400">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
                Instant Test Email Dispatcher
              </span>
              <span className="text-zinc-500 font-mono">Resend SDK</span>
            </div>
          </div>

          <button
            onClick={() => onSelectTab("email")}
            className="w-full inline-flex items-center justify-center gap-2 rounded-xl border border-brand-border bg-black/40 hover:bg-brand-green hover:text-black hover:border-brand-green p-3 text-xs font-bold text-white transition-all group"
          >
            Launch Email Studio Platform
            <ArrowRight className="h-3.5 w-3.5 group-hover:translate-x-1 transition-transform" />
          </button>
        </div>
      </div>

      {/* System & Infrastructure Status */}
      <div className="rounded-3xl border border-brand-border bg-brand-surface p-6 sm:p-7 space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Database className="h-4 w-4 text-brand-green" />
            <h3 className="text-sm font-bold text-white uppercase tracking-wider">
              Infrastructure &amp; Security Health
            </h3>
          </div>
          <span className="inline-flex items-center gap-1.5 text-xs text-brand-green font-semibold">
            <span className="h-2 w-2 rounded-full bg-brand-green" />
            All Systems Operational
          </span>
        </div>

        <div className="grid sm:grid-cols-3 gap-4 pt-2">
          <div className="p-4 rounded-xl bg-black/40 border border-brand-border/60 space-y-1">
            <span className="text-[11px] text-zinc-400 font-medium">Supabase Database</span>
            <p className="text-sm font-bold text-white">PostgreSQL Connected</p>
            <p className="text-[10px] text-zinc-500">site_announcements, site_updates RLS</p>
          </div>
          <div className="p-4 rounded-xl bg-black/40 border border-brand-border/60 space-y-1">
            <span className="text-[11px] text-zinc-400 font-medium">Email Sending Engine</span>
            <p className="text-sm font-bold text-white">Resend API v6</p>
            <p className="text-[10px] text-zinc-500">DKIM / SPF: noreply.amitrana.tech</p>
          </div>
          <div className="p-4 rounded-xl bg-black/40 border border-brand-border/60 space-y-1">
            <span className="text-[11px] text-zinc-400 font-medium">Access Protection</span>
            <p className="text-sm font-bold text-white">Stealth Isolation</p>
            <p className="text-[10px] text-zinc-500">Strict 404 for unauthorized visitors</p>
          </div>
        </div>
      </div>
    </div>
  );
}
