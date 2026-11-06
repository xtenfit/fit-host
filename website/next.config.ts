import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  turbopack: {
    root: path.resolve(__dirname),
  },
  compress: true,
  poweredByHeader: false,
  images: {
    formats: ["image/avif", "image/webp"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "eedubttdylyqrhyeikwb.supabase.co",
      },
      {
        protocol: "https",
        hostname: "api.amitrana.tech",
      },
      {
        protocol: "https",
        hostname: "lh3.googleusercontent.com",
      },
    ],
  },
  async headers() {
    return [
      {
        source: "/images/:path*",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=31536000, immutable",
          },
        ],
      },
      {
        source: "/(favicon.ico|icon-192.png|icon-512.png|apple-touch-icon.png|fit_host_icon.png)",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=31536000, immutable",
          },
        ],
      },
    ];
  },
  async redirects() {
    return [
      {
        source: "/release-notes",
        destination: "/updates",
        permanent: true,
      },
      {
        source: "/releases",
        destination: "/updates",
        permanent: true,
      },
      {
        source: "/changelog",
        destination: "/updates",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
