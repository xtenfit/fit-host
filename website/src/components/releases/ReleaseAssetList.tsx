import React from "react";
import { Download, FileCode, CheckCircle2, Copy, Clock } from "lucide-react";
import type { ReleaseAsset } from "@/lib/github/releases";

interface ReleaseAssetListProps {
  assets: ReleaseAsset[];
  sha256Checksum?: string | null;
  className?: string;
}

export default function ReleaseAssetList({
  assets,
  sha256Checksum,
  className = "",
}: ReleaseAssetListProps) {
  if (!assets || assets.length === 0) {
    return (
      <div className={`p-6 rounded-2xl border border-brand-border bg-brand-surface/40 text-center space-y-2 ${className}`}>
        <div className="inline-flex items-center gap-2 text-xs font-semibold text-brand-green bg-brand-green/10 px-3 py-1 rounded-full border border-brand-green/30">
          <Clock className="h-3.5 w-3.5 text-brand-green" />
          <span>Release Assets Pending</span>
        </div>
        <p className="text-xs text-zinc-400 max-w-md mx-auto leading-relaxed">
          Official APK build artifacts and checksum files will be automatically listed here once published to GitHub Releases.
        </p>
      </div>
    );
  }

  return (
    <div className={`space-y-3 ${className}`}>
      <div className="text-xs font-bold uppercase tracking-wider text-zinc-400">
        Verified Release Assets ({assets.length})
      </div>

      <div className="divide-y divide-brand-border/60 rounded-2xl border border-brand-border bg-brand-surface/70 overflow-hidden">
        {assets.map((asset) => {
          const isApk = asset.name.toLowerCase().endsWith(".apk");

          return (
            <div
              key={asset.id}
              className="flex flex-col sm:flex-row sm:items-center justify-between p-4 gap-3 hover:bg-brand-elevated/40 transition-colors"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div
                  className={`p-2.5 rounded-xl border ${
                    isApk
                      ? "bg-brand-green/10 border-brand-green/30 text-brand-green"
                      : "bg-brand-elevated border-brand-border text-zinc-400"
                  }`}
                >
                  <FileCode className="h-4 w-4" />
                </div>
                <div className="min-w-0">
                  <div className="text-sm font-bold text-white truncate font-mono">
                    {asset.name}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-zinc-400 mt-0.5">
                    <span>{asset.formattedSize}</span>
                    {asset.downloadCount > 0 && (
                      <>
                        <span>•</span>
                        <span>{asset.downloadCount.toLocaleString()} downloads</span>
                      </>
                    )}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2 self-end sm:self-auto shrink-0">
                <a
                  href={asset.downloadUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold rounded-lg transition-all ${
                    isApk
                      ? "bg-brand-green text-black hover:bg-brand-green-hover shadow-sm hover:shadow-brand-green/20"
                      : "bg-brand-elevated text-zinc-200 hover:text-white border border-brand-border hover:border-zinc-500"
                  }`}
                >
                  <Download className="h-3.5 w-3.5" />
                  <span>Download {isApk ? "APK" : "Asset"}</span>
                </a>
              </div>
            </div>
          );
        })}
      </div>

      {/* Verified SHA-256 Checksum Display */}
      {sha256Checksum && (
        <div className="rounded-xl border border-brand-border bg-zinc-950 p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
          <div className="flex items-center gap-2 text-zinc-400">
            <CheckCircle2 className="h-4 w-4 text-brand-green shrink-0" />
            <span className="font-semibold text-zinc-300">Verified SHA-256:</span>
            <span className="font-mono text-[11px] text-zinc-400 break-all select-all">
              {sha256Checksum}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
