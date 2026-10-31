-- Fit Host website content management
CREATE TABLE IF NOT EXISTS public.site_announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  label TEXT NOT NULL DEFAULT 'Announcement',
  headline TEXT NOT NULL,
  message TEXT NOT NULL,
  primary_label TEXT,
  primary_url TEXT,
  secondary_label TEXT,
  secondary_url TEXT,
  icon TEXT NOT NULL DEFAULT 'sparkles',
  background_color TEXT NOT NULL DEFAULT '#121820',
  accent_color TEXT NOT NULL DEFAULT '#00E676',
  text_color TEXT NOT NULL DEFAULT '#FFFFFF',
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.site_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  version TEXT,
  published_at TIMESTAMPTZ,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_site_announcements_active
  ON public.site_announcements(status, starts_at, ends_at, sort_order);
CREATE INDEX IF NOT EXISTS idx_site_updates_published
  ON public.site_updates(status, published_at DESC);

ALTER TABLE public.site_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read published announcements"
  ON public.site_announcements FOR SELECT TO anon, authenticated
  USING (
    status = 'published'
    AND (starts_at IS NULL OR starts_at <= NOW())
    AND (ends_at IS NULL OR ends_at > NOW())
  );

CREATE POLICY "Public can read published updates"
  ON public.site_updates FOR SELECT TO anon, authenticated
  USING (status = 'published');

CREATE POLICY "Admins manage announcements"
  ON public.site_announcements FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

CREATE POLICY "Admins manage updates"
  ON public.site_updates FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));
