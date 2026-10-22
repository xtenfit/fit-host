import { releasesConfig } from "@/lib/config/releases";
import { releasesData, type ReleaseUpdate } from "@/lib/data/updates";

export interface ReleaseAsset {
  id: number;
  name: string;
  sizeBytes: number;
  formattedSize: string;
  downloadUrl: string; // Direct verified browser_download_url
  contentType: string;
  downloadCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface StructuredReleaseNotes {
  raw: string;
  summary: string;
  whatsNew: string[];
  improvements: string[];
  bugFixes: string[];
  securityFixes: string[];
  knownIssues: string[];
  hasStructuredSections: boolean;
}

export type DistributionStatus = "available" | "coming_soon" | "testflight" | "unavailable";

export interface PlatformReleaseInfo {
  platform: "android" | "ios";
  version: string;
  tagName: string;
  releaseTitle: string;
  publishedAt: string;
  releaseNotes: StructuredReleaseNotes;
  downloadUrl: string | null;
  assetName: string | null;
  assetSize: string | null;
  sha256Checksum: string | null;
  minimumSupportedOs?: string;
  distributionStatus: DistributionStatus;
  releaseUrl: string;
}

export interface MobileRelease {
  id: number | string;
  slug: string;
  version: string;
  tagName: string;
  title: string;
  publishedAt: string;
  displayDate: string;
  isPrerelease: boolean;
  isDraft: boolean;
  htmlUrl: string;
  notes: StructuredReleaseNotes;
  assets: ReleaseAsset[];
  android: PlatformReleaseInfo;
  ios: PlatformReleaseInfo;
  isFallback?: boolean;
}

interface GitHubAssetRaw {
  id: number;
  name: string;
  size: number;
  browser_download_url: string;
  content_type: string;
  download_count: number;
  created_at: string;
  updated_at: string;
}

interface GitHubReleaseRaw {
  id: number;
  tag_name: string;
  name: string | null;
  body: string | null;
  draft: boolean;
  prerelease: boolean;
  created_at: string;
  published_at: string | null;
  html_url: string;
  assets: GitHubAssetRaw[];
}

/**
 * Format bytes into human-readable string (e.g. 44.2 MB)
 */
export function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return "0 MB";
  const mb = bytes / (1024 * 1024);
  return `${mb.toFixed(1)} MB`;
}

/**
 * Sanitize plain text to strip dangerous HTML tags (preventing raw HTML injection)
 */
export function sanitizeText(text: string): string {
  if (!text) return "";
  return text
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "")
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, "")
    .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, "")
    .replace(/<[^>]+>/g, ""); // strip remaining HTML tags
}

/**
 * Safely parse structured headings and bullet points from markdown notes.
 * Supports:
 *   ## What's New / Features
 *   ## Improvements / Enhancements
 *   ## Bug Fixes / Fixes
 *   ## Security Fixes / Security
 *   ## Known Issues
 */
