"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter, usePathname } from "next/navigation";
import { Menu, X, ArrowRight, LayoutDashboard, LogOut } from "lucide-react";
import type { User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";

interface NavItem {
  label: string;
  href: string;
}

const navItems: NavItem[] = [
  { label: "Features", href: "/features" },
  { label: "Download", href: "/download" },
  { label: "How It Works", href: "/how-it-works" },
  { label: "What's New", href: "/updates" },
  { label: "Guides", href: "/guides" },
  { label: "About", href: "/about" },
  { label: "Support", href: "/support" },
];

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();
  const supabase = createClient();

  useEffect(() => {
    async function checkAuth() {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        setUser(session?.user ?? null);
      } catch {
        setUser(null);
      } finally {
        setLoading(false);
      }
    }

    checkAuth();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [supabase]);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  return (
    <header className="sticky top-0 z-50 w-full border-b border-brand-border/60 bg-brand-bg/80 backdrop-blur-xl">
      <div className="mx-auto flex h-18 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-3 group focus:outline-none focus:ring-2 focus:ring-brand-green/50 rounded-lg p-1">
          <div className="relative h-10 w-10 overflow-hidden rounded-xl border border-brand-border bg-brand-surface shadow-md group-hover:border-brand-green/50 transition-colors">
            <Image
              src="/fit_host_icon.png"
              alt="Fit Host Logo"
              width={40}
              height={40}
              className="object-cover"
              priority
              unoptimized
            />
          </div>
          <div className="flex flex-col">
            <span className="text-xl font-black tracking-tight text-white group-hover:text-brand-green transition-colors">
              FIT<span className="text-brand-green">HOST</span>
            </span>
            <span className="text-[10px] tracking-widest uppercase text-brand-muted -mt-1 font-semibold">
              Fitness & Wellness
            </span>
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden lg:flex items-center gap-1" aria-label="Main Navigation">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`px-3.5 py-2 text-sm font-medium rounded-lg transition-colors ${
                  isActive
                    ? "text-brand-green bg-brand-green/10 font-semibold"
                    : "text-zinc-300 hover:text-white hover:bg-brand-surface"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Desktop CTA / Auth */}
        <div className="hidden lg:flex items-center gap-3">
          {loading ? (
            <div className="h-9 w-24 bg-brand-surface animate-pulse rounded-lg" />
          ) : user ? (
            <div className="flex items-center gap-2">
              <Link
                href="/dashboard"
                className={`inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-all ${
                  pathname === "/dashboard"
                    ? "bg-brand-green text-black font-bold shadow-md shadow-brand-green/20"
                    : "bg-brand-surface text-white hover:bg-brand-elevated border border-brand-border hover:border-brand-green/40"
                }`}
              >
                <LayoutDashboard className="h-4 w-4 text-brand-green" />
                Dashboard
              </Link>
              <button
                onClick={handleSignOut}
                aria-label="Sign out"
                className="p-2 text-zinc-400 hover:text-red-400 hover:bg-brand-surface rounded-lg transition-colors"
                title="Sign Out"
              >
                <LogOut className="h-4 w-4" />
              </button>
            </div>
          ) : (
            <>
              <Link
                href="/login"
                className="px-3.5 py-2 text-sm font-semibold text-zinc-300 hover:text-white transition-colors"
              >
                Sign In
              </Link>
              <Link
                href="/download"
                className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-lg shadow-sm hover:shadow-brand-green/20 transition-all"
              >
                Get App
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </>
          )}
        </div>

        {/* Mobile menu button */}
        <div className="flex lg:hidden items-center gap-2">
          {user && (
            <Link
              href="/dashboard"
              className="p-2 text-brand-green bg-brand-surface rounded-lg border border-brand-border"
              aria-label="Go to Dashboard"
            >
              <LayoutDashboard className="h-5 w-5" />
            </Link>
          )}
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2.5 text-zinc-300 hover:text-white bg-brand-surface hover:bg-brand-elevated rounded-lg border border-brand-border transition-colors"
            aria-expanded={mobileMenuOpen}
            aria-label="Toggle navigation menu"
          >
            {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu Drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden border-b border-brand-border bg-brand-bg/95 backdrop-blur-2xl px-4 pt-3 pb-6 animate-in slide-in-from-top-2 duration-200">
          <div className="flex flex-col space-y-2">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`px-4 py-3 rounded-xl text-base font-medium transition-colors ${
                    isActive
                      ? "bg-brand-green/10 text-brand-green font-semibold border border-brand-green/20"
                      : "text-zinc-300 hover:bg-brand-surface hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
            <div className="pt-4 border-t border-brand-border/60 flex flex-col gap-2">
              {user ? (
                <>
                  <Link
                    href="/dashboard"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex items-center justify-center gap-2 w-full py-3 text-sm font-bold text-black bg-brand-green rounded-xl shadow-md"
                  >
                    <LayoutDashboard className="h-4 w-4" />
                    Open Dashboard
                  </Link>
                  <button
                    onClick={() => {
                      setMobileMenuOpen(false);
                      handleSignOut();
                    }}
                    className="flex items-center justify-center gap-2 w-full py-3 text-sm font-semibold text-zinc-300 bg-brand-surface hover:text-red-400 rounded-xl border border-brand-border"
                  >
                    <LogOut className="h-4 w-4" />
                    Sign Out ({user.email})
                  </button>
                </>
              ) : (
                <>
                  <Link
                    href="/login"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex items-center justify-center w-full py-3 text-sm font-semibold text-white bg-brand-surface hover:bg-brand-elevated rounded-xl border border-brand-border"
                  >
                    Sign In
                  </Link>
                  <Link
                    href="/download"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex items-center justify-center gap-1.5 w-full py-3 text-sm font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-md shadow-brand-green/20"
                  >
                    Download Fit Host
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
