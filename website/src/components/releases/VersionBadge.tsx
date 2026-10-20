import React from "react";
import { Tag } from "lucide-react";

interface VersionBadgeProps {
  version: string;
  isPrerelease?: boolean;
  isLatest?: boolean;
  isFallback?: boolean;
  className?: string;
}

export default function VersionBadge({
  version,
  isPrerelease = false,
  isLatest = false,
  isFallback = false,
  className = "",
}: VersionBadgeProps) {
  if (isPrerelease) {
    return (
      <span
        className={`inline-flex items-center gap-1.5 font-mono text-xs font-bold px-3 py-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/30 ${className}`}
      >
        <Tag className="h-3 w-3" />
        <span>{version} (Pre-release)</span>
      </span>
    );
  }

  return (
    <span
      className={`inline-flex items-center gap-1.5 font-mono text-xs font-bold px-3 py-1 rounded-full ${
        isLatest
          ? "bg-brand-green/15 text-brand-green border border-brand-green/40 shadow-sm shadow-brand-green/10"
          : "bg-brand-surface text-zinc-300 border border-brand-border"
      } ${className}`}
    >
      <Tag className="h-3 w-3" />
      <span>{version}</span>
      {isLatest && (
        <span className="text-[10px] font-sans font-extrabold uppercase px-1.5 py-0.2 rounded bg-brand-green text-black ml-1">
          Latest
        </span>
      )}
      {isFallback && (
        <span
          className="text-[10px] font-sans font-medium text-zinc-400 ml-0.5"
          title="Served from cached verified build records"
        >
          • Verified
        </span>
      )}
    </span>
  );
}
