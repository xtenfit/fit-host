import React from "react";
import { CheckCircle2, Clock, AlertCircle } from "lucide-react";
import type { DistributionStatus } from "@/lib/github/releases";

interface ReleaseStatusProps {
  status: DistributionStatus;
  platform?: "android" | "ios";
  className?: string;
}

export default function ReleaseStatusBadge({ status, platform, className = "" }: ReleaseStatusProps) {
  switch (status) {
    case "available":
      return (
        <span
          className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full bg-brand-green/10 text-brand-green border border-brand-green/30 ${className}`}
        >
          <CheckCircle2 className="h-3.5 w-3.5 text-brand-green" />
          <span>Available Now</span>
        </span>
      );
    case "testflight":
      return (
        <span
          className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full bg-brand-blue/15 text-brand-blue border border-brand-blue/30 ${className}`}
        >
          <CheckCircle2 className="h-3.5 w-3.5 text-brand-blue" />
          <span>TestFlight Beta</span>
        </span>
      );
    case "coming_soon":
      return (
        <span
          className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full bg-brand-green/10 text-brand-green border border-brand-green/30 ${className}`}
        >
          <Clock className="h-3.5 w-3.5 text-brand-green" />
          <span>{platform === "ios" ? "Coming Soon to App Store" : "Release Soon"}</span>
        </span>
      );
    case "unavailable":
    default:
      return (
        <span
          className={`inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full bg-zinc-900 text-zinc-500 border border-zinc-800 ${className}`}
        >
          <AlertCircle className="h-3.5 w-3.5 text-zinc-500" />
          <span>Build Pending</span>
        </span>
      );
  }
}
