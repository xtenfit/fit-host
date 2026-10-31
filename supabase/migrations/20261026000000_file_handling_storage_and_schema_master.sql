-- ==============================================================================
-- FIT HOST — FULL-STACK FILE HANDLING, STORAGE BUCKETS, AND DB SCHEMA MASTER
-- Migration: 20261026000000_file_handling_storage_and_schema_master.sql
--
-- Features Handled:
-- 1. Storage Buckets & Policies:
--    - avatars (public, image files, user folder isolation)
--    - progress-photos (private, image files, authenticated owner access)
--    - diary-attachments (private, image/docs/audio memos, authenticated owner access)
--    - workout-attachments (private, image/video/logs, authenticated owner access)
-- 2. Daily Diary Entries (public.daily_diary_entries):
--    - Missing table created with owner RLS, media paths, sync timestamps
-- 3. Calorie Adjustments (public.calorie_adjustments):
--    - Missing table created with owner RLS and date indexes
-- 4. Reminders Architecture (public.reminder_schedules):
--    - Local-first execution (alarms, notifications, snooze strictly on-device)
--    - ONLY schedule records stored in public.reminder_schedules
-- 5. Profiles Reconciliation & Auto-Backfill:
--    - email nullability drop & trigger sync from auth.users
-- 6. Step Daily Logs Reconciliation:
--    - canonical columns (steps, target_steps, distance_meters, active_calories)
-- 7. Nutrition Logs Reconciliation:
--    - canonical unique(user_id, log_date)
-- ==============================================================================

-- ==============================================================================
-- 1. SUPABASE STORAGE BUCKETS SETUP
-- ==============================================================================

-- 1.1 Avatars (Public bucket for profile display avatars)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- 1.2 Progress Photos (Private bucket for client progress gallery)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'progress-photos',
    'progress-photos',
    false,
    15728640, -- 15 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 15728640,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];

-- 1.3 Diary Attachments (Private bucket for meal photos, journal docs & voice memos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'diary-attachments',
    'diary-attachments',
    false,
    26214400, -- 25 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf', 'audio/mp4', 'audio/mpeg', 'audio/m4a', 'audio/x-m4a', 'audio/wav', 'audio/aac']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 26214400,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf', 'audio/mp4', 'audio/mpeg', 'audio/m4a', 'audio/x-m4a', 'audio/wav', 'audio/aac'];

-- 1.4 Workout Attachments (Private bucket for exercise forms & workout media)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'workout-attachments',
    'workout-attachments',
    false,
    52428800, -- 50 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'video/webm', 'application/pdf', 'text/plain']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'video/webm', 'application/pdf', 'text/plain'];