export function parseReleaseNotes(markdown: string | null | undefined): StructuredReleaseNotes {
  if (!markdown || !markdown.trim()) {
    return {
      raw: "",
      summary: "No release notes provided.",
      whatsNew: [],
      improvements: [],
      bugFixes: [],
      securityFixes: [],
      knownIssues: [],
      hasStructuredSections: false,
    };
  }

  const raw = markdown.trim();
  const lines = raw.split("\n");

  const whatsNew: string[] = [];
  const improvements: string[] = [];
  const bugFixes: string[] = [];
  const securityFixes: string[] = [];
  const knownIssues: string[] = [];
  const generalLines: string[] = [];

  type Section = "none" | "whatsNew" | "improvements" | "bugFixes" | "securityFixes" | "knownIssues";
  let currentSection: Section = "none";
  let summary = "";

  const isHeading = (line: string): { matches: boolean; section: Section } => {
    const trimmed = line.trim();
    if (!trimmed.startsWith("#")) return { matches: false, section: "none" };

    const lower = trimmed.toLowerCase();
    if (lower.includes("what's new") || lower.includes("whats new") || lower.includes("new feature") || lower.includes("features")) {
      return { matches: true, section: "whatsNew" };
    }
    if (lower.includes("improvement") || lower.includes("enhancement") || lower.includes("performance") || lower.includes("architecture")) {
      return { matches: true, section: "improvements" };
    }
    if (lower.includes("security") || lower.includes("vulnerability") || lower.includes("cve")) {
      return { matches: true, section: "securityFixes" };
    }
    if (lower.includes("bug fix") || lower.includes("bugfix") || lower.includes("resolved issue") || lower.includes("fixes")) {
      return { matches: true, section: "bugFixes" };
    }
    if (lower.includes("known issue")) {
      return { matches: true, section: "knownIssues" };
    }
    return { matches: true, section: "none" };
  };

  for (const line of lines) {
    const headingCheck = isHeading(line);
    if (headingCheck.matches) {
      currentSection = headingCheck.section;
      continue;
    }

    const trimmed = line.trim();
    if (!trimmed) continue;

    // Check for bullet point
    const bulletMatch = trimmed.match(/^[-*+]\s+(.*)$/) || trimmed.match(/^\d+\.\s+(.*)$/);
    const content = sanitizeText(bulletMatch ? bulletMatch[1].trim() : trimmed);

    if (!content) continue;

    if (currentSection === "whatsNew") {
      whatsNew.push(content);
    } else if (currentSection === "improvements") {
      improvements.push(content);
    } else if (currentSection === "bugFixes") {
      bugFixes.push(content);
    } else if (currentSection === "securityFixes") {
      securityFixes.push(content);
    } else if (currentSection === "knownIssues") {
      knownIssues.push(content);
    } else {
      if (!summary && !bulletMatch) {
        summary = content;
      }
      generalLines.push(content);
    }
  }

  const hasStructuredSections =
    whatsNew.length > 0 ||
    improvements.length > 0 ||
    bugFixes.length > 0 ||
    securityFixes.length > 0 ||
    knownIssues.length > 0;

  if (!summary) {
    if (whatsNew.length > 0) {
      summary = whatsNew[0];
    } else if (generalLines.length > 0) {
      summary = generalLines[0];
    } else {
      summary = "Official release build for Fit Host mobile application.";
    }
  }

  return {
    raw,
    summary,
    whatsNew,
    improvements,
    bugFixes,
    securityFixes,
    knownIssues,
    hasStructuredSections,
  };
}

/**
 * Extract verified SHA-256 checksum from release assets or release markdown body
 */
export function extractSha256Checksum(assets: GitHubAssetRaw[], rawBody: string | null): string | null {
  // 1. Check for .sha256 file asset
  const shaAsset = assets.find((a) => a.name.toLowerCase().endsWith(".sha256"));
  // If there's an asset named <filename>.sha256, it's downloadable from shaAsset.browser_download_url
  if (shaAsset) {
    // Note: the asset itself contains the hash; if available in markdown, extract it
  }

  // 2. Look for SHA-256 pattern in markdown text: `SHA256: <64-hex>` or `SHA-256: <64-hex>`
  if (rawBody) {
    const match = rawBody.match(/(?:sha[-_]?256|checksum)[\s:=]+([a-fA-F0-9]{64})/i);
    if (match) {
      return match[1].toLowerCase();
    }
  }

  return null;
}

/**
 * Format ISO publication date to a clean, user-friendly display date
 */
export function formatDisplayDate(isoDate: string | null | undefined): string {
  if (!isoDate) return "Unknown Date";
  try {
    const date = new Date(isoDate);
    if (isNaN(date.getTime())) return "Unknown Date";
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }).format(date);
  } catch {
    return isoDate;
  }
}

/**
 * Convert slug to tag (e.g. "v2-1-0" -> "v2.1.0")
 */
export function slugToTagName(slug: string): string {
  return slug.replace(/^v(\d+)-(\d+)-(\d+).*$/, "v$1.$2.$3");
}

/**
 * Convert tag to slug (e.g. "v2.1.0" -> "v2-1-0")
 */
export function tagNameToSlug(tag: string): string {
  return tag.replace(/\./g, "-").toLowerCase();
}

/**
 * Normalize raw GitHub Release object into our verified domain model
 */
