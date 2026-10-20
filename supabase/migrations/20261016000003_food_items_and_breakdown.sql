-- ============================================================================
-- Migration: 20261016000003_food_items_and_breakdown.sql
-- Description: Creates food_items table with RLS and get_nutrition_breakdown RPC
-- ============================================================================

-- 1. CREATE FOOD ITEMS TABLE
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
    source TEXT NOT NULL DEFAULT 'user_custom', -- 'seeded', 'openfoodfacts', 'gemini', 'user_custom'
    image_url TEXT,
    is_deleted INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON public.food_items(barcode);
CREATE INDEX IF NOT EXISTS idx_food_items_user_id ON public.food_items(user_id);
CREATE INDEX IF NOT EXISTS idx_food_items_source ON public.food_items(source);

-- 2. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

-- 3. POLICIES
-- SELECT: public read for source IN ('seeded','openfoodfacts'); owner-only for source IN ('user_custom','gemini')
CREATE POLICY "food_items_select_policy" ON public.food_items
    FOR SELECT
    USING (
        source IN ('seeded', 'openfoodfacts')
        OR (auth.uid() = user_id)
    );

-- INSERT: owner-only
CREATE POLICY "food_items_insert_policy" ON public.food_items
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: owner-only
CREATE POLICY "food_items_update_policy" ON public.food_items
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- DELETE: owner-only
CREATE POLICY "food_items_delete_policy" ON public.food_items
    FOR DELETE
    USING (auth.uid() = user_id);

-- 4. RPC: get_nutrition_breakdown
-- Returns per-day totals and per-meal-type subtotals
CREATE OR REPLACE FUNCTION public.get_nutrition_breakdown(start_date DATE, end_date DATE)
RETURNS TABLE (
    summary_date DATE,
    total_calories INTEGER,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fats NUMERIC,
    breakfast_calories INTEGER,
    lunch_calories INTEGER,
    dinner_calories INTEGER,
    snack_calories INTEGER,
    custom_calories INTEGER
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
    expanded_meals AS (
        SELECT
            nl.log_date,
            (m->>'meal_type') AS m_type,
            COALESCE((m->>'calories')::INTEGER, 0) AS cal,
            COALESCE((m->>'protein_grams')::NUMERIC, 0.0) AS prot,
            COALESCE((m->>'carbs_grams')::NUMERIC, 0.0) AS carb,
            COALESCE((m->>'fat_grams')::NUMERIC, 0.0) AS fat
        FROM public.nutrition_logs nl,
             jsonb_array_elements(nl.logged_meals) m
        WHERE nl.user_id = current_uid
          AND nl.is_deleted = false
          AND nl.log_date >= start_date
          AND nl.log_date <= end_date
    ),
    day_subtotals AS (
        SELECT
            em.log_date,
            SUM(em.cal)::INTEGER AS tot_cal,
            SUM(em.prot)::NUMERIC AS tot_prot,
            SUM(em.carb)::NUMERIC AS tot_carb,
            SUM(em.fat)::NUMERIC AS tot_fat,
            SUM(CASE WHEN LOWER(em.m_type) = 'breakfast' THEN em.cal ELSE 0 END)::INTEGER AS b_cal,
            SUM(CASE WHEN LOWER(em.m_type) = 'lunch' THEN em.cal ELSE 0 END)::INTEGER AS l_cal,
            SUM(CASE WHEN LOWER(em.m_type) = 'dinner' THEN em.cal ELSE 0 END)::INTEGER AS d_cal,
            SUM(CASE WHEN LOWER(em.m_type) IN ('snack', 'snacks') THEN em.cal ELSE 0 END)::INTEGER AS s_cal,
            SUM(CASE WHEN LOWER(em.m_type) NOT IN ('breakfast', 'lunch', 'dinner', 'snack', 'snacks') THEN em.cal ELSE 0 END)::INTEGER AS c_cal
        FROM expanded_meals em
        GROUP BY em.log_date
    )
    SELECT
        d.day_date AS summary_date,
        COALESCE(ds.tot_cal, 0)::INTEGER AS total_calories,
        ROUND(COALESCE(ds.tot_prot, 0.0)::NUMERIC, 1) AS total_protein,
        ROUND(COALESCE(ds.tot_carb, 0.0)::NUMERIC, 1) AS total_carbs,
        ROUND(COALESCE(ds.tot_fat, 0.0)::NUMERIC, 1) AS total_fats,
        COALESCE(ds.b_cal, 0)::INTEGER AS breakfast_calories,
        COALESCE(ds.l_cal, 0)::INTEGER AS lunch_calories,
        COALESCE(ds.d_cal, 0)::INTEGER AS dinner_calories,
        COALESCE(ds.s_cal, 0)::INTEGER AS snack_calories,
        COALESCE(ds.c_cal, 0)::INTEGER AS custom_calories
    FROM days d
    LEFT JOIN day_subtotals ds ON d.day_date = ds.log_date
    ORDER BY d.day_date ASC;
END;
$$;
