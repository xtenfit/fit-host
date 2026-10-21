-- ==============================================================================
-- FIT HOST EMAIL STUDIO & AUTOMATION INFRASTRUCTURE
-- Migration: 20261021_email_studio.sql
-- ==============================================================================

-- 1. Email Templates Table
CREATE TABLE IF NOT EXISTS public.email_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  subject TEXT NOT NULL,
  preheader TEXT,
  html_body TEXT NOT NULL,
  text_body TEXT NOT NULL,
  fields JSONB DEFAULT '[]'::jsonb,
  variables TEXT[] DEFAULT ARRAY[]::TEXT[],
  status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Email Template Versions (Audit & Rollback)
CREATE TABLE IF NOT EXISTS public.email_template_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id TEXT NOT NULL REFERENCES public.email_templates(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  subject TEXT NOT NULL,
  preheader TEXT,
  html_body TEXT NOT NULL,
  text_body TEXT NOT NULL,
  change_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID
);

-- 3. Email Automation Workflows Table
CREATE TABLE IF NOT EXISTS public.email_automation_workflows (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  trigger_event TEXT NOT NULL,
  template_id TEXT NOT NULL REFERENCES public.email_templates(id),
  eligibility_rules JSONB DEFAULT '{}'::jsonb,
  delay_seconds INTEGER NOT NULL DEFAULT 0,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  retry_policy JSONB DEFAULT '{"max_retries": 3, "backoff_minutes": 15}'::jsonb,
  last_executed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Email Automation Runs (Execution Queue & History)
CREATE TABLE IF NOT EXISTS public.email_automation_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id TEXT NOT NULL REFERENCES public.email_automation_workflows(id) ON DELETE CASCADE,
  recipient_email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'queued', 'completed', 'failed', 'skipped')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  provider_message_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  idempotency_key TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- 5. Email Delivery Events (Audit Trail & Observability)
CREATE TABLE IF NOT EXISTS public.email_delivery_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id TEXT,
  workflow_id TEXT,
  recipient_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  provider TEXT NOT NULL DEFAULT 'resend',
  provider_message_id TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN ('queued', 'sent', 'delivered', 'bounced', 'rejected', 'failed', 'suppressed', 'retried')),
  status_code INTEGER,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Email Suppressions (Unsubscribes & Hard Bounces)
CREATE TABLE IF NOT EXISTS public.email_suppressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  reason TEXT NOT NULL DEFAULT 'unsubscribed' CHECK (reason IN ('unsubscribed', 'bounce_hard', 'bounce_soft', 'complaint', 'manual')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_email_templates_category ON public.email_templates(category);
CREATE INDEX IF NOT EXISTS idx_email_templates_status ON public.email_templates(status);
CREATE INDEX IF NOT EXISTS idx_email_template_versions_tpl_id ON public.email_template_versions(template_id);
CREATE INDEX IF NOT EXISTS idx_email_workflows_trigger ON public.email_automation_workflows(trigger_event);
CREATE INDEX IF NOT EXISTS idx_email_automation_runs_status ON public.email_automation_runs(status);
CREATE INDEX IF NOT EXISTS idx_email_delivery_events_recipient ON public.email_delivery_events(recipient_email);
CREATE INDEX IF NOT EXISTS idx_email_delivery_events_event_type ON public.email_delivery_events(event_type);
CREATE INDEX IF NOT EXISTS idx_email_delivery_events_created_at ON public.email_delivery_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_suppressions_email ON public.email_suppressions(email);

-- 8. Row Level Security Policies
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_template_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_automation_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_automation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_delivery_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_suppressions ENABLE ROW LEVEL SECURITY;

-- Service Role has full access
CREATE POLICY "Service role full access on email_templates" ON public.email_templates
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on email_template_versions" ON public.email_template_versions
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on email_automation_workflows" ON public.email_automation_workflows
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on email_automation_runs" ON public.email_automation_runs
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on email_delivery_events" ON public.email_delivery_events
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on email_suppressions" ON public.email_suppressions
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Authenticated Admin Access Policy
-- Users with app_metadata->>'role' = 'admin' can view and edit
CREATE POLICY "Admins full access on email_templates" ON public.email_templates
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins full access on email_template_versions" ON public.email_template_versions
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins full access on email_automation_workflows" ON public.email_automation_workflows
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins full access on email_automation_runs" ON public.email_automation_runs
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins full access on email_delivery_events" ON public.email_delivery_events
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins full access on email_suppressions" ON public.email_suppressions
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
