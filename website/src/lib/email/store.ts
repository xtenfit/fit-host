import {
  EmailTemplate,
  EmailWorkflow,
  EmailDeliveryEvent,
  EmailSuppression,
} from './types';
import { INITIAL_50_EMAIL_TEMPLATES } from './templates';

// In-memory state storage (persists per server instance, hydrates with pre-seeded data)
const globalStore = globalThis as unknown as {
  _fitHostEmailTemplates?: Map<string, EmailTemplate>;
  _fitHostEmailWorkflows?: Map<string, EmailWorkflow>;
  _fitHostEmailEvents?: EmailDeliveryEvent[];
  _fitHostEmailSuppressions?: Set<string>;
  _fitHostTemplateVersions?: Map<string, { version: number; subject: string; html: string; text: string; date: string }[]>;
};

if (!globalStore._fitHostEmailTemplates) {
  const map = new Map<string, EmailTemplate>();
  for (const t of INITIAL_50_EMAIL_TEMPLATES) {
    map.set(t.id, { ...t });
  }
  globalStore._fitHostEmailTemplates = map;
}

if (!globalStore._fitHostEmailWorkflows) {
  const defaultWorkflows: EmailWorkflow[] = [
    {
      id: 'wf-welcome-on-signup',
      name: 'Welcome Series: Immediate Onboarding',
      description: 'Sends the Fit Host welcome and feature tour immediately after user signup.',
      trigger_event: 'auth.user.signup',
      template_id: 'welcome-intro',
      eligibility_rules: { new_user: true },
      delay_seconds: 0,
      is_enabled: true,
      retry_policy: { max_retries: 3, backoff_minutes: 15 },
      created_at: '2026-10-21T00:00:00Z',
      updated_at: '2026-10-21T00:00:00Z',
    },
    {
      id: 'wf-workout-streak-7',
      name: '7-Day Workout Streak Celebration',
      description: 'Congratulates athlete upon hitting 7 consecutive days of workout logging.',
      trigger_event: 'workout.streak.7days',
      template_id: 'workout-streak-milestone',
      eligibility_rules: { streak_equal: 7 },
      delay_seconds: 300,
      is_enabled: true,
      retry_policy: { max_retries: 2, backoff_minutes: 30 },
      created_at: '2026-10-21T00:00:00Z',
      updated_at: '2026-10-21T00:00:00Z',
    },
    {
      id: 'wf-midday-hydration',
      name: 'Midday Hydration Opt-In Push',
      description: 'Sends daily 14:00 hydration reminder if user has opted in to nutrition alerts.',
      trigger_event: 'schedule.daily.1400',
      template_id: 'nutrition-hydration-boost',
      eligibility_rules: { opt_in_nutrition: true },
      delay_seconds: 0,
      is_enabled: true,
      retry_policy: { max_retries: 1, backoff_minutes: 60 },
      created_at: '2026-10-21T00:00:00Z',
      updated_at: '2026-10-21T00:00:00Z',
    },
    {
      id: 'wf-weekly-digest',
      name: 'Sunday Evening Performance Digest',
      description: 'Compiles 7-day tonnage, volume, and PR count and delivers to athletes on Sunday.',
      trigger_event: 'schedule.weekly.sunday',
      template_id: 'progress-weekly-digest',
      eligibility_rules: { min_workouts_this_week: 1 },
      delay_seconds: 0,
      is_enabled: true,
      retry_policy: { max_retries: 3, backoff_minutes: 30 },
      created_at: '2026-10-21T00:00:00Z',
      updated_at: '2026-10-21T00:00:00Z',
    },
    {
      id: 'wf-release-announcement',
      name: 'App Version Release Broadcast',
      description: 'Notifies verified athletes when a major new Fit Host release (e.g. v2.1.0) is published.',
      trigger_event: 'release.published',
      template_id: 'product-release-v210',
      eligibility_rules: { marketing_opt_in: true },
      delay_seconds: 0,
      is_enabled: false,
      retry_policy: { max_retries: 3, backoff_minutes: 60 },
      created_at: '2026-10-21T00:00:00Z',
      updated_at: '2026-10-21T00:00:00Z',
    },
  ];
  const wMap = new Map<string, EmailWorkflow>();
  for (const w of defaultWorkflows) {
    wMap.set(w.id, { ...w });
  }
  globalStore._fitHostEmailWorkflows = wMap;
}

