-- FIT HOST: Storage Buckets, RLS, and Auth Profile Automation
-- Migration: 20261024000002_fix_storage_and_auth_triggers.sql

-- 1. Ensure progress-photos bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- 2. Storage Objects RLS Policies for Progress Photos
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

-- 3. Automatic Profile Creation on User Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    derived_name TEXT;
    derived_avatar TEXT;
BEGIN
    derived_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 4. Sync Email Updates from Auth into Profile
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE OF email ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_updated();

-- 5. Revoke direct RPC execution from anon and authenticated for security definer trigger functions
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_user_updated() FROM PUBLIC, anon, authenticated;
