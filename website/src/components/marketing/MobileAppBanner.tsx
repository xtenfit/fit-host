"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { Download, X, Star } from "lucide-react";
import { siteConfig } from "@/lib/config/site";

const STORAGE_KEY = "fithost_mobile_banner_dismissed_until";
const DISMISS_DAYS = 7;

export default function MobileAppBanner() {
  const [isVisible, setIsVisible] = useState(false);
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    try {
      const dismissedUntil = localStorage.getItem(STORAGE_KEY);
      if (dismissedUntil) {
        const time = parseInt(dismissedUntil, 10);
        if (Date.now() < time) {
          return;
        }
      }
      setIsVisible(true);
    } catch {
      setIsVisible(true);
    }
  }, []);

  const handleDismiss = () => {
    setIsVisible(false);
    try {
      const until = Date.now() + DISMISS_DAYS * 24 * 60 * 60 * 1000;
      localStorage.setItem(STORAGE_KEY, until.toString());
    } catch {
      // Ignore storage errors in private browsing
    }
  };

  if (!isMounted || !isVisible) {
    return null;
  }

  const { storeLinks, version } = siteConfig;
  const directApkUrl = storeLinks.directApk.available ? storeLinks.directApk.url : null;
  const actionHref = directApkUrl || "/download";

  return (
    <aside
      aria-label="Fit Host Mobile App Download Banner"
      className="fixed bottom-3 inset-x-3 z-50 sm:hidden animate-in fade-in slide-in-from-bottom-3 duration-300 pointer-events-auto"
    >
      <div className="relative flex items-center justify-between gap-3 p-3 rounded-2xl bg-[#14181F]/95 backdrop-blur-xl border border-brand-green/30 shadow-[0_12px_40px_rgba(0,0,0,0.65),0_0_24px_rgba(57,255,136,0.12)]">
        {/* App Icon + App Info */}
        <Link
          href="/download"
          className="flex items-center gap-3 min-w-0 flex-1 group focus:outline-none"
        >
          <div className="relative h-11 w-11 shrink-0 overflow-hidden rounded-xl border border-white/10 bg-black/40 shadow-inner">
            <Image
              src="/fit_host_icon.png"
              alt="Fit Host App Icon"
              width={44}
              height={44}
              className="object-cover"
              priority
              unoptimized
            />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <span className="text-sm font-black text-white tracking-tight truncate">
                Fit Host
              </span>
              <span className="text-[10px] font-mono font-bold text-brand-green bg-brand-green/10 border border-brand-green/30 px-1.5 py-0.2 rounded">
                {version}
              </span>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-zinc-300">
              <div className="flex text-amber-400">
                <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
              </div>
              <span className="font-semibold text-white">Fast & Local-first</span>
              <span className="text-zinc-500">•</span>
              <span className="text-zinc-400 truncate">No ads</span>
            </div>
          </div>
        </Link>

        {/* Action Button & Dismiss */}
        <div className="flex items-center gap-1.5 shrink-0">
          <Link
            href={actionHref}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-md shadow-brand-green/20 active:scale-95 transition-all"
          >
            <Download className="h-3.5 w-3.5" />
            <span>Install</span>
          </Link>
          <button
            type="button"
            onClick={handleDismiss}
            aria-label="Dismiss mobile download banner"
            className="p-1.5 text-zinc-400 hover:text-white rounded-lg hover:bg-white/5 active:scale-90 transition-colors"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}

