-- ==============================================================================
-- FIT HOST — SUPABASE DATABASE ADVISORS & SECURITY HARDENING RECONCILIATION
-- Migration: 20261024000000_fix_supabase_advisor_warnings.sql
--
-- Directly fixes all issues identified by Supabase Database Linter & Advisors:
--   1. Drop duplicate & redundant indexes (calendar_events, nutrition_logs, reminders)
--   2. Add missing foreign key index on progress_photos(associated_measurement_id)
--   3. Secure function search paths (SET search_path = '') on mutable triggers
--   4. Convert get_day_summaries to SECURITY INVOKER & restrict public/anon execution
--   5. Restrict administrative functions (rls_auto_enable, set_admin_role_for_authorized_users)
--   6. Fix Multiple Permissive Policies on routine_exercises, routine_sets, site_announcements, site_updates
--   7. Fix Auth RLS InitPlan on site_announcements and site_updates via (select auth.jwt())
-- ==============================================================================

-- ==============================================================================
-- 1. DROP DUPLICATE & REDUNDANT INDEXES
-- ==============================================================================

-- calendar_events: idx_calendar_user_date is an identical duplicate of idx_calendar_events_user_date (user_id, scheduled_date)
DROP INDEX IF EXISTS public.idx_calendar_user_date;

-- nutrition_logs: uq_user_log_date is the unique constraint; drop redundant duplicate index & uq index
DROP INDEX IF EXISTS public.uq_nutrition_logs_user_date;
DROP INDEX IF EXISTS public.idx_nutrition_user_date;

-- reminders: idx_reminders_user is an identical duplicate of idx_reminders_user_id (user_id)
DROP INDEX IF EXISTS public.idx_reminders_user;


-- ==============================================================================
-- 2. ADD MISSING FOREIGN KEY INDEX
-- ==============================================================================

-- progress_photos: unindexed foreign key associated_measurement_id references public.body_measurements(id)
CREATE INDEX IF NOT EXISTS idx_progress_photos_measurement_id 
    ON public.progress_photos(associated_measurement_id);


-- ==============================================================================
-- 3. SECURE FUNCTION SEARCH PATHS & PRIVILEGES ON TRIGGER FUNCTIONS
-- ==============================================================================

-- sync_profile_user_id: search_path mutable
CREATE OR REPLACE FUNCTION public.sync_profile_user_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id := NEW.id;
    END IF;
    IF NEW.id IS NULL THEN
        NEW.id := NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_profile_user_id() FROM PUBLIC, anon, authenticated;

-- set_server_updated_at: search_path mutable
CREATE OR REPLACE FUNCTION public.set_server_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.server_updated_at := timezone('utc', now());
    NEW.updated_at := timezone('utc', now());
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.set_server_updated_at() FROM PUBLIC, anon, authenticated;

-- set_admin_role_for_authorized_users: search_path mutable + executable by anon/authenticated
CREATE OR REPLACE FUNCTION public.set_admin_role_for_authorized_users()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF lower(NEW.email) = 'xtenfit@gmail.com' THEN
        NEW.raw_app_meta_data = coalesce(NEW.raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'superadmin');
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.set_admin_role_for_authorized_users() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_admin_role_for_authorized_users() TO service_role;

-- rls_auto_enable: event trigger executable by anon/authenticated
REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO service_role;


