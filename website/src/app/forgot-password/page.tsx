"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Mail, ArrowRight, AlertCircle, CheckCircle2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);

  const supabase = createClient();

  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email.trim()) {
      setError("Please enter your account email address.");
      return;
    }

    setLoading(true);

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/auth/recovery`,
      });

      if (error) {
        setError(error.message);
        return;
      }

      setSubmitted(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to dispatch password recovery email.");
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
            Reset Your Password
          </h1>
          <p className="text-xs text-zinc-400">
            Enter your email to receive a secure recovery link.
          </p>
        </div>

        <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
          {submitted ? (
            <div className="text-center py-6 space-y-4">
              <div className="h-14 w-14 mx-auto rounded-full bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green">
                <CheckCircle2 className="h-7 w-7" />
              </div>
              <h2 className="text-xl font-bold text-white">Recovery Email Dispatched</h2>
              <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
                If an account exists for <strong className="text-white">{email}</strong>, you will receive an email containing a link to choose a new password.
              </p>
              <div className="pt-2">
                <Link
                  href="/login"
                  className="inline-flex items-center justify-center w-full py-2.5 rounded-xl bg-brand-surface border border-brand-border text-xs font-semibold text-white hover:bg-brand-elevated transition-colors"
                >
                  Return to Sign In
                </Link>
              </div>
            </div>
          ) : (
            <form onSubmit={handleReset} className="space-y-4">
              {error && (
                <div className="p-3.5 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-start gap-2.5">
                  <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                  <span>{error}</span>
                </div>
              )}

              <div className="space-y-1.5">
                <label htmlFor="recovery-email" className="text-xs font-semibold text-zinc-300">
                  Account Email Address
                </label>
                <div className="relative">
                  <input
                    id="recovery-email"
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="athlete@example.com"
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-sm focus:outline-none focus:border-brand-green transition-colors"
                  />
                  <Mail className="absolute left-3.5 top-3 h-4 w-4 text-zinc-500" />
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
                    Sending Recovery Link...
                  </>
                ) : (
                  <>
                    Send Recovery Link
                    <ArrowRight className="h-4 w-4" />
                  </>
                )}
              </button>

              <div className="text-center pt-2">
                <Link href="/login" className="text-xs text-zinc-400 hover:text-white">
                  Remember your password? <span className="text-brand-green font-semibold">Sign in</span>
                </Link>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
