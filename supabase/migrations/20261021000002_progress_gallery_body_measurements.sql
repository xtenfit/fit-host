-- FIT HOST — PROGRESS GALLERY, BODY MEASUREMENTS & MEDIA TRACKING MIGRATION
-- Migration: 20261021000002_progress_gallery_body_measurements.sql
-- Description: Creates body_measurements and progress_photos tables with RLS policies,
--              foreign keys, composite indexes, and soft-delete support.

-- ============================================================================
-- 1. BODY MEASUREMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.body_measurements (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    measured_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    weight_kg NUMERIC(5,2),
    body_fat_percentage NUMERIC(4,1),
    waist_cm NUMERIC(5,1),
    chest_cm NUMERIC(5,1),
    hips_cm NUMERIC(5,1),
    arms_cm NUMERIC(5,1),
    thighs_cm NUMERIC(5,1),
    calves_cm NUMERIC(5,1),
    neck_cm NUMERIC(5,1),
    shoulders_cm NUMERIC(5,1),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_body_measurements_user_id ON public.body_measurements(user_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_measured_at ON public.body_measurements(user_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_body_measurements_sync ON public.body_measurements(user_id, server_updated_at);

ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "body_measurements_select_own" ON public.body_measurements
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "body_measurements_insert_own" ON public.body_measurements
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "body_measurements_update_own" ON public.body_measurements
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "body_measurements_delete_own" ON public.body_measurements
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 2. PROGRESS PHOTOS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.progress_photos (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    photo_path TEXT NOT NULL,
    pose_type TEXT NOT NULL DEFAULT 'front' CHECK (pose_type IN ('front', 'side', 'back', 'other')),
    associated_measurement_id TEXT REFERENCES public.body_measurements(id) ON DELETE SET NULL,
    weight_kg_at_photo NUMERIC(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON public.progress_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_photos_user_taken_at ON public.progress_photos(user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_progress_photos_pose_type ON public.progress_photos(user_id, pose_type);
CREATE INDEX IF NOT EXISTS idx_progress_photos_measurement_id ON public.progress_photos(associated_measurement_id);

ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "progress_photos_select_own" ON public.progress_photos
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "progress_photos_insert_own" ON public.progress_photos
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "progress_photos_update_own" ON public.progress_photos
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "progress_photos_delete_own" ON public.progress_photos
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 3. UPDATED AT TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    NEW.server_updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_body_measurements_updated_at ON public.body_measurements;
CREATE TRIGGER set_body_measurements_updated_at
    BEFORE UPDATE ON public.body_measurements
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_progress_photos_updated_at ON public.progress_photos;
CREATE TRIGGER set_progress_photos_updated_at
    BEFORE UPDATE ON public.progress_photos
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