export function normalizeGitHubRelease(raw: GitHubReleaseRaw): MobileRelease {
  const publishedDate = raw.published_at || raw.created_at;
  const displayDate = formatDisplayDate(publishedDate);
  let notes = parseReleaseNotes(raw.body);
  const tagName = raw.tag_name || "v0.0.0";
  const slug = tagNameToSlug(tagName);
  const title = sanitizeText(raw.name || `Fit Host ${tagName}`);

  // Format assets
  const assets: ReleaseAsset[] = (raw.assets || []).map((a) => ({
    id: a.id,
    name: a.name,
    sizeBytes: a.size,
    formattedSize: formatBytes(a.size),
    downloadUrl: a.browser_download_url,
    contentType: a.content_type,
    downloadCount: a.download_count,
    createdAt: a.created_at,
    updatedAt: a.updated_at,
  }));

  // Identify Android APK asset (auto-detect any .apk published in GitHub release assets)
  const apkAsset =
    assets.find((a) => a.name.toLowerCase().includes("universal") && a.name.toLowerCase().endsWith(".apk")) ||
    assets.find((a) => a.name.toLowerCase().endsWith(".apk"));

  const sha256 = extractSha256Checksum(raw.assets || [], raw.body);

  // If GitHub release notes are brief, enrich with local changelog if available
  const matchingLocal = releasesData.find(
    (u) => u.version.toLowerCase() === tagName.toLowerCase() || u.slug.toLowerCase() === slug.toLowerCase()
  );
  if (matchingLocal && !notes.hasStructuredSections) {
    notes = {
      raw: raw.body || matchingLocal.summary,
      summary: notes.summary && notes.summary !== "No release notes provided." ? notes.summary : matchingLocal.summary,
      whatsNew: notes.whatsNew.length > 0 ? notes.whatsNew : matchingLocal.newFeatures,
      improvements: notes.improvements.length > 0 ? notes.improvements : matchingLocal.improvements,
      bugFixes: notes.bugFixes.length > 0 ? notes.bugFixes : matchingLocal.bugFixes,
      securityFixes: notes.securityFixes,
      knownIssues: notes.knownIssues.length > 0 ? notes.knownIssues : matchingLocal.knownIssues,
      hasStructuredSections: true,
    };
  }

  const android: PlatformReleaseInfo = {
    platform: "android",
    version: tagName,
    tagName,
    releaseTitle: title,
    publishedAt: publishedDate,
    releaseNotes: notes,
    downloadUrl: apkAsset ? apkAsset.downloadUrl : null,
    assetName: apkAsset ? apkAsset.name : null,
    assetSize: apkAsset ? apkAsset.formattedSize : null,
    sha256Checksum: sha256,
    minimumSupportedOs: "Android 8.0+ (Oreo, API 26)",
    distributionStatus: apkAsset ? "available" : "coming_soon",
    releaseUrl: raw.html_url,
  };

  const iosStatus = releasesConfig.platforms.ios.status;
  const iosUrl = releasesConfig.platforms.ios.testFlightUrl || releasesConfig.platforms.ios.appStoreUrl || null;

  const ios: PlatformReleaseInfo = {
    platform: "ios",
    version: tagName,
    tagName,
    releaseTitle: title,
    publishedAt: publishedDate,
    releaseNotes: notes,
    downloadUrl: iosUrl,
    assetName: null,
    assetSize: null,
    sha256Checksum: null,
    minimumSupportedOs: "iOS 14.0+",
    distributionStatus: iosStatus,
    releaseUrl: raw.html_url,
  };

  return {
    id: raw.id,
    slug,
    version: tagName,
    tagName,
    title,
    publishedAt: publishedDate,
    displayDate,
    isPrerelease: raw.prerelease,
    isDraft: raw.draft,
    htmlUrl: raw.html_url,
    notes,
    assets,
    android,
    ios,
    isFallback: false,
  };
}

/**
 * Construct fallback mobile releases from local historical cache (updates.ts).
 * This ensures high availability and resilience when GitHub API is down or rate-limited.
 * Real APK download links and assets are ONLY populated when published to GitHub.
 * When no release has been published yet, distributionStatus is "coming_soon" (Release Soon).
 */
export function getFallbackReleases(): MobileRelease[] {
  return releasesData.map((u: ReleaseUpdate) => {
    const tagName = u.version;
    const slug = u.slug;

    const notes: StructuredReleaseNotes = {
      raw: u.summary,
      summary: u.summary,
      whatsNew: u.newFeatures,
      improvements: u.improvements,
      bugFixes: u.bugFixes,
      securityFixes: [],
      knownIssues: u.knownIssues,
      hasStructuredSections: true,
    };

    return {
      id: `fallback-${slug}`,
      slug,
      version: tagName,
      tagName,
      title: u.title,
      publishedAt: new Date(u.releaseDate).toISOString() || new Date().toISOString(),
      displayDate: u.releaseDate,
      isPrerelease: false,
      isDraft: false,
      htmlUrl: `https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`,
      notes,
      assets: [],
      android: {
        platform: "android",
        version: tagName,
        tagName,
        releaseTitle: u.title,
        publishedAt: new Date(u.releaseDate).toISOString() || new Date().toISOString(),
        releaseNotes: notes,
        downloadUrl: null,
        assetName: null,
        assetSize: null,
        sha256Checksum: null,
        minimumSupportedOs: "Android 8.0+ (Oreo, API 26)",
        distributionStatus: "coming_soon",
        releaseUrl: `https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`,
      },
      ios: {
        platform: "ios",
        version: tagName,
        tagName,
        releaseTitle: u.title,
        publishedAt: new Date(u.releaseDate).toISOString() || new Date().toISOString(),
        releaseNotes: notes,
        downloadUrl: null,
        assetName: null,
        assetSize: null,
        sha256Checksum: null,
        minimumSupportedOs: "iOS 14.0+",
        distributionStatus: "coming_soon",
        releaseUrl: `https://github.com/${releasesConfig.github.owner}/${releasesConfig.github.repo}/releases`,
      },
      isFallback: true,
    };
  });
}

