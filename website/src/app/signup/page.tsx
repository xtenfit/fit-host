"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Lock, Mail, User, ArrowRight, AlertCircle } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function SignupPage() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (password.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    setLoading(true);

    try {
      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            display_name: fullName.trim() || undefined,
          },
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (error) {
        setError(error.message);
        return;
      }

      if (data.session) {
        // Immediate session granted
        router.push("/dashboard");
        router.refresh();
      } else {
        // Email confirmation / 6-digit code sent
        router.push(`/verify-email?email=${encodeURIComponent(email.trim())}`);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "An unexpected error occurred during registration.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignup = async () => {
    setError(null);
    setLoading(true);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: `${window.location.origin}/auth/callback?next=/dashboard`,
        },
      });
      if (error) {
        setError(error.message);
        setLoading(false);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to initiate Google sign-up.");
      setLoading(false);
    }
  };

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto flex items-center justify-center">
      <div className="w-full max-w-md mx-auto space-y-6">
        {/* Brand logo & title */}
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
            Create Your Fit Host Account
          </h1>
          <p className="text-xs text-zinc-400">
            Sync workouts, nutrition, and hydration across all your devices.
          </p>
        </div>

        {/* Main Card */}
        <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
          {/* Google Button */}
          <button
            type="button"
            onClick={handleGoogleSignup}
            disabled={loading}
            className="w-full flex items-center justify-center gap-3 px-4 py-3 rounded-xl bg-brand-surface hover:bg-brand-elevated border border-brand-border text-white text-sm font-semibold transition-colors disabled:opacity-50"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
            Sign up with Google
          </button>

          <div className="relative flex items-center justify-center">
            <div className="w-full border-t border-brand-border/60" />
            <span className="absolute px-3 bg-brand-surface text-[11px] font-mono text-zinc-500 uppercase tracking-widest">
              or with email
            </span>
          </div>

          {error && (
            <div className="p-3.5 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-start gap-2.5">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSignup} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="fullname" className="text-xs font-semibold text-zinc-300">
                Full Name
              </label>
              <div className="relative">
                <input
                  id="fullname"
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Jordan Lee"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-sm focus:outline-none focus:border-brand-green transition-colors"
                />
                <User className="absolute left-3.5 top-3 h-4 w-4 text-zinc-500" />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="email" className="text-xs font-semibold text-zinc-300">
                Email Address <span className="text-brand-green">*</span>
              </label>
              <div className="relative">
                <input
                  id="email"
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
              <label htmlFor="password" className="text-xs font-semibold text-zinc-300">
                Create Password (Min 6 Characters) <span className="text-brand-green">*</span>
              </label>
              <div className="relative">
                <input
                  id="password"
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

            <button
              type="submit"
              disabled={loading}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-green hover:bg-brand-green-hover text-black font-bold text-sm shadow-md transition-colors disabled:opacity-50"
            >
              {loading ? (
                <>
                  <span className="h-4 w-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
                  Creating Account...
                </>
              ) : (
                <>
                  Create Account
                  <ArrowRight className="h-4 w-4" />
                </>
              )}
            </button>
          </form>

          <div className="text-[11px] text-zinc-400 text-center leading-relaxed">
            By signing up, you agree to our{" "}
            <Link href="/terms" className="text-brand-green hover:underline">
              Terms of Service
            </Link>{" "}
            and{" "}
            <Link href="/privacy" className="text-brand-green hover:underline">
              Privacy Policy
            </Link>.
          </div>
        </div>

        {/* Switch to Sign In */}
        <div className="text-center text-xs text-zinc-400">
          Already have an account?{" "}
          <Link href="/login" className="text-brand-green font-bold hover:underline">
            Sign In Here
          </Link>
        </div>
      </div>
    </div>
  );
}
