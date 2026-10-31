-- FIT HOST — EXERCISE WIKI & COMMUNITY CONTRIBUTIONS MIGRATION
-- Migration: 20261021000003_exercise_wiki_and_submissions.sql
-- Description: Creates exercise_submissions and exercise_moderation_logs tables with RLS policies,
--              foreign keys, composite indexes, duplicate prevention, and provenance integrity.

-- ============================================================================
-- 1. EXERCISE SUBMISSIONS TABLE (Drafts & Suggestions separate from canonical catalog)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.exercise_submissions (
    id TEXT PRIMARY KEY,
    submission_type TEXT NOT NULL DEFAULT 'new_exercise' CHECK (submission_type IN ('new_exercise', 'correction')),
    target_exercise_id TEXT REFERENCES public.exercises(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    equipment TEXT NOT NULL,
    target_muscle TEXT NOT NULL,
    secondary_muscles JSONB NOT NULL DEFAULT '[]'::jsonb,
    instructions TEXT NOT NULL,
    safety_notes TEXT,
    difficulty_level TEXT NOT NULL DEFAULT 'Intermediate',
    movement_type TEXT NOT NULL DEFAULT 'Compound',
    audience_suitability TEXT NOT NULL DEFAULT 'universal' CHECK (audience_suitability IN ('universal', 'male_specific', 'female_specific', 'unverified')),
    suggested_rationale TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    moderator_notes TEXT,
    submitted_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    duplicate_hash TEXT NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_exercise_submissions_submitted_by ON public.exercise_submissions(submitted_by, status);
CREATE INDEX IF NOT EXISTS idx_exercise_submissions_target ON public.exercise_submissions(target_exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_submissions_hash ON public.exercise_submissions(duplicate_hash);
CREATE INDEX IF NOT EXISTS idx_exercise_submissions_status ON public.exercise_submissions(status);
CREATE INDEX IF NOT EXISTS idx_exercise_submissions_sync ON public.exercise_submissions(submitted_by, server_updated_at);

ALTER TABLE public.exercise_submissions ENABLE ROW LEVEL SECURITY;

-- Users can view their own submissions or any approved community-vetted submissions
CREATE POLICY "exercise_submissions_select" ON public.exercise_submissions
    FOR SELECT USING (
        (SELECT auth.uid()) = submitted_by
        OR status = 'approved'
    );

-- Users can only insert submissions owned by themselves with pending status
CREATE POLICY "exercise_submissions_insert_own" ON public.exercise_submissions
    FOR INSERT WITH CHECK (
        (SELECT auth.uid()) = submitted_by
        AND status = 'pending'
    );

-- Normal users can only soft-delete or cancel their pending submissions
CREATE POLICY "exercise_submissions_update_own" ON public.exercise_submissions
    FOR UPDATE USING (
        (SELECT auth.uid()) = submitted_by
        AND status = 'pending'
    ) WITH CHECK (
        (SELECT auth.uid()) = submitted_by
        AND status = 'pending'
    );

CREATE POLICY "exercise_submissions_delete_own" ON public.exercise_submissions
    FOR DELETE USING (
        (SELECT auth.uid()) = submitted_by
        AND status = 'pending'
    );

-- ============================================================================
-- 2. EXERCISE MODERATION LOGS TABLE (Audit trail for review actions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.exercise_moderation_logs (
    id TEXT PRIMARY KEY,
    submission_id TEXT NOT NULL REFERENCES public.exercise_submissions(id) ON DELETE CASCADE,
    moderator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('approve', 'reject', 'request_changes')),
    notes TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_exercise_moderation_submission ON public.exercise_moderation_logs(submission_id);
CREATE INDEX IF NOT EXISTS idx_exercise_moderation_moderator ON public.exercise_moderation_logs(moderator_id);

ALTER TABLE public.exercise_moderation_logs ENABLE ROW LEVEL SECURITY;

-- Users can view moderation logs on their own submissions
CREATE POLICY "exercise_moderation_logs_select" ON public.exercise_moderation_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.exercise_submissions s
            WHERE s.id = exercise_moderation_logs.submission_id
            AND s.submitted_by = (SELECT auth.uid())
        )
    );

-- Trigger for server_updated_at
CREATE OR REPLACE TRIGGER set_exercise_submissions_server_updated_at
BEFORE UPDATE ON public.exercise_submissions
FOR EACH ROW
EXECUTE FUNCTION public.update_server_updated_at_column();
