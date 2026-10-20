import Link from "next/link";
import Image from "next/image";
import { ShieldCheck, Cloud, Smartphone, Heart, Sparkles, BookOpen } from "lucide-react";
import { siteConfig } from "@/lib/config/site";

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="border-t border-brand-border/60 bg-brand-bg text-zinc-400">
      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-16">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 lg:gap-12">
          {/* Brand info */}
          <div className="md:col-span-1 space-y-4">
            <Link href="/" className="flex items-center gap-2.5">
              <div className="relative h-9 w-9 overflow-hidden rounded-xl border border-brand-border bg-brand-surface">
                <Image
                  src="/fit_host_icon.png"
                  alt="Fit Host Logo"
                  width={36}
                  height={36}
                  className="object-cover"
                  unoptimized
                />
              </div>
              <span className="text-lg font-black tracking-tight text-white">
                FIT<span className="text-brand-green">HOST</span>
              </span>
            </Link>
            <p className="text-sm text-zinc-400 leading-relaxed">
              Premium fitness, hydration, and nutrition tracking built for high-performance athletes.
              Fast fitness tracking with secure cloud sync, powered by Flutter, Drift SQLite, and Supabase.
            </p>
            <div className="flex flex-wrap gap-2 pt-2 text-xs text-zinc-500">
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-brand-surface border border-brand-border text-zinc-400">
                <Smartphone className="h-3 w-3 text-brand-green" /> iOS & Android
              </span>
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-brand-surface border border-brand-border text-zinc-400">
                <Cloud className="h-3 w-3 text-brand-blue" /> Cloud Sync
              </span>
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-brand-surface border border-brand-border text-zinc-400">
                <ShieldCheck className="h-3 w-3 text-brand-green" /> Supabase RLS
              </span>
            </div>
          </div>

          {/* Product & App Info */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-zinc-200">Mobile Product</h3>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/features" className="hover:text-brand-green transition-colors">
                  Features & Capabilities
                </Link>
              </li>
              <li>
                <Link href="/how-it-works" className="hover:text-brand-green transition-colors">
                  How It Works (Tutorial)
                </Link>
              </li>
              <li>
                <Link href="/download" className="hover:text-brand-green transition-colors flex items-center gap-1.5">
                  <span>Download App</span>
                </Link>
              </li>
              <li>
                <Link href="/updates" className="hover:text-brand-green transition-colors flex items-center gap-1.5">
                  <Sparkles className="h-3 w-3 text-brand-green" />
                  <span>What&apos;s New (Releases)</span>
                </Link>
              </li>
              <li>
                <Link href="/guides" className="hover:text-brand-green transition-colors flex items-center gap-1.5">
                  <BookOpen className="h-3 w-3 text-brand-cyan" />
                  <span>Guides & Knowledge Base</span>
                </Link>
              </li>
            </ul>
          </div>

          {/* Education & Resources */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-zinc-200">Guides & Tutorials</h3>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/guides/getting-started" className="hover:text-brand-green transition-colors">
                  Getting Started Guide
                </Link>
              </li>
              <li>
                <Link href="/guides/guest-mode-vs-account" className="hover:text-brand-green transition-colors">
                  Guest Mode vs Account
                </Link>
              </li>
              <li>
                <Link href="/guides/logging-workouts" className="hover:text-brand-green transition-colors">
                  Logging Workout Sets
                </Link>
              </li>
              <li>
                <Link href="/guides/cloud-sync-architecture" className="hover:text-brand-green transition-colors">
                  Drift & Supabase Sync
                </Link>
              </li>
              <li>
                <Link href="/guides/troubleshooting-sync" className="hover:text-brand-green transition-colors">
                  Troubleshooting Sync
                </Link>
              </li>
            </ul>
          </div>

          {/* Trust & Transparency */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-zinc-200">Trust & Transparency</h3>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/about" className="hover:text-brand-green transition-colors">
                  About Fit Host
                </Link>
              </li>
              <li>
                <Link href="/support" className="hover:text-brand-green transition-colors">
                  Support & Help Center
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="hover:text-brand-green transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="hover:text-brand-green transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <span className="inline-block text-xs text-zinc-500 pt-2">
                  Official Origin: <br />
                  <code className="text-zinc-400 font-mono text-[11px]">https://{siteConfig.domain}</code>
                </span>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-12 border-t border-brand-border/60 pt-6 flex flex-col sm:flex-row items-center justify-between text-xs text-zinc-500 gap-4">
          <p>© {currentYear} Fit Host. All rights reserved.</p>
          <p className="flex items-center gap-1.5">
            Engineered with <Heart className="h-3 w-3 text-brand-green fill-brand-green" /> for athletes and wellness enthusiasts.
          </p>
        </div>
      </div>
    </footer>
  );
}
