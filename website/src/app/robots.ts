import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: [
          '/dashboard',
          '/admin',
          '/api/admin',
          '/auth/recovery',
          '/auth/callback',
        ],
      },
    ],
    sitemap: 'https://fithost.amitrana.tech/sitemap.xml',
  };
}
