-- ============================================================================
-- FIT HOST — PRODUCTION SCHEMA RECONCILIATION & DATA SYNC REPAIR
-- Migration: 20261023000000_production_sync_repair_and_schema_reconciliation.sql
-- Description: Reconciles all schema mismatches between Flutter client models,
--              local Drift database, and deployed Supabase PostgreSQL schema.
--              Includes missing profile fields (activity_level, body composition),
--              body_measurements, progress_photos, hydration_logs, routines,
--              workout extensions, and security RLS policies.
-- Safe & Idempotent: Zero destructive operations. Preserves all existing rows.
-- ============================================================================

-- Ensure uuid-ossp extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. PROFILES TABLE RECONCILIATION
-- ============================================================================
-- Add all wizard expansion and health intelligence fields expected by UserProfile model
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS activity_level TEXT,
    ADD COLUMN IF NOT EXISTS gender_specific_goals TEXT DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS body_fat_percent NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS waist_cm NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS hip_cm NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS chest_cm NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS neck_cm NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS target_weeks INTEGER,
    ADD COLUMN IF NOT EXISTS selected_weekdays TEXT DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS session_duration_minutes INTEGER DEFAULT 45,
    ADD COLUMN IF NOT EXISTS uses_every_day BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS meals_per_day INTEGER DEFAULT 3,
    ADD COLUMN IF NOT EXISTS sleep_hours NUMERIC(4,2) DEFAULT 7.5,
    ADD COLUMN IF NOT EXISTS stress_level TEXT,
    ADD COLUMN IF NOT EXISTS reminder_frequency_hours INTEGER DEFAULT 2,
    ADD COLUMN IF NOT EXISTS quiet_hours_start TEXT,
    ADD COLUMN IF NOT EXISTS quiet_hours_end TEXT,
    ADD COLUMN IF NOT EXISTS allergy_notes TEXT,
    ADD COLUMN IF NOT EXISTS work_hours INTEGER,
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Backfill user_id from id for existing profile records
UPDATE public.profiles
SET user_id = id
WHERE user_id IS NULL;

-- Trigger to guarantee id and user_id stay synchronized on insert/update
CREATE OR REPLACE FUNCTION public.sync_profile_user_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id := NEW.id;
    END IF;
    IF NEW.id IS NULL THEN
        NEW.id := NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_profile_user_id ON public.profiles;
CREATE TRIGGER trg_sync_profile_user_id
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_profile_user_id();

-- Indexes for profile resolution
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);

