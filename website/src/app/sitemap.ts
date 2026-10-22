import { MetadataRoute } from 'next';
import { getAllMobileReleases } from '@/lib/github/releases';
import { getAllGuides } from '@/lib/data/guides';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://fithost.amitrana.tech';
  const lastModified = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified,
      changeFrequency: 'weekly',
      priority: 1.0,
    },
    {
      url: `${baseUrl}/download`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.95,
    },
    {
      url: `${baseUrl}/features`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/how-it-works`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.8,
    },
    {
      url: `${baseUrl}/updates`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/guides`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/about`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.7,
    },
    {
      url: `${baseUrl}/support`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.7,
    },
    {
      url: `${baseUrl}/privacy`,
      lastModified,
      changeFrequency: 'yearly',
      priority: 0.5,
    },
    {
      url: `${baseUrl}/terms`,
      lastModified,
      changeFrequency: 'yearly',
      priority: 0.5,
    },
    {
      url: `${baseUrl}/account-deletion`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.7,
    },
    {
      url: `${baseUrl}/login`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.6,
    },
    {
      url: `${baseUrl}/signup`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.6,
    },
    {
      url: `${baseUrl}/forgot-password`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.5,
    },
  ];

  // Dynamic release routes (auto-detects GitHub releases or uses cached updates)
  const releases = await getAllMobileReleases();
  const releaseRoutes: MetadataRoute.Sitemap = releases.map((r, index) => {
    let date = lastModified;
    try {
      const parsed = new Date(r.publishedAt || r.displayDate);
      if (!isNaN(parsed.getTime())) date = parsed;
    } catch {}

    return {
      url: `${baseUrl}/updates/${r.slug}`,
      lastModified: date,
      changeFrequency: index === 0 ? 'weekly' : 'monthly',
      priority: index === 0 ? 0.9 : 0.75,
    };
  });

  // Dynamic guide routes with accurate guide updatedDate
  const guideRoutes: MetadataRoute.Sitemap = getAllGuides().map((g) => {
    let date = lastModified;
    try {
      const parsed = new Date(g.updatedDate);
      if (!isNaN(parsed.getTime())) date = parsed;
    } catch {}

    return {
      url: `${baseUrl}/guides/${g.slug}`,
      lastModified: date,
      changeFrequency: 'monthly',
      priority: g.featured ? 0.85 : 0.75,
    };
  });

  return [...staticRoutes, ...releaseRoutes, ...guideRoutes];
}
