"use client";

import { useEffect } from "react";
import { trackException } from "@/lib/analytics/posthog";

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    trackException(error, { digest: error.digest });
  }, [error]);

  return (
    <div className="min-h-[60vh] flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-brand-surface border border-white/10 rounded-2xl p-6 text-center shadow-xl">
        <div className="w-12 h-12 rounded-full bg-brand-green/10 text-brand-green flex items-center justify-center mx-auto mb-4">
          <svg
            className="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <h2 className="text-xl font-bold text-white mb-2">Something went wrong</h2>
        <p className="text-sm text-brand-muted mb-6">
          An unexpected error occurred. Our monitoring system has recorded diagnostic details without personal data.
        </p>
        <button
          onClick={() => reset()}
          className="px-6 py-2.5 rounded-xl bg-brand-green text-black font-semibold text-sm hover:opacity-90 transition-opacity cursor-pointer"
        >
          Try Again
        </button>
      </div>
    </div>
  );
}

