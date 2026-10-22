import type { Metadata } from "next";
import Link from "next/link";
import { Trash2, AlertTriangle, CheckCircle2, ShieldCheck, Mail, ArrowRight } from "lucide-react";
import { siteConfig } from "@/lib/config/site";

export const metadata: Metadata = {
  title: "Account Deletion — Fit Host Data Governance & Account Removal",
  description:
    "Learn how to delete your Fit Host account and erase all associated personal fitness data, biometric measurements, workout logs, and cloud storage.",
};

export default function AccountDeletionPage() {
  const lastUpdated = "October 21, 2026";

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto space-y-12">
      {/* Page Header */}
      <div className="space-y-4">
        <span className="text-xs font-bold uppercase tracking-widest text-brand-green">
          Data Governance & Trust
        </span>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
          Delete Your Account & Data
        </h1>
        <p className="text-sm text-zinc-400">
          Last Updated: {lastUpdated} • Domain:{" "}
          <code className="text-brand-green font-mono">{siteConfig.domain}</code>
        </p>
      </div>

      {/* Overview Notice */}
      <div className="p-4 rounded-xl bg-brand-surface border border-brand-border text-xs text-zinc-300 flex items-start gap-3">
        <ShieldCheck className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
        <p className="leading-relaxed">
          <strong>Full User Data Autonomy:</strong> At Fit Host, you own your data. You can delete your account and all associated fitness logs at any time. Account deletion is permanent, irreversible, and immediately purges all user-owned records from our Supabase production databases and file storage.
        </p>
      </div>

      {/* Main Content Sections */}
      <div className="prose prose-invert max-w-none space-y-10 text-sm text-zinc-300 leading-relaxed">
        {/* Section 1: Exactly What Data Is Deleted */}
        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Trash2 className="h-5 w-5 text-red-400" />
            <span>1. What Data Is Deleted</span>
          </h2>
          <p>
            When you initiate account deletion, the following personal data is permanently and irreversibly removed:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose">
            <div className="p-4 rounded-xl bg-brand-surface/60 border border-brand-border space-y-2">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-brand-green" />
                <span>Account & Profile</span>
              </h3>
              <p className="text-xs text-zinc-400">
                Your primary email address, authenticated user ID, display name, profile avatar photo, and OAuth credentials.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-brand-surface/60 border border-brand-border space-y-2">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-brand-green" />
                <span>Workouts & Routines</span>
              </h3>
              <p className="text-xs text-zinc-400">
                All logged workouts, completed exercises, sets, weights, reps, custom workout routines, templates, and personal notes.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-brand-surface/60 border border-brand-border space-y-2">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-brand-green" />
                <span>Biometrics & Progress Photos</span>
              </h3>
              <p className="text-xs text-zinc-400">
                Body weight history, body measurements, circumferences, and all uploaded progress gallery images stored in private cloud buckets.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-brand-surface/60 border border-brand-border space-y-2">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-brand-green" />
                <span>Nutrition & Hydration</span>
              </h3>
              <p className="text-xs text-zinc-400">
                Daily food diaries, meal logs, macronutrient goals (protein, carbs, fat, calories), fluid logs, and water intake history.
              </p>
            </div>
          </div>
        </section>

        {/* Section 2: Retention Policy */}
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-amber-400" />
            <span>2. Data Retention & Exceptions</span>
          </h2>
          <p>
            Fit Host maintains a strict zero-shadow policy. We do not retain backup copies of deleted user data.
          </p>
          <ul className="list-disc pl-5 space-y-2">
            <li>
              <strong>Immediate Deletion:</strong> All database records tied to your authenticated <code className="text-brand-green font-mono text-xs">user_id</code> are purged immediately through PostgreSQL foreign key cascade rules.
            </li>
            <li>
              <strong>Guest Mode Users:</strong> If you use Fit Host in Guest Mode, your data is stored strictly in your local device SQLite/Drift database. Uninstalling the mobile app or clearing app storage instantly and completely destroys all local data.
            </li>
            <li>
              <strong>Operational Logs:</strong> Standard web server edge logs (e.g., anonymized IP addresses and request status codes) are retained for a maximum of 30 days for infrastructure DDoS mitigation and network security, after which they are automatically purged.
            </li>
          </ul>
        </section>

        {/* Section 3: How to Delete Your Account */}
        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">3. How to Delete Your Account</h2>
          <p>
            You can delete your account using either of the two methods below:
          </p>

          <div className="space-y-4 not-prose">
            {/* Method A: In-App Self Service */}
            <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-base font-bold text-white">Method A: Self-Service in the Mobile App (Instant)</h3>
                <span className="text-[11px] font-bold px-2 py-0.5 rounded bg-brand-green/20 text-brand-green border border-brand-green/30">
                  Recommended
                </span>
              </div>
              <ol className="list-decimal pl-5 text-xs text-zinc-300 space-y-2">
                <li>Open the <strong>Fit Host</strong> mobile application on your iOS or Android device.</li>
                <li>Navigate to the <strong>Profile</strong> tab (bottom navigation).</li>
                <li>Tap <strong>Settings & Privacy</strong>.</li>
                <li>Scroll to the <strong>Account Management</strong> section and select <strong>Delete Account & All Data</strong>.</li>
                <li>Enter your current account password to re-authenticate and confirm deletion.</li>
                <li>Your account, database entries, and cloud files are instantly erased, and your session is revoked.</li>
              </ol>
            </div>

            {/* Method B: Direct Request */}
            <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-3">
              <h3 className="text-base font-bold text-white">Method B: Direct Deletion Request via Email / Web</h3>
              <p className="text-xs text-zinc-300 leading-relaxed">
                If you have uninstalled the application, lost access to your mobile device, or signed in using Google OAuth and wish to request account deletion directly:
              </p>
              <div className="p-3 rounded-lg bg-black/40 border border-brand-border/60 text-xs text-zinc-300 flex items-center justify-between gap-4">
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-brand-green shrink-0" />
                  <span>Send an email from your registered account to: </span>
                  <a
                    href={`mailto:${siteConfig.support.email}?subject=Fit%20Host%20Account%20Deletion%20Request`}
                    className="text-brand-green font-mono font-bold hover:underline"
                  >
                    {siteConfig.support.email}
                  </a>
                </div>
              </div>
              <p className="text-[11px] text-zinc-400">
                Please include &ldquo;Account Deletion Request&rdquo; in the subject line. Requests received from the verified email address associated with the account are processed within 48 to 72 business hours.
              </p>
            </div>
          </div>
        </section>

        {/* Section 4: Related Links */}
        <section className="space-y-4 pt-4 border-t border-brand-border/60">
          <h2 className="text-lg font-bold text-white">Related Trust & Legal Documents</h2>
          <div className="flex flex-wrap gap-4 not-prose">
            <Link
              href="/privacy"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-surface border border-brand-border text-xs font-semibold text-zinc-200 hover:text-brand-green hover:border-brand-green transition-colors"
            >
              <span>Privacy Policy</span>
              <ArrowRight className="h-3 w-3" />
            </Link>
            <Link
              href="/terms"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-surface border border-brand-border text-xs font-semibold text-zinc-200 hover:text-brand-green hover:border-brand-green transition-colors"
            >
              <span>Terms of Service</span>
              <ArrowRight className="h-3 w-3" />
            </Link>
            <Link
              href="/support"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-surface border border-brand-border text-xs font-semibold text-zinc-200 hover:text-brand-green hover:border-brand-green transition-colors"
            >
              <span>Help & Support Center</span>
              <ArrowRight className="h-3 w-3" />
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
