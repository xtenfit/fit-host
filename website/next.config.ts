import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  turbopack: {
    root: path.resolve(__dirname),
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "eedubttdylyqrhyeikwb.supabase.co",
      },
      {
        protocol: "https",
        hostname: "lh3.googleusercontent.com",
      },
    ],
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
