"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function SignOutButton() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSignOut = async () => {
    setLoading(true);
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  return (
    <button
      onClick={handleSignOut}
      disabled={loading}
      className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-brand-surface hover:bg-brand-elevated border border-brand-border text-zinc-300 hover:text-red-400 text-xs font-semibold transition-colors disabled:opacity-50"
    >
      <LogOut className="h-3.5 w-3.5" />
      {loading ? "Signing Out..." : "Sign Out"}
    </button>
  );
}
