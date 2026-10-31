"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { LayoutDashboard, Megaphone, Mail } from "lucide-react";
import AdminHubOverview from "./AdminHubOverview";
import ContentCmsManager from "./ContentCmsManager";
import EmailStudioManager from "./EmailStudioManager";

export type AdminTab = "overview" | "content" | "email";

export default function AdminHubClient() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const tabParam = searchParams.get("tab") as AdminTab | null;

  const activeTab: AdminTab =
    tabParam === "overview" || tabParam === "content" || tabParam === "email"
      ? tabParam
      : "overview";

  const handleSelectTab = (tab: AdminTab) => {
    router.replace(`/admin?tab=${tab}`, { scroll: false });
  };

  return (
    <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 space-y-8">
      {/* Tab Switcher Bar */}
      <div className="flex items-center justify-between border-b border-brand-border/80 pb-4">
        <div className="flex items-center gap-2 p-1 rounded-2xl bg-brand-surface border border-brand-border/60">
          <button
            onClick={() => handleSelectTab("overview")}
            className={`inline-flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition-all ${
              activeTab === "overview"
                ? "bg-brand-green text-black shadow-md shadow-brand-green/20"
                : "text-zinc-400 hover:text-white hover:bg-white/5"
            }`}
          >
            <LayoutDashboard className="h-3.5 w-3.5" />
            <span>Admin Hub</span>
          </button>

          <button
            onClick={() => handleSelectTab("content")}
            className={`inline-flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition-all ${
              activeTab === "content"
                ? "bg-brand-green text-black shadow-md shadow-brand-green/20"
                : "text-zinc-400 hover:text-white hover:bg-white/5"
            }`}
          >
            <Megaphone className="h-3.5 w-3.5" />
            <span>Content CMS</span>
          </button>

          <button
            onClick={() => handleSelectTab("email")}
            className={`inline-flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition-all ${
              activeTab === "email"
                ? "bg-brand-green text-black shadow-md shadow-brand-green/20"
                : "text-zinc-400 hover:text-white hover:bg-white/5"
            }`}
          >
            <Mail className="h-3.5 w-3.5" />
            <span>Email Studio</span>
          </button>
        </div>

        <div className="hidden sm:flex items-center gap-2 text-xs text-zinc-500">
          <span className="h-2 w-2 rounded-full bg-brand-green animate-pulse" />
          <span>Superadmin Access Active</span>
        </div>
      </div>

      {/* Render Active View */}
      {activeTab === "overview" && (
        <AdminHubOverview onSelectTab={(tab) => handleSelectTab(tab)} />
      )}

      {activeTab === "content" && <ContentCmsManager />}

      {activeTab === "email" && <EmailStudioManager />}
    </main>
  );
}
