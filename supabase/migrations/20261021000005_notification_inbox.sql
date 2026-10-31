-- FIT HOST — NOTIFICATION CENTER & INBOX MIGRATION
-- Migration: 20261021000005_notification_inbox.sql
-- Description: Creates notification_inbox_items table with RLS policies,
--              composite indexes, and soft-delete support for fitness-related incoming alerts.

-- ============================================================================
-- 1. NOTIFICATION INBOX ITEMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notification_inbox_items (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('workout', 'nutrition', 'hydration', 'step_goal', 'reminder', 'system', 'general')),
    action_route TEXT,
    action_payload JSONB,
    is_read BOOLEAN NOT NULL DEFAULT false,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    read_at TIMESTAMPTZ,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    sync_status TEXT
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notification_inbox_items(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notification_inbox_items(user_id, is_read, is_deleted) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_notifications_user_category ON public.notification_inbox_items(user_id, category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_sync ON public.notification_inbox_items(user_id, server_updated_at);

-- ============================================================================
-- 2. ROW LEVEL SECURITY POLICIES
-- ============================================================================

ALTER TABLE public.notification_inbox_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_inbox_select_own" ON public.notification_inbox_items
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "notification_inbox_insert_own" ON public.notification_inbox_items
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "notification_inbox_update_own" ON public.notification_inbox_items
    FOR UPDATE USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "notification_inbox_delete_own" ON public.notification_inbox_items
    FOR DELETE USING ((SELECT auth.uid()) = user_id);
