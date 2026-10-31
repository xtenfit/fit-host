import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Shield, Megaphone, Mail, LayoutDashboard, ArrowUpRight } from 'lucide-react';
import { verifyAdminAuthorization } from '@/lib/email/auth';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const auth = await verifyAdminAuthorization();

  // Stealth 404: Render standard 404 page for any unauthorized visitor or normal user
  if (!auth.authorized) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Top Admin Hub Navigation Bar */}
      <nav className="sticky top-0 z-50 border-b border-brand-border bg-black/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6">
          <div className="flex items-center gap-3">
            <Link href="/admin" className="flex items-center gap-2.5 group">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-green/10 text-brand-green border border-brand-green/30 group-hover:bg-brand-green/20 transition-all">
                <Shield className="h-4.5 w-4.5 text-brand-green" />
              </span>
              <div>
                <span className="text-sm font-black tracking-wide text-white group-hover:text-brand-green transition-colors flex items-center gap-1.5">
                  Fit Host Admin Hub
                </span>
                <span className="block text-[10px] font-semibold tracking-wider uppercase text-zinc-500">
                  Control &amp; Operations
                </span>
              </div>
            </Link>
          </div>

          <div className="flex items-center gap-1.5 sm:gap-2">
            <Link
              href="/admin?tab=overview"
              className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold text-zinc-300 transition-colors hover:bg-white/5 hover:text-white"
            >
              <LayoutDashboard className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">Overview</span>
            </Link>
            <Link
              href="/admin?tab=content"
              className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold text-zinc-300 transition-colors hover:bg-white/5 hover:text-brand-green"
            >
              <Megaphone className="h-3.5 w-3.5" />
              <span>Content CMS</span>
            </Link>
            <Link
              href="/admin?tab=email"
              className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold text-zinc-300 transition-colors hover:bg-white/5 hover:text-brand-green"
            >
              <Mail className="h-3.5 w-3.5" />
              <span>Email Studio</span>
            </Link>
            <div className="h-4 w-px bg-zinc-800 mx-1 hidden sm:block" />
            <Link
              href="/dashboard"
              className="inline-flex items-center gap-1 rounded-lg border border-brand-border bg-brand-surface px-3 py-1.5 text-xs font-semibold text-zinc-400 hover:text-white hover:border-zinc-700 transition-colors"
            >
              Dashboard
              <ArrowUpRight className="h-3 w-3 opacity-60" />
            </Link>
          </div>
        </div>
      </nav>

      {children}
    </div>
  );
}
