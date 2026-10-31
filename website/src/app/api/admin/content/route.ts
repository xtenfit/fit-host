import { NextResponse } from "next/server";
import { verifyAdminAuthorization } from "@/lib/email/auth";
import { createAdminClient } from "@/lib/supabase/admin";

export async function GET(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const supabase = createAdminClient();
  const [{ data: announcements, error: announcementError }, { data: updates, error: updateError }] =
    await Promise.all([
      supabase.from("site_announcements").select("*").order("sort_order").order("updated_at", { ascending: false }),
      supabase.from("site_updates").select("*").order("published_at", { ascending: false, nullsFirst: false }),
    ]);

  if (announcementError || updateError) {
    return NextResponse.json({ error: announcementError?.message || updateError?.message }, { status: 500 });
  }
  return NextResponse.json({ announcements: announcements ?? [], updates: updates ?? [] });
}

export async function POST(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) return NextResponse.json({ error: "Not found" }, { status: 404 });

  try {
    const body = await request.json();
    const type = body.type === "update" ? "site_updates" : "site_announcements";
    const record = body.record;
    if (!record || typeof record !== "object") {
      return NextResponse.json({ error: "A content record is required." }, { status: 400 });
    }

    const supabase = createAdminClient();
    const payload = {
      ...record,
      updated_at: new Date().toISOString(),
      ...(type === "site_updates" && record.status === "published" && !record.published_at
        ? { published_at: new Date().toISOString() }
        : {}),
    };
    const { data, error } = await supabase.from(type).upsert(payload).select().single();
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
    return NextResponse.json({ record: data });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Unable to save content." }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  const auth = await verifyAdminAuthorization(request);
  if (!auth.authorized) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const { searchParams } = new URL(request.url);
  const type = searchParams.get("type") === "update" ? "site_updates" : "site_announcements";
  const id = searchParams.get("id");
  if (!id) return NextResponse.json({ error: "Content id is required." }, { status: 400 });

  const { error } = await createAdminClient().from(type).delete().eq("id", id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
