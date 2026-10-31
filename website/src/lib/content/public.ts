import { createClient } from "@/lib/supabase/server";
import type { SiteAnnouncement, SiteUpdate } from "./types";

export async function getActiveAnnouncement(): Promise<SiteAnnouncement | null> {
  try {
    const { data, error } = await (await createClient())
      .from("site_announcements")
      .select("*")
      .eq("status", "published")
      .order("sort_order")
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error || !data) return null;
    return data as SiteAnnouncement;
  } catch {
    return null;
  }
}

export async function getPublishedUpdates(): Promise<SiteUpdate[]> {
  try {
    const { data, error } = await (await createClient())
      .from("site_updates")
      .select("*")
      .eq("status", "published")
      .order("published_at", { ascending: false, nullsFirst: false });
    if (error) return [];
    return (data ?? []) as SiteUpdate[];
  } catch {
    return [];
  }
}

export async function getPublishedUpdate(slug: string): Promise<SiteUpdate | null> {
  try {
    const { data, error } = await (await createClient())
      .from("site_updates")
      .select("*")
      .eq("status", "published")
      .eq("slug", slug)
      .maybeSingle();
    if (error || !data) return null;
    return data as SiteUpdate;
  } catch {
    return null;
  }
}