-- ==============================================================================
-- 4. CONVERT get_day_summaries TO SECURITY INVOKER & SECURE PERMISSIONS
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.get_day_summaries(start_date DATE, end_date DATE)
RETURNS TABLE (
    summary_date DATE,
    steps INTEGER,
    distance_km NUMERIC,
    workout_count INTEGER,
    workout_duration_min INTEGER,
    calories_burned INTEGER,
    calories_in INTEGER,
    protein_g NUMERIC,
    carbs_g NUMERIC,
    fats_g NUMERIC,
    water_ml INTEGER,
    has_reminder BOOLEAN,
    completed_reminders INTEGER,
    missed_reminders INTEGER
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    current_uid UUID;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    WITH days AS (
        SELECT d::DATE AS day_date
        FROM generate_series(start_date::timestamp, end_date::timestamp, '1 day'::interval) d
    ),
    user_workouts AS (
        SELECT 
            w.started_at::DATE AS w_date,
            COUNT(w.id)::INTEGER AS cnt,
            COALESCE(SUM(w.duration_seconds) / 60, 0)::INTEGER AS dur_min,
            COALESCE(SUM(COALESCE(w.calories_burned, (w.duration_seconds / 60 * 8)::INTEGER)), 0)::INTEGER AS cal_burned
        FROM public.workouts w
        WHERE w.user_id = current_uid
          AND w.status = 'completed'
          AND w.is_deleted = false
          AND w.started_at::DATE >= start_date
          AND w.started_at::DATE <= end_date
        GROUP BY w.started_at::DATE
    ),
    user_nutrition AS (
        SELECT
            nl.log_date,
            COALESCE((
                SELECT SUM((m->>'calories')::INTEGER)
                FROM jsonb_array_elements(nl.logged_meals) m
            ), 0)::INTEGER AS cal_in,
            COALESCE((
                SELECT SUM((m->>'protein_grams')::NUMERIC)
                FROM jsonb_array_elements(nl.logged_meals) m
            ), 0.0)::NUMERIC AS prot_g,
            COALESCE((
                SELECT SUM((m->>'carbs_grams')::NUMERIC)
                FROM jsonb_array_elements(nl.logged_meals) m
            ), 0.0)::NUMERIC AS carb_g,
            COALESCE((
                SELECT SUM((m->>'fat_grams')::NUMERIC)
                FROM jsonb_array_elements(nl.logged_meals) m
            ), 0.0)::NUMERIC AS fat_g,
            (COALESCE(nl.water_glasses, 0) * 250)::INTEGER AS w_ml
        FROM public.nutrition_logs nl
        WHERE nl.user_id = current_uid
          AND nl.is_deleted = false
          AND nl.log_date >= start_date
          AND nl.log_date <= end_date
    ),
    user_steps AS (
        SELECT
            s.step_date::DATE AS s_date,
            COALESCE(SUM(s.steps), 0)::INTEGER AS st_count,
            COALESCE(SUM(s.distance_meters) / 1000.0, 0.0)::NUMERIC AS dist_km,
            COALESCE(SUM(s.active_calories), 0)::INTEGER AS step_cals
        FROM public.step_daily_logs s
        WHERE s.user_id = current_uid
          AND s.deleted_at IS NULL
          AND s.step_date::DATE >= start_date
          AND s.step_date::DATE <= end_date
        GROUP BY s.step_date::DATE
    ),
    user_reminders AS (
        SELECT
            d.day_date,
            COUNT(r.id) > 0 AS has_rem,
            COUNT(CASE WHEN r.last_completed_at::DATE = d.day_date THEN 1 END)::INTEGER AS comp_rem,
            COUNT(CASE WHEN r.is_dismissed = true AND r.last_triggered_at::DATE = d.day_date THEN 1 END)::INTEGER AS miss_rem
        FROM days d
        LEFT JOIN public.reminders r 
          ON r.user_id = current_uid 
         AND r.is_deleted = false
         AND r.is_enabled = true
        GROUP BY d.day_date
    )
    SELECT
        d.day_date AS summary_date,
        COALESCE(us.st_count, 0)::INTEGER AS steps,
        COALESCE(us.dist_km, 0.0)::NUMERIC AS distance_km,
        COALESCE(uw.cnt, 0)::INTEGER AS workout_count,
        COALESCE(uw.dur_min, 0)::INTEGER AS workout_duration_min,
        COALESCE(uw.cal_burned, 0)::INTEGER AS calories_burned,
        COALESCE(un.cal_in, 0)::INTEGER AS calories_in,
        COALESCE(un.prot_g, 0.0)::NUMERIC AS protein_g,
        COALESCE(un.carb_g, 0.0)::NUMERIC AS carbs_g,
        COALESCE(un.fat_g, 0.0)::NUMERIC AS fats_g,
        COALESCE(un.w_ml, 0)::INTEGER AS water_ml,
        COALESCE(ur.has_rem, false) AS has_reminder,
        COALESCE(ur.comp_rem, 0)::INTEGER AS completed_reminders,
        COALESCE(ur.miss_rem, 0)::INTEGER AS missed_reminders
    FROM days d
    LEFT JOIN user_workouts uw ON uw.w_date = d.day_date
    LEFT JOIN user_nutrition un ON un.log_date = d.day_date
    LEFT JOIN user_steps us ON us.s_date = d.day_date
    LEFT JOIN user_reminders ur ON ur.day_date = d.day_date
    ORDER BY d.day_date ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_day_summaries(DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_day_summaries(DATE, DATE) TO authenticated, service_role;


-- ==============================================================================
-- 5. RESOLVE MULTIPLE PERMISSIVE POLICIES ON routine_exercises & routine_sets
-- ==============================================================================

-- Drop overlapping and legacy policies
DROP POLICY IF EXISTS "routine_exercises_modify" ON public.routine_exercises;
DROP POLICY IF EXISTS "routine_exercises_select_own_or_template" ON public.routine_exercises;
DROP POLICY IF EXISTS "routine_exercises_insert_own" ON public.routine_exercises;
DROP POLICY IF EXISTS "routine_exercises_update_own" ON public.routine_exercises;
DROP POLICY IF EXISTS "routine_exercises_delete_own" ON public.routine_exercises;

-- Non-overlapping action policies for routine_exercises
DROP POLICY IF EXISTS "routine_exercises_insert" ON public.routine_exercises;
CREATE POLICY "routine_exercises_insert" ON public.routine_exercises
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "routine_exercises_update" ON public.routine_exercises;
CREATE POLICY "routine_exercises_update" ON public.routine_exercises
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND r.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "routine_exercises_delete" ON public.routine_exercises;
CREATE POLICY "routine_exercises_delete" ON public.routine_exercises
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.routines r
            WHERE r.id = routine_exercises.routine_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

-- routine_sets
DROP POLICY IF EXISTS "routine_sets_modify" ON public.routine_sets;
DROP POLICY IF EXISTS "routine_sets_select_own_or_template" ON public.routine_sets;
DROP POLICY IF EXISTS "routine_sets_insert_own" ON public.routine_sets;
DROP POLICY IF EXISTS "routine_sets_update_own" ON public.routine_sets;
DROP POLICY IF EXISTS "routine_sets_delete_own" ON public.routine_sets;

DROP POLICY IF EXISTS "routine_sets_insert" ON public.routine_sets;
CREATE POLICY "routine_sets_insert" ON public.routine_sets
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "routine_sets_update" ON public.routine_sets;
CREATE POLICY "routine_sets_update" ON public.routine_sets
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND r.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND r.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "routine_sets_delete" ON public.routine_sets;
CREATE POLICY "routine_sets_delete" ON public.routine_sets
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.routine_exercises re
            JOIN public.routines r ON r.id = re.routine_id
            WHERE re.id = routine_sets.routine_exercise_id
              AND r.user_id = (SELECT auth.uid())
        )
    );


