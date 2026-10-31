-- FIT HOST — ADVANCED WORKOUT ROUTINES & TRAINING ENGINE MIGRATION
-- Migration: 20261021000001_advanced_workout_routines_engine.sql
-- Description: Extends workout tables, adds routines, routine_exercises, routine_sets,
--              personal_records, and progression_settings tables with strict RLS policies.

-- ============================================================================
-- 1. EXTEND WORKOUT_EXERCISES AND WORKOUT_SETS
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
-- 2. ROUTINES
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

CREATE POLICY "routines_select_own_or_template" ON public.routines
    FOR SELECT USING (is_template = true OR (SELECT auth.uid()) = user_id);

CREATE POLICY "routines_insert_own" ON public.routines
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routines_update_own" ON public.routines
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routines_delete_own" ON public.routines
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 3. ROUTINE_EXERCISES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.routine_exercises (
    id TEXT PRIMARY KEY,
    routine_id TEXT NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id),
    order_index INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    superset_id TEXT,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine ON public.routine_exercises(routine_id, order_index);
CREATE INDEX IF NOT EXISTS idx_routine_exercises_user ON public.routine_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_routine_exercises_exercise ON public.routine_exercises(exercise_id);

ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "routine_exercises_select_own_or_template" ON public.routine_exercises
    FOR SELECT USING (
        (SELECT auth.uid()) = user_id OR
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id AND r.is_template = true
        )
    );

CREATE POLICY "routine_exercises_insert_own" ON public.routine_exercises
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routine_exercises_update_own" ON public.routine_exercises
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routine_exercises_delete_own" ON public.routine_exercises
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 4. ROUTINE_SETS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.routine_sets (
    id TEXT PRIMARY KEY,
    routine_exercise_id TEXT NOT NULL REFERENCES public.routine_exercises(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL,
    set_type TEXT NOT NULL DEFAULT 'normal',
    target_reps INTEGER NOT NULL DEFAULT 10,
    target_weight_kg NUMERIC(6,2),
    target_duration_seconds INTEGER,
    target_distance_meters NUMERIC(8,2),
    target_rpe NUMERIC(3,1),
    tempo TEXT,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_routine_sets_exercise ON public.routine_sets(routine_exercise_id, set_number);
CREATE INDEX IF NOT EXISTS idx_routine_sets_user ON public.routine_sets(user_id);

ALTER TABLE public.routine_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "routine_sets_select_own_or_template" ON public.routine_sets
    FOR SELECT USING (
        (SELECT auth.uid()) = user_id OR
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id AND r.is_template = true
        )
    );

CREATE POLICY "routine_sets_insert_own" ON public.routine_sets
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routine_sets_update_own" ON public.routine_sets
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "routine_sets_delete_own" ON public.routine_sets
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 5. PERSONAL_RECORDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.personal_records (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id),
    record_type TEXT NOT NULL,
    value NUMERIC(10,2) NOT NULL,
    weight_kg NUMERIC(6,2),
    reps INTEGER,
    duration_seconds INTEGER,
    workout_id TEXT REFERENCES public.workouts(id) ON DELETE SET NULL,
    workout_set_id TEXT,
    achieved_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise ON public.personal_records(user_id, exercise_id, record_type);
CREATE INDEX IF NOT EXISTS idx_personal_records_achieved_at ON public.personal_records(achieved_at DESC);

ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "personal_records_select_own" ON public.personal_records
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "personal_records_insert_own" ON public.personal_records
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "personal_records_update_own" ON public.personal_records
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "personal_records_delete_own" ON public.personal_records
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 6. PROGRESSION_SETTINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.progression_settings (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id),
    strategy TEXT NOT NULL DEFAULT 'double_progression',
    target_reps_min INTEGER NOT NULL DEFAULT 8,
    target_reps_max INTEGER NOT NULL DEFAULT 12,
    target_working_sets INTEGER NOT NULL DEFAULT 3,
    successful_sessions_required INTEGER NOT NULL DEFAULT 2,
    weight_increment_kg NUMERIC(5,2) NOT NULL DEFAULT 2.50,
    unit_system TEXT NOT NULL DEFAULT 'kg',
    auto_apply BOOLEAN NOT NULL DEFAULT false,
    deload_after_missed_sessions INTEGER NOT NULL DEFAULT 3,
    deload_percentage NUMERIC(5,2) NOT NULL DEFAULT 10.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_progression_settings_user_exercise UNIQUE (user_id, exercise_id)
);

CREATE INDEX IF NOT EXISTS idx_progression_settings_user_exercise ON public.progression_settings(user_id, exercise_id);

ALTER TABLE public.progression_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "progression_settings_select_own" ON public.progression_settings
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "progression_settings_insert_own" ON public.progression_settings
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "progression_settings_update_own" ON public.progression_settings
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "progression_settings_delete_own" ON public.progression_settings
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 7. AUTO-UPDATE SERVER_UPDATED_AT TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_server_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.server_updated_at = timezone('utc', now());
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_routines_server_updated_at ON public.routines;
CREATE TRIGGER trg_routines_server_updated_at
    BEFORE UPDATE ON public.routines
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

DROP TRIGGER IF EXISTS trg_personal_records_server_updated_at ON public.personal_records;
CREATE TRIGGER trg_personal_records_server_updated_at
    BEFORE UPDATE ON public.personal_records
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

DROP TRIGGER IF EXISTS trg_progression_settings_server_updated_at ON public.progression_settings;
CREATE TRIGGER trg_progression_settings_server_updated_at
    BEFORE UPDATE ON public.progression_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();
