-- ============================================================================
-- FIT HOST — PRODUCTION ACCOUNT USER DATA ISOLATION & FULL FEATURE RECONCILIATION
-- Migration: 20261023000002_account_user_data_isolation_and_features.sql
-- Description: Enforces complete user account data separation by unique auth.users(id)
--              (e.g., Google/Gmail and email accounts) across all features:
--              1. Automatic profile provisioning and email synchronization triggers on auth.users
--              2. Account self-deletion cascading RPC (delete_user)
--              3. Full Daily Diary & Notes table (public.daily_diary_entries) with strict owner RLS
--              4. Strict Row Level Security (RLS) policies on Diet (nutrition_logs, food_items, hydration_logs)
--              5. Strict RLS on Workouts, exercises, sets, routines, PRs, and progression settings
--              6. Strict RLS on Steps & Activities (step_daily_logs, calorie_adjustments, calendar_events)
--              7. Strict RLS on Measurements (body_measurements) & Progress Photos (with date)
--              8. Strict RLS on Reminders & Notification Inbox
--              9. Secure storage bucket policies for progress photos isolated by user UUID folder
--              10. User Account Overview diagnostic RPC for verification
-- Safe & Idempotent: Can be run multiple times safely without data loss.
-- ============================================================================

-- Ensure uuid-ossp extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. SERVER UPDATED_AT TRIGGER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_server_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.server_updated_at := timezone('utc', now());
    NEW.updated_at := timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. AUTOMATIC ACCOUNT USER PROFILES TRIGGER & EMAIL SYNCHRONIZATION
-- ============================================================================
-- When a user registers or logs in via Google (Gmail) or Email, automatically
-- create/update their public.profiles row associated with their unique auth.users.id.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    derived_name TEXT;
    derived_avatar TEXT;
BEGIN
    -- Extract display name from metadata (Google OAuth provides full_name or name)
    derived_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );

    -- Extract avatar URL if provided by OAuth provider
    derived_avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        NULL
    );

    INSERT INTO public.profiles (
        id,
        user_id,
        email,
        display_name,
        avatar_url,
        fitness_goal,
        diet_type,
        daily_calories_target,
        target_protein_grams,
        target_carbs_grams,
        target_fats_grams,
        target_water_ml,
        weekly_workout_days,
        daily_workout_minutes,
        is_profile_setup_completed,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.id,
        NEW.email,
        derived_name,
        derived_avatar,
        'maintain_weight',
        'balanced',
        2250,
        145,
        250,
        60,
        2500,
        4,
        45,
        false,
        timezone('utc', now()),
        timezone('utc', now())
    )
    ON CONFLICT (id) DO UPDATE SET
        user_id = EXCLUDED.user_id,
        email = EXCLUDED.email,
        display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = timezone('utc', now());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Trigger to sync email changes from auth.users into public.profiles
CREATE OR REPLACE FUNCTION public.handle_user_updated()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET
        email = NEW.email,
        updated_at = timezone('utc', now())
    WHERE id = NEW.id OR user_id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE OF email ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_updated();

-- Trigger to guarantee id and user_id stay synchronized on insert/update in profiles
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