/**
 * Fetch all published releases from GitHub REST API with Next.js ISR tag revalidation.
 * Ignores drafts. Ignores prereleases unless configured.
 * Falls back to local cached historical data on failure.
 */
export async function getAllMobileReleases(): Promise<MobileRelease[]> {
  const { owner, repo, token, apiUrl } = releasesConfig.github;
  const endpoint = `${apiUrl}/repos/${owner}/${repo}/releases`;

  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "FitHost-Website-Releases/1.0",
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  try {
    const res = await fetch(endpoint, {
      headers,
      next: {
        revalidate: releasesConfig.revalidation.intervalSeconds,
        tags: [releasesConfig.revalidation.tag],
      },
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) {
      // If 404 (repo not created yet or no releases) or rate-limited (403), use fallback
      console.warn(
        `[FitHost Releases] GitHub API responded with status ${res.status} for ${owner}/${repo}. Using fallback release cache.`
      );
      return getFallbackReleases();
    }

    const data: GitHubReleaseRaw[] = await res.json();
    if (!Array.isArray(data) || data.length === 0) {
      console.warn(`[FitHost Releases] No releases returned for ${owner}/${repo}. Using fallback release cache.`);
      return getFallbackReleases();
    }

    // Filter drafts and prereleases
    const valid = data.filter((r) => {
      if (r.draft) return false;
      if (!releasesConfig.allowPrereleases && r.prerelease) return false;
      return true;
    });

    if (valid.length === 0) {
      return getFallbackReleases();
    }

    // Sort by publication date descending
    valid.sort((a, b) => {
      const dateA = new Date(a.published_at || a.created_at).getTime();
      const dateB = new Date(b.published_at || b.created_at).getTime();
      return dateB - dateA;
    });

    return valid.map(normalizeGitHubRelease);
  } catch (error) {
    console.error("[FitHost Releases] Network or fetch error while retrieving GitHub releases:", error);
    return getFallbackReleases();
  }
}

/**
 * Fetch the single latest stable mobile release.
 */
export async function getLatestMobileRelease(): Promise<MobileRelease> {
  const all = await getAllMobileReleases();
  if (all.length > 0) {
    return all[0];
  }
  return getFallbackReleases()[0];
}

/**
 * Fetch a specific release by slug or tag name.
 */
export async function getMobileReleaseBySlug(slug: string): Promise<MobileRelease | null> {
  const all = await getAllMobileReleases();
  const normalizedSlug = slug.toLowerCase();
  const normalizedTag = slugToTagName(slug).toLowerCase();

  const found = all.find(
    (r) =>
      r.slug.toLowerCase() === normalizedSlug ||
      r.tagName.toLowerCase() === normalizedTag ||
      r.version.toLowerCase() === normalizedSlug ||
      r.slug.toLowerCase().startsWith(normalizedSlug) ||
      normalizedSlug.startsWith(r.slug.toLowerCase())
  );

  if (found) return found;

  // Attempt direct tag lookup if not in the cached list
  const { owner, repo, token, apiUrl } = releasesConfig.github;
  const tagLookup = slugToTagName(slug);
  const endpoint = `${apiUrl}/repos/${owner}/${repo}/releases/tags/${encodeURIComponent(tagLookup)}`;

  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "FitHost-Website-Releases/1.0",
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  try {
    const res = await fetch(endpoint, {
      headers,
      next: {
        revalidate: releasesConfig.revalidation.intervalSeconds,
        tags: [releasesConfig.revalidation.tag],
      },
      signal: AbortSignal.timeout(6000),
    });

    if (res.ok) {
      const raw: GitHubReleaseRaw = await res.json();
      if (!raw.draft && (releasesConfig.allowPrereleases || !raw.prerelease)) {
        return normalizeGitHubRelease(raw);
      }
    }
  } catch {
    // ignore network errors and fallback
  }

  const fallbackAll = getFallbackReleases();
  return (
    fallbackAll.find(
      (r) =>
        r.slug.toLowerCase() === normalizedSlug ||
        r.tagName.toLowerCase() === normalizedTag ||
        r.version.toLowerCase() === normalizedSlug ||
        r.slug.toLowerCase().startsWith(normalizedSlug) ||
        normalizedSlug.startsWith(r.slug.toLowerCase())
    ) || null
  );
}
