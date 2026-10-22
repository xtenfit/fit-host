import type { Metadata } from "next";
import Link from "next/link";
import { Shield } from "lucide-react";
import { siteConfig } from "@/lib/config/site";

export const metadata: Metadata = {
  title: "Privacy Policy — Fit Host Data Governance & Security",
  description:
    "Read the Fit Host Privacy Policy. We detail exact biometric and account data collected, storage security via Supabase RLS, and your rights to data deletion.",
};

export default function PrivacyPage() {
  const lastUpdated = "October 21, 2026";

  return (
    <div className="py-12 sm:py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto space-y-12">
      <div className="space-y-4">
        <span className="text-xs font-bold uppercase tracking-widest text-brand-green">
          Legal & Compliance
        </span>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
          Privacy Policy
        </h1>
        <p className="text-sm text-zinc-400">
          Last Updated: {lastUpdated} • Official Domain:{" "}
          <code className="text-brand-green font-mono">{siteConfig.domain}</code>
        </p>
      </div>

      <div className="p-4 rounded-xl bg-brand-surface border border-brand-border text-xs text-zinc-300 flex items-start gap-3">
        <Shield className="h-5 w-5 text-brand-green shrink-0 mt-0.5" />
        <p className="leading-relaxed">
          <strong>Summary of Our Commitment:</strong> Fit Host is engineered around privacy-first principles. We do not sell your personal biometrics or workout data to advertisers, health insurers, or data brokers. Data remains stored locally on your device in Guest Mode, and encrypts via Supabase Row Level Security when you choose to synchronize to the cloud.
        </p>
      </div>

      <div className="prose prose-invert max-w-none space-y-8 text-sm text-zinc-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            1. Information We Collect
          </h2>
          <p>
            The data Fit Host processes depends entirely on whether you utilize Guest Mode or register an Authenticated Account:
          </p>
          <ul className="list-disc pl-5 space-y-2">
            <li>
              <strong>Account Information:</strong> When signing up, we collect your email address, display name, and authentication tokens via Supabase. If you sign in using Google OAuth, we receive your name, email address, and avatar image URL provided by Google.
            </li>
            <li>
              <strong>Onboarding & Profile Details:</strong> Self-reported fitness goals (e.g. hypertrophy, endurance, fat loss), experience level, target workout days per week, and preferred training split.
            </li>
            <li>
              <strong>Workout & Exercise Data:</strong> Exercise names, sets, repetitions, resistance weight, RPE (rate of perceived exertion), workout duration, and personal workout notes.
            </li>
            <li>
              <strong>Body Measurements & Progress Photos:</strong> Body weight logs, circumferences (waist, hips, chest, biceps), estimated body fat percentages, and optional user-uploaded progress gallery photos stored in private encrypted cloud buckets.
            </li>
            <li>
              <strong>Hydration & Fluid Logs:</strong> Volumes of fluid intake (milliliters) and timestamps of fluid consumption.
            </li>
            <li>
              <strong>Nutrition & Macronutrient Logs:</strong> Caloric totals, protein, carbohydrates, fats (in grams), food item names, meal classifications (Breakfast, Lunch, Dinner, Snacks), and scanned product barcodes.
            </li>
            <li>
              <strong>Activity & Step Counts:</strong> Daily step counts and estimated distances recorded via native mobile pedometer sensors.
            </li>
            <li>
              <strong>Device Permissions:</strong> Notification and exact alarm permissions for scheduled workout reminders and hydration nudges; camera permission exclusively for barcode scanning; storage/photo library access solely when explicitly selecting progress photos.
            </li>
            <li>
              <strong>Guest Data:</strong> In Guest Mode, all data is written strictly to an isolated local SQLite database on your device and is never transmitted to our cloud servers without your explicit consent.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            2. How We Store and Protect Your Data
          </h2>
          <p>
            We implement defense-in-depth security measures to protect your physical training and wellness records:
          </p>
          <ul className="list-disc pl-5 space-y-2">
            <li>
              <strong>Row Level Security (RLS):</strong> Our Supabase PostgreSQL database enforces strict database-level RLS policies (<code className="text-brand-green font-mono text-xs">auth.uid() = user_id</code>). No user can access or view another user&apos;s workout or nutrition logs.
            </li>
            <li>
              <strong>Local Drift Database:</strong> On mobile devices, data is stored in an embedded SQLite database using Drift ORM. This data resides solely in your device&apos;s sandboxed application storage.
            </li>
            <li>
              <strong>Private Storage Buckets:</strong> User-uploaded progress photos are stored in isolated Supabase Storage buckets governed by user-scoped RLS policies.
            </li>
            <li>
              <strong>Encryption in Transit:</strong> All communications between mobile clients, the Next.js web application, and Supabase occur over TLS 1.3 / HTTPS.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            3. Third-Party Service Providers
          </h2>
          <p>
            Fit Host uses a minimal set of trusted infrastructure partners:
          </p>
          <ul className="list-disc pl-5 space-y-2">
            <li>
              <strong>Supabase Inc.:</strong> Authoritative cloud database, authentication, and file storage provider.
            </li>
            <li>
              <strong>Vercel Inc.:</strong> Hosting infrastructure and Edge Network for the Fit Host web platform.
            </li>
            <li>
              <strong>Google Cloud Identity:</strong> Optional third-party authentication via Google OAuth.
            </li>
            <li>
              <strong>OpenFoodFacts & USDA FoodData Central:</strong> Public open-data nutritional databases queried for barcode food product details and macro composition.
            </li>
            <li>
              <strong>Resend Inc.:</strong> Transactional email service for email verification codes, password resets, and account security notifications.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            4. User Rights and Data Deletion
          </h2>
          <p>
            You retain absolute ownership of your personal fitness records. You have the right to:
          </p>
          <ul className="list-disc pl-5 space-y-2">
            <li>Access and export your full workout and nutrition history.</li>
            <li>
              Request immediate and permanent account deletion. Review our comprehensive{" "}
              <Link href="/account-deletion" className="text-brand-green font-semibold hover:underline">
                Account Deletion & Data Removal Policy
              </Link>{" "}
              for detailed self-service and email instructions.
            </li>
            <li>Clear all local mobile cache by uninstalling the app or using the in-app reset tools.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            5. Contact and Inquiries
          </h2>
          <p>
            If you have questions regarding this Privacy Policy or wish to request data deletion, please submit an inquiry via our{" "}
            <Link href="/support" className="text-brand-green font-semibold hover:underline">
              Support Center
            </Link>{" "}
            or email our security team directly at{" "}
            <a href={`mailto:${siteConfig.support.email}`} className="text-brand-green font-mono font-semibold hover:underline">
              {siteConfig.support.email}
            </a>.
          </p>
        </section>
      </div>
    </div>
  );
}