-- ==============================================================================
-- 2. STORAGE OBJECTS ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 2.1 Avatars Storage Policies
DROP POLICY IF EXISTS "avatars_storage_select_public" ON storage.objects;
CREATE POLICY "avatars_storage_select_public"
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_storage_insert_own" ON storage.objects;
CREATE POLICY "avatars_storage_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "avatars_storage_update_own" ON storage.objects;
CREATE POLICY "avatars_storage_update_own"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    )
    WITH CHECK (
        bucket_id = 'avatars'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "avatars_storage_delete_own" ON storage.objects;
CREATE POLICY "avatars_storage_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

-- 2.2 Progress Photos Storage Policies (Private, User-Folder Isolated)
DROP POLICY IF EXISTS "progress_photos_storage_select_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_select_own"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "progress_photos_storage_insert_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'progress-photos'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "progress_photos_storage_update_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_update_own"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    )
    WITH CHECK (
        bucket_id = 'progress-photos'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "progress_photos_storage_delete_own" ON storage.objects;
CREATE POLICY "progress_photos_storage_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'progress-photos'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

-- 2.3 Diary Attachments Storage Policies (Private, User-Folder Isolated)
DROP POLICY IF EXISTS "diary_attachments_storage_select_own" ON storage.objects;
CREATE POLICY "diary_attachments_storage_select_own"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'diary-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "diary_attachments_storage_insert_own" ON storage.objects;
CREATE POLICY "diary_attachments_storage_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'diary-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "diary_attachments_storage_update_own" ON storage.objects;
CREATE POLICY "diary_attachments_storage_update_own"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'diary-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    )
    WITH CHECK (
        bucket_id = 'diary-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "diary_attachments_storage_delete_own" ON storage.objects;
CREATE POLICY "diary_attachments_storage_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'diary-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

-- 2.4 Workout Attachments Storage Policies (Private, User-Folder Isolated)
DROP POLICY IF EXISTS "workout_attachments_storage_select_own" ON storage.objects;
CREATE POLICY "workout_attachments_storage_select_own"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'workout-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "workout_attachments_storage_insert_own" ON storage.objects;
CREATE POLICY "workout_attachments_storage_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'workout-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "workout_attachments_storage_update_own" ON storage.objects;
CREATE POLICY "workout_attachments_storage_update_own"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'workout-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    )
    WITH CHECK (
        bucket_id = 'workout-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

DROP POLICY IF EXISTS "workout_attachments_storage_delete_own" ON storage.objects;
CREATE POLICY "workout_attachments_storage_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'workout-attachments'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid()::text)
            OR name LIKE ((SELECT auth.uid()::text) || '/%')
        )
    );

-- ==============================================================================
-- 3. NOTES & DIARY FEATURE (public.daily_diary_entries)
-- ==============================================================================

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
CREATE POLICY "daily_diary_entries_select_own"
    ON public.daily_diary_entries
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "daily_diary_entries_insert_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_insert_own"
    ON public.daily_diary_entries
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "daily_diary_entries_update_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_update_own"
    ON public.daily_diary_entries
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "daily_diary_entries_delete_own" ON public.daily_diary_entries;
CREATE POLICY "daily_diary_entries_delete_own"
    ON public.daily_diary_entries
    FOR DELETE
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP TRIGGER IF EXISTS trg_daily_diary_entries_updated_at ON public.daily_diary_entries;
CREATE TRIGGER trg_daily_diary_entries_updated_at
    BEFORE UPDATE ON public.daily_diary_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.set_server_updated_at();

GRANT ALL ON TABLE public.daily_diary_entries TO authenticated, service_role;

-- ==============================================================================
-- 4. CALORIE ADJUSTMENTS TABLE (public.calorie_adjustments)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.calorie_adjustments (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    calories_burned INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    note TEXT,
    source TEXT NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_calorie_adjustments_user_id ON public.calorie_adjustments(user_id);
CREATE INDEX IF NOT EXISTS idx_calorie_adjustments_user_date ON public.calorie_adjustments(user_id, date, deleted_at);

ALTER TABLE public.calorie_adjustments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "calorie_adjustments_select_own" ON public.calorie_adjustments;
CREATE POLICY "calorie_adjustments_select_own"
    ON public.calorie_adjustments
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "calorie_adjustments_insert_own" ON public.calorie_adjustments;
CREATE POLICY "calorie_adjustments_insert_own"
    ON public.calorie_adjustments
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "calorie_adjustments_update_own" ON public.calorie_adjustments;
CREATE POLICY "calorie_adjustments_update_own"
    ON public.calorie_adjustments
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "calorie_adjustments_delete_own" ON public.calorie_adjustments;
CREATE POLICY "calorie_adjustments_delete_own"
    ON public.calorie_adjustments
    FOR DELETE
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

GRANT ALL ON TABLE public.calorie_adjustments TO authenticated, service_role;

-- ==============================================================================
-- 5. REMINDER SCHEDULES TABLE (SCHEDULE-ONLY SYNC ARCHITECTURE)
-- ==============================================================================
-- As per architecture requirements: alarms, vibrations, sounds, and snooze states
-- remain strictly local in SQLite. Only schedule times sync to remote DB.

CREATE TABLE IF NOT EXISTS public.reminder_schedules (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    time_of_day TEXT NOT NULL,
    repeat_days TEXT,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON public.reminder_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_enabled ON public.reminder_schedules(user_id, is_enabled);

ALTER TABLE public.reminder_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reminder_schedules_select_own" ON public.reminder_schedules;
CREATE POLICY "reminder_schedules_select_own"
    ON public.reminder_schedules
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "reminder_schedules_insert_own" ON public.reminder_schedules;
CREATE POLICY "reminder_schedules_insert_own"
    ON public.reminder_schedules
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "reminder_schedules_update_own" ON public.reminder_schedules;
CREATE POLICY "reminder_schedules_update_own"
    ON public.reminder_schedules
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "reminder_schedules_delete_own" ON public.reminder_schedules;
CREATE POLICY "reminder_schedules_delete_own"
    ON public.reminder_schedules
    FOR DELETE
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

GRANT ALL ON TABLE public.reminder_schedules TO authenticated, service_role;

-- ==============================================================================
-- 6. PROFILES RECONCILIATION & AUTO-BACKFILL
-- ==============================================================================
-- Make email nullable on public.profiles so partial mutations from SQLite outbox
-- (e.g., target_steps, display_name) never fail with a not-null violation.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'profiles' 
          AND column_name = 'email' 
          AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.profiles ALTER COLUMN email DROP NOT NULL;
    END IF;
END $$;

-- Trigger to auto-fill email from auth.users if missing during insert/update
CREATE OR REPLACE FUNCTION public.sync_profile_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email IS NULL OR TRIM(NEW.email) = '' THEN
        NEW.email := (
            SELECT email FROM auth.users 
            WHERE id = COALESCE(NEW.user_id, NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_profile_email ON public.profiles;
CREATE TRIGGER trg_sync_profile_email
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_profile_email();

-- Backfill missing email for any existing profiles
UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE (p.id = u.id OR p.user_id = u.id)
  AND (p.email IS NULL OR TRIM(p.email) = '');

GRANT ALL ON TABLE public.profiles TO authenticated, service_role;

-- ==============================================================================
-- 7. STEP DAILY LOGS RECONCILIATION
-- ==============================================================================
-- Ensure all canonical columns exist and unique constraint is active.

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
    deleted_at TIMESTAMPTZ
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'step_daily_logs' AND column_name = 'steps'
    ) THEN
        ALTER TABLE public.step_daily_logs ADD COLUMN steps INTEGER NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'step_daily_logs' AND column_name = 'target_steps'
    ) THEN
        ALTER TABLE public.step_daily_logs ADD COLUMN target_steps INTEGER NOT NULL DEFAULT 10000;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'step_daily_logs' AND column_name = 'distance_meters'
    ) THEN
        ALTER TABLE public.step_daily_logs ADD COLUMN distance_meters NUMERIC(10,2) NOT NULL DEFAULT 0.0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'step_daily_logs' AND column_name = 'active_calories'
    ) THEN
        ALTER TABLE public.step_daily_logs ADD COLUMN active_calories INTEGER NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'step_daily_logs' AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE public.step_daily_logs ADD COLUMN deleted_at TIMESTAMPTZ;
    END IF;
END $$;

-- Ensure unique constraint on (user_id, step_date)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname IN ('uq_step_daily_logs_user_date', 'uq_step_user_date')
    ) THEN
        ALTER TABLE public.step_daily_logs 
        ADD CONSTRAINT uq_step_daily_logs_user_date UNIQUE (user_id, step_date);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_step_daily_logs_user_date ON public.step_daily_logs(user_id, step_date);
CREATE INDEX IF NOT EXISTS idx_step_daily_logs_user_id ON public.step_daily_logs(user_id);

ALTER TABLE public.step_daily_logs ENABLE ROW LEVEL SECURITY;

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

GRANT ALL ON TABLE public.step_daily_logs TO authenticated, service_role;

-- ==============================================================================
-- 8. NUTRITION LOGS RECONCILIATION
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname IN ('uq_nutrition_logs_user_date', 'uq_user_log_date')
    ) THEN
        ALTER TABLE public.nutrition_logs 
        ADD CONSTRAINT uq_nutrition_logs_user_date UNIQUE (user_id, log_date);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user_date ON public.nutrition_logs(user_id, log_date);

GRANT ALL ON TABLE public.nutrition_logs TO authenticated, service_role;

-- ==============================================================================
-- 9. RELOAD POSTGREST SCHEMA CACHE
-- ==============================================================================
NOTIFY pgrst, 'reload schema';
