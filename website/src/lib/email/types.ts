export type EmailCategory =
  | 'authentication'
  | 'welcome'
  | 'workout'
  | 'nutrition'
  | 'progress'
  | 'product'
  | 'support'
  | 'feedback'
  | 'announcement'
  | 'blank';

export type EmailTemplateStatus = 'draft' | 'published' | 'archived';

export interface EmailTemplateField {
  name: string;
  label: string;
  type: 'text' | 'textarea' | 'url' | 'number';
  defaultValue: string;
  description?: string;
}

export interface EmailTemplate {
  id: string;
  name: string;
  category: EmailCategory;
  subject: string;
  preheader: string;
  html_body: string;
  text_body: string;
  fields: EmailTemplateField[];
  variables: string[];
  status: EmailTemplateStatus;
  version: number;
  created_at: string;
  updated_at: string;
}

export interface EmailDeliveryEvent {
  id: string;
  template_id?: string;
  workflow_id?: string;
  recipient_email: string;
  subject: string;
  provider: string;
  provider_message_id?: string;
  event_type: 'queued' | 'sent' | 'delivered' | 'bounced' | 'rejected' | 'failed' | 'suppressed' | 'retried';
  status_code?: number;
  error_message?: string;
  metadata?: Record<string, unknown>;
  created_at: string;
}

export interface EmailWorkflow {
  id: string;
  name: string;
  description: string;
  trigger_event: string;
  template_id: string;
  eligibility_rules: Record<string, unknown>;
  delay_seconds: number;
  is_enabled: boolean;
  retry_policy: {
    max_retries: number;
    backoff_minutes: number;
  };
  last_executed_at?: string;
  created_at: string;
  updated_at: string;
}

export interface EmailSuppression {
  id: string;
  email: string;
  reason: 'unsubscribed' | 'bounce_hard' | 'bounce_soft' | 'complaint' | 'manual';
  created_at: string;
}

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  from?: string;
  replyTo?: string;
  tags?: { name: string; value: string }[];
  templateId?: string;
  workflowId?: string;
  isTest?: boolean;
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
  isTest?: boolean;
}
