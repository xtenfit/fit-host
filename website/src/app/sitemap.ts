import { MetadataRoute } from 'next';
import { getAllPublishedReleases } from '@/lib/data/updates';
import { getAllGuides } from '@/lib/data/guides';

export default function sitemap(): MetadataRoute.Sitemap {
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
  ];

  // Dynamic release routes
  const releaseRoutes: MetadataRoute.Sitemap = getAllPublishedReleases().map((r) => ({
    url: `${baseUrl}/updates/${r.slug}`,
    lastModified,
    changeFrequency: 'monthly',
    priority: 0.8,
  }));

  // Dynamic guide routes
  const guideRoutes: MetadataRoute.Sitemap = getAllGuides().map((g) => ({
    url: `${baseUrl}/guides/${g.slug}`,
    lastModified,
    changeFrequency: 'monthly',
    priority: 0.8,
  }));

  return [...staticRoutes, ...releaseRoutes, ...guideRoutes];
}
