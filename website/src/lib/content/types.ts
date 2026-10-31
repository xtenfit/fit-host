export type ContentStatus = "draft" | "published" | "archived";

export interface SiteAnnouncement {
  id: string;
  name: string;
  status: ContentStatus;
  label: string;
  headline: string;
  message: string;
  primary_label: string | null;
  primary_url: string | null;
  secondary_label: string | null;
  secondary_url: string | null;
  icon: string;
  background_color: string;
  accent_color: string;
  text_color: string;
  starts_at: string | null;
  ends_at: string | null;
  sort_order: number;
  created_at?: string;
  updated_at?: string;
}

export interface SiteUpdate {
  id: string;
  slug: string;
  status: ContentStatus;
  title: string;
  summary: string;
  body: string;
  version: string | null;
  published_at: string | null;
  created_at?: string;
  updated_at?: string;
}
