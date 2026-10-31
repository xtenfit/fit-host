"use client";

import { useEffect } from "react";
import { trackException } from "@/lib/analytics/posthog";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    trackException(error, { digest: error.digest, fatal: true });
  }, [error]);

  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-[#0A0F0D] text-white flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-[#141A17] border border-white/10 rounded-2xl p-6 text-center shadow-2xl">
          <h2 className="text-xl font-bold mb-2">Application Error</h2>
          <p className="text-sm text-gray-400 mb-6">
            A critical error occurred while rendering the page. Diagnostic context has been recorded safely.
          </p>
          <button
            onClick={() => reset()}
            className="px-6 py-2.5 rounded-xl bg-[#00E676] text-black font-semibold text-sm hover:opacity-90 cursor-pointer"
          >
            Reload Application
          </button>
        </div>
      </body>
    </html>
  );
}

