-- ============================================================================
-- FIT HOST — MIGRATION 20261016000005: WIZARD EXPANSION & PERSONALIZATION
-- Adds custom schedule, body composition, gender branching, and lifestyle fields
-- ============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender_specific_goals TEXT DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS body_fat_percent NUMERIC,
  ADD COLUMN IF NOT EXISTS waist_cm NUMERIC,
  ADD COLUMN IF NOT EXISTS hip_cm NUMERIC,
  ADD COLUMN IF NOT EXISTS chest_cm NUMERIC,
  ADD COLUMN IF NOT EXISTS neck_cm NUMERIC,
  ADD COLUMN IF NOT EXISTS target_weeks INTEGER,
  ADD COLUMN IF NOT EXISTS selected_weekdays TEXT DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS session_duration_minutes INTEGER DEFAULT 45,
  ADD COLUMN IF NOT EXISTS uses_every_day BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS meals_per_day INTEGER DEFAULT 3,
  ADD COLUMN IF NOT EXISTS sleep_hours NUMERIC DEFAULT 7.5,
  ADD COLUMN IF NOT EXISTS stress_level TEXT,
  ADD COLUMN IF NOT EXISTS reminder_frequency_hours INTEGER DEFAULT 2,
  ADD COLUMN IF NOT EXISTS quiet_hours_start TEXT,
  ADD COLUMN IF NOT EXISTS quiet_hours_end TEXT,
  ADD COLUMN IF NOT EXISTS allergy_notes TEXT,
  ADD COLUMN IF NOT EXISTS activity_level TEXT,
  ADD COLUMN IF NOT EXISTS work_hours INTEGER;
