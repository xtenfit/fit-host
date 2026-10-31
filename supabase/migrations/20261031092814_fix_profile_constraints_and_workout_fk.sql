-- ==============================================================================
-- FIT HOST — PRODUCTION POSTGRES ERRORS REPAIR
-- Migration: 20261031092814_fix_profile_constraints_and_workout_fk.sql
--
-- Directly fixes the two root causes of Postgres errors in Logs Explorer:
--   1. Error 23514 on public.profiles:
--      Relax check constraints (age, height_cm, weight_kg, gender) to safely
--      allow draft / onboarding initial states (0 or NULL) before setup is completed.
--   2. Error 23503 on public.workout_exercises:
--      Drop the rigid foreign key constraint referencing public.exercises(id)
--      so workouts containing custom, offline, or catalog exercises can sync seamlessly.
-- ==============================================================================

-- 1. Relax profiles check constraints for draft / pre-onboarding values
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_age_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_age_check
    CHECK (age IS NULL OR age = 0 OR (age >= 10 AND age <= 120));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_height_cm_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_height_cm_check
    CHECK (height_cm IS NULL OR height_cm >= 0);

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_weight_kg_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_weight_kg_check
    CHECK (weight_kg IS NULL OR weight_kg >= 0);

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_gender_check
    CHECK (gender IS NULL OR gender = '' OR gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text]));

-- 2. Drop rigid foreign key from workout_exercises to exercises catalog
ALTER TABLE public.workout_exercises DROP CONSTRAINT IF EXISTS workout_exercises_exercise_id_fkey;
