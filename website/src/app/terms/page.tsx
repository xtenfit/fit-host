import type { Metadata } from "next";
import { AlertTriangle } from "lucide-react";

export const metadata: Metadata = {
  title: "Terms of Service — Fit Host Terms of Use",
  description:
    "Read the Fit Host Terms of Service governing the use of the Fit Host mobile application and web dashboard at fithost.amitrana.tech.",
};

export default function TermsPage() {
  const lastUpdated = "October 20, 2026";

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto space-y-12">
      <div className="space-y-4">
        <span className="text-xs font-bold uppercase tracking-widest text-brand-green">
          Legal Agreement
        </span>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
          Terms of Service
        </h1>
        <p className="text-sm text-zinc-400">
          Last Updated: {lastUpdated} • Domain:{" "}
          <code className="text-brand-green font-mono">fithost.amitrana.tech</code>
        </p>
      </div>

      {/* Critical Medical Disclaimer Banner */}
      <div className="p-4 rounded-xl bg-amber-500/10 border border-amber-500/30 text-xs text-amber-200 flex items-start gap-3">
        <AlertTriangle className="h-5 w-5 text-amber-400 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <p className="font-bold text-amber-300">Important Fitness & Medical Disclaimer:</p>
          <p className="leading-relaxed">
            Fit Host is a physical training, workout logging, and wellness tracking application. It is NOT a medical device, nor does it provide personalized clinical medical diagnosis or treatment plans. Always consult a certified physician or healthcare professional before beginning any intense exercise or nutrition program.
          </p>
        </div>
      </div>

      <div className="prose prose-invert max-w-none space-y-8 text-sm text-zinc-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">1. Acceptance of Terms</h2>
          <p>
            By accessing or using the Fit Host mobile application or web portal at <code>fithost.amitrana.tech</code>, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">2. User Accounts and Security</h2>
          <p>
            When creating an account, you agree to provide accurate email and authentication information. You are solely responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">3. Acceptable Use</h2>
          <p>You agree not to:</p>
          <ul className="list-disc pl-5 space-y-1.5">
            <li>Attempt to probe, scan, or compromise our database or server infrastructure.</li>
            <li>Bypass authentication controls or access another user&apos;s records.</li>
            <li>Use automated scrapers, bots, or extraction scripts against our web endpoints.</li>
            <li>Violate any applicable local, state, national, or international law.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">4. Intellectual Property</h2>
          <p>
            Fit Host, its logos, visual themes, custom user interfaces, and software code are the intellectual property of Fit Host and its contributors. You are granted a personal, non-exclusive, revocable license to use the platform for individual fitness management.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">5. Limitation of Liability</h2>
          <p>
            To the maximum extent permitted by law, Fit Host and its developers shall not be liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the platform, including any physical injury resulting from workout routines.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">6. Modifications to Terms</h2>
          <p>
            We reserve the right to modify these terms at any time. Continued use of Fit Host following any posted revisions constitutes acceptance of the revised terms.
          </p>
        </section>
      </div>
    </div>
  );
}
