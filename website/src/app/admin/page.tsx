import { Suspense } from "react";
import AdminHubClient from "@/components/admin/AdminHubClient";

export const metadata = {
  title: "Admin Hub | Fit Host",
  robots: {
    index: false,
    follow: false,
  },
};

export default function AdminHubPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-7xl px-4 py-16 text-center text-zinc-500 text-sm">
          Loading Fit Host Admin Hub...
        </div>
      }
    >
      <AdminHubClient />
    </Suspense>
  );
}
