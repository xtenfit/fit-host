-- ==============================================================================
-- FIT HOST — REMOVE REMINDERS FROM REMOTE DATABASE
-- Migration: 20261024000001_remove_reminders_from_cloud_db.sql
--
-- Alarms and reminders are managed strictly on-device (local SQLite/Drift)
-- and are not stored or synced to the Supabase remote database.
-- ==============================================================================

-- 1. Update get_day_summaries to remove dependence on public.reminders
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
        false AS has_reminder,
        0::INTEGER AS completed_reminders,
        0::INTEGER AS missed_reminders
    FROM days d
    LEFT JOIN user_workouts uw ON uw.w_date = d.day_date
    LEFT JOIN user_nutrition un ON un.log_date = d.day_date
    LEFT JOIN user_steps us ON us.s_date = d.day_date
    ORDER BY d.day_date ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_day_summaries(DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_day_summaries(DATE, DATE) TO authenticated, service_role;

-- 2. Drop reminders table from remote database
DROP TABLE IF EXISTS public.reminders CASCADE;