-- ============================================================================
-- 3. ACCOUNT SELF-DELETION RPC (delete_user)
-- ============================================================================
-- Allows authenticated users to safely delete their own account and cascade-delete
-- all their workouts, diet, notes, diary, measurements, photos, and personal data.
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void AS $$
DECLARE
    current_uid UUID;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete user from auth.users (cascades to all public tables via foreign keys)
    DELETE FROM auth.users WHERE id = current_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. PROFILES TABLE RECONCILIATION & HARDENED RLS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    gender TEXT,
    age INTEGER,
    height_cm NUMERIC(5,2),
    weight_kg NUMERIC(5,2),
    target_weight_kg NUMERIC(5,2),
    fitness_goal TEXT NOT NULL DEFAULT 'maintain_weight',
    diet_type TEXT NOT NULL DEFAULT 'balanced',
    daily_calories_target INTEGER NOT NULL DEFAULT 2250,
    target_protein_grams INTEGER NOT NULL DEFAULT 145,
    target_carbs_grams INTEGER NOT NULL DEFAULT 250,
    target_fats_grams INTEGER NOT NULL DEFAULT 60,
    target_water_ml INTEGER NOT NULL DEFAULT 2500,
    weekly_workout_days INTEGER NOT NULL DEFAULT 4,
    daily_workout_minutes INTEGER NOT NULL DEFAULT 45,
    custom_target_note TEXT,
    is_profile_setup_completed BOOLEAN NOT NULL DEFAULT true,
    activity_level TEXT,
    gender_specific_goals TEXT DEFAULT '[]',
    body_fat_percent NUMERIC(5,2),
    waist_cm NUMERIC(5,2),
    hip_cm NUMERIC(5,2),
    chest_cm NUMERIC(5,2),
    neck_cm NUMERIC(5,2),
    target_weeks INTEGER,
    selected_weekdays TEXT DEFAULT '[]',
    session_duration_minutes INTEGER DEFAULT 45,
    uses_every_day BOOLEAN DEFAULT false,
    meals_per_day INTEGER DEFAULT 3,
    sleep_hours NUMERIC(4,2) DEFAULT 7.5,
    stress_level TEXT,
    reminder_frequency_hours INTEGER DEFAULT 2,
    quiet_hours_start TEXT,
    quiet_hours_end TEXT,
    allergy_notes TEXT,
    work_hours INTEGER,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    version INTEGER NOT NULL DEFAULT 1
);

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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
    ADD COLUMN IF NOT EXISTS work_hours INTEGER;

