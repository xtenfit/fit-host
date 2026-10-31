"use client";

import { useEffect, useMemo, useState } from "react";
import { Eye, Megaphone, Newspaper, Plus, Save, Trash2 } from "lucide-react";
import type { SiteAnnouncement, SiteUpdate } from "@/lib/content/types";

const emptyAnnouncement: Omit<SiteAnnouncement, "id"> = {
  name: "New promotion",
  status: "draft",
  label: "Promotion",
  headline: "Your headline",
  message: "Your announcement message",
  primary_label: "Download",
  primary_url: "/download",
  secondary_label: "Learn more",
  secondary_url: "/updates",
  icon: "sparkles",
  background_color: "#121820",
  accent_color: "#00E676",
  text_color: "#FFFFFF",
  starts_at: null,
  ends_at: null,
  sort_order: 0,
};

const emptyUpdate: Omit<SiteUpdate, "id"> = {
  slug: "new-update",
  status: "draft",
  title: "New Fit Host update",
  summary: "Describe what changed in this update.",
  body: "Write the full update here.",
  version: null,
  published_at: null,
};

export default function ContentCmsManager() {
  const [announcements, setAnnouncements] = useState<SiteAnnouncement[]>([]);
  const [updates, setUpdates] = useState<SiteUpdate[]>([]);
  const [kind, setKind] = useState<"announcement" | "update">("announcement");
  const [announcement, setAnnouncement] = useState<SiteAnnouncement | null>(null);
  const [update, setUpdate] = useState<SiteUpdate | null>(null);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    try {
      const response = await fetch("/api/admin/content");
      if (response.ok) {
        const data = await response.json();
        setAnnouncements(data.announcements ?? []);
        setUpdates(data.updates ?? []);
      }
    } catch (e) {
      console.error("Failed to load CMS content", e);
    } finally {
      setLoading(false);
    }
  }

  // Initial load
  useEffect(() => {
    void Promise.resolve().then(load);
  }, []);

  const preview = useMemo(() => {
    if (kind === "update") return null;
    return announcement ?? ({ id: "preview", ...emptyAnnouncement } as SiteAnnouncement);
  }, [announcement, kind]);

  async function save() {
    const record = kind === "announcement" ? announcement : update;
    if (!record) return;
    const response = await fetch("/api/admin/content", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ type: kind, record }),
    });
    const data = await response.json();
    if (!response.ok) {
      setMessage(data.error ?? "Unable to save content.");
      return;
    }
    setMessage("Saved successfully.");
    await load();
  }

  async function remove() {
    const record = kind === "announcement" ? announcement : update;
    if (!record || !confirm("Delete this content permanently?")) return;
    await fetch(`/api/admin/content?type=${kind}&id=${record.id}`, { method: "DELETE" });
    setAnnouncement(null);
    setUpdate(null);
    await load();
  }

  function editAnnouncement(value: SiteAnnouncement) {
    setKind("announcement");
    setAnnouncement(value);
    setMessage("");
  }
  function editUpdate(value: SiteUpdate) {
    setKind("update");
    setUpdate(value);
    setMessage("");
  }

  return (
    <div className="space-y-8 text-white">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-brand-border">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-brand-green">Website CMS</p>
          <h2 className="mt-1 text-2xl font-black">Promotions &amp; Announcement Banners</h2>
          <p className="mt-1 text-xs text-zinc-400">
            Publish top announcement banners and version updates on the live website.
          </p>
        </div>
        <div className="flex flex-wrap gap-2.5">
          <button
            onClick={() => {
              setKind("announcement");
              setAnnouncement({ id: crypto.randomUUID(), ...emptyAnnouncement });
              setUpdate(null);
            }}
            className="inline-flex items-center gap-2 rounded-xl bg-brand-green px-4 py-2 text-xs font-bold text-black hover:opacity-90 transition-opacity"
          >
            <Plus className="h-3.5 w-3.5" /> New banner
          </button>
          <button
            onClick={() => {
              setKind("update");
              setUpdate({ id: crypto.randomUUID(), ...emptyUpdate });
              setAnnouncement(null);
            }}
            className="inline-flex items-center gap-2 rounded-xl border border-brand-border bg-brand-surface px-4 py-2 text-xs font-bold text-zinc-200 hover:text-white hover:border-zinc-700 transition-colors"
          >
            <Plus className="h-3.5 w-3.5" /> New update
          </button>
        </div>
      </div>

      <section className="grid gap-6 lg:grid-cols-[280px_1fr_360px]">
        <aside className="space-y-5">
          <div>
            <h3 className="mb-2.5 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-zinc-400">
              <Megaphone className="h-3.5 w-3.5 text-brand-green" /> Banners ({announcements.length})
            </h3>
            <div className="space-y-2">
              {loading ? (
                <p className="text-xs text-zinc-500">Loading…</p>
              ) : announcements.length === 0 ? (
                <p className="text-xs text-zinc-500">No banners created yet.</p>
              ) : (
                announcements.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => editAnnouncement(item)}
                    className={`w-full rounded-xl border p-3 text-left transition-colors ${
                      announcement?.id === item.id
                        ? "border-brand-green bg-brand-green/10"
                        : "border-brand-border bg-brand-surface hover:border-brand-green/50"
                    }`}
                  >
                    <p className="truncate text-sm font-semibold">{item.name}</p>
                    <div className="mt-1 flex items-center justify-between text-xs">
                      <span className="text-zinc-500">{item.label}</span>
                      <span
                        className={`rounded px-1.5 py-0.5 text-[10px] font-bold uppercase ${
                          item.status === "published"
                            ? "bg-brand-green/20 text-brand-green"
                            : item.status === "archived"
                            ? "bg-zinc-800 text-zinc-500"
                            : "bg-amber-500/20 text-amber-400"
                        }`}
                      >
                        {item.status}
                      </span>
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>

          <div>
            <h3 className="mb-2.5 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-zinc-400">
              <Newspaper className="h-3.5 w-3.5 text-brand-blue" /> Updates ({updates.length})
            </h3>
            <div className="space-y-2">
              {updates.length === 0 ? (
                <p className="text-xs text-zinc-500">No updates created yet.</p>
              ) : (
                updates.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => editUpdate(item)}
                    className={`w-full rounded-xl border p-3 text-left transition-colors ${
                      update?.id === item.id
                        ? "border-brand-blue bg-brand-blue/10"
                        : "border-brand-border bg-brand-surface hover:border-brand-blue/50"
                    }`}
                  >
                    <p className="truncate text-sm font-semibold">{item.title}</p>
                    <div className="mt-1 flex items-center justify-between text-xs">
                      <span className="text-zinc-500">{item.version || item.slug}</span>
                      <span
                        className={`rounded px-1.5 py-0.5 text-[10px] font-bold uppercase ${
                          item.status === "published"
                            ? "bg-brand-blue/20 text-brand-blue"
                            : "bg-zinc-800 text-zinc-500"
                        }`}
                      >
                        {item.status}
                      </span>
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>
        </aside>

        <div className="rounded-2xl border border-brand-border bg-brand-surface/60 p-5">
          {!announcement && !update ? (
            <div className="flex min-h-[420px] flex-col items-center justify-center text-center text-sm text-zinc-500 space-y-3">
              <div className="h-12 w-12 rounded-2xl bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-600">
                <Megaphone className="h-6 w-6" />
              </div>
              <p>Choose an item on the left or create a new banner/update.</p>
            </div>
          ) : kind === "announcement" && announcement ? (
            <AnnouncementEditor value={announcement} onChange={setAnnouncement} />
          ) : update ? (
            <UpdateEditor value={update} onChange={setUpdate} />
          ) : null}
          {(announcement || update) && (
            <div className="mt-6 flex items-center gap-3 border-t border-brand-border pt-5">
              <button
                onClick={save}
                className="inline-flex items-center gap-2 rounded-xl bg-brand-green px-4 py-2.5 text-sm font-bold text-black hover:opacity-90 transition-opacity"
              >
                <Save className="h-4 w-4" /> Save
              </button>
              <button
                onClick={remove}
                className="inline-flex items-center gap-2 rounded-xl border border-red-500/30 px-4 py-2.5 text-sm font-bold text-red-300 hover:bg-red-500/10 transition-colors"
              >
                <Trash2 className="h-4 w-4" /> Delete
              </button>
              {message && <span className="text-sm text-brand-green font-medium">{message}</span>}
            </div>
          )}
        </div>

        <div className="rounded-2xl border border-brand-border bg-brand-surface/40 p-5 space-y-4">
          <h3 className="flex items-center gap-2 text-sm font-bold text-white">
            <Eye className="h-4 w-4 text-brand-green" /> Live Banner Preview
          </h3>
          {preview ? (
            <div
              className="rounded-xl border px-4 py-3.5 text-sm shadow-xl"
              style={{
                backgroundColor: preview.background_color,
                color: preview.text_color,
                borderColor: `${preview.accent_color}55`,
              }}
            >
              <span className="text-xs font-bold uppercase tracking-wider" style={{ color: preview.accent_color }}>
                {preview.label}
              </span>
              <p className="mt-2 font-bold text-base leading-snug">{preview.headline}</p>
              <p className="mt-1 text-xs opacity-80 leading-relaxed">{preview.message}</p>
              <div className="mt-4 flex flex-wrap gap-2.5 text-xs font-bold" style={{ color: preview.accent_color }}>
                {preview.primary_label && (
                  <span className="rounded-lg bg-white/10 px-2.5 py-1 backdrop-blur-sm">
                    {preview.primary_label}
                  </span>
                )}
                {preview.secondary_label && (
                  <span className="px-2.5 py-1 opacity-80">
                    {preview.secondary_label}
                  </span>
                )}
              </div>
            </div>
          ) : (
            <p className="text-xs text-zinc-500">Update pages use the public release update template.</p>
          )}
        </div>
      </section>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string | number | null;
  onChange: (value: string) => void;
  type?: string;
}) {
  return (
    <label className="block space-y-1.5">
      <span className="text-xs font-semibold text-zinc-400">{label}</span>
      <input
        type={type}
        value={value ?? ""}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-lg border border-brand-border bg-brand-surface px-3 py-2 text-sm text-white outline-none focus:border-brand-green"
      />
    </label>
  );
}

function Select({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (value: "draft" | "published" | "archived") => void;
}) {
  return (
    <label className="block space-y-1.5">
      <span className="text-xs font-semibold text-zinc-400">{label}</span>
      <select
        value={value}
        onChange={(event) => onChange(event.target.value as "draft" | "published" | "archived")}
        className="w-full rounded-lg border border-brand-border bg-brand-surface px-3 py-2 text-sm text-white"
      >
        <option value="draft">Draft</option>
        <option value="published">Published</option>
        <option value="archived">Archived</option>
      </select>
    </label>
  );
}

function AnnouncementEditor({
  value,
  onChange,
}: {
  value: SiteAnnouncement;
  onChange: (value: SiteAnnouncement) => void;
}) {
  const set = (key: keyof SiteAnnouncement, next: string | number | null) => onChange({ ...value, [key]: next });
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <div className="sm:col-span-2">
        <Field label="Internal name" value={value.name} onChange={(v) => set("name", v)} />
      </div>
      <Select label="Status" value={value.status} onChange={(v) => set("status", v)} />
      <Field label="Label" value={value.label} onChange={(v) => set("label", v)} />
      <div className="sm:col-span-2">
        <Field label="Headline" value={value.headline} onChange={(v) => set("headline", v)} />
      </div>
      <div className="sm:col-span-2">
        <Field label="Message" value={value.message} onChange={(v) => set("message", v)} />
      </div>
      <Field label="Primary button text" value={value.primary_label} onChange={(v) => set("primary_label", v || null)} />
      <Field label="Primary URL" value={value.primary_url} onChange={(v) => set("primary_url", v || null)} />
      <Field label="Secondary button text" value={value.secondary_label} onChange={(v) => set("secondary_label", v || null)} />
      <Field label="Secondary URL" value={value.secondary_url} onChange={(v) => set("secondary_url", v || null)} />
      <Field label="Starts at (ISO)" value={value.starts_at} onChange={(v) => set("starts_at", v || null)} />
      <Field label="Ends at (ISO)" value={value.ends_at} onChange={(v) => set("ends_at", v || null)} />
      <Field label="Background color" value={value.background_color} onChange={(v) => set("background_color", v)} />
      <Field label="Accent color" value={value.accent_color} onChange={(v) => set("accent_color", v)} />
      <Field label="Text color" value={value.text_color} onChange={(v) => set("text_color", v)} />
      <Field label="Sort order" type="number" value={value.sort_order} onChange={(v) => set("sort_order", Number(v) || 0)} />
    </div>
  );
}

function UpdateEditor({ value, onChange }: { value: SiteUpdate; onChange: (value: SiteUpdate) => void }) {
  const set = (key: keyof SiteUpdate, next: string | null) => onChange({ ...value, [key]: next });
  return (
    <div className="space-y-4">
      <Select label="Status" value={value.status} onChange={(v) => set("status", v)} />
      <Field label="URL slug" value={value.slug} onChange={(v) => set("slug", v)} />
      <Field label="Version" value={value.version} onChange={(v) => set("version", v || null)} />
      <Field label="Title" value={value.title} onChange={(v) => set("title", v)} />
      <Field label="Summary" value={value.summary} onChange={(v) => set("summary", v)} />
      <label className="block space-y-1.5">
        <span className="text-xs font-semibold text-zinc-400">Full update body</span>
        <textarea
          value={value.body}
          onChange={(e) => set("body", e.target.value)}
          rows={12}
          className="w-full rounded-lg border border-brand-border bg-brand-surface px-3 py-2 text-sm text-white outline-none focus:border-brand-green"
        />
      </label>
    </div>
  );
}
