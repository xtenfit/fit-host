"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Lock, ArrowRight, AlertCircle, CheckCircle2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function PasswordRecoveryPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const supabase = createClient();

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (password.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);

    try {
      const { error } = await supabase.auth.updateUser({
        password: password,
      });

      if (error) {
        setError(error.message);
        return;
      }

      setSuccess(true);
      setTimeout(() => {
        router.push("/dashboard");
        router.refresh();
      }, 1500);
    } catch (err: any) {
      setError(err?.message || "Failed to update password.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto flex items-center justify-center">
      <div className="w-full max-w-md mx-auto space-y-6">
        <div className="text-center space-y-2">
          <Link href="/" className="inline-flex items-center gap-2.5">
            <div className="relative h-12 w-12 rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
              <Image
                src="/fit_host_icon.png"
                alt="Fit Host Logo"
                width={48}
                height={48}
                className="object-cover"
                priority
              />
            </div>
          </Link>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-white">
            Set New Password
          </h1>
          <p className="text-xs text-zinc-400">
            Choose a strong new password for your Fit Host account.
          </p>
        </div>

        <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
          {success ? (
            <div className="text-center py-6 space-y-3">
              <div className="h-12 w-12 mx-auto rounded-full bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green">
                <CheckCircle2 className="h-6 w-6" />
              </div>
              <h2 className="text-lg font-bold text-white">Password Updated!</h2>
              <p className="text-xs text-zinc-400">Redirecting to your dashboard...</p>
            </div>
          ) : (
            <form onSubmit={handleUpdatePassword} className="space-y-4">
              {error && (
                <div className="p-3.5 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-start gap-2.5">
                  <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                  <span>{error}</span>
                </div>
              )}

              <div className="space-y-1.5">
                <label htmlFor="new-password" className="text-xs font-semibold text-zinc-300">
                  New Password (Min 6 Characters)
                </label>
                <div className="relative">
                  <input
                    id="new-password"
                    type="password"
                    required
                    minLength={6}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••••••"
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-sm focus:outline-none focus:border-brand-green transition-colors"
                  />
                  <Lock className="absolute left-3.5 top-3 h-4 w-4 text-zinc-500" />
                </div>
              </div>

              <div className="space-y-1.5">
                <label htmlFor="confirm-password" className="text-xs font-semibold text-zinc-300">
                  Confirm New Password
                </label>
                <div className="relative">
                  <input
                    id="confirm-password"
                    type="password"
                    required
                    minLength={6}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="••••••••••••"
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-sm focus:outline-none focus:border-brand-green transition-colors"
                  />
                  <Lock className="absolute left-3.5 top-3 h-4 w-4 text-zinc-500" />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-green hover:bg-brand-green-hover text-black font-bold text-sm shadow-md transition-colors disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <span className="h-4 w-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
                    Updating Password...
                  </>
                ) : (
                  <>
                    Save New Password
                    <ArrowRight className="h-4 w-4" />
                  </>
                )}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