-- Hardened RLS policies for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT
    USING ((SELECT auth.uid()) = id OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = id OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE
    USING ((SELECT auth.uid()) = id OR (SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = id OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;
CREATE POLICY "profiles_delete_own" ON public.profiles
    FOR DELETE
    USING ((SELECT auth.uid()) = id OR (SELECT auth.uid()) = user_id);

-- ============================================================================
-- 2. BODY MEASUREMENTS TABLE
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

DROP POLICY IF EXISTS "body_measurements_select_own" ON public.body_measurements;
CREATE POLICY "body_measurements_select_own" ON public.body_measurements
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "body_measurements_insert_own" ON public.body_measurements;
CREATE POLICY "body_measurements_insert_own" ON public.body_measurements
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "body_measurements_update_own" ON public.body_measurements;
CREATE POLICY "body_measurements_update_own" ON public.body_measurements
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "body_measurements_delete_own" ON public.body_measurements;
CREATE POLICY "body_measurements_delete_own" ON public.body_measurements
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Auto-update server_updated_at trigger function
CREATE OR REPLACE FUNCTION public.set_server_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.server_updated_at := timezone('utc', now());
    NEW.updated_at := timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_body_measurements_updated_at ON public.body_measurements;
CREATE TRIGGER trg_body_measurements_updated_at
    BEFORE UPDATE ON public.body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

-- ============================================================================
-- 3. PROGRESS PHOTOS TABLE
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
CREATE INDEX IF NOT EXISTS idx_progress_photos_sync ON public.progress_photos(user_id, server_updated_at);

ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "progress_photos_select_own" ON public.progress_photos;
CREATE POLICY "progress_photos_select_own" ON public.progress_photos
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "progress_photos_insert_own" ON public.progress_photos;
CREATE POLICY "progress_photos_insert_own" ON public.progress_photos
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "progress_photos_update_own" ON public.progress_photos;
CREATE POLICY "progress_photos_update_own" ON public.progress_photos
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "progress_photos_delete_own" ON public.progress_photos;
CREATE POLICY "progress_photos_delete_own" ON public.progress_photos
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

DROP TRIGGER IF EXISTS trg_progress_photos_updated_at ON public.progress_photos;
CREATE TRIGGER trg_progress_photos_updated_at
    BEFORE UPDATE ON public.progress_photos
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

-- ============================================================================
-- 4. HYDRATION LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.hydration_logs (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    water_glasses INTEGER NOT NULL DEFAULT 0,
    target_glasses INTEGER NOT NULL DEFAULT 10,
    total_ml INTEGER NOT NULL DEFAULT 0,
    drink_type TEXT NOT NULL DEFAULT 'water',
    note TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_hydration_logs_user_date UNIQUE(user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_hydration_logs_user_date ON public.hydration_logs(user_id, log_date);
CREATE INDEX IF NOT EXISTS idx_hydration_logs_user_id ON public.hydration_logs(user_id);

ALTER TABLE public.hydration_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hydration_logs_select_own" ON public.hydration_logs;
CREATE POLICY "hydration_logs_select_own" ON public.hydration_logs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "hydration_logs_insert_own" ON public.hydration_logs;
CREATE POLICY "hydration_logs_insert_own" ON public.hydration_logs
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "hydration_logs_update_own" ON public.hydration_logs;
CREATE POLICY "hydration_logs_update_own" ON public.hydration_logs
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "hydration_logs_delete_own" ON public.hydration_logs;
CREATE POLICY "hydration_logs_delete_own" ON public.hydration_logs
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 5. WORKOUT EXERCISES AND WORKOUT SETS EXTENSIONS
-- ============================================================================
ALTER TABLE public.workout_exercises
    ADD COLUMN IF NOT EXISTS superset_id TEXT,
    ADD COLUMN IF NOT EXISTS is_skipped BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.workout_sets
    ADD COLUMN IF NOT EXISTS target_reps INTEGER,
    ADD COLUMN IF NOT EXISTS target_weight_kg NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS duration_seconds INTEGER,
    ADD COLUMN IF NOT EXISTS distance_meters NUMERIC(8,2),
    ADD COLUMN IF NOT EXISTS tempo TEXT,
    ADD COLUMN IF NOT EXISTS rpe NUMERIC(3,1),
    ADD COLUMN IF NOT EXISTS is_skipped BOOLEAN NOT NULL DEFAULT false;

-- ============================================================================
-- 6. ROUTINES & TRAINING ENGINE TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.routines (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'custom',
    difficulty TEXT NOT NULL DEFAULT 'intermediate',
    estimated_duration_minutes INTEGER NOT NULL DEFAULT 45,
    is_template BOOLEAN NOT NULL DEFAULT false,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_routines_user_id ON public.routines(user_id);
CREATE INDEX IF NOT EXISTS idx_routines_category ON public.routines(category);
CREATE INDEX IF NOT EXISTS idx_routines_is_template ON public.routines(is_template);

ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "routines_select_own_or_template" ON public.routines;
CREATE POLICY "routines_select_own_or_template" ON public.routines
    FOR SELECT USING (is_template = true OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "routines_insert_own" ON public.routines;
CREATE POLICY "routines_insert_own" ON public.routines
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "routines_update_own" ON public.routines;
CREATE POLICY "routines_update_own" ON public.routines
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "routines_delete_own" ON public.routines;
CREATE POLICY "routines_delete_own" ON public.routines
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

CREATE TABLE IF NOT EXISTS public.routine_exercises (
    id TEXT PRIMARY KEY,
    routine_id TEXT NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    superset_id TEXT,
    rest_seconds INTEGER DEFAULT 90,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine_id ON public.routine_exercises(routine_id);

ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "routine_exercises_select" ON public.routine_exercises;
CREATE POLICY "routine_exercises_select" ON public.routine_exercises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND (r.is_template = true OR r.user_id = (SELECT auth.uid()))
        )
    );

DROP POLICY IF EXISTS "routine_exercises_modify" ON public.routine_exercises;
CREATE POLICY "routine_exercises_modify" ON public.routine_exercises
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

CREATE TABLE IF NOT EXISTS public.routine_sets (
    id TEXT PRIMARY KEY,
    routine_exercise_id TEXT NOT NULL REFERENCES public.routine_exercises(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL DEFAULT 1,
    set_type TEXT NOT NULL DEFAULT 'normal',
    target_reps INTEGER,
    target_weight_kg NUMERIC(6,2),
    duration_seconds INTEGER,
    distance_meters NUMERIC(8,2),
    tempo TEXT,
    rpe NUMERIC(3,1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_routine_sets_exercise ON public.routine_sets(routine_exercise_id);

ALTER TABLE public.routine_sets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "routine_sets_select" ON public.routine_sets;
CREATE POLICY "routine_sets_select" ON public.routine_sets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND (r.is_template = true OR r.user_id = (SELECT auth.uid()))
        )
    );

DROP POLICY IF EXISTS "routine_sets_modify" ON public.routine_sets;
CREATE POLICY "routine_sets_modify" ON public.routine_sets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

CREATE TABLE IF NOT EXISTS public.personal_records (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    metric_type TEXT NOT NULL DEFAULT 'weight',
    value NUMERIC(8,2) NOT NULL,
    reps INTEGER,
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    workout_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_personal_records_user ON public.personal_records(user_id, exercise_id);

ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "personal_records_owner" ON public.personal_records;
CREATE POLICY "personal_records_owner" ON public.personal_records
    FOR ALL USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE TABLE IF NOT EXISTS public.progression_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    double_progression_enabled BOOLEAN NOT NULL DEFAULT true,
    default_rep_increase INTEGER NOT NULL DEFAULT 2,
    default_weight_increment_kg NUMERIC(4,2) NOT NULL DEFAULT 2.50,
    deload_threshold_percentage NUMERIC(4,2) NOT NULL DEFAULT 10.00,
    warmup_set_count INTEGER NOT NULL DEFAULT 2,
    auto_progress_prs BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.progression_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "progression_settings_owner" ON public.progression_settings;
CREATE POLICY "progression_settings_owner" ON public.progression_settings
    FOR ALL USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 7. COMMUNITY EXERCISES, MAPPINGS & SUBMISSIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.exercise_id_mappings (
    old_exercise_id TEXT PRIMARY KEY,
    canonical_exercise_id TEXT NOT NULL,
    old_name TEXT,
    canonical_name TEXT,
    confidence TEXT NOT NULL DEFAULT 'high',
    mapped_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.exercise_id_mappings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exercise_mappings_public_read" ON public.exercise_id_mappings;
CREATE POLICY "exercise_mappings_public_read" ON public.exercise_id_mappings
    FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.exercise_submissions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT,
    submission_type TEXT NOT NULL CHECK (submission_type IN ('new_exercise', 'correction', 'safety_note')),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    target_muscle TEXT NOT NULL,
    secondary_muscles TEXT[] DEFAULT '{}'::text[],
    equipment TEXT NOT NULL,
    instruction_steps TEXT[] DEFAULT '{}'::text[],
    safety_notes TEXT,
    source_attribution TEXT,
    submission_status TEXT NOT NULL DEFAULT 'pending' CHECK (submission_status IN ('pending', 'approved', 'rejected')),
    reviewer_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_exercise_submissions_user_id ON public.exercise_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_submissions_status ON public.exercise_submissions(submission_status);

ALTER TABLE public.exercise_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exercise_submissions_select_own_or_approved" ON public.exercise_submissions;
CREATE POLICY "exercise_submissions_select_own_or_approved" ON public.exercise_submissions
    FOR SELECT USING ((SELECT auth.uid()) = user_id OR submission_status = 'approved');

DROP POLICY IF EXISTS "exercise_submissions_insert_own" ON public.exercise_submissions;
CREATE POLICY "exercise_submissions_insert_own" ON public.exercise_submissions
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 8. NOTIFICATION INBOX TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notification_inbox (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    is_read BOOLEAN NOT NULL DEFAULT false,
    payload JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    read_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notification_inbox_user_id ON public.notification_inbox(user_id, created_at DESC);

ALTER TABLE public.notification_inbox ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notification_inbox_owner" ON public.notification_inbox;
CREATE POLICY "notification_inbox_owner" ON public.notification_inbox
    FOR ALL USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 8B. CALORIE ADJUSTMENTS TABLE (INDEPENDENT MANUAL EXPENDITURE RECORDS)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.calorie_adjustments (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    calories_burned NUMERIC(7,2) NOT NULL,
    activity_type TEXT NOT NULL,
    notes TEXT,
    source TEXT NOT NULL DEFAULT 'manual',
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_calorie_adjustments_user_date ON public.calorie_adjustments(user_id, date);

ALTER TABLE public.calorie_adjustments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "calorie_adjustments_owner" ON public.calorie_adjustments;
CREATE POLICY "calorie_adjustments_owner" ON public.calorie_adjustments
    FOR ALL
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 9. PERMISSIONS & GRANTS
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- ============================================================================
-- 10. NOTIFY POSTGREST SCHEMA CACHE RELOAD
-- ============================================================================
-- Signal PostgREST schema cache to reload immediately so new tables and columns
-- are recognized in the REST API without delay.
NOTIFY pgrst, 'reload schema';