-- ==============================================================================
-- 6. RESOLVE AUTH RLS INITPLAN & MULTIPLE PERMISSIVE POLICIES ON CMS TABLES
-- ==============================================================================

-- site_announcements
DROP POLICY IF EXISTS "Admins manage announcements" ON public.site_announcements;
DROP POLICY IF EXISTS "Public can read published announcements" ON public.site_announcements;
DROP POLICY IF EXISTS "site_announcements_select" ON public.site_announcements;
DROP POLICY IF EXISTS "site_announcements_insert" ON public.site_announcements;
DROP POLICY IF EXISTS "site_announcements_update" ON public.site_announcements;
DROP POLICY IF EXISTS "site_announcements_delete" ON public.site_announcements;

CREATE POLICY "site_announcements_select"
  ON public.site_announcements FOR SELECT TO anon, authenticated
  USING (
    (status = 'published' AND (starts_at IS NULL OR starts_at <= now()) AND (ends_at IS NULL OR ends_at > now()))
    OR (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  );

CREATE POLICY "site_announcements_insert"
  ON public.site_announcements FOR INSERT TO authenticated
  WITH CHECK (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

CREATE POLICY "site_announcements_update"
  ON public.site_announcements FOR UPDATE TO authenticated
  USING (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  WITH CHECK (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

CREATE POLICY "site_announcements_delete"
  ON public.site_announcements FOR DELETE TO authenticated
  USING (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

-- site_updates
DROP POLICY IF EXISTS "Admins manage updates" ON public.site_updates;
DROP POLICY IF EXISTS "Public can read published updates" ON public.site_updates;
DROP POLICY IF EXISTS "site_updates_select" ON public.site_updates;
DROP POLICY IF EXISTS "site_updates_insert" ON public.site_updates;
DROP POLICY IF EXISTS "site_updates_update" ON public.site_updates;
DROP POLICY IF EXISTS "site_updates_delete" ON public.site_updates;

CREATE POLICY "site_updates_select"
  ON public.site_updates FOR SELECT TO anon, authenticated
  USING (
    status = 'published'
    OR (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  );

CREATE POLICY "site_updates_insert"
  ON public.site_updates FOR INSERT TO authenticated
  WITH CHECK (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

CREATE POLICY "site_updates_update"
  ON public.site_updates FOR UPDATE TO authenticated
  USING (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'))
  WITH CHECK (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));

CREATE POLICY "site_updates_delete"
  ON public.site_updates FOR DELETE TO authenticated
  USING (((select auth.jwt()) -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin'));
