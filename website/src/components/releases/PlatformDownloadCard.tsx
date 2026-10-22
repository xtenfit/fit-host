import React from "react";
import Link from "next/link";
import {
  Download,
  Smartphone,
  Apple,
  ShieldCheck,
  AlertCircle,
  ExternalLink,
  Info,
  CheckCircle2,
  Clock,
} from "lucide-react";
import type { PlatformReleaseInfo } from "@/lib/github/releases";
import { releasesConfig } from "@/lib/config/releases";
import ReleaseStatusBadge from "./ReleaseStatus";

interface PlatformDownloadCardProps {
  platform: "android" | "ios";
  info: PlatformReleaseInfo;
  slug?: string;
  className?: string;
}

export default function PlatformDownloadCard({
  platform,
  info,
  slug,
  className = "",
}: PlatformDownloadCardProps) {
  const isAndroid = platform === "android";

  if (isAndroid) {
    const hasApk = Boolean(info.downloadUrl && info.distributionStatus === "available");

    return (
      <div
        className={`relative flex flex-col justify-between rounded-3xl border border-brand-border bg-gradient-to-b from-brand-surface to-brand-surface/70 p-6 sm:p-8 hover:border-brand-green/40 transition-all shadow-xl ${className}`}
      >
        {/* Top Header */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-2xl bg-brand-green/10 border border-brand-green/20 text-brand-green">
                <Smartphone className="h-6 w-6" />
              </div>
              <div>
                <h3 className="text-xl font-black text-white">Android</h3>
                <p className="text-xs text-zinc-400">Direct Sideloadable Release APK</p>
              </div>
            </div>
            <ReleaseStatusBadge status={info.distributionStatus} platform="android" />
          </div>

          {/* Version & OS details */}
          <div className="grid grid-cols-2 gap-2 pt-2 text-xs">
            <div className="rounded-xl border border-brand-border/60 bg-brand-surface/80 p-3">
              <span className="text-zinc-500 block uppercase font-bold text-[10px]">Version</span>
              <span className="font-mono font-bold text-white text-sm">{info.version}</span>
            </div>
            <div className="rounded-xl border border-brand-border/60 bg-brand-surface/80 p-3">
              <span className="text-zinc-500 block uppercase font-bold text-[10px]">Asset Size</span>
              <span className="font-mono font-bold text-brand-green text-sm">
                {info.assetSize || "Release Soon"}
              </span>
            </div>
          </div>

          <div className="text-xs text-zinc-300 leading-relaxed">
            {info.minimumSupportedOs && (
              <p className="text-zinc-400">
                <strong className="text-zinc-200">Compatibility: </strong>
                {info.minimumSupportedOs}
              </p>
            )}
          </div>

          {/* Android Installation Sideload Guidance */}
          <div className="rounded-xl border border-amber-500/20 bg-amber-500/5 p-3.5 text-xs text-amber-200/90 flex items-start gap-2.5">
            <Info className="h-4 w-4 text-amber-400 shrink-0 mt-0.5" />
            <p className="leading-relaxed">
              When installing directly, Android may prompt:{" "}
              <em>&ldquo;Install unknown apps&rdquo;</em>. Tap Settings and allow your browser or file manager to complete installation.
            </p>
          </div>

          {/* Verified Checksum if available */}
          {info.sha256Checksum && (
            <div className="rounded-xl border border-brand-border bg-black/40 p-3 text-xs space-y-1">
              <span className="text-[10px] uppercase font-bold text-brand-muted block">
                Verified SHA-256 Checksum
              </span>
              <code className="text-[11px] font-mono text-zinc-300 break-all select-all block">
                {info.sha256Checksum}
              </code>
            </div>
          )}
        </div>

        {/* Bottom Actions */}
        <div className="pt-6 space-y-3">
          {hasApk ? (
            <a
              href={info.downloadUrl!}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full inline-flex items-center justify-center gap-2.5 px-6 py-4 text-base font-bold text-black bg-brand-green hover:bg-brand-green-hover rounded-xl shadow-lg shadow-brand-green/20 hover:shadow-brand-green/35 transition-all hover:scale-[1.01]"
            >
              <Download className="h-5 w-5" />
              <span>Download Android APK</span>
              {info.assetSize && (
                <span className="text-xs font-mono bg-black/20 px-2 py-0.5 rounded">
                  {info.assetSize}
                </span>
              )}
            </a>
          ) : (
            <div className="w-full p-5 rounded-2xl border border-brand-green/30 bg-zinc-950/80 text-center space-y-2">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-brand-green/10 border border-brand-green/30 text-brand-green text-xs font-bold">
                <Clock className="h-3.5 w-3.5" />
                <span>Release Soon</span>
              </div>
              <h4 className="text-white font-bold text-sm">Official APK Build Releasing Soon</h4>
              <p className="text-xs text-zinc-400 max-w-sm mx-auto leading-relaxed">
                The latest production APK is being compiled and prepared. It will be auto-detected and immediately available for direct download here once published to GitHub.
              </p>
              <div className="pt-2">
                <a
                  href={info.releaseUrl || `https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-brand-surface border border-brand-border text-xs font-semibold text-zinc-200 hover:text-white hover:border-brand-green/40 transition-all"
                >
                  <span>Track Releases on GitHub</span>
                  <ExternalLink className="h-3.5 w-3.5 text-zinc-400" />
                </a>
              </div>
            </div>
          )}

          <div className="flex items-center justify-between text-xs pt-1">
            {slug ? (
              <Link
                href={`/updates/${slug}`}
                className="text-zinc-400 hover:text-brand-green font-medium transition-colors"
              >
                View Changelog & Notes →
              </Link>
            ) : (
              <Link
                href="/updates"
                className="text-zinc-400 hover:text-brand-green font-medium transition-colors"
              >
                Browse Release History →
              </Link>
            )}

            {info.releaseUrl && (
              <a
                href={info.releaseUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 text-zinc-500 hover:text-zinc-300 font-medium transition-colors"
              >
                <span>GitHub Release</span>
                <ExternalLink className="h-3 w-3" />
              </a>
            )}
          </div>
        </div>
      </div>
    );
  }

  // iOS Card
  const hasIosDistribution = Boolean(info.downloadUrl && info.distributionStatus !== "coming_soon");

  return (
    <div
      className={`relative flex flex-col justify-between rounded-3xl border border-brand-border bg-gradient-to-b from-brand-surface to-brand-surface/70 p-6 sm:p-8 hover:border-brand-blue/40 transition-all shadow-xl ${className}`}
    >
      {/* Top Header */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-brand-blue/10 border border-brand-blue/20 text-brand-blue">
              <Apple className="h-6 w-6" />
            </div>
            <div>
              <h3 className="text-xl font-black text-white">Apple iOS</h3>
              <p className="text-xs text-zinc-400">App Store &amp; TestFlight Distribution</p>
            </div>
          </div>
          <ReleaseStatusBadge status={info.distributionStatus} platform="ios" />
        </div>

        {/* Version & OS details */}
        <div className="grid grid-cols-2 gap-2 pt-2 text-xs">
          <div className="rounded-xl border border-brand-border/60 bg-brand-surface/80 p-3">
            <span className="text-zinc-500 block uppercase font-bold text-[10px]">Target Version</span>
            <span className="font-mono font-bold text-white text-sm">{info.version}</span>
          </div>
          <div className="rounded-xl border border-brand-border/60 bg-brand-surface/80 p-3">
            <span className="text-zinc-500 block uppercase font-bold text-[10px]">Platform Status</span>
            <span className="font-medium text-brand-blue text-xs mt-0.5 block">
              {info.distributionStatus === "testflight"
                ? "TestFlight Beta"
                : info.distributionStatus === "available"
                ? "App Store Ready"
                : "Review In Progress"}
            </span>
          </div>
        </div>

        <div className="text-xs text-zinc-300 leading-relaxed">
          {info.minimumSupportedOs && (
            <p className="text-zinc-400">
              <strong className="text-zinc-200">Compatibility: </strong>
              {info.minimumSupportedOs}
            </p>
          )}
        </div>

        {/* iOS Notice: APK cannot be installed on iOS */}
        <div className="rounded-xl border border-brand-border bg-brand-elevated/40 p-3.5 text-xs text-zinc-400 flex items-start gap-2.5">
          <ShieldCheck className="h-4 w-4 text-brand-blue shrink-0 mt-0.5" />
          <p className="leading-relaxed">
            iOS devices require installation via Apple App Store or TestFlight. Android APK packages cannot be sideloaded directly on iPhone or iPad.
          </p>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="pt-6 space-y-3">
        {hasIosDistribution ? (
          <a
            href={info.downloadUrl!}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full inline-flex items-center justify-center gap-2.5 px-6 py-4 text-base font-bold text-white bg-brand-blue hover:bg-brand-blue-hover rounded-xl shadow-lg shadow-brand-blue/20 transition-all hover:scale-[1.01]"
          >
            <Apple className="h-5 w-5" />
            <span>
              {info.distributionStatus === "testflight"
                ? "Join TestFlight Beta"
                : "Download on App Store"}
            </span>
            <ExternalLink className="h-4 w-4" />
          </a>
        ) : (
          <div className="w-full p-4 rounded-xl border border-zinc-800 bg-zinc-950 text-center text-xs text-zinc-400">
            <Apple className="h-4 w-4 mx-auto mb-1 text-zinc-500" />
            <span className="font-semibold text-zinc-300 block mb-0.5">
              Apple App Store Listing in Review
            </span>
            <span className="text-[11px] text-zinc-500">
              Official iOS binary will be linked here immediately upon App Store review completion.
            </span>
          </div>
        )}

        <div className="flex items-center justify-between text-xs pt-1">
          {slug ? (
            <Link
              href={`/updates/${slug}`}
              className="text-zinc-400 hover:text-brand-blue font-medium transition-colors"
            >
              View Changelog & Notes →
            </Link>
          ) : (
            <Link
              href="/updates"
              className="text-zinc-400 hover:text-brand-blue font-medium transition-colors"
            >
              Browse Release History →
            </Link>
          )}

          <Link
            href="/support"
            className="text-zinc-500 hover:text-zinc-300 font-medium transition-colors"
          >
            Request iOS Beta Access
          </Link>
        </div>
      </div>
    </div>
  );
}
