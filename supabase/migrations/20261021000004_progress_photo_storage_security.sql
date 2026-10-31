-- Progress-photo storage hardening.
-- This migration is intentionally additive and does not remove existing files
-- or rows. Apply only after reviewing the target Supabase project.

INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "progress_photos_storage_select_own"
  ON storage.objects;
CREATE POLICY "progress_photos_storage_select_own"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'progress-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );

DROP POLICY IF EXISTS "progress_photos_storage_insert_own"
  ON storage.objects;
CREATE POLICY "progress_photos_storage_insert_own"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'progress-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'heic', 'heif')
  );

DROP POLICY IF EXISTS "progress_photos_storage_update_own"
  ON storage.objects;
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
    AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'heic', 'heif')
  );

DROP POLICY IF EXISTS "progress_photos_storage_delete_own"
  ON storage.objects;
CREATE POLICY "progress_photos_storage_delete_own"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'progress-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );

ALTER TABLE public.progress_photos
  ADD COLUMN IF NOT EXISTS storage_object_path TEXT;
ALTER TABLE public.progress_photos
  ADD COLUMN IF NOT EXISTS media_mime_type TEXT;
ALTER TABLE public.progress_photos
  ADD COLUMN IF NOT EXISTS media_size_bytes BIGINT;
ALTER TABLE public.progress_photos
  ADD COLUMN IF NOT EXISTS sharing_consent_at TIMESTAMPTZ;

ALTER TABLE public.progress_photos
  DROP CONSTRAINT IF EXISTS progress_photos_media_mime_type_check;
ALTER TABLE public.progress_photos
  ADD CONSTRAINT progress_photos_media_mime_type_check
  CHECK (
    media_mime_type IS NULL
    OR media_mime_type IN ('image/jpeg', 'image/png', 'image/heic', 'image/heif')
  );

ALTER TABLE public.progress_photos
  DROP CONSTRAINT IF EXISTS progress_photos_media_size_check;
ALTER TABLE public.progress_photos
  ADD CONSTRAINT progress_photos_media_size_check
  CHECK (media_size_bytes IS NULL OR media_size_bytes BETWEEN 1 AND 10485760);
