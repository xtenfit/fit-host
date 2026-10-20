-- ============================================================================
-- Migration: 20261016000002_calories_burned.sql
-- Description: Adds calories_burned to workouts table and updates get_day_summaries
-- ============================================================================

-- 1. ADD COLUMN calories_burned TO WORKOUTS
ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS calories_burned INTEGER;

-- 2. UPDATE get_day_summaries TO AGGREGATE calories_burned
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
SECURITY DEFINER
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
        COALESCE(st.st_count, 0)::INTEGER AS steps,
        ROUND(COALESCE(st.dist_km, 0.0)::NUMERIC, 2) AS distance_km,
        COALESCE(w.cnt, 0)::INTEGER AS workout_count,
        COALESCE(w.dur_min, 0)::INTEGER AS workout_duration_min,
        (COALESCE(w.cal_burned, 0) + COALESCE(st.step_cals, 0))::INTEGER AS calories_burned,
        COALESCE(n.cal_in, 0)::INTEGER AS calories_in,
        ROUND(COALESCE(n.prot_g, 0.0)::NUMERIC, 1) AS protein_g,
        ROUND(COALESCE(n.carb_g, 0.0)::NUMERIC, 1) AS carbs_g,
        ROUND(COALESCE(n.fat_g, 0.0)::NUMERIC, 1) AS fats_g,
        COALESCE(n.w_ml, 0)::INTEGER AS water_ml,
        COALESCE(rem.has_rem, false) AS has_reminder,
        COALESCE(rem.comp_rem, 0)::INTEGER AS completed_reminders,
        COALESCE(rem.missed_reminders, 0)::INTEGER AS missed_reminders
    FROM days d
    LEFT JOIN user_workouts w ON d.day_date = w.w_date
    LEFT JOIN user_nutrition n ON d.day_date = n.log_date
    LEFT JOIN user_steps st ON d.day_date = st.s_date
    LEFT JOIN user_reminders rem ON d.day_date = rem.day_date
    ORDER BY d.day_date ASC;
END;
$$;
