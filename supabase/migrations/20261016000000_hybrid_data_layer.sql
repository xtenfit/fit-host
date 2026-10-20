-- FIT HOST — HYBRID DATA LAYER BASELINE MIGRATION
-- Migration: 20261016000000_hybrid_data_layer.sql
-- Description: Baseline schema matching the 8 live tables created in Supabase with hardened RLS policies.
-- Baseline command: supabase migration repair --status applied 20261016000000

-- ============================================================================
-- 1. PROFILES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    age INTEGER CHECK (age >= 10 AND age <= 120),
    height_cm NUMERIC(5,2) CHECK (height_cm > 0),
    weight_kg NUMERIC(5,2) CHECK (weight_kg > 0),
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING ((SELECT auth.uid()) = id);
CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING ((SELECT auth.uid()) = id) WITH CHECK ((SELECT auth.uid()) = id);
CREATE POLICY "profiles_delete_own" ON public.profiles
    FOR DELETE USING ((SELECT auth.uid()) = id);

-- ============================================================================
-- 2. EXERCISES (Global catalog + custom user exercises)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.exercises (
    id TEXT PRIMARY KEY,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    target_muscle TEXT NOT NULL,
    instructions TEXT,
    equipment TEXT,
    is_custom BOOLEAN NOT NULL DEFAULT false,
    image_asset TEXT,
    anatomy_asset TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_exercises_owner ON public.exercises(owner_id);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON public.exercises(category);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "exercises_select_public_or_own" ON public.exercises
    FOR SELECT USING (owner_id IS NULL OR (SELECT auth.uid()) = owner_id);
CREATE POLICY "exercises_insert_own" ON public.exercises
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = owner_id);
CREATE POLICY "exercises_update_own" ON public.exercises
    FOR UPDATE USING ((SELECT auth.uid()) = owner_id) WITH CHECK ((SELECT auth.uid()) = owner_id);
CREATE POLICY "exercises_delete_own" ON public.exercises
    FOR DELETE USING ((SELECT auth.uid()) = owner_id);

-- ============================================================================
-- 3. WORKOUTS
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

CREATE POLICY "workouts_select_own" ON public.workouts
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "workouts_insert_own" ON public.workouts
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workouts_update_own" ON public.workouts
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workouts_delete_own" ON public.workouts
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 4. WORKOUT_EXERCISES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_exercises (
    id TEXT PRIMARY KEY,
    workout_id TEXT NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_workout_exercises_user_workout ON public.workout_exercises(user_id, workout_id, order_index);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_user_id ON public.workout_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON public.workout_exercises(workout_id);

ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_exercises_select_own" ON public.workout_exercises
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_exercises_insert_own" ON public.workout_exercises
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_exercises_update_own" ON public.workout_exercises
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_exercises_delete_own" ON public.workout_exercises
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 5. WORKOUT_SETS
-- ============================================================================
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_workout_sets_user_parent ON public.workout_sets(user_id, workout_exercise_id, set_number);
CREATE INDEX IF NOT EXISTS idx_workout_sets_user_id ON public.workout_sets(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_exercise_id ON public.workout_sets(workout_exercise_id);

ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_sets_select_own" ON public.workout_sets
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_sets_insert_own" ON public.workout_sets
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_sets_update_own" ON public.workout_sets
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "workout_sets_delete_own" ON public.workout_sets
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 6. NUTRITION_LOGS (Daily consolidated document: meals, drinks, water)
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

CREATE POLICY "nutrition_logs_select_own" ON public.nutrition_logs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "nutrition_logs_insert_own" ON public.nutrition_logs
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "nutrition_logs_update_own" ON public.nutrition_logs
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "nutrition_logs_delete_own" ON public.nutrition_logs
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 7. REMINDERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reminders (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    time_of_day TEXT NOT NULL, -- HH:mm
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

CREATE POLICY "reminders_select_own" ON public.reminders
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "reminders_insert_own" ON public.reminders
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "reminders_update_own" ON public.reminders
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "reminders_delete_own" ON public.reminders
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 8. CALENDAR_EVENTS
-- ============================================================================
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

CREATE POLICY "calendar_events_select_own" ON public.calendar_events
    FOR SELECT USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "calendar_events_insert_own" ON public.calendar_events
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "calendar_events_update_own" ON public.calendar_events
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "calendar_events_delete_own" ON public.calendar_events
    FOR DELETE USING ((SELECT auth.uid()) = user_id);
