-- ==============================================================================
-- FIT HOST — SUPABASE DATABASE ADVISORS & SECURITY HARDENING RECONCILIATION
-- Migration: 20261031091349_fix_database_advisors_and_security_hardening.sql
--
-- Directly fixes all issues identified by Supabase Database Linter & Advisors:
--   1. Secure search_path and revoke public/anon RPC execution on sync_profile_email()
--   2. Fix Multiple Permissive Policies on public.step_daily_logs by removing redundant ALL policy
--   3. Secure storage.avatars bucket listing by replacing public SELECT policy with authenticated SELECT
--   4. Drop exact duplicate indexes (step_daily_logs, hydration_logs)
--   5. Drop redundant single-column prefix indexes (covered by composite indexes with user_id/parent)
--   6. Drop unused low-cardinality indexes
-- ==============================================================================

-- ==============================================================================
-- 1. SECURE FUNCTION SEARCH PATH & PRIVILEGES (sync_profile_email)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.sync_profile_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.email IS NULL OR TRIM(NEW.email) = '' THEN
        NEW.email := (
            SELECT email FROM auth.users 
            WHERE id = COALESCE(NEW.user_id, NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$;

-- Revoke direct RPC execution from public/anon/authenticated roles
-- Trigger functions only need execution by PostgreSQL trigger runner & service_role
REVOKE ALL ON FUNCTION public.sync_profile_email() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sync_profile_email() TO service_role;


-- ==============================================================================
-- 2. FIX MULTIPLE PERMISSIVE POLICIES (public.step_daily_logs)
-- ==============================================================================

-- Drop the legacy blanket "step_daily_logs_owner_all" policy which duplicated the 4 granular policies
DROP POLICY IF EXISTS "step_daily_logs_owner_all" ON public.step_daily_logs;

-- Re-assert canonical single permissive policies for authenticated role with optimized (select auth.uid())
DROP POLICY IF EXISTS "step_daily_logs_select_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_select_own"
    ON public.step_daily_logs FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "step_daily_logs_insert_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_insert_own"
    ON public.step_daily_logs FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "step_daily_logs_update_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_update_own"
    ON public.step_daily_logs FOR UPDATE TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "step_daily_logs_delete_own" ON public.step_daily_logs;
CREATE POLICY "step_daily_logs_delete_own"
    ON public.step_daily_logs FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));


-- ==============================================================================
-- 3. SECURE STORAGE AVATARS BUCKET LISTING (storage.objects)
-- ==============================================================================

-- The public bucket serves avatars to the public via direct CDN URL (/storage/v1/object/public/avatars/...)
-- Direct listing of objects in storage.objects should only be allowed for authenticated users.
DROP POLICY IF EXISTS "avatars_storage_select_public" ON storage.objects;

DROP POLICY IF EXISTS "avatars_storage_select_authenticated" ON storage.objects;
CREATE POLICY "avatars_storage_select_authenticated"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'avatars');


-- ==============================================================================
-- 4. DROP EXACT DUPLICATE & REDUNDANT PREFIX INDEXES
-- ==============================================================================

-- 4.1 step_daily_logs:
-- idx_step_daily_logs_user_date is an identical duplicate of unique constraint uq_step_user_date (user_id, step_date)
-- idx_step_daily_logs_user_id is redundant to uq_step_user_date (user_id leading column)
DROP INDEX IF EXISTS public.idx_step_daily_logs_user_date;
DROP INDEX IF EXISTS public.idx_step_daily_logs_user_id;

-- 4.2 hydration_logs:
-- idx_hydration_logs_user_date is an identical duplicate of unique constraint uq_hydration_logs_user_date (user_id, log_date)
-- idx_hydration_logs_user_id is redundant to uq_hydration_logs_user_date (user_id leading column)
DROP INDEX IF EXISTS public.idx_hydration_logs_user_date;
DROP INDEX IF EXISTS public.idx_hydration_logs_user_id;

-- 4.3 body_measurements:
-- idx_body_measurements_user_id is redundant to idx_body_measurements_sync(user_id, server_updated_at)
DROP INDEX IF EXISTS public.idx_body_measurements_user_id;

-- 4.4 progress_photos:
-- idx_progress_photos_user_id is redundant to idx_progress_photos_sync(user_id, server_updated_at)
DROP INDEX IF EXISTS public.idx_progress_photos_user_id;

-- 4.5 calorie_adjustments:
-- idx_calorie_adjustments_user_id is redundant to idx_calorie_adjustments_user_date(user_id, date, deleted_at)
DROP INDEX IF EXISTS public.idx_calorie_adjustments_user_id;

-- 4.6 daily_diary_entries:
-- idx_daily_diary_entries_user_id is redundant to idx_daily_diary_entries_sync(user_id, server_updated_at)
DROP INDEX IF EXISTS public.idx_daily_diary_entries_user_id;

-- 4.7 workout_exercises:
-- idx_workout_exercises_workout_id is redundant to idx_workout_exercises_parent(workout_id, order_index)
DROP INDEX IF EXISTS public.idx_workout_exercises_workout_id;

-- 4.8 workout_sets:
-- idx_workout_sets_workout_exercise_id is redundant to idx_workout_sets_parent(workout_exercise_id, set_number)
DROP INDEX IF EXISTS public.idx_workout_sets_workout_exercise_id;

-- 4.9 reminder_schedules:
-- idx_reminder_schedules_user_id is redundant to idx_reminder_schedules_user_enabled(user_id, is_enabled)
DROP INDEX IF EXISTS public.idx_reminder_schedules_user_id;

-- 4.10 workouts:
-- idx_workouts_user_id is redundant to idx_workouts_server_updated(user_id, server_updated_at)
DROP INDEX IF EXISTS public.idx_workouts_user_id;


-- ==============================================================================
-- 5. DROP UNUSED LOW-CARDINALITY STANDALONE INDEXES
-- ==============================================================================

DROP INDEX IF EXISTS public.idx_routines_category;
DROP INDEX IF EXISTS public.idx_routines_is_template;
DROP INDEX IF EXISTS public.idx_food_items_source;
DROP INDEX IF EXISTS public.idx_exercises_category;
DROP INDEX IF EXISTS public.idx_exercise_submissions_status;