if (!globalStore._fitHostEmailEvents) {
  // Pre-seed sample delivery audit logs so the Email Studio shows rich history
  globalStore._fitHostEmailEvents = [
    {
      id: 'evt-init-01',
      recipient_email: 'athlete@amitrana.tech',
      subject: 'Verify your Fit Host account (Code: 839201)',
      template_id: 'auth-signup-confirmation',
      provider: 'resend',
      provider_message_id: 'msg_98418294a8c9b201',
      event_type: 'delivered',
      created_at: new Date(Date.now() - 3600000 * 2).toISOString(),
    },
    {
      id: 'evt-init-02',
      recipient_email: 'athlete@amitrana.tech',
      subject: 'Welcome to Fit Host — Your High-Performance Fitness Hub',
      template_id: 'welcome-intro',
      workflow_id: 'wf-welcome-on-signup',
      provider: 'resend',
      provider_message_id: 'msg_38219481b9e8c119',
      event_type: 'delivered',
      created_at: new Date(Date.now() - 3600000 * 1.8).toISOString(),
    },
    {
      id: 'evt-init-03',
      recipient_email: 'demo@amitrana.tech',
      subject: 'Your Fit Host Weekly Performance Report (34,250 kg logged)',
      template_id: 'progress-weekly-digest',
      workflow_id: 'wf-weekly-digest',
      provider: 'resend',
      provider_message_id: 'msg_29104812c8a7b392',
      event_type: 'delivered',
      created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
    },
    {
      id: 'evt-init-04',
      recipient_email: 'unreachable-bounce@example.org',
      subject: 'Time for your daily workout: Push Hypertrophy',
      template_id: 'workout-reminder',
      provider: 'resend',
      provider_message_id: 'msg_90192834d7e6f543',
      event_type: 'bounced',
      error_message: '550 5.1.1 Recipient mailbox does not exist (hard bounce)',
      created_at: new Date(Date.now() - 3600000 * 48).toISOString(),
    },
  ];
}

if (!globalStore._fitHostEmailSuppressions) {
  globalStore._fitHostEmailSuppressions = new Set([
    'unreachable-bounce@example.org',
    'optout-test@example.com',
  ]);
}

if (!globalStore._fitHostTemplateVersions) {
  globalStore._fitHostTemplateVersions = new Map();
}

export const emailStore = {
  // --- Templates ---
  async getTemplates(): Promise<EmailTemplate[]> {
    return Array.from(globalStore._fitHostEmailTemplates!.values());
  },

  async getTemplate(id: string): Promise<EmailTemplate | undefined> {
    return globalStore._fitHostEmailTemplates!.get(id);
  },

  async saveTemplate(template: EmailTemplate): Promise<EmailTemplate> {
    const existing = globalStore._fitHostEmailTemplates!.get(template.id);
    const updated = {
      ...template,
      version: existing ? existing.version + 1 : 1,
      updated_at: new Date().toISOString(),
    };

    // Save previous snapshot to version history
    if (existing) {
      const vList = globalStore._fitHostTemplateVersions!.get(template.id) || [];
      vList.unshift({
        version: existing.version,
        subject: existing.subject,
        html: existing.html_body,
        text: existing.text_body,
        date: existing.updated_at,
      });
      globalStore._fitHostTemplateVersions!.set(template.id, vList.slice(0, 15)); // keep last 15
    }

    globalStore._fitHostEmailTemplates!.set(template.id, updated);
    return updated;
  },

  async duplicateTemplate(sourceId: string, newId: string, newName: string): Promise<EmailTemplate | null> {
    const source = globalStore._fitHostEmailTemplates!.get(sourceId);
    if (!source) return null;

    const copy: EmailTemplate = {
      ...source,
      id: newId,
      name: newName,
      status: 'draft',
      version: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    globalStore._fitHostEmailTemplates!.set(newId, copy);
    return copy;
  },

  async getTemplateVersions(templateId: string) {
    return globalStore._fitHostTemplateVersions!.get(templateId) || [];
  },

  // --- Workflows ---
  async getWorkflows(): Promise<EmailWorkflow[]> {
    return Array.from(globalStore._fitHostEmailWorkflows!.values());
  },

  async updateWorkflow(id: string, updates: Partial<EmailWorkflow>): Promise<EmailWorkflow | null> {
    const existing = globalStore._fitHostEmailWorkflows!.get(id);
    if (!existing) return null;

    const updated = {
      ...existing,
      ...updates,
      updated_at: new Date().toISOString(),
    };
    globalStore._fitHostEmailWorkflows!.set(id, updated);
    return updated;
  },

  // --- Delivery Logs ---
  async getDeliveryEvents(limit: number = 100): Promise<EmailDeliveryEvent[]> {
    return [...globalStore._fitHostEmailEvents!].slice(0, limit);
  },

  async recordDeliveryEvent(event: Omit<EmailDeliveryEvent, 'id' | 'created_at'>): Promise<EmailDeliveryEvent> {
    const newEvent: EmailDeliveryEvent = {
      ...event,
      id: `evt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      created_at: new Date().toISOString(),
    };
    globalStore._fitHostEmailEvents!.unshift(newEvent);

    // Keep events array within bounds
    if (globalStore._fitHostEmailEvents!.length > 500) {
      globalStore._fitHostEmailEvents = globalStore._fitHostEmailEvents!.slice(0, 500);
    }

    return newEvent;
  },

  // --- Suppressions ---
  async isSuppressed(email: string): Promise<boolean> {
    return globalStore._fitHostEmailSuppressions!.has(email.toLowerCase().trim());
  },

  async getSuppressions(): Promise<EmailSuppression[]> {
    return Array.from(globalStore._fitHostEmailSuppressions!).map((email) => ({
      id: `sup_${email}`,
      email,
      reason: 'unsubscribed',
      created_at: '2026-10-21T00:00:00Z',
    }));
  },

  async addSuppression(email: string): Promise<void> {
    globalStore._fitHostEmailSuppressions!.add(email.toLowerCase().trim());
  },

  async removeSuppression(email: string): Promise<void> {
    globalStore._fitHostEmailSuppressions!.delete(email.toLowerCase().trim());
  },
};