UPDATE public.profiles
SET user_id = id
WHERE user_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

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
-- 5. NOTES & DIARY FEATURE (public.daily_diary_entries)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.daily_diary_entries (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entry_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'work',
    mood TEXT NOT NULL DEFAULT 'focused',
    voice_memo_path TEXT,
    voice_memo_duration_seconds INTEGER,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_daily_diary_entries_user_id ON public.daily_diary_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_diary_entries_user_date ON public.daily_diary_entries(user_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_diary_entries_sync ON public.daily_diary_entries(user_id, server_updated_at);

ALTER TABLE public.daily_diary_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "daily_diary_entries_select_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_select_own" ON public.daily_diary_entries
    FOR SELECT
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "daily_diary_entries_insert_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_insert_own" ON public.daily_diary_entries
    FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "daily_diary_entries_update_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_update_own" ON public.daily_diary_entries
    FOR UPDATE
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "daily_diary_entries_delete_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_delete_own" ON public.daily_diary_entries
    FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

DROP TRIGGER IF EXISTS trg_daily_diary_entries_updated_at ON public.daily_diary_entries;
CREATE TRIGGER trg_daily_diary_entries_updated_at
    BEFORE UPDATE ON public.daily_diary_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

-- ============================================================================
-- 6. DIET & NUTRITION (nutrition_logs, food_items, hydration_logs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.nutrition_logs (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    target_calories INTEGER NOT NULL DEFAULT 2250,
    target_protein INTEGER NOT NULL DEFAULT 145,
    target_carbs INTEGER NOT NULL DEFAULT 250,
    target_fat INTEGER NOT NULL DEFAULT 60,
    target_water_glasses INTEGER NOT NULL DEFAULT 10,
    water_glasses INTEGER NOT NULL DEFAULT 0,
    logged_meals JSONB NOT NULL DEFAULT '[]'::jsonb,
    logged_drinks JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_nutrition_logs_user_date UNIQUE(user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user_date ON public.nutrition_logs(user_id, log_date);
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user_id ON public.nutrition_logs(user_id);

ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "nutrition_logs_select_own" ON public.nutrition_logs;
CREATE POLICY "nutrition_logs_select_own" ON public.nutrition_logs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "nutrition_logs_insert_own" ON public.nutrition_logs;
CREATE POLICY "nutrition_logs_insert_own" ON public.nutrition_logs
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "nutrition_logs_update_own" ON public.nutrition_logs;
CREATE POLICY "nutrition_logs_update_own" ON public.nutrition_logs
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "nutrition_logs_delete_own" ON public.nutrition_logs;
CREATE POLICY "nutrition_logs_delete_own" ON public.nutrition_logs
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Food Items
CREATE TABLE IF NOT EXISTS public.food_items (
    id TEXT PRIMARY KEY,
    barcode TEXT,
    name TEXT NOT NULL,
    brand TEXT,
    protein_per_100g REAL DEFAULT 0.0,
    carbs_per_100g REAL DEFAULT 0.0,
    fats_per_100g REAL DEFAULT 0.0,
    calories_per_100g REAL DEFAULT 0.0,
    serving_presets_json TEXT DEFAULT '[]',
    source TEXT NOT NULL DEFAULT 'user_custom',
    image_url TEXT,
    is_deleted INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON public.food_items(barcode);
CREATE INDEX IF NOT EXISTS idx_food_items_user_id ON public.food_items(user_id);
CREATE INDEX IF NOT EXISTS idx_food_items_source ON public.food_items(source);

ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "food_items_select_policy" ON public.food_items;
CREATE POLICY "food_items_select_policy" ON public.food_items
    FOR SELECT
    USING (
        source IN ('seeded', 'openfoodfacts')
        OR (user_id IS NOT NULL AND (SELECT auth.uid()) = user_id)
    );

DROP POLICY IF EXISTS "food_items_insert_policy" ON public.food_items;
CREATE POLICY "food_items_insert_policy" ON public.food_items
    FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "food_items_update_policy" ON public.food_items;
CREATE POLICY "food_items_update_policy" ON public.food_items
    FOR UPDATE
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "food_items_delete_policy" ON public.food_items;
CREATE POLICY "food_items_delete_policy" ON public.food_items
    FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

-- Hydration Logs
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
-- 7. WORKOUTS, EXERCISES, SETS, ROUTINES & PRS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workouts (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    note TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'cancelled')),
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    calories_burned INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    client_mutation_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_started ON public.workouts(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON public.workouts(user_id);

ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "workouts_select_own" ON public.workouts;
CREATE POLICY "workouts_select_own" ON public.workouts
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workouts_insert_own" ON public.workouts;
CREATE POLICY "workouts_insert_own" ON public.workouts
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workouts_update_own" ON public.workouts;
CREATE POLICY "workouts_update_own" ON public.workouts
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workouts_delete_own" ON public.workouts;
CREATE POLICY "workouts_delete_own" ON public.workouts
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Workout Exercises
CREATE TABLE IF NOT EXISTS public.workout_exercises (
    id TEXT PRIMARY KEY,
    workout_id TEXT NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    superset_id TEXT,
    is_skipped BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

ALTER TABLE public.workout_exercises
    ADD COLUMN IF NOT EXISTS superset_id TEXT,
    ADD COLUMN IF NOT EXISTS is_skipped BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_workout_exercises_user_workout ON public.workout_exercises(user_id, workout_id, order_index);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_user_id ON public.workout_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON public.workout_exercises(workout_id);

ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "workout_exercises_select_own" ON public.workout_exercises;
CREATE POLICY "workout_exercises_select_own" ON public.workout_exercises
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_exercises_insert_own" ON public.workout_exercises;
CREATE POLICY "workout_exercises_insert_own" ON public.workout_exercises
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_exercises_update_own" ON public.workout_exercises;
CREATE POLICY "workout_exercises_update_own" ON public.workout_exercises
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_exercises_delete_own" ON public.workout_exercises;
CREATE POLICY "workout_exercises_delete_own" ON public.workout_exercises
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Workout Sets
CREATE TABLE IF NOT EXISTS public.workout_sets (
    id TEXT PRIMARY KEY,
    workout_exercise_id TEXT NOT NULL REFERENCES public.workout_exercises(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL,
    reps INTEGER NOT NULL DEFAULT 0,
    weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0.0,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    set_type TEXT NOT NULL DEFAULT 'normal',
    target_reps INTEGER,
    target_weight_kg NUMERIC(6,2),
    duration_seconds INTEGER,
    distance_meters NUMERIC(8,2),
    tempo TEXT,
    rpe NUMERIC(3,1),
    is_skipped BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

ALTER TABLE public.workout_sets
    ADD COLUMN IF NOT EXISTS target_reps INTEGER,
    ADD COLUMN IF NOT EXISTS target_weight_kg NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS duration_seconds INTEGER,
    ADD COLUMN IF NOT EXISTS distance_meters NUMERIC(8,2),
    ADD COLUMN IF NOT EXISTS tempo TEXT,
    ADD COLUMN IF NOT EXISTS rpe NUMERIC(3,1),
    ADD COLUMN IF NOT EXISTS is_skipped BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_workout_sets_user_parent ON public.workout_sets(user_id, workout_exercise_id, set_number);
CREATE INDEX IF NOT EXISTS idx_workout_sets_user_id ON public.workout_sets(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_exercise_id ON public.workout_sets(workout_exercise_id);

ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "workout_sets_select_own" ON public.workout_sets;
CREATE POLICY "workout_sets_select_own" ON public.workout_sets
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_sets_insert_own" ON public.workout_sets;
CREATE POLICY "workout_sets_insert_own" ON public.workout_sets
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_sets_update_own" ON public.workout_sets;
CREATE POLICY "workout_sets_update_own" ON public.workout_sets
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "workout_sets_delete_own" ON public.workout_sets;
CREATE POLICY "workout_sets_delete_own" ON public.workout_sets
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Routines & Training Engine
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

-- Routine Exercises
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

-- Routine Sets
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

-- Personal Records
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

-- Progression Settings
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
-- 8. STEPS & ACTIVITIES (step_daily_logs, calorie_adjustments, calendar_events)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.step_daily_logs (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    step_date DATE NOT NULL,
    steps INTEGER NOT NULL DEFAULT 0,
    target_steps INTEGER NOT NULL DEFAULT 10000,
    distance_meters NUMERIC(10,2) NOT NULL DEFAULT 0.0,
    active_calories INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_step_daily_logs_user_date UNIQUE(user_id, step_date)
);

CREATE INDEX IF NOT EXISTS idx_step_daily_logs_user_date ON public.step_daily_logs(user_id, step_date);
CREATE INDEX IF NOT EXISTS idx_step_daily_logs_user_id ON public.step_daily_logs(user_id);

ALTER TABLE public.step_daily_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "step_daily_logs_select_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_select_own" ON public.step_daily_logs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "step_daily_logs_insert_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_insert_own" ON public.step_daily_logs
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "step_daily_logs_update_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_update_own" ON public.step_daily_logs
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "step_daily_logs_delete_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_delete_own" ON public.step_daily_logs
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Calorie Adjustments (Manual Expenditures)
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

-- Calendar Events
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL,
    scheduled_date DATE NOT NULL,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    is_missed BOOLEAN NOT NULL DEFAULT false,
    recurrence_rule TEXT NOT NULL DEFAULT 'none',
    target_metrics JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON public.calendar_events(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "calendar_events_select_own" ON public.calendar_events;
CREATE POLICY "calendar_events_select_own" ON public.calendar_events
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "calendar_events_insert_own" ON public.calendar_events;
CREATE POLICY "calendar_events_insert_own" ON public.calendar_events
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "calendar_events_update_own" ON public.calendar_events;
CREATE POLICY "calendar_events_update_own" ON public.calendar_events
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "calendar_events_delete_own" ON public.calendar_events;
CREATE POLICY "calendar_events_delete_own" ON public.calendar_events
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 9. BODY MEASUREMENTS & PHYSIQUE PROGRESS PHOTOS (WITH DATES)
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

DROP TRIGGER IF EXISTS trg_body_measurements_updated_at ON public.body_measurements;
CREATE TRIGGER trg_body_measurements_updated_at
    BEFORE UPDATE ON public.body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

-- Progress Photos Table (Tied to user and exact capture date/time)
CREATE TABLE IF NOT EXISTS public.progress_photos (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    photo_path TEXT NOT NULL,
    pose_type TEXT NOT NULL DEFAULT 'front' CHECK (pose_type IN ('front', 'side', 'back', 'other')),
    associated_measurement_id TEXT REFERENCES public.body_measurements(id) ON DELETE SET NULL,
    weight_kg_at_photo NUMERIC(5,2),
    notes TEXT,
    storage_object_path TEXT,
    media_mime_type TEXT,
    media_size_bytes BIGINT,
    sharing_consent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

ALTER TABLE public.progress_photos
    ADD COLUMN IF NOT EXISTS storage_object_path TEXT,
    ADD COLUMN IF NOT EXISTS media_mime_type TEXT,
    ADD COLUMN IF NOT EXISTS media_size_bytes BIGINT,
    ADD COLUMN IF NOT EXISTS sharing_consent_at TIMESTAMPTZ;

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

-- Progress Photos Storage Bucket & Folder-Level User Isolation
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "progress_photos_storage_select_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_select_own"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    );

DROP POLICY IF EXISTS "progress_photos_storage_insert_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'progress-photos'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
        AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'webp', 'heic', 'heif')
    );

DROP POLICY IF EXISTS "progress_photos_storage_update_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_update_own"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    )
    WITH CHECK (
        bucket_id = 'progress-photos'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
        AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'webp', 'heic', 'heif')
    );

DROP POLICY IF EXISTS "progress_photos_storage_delete_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    );

-- ============================================================================
-- 10. REMINDERS & NOTIFICATION INBOX
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reminders (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    time_of_day TEXT NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    recurrence TEXT NOT NULL DEFAULT 'daily',
    repeat_days TEXT,
    sound_enabled BOOLEAN NOT NULL DEFAULT true,
    vibration_enabled BOOLEAN NOT NULL DEFAULT true,
    snooze_duration_minutes INTEGER NOT NULL DEFAULT 10,
    last_triggered_at TIMESTAMPTZ,
    last_completed_at TIMESTAMPTZ,
    is_dismissed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reminders_select_own" ON public.reminders;
CREATE POLICY "reminders_select_own" ON public.reminders
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "reminders_insert_own" ON public.reminders;
CREATE POLICY "reminders_insert_own" ON public.reminders
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "reminders_update_own" ON public.reminders;
CREATE POLICY "reminders_update_own" ON public.reminders
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "reminders_delete_own" ON public.reminders;
CREATE POLICY "reminders_delete_own" ON public.reminders
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- In-app Notification Inbox
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
-- 11. USER ACCOUNT OVERVIEW & DIAGNOSTIC RPC
-- ============================================================================
-- Returns total counts of all records owned by the authenticated caller.
-- Serves as immediate verification of user data separation.
CREATE OR REPLACE FUNCTION public.get_user_account_overview()
RETURNS TABLE (
    account_user_id UUID,
    account_email TEXT,
    profile_exists BOOLEAN,
    profile_setup_completed BOOLEAN,
    total_workouts BIGINT,
    total_nutrition_logs BIGINT,
    total_hydration_logs BIGINT,
    total_step_logs BIGINT,
    total_diary_entries BIGINT,
    total_body_measurements BIGINT,
    total_progress_photos BIGINT,
    total_reminders BIGINT,
    total_calendar_events BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_uid UUID;
    prof RECORD;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO prof FROM public.profiles WHERE id = current_uid OR user_id = current_uid LIMIT 1;

    RETURN QUERY
    SELECT
        current_uid AS account_user_id,
        COALESCE(prof.email, (SELECT email FROM auth.users WHERE id = current_uid)) AS account_email,
        (prof.id IS NOT NULL) AS profile_exists,
        COALESCE(prof.is_profile_setup_completed, false) AS profile_setup_completed,
        (SELECT COUNT(*) FROM public.workouts WHERE user_id = current_uid AND is_deleted = false) AS total_workouts,
        (SELECT COUNT(*) FROM public.nutrition_logs WHERE user_id = current_uid AND is_deleted = false) AS total_nutrition_logs,
        (SELECT COUNT(*) FROM public.hydration_logs WHERE user_id = current_uid AND deleted_at IS NULL) AS total_hydration_logs,
        (SELECT COUNT(*) FROM public.step_daily_logs WHERE user_id = current_uid AND deleted_at IS NULL) AS total_step_logs,
        (SELECT COUNT(*) FROM public.daily_diary_entries WHERE user_id = current_uid AND is_deleted = false) AS total_diary_entries,
        (SELECT COUNT(*) FROM public.body_measurements WHERE user_id = current_uid AND is_deleted = false) AS total_body_measurements,
        (SELECT COUNT(*) FROM public.progress_photos WHERE user_id = current_uid AND is_deleted = false) AS total_progress_photos,
        (SELECT COUNT(*) FROM public.reminders WHERE user_id = current_uid AND is_deleted = false) AS total_reminders,
        (SELECT COUNT(*) FROM public.calendar_events WHERE user_id = current_uid AND is_deleted = false) AS total_calendar_events;
END;
$$;

-- ============================================================================
-- 12. PERMISSIONS, GRANTS & SCHEMA CACHE RELOAD
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- Signal PostgREST schema cache to reload immediately so all new tables, columns,
-- triggers, and functions are recognized in the REST API without delay.
NOTIFY pgrst, 'reload schema';
