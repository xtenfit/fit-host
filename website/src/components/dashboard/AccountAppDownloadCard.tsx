"use client";

import { useState } from "react";
import {
  Download,
  Smartphone,
  ShieldCheck,
  Check,
  Copy,
  Layers,
  Cpu,
  RefreshCw,
  ExternalLink,
} from "lucide-react";
import {
  splitReleasePackages,
  type SplitPackageInfo,
  APP_RELEASE_VERSION,
  APP_SCHEMA_VERSION,
} from "@/lib/config/downloads";

interface AccountAppDownloadCardProps {
  userEmail: string;
  isProfileSetupCompleted?: boolean;
  profileVersion?: number;
}

export default function AccountAppDownloadCard({
  userEmail,
  isProfileSetupCompleted = true,
  profileVersion = APP_SCHEMA_VERSION,
}: AccountAppDownloadCardProps) {
  const [selectedAbi, setSelectedAbi] = useState<string>("arm64-v8a");
  const [copiedSha, setCopiedSha] = useState(false);

  const selectedPkg =
    splitReleasePackages.find((p) => p.abi === selectedAbi) ||
    splitReleasePackages[0];

  const handleCopySha = () => {
    navigator.clipboard.writeText(selectedPkg.sha256);
    setCopiedSha(true);
    setTimeout(() => setCopiedSha(false), 2000);
  };

  return (
    <div className="glass-panel p-6 sm:p-8 rounded-3xl border border-brand-green/30 bg-gradient-to-br from-brand-surface via-brand-surface/95 to-brand-elevated shadow-xl space-y-6">
      {/* Header with Account Sync Context */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 border-b border-brand-border/60">
        <div className="flex items-center gap-3.5">
          <div className="p-3 rounded-2xl bg-brand-green/10 border border-brand-green/30 text-brand-green shadow-inner">
            <Smartphone className="h-6 w-6" />
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-xl font-black text-white">
                Mobile App Client for Your Account
              </h2>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-brand-green/10 border border-brand-green/30 text-brand-green font-mono">
                {APP_RELEASE_VERSION}
              </span>
            </div>
            <p className="text-xs text-zinc-400 mt-0.5">
              Synced to user account:{" "}
              <strong className="text-zinc-200">{userEmail}</strong>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-wrap text-xs">
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-brand-surface border border-brand-border text-zinc-300 font-medium">
            <RefreshCw className="h-3.5 w-3.5 text-brand-green" />
            <span>Schema v{profileVersion}</span>
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-brand-green/10 border border-brand-green/30 text-brand-green font-bold">
            <ShieldCheck className="h-3.5 w-3.5" />
            <span>
              {isProfileSetupCompleted ? "Account Configured" : "Setup Active"}
            </span>
          </span>
        </div>
      </div>

      {/* Architecture Selection (Split APKs) */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <label className="text-xs font-bold text-zinc-300 uppercase tracking-wider flex items-center gap-2">
            <Cpu className="h-4 w-4 text-brand-green" />
            Select Device Architecture (Split Release Build)
          </label>
          <span className="text-[11px] text-zinc-400">
            Dramatically reduces APK size (from 107MB down to ~44MB)
          </span>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2.5">
          {splitReleasePackages.map((pkg) => {
            const isSelected = selectedAbi === pkg.abi;
            return (
              <button
                key={pkg.abi}
                type="button"
                onClick={() => setSelectedAbi(pkg.abi)}
                className={`text-left p-3.5 rounded-2xl border transition-all ${
                  isSelected
                    ? "bg-brand-green/15 border-brand-green text-white shadow-lg shadow-brand-green/10"
                    : "bg-brand-surface/70 border-brand-border text-zinc-400 hover:text-white hover:border-brand-green/40"
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-mono font-bold">
                    {pkg.name}
                  </span>
                  {pkg.recommended && (
                    <span className="px-1.5 py-0.5 rounded text-[9px] font-black uppercase bg-brand-green text-black">
                      Rec
                    </span>
                  )}
                </div>
                <div className="text-[11px] font-semibold text-brand-green">
                  {pkg.sizeFormatted}
                </div>
                <div className="text-[10px] text-zinc-500 mt-0.5 truncate">
                  {pkg.architecture}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Package Details */}
      <div className="rounded-2xl border border-brand-border bg-black/40 p-4 space-y-3 text-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div>
            <div className="font-bold text-white flex items-center gap-2">
              <span>{selectedPkg.name}</span>
              <span className="text-zinc-500 font-normal">·</span>
              <span className="text-brand-green font-mono font-semibold">
                {selectedPkg.sizeFormatted}
              </span>
              <span className="text-zinc-500 font-normal">·</span>
              <span className="text-zinc-400">{selectedPkg.minAndroid}</span>
            </div>
            <p className="text-zinc-400 text-[11px] mt-0.5">
              {selectedPkg.description}
            </p>
          </div>

          <a
            href={selectedPkg.downloadUrl}
            download={selectedPkg.filename}
            className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-green hover:bg-brand-green-hover text-black font-bold text-sm shadow-md shadow-brand-green/20 transition-all shrink-0 hover:scale-[1.02]"
          >
            <Download className="h-4 w-4" />
            <span>Download {selectedPkg.filename}</span>
          </a>
        </div>

        {/* SHA-256 Checksum Verification */}
        <div className="pt-2 border-t border-brand-border/40 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div className="flex items-center gap-2 overflow-hidden">
            <span className="text-[10px] uppercase font-bold text-zinc-500 shrink-0">
              SHA-256:
            </span>
            <code className="text-[11px] font-mono text-zinc-400 truncate select-all">
              {selectedPkg.sha256}
            </code>
          </div>
          <button
            type="button"
            onClick={handleCopySha}
            className="inline-flex items-center gap-1.5 text-[11px] text-zinc-400 hover:text-white shrink-0 self-end sm:self-auto py-1 px-2 rounded-lg bg-brand-surface border border-brand-border hover:border-brand-green/40 transition-colors"
          >
            {copiedSha ? (
              <>
                <Check className="h-3 w-3 text-brand-green" />
                <span className="text-brand-green font-semibold">Copied!</span>
              </>
            ) : (
              <>
                <Copy className="h-3 w-3" />
                <span>Copy Checksum</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Account Seamless Sync Instructions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
        <div className="p-3.5 rounded-xl bg-brand-surface border border-brand-border">
          <span className="text-[10px] font-bold text-brand-green uppercase block mb-1">
            Step 1 · Install
          </span>
          <p className="text-zinc-300 text-[11px] leading-relaxed">
            Download the split APK on your Android device and allow &ldquo;Install
            unknown apps&rdquo; in settings.
          </p>
        </div>

        <div className="p-3.5 rounded-xl bg-brand-surface border border-brand-border">
          <span className="text-[10px] font-bold text-brand-green uppercase block mb-1">
            Step 2 · Connect Account
          </span>
          <p className="text-zinc-300 text-[11px] leading-relaxed">
            Sign in with <strong className="text-white">{userEmail}</strong>.
            Your account wizard setup is saved automatically.
          </p>
        </div>

        <div className="p-3.5 rounded-xl bg-brand-surface border border-brand-border">
          <span className="text-[10px] font-bold text-brand-green uppercase block mb-1">
            Step 3 · Realtime Sync
          </span>
          <p className="text-zinc-300 text-[11px] leading-relaxed">
            All offline workouts, hydration, and nutrition logs will sync seamlessly
            to this web dashboard.
          </p>
        </div>
      </div>
    </div>
  );
}

