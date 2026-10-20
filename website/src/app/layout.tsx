import type { Metadata, Viewport } from "next";
import "./globals.css";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import AnnouncementBanner from "@/components/marketing/AnnouncementBanner";

export const viewport: Viewport = {
  themeColor: "#0A0F0D",
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
};

export const metadata: Metadata = {
  metadataBase: new URL("https://fithost.amitrana.tech"),
  title: {
    default: "Fit Host — Premium Fitness Tracking, Workouts & Wellness",
    template: "%s | Fit Host",
  },
  description:
    "Fit Host is a modern fitness tracking application for iOS and Android featuring fast fitness tracking with secure cloud sync, hydration logging, nutrition planning, and local data storage.",
  keywords: [
    "Fit Host",
    "fitness tracker",
    "workout logger",
    "hydration tracker",
    "nutrition planner",
    "local data storage",
    "Drift database",
    "Supabase fitness",
  ],
  authors: [{ name: "Fit Host Team" }],
  creator: "Fit Host",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://fithost.amitrana.tech",
    siteName: "Fit Host",
    title: "Fit Host — Premium Fitness Tracking, Workouts & Wellness",
    description:
      "Fast fitness tracking with secure cloud sync, hydration logs, and guest mode with local data storage.",
    images: [
      {
        url: "/images/screenshots/home.png",
        width: 1200,
        height: 630,
        alt: "Fit Host Dashboard Preview",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Fit Host — Premium Fitness Tracking",
    description:
      "Fast fitness tracking with local data storage and secure cloud synchronization.",
    images: ["/images/screenshots/home.png"],
  },
  icons: {
    icon: "/fit_host_icon.png",
    shortcut: "/fit_host_icon.png",
    apple: "/fit_host_icon.png",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-brand-bg text-brand-text flex flex-col antialiased selection:bg-brand-green selection:text-black">
        <AnnouncementBanner />
        <Navbar />
        <main className="flex-1 flex flex-col">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
