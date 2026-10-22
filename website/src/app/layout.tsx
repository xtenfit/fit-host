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
    "Fit Host is a modern mobile fitness and workout tracking application for Android and iOS. Features a 20-step animated setup wizard, 1,324+ exercises with looping GIF demonstrations and anatomical muscle targeting, offline Drift SQLite storage, and instant cloud sync.",
  keywords: [
    "Fit Host",
    "fitness tracker",
    "workout logger",
    "exercise gif library",
    "animated workout guide",
    "body composition circumference tracker",
    "hydration tracker",
    "nutrition planner",
    "local data storage",
    "Drift database",
    "Supabase fitness",
    "Flutter fitness app",
  ],
  authors: [{ name: "Fit Host Team" }],
  creator: "Fit Host",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://fithost.amitrana.tech",
    siteName: "Fit Host",
    title: "Fit Host — Premium Fitness Tracking, 1,324+ Exercise GIFs & Workouts",
    description:
      "Fast fitness tracking with secure cloud sync, 1,324+ exercise animated GIFs, personalized setup wizard, and offline Drift SQLite storage.",
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
      "Fast fitness tracking with 1,324+ exercise animated GIFs, personalized setup wizard, and secure cloud synchronization.",
    images: ["/images/screenshots/home.png"],
  },
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    shortcut: "/favicon.ico",
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
  robots: {
    index: true,
    follow: true,
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://fithost.amitrana.tech/#organization",
      name: "Fit Host",
      url: "https://fithost.amitrana.tech",
      logo: "https://fithost.amitrana.tech/fit_host_icon.png",
      sameAs: ["https://github.com/xtenfit/fit-host"],
    },
    {
      "@type": "MobileApplication",
      "@id": "https://fithost.amitrana.tech/#app",
      name: "Fit Host",
      operatingSystem: "Android 8.0+, iOS 14.0+",
      applicationCategory: "HealthAndFitnessApplication",
      installUrl: "https://fithost.amitrana.tech/download",
      screenshot: "https://fithost.amitrana.tech/images/screenshots/home.png",
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
      description:
        "Fast fitness tracking with secure cloud sync, 1,324+ exercise animated GIFs, 20-step personalized setup wizard, hydration tracking, and offline Drift SQLite storage.",
    },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" type="image/png" sizes="192x192" href="/icon-192.png" />
        <link rel="icon" type="image/png" sizes="512x512" href="/icon-512.png" />
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="min-h-screen bg-brand-bg text-brand-text flex flex-col antialiased selection:bg-brand-green selection:text-black">
        <AnnouncementBanner />
        <Navbar />
        <main className="flex-1 flex flex-col">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
