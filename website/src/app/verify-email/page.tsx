"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter, useSearchParams } from "next/navigation";
import { KeyRound, Mail, ArrowRight, AlertCircle, CheckCircle2, RotateCcw } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

function VerifyEmailForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialEmail = searchParams.get("email") || "";

  const [email, setEmail] = useState(initialEmail);
  const [token, setToken] = useState("");
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const supabase = createClient();

  useEffect(() => {
    let timer: NodeJS.Timeout | undefined;
    if (cooldown > 0) {
      timer = setTimeout(() => setCooldown(cooldown - 1), 1000);
    }
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [cooldown]);

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const cleanToken = token.trim();
    if (cleanToken.length !== 6) {
      setError("Please enter the complete 6-digit verification code.");
      return;
    }

    setLoading(true);

    try {
      // First attempt with email verification
      let { error: verifyError } = await supabase.auth.verifyOtp({
        email: email.trim(),
        token: cleanToken,
        type: "email",
      });

      // If 'email' type fails, attempt 'signup' type
      if (verifyError) {
        const signupAttempt = await supabase.auth.verifyOtp({
          email: email.trim(),
          token: cleanToken,
          type: "signup",
        });
        if (!signupAttempt.error) {
          verifyError = null;
        }
      }

      if (verifyError) {
        setError(verifyError.message || "Invalid or expired 6-digit code.");
        return;
      }

      setSuccess(true);
      setTimeout(() => {
        router.push("/dashboard");
        router.refresh();
      }, 1000);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "An error occurred while verifying the code.");
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (cooldown > 0 || !email.trim()) return;
    setError(null);
    setResending(true);

    try {
      const { error } = await supabase.auth.signInWithOtp({
        email: email.trim(),
        options: {
          shouldCreateUser: false,
        },
      });

      if (error) {
        setError(error.message);
        return;
      }

      setCooldown(60);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to resend code.");
    } finally {
      setResending(false);
    }
  };

  return (
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
          Verify 6-Digit Email Code
        </h1>
        <p className="text-xs text-zinc-400">
          Enter the verification code sent to your email address.
        </p>
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
        {success ? (
          <div className="text-center py-6 space-y-3">
            <div className="h-12 w-12 mx-auto rounded-full bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green">
              <CheckCircle2 className="h-6 w-6" />
            </div>
            <h2 className="text-lg font-bold text-white">Verification Successful!</h2>
            <p className="text-xs text-zinc-400">Redirecting to your fitness dashboard...</p>
          </div>
        ) : (
          <form onSubmit={handleVerify} className="space-y-4">
            {error && (
              <div className="p-3.5 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-start gap-2.5">
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div className="space-y-1.5">
              <label htmlFor="verify-email" className="text-xs font-semibold text-zinc-300">
                Email Address
              </label>
              <div className="relative">
                <input
                  id="verify-email"
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

            <div className="space-y-1.5">
              <label htmlFor="token" className="text-xs font-semibold text-zinc-300">
                6-Digit Security Code
              </label>
              <div className="relative">
                <input
                  id="token"
                  type="text"
                  maxLength={6}
                  required
                  value={token}
                  onChange={(e) => setToken(e.target.value.replace(/\D/g, ""))}
                  placeholder="123456"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-base tracking-[0.3em] font-mono focus:outline-none focus:border-brand-green transition-colors"
                />
                <KeyRound className="absolute left-3.5 top-3.5 h-4 w-4 text-zinc-500" />
              </div>
              <p className="text-[11px] text-zinc-500">
                Check your inbox or Spam folder for the 6-digit code.
              </p>
            </div>

            <button
              type="submit"
              disabled={loading || token.length !== 6}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-green hover:bg-brand-green-hover text-black font-bold text-sm shadow-md transition-colors disabled:opacity-50"
            >
              {loading ? (
                <>
                  <span className="h-4 w-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
                  Verifying...
                </>
              ) : (
                <>
                  Verify & Continue
                  <ArrowRight className="h-4 w-4" />
                </>
              )}
            </button>

            <div className="pt-2 flex items-center justify-between text-xs">
              <button
                type="button"
                onClick={handleResend}
                disabled={resending || cooldown > 0 || !email.trim()}
                className="text-brand-green hover:underline flex items-center gap-1.5 disabled:opacity-40 disabled:hover:no-underline font-semibold"
              >
                <RotateCcw className="h-3.5 w-3.5" />
                {cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend 6-Digit Code"}
              </button>

              <Link href="/login" className="text-zinc-400 hover:text-white">
                Back to Sign In
              </Link>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto flex items-center justify-center">
      <Suspense fallback={<div className="h-96 w-full max-w-md bg-brand-surface animate-pulse rounded-2xl" />}>
        <VerifyEmailForm />
      </Suspense>
    </div>
  );
}
